#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Profile Manager                       ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Управление профилями прокси: добавление, удаление,       ║
# ║  генерация QR-кодов, статистика использования             ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Подключаем i18n модуль для единых функций локализации
if [[ -f "${PROJECT_DIR}/lib/i18n.sh" ]]; then
  source "${PROJECT_DIR}/lib/i18n.sh"
elif [[ -f "${PROJECT_DIR}/lang.sh" ]]; then
  source "${PROJECT_DIR}/lang.sh"
else
  source "${PROJECT_DIR}/lib/fallback.sh"
fi

# ── Подключение унифицированных функций вывода ───────────────
source "${PROJECT_DIR}/lib/output.sh" || {
  echo "❌ Не удалось загрузить lib/output.sh" >&2
  exit 1
}

# ── Подключение общих утилит ───────────────────────────────────
source "${PROJECT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}

# ── Константы ─────────────────────────────────────────────────
MARZBAN_DIR="/opt/marzban"
# shellcheck disable=SC2034
MARZBAN_CLI="marzban-cli"
# shellcheck disable=SC2034
PYTHON="/opt/marzban/bin/python3"

# ── Локализация сообщений ─────────────────────────────────────
declare -A MSG=(
  [TITLE_PROFILES]="CubiVeil — Profile Manager"
  [TITLE_LIST]="Список профилей"
  [TITLE_ADD]="Добавление профиля"
  [TITLE_REMOVE]="Удаление профиля"
  [TITLE_ENABLE]="Включение профиля"
  [TITLE_DISABLE]="Выключение профиля"
  [TITLE_QR]="Генерация QR-кода"
  [TITLE_STATS]="Статистика использования"
  [TITLE_INFO]="Информация о профиле"

  [MSG_PROFILE]="Профиль"
  [MSG_USERNAME]="Имя пользователя"
  [MSG_STATUS]="Статус"
  [MSG_USED]="Использовано"
  [MSG_REMAINING]="Осталось"
  [MSG_EXPIRY]="Истекает"
  [MSG_TOTAL]="Всего"
  [MSG_ACTIVE]="активен"
  [MSG_DISABLED]="отключён"
  [MSG_LIMITED]="ограничен"
  [MSG_EXPIRED]="истёк"
  [MSG_CREATED]="создан"
  [MSG_DELETED]="удалён"
  [MSG_ENABLED]="включён"
  [MSG_DISABLED_ACTION]="отключён"

  [ERR_NOT_ROOT]="Требуется запуск от root"
  [ERR_MARZBAN_NOT_FOUND]="Marzban не найден"
  [ERR_USER_NOT_FOUND]="Пользователь не найден"
  [ERR_PROFILE_EXISTS]="Пользователь уже существует"
  [ERR_QR_FAILED]="Не удалось сгенерировать QR-код"

  [PROMPT_USERNAME]="Введите имя пользователя"
  [PROMPT_CONFIRM]="Вы уверены"
  [PROMPT_DATA_LIMIT]="Лимит данных (GB, 0 = безлимит)"
  [PROMPT_DAYS_LIMIT]="Лимит дней (0 = безлимит)"

  [CMD_LIST]="list"
  [CMD_ADD]="add"
  [CMD_REMOVE]="remove"
  [CMD_ENABLE]="enable"
  [CMD_DISABLE]="disable"
  [CMD_QR]="qr"
  [CMD_STATS]="stats"
  [CMD_INFO]="info"
  [CMD_HELP]="help"
)

# Функции msg и step_title импортируются из lib/i18n.sh

# ══════════════════════════════════════════════════════════════
# Утилиты для работы с Marzban API
# ══════════════════════════════════════════════════════════════

