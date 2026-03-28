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

REPO_URL="https://raw.githubusercontent.com/cubiculus/cubiveil/main"
TEMP_DIR=""

cleanup_temp() {
  [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}
trap cleanup_temp EXIT

is_curl_install() {
  [[ "$INSTALL_SCRIPT_DIR" == /dev/fd* || -z "$INSTALL_SCRIPT_DIR" ]]
}

ensure_file() {
  local file="$1" target_dir="$2"
  local target_path="${target_dir}/${file}"
  [[ -f "$target_path" ]] && return 0
  mkdir -p "$(dirname "$target_path")" 2>/dev/null || return 1
  local url="${REPO_URL}/${file}"
  if command -v wget &>/dev/null; then
    wget -q --timeout=30 -O "$target_path" "$url" && [[ -s "$target_path" ]] && return 0
    rm -f "$target_path"
  fi
  if command -v curl &>/dev/null; then
    curl -fsSL --connect-timeout 10 --max-time 60 -o "$target_path" "$url" &&
      [[ -s "$target_path" ]] && return 0
    rm -f "$target_path"
  fi
  echo -e "\033[0;31m[✗]\033[0m Failed to download: $file"
  return 1
}

setup_remote_install() {
  is_curl_install || return 0
  TEMP_DIR=$(mktemp -d -t cubiveil.XXXXXX)
  mkdir -p \
    "$TEMP_DIR/lib" \
    "$TEMP_DIR/lib/core" \
    "$TEMP_DIR/lib/modules/decoy-site/templates" \
    "$TEMP_DIR/lib/modules/traffic-shaping" \
    "$TEMP_DIR/lib/modules/system" \
    "$TEMP_DIR/lib/modules/firewall" \
    "$TEMP_DIR/lib/modules/fail2ban" \
    "$TEMP_DIR/lib/modules/ssl" \
    "$TEMP_DIR/lib/modules/singbox" \
    "$TEMP_DIR/lib/modules/marzban" \
    "$TEMP_DIR/lib/modules/backup" \
    "$TEMP_DIR/lib/modules/rollback" \
    "$TEMP_DIR/lib/modules/monitoring" \
    "$TEMP_DIR/assets/telegram-bot"

  local files=(
    "lang.sh"
    "setup-telegram.sh"
    "lib/fallback.sh" "lib/common.sh" "lib/utils.sh"
    "lib/output.sh" "lib/security.sh" "lib/i18n.sh"
    "lib/validation.sh" "lib/manifest.sh"
    "lib/core/log.sh" "lib/core/system.sh"
    "lib/modules/system/install.sh"
    "lib/modules/firewall/install.sh"
    "lib/modules/fail2ban/install.sh"
    "lib/modules/ssl/install.sh"
    "lib/modules/singbox/install.sh"
    "lib/modules/marzban/install.sh"
    "lib/modules/backup/install.sh"
    "lib/modules/rollback/install.sh"
    "lib/modules/monitoring/install.sh"
    "lib/modules/decoy-site/install.sh"
    "lib/modules/decoy-site/generate.sh"
    "lib/modules/decoy-site/rotate.sh"
    "lib/modules/decoy-site/mikrotik.sh"
    "lib/modules/decoy-site/nginx.conf.tpl"
    "lib/modules/decoy-site/templates/admin.html"
    "lib/modules/decoy-site/templates/dashboard.html"
    "lib/modules/decoy-site/templates/portal.html"
    "lib/modules/decoy-site/templates/storage.html"
    "lib/modules/traffic-shaping/install.sh"
    "lib/modules/traffic-shaping/persist.sh"
    "lib/modules/traffic-shaping/uninstall.sh"
    "assets/telegram-bot/bot.py"
    "assets/telegram-bot/telegram_client.py"
    "assets/telegram-bot/metrics.py"
    "assets/telegram-bot/backup.py"
    "assets/telegram-bot/alert_state.py"
    "assets/telegram-bot/commands.py"
    "assets/telegram-bot/health_check.py"
    "assets/telegram-bot/logs.py"
    "assets/telegram-bot/keyboards.py"
    "assets/telegram-bot/profiles.py"
  )
  for f in "${files[@]}"; do
    ensure_file "$f" "$TEMP_DIR" || {
      echo "[✗] Critical file missing: $f"
      return 1
    }
  done
  INSTALL_SCRIPT_DIR="$TEMP_DIR"
}

if ! setup_remote_install; then
  echo -e "\033[0;31m[✗]\033[0m Failed to prepare installation files"
  echo ""
  echo "Clone the repo and run manually:"
  echo "  git clone https://github.com/cubiculus/cubiveil.git && cd cubiveil && sudo bash install.sh"
  exit 1
fi

# ══════════════════════════════════════════════════════════════
# Аргументы (ранний разбор, до загрузки библиотек)
# ══════════════════════════════════════════════════════════════

DEV_MODE="false"
DRY_RUN="false"
DEBUG_MODE="false"
DEV_DOMAIN="dev.cubiveil.local"
DOMAIN=""
INSTALL_DECOY="true"
INSTALL_TRAFFIC_SHAPING="true"
INSTALL_TELEGRAM=""

# Автоматический режим (не интерактивный) — для предотвращения запросов
INTERACTIVE_MODE="false"
export INTERACTIVE_MODE

# Переменные, которые будут заполнены в prompt_inputs()
LE_EMAIL=""
LANG_NAME="${LANG_NAME:-Русский}"
SERVER_IP=""

# Заглушки для lang.sh (переменные используются до загрузки строк)
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

_parse_args_early "$@"

[[ "$DEV_MODE" == "true" && -z "$DOMAIN" ]] && DOMAIN="$DEV_DOMAIN"

# ── Root check / auto-relaunch ────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

# ══════════════════════════════════════════════════════════════
# Загрузка библиотек
# ══════════════════════════════════════════════════════════════

if [[ -f "${INSTALL_SCRIPT_DIR}/lang/main.sh" ]]; then
  source "${INSTALL_SCRIPT_DIR}/lang/main.sh"
else
  # Fallback если lang/main.sh отсутствует
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

# ══════════════════════════════════════════════════════════════
# Выбор языка / Language selection
# ══════════════════════════════════════════════════════════════

_select_language() {
  echo ""
  echo "$(get_str MSG_SELECT_LANGUAGE)"
  echo "  1) $(get_str MSG_OPTION_RU)"
  echo "  2) $(get_str MSG_OPTION_EN)"
  echo ""
  while true; do
    read -rp "  Enter choice [1-2]: " _lc
    case "$_lc" in
    1)
      LANG_NAME="Русский"
      return
      ;;
    2)
      LANG_NAME="English"
      return
      ;;
    *) echo "  $(get_str MSG_INVALID_CHOICE)" ;;
    esac
  done
}

