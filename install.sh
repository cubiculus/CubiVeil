#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║                        CubiVeil                           ║
# ║         github.com/cubiculus/cubiveil                     ║
# ║                                                           ║
# ║  Marzban + Sing-box | 5 profiles                          ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/lang.sh" ]]; then
  source "${SCRIPT_DIR}/lang.sh"
else
  # Fallback если файл локализации отсутствует
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  PLAIN='\033[0m'
  ok() { echo -e "${GREEN}[✓]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[✗]${PLAIN} $1"
    exit 1
  }
  info() { echo -e "${CYAN}[→]${PLAIN} $1"; }
  step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e "${BLUE}  $1${PLAIN}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  }
  step_title() {
    local num="$1"
    local ru="$2"
    local en="$3"
    if [[ "$LANG_NAME" == "Русский" ]]; then
      step "Шаг ${num}/12 — ${ru}"
    else
      step "Step ${num}/12 — ${en}"
    fi
  }
fi

# ── Подключение модулей ───────────────────────────────────────
source "${SCRIPT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}
source "${SCRIPT_DIR}/lib/install-steps.sh" || {
  err "Не удалось загрузить lib/install-steps.sh"
}

# ── Баннер ─────────────────────────────────────────────────────
print_banner() {
  clear
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
  echo -e "${CYAN}  ║            CubiVeil Installer            ║${PLAIN}"
  echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
  echo -e "${CYAN}  ║    Marzban + Sing-box                    ║${PLAIN}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════
main() {
  select_language
  print_banner
  prompt_inputs
  step_check_ip_neighborhood
  step_system_update
  step_auto_updates
  step_bbr
  step_firewall
  step_fail2ban
  step_install_singbox
  step_generate_keys_and_ports
  step_install_marzban
  step_ssl
  step_configure
  step_finish
}

main "$@"