# Получение токена администратора
get_admin_token() {
  local username password base_url

  if [[ -f "${MARZBAN_DIR}/.env" ]]; then
    username=$(grep -E "^SUDO_USERNAME=" "${MARZBAN_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "")
    password=$(grep -E "^SUDO_PASSWORD=" "${MARZBAN_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "")
    base_url=$(grep -E "^MARZBAN_HOST=" "${MARZBAN_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "localhost")
  fi

  if [[ -z "$username" ]] || [[ -z "$password" ]]; then
    err "${MSG[ERR_MARZBAN_NOT_FOUND]}"
  fi

  # Получаем токен через API
  local token
  token=$(curl -sf -X POST "https://${base_url}/api/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${username}&password=${password}" \
    2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || echo "")

  if [[ -z "$token" ]]; then
    err "Не удалось получить токен доступа"
  fi

  echo "$token"
}

# Получение базового URL API
get_api_url() {
  local base_url
  if [[ -f "${MARZBAN_DIR}/.env" ]]; then
    base_url=$(grep -E "^MARZBAN_HOST=" "${MARZBAN_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "localhost")
  fi
  echo "https://${base_url}"
}

# ══════════════════════════════════════════════════════════════
# Функции управления профилями
# ══════════════════════════════════════════════════════════════

# Список всех профилей
list_profiles() {
  step_title "" "${MSG[TITLE_LIST]}" "${MSG[TITLE_LIST]}"

  local token api_url
  token=$(get_admin_token)
  api_url=$(get_api_url)

  info "Получение списка профилей..."

  local users
  users=$(curl -sf -X GET "${api_url}/api/users" \
    -H "Authorization: Bearer ${token}" \
    2>/dev/null || echo '{"users":[],"total":0}')

  local total
  total=$(echo "$users" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',0))" 2>/dev/null || echo "0")

  echo ""
  printf "  %-20s %-12s %-15s %-20s\n" \
    "${MSG[MSG_USERNAME]}" "${MSG[MSG_STATUS]}" "${MSG[MSG_USED]}" "${MSG[MSG_EXPIRY]}"
  echo "  ──────────────────────────────────────────────────────────────────"

  echo "$users" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for user in data.get('users', []):
    username = user.get('username', 'N/A')[:18]
    status = user.get('status', 'unknown')
    used = user.get('used_traffic', 0)
    used_gb = used / (1024**3)

    # Статус
    status_map = {'active': '🟢 active', 'disabled': '🔴 disabled',
                  'limited': '🟡 limited', 'expired': '🔴 expired'}
    status_display = status_map.get(status, status)

    # Трафик
    if used_gb < 1:
        used_display = f'{used_gb*1024:.0f} MB'
    else:
        used_display = f'{used_gb:.2f} GB'

    # Срок действия
    expiry = user.get('expire', 0)
    if expiry:
        from datetime import datetime
        exp_date = datetime.fromtimestamp(expiry)
        expiry_display = exp_date.strftime('%Y-%m-%d')
    else:
        expiry_display = '∞'

    print(f'  {username:<20} {status_display:<12} {used_display:<15} {expiry_display}')
" 2>/dev/null || warning "  Не удалось получить данные"

  echo ""
  info "${MSG[MSG_TOTAL]}: ${total}"
}

# Добавление нового профиля
add_profile() {
  step_title "" "${MSG[TITLE_ADD]}" "${MSG[TITLE_ADD]}"

  local username data_limit days_limit

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  else
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  fi

  if [[ -z "$username" ]]; then
    err "Имя пользователя не может быть пустым"
  fi

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_DATA_LIMIT]}: " data_limit
    read -rp "  ${MSG[PROMPT_DAYS_LIMIT]}: " days_limit
  else
    read -rp "  ${MSG[PROMPT_DATA_LIMIT]}: " data_limit
    read -rp "  ${MSG[PROMPT_DAYS_LIMIT]}: " days_limit
  fi

  data_limit=${data_limit:-0}
  days_limit=${days_limit:-0}

  # Конвертируем в байты и секунды
  local data_limit_bytes=$((data_limit * 1024 * 1024 * 1024))
  local expire_date=0
  if [[ "$days_limit" -gt 0 ]]; then
    expire_date=$(($(date +%s) + days_limit * 86400))
  fi

  local token api_url
  token=$(get_admin_token)
  api_url=$(get_api_url)

  info "Создание профиля: ${username}..."

  local response
  response=$(curl -sf -X POST "${api_url}/api/user" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"${username}\",
      \"status\": \"active\",
      \"data_limit\": ${data_limit_bytes},
      \"expire\": ${expire_date}
    }" 2>/dev/null || echo "")

  if [[ -n "$response" ]]; then
    success "${MSG[MSG_PROFILE]} ${username} ${MSG[MSG_CREATED]}"

    # Показываем ссылку для подключения
    local subscription_url
    subscription_url=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('subscription_url',''))" 2>/dev/null || echo "")

    if [[ -n "$subscription_url" ]]; then
      echo ""
      info "Subscription URL:"
      echo "  ${subscription_url}"
    fi
  else
    err "${MSG[ERR_PROFILE_EXISTS]}"
  fi
}

# Удаление профиля
remove_profile() {
  step_title "" "${MSG[TITLE_REMOVE]}" "${MSG[TITLE_REMOVE]}"

  local username

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  else
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  fi

  if [[ -z "$username" ]]; then
    err "Имя пользователя не может быть пустым"
  fi

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_CONFIRM]}? [y/N]: " confirm
  else
    read -rp "  ${MSG[PROMPT_CONFIRM]}? [y/N]: " confirm
  fi

  if [[ "${confirm,,}" != "y" ]]; then
    info "Удаление отменено"
    return 0
  fi

  local token api_url
  token=$(get_admin_token)
  api_url=$(get_api_url)

  info "Удаление профиля: ${username}..."

  local response
  local curl_status
  response=$(curl -sf -X DELETE "${api_url}/api/user/${username}" \
    -H "Authorization: Bearer ${token}" \
    2>/dev/null || echo "")
  curl_status=$?

  if [[ -n "$response" ]] || [[ $curl_status -eq 0 ]]; then
    success "${MSG[MSG_PROFILE]} ${username} ${MSG[MSG_DELETED]}"
  else
    err "${MSG[ERR_USER_NOT_FOUND]}"
  fi
}

