#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Common Functions                     ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Общие функции для всех скриптов проекта                  ║
# ║  - Проверки окружения (root, ubuntu)                      ║
# ║  - Баннеры                                                 ║
# ║  - Интеграция с security.sh и output.sh                   ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение модулей ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключаем output.sh если ещё не подключён
if [[ -f "${SCRIPT_DIR}/output.sh" ]]; then
  source "${SCRIPT_DIR}/output.sh"
fi

# Подключаем security.sh если ещё не подключён
if [[ -f "${SCRIPT_DIR}/security.sh" ]]; then
  source "${SCRIPT_DIR}/security.sh"
fi

# ── Проверки окружения / Environment checks ──────────────────

# Проверка root прав
# Выходит с ошибкой если не root
check_root() {
  local err_msg="${1:-}"
  local err_msg_ru="${2:-}"
  
  if [[ $EUID -ne 0 ]]; then
    if [[ "${LANG_NAME:-}" == "Русский" ]]; then
      err "${err_msg_ru:-Запускай от root (sudo)}"
    else
      err "${err_msg:-Scripts must be run as root (sudo)}"
    fi
  fi
}

# Проверка что это Ubuntu
# Выходит с ошибкой если не Ubuntu
check_ubuntu() {
  local err_msg="${1:-}"
  local err_msg_ru="${2:-}"
  
  if ! grep -qi "ubuntu" /etc/os-release; then
    if [[ "${LANG_NAME:-}" == "Русский" ]]; then
      err "${err_msg_ru:-Скрипт только для Ubuntu}"
    else
      err "${err_msg:-This script is only for Ubuntu}"
    fi
  fi
}

# Проверка root без выхода (возвращает 0/1)
is_root() {
  [[ $EUID -eq 0 ]]
}

# Проверка Ubuntu без выхода (возвращает 0/1)
is_ubuntu() {
  grep -qi "ubuntu" /etc/os-release
}

# ── Баннеры / Banners ────────────────────────────────────────

# Основной баннер установщика
print_banner() {
  clear
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
  echo -e "${CYAN}  ║            CubiVeil Installer            ║${PLAIN}"
  echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
  if [[ "${LANG_NAME:-}" == "Русский" ]]; then
    echo -e "${CYAN}  ║    Marzban + Sing-box + Telegram бот     ║${PLAIN}"
  else
    echo -e "${CYAN}  ║    Marzban + Sing-box + Telegram Bot     ║${PLAIN}"
  fi
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
  echo ""
}

# Баннер для Telegram бота
print_banner_telegram() {
  clear
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
  echo -e "${CYAN}  ║       CubiVeil Telegram Bot Setup       ║${PLAIN}"
  echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
  if [[ "${LANG_NAME:-}" == "Русский" ]]; then
    echo -e "${CYAN}  ║    Marzban + Sing-box + Telegram бот     ║${PLAIN}"
  else
    echo -e "${CYAN}  ║    Marzban + Sing-box + Telegram Bot     ║${PLAIN}"
  fi
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
  echo ""
}

# Баннер для утилит (monitor, backup, export и т.д.)
print_banner_utility() {
  local utility_name="${1:-Utility}"
  clear
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
  echo -e "${CYAN}  ║        CubiVeil — ${utility_name}          ║${PLAIN}"
  echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
  echo ""
}

# ── Выбор языка / Language selection ─────────────────────────

# Стандартный выбор языка (используется в основных скриптах)
select_language() {
  echo ""
  echo "  Select language / Выберите язык:"
  echo ""
  echo "  1) Русский (Russian)"
  echo "  2) English"
  echo ""

  while true; do
    read -rp "  Enter choice [1-2]: " lang_choice
    case "$lang_choice" in
      1)
        LANG_NAME="Русский"
        return
        ;;
      2)
        LANG_NAME="English"
        return
        ;;
      *)
        warn "Invalid choice / Неверный выбор"
        ;;
    esac
  done
}

# Быстрый выбор языка из аргументов
select_language_fast() {
  local default="${1:-Русский}"
  
  # Проверяем аргументы командной строки
  for arg in "$@"; do
    case "$arg" in
      --lang=ru|--language=ru|-ru)
        LANG_NAME="Русский"
        return
        ;;
      --lang=en|--language=en|-en)
        LANG_NAME="English"
        return
        ;;
    esac
  done
  
  # Если нет аргументов — используем дефолт
  LANG_NAME="$default"
}

# ── Утилиты / Utilities ──────────────────────────────────────

# Проверка команды
# Возвращает 0 если команда доступна, 1 если нет
check_command() {
  local cmd="$1"
  command -v "$cmd" &>/dev/null
}

# Проверка нескольких команд
# Выходит с ошибкой если какая-то команда не найдена
require_commands() {
  local missing=()
  
  for cmd in "$@"; do
    if ! check_command "$cmd"; then
      missing+=("$cmd")
    fi
  done
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    if [[ "${LANG_NAME:-}" == "Русский" ]]; then
      err "Отсутствуют команды: ${missing[*]}. Установи: apt-get install ${missing[*]}"
    else
      err "Missing commands: ${missing[*]}. Install: apt-get install ${missing[*]}"
    fi
  fi
}

# Проверка что сервис существует
check_service_exists() {
  local service="$1"
  systemctl list-unit-files "$service" &>/dev/null
}

# Проверка что сервис активен
is_service_active() {
  local service="$1"
  systemctl is-active --quiet "$service" 2>/dev/null
}

# ── Работа с файлами / File operations ───────────────────────

# Безопасное создание временной директории
# Возвращает путь к директории
create_temp_dir() {
  local prefix="${1:-cubiveil}"
  mktemp -d -t "${prefix}.XXXXXX"
}

# Безопасное удаление временной директории
cleanup_temp_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    rm -rf "$dir"
  fi
}

# Проверка что файл существует и не пустой
validate_file() {
  local file="$1"
  local min_size="${2:-1}"
  
  [[ -f "$file" ]] && [[ -s "$file" ]] && [[ $(stat -c%s "$file") -ge $min_size ]]
}

# ── Сеть / Network ───────────────────────────────────────────

# Проверка доступности хоста
check_host() {
  local host="$1"
  local timeout="${2:-5}"
  
  curl -sf --max-time "$timeout" "https://${host}" &>/dev/null
}

# Получение внешнего IP (быстрое, с fallback)
get_external_ip() {
  local ip
  
  # Пробуем несколько сервисов параллельно
  for url in "https://api4.ipify.org" "https://ipv4.icanhazip.com" "https://4.ident.me"; do
    ip=$(curl -sf --max-time 4 "$url" 2>/dev/null | tr -d '[:space:]')
    if [[ -n "$ip" ]]; then
      echo "$ip"
      return 0
    fi
  done
  
  return 1
}

# ── Логирование / Logging ────────────────────────────────────

# Запись в лог файл
log_message() {
  local level="$1"
  local message="$2"
  local log_file="${3:-/var/log/cubiveil.log}"
  
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "$log_file"
}

log_info() { log_message "INFO" "$1" "$2"; }
log_warn() { log_message "WARN" "$1" "$2"; }
log_error() { log_message "ERROR" "$1" "$2"; }

# ── Обратная совместимость / Backward compatibility ──────────

# Эти функции определены для совместимости со старыми скриптами
# Они дублируются из output.sh и fallback.sh

# step_title уже определён в output.sh
# step уже определён в fallback.sh
# ok, warn, err, info уже определены в output.sh
