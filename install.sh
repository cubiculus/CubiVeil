#!/bin/bash
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
parse_args "$@"

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
    echo ""
    echo "══════════════════════════════════════════════════════════"
    echo "  DRY-RUN MODE / Режим симуляции"
    echo "  Installation Plan / План установки"
    echo "══════════════════════════════════════════════════════════"
    echo ""
    echo "  Simulation mode: No changes will be made to the system"
    echo "  Режим симуляции: изменения не будут внесены в систему"
    echo ""
    # Root access check (EUID check for tests)
    if [[ $EUID -ne 0 ]]; then
      echo "  [WARN] Root access: would check for root privileges"
    else
      echo "  [OK] Root access: verified"
    fi
    # Ubuntu check (for tests)
    if grep -qi ubuntu /etc/os-release 2>/dev/null; then
      echo "  [OK] Ubuntu detected"
    else
      echo "  [INFO] Ubuntu: would check"
    fi
    echo ""
    echo "  Installation steps that would run:"
    echo "    1. system   — update, BBR, auto-updates"
    echo "    2. firewall — UFW rules"
    echo "    3. fail2ban — SSH brute-force protection"
    echo "    4. ssl      — Let's Encrypt or self-signed"
    echo "    5. s-ui     — panel installation and configuration"
    [[ "$INSTALL_DECOY" == "true" ]] && echo "    6. decoy-site      — decoy website"
    [[ "$INSTALL_TRAFFIC_SHAPING" == "true" ]] && echo "    7. traffic-shaping — tc/netem fingerprint"
    [[ "$INSTALL_TELEGRAM" == "true" ]] && echo "    8. telegram        — Telegram bot setup"
    echo ""
    echo "  No changes will be made to the system."
    echo ""
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
  step_check_ip_neighborhood
  step_system_update
  step_firewall
  step_fail2ban
  step_ssl
  step_install_sui
  step_configure
  step_decoy_site
  step_traffic_shaping
  step_telegram

  step_finish
  exit 0
}

main "$@"
