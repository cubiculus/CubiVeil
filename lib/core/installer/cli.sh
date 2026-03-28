#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — CLI Parser                                    ║
# ║  Разбор аргументов командной строки                       ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Глобальные переменные ───────────────────────────────────
DEV_MODE="false"
DRY_RUN="false"
DEBUG_MODE="false"
DEV_DOMAIN="dev.cubiveil.local"
DOMAIN=""
INSTALL_DECOY="true"
INSTALL_TRAFFIC_SHAPING="true"
INSTALL_TELEGRAM=""

# Автоматический режим (не интерактивный)
INTERACTIVE_MODE="false"
export INTERACTIVE_MODE

# Переменные по умолчанию (заполняются в prompt_inputs())
LE_EMAIL=""
LANG_NAME="${LANG_NAME:-Русский}"
SERVER_IP=""

# Заглушки для совместимости
REPORT_TIME="${REPORT_TIME:-09:00}"
ALERT_CPU="${ALERT_CPU:-80}"
ALERT_RAM="${ALERT_RAM:-85}"
ALERT_DISK="${ALERT_DISK:-90}"
SB_TAG="${SB_TAG:-}"
REALITY_SNI="${REALITY_SNI:-}"
TROJAN_PORT="${TROJAN_PORT:-}"
SS_PORT="${SS_PORT:-}"
PANEL_PORT="${PANEL_PORT:-}"
SUB_PORT="${SUB_PORT:-}"
CUBIVEIL_DIR="${CUBIVEIL_DIR:-/opt/cubiveil}"
BACKUP_DIR="${BACKUP_DIR:-}"
SSH_PORT="${SSH_PORT:-22}"
CHECKED="${CHECKED:-0}"
VPN_COUNT="${VPN_COUNT:-0}"
CURRENT="${CURRENT:-}"
cmd="${cmd:-}"

# ── Функции ─────────────────────────────────────────────────

# parse_args() - алиас для совместимости с тестами
parse_args() {
  _parse_args_early "$@"
}

_parse_args_early() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --dev) DEV_MODE="true" ;;
    --dry-run) DRY_RUN="true" ;;
    --debug | -v) DEBUG_MODE="true" ;;
    --domain=*) DOMAIN="${1#*=}" ;;
    --no-decoy) INSTALL_DECOY="false" ;;
    --no-traffic-shaping) INSTALL_TRAFFIC_SHAPING="false" ;;
    --telegram) INSTALL_TELEGRAM="true" ;;
    --help | -h)
      _usage
      exit 0
      ;;
    *) ;;
    esac
    shift
  done

  # Включаем режим отладки bash если указан флаг --debug
  if [[ "$DEBUG_MODE" == "true" ]]; then
    set -x
    export CUBIVEIL_LOG_LEVEL="DEBUG"
  fi

  # Set default language to English in dev mode
  if [[ "$DEV_MODE" == "true" ]]; then
    LANG_NAME="English"
  fi
}

_usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

CubiVeil Installer — Marzban + Sing-box

Options:
  --dev                 Dev mode: self-signed SSL, no domain required
  --dry-run             Simulate install without changing the system
  --debug, -v           Enable debug mode (verbose bash output + DEBUG logs)
  --domain=NAME         Set domain (default in dev mode: ${DEV_DOMAIN})
  --no-decoy            Skip decoy-site installation
  --no-traffic-shaping  Skip traffic-shaping module
  --telegram            Install Telegram bot (will prompt for config)
  --help, -h            Show this help

Examples:
  sudo bash install.sh
  sudo bash install.sh --dev
  sudo bash install.sh --debug --dry-run
  sudo bash install.sh --domain=panel.example.com
  sudo bash install.sh --telegram
  sudo bash install.sh --debug 2>&1 | tee install_debug.log
EOF
}
