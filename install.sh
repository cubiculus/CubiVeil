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
    "$TEMP_DIR/lib/modules/monitoring"

  local files=(
    "lang.sh"
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
DEV_DOMAIN="dev.cubiveil.local"
DOMAIN=""
INSTALL_DECOY="true"
INSTALL_TRAFFIC_SHAPING="true"

# Переменные, которые будут заполнены в prompt_inputs()
LE_EMAIL=""
LANG_NAME="Русский"
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
    --domain=*) DOMAIN="${1#*=}" ;;
    --no-decoy) INSTALL_DECOY="false" ;;
    --no-traffic-shaping) INSTALL_TRAFFIC_SHAPING="false" ;;
    --help | -h)
      _usage
      exit 0
      ;;
    *) ;;
    esac
    shift
  done
}

_usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

CubiVeil Installer — Marzban + Sing-box

Options:
  --dev                 Dev mode: self-signed SSL, no domain required
  --dry-run             Simulate install without changing the system
  --domain=NAME         Set domain (default in dev mode: ${DEV_DOMAIN})
  --no-decoy            Skip decoy-site installation
  --no-traffic-shaping  Skip traffic-shaping module
  --help, -h            Show this help

Examples:
  sudo bash install.sh
  sudo bash install.sh --dev
  sudo bash install.sh --dev --dry-run
  sudo bash install.sh --domain=panel.example.com
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

