#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Common Utilities                     ║
# ║          github.com/cubiculus/cubiveil                   ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Определение директории скрипта ──────────────────────────────
UTILS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Подключение локализации (если доступно) ───────────────────────
if [[ -f "${UTILS_SCRIPT_DIR}/i18n.sh" ]]; then
  source "${UTILS_SCRIPT_DIR}/i18n.sh"
fi

# ── Подключение модуля валидации ──────────────────────────────────
if [[ -f "${UTILS_SCRIPT_DIR}/validation.sh" ]]; then
  source "${UTILS_SCRIPT_DIR}/validation.sh"
fi

# ── Генераторы случайных значений ────────────────────────────
gen_random() {
  LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$1" | head -n 1
}

gen_hex() {
  LC_ALL=C tr -dc 'a-f0-9' </dev/urandom | fold -w "$1" | head -n 1
}

gen_port() {
  shuf -i 30000-62000 -n 1
}

# ── Управление портами ───────────────────────────────────────
declare -A USED_PORTS_MAP
USED_PORTS_MAP[443]=1

unique_port() {
  local p
  local max_attempts=50
  local attempts=0

  while [[ $attempts -lt $max_attempts ]]; do
    p=$(gen_port)
    # Валидация порта через модуль validation.sh
    if ! validate_port "$p"; then
      ((attempts++))
      continue
    fi
    # Быстрая проверка через ассоциативный массив вместо grep в цикле
    if [[ -z "${USED_PORTS_MAP[$p]:-}" ]] &&
      ! ss -tlnp 2>/dev/null | grep -q ":${p} "; then
      USED_PORTS_MAP[$p]=1
      echo "$p"
      return
    fi
    ((attempts++))
  done

  local msg
  if declare -f get_str >/dev/null; then
    msg=$(get_str "MSG_ERR_NO_FREE_PORT" | sed "s/{MAX}/${max_attempts}/")
  else
    msg="Failed to find free port after ${max_attempts} attempts"
  fi
  err "$msg"
}

open_port() {
  local port="$1"
  local proto="${2:-tcp}"
  local comment="${3:-cubiveil}"

  # Валидация порта через модуль validation.sh
  if ! validate_port "$port"; then
    local msg
    if declare -f get_str >/dev/null; then
      msg=$(get_str "MSG_ERR_INVALID_PORT" | sed "s/{PORT}/${port}/")
    else
      msg="Invalid port: ${port}"
    fi
    err "$msg"
  fi

  if ! ufw allow "${port}/${proto}" comment "${comment}" >/dev/null 2>&1; then
    # Пробуем без comment (некоторые версии ufw не поддерживают)
    if ! ufw allow "${port}/${proto}" >/dev/null 2>&1; then
      local msg
      if declare -f get_str >/dev/null; then
        msg=$(get_str "MSG_ERR_OPEN_PORT" | sed "s/{PORT}/${port}/" | sed "s/{PROTO}/${proto}/")
      else
        msg="Failed to open port ${port}/${proto} in firewall"
      fi
      err "$msg"
    fi
  fi
}

close_port() {
  local port="$1"
  local proto="${2:-tcp}"
  ufw delete allow "${port}/${proto}" >/dev/null 2>&1 || true
}

# ── Системная информация ───────────────────────────────────────
arch() {
  local arch_name
  arch_name=$(uname -m)

  case "$arch_name" in
  x86_64 | amd64) echo 'amd64' ;;
  aarch64 | arm64) echo 'arm64' ;;
  *)
    local msg
    if declare -f get_str >/dev/null; then
      msg=$(get_str "MSG_ERR_UNKNOWN_ARCH" | sed "s/{ARCH}/${arch_name}/")
    else
      msg="Unknown architecture: ${arch_name}"
    fi
    err "$msg"
    ;;
  esac
}

# ── Получение внешнего IP ───────────────────────────────────────
# Обёртка над get_external_ip из lib/common.sh для обратной совместимости
get_server_ip() {
  if declare -f get_external_ip >/dev/null; then
    get_external_ip
  else
    # Fallback, если common.sh ещё не подключён
    local ip
    for url in "https://api4.ipify.org" "https://ipv4.icanhazip.com" "https://4.ident.me"; do
      ip=$(curl -sf --max-time 4 "$url" 2>/dev/null | tr -d '[:space:]')
      if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
      fi
    done
    return 1
  fi
}
