#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║           CubiVeil — Common Utilities                    ║
# ║         github.com/cubiculus/cubiveil                     ║
# ╚═══════════════════════════════════════════════════════════╝

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
USED_PORTS=(443)

unique_port() {
  local p
  local max_attempts=50
  local attempts=0

  while [[ $attempts -lt $max_attempts ]]; do
    p=$(gen_port)
    # Проверка: не используется ли порт в списке и не занят ли процессом
    if [[ ! " ${USED_PORTS[*]} " =~ ${p} ]] &&
      ! ss -tlnp 2>/dev/null | grep -q ":${p} "; then
      USED_PORTS+=("$p")
      echo "$p"
      return
    fi
    ((attempts++))
  done

  if [[ "$LANG_NAME" == "Русский" ]]; then
    err "Не удалось найти свободный порт после ${max_attempts} попыток"
  else
    err "Failed to find free port after ${max_attempts} attempts"
  fi
}

open_port() {
  local port="$1"
  local proto="${2:-tcp}"
  local comment="${3:-cubiveil}"

  if ! ufw allow "${port}/${proto}" comment "${comment}" >/dev/null 2>&1; then
    # Пробуем без comment (некоторые версии ufw не поддерживают)
    if ! ufw allow "${port}/${proto}" >/dev/null 2>&1; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        err "Не удалось открыть порт ${port}/${proto} в файрволе"
      else
        err "Failed to open port ${port}/${proto} in firewall"
      fi
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
  case "$(uname -m)" in
  x86_64 | amd64) echo 'amd64' ;;
  aarch64 | arm64) echo 'arm64' ;;
  *) err "Неизвестная архитектура: $(uname -m)" ;;
  esac
}

get_server_ip() {
  local ip
  for url in https://api4.ipify.org https://ipv4.icanhazip.com https://4.ident.me; do
    ip=$(curl -s --max-time 4 "$url" 2>/dev/null | tr -d '[:space:]')
    [[ -n "$ip" ]] && echo "$ip" && return
  done
  echo ""
}
