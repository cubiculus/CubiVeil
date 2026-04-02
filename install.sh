#!/bin/bash
# shellcheck disable=SC1071
# ╔═══════════════════════════════════════════════════════════╗
# ║                        CubiVeil                           ║
# ║               github.com/cubiculus/cubiveil              ║
# ║                                                           ║
# ║                    s-ui Unified Installer                 ║
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

# ── Функция usage ───────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

CubiVeil Installer — S-UI + Sing-box

Options:
  --dev                 Dev mode: self-signed SSL, no domain required
  --dry-run             Simulate install without changing the system
  --debug, -v           Enable debug mode (verbose bash output + DEBUG logs)
  --domain=NAME         Set domain (default in dev mode: ${DEV_DOMAIN})
  --no-decoy            Skip decoy-site installation
  --no-traffic-shaping  Skip traffic-shaping module
  --no-sui              Skip s-ui panel installation
  --no-ssl              Skip SSL certificate installation
  --telegram            Install Telegram bot (will prompt for config)
  --non-interactive     Run in non-interactive mode (no prompts)
  --sui-panel-port=PORT Set s-ui panel port (default 2095)
  --sui-sub-port=PORT  Set s-ui subscription port (default 2096)
  --sui-path=PATH      Set s-ui panel path (default /app/)
  --sui-sub-path=PATH  Set s-ui subscription path (default /sub/)
  --sui-admin-user=USER    Set s-ui admin username (auto if missing)
  --sui-admin-password=PWD Set s-ui admin password (auto if missing)
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
# Используем централизованный загрузчик для правильного порядка
if [[ -f "${INSTALL_SCRIPT_DIR}/lib/init.sh" ]]; then
  source "${INSTALL_SCRIPT_DIR}/lib/init.sh" || {
    echo "[✗] Cannot load lib/init.sh"
    exit 1
  }
else
  # Fallback для обратной совместимости
  source "${INSTALL_SCRIPT_DIR}/lib/output.sh" || {
    echo "[✗] Cannot load lib/output.sh"
    exit 1
  }
  source "${INSTALL_SCRIPT_DIR}/lib/validation.sh" || { err "Cannot load lib/validation.sh"; }
  source "${INSTALL_SCRIPT_DIR}/lib/i18n.sh" || { err "Cannot load lib/i18n.sh"; }
  source "${INSTALL_SCRIPT_DIR}/lib/security.sh" || { err "Cannot load lib/security.sh"; }
  source "${INSTALL_SCRIPT_DIR}/lib/common.sh" || { err "Cannot load lib/common.sh"; }
  source "${INSTALL_SCRIPT_DIR}/lib/fallback.sh" 2>/dev/null || true
  source "${INSTALL_SCRIPT_DIR}/lib/utils.sh" || { err "Cannot load lib/utils.sh"; }
  source "${INSTALL_SCRIPT_DIR}/lib/core/log.sh" || { err "Cannot load lib/core/log.sh"; }
  source "${INSTALL_SCRIPT_DIR}/lib/core/system.sh" || { err "Cannot load lib/core/system.sh"; }
fi

# Загрузка локализации (после init.sh чтобы i18n уже был загружен)
if [[ -f "${INSTALL_SCRIPT_DIR}/lang/main.sh" ]]; then
  source "${INSTALL_SCRIPT_DIR}/lang/main.sh"
fi

# ── Применение аргументов ───────────────────────────────────
parse_args "$@"

# Вычисляем количество шагов после обработки аргументов
_calculate_total_steps

# В dev-режиме устанавливаем домен по умолчанию
[[ "$DEV_MODE" == "true" && -z "$DOMAIN" ]] && DOMAIN="$DEV_DOMAIN"

# В не-dev режиме DOMAIN обязателен
if [[ "$DEV_MODE" != "true" && -z "$DOMAIN" && "$DRY_RUN" != "true" ]]; then
  echo "Error: DOMAIN is required for production installation"
  echo "Use --domain=example.com or --dev for self-signed SSL"
  echo ""
  usage
  exit 1
fi

# ══════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════

main() {
  # Dry-run: быстрый путь
  if [[ "$DRY_RUN" == "true" ]]; then
    LANG_NAME="English"
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

  # Сообщение о режиме (DEV-режим: Self-signed SSL, no domain required)
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
  _step_system
  step_firewall
  step_fail2ban
  step_ssl
  step_install_sui
  step_decoy_site
  step_traffic_shaping
  step_telegram

  step_finish
  exit 0
}

main "$@"
