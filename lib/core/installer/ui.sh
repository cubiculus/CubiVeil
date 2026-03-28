#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — UI                                            ║
# ║  Вывод отчётов, dry-run план, финальные инструкции        ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Функции ─────────────────────────────────────────────────

_dry_run_plan() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  $(get_str MSG_DRY_RUN_TITLE)"
  echo "  Installation Plan / План установки"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo "  $(get_str MSG_DRY_RUN_SIMULATION_MODE)"
  echo "  Simulation Mode: No changes will be made to the system"
  echo ""
  local _steps=(
    "system   — update, BBR, auto-updates"
    "firewall — UFW rules"
    "fail2ban — SSH brute-force protection"
    "singbox  — generate keys/ports, install Sing-box"
    "ssl      — Let's Encrypt or self-signed"
    "marzban  — panel installation and configuration"
  )
  [[ "$INSTALL_DECOY" == "true" ]] && _steps+=("decoy-site      — decoy website")
  [[ "$INSTALL_TRAFFIC_SHAPING" == "true" ]] && _steps+=("traffic-shaping — tc/netem fingerprint")
  [[ "$INSTALL_TELEGRAM" == "true" ]] && _steps+=("telegram        — Telegram bot setup")

  local _i=1
  for _s in "${_steps[@]}"; do
    printf "  %2d. %s\n" "$_i" "$_s"
    ((_i++))
  done

  echo ""
  if [[ "$DEV_MODE" == "true" ]]; then
    echo "  $(get_str MSG_DRY_RUN_MODE_DEV)"
    echo "  $(get_str MSG_DRY_RUN_DOMAIN) ${DOMAIN}"
  else
    echo "  $(get_str MSG_DRY_RUN_MODE_PROD)"
    echo "  $(get_str MSG_DRY_RUN_DOMAIN) ${DOMAIN:-<$(get_str MSG_DRY_RUN_WILL_BE_PROMPTED)>}"
    echo "  $(get_str MSG_DRY_RUN_EMAIL) ${LE_EMAIL:-<$(get_str MSG_DRY_RUN_WILL_BE_PROMPTED)>}"
  fi
  echo ""

  # Проверка окружения
  echo "  $(get_str MSG_DRY_RUN_CHECKING_ENV)..."
  # Root access check (EUID check for tests)
  if [[ $EUID -ne 0 ]]; then
    echo "  $(get_str MSG_DRY_RUN_ROOT_ACCESS_WOULD_CHECK)"
  else
    echo "  $(get_str MSG_DRY_RUN_ROOT_ACCESS_OK)"
  fi
  # Ubuntu check (for tests)
  if grep -qi ubuntu /etc/os-release 2>/dev/null; then
    echo "  $(get_str MSG_DRY_RUN_UBUNTU_DETECTED_OK)"
  else
    echo "  $(get_str MSG_DRY_RUN_UBUNTU_WOULD_CHECK)"
  fi
  echo -e "\033[0;32m  $(get_str MSG_DRY_RUN_ENV_CHECKS_OK)\033[0m"
  echo ""
  echo "  $(get_str MSG_DRY_RUN_NO_CHANGES)"
  echo ""
}