source "${INSTALL_SCRIPT_DIR}/lib/fallback.sh" 2>/dev/null || true
source "${INSTALL_SCRIPT_DIR}/lang.sh" 2>/dev/null || true
source "${INSTALL_SCRIPT_DIR}/lib/output.sh" || {
  echo "[✗] Cannot load lib/output.sh"
  exit 1
}
source "${INSTALL_SCRIPT_DIR}/lib/common.sh" || { err "Cannot load lib/common.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/utils.sh" || { err "Cannot load lib/utils.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/validation.sh" || { err "Cannot load lib/validation.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/security.sh" || { err "Cannot load lib/security.sh"; }
source "${INSTALL_SCRIPT_DIR}/lib/i18n.sh" || { err "Cannot load lib/i18n.sh"; }

# ══════════════════════════════════════════════════════════════
# Выбор языка / Language selection
# ══════════════════════════════════════════════════════════════

_select_language() {
  echo ""
  echo "Select language / Выберите язык:"
  echo "  1) Русский"
  echo "  2) English"
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
    *) echo "  Invalid choice / Неверный выбор" ;;
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
  [[ "$LANG_NAME" == "Русский" ]] &&
    _step_label="Настройка перед установкой" ||
    _step_label="Pre-installation setup"
  step "$_step_label"

  # ── DEV MODE ──────────────────────────────────────────────
  if [[ "$DEV_MODE" == "true" ]]; then
    [[ -z "$DOMAIN" ]] && DOMAIN="$DEV_DOMAIN"
    LE_EMAIL="admin@${DOMAIN}"
    if [[ "$LANG_NAME" == "Русский" ]]; then
      info "DEV-режим: самоподписной SSL, домен: ${DOMAIN}"
      warn "Браузеры покажут предупреждение о безопасности"
      warn "Не используйте в production!"
    else
      info "DEV mode: self-signed SSL, domain: ${DOMAIN}"
      warn "Browsers will show a security warning"
      warn "Do not use in production!"
    fi
    echo ""
    ok "Domain:  $DOMAIN"
    ok "Email:   $LE_EMAIL"
    echo ""
    return 0
  fi

  # ── PRODUCTION MODE ───────────────────────────────────────
  if [[ "$LANG_NAME" == "Русский" ]]; then
    warn "Убедитесь, что A-запись домена уже указывает на этот сервер."
    warn "Let's Encrypt проверит DNS — установка упадёт без правильной A-записи."
  else
    warn "Make sure the domain A record already points to this server."
    warn "Let's Encrypt will check DNS — install will fail without a valid A record."
  fi
  echo ""

  # Получаем внешний IP сервера
  SERVER_IP=$(get_external_ip 2>/dev/null || hostname -I | awk '{print $1}')

  # Домен
  while true; do
    local _pdomain
    [[ "$LANG_NAME" == "Русский" ]] &&
      _pdomain="  Домен для панели (например panel.example.com): " ||
      _pdomain="  Domain for panel (e.g. panel.example.com): "
    read -rp "$_pdomain" DOMAIN
    DOMAIN="${DOMAIN// /}"

    if [[ -z "$DOMAIN" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Домен не может быть пустым"
      else
        warn "Domain cannot be empty"
      fi
      continue
    fi
    if ! validate_domain "$DOMAIN"; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Некорректный формат домена. Пример: panel.example.com"
      else
        warn "Invalid domain format. Example: panel.example.com"
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
        warn "Не удалось разрешить $DOMAIN. Проверьте A-запись."
        read -rp "  Продолжить несмотря на ошибку? (y/n): " _cont
      else
        warn "Cannot resolve $DOMAIN. Check your A record."
        read -rp "  Continue despite the error? (y/n): " _cont
      fi
      [[ "$_cont" =~ ^[yY]$ ]] || continue
    elif [[ -n "$SERVER_IP" && "$_resolved" != "$SERVER_IP" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "A-запись $DOMAIN → $_resolved, но IP сервера: $SERVER_IP"
        read -rp "  Продолжить несмотря на несоответствие? (y/n): " _cont
      else
        warn "A record $DOMAIN → $_resolved, but server IP: $SERVER_IP"
        read -rp "  Continue despite the mismatch? (y/n): " _cont
      fi
      [[ "$_cont" =~ ^[yY]$ ]] || continue
    fi
    break
  done

  # Email
  local _pemail
  [[ "$LANG_NAME" == "Русский" ]] &&
    _pemail="  Email для Let's Encrypt [admin@${DOMAIN}]: " ||
    _pemail="  Email for Let's Encrypt [admin@${DOMAIN}]: "
  read -rp "$_pemail" LE_EMAIL
  LE_EMAIL="${LE_EMAIL// /}"
  [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"

  while ! validate_email "$LE_EMAIL"; do
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Некорректный email. Пример: admin@${DOMAIN}"
    else
      warn "Invalid email. Example: admin@${DOMAIN}"
    fi
    read -rp "$_pemail" LE_EMAIL
    LE_EMAIL="${LE_EMAIL// /}"
    [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"
  done

  echo ""
  ok "Domain:  $DOMAIN"
  ok "Email:   $LE_EMAIL"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Вспомогательная функция: загрузить и вызвать модуль
# ══════════════════════════════════════════════════════════════

# Экспортируем глобальные переменные, нужные модулям
_export_globals() {
  export LANG_NAME DEV_MODE DRY_RUN DOMAIN LE_EMAIL SERVER_IP
  export INSTALL_SCRIPT_DIR
}

# run_module <name> — источник, configure, enable
run_module() {
  local name="$1"
  local module_file="${INSTALL_SCRIPT_DIR}/lib/modules/${name}/install.sh"

  if [[ ! -f "$module_file" ]]; then
    warn "Module not found, skipping: $name ($module_file)"
    return 0
  fi

  # Каждый модуль source-ится в подоболочке чтобы не загрязнять глобальный namespace
  # НО нам нужны side-effects (порты, ключи), поэтому source в текущей оболочке
  # с очисткой module_* функций после
  # shellcheck disable=SC1090
  source "$module_file"

  if [[ "$DRY_RUN" == "true" ]]; then
    info "[DRY-RUN] Would run: ${name}::install, configure, enable"
    return 0
  fi

  declare -f module_install >/dev/null && module_install
  declare -f module_configure >/dev/null && module_configure
  declare -f module_enable >/dev/null && module_enable

  # Сбрасываем функции модуля, чтобы следующий модуль не унаследовал
  unset -f module_install module_configure module_enable module_disable \
    module_update module_remove module_status module_health_check 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════
# Шаги оркестрации (тонкая обёртка над модулями)
# ══════════════════════════════════════════════════════════════

_step_system() {
  local _label
  [[ "$LANG_NAME" == "Русский" ]] &&
    _label="Шаг 1/8 — Обновление системы и базовые настройки" ||
    _label="Step 1/8 — System update and base configuration"
  step "$_label"
  run_module "system"
}

_step_firewall() {
  local _label
  [[ "$LANG_NAME" == "Русский" ]] &&
    _label="Шаг 2/8 — Файрвол (UFW)" ||
    _label="Step 2/8 — Firewall (UFW)"
  step "$_label"
  run_module "firewall"
}

_step_fail2ban() {
  local _label
  [[ "$LANG_NAME" == "Русский" ]] &&
    _label="Шаг 3/8 — Fail2ban" ||
    _label="Step 3/8 — Fail2ban"
  step "$_label"
  run_module "fail2ban"
}

_step_singbox() {
  local _label
  [[ "$LANG_NAME" == "Русский" ]] &&
    _label="Шаг 4/8 — Sing-box" ||
    _label="Step 4/8 — Sing-box"
  step "$_label"

  # Генерируем ключи и порты до установки, чтобы модуль SSL/Marzban их видел
  _generate_keys_and_ports
  run_module "singbox"
}

_step_ssl() {
  local _label
  [[ "$LANG_NAME" == "Русский" ]] &&
    _label="Шаг 5/8 — SSL сертификат" ||
    _label="Step 5/8 — SSL certificate"
  step "$_label"
  run_module "ssl"
}

_step_marzban() {
  local _label
  [[ "$LANG_NAME" == "Русский" ]] &&
    _label="Шаг 6/8 — Marzban" ||
    _label="Step 6/8 — Marzban"
  step "$_label"
  run_module "marzban"
}

_step_decoy() {
  [[ "$INSTALL_DECOY" != "true" ]] && return 0
  local _label
  [[ "$LANG_NAME" == "Русский" ]] &&
    _label="Шаг 7/8 — Сайт-прикрытие (decoy)" ||
    _label="Step 7/8 — Decoy site"
  step "$_label"
  run_module "decoy-site"
}

_step_traffic_shaping() {
  [[ "$INSTALL_TRAFFIC_SHAPING" != "true" ]] && return 0
  local _label
  [[ "$LANG_NAME" == "Русский" ]] &&
    _label="Шаг 8/8 — Traffic shaping" ||
    _label="Step 8/8 — Traffic shaping"
  step "$_label"
  run_module "traffic-shaping"
}

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

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Reality keypair сгенерирован, camouflage: ${REALITY_SNI}"
    ok "Порты → Trojan:${TROJAN_PORT} SS:${SS_PORT} Панель:${PANEL_PORT} Подписки:${SUB_PORT}"
  else
    ok "Reality keypair generated, camouflage: ${REALITY_SNI}"
    ok "Ports → Trojan:${TROJAN_PORT} SS:${SS_PORT} Panel:${PANEL_PORT} Subscription:${SUB_PORT}"
  fi
}

# ══════════════════════════════════════════════════════════════
# Dry-run: показать план без изменений
# ══════════════════════════════════════════════════════════════

_dry_run_plan() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  [DRY-RUN] Installation plan / План установки"
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
  echo "  [DRY-RUN] No changes were made to the system."
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Финальный вывод
# ══════════════════════════════════════════════════════════════

_print_finish() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "  ✅ CubiVeil установлен успешно! 🎉"
  else
    echo "  ✅ CubiVeil installed successfully! 🎉"
  fi
  echo "══════════════════════════════════════════════════════════"
  echo ""

  local _panel_url="https://${DOMAIN}:${PANEL_PORT:-8080}"
  local _sub_url="https://${DOMAIN}:${SUB_PORT:-8081}/subscription"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "  URL панели:     ${_panel_url}"
    echo "  URL подписки:   ${_sub_url}"
    echo ""
    echo "  Профили: Trojan · Shadowsocks · VLESS · VMess · Hysteria2"
    echo ""
    [[ "$DEV_MODE" == "true" ]] &&
      warn "⚠  DEV-режим: самоподписной SSL — браузеры покажут предупреждение"
    echo ""
    echo "  Следующие шаги:"
    echo "    1. Зайдите в панель → создайте пользователей"
    echo "    2. Subscription URL скопируйте в Mihomo/клиент"
    echo "    3. Смените SSH порт, закройте 22 в UFW"
    echo "    4. Установите Telegram-бот: bash setup-telegram.sh"
  else
    echo "  Panel URL:        ${_panel_url}"
    echo "  Subscription URL: ${_sub_url}"
    echo ""
    echo "  Profiles: Trojan · Shadowsocks · VLESS · VMess · Hysteria2"
    echo ""
    [[ "$DEV_MODE" == "true" ]] &&
      warn "⚠  DEV mode: self-signed SSL — browsers will show a warning"
    echo ""
    echo "  Next steps:"
    echo "    1. Log in to panel → create users"
    echo "    2. Copy Subscription URL to your client"
    echo "    3. Change SSH port, close 22 in UFW"
    echo "    4. Setup Telegram bot: bash setup-telegram.sh"
  fi

  # MikroTik скрипт (если decoy установлен)
  if [[ "$INSTALL_DECOY" == "true" && -f "/etc/cubiveil/decoy.json" ]]; then
    local _mikrotik_mod="${INSTALL_SCRIPT_DIR}/lib/modules/decoy-site/mikrotik.sh"
    if [[ -f "$_mikrotik_mod" ]]; then
      echo ""
      echo "══════════════════════════════════════════════════════════"
      [[ "$LANG_NAME" == "Русский" ]] &&
        echo "  MikroTik RouterOS скрипт (decoy-site):" ||
        echo "  MikroTik RouterOS script (decoy-site):"
      echo "══════════════════════════════════════════════════════════"
      # shellcheck disable=SC1090
      source "$_mikrotik_mod"
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

  # Выбор языка
  _select_language

  _print_banner

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

  # Оркестрация модулей
  _step_system
  _step_firewall
  _step_fail2ban
  _step_singbox
  _step_ssl
  _step_marzban
  _step_decoy
  _step_traffic_shaping

  _print_finish
}

main "$@"
