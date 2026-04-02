#!/bin/bash
# shellcheck disable=SC1071
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Common Functions                      ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Общие функции для всех скриптов проекта                  ║
# ║  - Утилиты проверки окружения                             ║
# ║  - Работа с файмами и сетью                               ║
# ║  - Логирование                                            ║
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

# Проверка root без выхода (возвращает 0/1)
is_root() {
  [[ $EUID -eq 0 ]]
}

# Проверка root с выходом при ошибке
check_root() {
  if ! is_root; then
    if [[ "${LANG_NAME:-}" == "Русский" ]]; then
      err "Скрипт требует прав root. Запустите с sudo"
    else
      err "Script requires root privileges. Run with sudo"
    fi
  fi
}

# Проверка Ubuntu без выхода (возвращает 0/1)
is_ubuntu() {
  grep -qi "ubuntu" /etc/os-release
}

# Проверка Ubuntu с выходом при ошибке
check_ubuntu() {
  if ! is_ubuntu; then
    if [[ "${LANG_NAME:-}" == "Русский" ]]; then
      err "Этот скрипт предназначен только для Ubuntu"
    else
      err "This script is designed for Ubuntu only"
    fi
  fi
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
  local level="${1:-INFO}"
  local message="${2:-}"
  local log_file="${3:-/var/log/cubiveil.log}"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >>"$log_file"
}

log_info() { log_message "INFO" "$1" "${2:-}"; }
log_warn() { log_message "WARN" "$1" "${2:-}"; }
log_error() { log_message "ERROR" "$1" "${2:-}"; }