_print_finish() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  ✅ CubiVeil $(get_str MSG_INSTALLED_SUCCESSFULLY)"
  echo "══════════════════════════════════════════════════════════"
  echo ""

  # Читаем домен и порты из файлов если переменные не установлены
  local _domain="${DOMAIN:-}"
  local _panel_port="${PANEL_PORT:-8080}"
  local _sub_port="${SUB_PORT:-8081}"

  # Читаем из domain.json если домен не установлен
  if [[ -z "$_domain" && -f "/etc/cubiveil/domain.json" ]]; then
    _domain=$(jq -r '.domain' "/etc/cubiveil/domain.json" 2>/dev/null || echo "0.0.0.0")
  fi
  [[ -z "$_domain" ]] && _domain="0.0.0.0"

  # Читаем из ports.json если порты не установлены
  if [[ -f "/etc/cubiveil/ports.json" ]]; then
    _panel_port=$(jq -r '.panel' "/etc/cubiveil/ports.json" 2>/dev/null || echo "8080")
    _sub_port=$(jq -r '.subscription' "/etc/cubiveil/ports.json" 2>/dev/null || echo "8081")
  fi

  local _panel_url="https://${_domain}:${_panel_port}"
  local _sub_url="https://${_domain}:${_sub_port}/subscription"

  # Итоговая сводка предупреждений
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}$(get_str MSG_WARNINGS_DURING_INSTALL)${PLAIN}"
    for _warn in "${WARNINGS[@]}"; do
      echo -e "  - ${_warn}"
    done
    echo ""
  fi

  # Выделение финального блока (URL + credentials)
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${PLAIN}"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "  $(get_str SUCCESS_PANEL_URL)     ${_panel_url}"
    echo "  $(get_str SUCCESS_SUBSCRIPTION_URL)   ${_sub_url}"
    echo ""
    echo "  $(get_str SUCCESS_PROFILES) Trojan · Shadowsocks · VLESS · VMess · Hysteria2"
    echo ""
    [[ "$DEV_MODE" == "true" ]] &&
      warn "$(get_str MSG_BROWSERS_SECURITY_WARNING)"
    echo ""
    echo "  $(get_str NEXT_STEPS)"
    echo "    $(get_str MSG_NEXT_STEP_CREATE_USERS)"
    echo "    $(get_str MSG_NEXT_STEP_SUBSCRIPTION)"
    echo "    $(get_str MSG_NEXT_STEP_SSH)"
    if [[ "$INSTALL_TELEGRAM" != "true" ]]; then
      echo "    $(get_str MSG_NEXT_STEP_TELEGRAM)"
    fi
  else
    echo "  $(get_str SUCCESS_PANEL_URL)        ${_panel_url}"
    echo "  $(get_str SUCCESS_SUBSCRIPTION_URL) ${_sub_url}"
    echo ""
    echo "  $(get_str SUCCESS_PROFILES) Trojan · Shadowsocks · VLESS · VMess · Hysteria2"
    echo ""
    [[ "$DEV_MODE" == "true" ]] &&
      warn "$(get_str MSG_BROWSERS_SECURITY_WARNING)"
    echo ""
    echo "  $(get_str NEXT_STEPS)"
    echo "    $(get_str MSG_NEXT_STEP_CREATE_USERS)"
    echo "    $(get_str MSG_NEXT_STEP_SUBSCRIPTION)"
    echo "    $(get_str MSG_NEXT_STEP_SSH)"
    if [[ "$INSTALL_TELEGRAM" != "true" ]]; then
      echo "    $(get_str MSG_NEXT_STEP_TELEGRAM)"
    fi
  fi

  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${PLAIN}"

  # Вывод данных админа если файл существует
  if [[ -f "/etc/cubiveil/admin.credentials" ]]; then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${PLAIN}"
    echo "  $(get_str MSG_ADMIN_CREDENTIALS)"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${PLAIN}"
    local _admin_user _admin_pass
    _admin_user=$(grep "MARZBAN_USERNAME" /etc/cubiveil/admin.credentials 2>/dev/null | cut -d= -f2 || echo "N/A")
    _admin_pass=$(grep "MARZBAN_PASSWORD" /etc/cubiveil/admin.credentials 2>/dev/null | cut -d= -f2 || echo "N/A")
    echo -e "${GREEN}  Username: ${PLAIN}${_admin_user}"
    echo -e "${GREEN}  Password: ${YELLOW}${_admin_pass}${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
  fi

  # MikroTik скрипт (если decoy установлен)
  if [[ "$INSTALL_DECOY" == "true" && -f "/etc/cubiveil/decoy.json" ]]; then
    local _mikrotik_mod="${INSTALL_SCRIPT_DIR}/lib/modules/decoy-site/mikrotik.sh"
    if [[ -f "$_mikrotik_mod" ]]; then
      echo ""
      echo "══════════════════════════════════════════════════════════"
      echo "  $(get_str MSG_MIKROTIK_SCRIPT)"
      echo "══════════════════════════════════════════════════════════"
      # shellcheck disable=SC1090
      source "$_mikrotik_mod"

      # Сохраняем скрипт в файл
      if declare -f decoy_save_mikrotik_script >/dev/null; then
        decoy_save_mikrotik_script "/etc/cubiveil/mikrotik-decoy.rsc"
        echo ""
        echo "  $(get_str MSG_MIKROTIK_SCRIPT_SAVED | sed "s/{PATH}/\/etc\/cubiveil\/mikrotik-decoy.rsc/g")"
        echo "  $(get_str MSG_MIKROTIK_IMPORT_INSTRUCTIONS_1 | sed "s/{PATH}/\/etc\/cubiveil\/mikrotik-decoy.rsc/g")"
        echo "  $(get_str MSG_MIKROTIK_IMPORT_INSTRUCTIONS_2)"
        echo "  $(get_str MSG_MIKROTIK_IMPORT_INSTRUCTIONS_3)"
      fi
      echo "══════════════════════════════════════════════════════════"
    fi
  fi

  echo ""
}

# ── Legacy API wrapper ──────────────────────────────────────
step_finish() { _print_finish; }
