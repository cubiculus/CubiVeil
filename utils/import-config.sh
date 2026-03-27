#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Import Config Utility                 ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Импорт конфигурации после экспорта                       ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

if [[ -f "${PROJECT_DIR}/lang.sh" ]]; then
  source "${PROJECT_DIR}/lang.sh"
else
  source "${PROJECT_DIR}/lib/fallback.sh"
fi

# ── Подключение общих утилит ───────────────────────────────────
source "${PROJECT_DIR}/lib/output.sh" || {
  echo "❌ Не удалось загрузить lib/output.sh" >&2
  exit 1
}

source "${PROJECT_DIR}/lib/utils.sh" || {
  echo "❌ Не удалось загрузить lib/utils.sh" >&2
  exit 1
}

# ── Локализация ───────────────────────────────────────────────
declare -A MSG=(
  [TITLE]="CubiVeil — Import Config"
  [USAGE]="Использование"
  [ERR_NO_ROOT]="Требуется запуск от root"
  [ERR_NO_SOURCE_DIR]="Не указана директория с конфигурацией"
  [ERR_DIR_NOT_FOUND]="Директория не найдена"
  [ERR_NO_MARZBAN_DIR]="Директория Marzban не найдена в экспорте"
  [ERR_NO_SINGBOX_DIR]="Директория Sing-box не найдена в экспорте"
  [ERR_NO_CUBIVEIL_DIR]="Директория CubiVeil не найдена в экспорте"
  [MSG_IMPORTING]="Импорт конфигурации из"
  [MSG_RESTORED]="восстановлен"
  [MSG_PERMISSIONS]="Настройка прав доступа"
  [MSG_SUCCESS]="Импорт завершён успешно"
  [MSG_RESTART]="Перезапуск сервисов"
  [PROMPT_RESTART]="Перезапустить сервисы? (y/n)"
)

# ── Проверка окружения ────────────────────────────────────────
check_environment() {
  if [[ $EUID -ne 0 ]]; then
    echo "${MSG[ERR_NO_ROOT]}" >&2
    exit 1
  fi

  if [[ -z "${1:-}" ]]; then
    echo "${MSG[ERR_NO_SOURCE_DIR]}" >&2
    echo "${MSG[USAGE]}: $0 <source_dir>" >&2
    exit 1
  fi

  local source_dir="$1"

  if [[ ! -d "$source_dir" ]]; then
    echo "${MSG[ERR_DIR_NOT_FOUND]}: $source_dir" >&2
    exit 1
  fi

  export SOURCE_DIR="$source_dir"
}

# ── Импорт конфигурации Marzban ───────────────────────────────
import_marzban_config() {
  step_title "1" "Импорт Marzban" "Marzban Import"

  local marzban_source="${SOURCE_DIR}/marzban"

  if [[ ! -d "$marzban_source" ]]; then
    err "${MSG[ERR_NO_MARZBAN_DIR]}"
  fi

  info "${MSG[MSG_IMPORTING]}: Marzban..."

  # Восстановление .env
  if [[ -f "${marzban_source}/.env" ]]; then
    cp "${marzban_source}/.env" /opt/marzban/.env
    ok ".env ${MSG[MSG_RESTORED]}"
  fi

  # Восстановление базы данных
  if [[ -f "${marzban_source}/db.sqlite3" ]]; then
    cp "${marzban_source}/db.sqlite3" /opt/marzban/db.sqlite3
    ok "db.sqlite3 ${MSG[MSG_RESTORED]}"
  fi

  # Восстановление Xray configs
  if [[ -d "${marzban_source}/xray_config" ]]; then
    cp -rp "${marzban_source}/xray_config" /opt/marzban/
    ok "Xray configs ${MSG[MSG_RESTORED]}"
  fi
}

# ── Импорт конфигурации Sing-box ──────────────────────────────
import_singbox_config() {
  step_title "2" "Импорт Sing-box" "Sing-box Import"

  local singbox_source="${SOURCE_DIR}/sing-box"

  if [[ ! -d "$singbox_source" ]]; then
    err "${MSG[ERR_NO_SINGBOX_DIR]}"
  fi

  info "${MSG[MSG_IMPORTING]}: Sing-box..."

  # Восстановление config.json
  if [[ -f "${singbox_source}/config.json" ]]; then
    cp "${singbox_source}/config.json" /etc/sing-box/config.json
    ok "config.json ${MSG[MSG_RESTORED]}"
  fi
}

