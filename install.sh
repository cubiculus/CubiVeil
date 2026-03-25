#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║                        CubiVeil                           ║
# ║                   github.com/cubiculus/cubiveil           ║
# ║                                                           ║
# ║           Marzban + Sing-box | 5 profiles                 ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/lang.sh" ]]; then
  source "${SCRIPT_DIR}/lang.sh"
else
  # Fallback если файл локализации отсутствует
  source "${SCRIPT_DIR}/lib/fallback.sh"
fi

# ── Подключение общих модулей ─────────────────────────────────
source "${SCRIPT_DIR}/lib/common.sh" || {
  err "Не удалось загрузить lib/common.sh"
}
source "${SCRIPT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}
source "${SCRIPT_DIR}/lib/install-steps.sh" || {
  err "Не удалось загрузить lib/install-steps.sh"
}

# ── Режимы установки / Installation Modes ────────────────────
# DEV_MODE: true | false (по умолчанию)
#   - true:  используется самоподписной SSL сертификат
#   - false: используется Let's Encrypt (требуется домен)
DEV_MODE="${DEV_MODE:-false}"

# DRY_RUN: true | false (по умолчанию)
#   - true:  симуляция установки без внесения изменений
#   - false: реальная установка
DRY_RUN="${DRY_RUN:-false}"

# Домен по умолчанию для dev-режима
DEV_DOMAIN="${DEV_DOMAIN:-dev.cubiveil.local}"

# ══════════════════════════════════════════════════════════════
# Обработка аргументов / Argument Parsing
# ══════════════════════════════════════════════════════════════

usage() {
  cat <<EOF
Usage: \$0 [OPTIONS]

CubiVeil Installer - Marzban + Sing-box with 5 profiles

Options:
  --dev           Enable dev mode (self-signed SSL, no domain required)
                  Useful for testing on virtual machines
  --dry-run       Simulate installation without making changes
                  Shows what would be done without modifying the system
  --domain=NAME   Set domain name (default in dev mode: \${DEV_DOMAIN})
  --help, -h      Show this help message

Examples:
  \$0                      # Interactive mode with Let's Encrypt
  \$0 --dev                # Dev mode with self-signed SSL
  \$0 --dev --domain=test  # Dev mode with custom domain
  \$0 --dry-run            # Dry-run mode (simulation)
  \$0 --dev --dry-run      # Dev mode dry-run (test dev installation)

Dev Mode Features:
  - Self-signed SSL certificate (valid for 100 years)
  - No DNS A-record required
  - No domain validation
  - Perfect for testing and development
  - Not suitable for production

Dry-run Mode Features:
  - No system changes made
  - Shows all steps that would be executed
  - Validates environment and dependencies
  - Safe to run on any system

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dev)
        DEV_MODE="true"
        shift
        ;;
      --dry-run)
        DRY_RUN="true"
        shift
        ;;
      --domain=*)
        DOMAIN="${1#*=}"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        err "Unknown option: $1. Use --help for usage."
        ;;
    esac
  done
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════

# Шаг установки (заглушка для dry-run)
step_dry_run() {
  local step_name="$1"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${CYAN}  [DRY-RUN] Would execute: ${step_name}${PLAIN}"
  fi
}

main() {
  # Парсинг аргументов
  parse_args "$@"

  # Выбор языка
  select_language

  # Печать баннера с учётом режима
  print_banner

  # Информация о режиме установки
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}  [DRY-RUN] Simulation mode - no changes will be made${PLAIN}"
    echo -e "${YELLOW}  [DRY-RUN] Режим симуляции - изменения не будут внесены${PLAIN}"
    echo ""
  fi

  if [[ "$DEV_MODE" == "true" ]]; then
    echo -e "${YELLOW}  [DEV MODE] Self-signed SSL, no domain required${PLAIN}"
    echo -e "${YELLOW}  [DEV MODE] Самоподписной SSL, домен не требуется${PLAIN}"
    echo ""
  fi

  # В режиме dry-run показываем план установки
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "══════════════════════════════════════════════════════════"
    echo "  Installation Plan / План установки"
    echo "══════════════════════════════════════════════════════════"
    echo ""
    echo "  Steps to be executed:"
    echo "  1.  Check IP neighborhood"
    echo "  2.  System update"
    echo "  3.  Auto-updates configuration"
    echo "  4.  BBR optimization"
    echo "  5.  Firewall (UFW) setup"
    echo "  6.  Fail2ban installation"
    echo "  7.  Sing-box installation"
    echo "  8.  Generate keys and ports"
    echo "  9.  Marzban installation"
    echo "  10. SSL certificate (Let's Encrypt or self-signed)"
    echo "  11. Configuration"
    echo "  12. Finish"
    echo ""

    if [[ "$DEV_MODE" == "true" ]]; then
      echo -e "${YELLOW}  [DEV MODE] Self-signed SSL will be generated${PLAIN}"
      echo -e "${YELLOW}  [DEV MODE] No domain validation required${PLAIN}"
    else
      echo "  Domain: ${DOMAIN:-<will be prompted>}"
      echo "  SSL: Let's Encrypt certificate"
    fi

    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo ""

    # Проверка окружения (без изменений)
    echo "Checking environment..."
    if [[ $EUID -ne 0 ]]; then
      echo -e "${RED}  [DRY-RUN] ERROR: Root access required${PLAIN}"
      exit 1
    fi
    echo -e "${GREEN}  [DRY-RUN] Root access: OK${PLAIN}"

    if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
      echo -e "${RED}  [DRY-RUN] ERROR: Ubuntu required${PLAIN}"
      exit 1
    fi
    echo -e "${GREEN}  [DRY-RUN] Ubuntu detected: OK${PLAIN}"

    echo ""
    echo -e "${GREEN}  [DRY-RUN] All checks passed. Installation would proceed.${PLAIN}"
    echo -e "${YELLOW}  [DRY-RUN] No changes were made to the system.${PLAIN}"
    echo ""

    return 0
  fi

  # Реальная установка
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
