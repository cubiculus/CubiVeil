#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Monitor Utility                      ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                          ║
# ║  Мониторинг состояния сервера в реальном времени         ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
if [[ -f "${PROJECT_DIR}/lang.sh" ]]; then
  source "${PROJECT_DIR}/lang.sh"
else
  source "${PROJECT_DIR}/lib/fallback.sh"
fi

# ── Подключение общих утилит ───────────────────────────────────
source "${PROJECT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}

# ── Константы ─────────────────────────────────────────────────
REFRESH_INTERVAL=5
MARZBAN_DIR="/opt/marzban"

# ── Локализация сообщений ─────────────────────────────────────
declare -A MSG=(
  [TITLE_MONITOR]="CubiVeil — Server Monitor"
  [TITLE_SYSTEM]="Системные ресурсы"
  [TITLE_SERVICES]="Статус сервисов"
  [TITLE_NETWORK]="Сеть"
  [TITLE_USERS]="Пользователи"
  [TITLE_LOGS]="Последние события"

  [MSG_CPU_LOAD]="Загрузка CPU"
  [MSG_RAM_USAGE]="Использование RAM"
  [MSG_DISK_USAGE]="Использование диска"
  [MSG_UPTIME]="Время работы"
  [MSG_ACTIVE]="активен"
  [MSG_INACTIVE]="неактивен"
  [MSG_RUNNING]="работает"
  [MSG_STOPPED]="остановлен"
  [MSG_USERS_ONLINE]="пользователей онлайн"
  [MSG_NO_DATA]="нет данных"

  [ERR_NOT_ROOT]="Требуется запуск от root"
  [ERR_INTERRUPTED]="Мониторинг прерван"

  [PROMPT_REFRESH]="Обновление каждые"
  [PROMPT_QUIT]="Нажмите Ctrl+C для выхода"
)

msg() {
  local key="$1"
  local default="${2:-}"
  echo "${MSG[$key]:-$default}"
}

info() { echo -e "ℹ️  $*"; }
success() { echo -e "✅ $*"; }
warning() { echo -e "⚠️  $*"; }
err() { echo -e "❌ $*" >&2; exit 1; }

# ══════════════════════════════════════════════════════════════
# Утилиты мониторинга
# ══════════════════════════════════════════════════════════════

# Получение загрузки CPU
get_cpu_usage() {
  local cpu_usage
  cpu_usage=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0")

  # Если top не вернул, пробуем другой метод
  if [[ -z "$cpu_usage" ]] || [[ "$cpu_usage" == "0" ]]; then
    cpu_usage=$(vmstat 1 2 2>/dev/null | tail -1 | awk '{print 100 - $15}' || echo "0")
  fi

  echo "${cpu_usage:-0}"
}

# Получение использования RAM
get_ram_usage() {
  local total used percent
  total=$(free -m | awk '/^Mem:/ {print $2}')
  used=$(free -m | awk '/^Mem:/ {print $3}')

  if [[ "$total" -gt 0 ]]; then
    percent=$((used * 100 / total))
  else
    percent=0
  fi

  echo "${used}/${total} MB (${percent}%)"
}

