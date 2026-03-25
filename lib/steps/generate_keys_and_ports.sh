#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Generate Keys and Ports         ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Генерация ключей Reality и портов                         ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# Подключаем utils
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# ── Функции / Functions ──────────────────────────────────────

# Генерация Reality keypair
generate_reality_keypair() {
  log_step "generate_reality_keypair" "Generating Reality keypair"

  local KEYPAIR
  KEYPAIR=$(sing-box generate reality-keypair)
  REALITY_PRIVATE_KEY=$(echo "$KEYPAIR" | grep 'PrivateKey' | awk '{print $2}')
  REALITY_PUBLIC_KEY=$(echo "$KEYPAIR" | grep 'PublicKey' | awk '{print $2}')
  REALITY_SHORT_ID=$(gen_hex 8)

  log_debug "Reality keypair generated"
}

# Выбор случайного camouflage (CDN)
generate_reality_camouflage() {
  log_step "generate_reality_camouflage" "Selecting Reality camouflage"

  local CDN_LIST=(
    "dl.google.com"
    "ajax.aspnetcdn.com"
    "www.fastly.com"
    "cdn.jsdelivr.net"
    "cdnjs.cloudflare.com"
    "static.cloudflareinsights.com"
    "ajax.googleapis.com"
  )
  REALITY_SNI="${CDN_LIST[$((RANDOM % ${#CDN_LIST[@]}))]}"

  log_debug "Reality camouflage: ${REALITY_SNI}"
}

# Генерация UUID для профилей
generate_profile_uuids() {
  log_step "generate_profile_uuids" "Generating UUIDs for profiles"

  export UUID_VLESS_TCP
  UUID_VLESS_TCP=$(sing-box generate uuid)
  export UUID_VLESS_GRPC
  UUID_VLESS_GRPC=$(sing-box generate uuid)
  export UUID_HY2
  UUID_HY2=$(sing-box generate uuid)
  export UUID_TROJAN
  UUID_TROJAN=$(sing-box generate uuid)
  SS_PASSWORD=$(gen_random 32)

  log_debug "UUIDs generated for profiles"
}

# Генерация уникальных портов
generate_ports() {
  log_step "generate_ports" "Generating unique ports"

  TROJAN_PORT=$(unique_port)
  SS_PORT=$(unique_port)
  PANEL_PORT=$(unique_port)
  SUB_PORT=$(unique_port)

  log_debug "Ports: Trojan=${TROJAN_PORT}, SS=${SS_PORT}, Panel=${PANEL_PORT}, Sub=${SUB_PORT}"
}

# Открытие портов в файрволе
open_generated_ports() {
  log_step "open_generated_ports" "Opening ports in firewall"

  open_port "$TROJAN_PORT" tcp "Trojan WebSocket TLS"
  open_port "$SS_PORT" tcp "Shadowsocks 2022"
  open_port "$PANEL_PORT" tcp "Marzban Panel"
  open_port "$SUB_PORT" tcp "Subscription Link"

  log_debug "Ports opened in firewall"
}

# Основная функция шага (вызывается из install-steps.sh)
step_generate_keys_and_ports() {
  step_title "8" "Ключи Reality и порты" "Reality keypair and ports"

  generate_reality_keypair
  generate_reality_camouflage
  generate_profile_uuids
  generate_ports
  open_generated_ports

  ok "Reality keypair сгенерирован, camouflage: ${REALITY_SNI}"
  ok "Порты → Trojan:${TROJAN_PORT} SS:${SS_PORT} Панель:${PANEL_PORT} Подписки:${SUB_PORT}"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { :; }
module_configure() { step_generate_keys_and_ports; }
module_enable() { :; }
module_disable() { :; }
