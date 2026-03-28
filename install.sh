#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║                        CubiVeil                           ║
# ║               github.com/cubiculus/cubiveil              ║
# ║                                                           ║
# ║           Marzban + Sing-box — Unified Installer          ║
# ╚═══════════════════════════════════════════════════════════╝
#
# Единая точка входа. Вся логика установки — в lib/modules/*.
# Этот файл отвечает только за:
#   1. Разбор аргументов CLI
#   2. Ввод данных от пользователя
#   3. Оркестрацию модулей в правильном порядке

set -euo pipefail

# ── Определение корневой директории ─────────────────────────
# При запуске через curl/pipe BASH_SOURCE[0] == "-s"
if [[ "${BASH_SOURCE[0]}" == "-s" || ! -f "${BASH_SOURCE[0]}" ]]; then
  INSTALL_SCRIPT_DIR=""
else
  INSTALL_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# ── Загрузка модулей установщика ────────────────────────────
source "${INSTALL_SCRIPT_DIR}/lib/core/installer/bootstrap.sh"
source "${INSTALL_SCRIPT_DIR}/lib/core/installer/cli.sh"
source "${INSTALL_SCRIPT_DIR}/lib/core/installer/prompt.sh"
source "${INSTALL_SCRIPT_DIR}/lib/core/installer/orchestrator.sh"
source "${INSTALL_SCRIPT_DIR}/lib/core/installer/ui.sh"

# ── Инициализация ───────────────────────────────────────────
if ! setup_remote_install; then
  handle_setup_error
fi

# ── Root check / auto-relaunch ──────────────────────────────
# Skip root check for dry-run mode (for testing)
if [[ "$DRY_RUN" != "true" && $EUID -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

# ── Загрузка библиотек ──────────────────────────────────────
if [[ -f "${INSTALL_SCRIPT_DIR}/lang/main.sh" ]]; then
  source "${INSTALL_SCRIPT_DIR}/lang/main.sh"
else
  source "${INSTALL_SCRIPT_DIR}/lib/fallback.sh" 2>/dev/null || true
fi

source "${INSTALL_SCRIPT_DIR}/lib/output.sh" || {
  echo "[✗] Cannot load lib/output.sh"
  exit 1
}
source "${INSTALL_SCRIPT_DIR}/lib/common.sh" || { err "Cannot load lib/common.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/core/log.sh" || { err "Cannot load lib/core/log.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/core/system.sh" || { err "Cannot load lib/core/system.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/utils.sh" || { err "Cannot load lib/utils.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/validation.sh" || { err "Cannot load lib/validation.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/security.sh" || { err "Cannot load lib/security.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/i18n.sh" || { err "Cannot load lib/i18n.sh"; }

# ── Применение аргументов ───────────────────────────────────
_parse_args_early "$@"

[[ "$DEV_MODE" == "true" && -z "$DOMAIN" ]] && DOMAIN="$DEV_DOMAIN"

# ══════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════

main() {
  # Dry-run: быстрый путь
  if [[ "$DRY_RUN" == "true" ]]; then
    LANG_NAME="Русский"
    _print_banner
    _dry_run_plan
    return 0
  fi

  # Выбор языка (если переменная задана, пропускаем)
  if [[ -n "${LANG_NAME:-}" ]]; then
    :
  else
    _select_language
  fi

  _print_banner

  # Инициализация логов
  if [[ -z "${CUBIVEIL_LOG_FILE:-}" ]]; then
    CUBIVEIL_LOG_FILE="/var/log/cubiveil/install.log"
  fi
  log_init "$CUBIVEIL_LOG_FILE"

  # Сообщение о режиме
  if [[ "$DEV_MODE" == "true" ]]; then
    echo -e "\033[0;33m  [DEV MODE] Self-signed SSL, no domain required\033[0m"
    echo ""
  fi

  # Проверки окружения
  check_root
  check_ubuntu

  # Пользовательский ввод
  prompt_inputs

  # Экспортируем переменные для модулей
  _export_globals

  # Оркестрация модулей (legacy API wrappers)
  step_check_ip_neighborhood
  step_system_update
  step_firewall
  step_fail2ban
  step_install_singbox
  step_ssl
  step_install_marzban
  step_configure
  step_decoy_site
  step_traffic_shaping
  step_telegram

  step_finish
  exit 0
}

main "$@"