# ══════════════════════════════════════════════════════════════
# Баннер
# ══════════════════════════════════════════════════════════════

_print_banner() {
  echo ""
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║        CubiVeil Installer                ║"
  echo "  ║   github.com/cubiculus/cubiveil          ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Ввод данных от пользователя
# ══════════════════════════════════════════════════════════════

prompt_inputs() {
  local _step_label
  _step_label="$(get_str MSG_PRE_INSTALL_SETUP)"
  step "$_step_label"

  # ── DEV MODE ──────────────────────────────────────────────
  if [[ "$DEV_MODE" == "true" ]]; then
    [[ -z "$DOMAIN" ]] && DOMAIN="$DEV_DOMAIN"
    LE_EMAIL="admin@${DOMAIN}"
    if [[ "$LANG_NAME" == "Русский" ]]; then
      info "$(get_str INFO_DEV_MODE_RU)"
      warn "$(get_str MSG_BROWSERS_SECURITY_WARNING_RU)"
      warn "$(get_str MSG_DO_NOT_USE_PRODUCTION_RU)"
    else
      info "$(get_str INFO_DEV_MODE)"
      warn "$(get_str MSG_BROWSERS_SECURITY_WARNING)"
      warn "$(get_str MSG_DO_NOT_USE_PRODUCTION)"
    fi
    echo ""
    ok "Domain:  $DOMAIN"
    ok "Email:   $LE_EMAIL"
    echo ""
    return 0
  fi

  # ── PRODUCTION MODE ───────────────────────────────────────
  if [[ "$LANG_NAME" == "Русский" ]]; then
    warn "$(get_str MSG_DNS_A_RECORD_HINT_RU)"
    warn "$(get_str MSG_LE_DNS_CHECK_RU)"
  else
    warn "$(get_str MSG_DNS_A_RECORD_HINT)"
    warn "$(get_str MSG_LE_DNS_CHECK)"
  fi
  echo ""

  # Получаем внешний IP сервера
  SERVER_IP=$(get_external_ip 2>/dev/null || hostname -I | awk '{print $1}')

  # Домен
  while true; do
    local _pdomain
    _pdomain="$(get_str MSG_PROMPT_DOMAIN)"
    read -rp "$_pdomain" DOMAIN
    DOMAIN="${DOMAIN// /}"

    if [[ -z "$DOMAIN" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "$(get_str WARN_DOMAIN_EMPTY_RU)"
      else
        warn "$(get_str WARN_DOMAIN_EMPTY)"
      fi
      continue
    fi
    if ! validate_domain "$DOMAIN"; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "$(get_str WARN_DOMAIN_FORMAT_RU)"
      else
        warn "$(get_str WARN_DOMAIN_FORMAT)"
      fi
      continue
    fi

    # DNS check
    if ! command -v dig &>/dev/null; then
      apt-get install -y -qq dnsutils >/dev/null 2>&1
    fi
    local _resolved
    _resolved=$(dig +short "$DOMAIN" A 2>/dev/null | head -1)
    if [[ -z "$_resolved" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "$(get_str MSG_CANNOT_RESOLVE_DOMAIN_RU | sed "s/{DOMAIN}/$DOMAIN/g")"
        read -rp "  $(get_str MSG_CONTINUE_DESPITE_ERROR_RU) " _cont
      else
        warn "$(get_str MSG_CANNOT_RESOLVE_DOMAIN | sed "s/{DOMAIN}/$DOMAIN/g")"
        read -rp "  $(get_str MSG_CONTINUE_DESPITE_ERROR) " _cont
      fi
      [[ "$_cont" =~ ^[yY]$ ]] || continue
    elif [[ -n "$SERVER_IP" && "$_resolved" != "$SERVER_IP" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        local _mismatch_msg
        _mismatch_msg="$(get_str MSG_A_RECORD_MISMATCH_RU)"
        _mismatch_msg="${_mismatch_msg//\{DOMAIN\}/$DOMAIN}"
        _mismatch_msg="${_mismatch_msg//\{RESOLVED\}/$_resolved}"
        _mismatch_msg="${_mismatch_msg//\{SERVER_IP\}/$SERVER_IP}"
        warn "$_mismatch_msg"
        read -rp "  $(get_str MSG_CONTINUE_DESPITE_MISMATCH_RU) " _cont
      else
        local _mismatch_msg_en
        _mismatch_msg_en="$(get_str MSG_A_RECORD_MISMATCH)"
        _mismatch_msg_en="${_mismatch_msg_en//\{DOMAIN\}/$DOMAIN}"
        _mismatch_msg_en="${_mismatch_msg_en//\{RESOLVED\}/$_resolved}"
        _mismatch_msg_en="${_mismatch_msg_en//\{SERVER_IP\}/$SERVER_IP}"
        warn "$_mismatch_msg_en"
        read -rp "  $(get_str MSG_CONTINUE_DESPITE_MISMATCH) " _cont
      fi
      [[ "$_cont" =~ ^[yY]$ ]] || continue
    fi
    break
  done

  # Email
  local _pemail
  local _domain_placeholder="${DOMAIN}"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    _pemail="$(get_str MSG_PROMPT_EMAIL_RU | sed "s/{DOMAIN}/$_domain_placeholder/g")"
  else
    _pemail="$(get_str MSG_PROMPT_EMAIL | sed "s/{DOMAIN}/$_domain_placeholder/g")"
  fi
  read -rp "$_pemail" LE_EMAIL
  LE_EMAIL="${LE_EMAIL// /}"
  [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"

  while ! validate_email "$LE_EMAIL"; do
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "$(get_str MSG_INVALID_EMAIL_RU | sed "s/{DOMAIN}/$_domain_placeholder/g")"
    else
      warn "$(get_str MSG_INVALID_EMAIL | sed "s/{DOMAIN}/$_domain_placeholder/g")"
    fi
    read -rp "$_pemail" LE_EMAIL
    LE_EMAIL="${LE_EMAIL// /}"
    [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"
  done

  echo ""
  ok "Domain:  $DOMAIN"
  ok "Email:   $LE_EMAIL"
  echo ""

  # ── Telegram bot ───────────────────────────────────────────
  if [[ -z "$INSTALL_TELEGRAM" ]]; then
    local _ptg
    if [[ "$LANG_NAME" == "Русский" ]]; then
      _ptg="$(get_str MSG_PROMPT_TELEGRAM_RU)"
    else
      _ptg="$(get_str MSG_PROMPT_TELEGRAM)"
    fi
    read -rp "$_ptg" _tg_choice
    if [[ "$_tg_choice" =~ ^[yY]$ ]]; then
      INSTALL_TELEGRAM="true"
      if [[ "$LANG_NAME" == "Русский" ]]; then
        info "$(get_str MSG_TELEGRAM_WILL_BE_INSTALLED_RU)"
      else
        info "$(get_str MSG_TELEGRAM_WILL_BE_INSTALLED)"
      fi
    else
      INSTALL_TELEGRAM="false"
    fi
  fi

  echo ""
}

# ══════════════════════════════════════════════════════════════
# Вспомогательная функция: загрузить и вызвать модуль
# ══════════════════════════════════════════════════════════════
# Шаг в обёртке для показа прогресса [x/N]
step_module() {
  local label="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  step "$CURRENT_STEP" "$TOTAL_STEPS" "$label"
}
# Экспортируем глобальные переменные, нужные модулям
_export_globals() {
  export LANG_NAME DEV_MODE DRY_RUN DEBUG_MODE DOMAIN LE_EMAIL SERVER_IP
  export INSTALL_SCRIPT_DIR CUBIVEIL_LOG_LEVEL
}

# run_module <name> — источник, configure, enable
run_module() {
  local name="$1"
  local module_file="${INSTALL_SCRIPT_DIR}/lib/modules/${name}/install.sh"

  if [[ ! -f "$module_file" ]]; then
    warning "Module not found, skipping: $name ($module_file)"
    WARNINGS+=("Module not found: $name")
    echo -e "${YELLOW}⚠ Skipped${PLAIN}"
    return 0
  fi

  # Каждый модуль source-ится в подоболочке чтобы не загрязнить глобальную namespace
  # НО нам нужны side-effects (порты, ключи), поэтому source в текущей оболочке
  # с очисткой module_* функций после
  # shellcheck disable=SC1090
  source "$module_file"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would run: ${name}::install, configure, enable"
    unset -f module_install module_configure module_enable module_disable \
      module_update module_remove module_status module_health_check 2>/dev/null || true
    echo -e "${GREEN}✓ DRY-RUN: ${name} skipped${PLAIN}"
    return 0
  fi

  # Отключаем обильные разделители log_step для внутренних шагов модулей
  export CUBIVEIL_HIDE_LOG_STEP="true"

  local module_status=0

  if declare -f module_install >/dev/null; then
    if ! module_install; then
      warning "module_install failed for ${name}, continuing"
      WARNINGS+=("module_install failed for ${name}")
      module_status=1
    fi
  fi

  if declare -f module_configure >/dev/null; then
    if ! module_configure; then
      warning "module_configure failed for ${name}, continuing"
      WARNINGS+=("module_configure failed for ${name}")
      module_status=1
    fi
  fi

  if declare -f module_enable >/dev/null; then
    if ! module_enable; then
      warning "module_enable failed for ${name}, continuing"
      WARNINGS+=("module_enable failed for ${name}")
      module_status=1
    fi
  fi

  if [[ $module_status -eq 0 ]]; then
    success "Module ${name}: ✓ OK"
  else
    warning "Module ${name}: ⚠ Skipped with issues"
  fi

  # Сбрасываем функции модуля, чтобы следующий модуль не унаследил
  unset -f module_install module_configure module_enable module_disable \
    module_update module_remove module_status module_health_check 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════
# Шаги оркестрации (тонкая обёртка над модулями)
# ══════════════════════════════════════════════════════════════

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

  # Генерируем ключи и порты до установки, чтобы модуль SSL/Marzban их видел
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
    warn "Telegram bot setup script not found: $_setup_script"
  fi
}

# ══════════════════════════════════════════════════════════════
# Legacy API wrappers (для тестов, совместимости)
# ══════════════════════════════════════════════════════════════

select_language() { _select_language; }
print_banner() { _print_banner; }

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
step_finish() { _print_finish; }

# ══════════════════════════════════════════════════════════════
# Генерация ключей Reality и портов
# (выделено из модуля, т.к. нужно перед SSL и Marzban)
# ══════════════════════════════════════════════════════════════

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
  if [[ "$LANG_NAME" == "Русский" ]]; then
    _ports_msg="$(get_str MSG_PORTS_GENERATED_RU)"
    _ports_msg="${_ports_msg//\{TROJAN\}/$TROJAN_PORT}"
    _ports_msg="${_ports_msg//\{SS\}/$SS_PORT}"
    _ports_msg="${_ports_msg//\{PANEL\}/$PANEL_PORT}"
    _ports_msg="${_ports_msg//\{SUB\}/$SUB_PORT}"
    ok "$(get_str OK_REALITY_GENERATED_RU | sed "s/\[REALITY_SNI\]/$REALITY_SNI/g")"
    ok "$_ports_msg"
  else
    _ports_msg="$(get_str MSG_PORTS_GENERATED)"
    _ports_msg="${_ports_msg//\{TROJAN\}/$TROJAN_PORT}"
    _ports_msg="${_ports_msg//\{SS\}/$SS_PORT}"
    _ports_msg="${_ports_msg//\{PANEL\}/$PANEL_PORT}"
    _ports_msg="${_ports_msg//\{SUB\}/$SUB_PORT}"
    ok "$(get_str OK_REALITY_GENERATED | sed "s/\[REALITY_SNI\]/$REALITY_SNI/g")"
    ok "$_ports_msg"
  fi
}

# ══════════════════════════════════════════════════════════════
# Dry-run: показать план без изменений
# ══════════════════════════════════════════════════════════════

_dry_run_plan() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  $(get_str MSG_DRY_RUN_TITLE)"
  echo "══════════════════════════════════════════════════════════"
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
    echo "  Mode:   DEV (self-signed SSL, no DNS check)"
    echo "  Domain: ${DOMAIN}"
  else
    echo "  Mode:   PRODUCTION (Let's Encrypt)"
    echo "  Domain: ${DOMAIN:-<will be prompted>}"
    echo "  Email:  ${LE_EMAIL:-<will be prompted>}"
  fi
  echo ""

  # Проверка окружения (без изменений)
  check_root
  check_ubuntu
  echo -e "\033[0;32m  [DRY-RUN] Environment checks: OK\033[0m"
  echo ""
  echo "  $(get_str MSG_DRY_RUN_NO_CHANGES)"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Финальный вывод
# ══════════════════════════════════════════════════════════════

_print_finish() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "  ✅ CubiVeil $(get_str MSG_INSTALLED_SUCCESSFULLY_RU)"
  else
    echo "  ✅ CubiVeil $(get_str MSG_INSTALLED_SUCCESSFULLY)"
  fi
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
    echo -e "${YELLOW}⚠ Warnings during install:${PLAIN}"
    for _warn in "${WARNINGS[@]}"; do
      echo -e "  - ${_warn}"
    done
    echo ""
  fi

  # Выделение финального блока (URL + credentials)
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${PLAIN}"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo -e "${GREEN}  $(get_str SUCCESS_PANEL_URL_RU)     ${_panel_url}${PLAIN}"
    echo -e "${GREEN}  $(get_str SUCCESS_SUBSCRIPTION_URL_RU)   ${_sub_url}${PLAIN}"
    echo ""
    echo "  $(get_str SUCCESS_PROFILES_RU) Trojan · Shadowsocks · VLESS · VMess · Hysteria2"
    echo ""
    [[ "$DEV_MODE" == "true" ]] &&
      warn "⚠  $(get_str MSG_BROWSERS_SECURITY_WARNING_RU)"
    echo ""
    echo "  $(get_str NEXT_STEPS_RU)"
    echo "    $(get_str MSG_NEXT_STEP_CREATE_USERS_RU)"
    echo "    $(get_str MSG_NEXT_STEP_SUBSCRIPTION_RU)"
    echo "    $(get_str MSG_NEXT_STEP_SSH_RU)"
    if [[ "$INSTALL_TELEGRAM" != "true" ]]; then
      echo "    $(get_str MSG_NEXT_STEP_TELEGRAM_RU)"
    fi
  else
    echo "  $(get_str SUCCESS_PANEL_URL)        ${_panel_url}"
    echo "  $(get_str SUCCESS_SUBSCRIPTION_URL) ${_sub_url}"
    echo ""
    echo "  $(get_str SUCCESS_PROFILES) Trojan · Shadowsocks · VLESS · VMess · Hysteria2"
    echo ""
    [[ "$DEV_MODE" == "true" ]] &&
      warn "⚠  $(get_str MSG_BROWSERS_SECURITY_WARNING)"
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
    if [[ "$LANG_NAME" == "Русский" ]]; then
      echo -e "${GREEN}  $(get_str MSG_ADMIN_CREDENTIALS_RU)${PLAIN}"
    else
      echo -e "${GREEN}  $(get_str MSG_ADMIN_CREDENTIALS)${PLAIN}"
    fi
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
      if [[ "$LANG_NAME" == "Русский" ]]; then
        echo "  $(get_str MSG_MIKROTIK_SCRIPT_RU)"
      else
        echo "  $(get_str MSG_MIKROTIK_SCRIPT)"
      fi
      echo "══════════════════════════════════════════════════════════"
      # shellcheck disable=SC1090
      source "$_mikrotik_mod"

      # Сохраняем скрипт в файл
      if declare -f decoy_save_mikrotik_script >/dev/null; then
        decoy_save_mikrotik_script "/etc/cubiveil/mikrotik-decoy.rsc"
        echo ""
        echo "  Скрипт сохранён: /etc/cubiveil/mikrotik-decoy.rsc"
        echo "  Для импорта в MikroTik:"
        echo "    1. Скопируйте файл на компьютер"
        echo "    2. В WinBox: Files → перетащите mikrotik-decoy.rsc"
        echo "    3. В Terminal: /import file-name= mikrotik-decoy.rsc"
      fi

      # Вывод в терминал
      echo ""
      declare -f decoy_print_mikrotik_script >/dev/null && decoy_print_mikrotik_script || true
      echo "══════════════════════════════════════════════════════════"
    fi
  fi

  echo ""
}

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

  # Инициализация счётчика шагов
  CURRENT_STEP=0
  TOTAL_STEPS=9

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
