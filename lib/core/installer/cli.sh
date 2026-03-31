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
# shellcheck disable=SC2034
DEV_DOMAIN="dev.cubiveil.local"
DOMAIN=""
INSTALL_DECOY="true"
INSTALL_TRAFFIC_SHAPING="true"
INSTALL_TELEGRAM=""
INSTALL_SUI="true"
INSTALL_SSL="true"

# Автоматический режим (не интерактивный)
INTERACTIVE_MODE="false"
export INTERACTIVE_MODE

# Переменные по умолчанию (заполняются в prompt_inputs())
# shellcheck disable=SC2034
LE_EMAIL=""
LANG_NAME="${LANG_NAME:-Русский}"
# shellcheck disable=SC2034
SERVER_IP=""

# Заглушки для совместимости (используются в модулях)
# shellcheck disable=SC2034
REPORT_TIME="${REPORT_TIME:-09:00}"
# shellcheck disable=SC2034
ALERT_CPU="${ALERT_CPU:-80}"
# shellcheck disable=SC2034
ALERT_RAM="${ALERT_RAM:-85}"
# shellcheck disable=SC2034
ALERT_DISK="${ALERT_DISK:-90}"
# shellcheck disable=SC2034
CUBIVEIL_DIR="${CUBIVEIL_DIR:-/opt/cubiveil}"
# shellcheck disable=SC2034
SSH_PORT="${SSH_PORT:-22}"

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
    --no-sui) INSTALL_SUI="false" ;;
    --no-ssl) INSTALL_SSL="false" ;;
    --telegram) INSTALL_TELEGRAM="true" ;;
    --help | -h)
      usage
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