# Получение использования диска
get_disk_usage() {
  local disk_info
  disk_info=$(df -h / 2>/dev/null | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')
  echo "${disk_info:-N/A}"
}

# Получение uptime
get_uptime() {
  local uptime_seconds days hours minutes

  if [[ -f /proc/uptime ]]; then
    uptime_seconds=$(cut -d' ' -f1 /proc/uptime | cut -d'.' -f1)
    days=$((uptime_seconds / 86400))
    hours=$(((uptime_seconds % 86400) / 3600))
    minutes=$(((uptime_seconds % 3600) / 60))

    if [[ "$days" -gt 0 ]]; then
      echo "${days}д ${hours}ч ${minutes}м"
    elif [[ "$hours" -gt 0 ]]; then
      echo "${hours}ч ${minutes}м"
    else
      echo "${minutes}м"
    fi
  else
    echo "N/A"
  fi
}

# Проверка статуса сервиса
check_service_status() {
  local service="$1"
  if systemctl is-active --quiet "$service" 2>/dev/null; then
    echo "🟢"
  else
    echo "🔴"
  fi
}

# Получение статуса сервиса текстом
get_service_status_text() {
  local service="$1"
  if systemctl is-active --quiet "$service" 2>/dev/null; then
    echo "${MSG[MSG_RUNNING]}"
  else
    echo "${MSG[MSG_STOPPED]}"
  fi
}

# Получение количества активных пользователей
get_active_users() {
  local count=0

  if [[ -f "${MARZBAN_DIR}/db.sqlite3" ]]; then
    count=$(sqlite3 "${MARZBAN_DIR}/db.sqlite3" \
      "SELECT COUNT(*) FROM users WHERE status='active';" 2>/dev/null || echo "0")
  fi

  echo "${count:-0}"
}

# Получение последних логов
get_recent_logs() {
  local service="$1"
  local lines="${2:-5}"

  journalctl -u "$service" --no-pager -n "$lines" 2>/dev/null | tail -n "$lines" || echo "  ${MSG[MSG_NO_DATA]}"
}

# Визуальная шкала загрузки
draw_bar() {
  local percent="$1"
  local width="${2:-20}"
  local filled empty bar

  # Ограничиваем процент
  percent=$((percent > 100 ? 100 : percent))
  percent=$((percent < 0 ? 0 : percent))

  filled=$((percent * width / 100))
  empty=$((width - filled))

  bar=""
  for ((i=0; i<filled; i++)); do bar+="█"; done
  for ((i=0; i<empty; i++)); do bar+="░"; done

  echo "${bar}"
}

# ══════════════════════════════════════════════════════════════
# Отображение секций мониторинга
# ══════════════════════════════════════════════════════════════

print_header() {
  clear
  echo "══════════════════════════════════════════════════════════"
  echo "           ${MSG[TITLE_MONITOR]}"
  echo "           $(date '+%Y-%m-%d %H:%M:%S')"
  echo "══════════════════════════════════════════════════════════"
  echo ""
}

print_system_resources() {
  local cpu_usage ram_usage disk_usage uptime_info
  local ram_percent disk_percent

  cpu_usage=$(get_cpu_usage)
  ram_usage=$(get_ram_usage)
  disk_usage=$(get_disk_usage)
  uptime_info=$(get_uptime)

  # Извлекаем проценты
  ram_percent=$(echo "$ram_usage" | grep -oP '\d+(?=%)' | tail -1 || echo "0")
  disk_percent=$(echo "$disk_usage" | grep -oP '\d+(?=%)' | tail -1 || echo "0")

  echo "  ${MSG[TITLE_SYSTEM]}"
  echo "  ────────────────────────────────────────────────────────"

  # CPU
  local cpu_bar
  cpu_bar=$(draw_bar "${cpu_usage%.*}")
  printf "  CPU:    %6s%%  %s\n" "${cpu_usage%.*}" "${cpu_bar}"

  # RAM
  local ram_bar
  ram_bar=$(draw_bar "$ram_percent")
  printf "  RAM:    %6s%%  %s  [%s]\n" "$ram_percent" "${ram_bar}" "$ram_usage"

  # Disk
  local disk_bar
  disk_bar=$(draw_bar "$disk_percent")
  printf "  Disk:   %6s%%  %s  [%s]\n" "$disk_percent" "${disk_bar}" "$disk_usage"

  # Uptime
  printf "  Uptime: %s\n" "$uptime_info"
  echo ""
}

print_services_status() {
  echo "  ${MSG[TITLE_SERVICES]}"
  echo "  ────────────────────────────────────────────────────────"

  local services=("marzban" "sing-box" "cubiveil-bot" "ufw" "fail2ban")

  for service in "${services[@]}"; do
    local status status_text
    status=$(check_service_status "$service")
    status_text=$(get_service_status_text "$service")
    printf "  %s %-20s %s\n" "$status" "$service" "$status_text"
  done
  echo ""
}

print_network_info() {
  echo "  ${MSG[TITLE_NETWORK]}"
  echo "  ────────────────────────────────────────────────────────"

  # Внешний IP
  local external_ip
  external_ip=$(curl -sf --max-time 5 https://api4.ipify.org 2>/dev/null || echo "N/A")
  printf "  External IP:  %s\n" "$external_ip"

  # Внутренний IP
  local internal_ip
  internal_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "N/A")
  printf "  Internal IP:  %s\n" "$internal_ip"

  # Открытые порты CubiVeil
  printf "  Open ports:   "
  local ports
  ports=$(ss -tlnp 2>/dev/null | grep -E "(marzban|sing-box|443)" | awk '{print $4}' | grep -oP ':\K\d+' | sort -u | tr '\n' ' ' || echo "N/A")
  echo "${ports:-N/A}"

  # Активные подключения
  local connections
  connections=$(ss -tn state established 2>/dev/null | wc -l || echo "0")
  printf "  Connections:  %s active\n" "$connections"
  echo ""
}

print_users_info() {
  local active_users
  active_users=$(get_active_users)

  echo "  ${MSG[TITLE_USERS]}"
  echo "  ────────────────────────────────────────────────────────"
  printf "  %s: %s\n" "${MSG[MSG_USERS_ONLINE]}" "$active_users"
  echo ""
}

print_recent_events() {
  echo "  ${MSG[TITLE_LOGS]}"
  echo "  ────────────────────────────────────────────────────────"

  # Последние события от каждого сервиса
  echo "  Marzban:"
  get_recent_logs "marzban" 3 | sed 's/^/    /'

  echo ""
  echo "  Sing-box:"
  get_recent_logs "sing-box" 3 | sed 's/^/    /'

  echo ""
  echo "  CubiVeil Bot:"
  get_recent_logs "cubiveil-bot" 3 | sed 's/^/    /'

  echo ""
}

print_footer() {
  echo "══════════════════════════════════════════════════════════"
  echo "  ${MSG[PROMPT_QUIT]}"
  echo "══════════════════════════════════════════════════════════"
}

# ══════════════════════════════════════════════════════════════
# Главный цикл мониторинга
# ══════════════════════════════════════════════════════════════

monitor_loop() {
  local interval="${1:-$REFRESH_INTERVAL}"

  # Обработка прерывания
  trap 'echo ""; info "${MSG[ERR_INTERRUPTED]}"; exit 0' INT TERM

  while true; do
    print_header
    print_system_resources
    print_services_status
    print_network_info
    print_users_info
    print_recent_events
    print_footer

    sleep "$interval"
  done
}

# ══════════════════════════════════════════════════════════════
# Однократный вывод (snapshot)
# ══════════════════════════════════════════════════════════════

print_snapshot() {
  print_header
  print_system_resources
  print_services_status
  print_network_info
  print_users_info
  print_recent_events
  print_footer
}

# ══════════════════════════════════════════════════════════════
# Проверка окружения
# ══════════════════════════════════════════════════════════════

step_check_environment() {
  if [[ $EUID -ne 0 ]]; then
    err "${MSG[ERR_NOT_ROOT]}"
  fi

  # Проверка необходимых утилит
  for cmd in free df ss journalctl; do
    if ! command -v "$cmd" &>/dev/null; then
      warning "Утилита ${cmd} не найдена — некоторые данные могут быть недоступны"
    fi
  done

  success "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════

main() {
  select_language

  # Парсинг аргументов
  local mode="monitor"
  local interval="$REFRESH_INTERVAL"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --snapshot|-s)
        mode="snapshot"
        shift
        ;;
      --interval|-i)
        interval="${2:-$REFRESH_INTERVAL}"
        shift 2
        ;;
      --help|-h)
        echo "Использование: $0 [опции]"
        echo ""
        echo "Опции:"
        echo "  --snapshot, -s   Однократный вывод (не обновлять)"
        echo "  --interval, -i N Интервал обновления в секундах (по умолчанию: ${REFRESH_INTERVAL})"
        echo "  --help, -h       Показать эту справку"
        exit 0
        ;;
      *)
        err "Неизвестный аргумент: $1"
        ;;
    esac
  done

  step_check_environment

  if [[ "$mode" == "snapshot" ]]; then
    print_snapshot
  else
    info "${MSG[PROMPT_REFRESH]}: ${interval}с"
    monitor_loop "$interval"
  fi
}

main "$@"
