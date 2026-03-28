#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Orchestrator                                  ║
# ║  Запуск модулей установки в правильном порядке            ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Глобальные переменные ───────────────────────────────────
CURRENT_STEP=0
TOTAL_STEPS=9
WARNINGS=()

# ── Функции ─────────────────────────────────────────────────

# Экспортируем глобальные переменные, нужные модулям
_export_globals() {
  export LANG_NAME DEV_MODE DRY_RUN DEBUG_MODE DOMAIN LE_EMAIL SERVER_IP
  export INSTALL_SCRIPT_DIR CUBIVEIL_LOG_LEVEL
}

# Шаг в обёртке для показа прогресса [x/N]
step_module() {
  local label="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "$label"
}

# run_module <name> — source, configure, enable
run_module() {
  local name="$1"
  local module_file="${INSTALL_SCRIPT_DIR}/lib/modules/${name}/install.sh"

  if [[ ! -f "$module_file" ]]; then
    local _msg_not_found
    _msg_not_found="$(get_str MSG_MODULE_NOT_FOUND | sed "s/{NAME}/$name/g")"
    warning "$_msg_not_found ($module_file)"
    WARNINGS+=("Module not found: $name")
    echo -e "${YELLOW}$(get_str MSG_MODULE_SKIPPED)${PLAIN}"
    return 0
  fi

  # Каждый модуль source-ится в текущей оболочке
  # с очисткой module_* функций после
  # shellcheck disable=SC1090
  source "$module_file"

  if [[ "$DRY_RUN" == "true" ]]; then
    local _msg_would_run
    _msg_would_run="$(get_str MSG_DRY_RUN_WOULD_RUN | sed "s/{NAME}/$name/g")"
    info "$_msg_would_run ::install, configure, enable"
    unset -f module_install module_configure module_enable module_disable \
      module_update module_remove module_status module_health_check 2>/dev/null || true
    local _msg_dry_run_skipped
    _msg_dry_run_skipped="$(get_str MSG_DRY_RUN_SKIPPED | sed "s/{NAME}/$name/g")"
    echo -e "${GREEN}${_msg_dry_run_skipped}${PLAIN}"
    return 0
  fi

  # Отключаем обильные разделители log_step для внутренних шагов модулей
  export CUBIVEIL_HIDE_LOG_STEP="true"

  local module_status=0

  if declare -f module_install >/dev/null; then
    if ! module_install; then
      local _msg_install_failed
      _msg_install_failed="$(get_str MSG_MODULE_INSTALL_FAILED | sed "s/{NAME}/$name/g")"
      warning "$_msg_install_failed, continuing"
      WARNINGS+=("module_install failed for ${name}")
      module_status=1
    fi
  fi

  if declare -f module_configure >/dev/null; then
    if ! module_configure; then
      local _msg_configure_failed
      _msg_configure_failed="$(get_str MSG_MODULE_CONFIGURE_FAILED | sed "s/{NAME}/$name/g")"
      warning "$_msg_configure_failed, continuing"
      WARNINGS+=("module_configure failed for ${name}")
      module_status=1
    fi
  fi

  if declare -f module_enable >/dev/null; then
    if ! module_enable; then
      local _msg_enable_failed
      _msg_enable_failed="$(get_str MSG_MODULE_ENABLE_FAILED | sed "s/{NAME}/$name/g")"
      warning "$_msg_enable_failed, continuing"
      WARNINGS+=("module_enable failed for ${name}")
      module_status=1
    fi
  fi

  if [[ $module_status -eq 0 ]]; then
    local _msg_ok
    _msg_ok="$(get_str MSG_MODULE_OK | sed "s/{NAME}/$name/g")"
    success "$_msg_ok"
  else
    local _msg_issues
    _msg_issues="$(get_str MSG_MODULE_SKIPPED_ISSUES | sed "s/{NAME}/$name/g")"
    warning "$_msg_issues"
  fi

  # Сбрасываем функции модуля
  unset -f module_install module_configure module_enable module_disable \
    module_update module_remove module_status module_health_check 2>/dev/null || true
}

# ── Шаги оркестрации ────────────────────────────────────────

_step_system() {
  local _label
  _label="$(get_str MSG_STEP_1_8_SYSTEM)"
  step_module "$_label"
  run_module "system"
}

_step_firewall() {
  local _label
  _label="$(get_str MSG_STEP_2_8_FIREWALL)"
  step_module "$_label"
  run_module "firewall"
}

_step_fail2ban() {
  local _label
  _label="$(get_str MSG_STEP_3_8_FAIL2BAN)"
  step_module "$_label"
  run_module "fail2ban"
}

_step_singbox() {
  local _label
  _label="$(get_str MSG_STEP_4_8_SINGBOX)"
  step_module "$_label"

  # Генерируем ключи и порты до установки
  _generate_keys_and_ports
  run_module "singbox"
}

