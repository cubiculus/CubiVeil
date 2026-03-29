#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Bootstrap                                     ║
# ║  Загрузка файлов репозитория при curl-установке          ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Переменные ──────────────────────────────────────────────
REPO_URL="https://raw.githubusercontent.com/cubiculus/cubiveil/main"
TEMP_DIR=""

# ── Функции ─────────────────────────────────────────────────

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
  local _msg_failed
  _msg_failed="$(get_str MSG_FAILED_DOWNLOAD | sed "s/{FILE}/$file/g")"
  echo -e "\033[0;31m[✗]\033[0m $_msg_failed"
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
    "$TEMP_DIR/lib/modules/s-ui" \
    "$TEMP_DIR/lib/modules/backup" \
    "$TEMP_DIR/lib/modules/rollback" \
    "$TEMP_DIR/lib/modules/monitoring" \
    "$TEMP_DIR/assets/telegram-bot"

  local files=(
    "lang/main.sh"
    "lang/telegram.sh"
    "setup-telegram.sh"
    "lib/fallback.sh" "lib/common.sh" "lib/utils.sh"
    "lib/output.sh" "lib/security.sh" "lib/i18n.sh"
    "lib/validation.sh" "lib/manifest.sh"
    "lib/core/log.sh" "lib/core/system.sh"
    "lib/modules/system/install.sh"
    "lib/modules/firewall/install.sh"
    "lib/modules/fail2ban/install.sh"
    "lib/modules/ssl/install.sh"
    "lib/modules/s-ui/install.sh"
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
      local _msg_critical
      _msg_critical="$(get_str MSG_CRITICAL_FILE_MISSING | sed "s/{FILE}/$f/g")"
      echo "[✗] $_msg_critical"
      return 1
    }
  done
  INSTALL_SCRIPT_DIR="$TEMP_DIR"
}

# Обработка ошибки setup_remote_install
handle_setup_error() {
  local _msg_failed_prepare
  local _msg_clone_run
  _msg_failed_prepare="$(get_str MSG_FAILED_PREPARE)"
  _msg_clone_run="$(get_str MSG_CLONE_AND_RUN)"
  echo -e "\033[0;31m[✗]\033[0m $_msg_failed_prepare"
  echo ""
  echo "$_msg_clone_run"
  echo "  git clone https://github.com/cubiculus/cubiveil.git && cd cubiveil && sudo bash install.sh"
  exit 1
}
