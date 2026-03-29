#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Orchestrator                                  ║
# ║  Запуск модулей установки в правильном порядке            ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Глобальные переменные ───────────────────────────────────
CURRENT_STEP=0
TOTAL_STEPS=8
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
    echo "Module not found: $name"
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

_step_ssl() {
  local _label
  _label="$(get_str MSG_STEP_4_8_SSL)"
  step_module "$_label"
  run_module "ssl"
}

_step_sui() {
  local _label
  _label="$(get_str MSG_STEP_5_8_SUI)"
  step_module "$_label"

  # Устанавливаем s-ui через официальный скрипт
  _install_sui_panel
  run_module "s-ui"
}

# Установка s-ui панели через официальный скрипт
_install_sui_panel() {
  log_step "install_sui_panel" "Installing s-ui panel"

  # Проверяем, установлен ли уже s-ui
  if [[ -f "/usr/local/s-ui/s-ui" ]]; then
    log_info "s-ui already installed"
    return 0
  fi

  log_info "Downloading s-ui installation script..."

  # Загружаем официальный скрипт установки s-ui
  local _sui_script="/tmp/s-ui-install.sh"
  if ! curl -sfL --connect-timeout 10 --max-time 60 \
    "https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh" \
    -o "$_sui_script" 2>/dev/null; then
    log_error "Failed to download s-ui installation script"
    log_warn "You can install s-ui manually later:"
    log_warn "  bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)"
    return 0
  fi

  chmod +x "$_sui_script"

  log_info "Running s-ui installation..."

  # Запускаем установку в автоматическом режиме
  local _sui_log="/var/log/cubiveil/s-ui-install.log"
  mkdir -p "$(dirname "$_sui_log")"
  log_info "s-ui install log: $_sui_log"

  # Запускаем скрипт в фоновом режиме
  bash "$_sui_script" >"$_sui_log" 2>&1 &
  local _sui_bg_pid=$!

  # Ждём, пока сервис станет активным (до 180 секунд)
  local _max_wait=180
  local _started=false
  local _start_time
  _start_time=$(date +%s)

  while true; do
    local _now
    _now=$(date +%s)
    local _elapsed=$((_now - _start_time))

    if [[ $_elapsed -ge $_max_wait ]]; then
      break
    fi

    if systemctl is-active --quiet s-ui 2>/dev/null; then
      _started=true
      break
    fi

    echo -ne "\rWaiting for s-ui... ${_elapsed}s"
    sleep 2
  done
  echo -ne "\r"

  # Убиваем фоновый процесс
  kill "$_sui_bg_pid" 2>/dev/null || true
  wait "$_sui_bg_pid" 2>/dev/null || true

  if [[ "$_started" != "true" ]]; then
    log_error "s-ui did not start within ${_max_wait}s"
    log_warn "Check: systemctl status s-ui"
    log_warn "Full install log: $_sui_log"
    rm -f "$_sui_script"
    return 1
  fi

  # Очищаем временный файл
  rm -f "$_sui_script"

  log_success "s-ui installed successfully"
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

# ── Legacy API wrappers (для тестов, совместимости) ─────────

step_check_ip_neighborhood() { _step_system; }
step_system_update() { _step_system; }
step_auto_updates() { :; }
step_bbr() { :; }
step_firewall() { _step_firewall; }
step_fail2ban() { _step_fail2ban; }
step_ssl() { _step_ssl; }
step_install_sui() { _step_sui; }
step_configure() { :; }
step_decoy_site() { _step_decoy; }
step_traffic_shaping() { _step_traffic_shaping; }
step_telegram() { _step_telegram; }