# ── Импорт конфигурации CubiVeil ──────────────────────────────
import_cubiveil_config() {
  step_title "3" "Импорт CubiVeil" "CubiVeil Import"

  local cubiveil_source="${SOURCE_DIR}/cubiveil"

  if [[ ! -d "$cubiveil_source" ]]; then
    err "${MSG[ERR_NO_CUBIVEIL_DIR]}"
  fi

  info "${MSG[MSG_IMPORTING]}: CubiVeil..."

  # Восстановление файлов проекта
  if [[ -d "${cubiveil_source}" ]]; then
    cp -rp "${cubiveil_source}/"* /opt/cubiveil/ 2>/dev/null || true
    ok "Project files ${MSG[MSG_RESTORED]}"
  fi

  # Восстановление bot.env
  if [[ -f "/etc/cubiveil/bot.env" ]] && [[ -f "${cubiveil_source}/bot.env.backup" ]]; then
    cp "${cubiveil_source}/bot.env.backup" /etc/cubiveil/bot.env
    chmod 600 /etc/cubiveil/bot.env
    ok "bot.env ${MSG[MSG_RESTORED]}"
  fi
}

# ── Настройка прав доступа ────────────────────────────────────
set_permissions() {
  step_title "4" "${MSG[MSG_PERMISSIONS]}" "Setting Permissions"

  # Marzban
  if [[ -d "/opt/marzban" ]]; then
    chown -R root:root /opt/marzban
    chmod 600 /opt/marzban/.env 2>/dev/null || true
    chmod 600 /opt/marzban/db.sqlite3 2>/dev/null || true
    ok "Marzban permissions set"
  fi

  # Sing-box
  if [[ -d "/etc/sing-box" ]]; then
    chown -R singbox:singbox /etc/sing-box 2>/dev/null || true
    ok "Sing-box permissions set"
  fi

  # CubiVeil
  if [[ -d "/opt/cubiveil" ]]; then
    chown -R root:root /opt/cubiveil
    ok "CubiVeil permissions set"
  fi

  # Bot
  if [[ -d "/opt/cubiveil-bot" ]]; then
    chown -R root:root /opt/cubiveil-bot
    ok "Bot permissions set"
  fi
}

# ── Перезапуск сервисов ───────────────────────────────────────
restart_services() {
  step_title "5" "${MSG[MSG_RESTART]}" "Restarting Services"

  read -rp "  ${MSG[PROMPT_RESTART]}: " confirm

  if [[ "${confirm,,}" == "y" ]]; then
    info "Restarting services..."

    systemctl restart marzban 2>/dev/null && ok "Marzban restarted" || warn "Marzban restart failed"
    systemctl restart sing-box 2>/dev/null && ok "Sing-box restarted" || warn "Sing-box restart failed"
    systemctl restart cubiveil-bot 2>/dev/null && ok "Bot restarted" || warn "Bot restart failed"
  else
    info "Services not restarted"
  fi
}

# ── Завершение ────────────────────────────────────────────────
step_finish() {
  step_title "6" "Завершение" "Finish"

  success "${MSG[MSG_SUCCESS]}"

  echo ""
  echo "  ────────────────────────────────────────────────────────"
  echo "  Imported from: ${SOURCE_DIR}"
  echo ""
  echo "  Next steps:"
  echo "    1. Check services: systemctl status marzban sing-box cubiveil-bot"
  echo "    2. Check logs: journalctl -u marzban -u sing-box -u cubiveil-bot -f"
  echo "    3. Test panel: https://\$(hostname):8080"
  echo "  ────────────────────────────────────────────────────────"
}

# ── Точка входа ───────────────────────────────────────────────
main() {
  check_environment "$@"
  import_marzban_config
  import_singbox_config
  import_cubiveil_config
  set_permissions
  restart_services
  step_finish
}

main "$@"