# Включение профиля
enable_profile() {
  step_title "" "${MSG[TITLE_ENABLE]}" "${MSG[TITLE_ENABLE]}"

  local username

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  else
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  fi

  if [[ -z "$username" ]]; then
    err "Имя пользователя не может быть пустым"
  fi

  local token api_url
  token=$(get_admin_token)
  api_url=$(get_api_url)

  info "Включение профиля: ${username}..."

  local response
  response=$(curl -sf -X PUT "${api_url}/api/user/${username}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d '{"status": "active"}' 2>/dev/null || echo "")

  if [[ -n "$response" ]]; then
    success "${MSG[MSG_PROFILE]} ${username} ${MSG[MSG_ENABLED]}"
  else
    err "${MSG[ERR_USER_NOT_FOUND]}"
  fi
}

# Выключение профиля
disable_profile() {
  step_title "" "${MSG[TITLE_DISABLE]}" "${MSG[TITLE_DISABLE]}"

  local username

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  else
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  fi

  if [[ -z "$username" ]]; then
    err "Имя пользователя не может быть пустым"
  fi

  local token api_url
  token=$(get_admin_token)
  api_url=$(get_api_url)

  info "Выключение профиля: ${username}..."

  local response
  response=$(curl -sf -X PUT "${api_url}/api/user/${username}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d '{"status": "disabled"}' 2>/dev/null || echo "")

  if [[ -n "$response" ]]; then
    success "${MSG[MSG_PROFILE]} ${username} ${MSG[MSG_DISABLED_ACTION]}"
  else
    err "${MSG[ERR_USER_NOT_FOUND]}"
  fi
}

# Генерация QR-кода
generate_qr() {
  step_title "" "${MSG[TITLE_QR]}" "${MSG[TITLE_QR]}"

  local username

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  else
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  fi

  if [[ -z "$username" ]]; then
    err "Имя пользователя не может быть пустым"
  fi

  local token api_url
  token=$(get_admin_token)
  api_url=$(get_api_url)

  info "Генерация QR-кода для: ${username}..."

  # Получаем ссылки для подключения
  local user_data
  user_data=$(curl -sf -X GET "${api_url}/api/user/${username}" \
    -H "Authorization: Bearer ${token}" \
    2>/dev/null || echo "")

  if [[ -z "$user_data" ]]; then
    err "${MSG[ERR_USER_NOT_FOUND]}"
  fi

  # Извлекаем ссылки
  local links
  links=$(echo "$user_data" | python3 -c "
import sys, json
data = json.load(sys.stdin)
links = data.get('links', [])
for link in links:
    print(link)
" 2>/dev/null || echo "")

  if [[ -z "$links" ]]; then
    # Пробуем subscription_url
    links=$(echo "$user_data" | python3 -c "import sys,json; print(json.load(sys.stdin).get('subscription_url',''))" 2>/dev/null || echo "")
  fi

  if [[ -z "$links" ]]; then
    err "${MSG[ERR_QR_FAILED]}"
  fi

  # Проверяем наличие qrencode
  if ! command -v qrencode &>/dev/null; then
    warning "qrencode не установлен. Установка..."
    apt-get update && apt-get install -y qrencode >/dev/null 2>&1 || true
  fi

  if command -v qrencode &>/dev/null; then
    echo ""
    info "QR-код:"
    echo "$links" | head -1 | qrencode -t UTF8 2>/dev/null ||
      echo "$links" | head -1 | qrencode -o - 2>/dev/null ||
      warning "Не удалось сгенерировать QR-код"

    echo ""
    info "Ссылка для подключения:"
    echo "  $links" | head -1
  else
    info "Ссылка для подключения (установите qrencode для QR-кода):"
    echo "  $links" | head -1
  fi
}

# Статистика использования
show_stats() {
  step_title "" "${MSG[TITLE_STATS]}" "${MSG[TITLE_STATS]}"

  local username=""

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_USERNAME]} (Enter для всех): " username
  else
    read -rp "  ${MSG[PROMPT_USERNAME]} (Enter for all): " username
  fi

  local token api_url
  token=$(get_admin_token)
  api_url=$(get_api_url)

  if [[ -n "$username" ]]; then
    # Статистика конкретного пользователя
    local user_data
    user_data=$(curl -sf -X GET "${api_url}/api/user/${username}" \
      -H "Authorization: Bearer ${token}" \
      2>/dev/null || echo "")

    if [[ -z "$user_data" ]]; then
      err "${MSG[ERR_USER_NOT_FOUND]}"
    fi

    echo ""
    echo "$user_data" | python3 -c "
import sys, json
from datetime import datetime

data = json.load(sys.stdin)
username = data.get('username', 'N/A')
status = data.get('status', 'unknown')
used = data.get('used_traffic', 0)
data_limit = data.get('data_limit', 0)
expire = data.get('expire', 0)
created_at = data.get('created_at', '')

used_gb = used / (1024**3)
limit_gb = data_limit / (1024**3) if data_limit else '∞'

print(f'  Профиль: {username}')
print(f'  Статус: {status}')
print(f'  Использовано: {used_gb:.2f} GB / {limit_gb} GB')

if expire:
    exp_date = datetime.fromtimestamp(expire)
    days_left = (exp_date - datetime.now()).days
    print(f'  Истекает: {exp_date.strftime(\"%Y-%m-%d\")} (дней: {days_left})')
else:
    print('  Истекает: никогда')

print(f'  Создан: {created_at}')
" 2>/dev/null || warning "Не удалось получить статистику"
  else
    # Общая статистика
    info "Общая статистика..."

    local stats
    stats=$(curl -sf -X GET "${api_url}/api/users" \
      -H "Authorization: Bearer ${token}" \
      2>/dev/null || echo '{"users":[],"total":0}')

    echo ""
    echo "$stats" | python3 -c "
import sys, json

data = json.load(sys.stdin)
total = data.get('total', 0)
users = data.get('users', [])

active = sum(1 for u in users if u.get('status') == 'active')
disabled = sum(1 for u in users if u.get('status') == 'disabled')
limited = sum(1 for u in users if u.get('status') == 'limited')
expired = sum(1 for u in users if u.get('status') == 'expired')

total_used = sum(u.get('used_traffic', 0) for u in users)
total_used_gb = total_used / (1024**3)

print(f'  Всего профилей: {total}')
print(f'  Активных: {active}')
print(f'  Отключенных: {disabled}')
print(f'  Ограниченных: {limited}')
print(f'  Истёкших: {expired}')
print(f'  Общий трафик: {total_used_gb:.2f} GB')
" 2>/dev/null || warning "Не удалось получить статистику"
  fi
}

# Информация о профиле
show_profile_info() {
  step_title "" "${MSG[TITLE_INFO]}" "${MSG[TITLE_INFO]}"

  local username

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  else
    read -rp "  ${MSG[PROMPT_USERNAME]}: " username
  fi

  if [[ -z "$username" ]]; then
    err "Имя пользователя не может быть пустым"
  fi

  local token api_url
  token=$(get_admin_token)
  api_url=$(get_api_url)

  info "Информация о профиле: ${username}..."

  local user_data
  user_data=$(curl -sf -X GET "${api_url}/api/user/${username}" \
    -H "Authorization: Bearer ${token}" \
    2>/dev/null || echo "")

  if [[ -z "$user_data" ]]; then
    err "${MSG[ERR_USER_NOT_FOUND]}"
  fi

  echo ""
  echo "$user_data" | python3 -c "
import sys, json

data = json.load(sys.stdin)

print('  ────────────────────────────────────────────────────────')
for key, value in data.items():
    if key == 'links':
        print(f'  {key}:')
        for link in value:
            print(f'    - {link[:60]}...' if len(link) > 60 else f'    - {link}')
    elif key == 'proxies':
        print(f'  {key}:')
        for proto, config in value.items():
            print(f'    {proto}: {list(config.keys()) if isinstance(config, dict) else config}')
    else:
        print(f'  {key}: {value}')
print('  ────────────────────────────────────────────────────────')
" 2>/dev/null || warning "Не удалось получить информацию"
}

# Справка
show_help() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  CubiVeil — Profile Manager"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo "  Использование: $0 <команда> [аргументы]"
  echo ""
  echo "  Команды:"
  echo "    list              Список всех профилей"
  echo "    add               Добавить новый профиль"
  echo "    remove            Удалить профиль"
  echo "    enable            Включить профиль"
  echo "    disable           Выключить профиль"
  echo "    qr                Сгенерировать QR-код"
  echo "    stats             Статистика использования"
  echo "    info              Информация о профиле"
  echo "    help              Эта справка"
  echo ""
  echo "  Примеры:"
  echo "    $0 list"
  echo "    $0 add"
  echo "    $0 qr username"
  echo "    $0 stats"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Проверка окружения
# ══════════════════════════════════════════════════════════════

step_check_environment() {
  if [[ $EUID -ne 0 ]]; then
    err "${MSG[ERR_NOT_ROOT]}"
  fi

  if [[ ! -d "${MARZBAN_DIR}" ]]; then
    err "${MSG[ERR_MARZBAN_NOT_FOUND]}"
  fi

  # Проверка curl и python3
  for cmd in curl python3; do
    if ! command -v "$cmd" &>/dev/null; then
      err "Требуется ${cmd}"
    fi
  done

  success "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════

main() {
  select_language

  local command="${1:-help}"
  shift || true

  step_check_environment

  case "$command" in
  list | l)
    list_profiles
    ;;
  add | a)
    add_profile
    ;;
  remove | rm | del | delete)
    remove_profile
    ;;
  enable | on)
    enable_profile
    ;;
  disable | off)
    disable_profile
    ;;
  qr | qrcode)
    generate_qr
    ;;
  stats | statistics)
    show_stats
    ;;
  info | i)
    show_profile_info
    ;;
  help | h | --help | -h)
    show_help
    ;;
  *)
    err "Неизвестная команда: ${command}. Используйте '$0 help'"
    ;;
  esac
}

main "$@"