_step_ssl() {
  local _label
  _label="$(get_str MSG_STEP_5_8_SSL)"
  step_module "$_label"
  run_module "ssl"
}

_step_marzban() {
  local _label
  _label="$(get_str MSG_STEP_6_8_MARZBAN)"
  step_module "$_label"
  run_module "marzban"
}

_step_decoy() {
  [[ "$INSTALL_DECOY" != "true" ]] && return 0
  local _label
  _label="$(get_str MSG_STEP_7_8_DECOY)"
  step_module "$_label"
  run_module "decoy-site"
}

_step_traffic_shaping() {
  [[ "$INSTALL_TRAFFIC_SHAPING" != "true" ]] && return 0
  local _label
  _label="$(get_str MSG_STEP_8_8_TRAFFIC)"
  step_module "$_label"
  run_module "traffic-shaping"
}

_step_telegram() {
  [[ "$INSTALL_TELEGRAM" != "true" ]] && return 0
  local _label
  _label="$(get_str MSG_STEP_9_9_TELEGRAM)"
  step_module "$_label"
  # Запускаем setup-telegram.sh
  local _setup_script="${INSTALL_SCRIPT_DIR}/setup-telegram.sh"
  if [[ -f "$_setup_script" ]]; then
    # shellcheck disable=SC1090
    source "$_setup_script"
    # Вызываем функцию telegram_main если она существует
    declare -f telegram_main >/dev/null && telegram_main
  else
    local _msg_tg_not_found
    _msg_tg_not_found="$(get_str MSG_TELEGRAM_SETUP_NOT_FOUND | sed "s/{SCRIPT}/$_setup_script/g")"
    warn "$_msg_tg_not_found"
  fi
}

# ── Генерация ключей Reality и портов ───────────────────────

_generate_keys_and_ports() {
  source "${INSTALL_SCRIPT_DIR}/lib/utils.sh"

  mkdir -p /etc/cubiveil

  # Reality keypair
  local _private_key=""
  if [[ -x "/usr/local/bin/sing-box" ]]; then
    _private_key=$(/usr/local/bin/sing-box generate reality-keypair 2>/dev/null |
      grep "PrivateKey:" | awk '{print $2}' || true)
  fi
  [[ -z "$_private_key" ]] && _private_key=$(generate_secure_key 32 2>/dev/null || openssl rand -base64 32)

  cat >/etc/cubiveil/reality.json <<EOF
{
  "private_key": "${_private_key}",
  "sni": "www.microsoft.com"
}
EOF

  # Сохраняем домен
  cat >/etc/cubiveil/domain.json <<EOF
{
  "domain": "${DOMAIN:-0.0.0.0}",
  "email": "${LE_EMAIL:-}",
  "dev_mode": "${DEV_MODE:-false}"
}
EOF

  # Уникальные порты
  TROJAN_PORT=$(unique_port)
  SS_PORT=$(unique_port)
  PANEL_PORT=$(unique_port)
  SUB_PORT=$(unique_port)

  cat >/etc/cubiveil/ports.json <<EOF
{
  "trojan":        ${TROJAN_PORT},
  "shadowsocks":   ${SS_PORT},
  "panel":         ${PANEL_PORT},
  "subscription":  ${SUB_PORT}
}
EOF

  REALITY_SNI="www.microsoft.com"
  export TROJAN_PORT SS_PORT PANEL_PORT SUB_PORT REALITY_SNI

  local _ports_msg
  _ports_msg="$(get_str MSG_PORTS_GENERATED)"
  _ports_msg="${_ports_msg//\{TROJAN\}/$TROJAN_PORT}"
  _ports_msg="${_ports_msg//\{SS\}/$SS_PORT}"
  _ports_msg="${_ports_msg//\{PANEL\}/$PANEL_PORT}"
  _ports_msg="${_ports_msg//\{SUB\}/$SUB_PORT}"
  ok "$(get_str OK_REALITY_GENERATED | sed "s/\[REALITY_SNI\]/$REALITY_SNI/g")"
  ok "$_ports_msg"
}

# ── Legacy API wrappers (для тестов, совместимости) ─────────

step_check_ip_neighborhood() { _step_system; }
step_system_update() { _step_system; }
step_auto_updates() { :; }
step_bbr() { :; }
step_firewall() { _step_firewall; }
step_fail2ban() { _step_fail2ban; }
step_install_singbox() { _step_singbox; }
step_generate_keys_and_ports() { _generate_keys_and_ports; }
step_install_marzban() { _step_marzban; }
step_ssl() { _step_ssl; }
step_configure() { :; }
step_decoy_site() { _step_decoy; }
step_traffic_shaping() { _step_traffic_shaping; }
step_telegram() { _step_telegram; }
