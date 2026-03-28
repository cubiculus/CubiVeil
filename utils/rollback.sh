#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Rollback Utility                      ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Откат к предыдущей версии из бэкапа                      ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
if [[ -f "${PROJECT_DIR}/lang/main.sh" ]]; then
  source "${PROJECT_DIR}/lang/main.sh"
else
  source "${PROJECT_DIR}/lib/fallback.sh"
fi

# ── Подключение общих утилит ───────────────────────────────────
source "${PROJECT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}

# ── Константы ─────────────────────────────────────────────────
CUBIVEIL_DIR="/opt/cubiveil"
BACKUP_DIR="/root/cubiveil-backup"
MARZBAN_DIR="/opt/marzban"

# ══════════════════════════════════════════════════════════════
# ШАГ 1: Проверка окружения
# ══════════════════════════════════════════════════════════════
step_check_environment() {
  step_title "1" "Проверка окружения" "Environment check"

  if [[ $EUID -ne 0 ]]; then
    err "$(get_str "MSG_ERR_ROOT_REQUIRED")"
  fi

  if [[ ! -d "${BACKUP_DIR}" ]]; then
    err "$(get_str "MSG_ERR_NO_BACKUPS")"
  fi

  success "$(get_str "MSG_INFO_ENV_CHECKED")"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Выбор бэкапа
# ══════════════════════════════════════════════════════════════
step_select_backup() {
  step_title "2" "$(get_str "MSG_TITLE_ROLLBACK_CHECK")" "$(get_str "MSG_TITLE_ROLLBACK_CHECK")"

  # Находим все бэкапы
  local backups=()
  while IFS= read -r -d '' dir; do
    if [[ -d "$dir" ]] && [[ -f "$dir/.timestamp" ]]; then
      backups+=("$dir")
    fi
  done < <(find "${BACKUP_DIR}" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null | sort -z -r)

  if [[ ${#backups[@]} -eq 0 ]]; then
    err "$(get_str "MSG_ERR_NO_BACKUPS")"
  fi

  info "$(get_str "MSG_MSG_AVAILABLE_BACKUPS"):"
  echo ""

  # Выводим список бэкапов
  local i=1
  declare -gA BACKUP_MAP
  for backup in "${backups[@]}"; do
    local timestamp
    local version
    timestamp=$(cat "$backup/.timestamp" 2>/dev/null || echo "unknown")
    version=$(cat "$backup/.version" 2>/dev/null || echo "unknown")

    if [[ "$LANG_NAME" == "Русский" ]]; then
      printf "  %d) %s (версия: %s)\n" "$i" "$timestamp" "$version"
    else
      printf "  %d) %s (version: %s)\n" "$i" "$timestamp" "$version"
    fi

    BACKUP_MAP[$i]="$backup"
    ((i++))
  done

  echo ""

  # Выбор бэкапа
  local selected
  read -rp "  $(get_str "MSG_PROMPT_SELECT_BACKUP") [1-${#backups[@]}]: " selected

  if [[ ! "$selected" =~ ^[0-9]+$ ]] || [[ -z "${BACKUP_MAP[$selected]:-}" ]]; then
    err "Invalid selection"
  fi

  export SELECTED_BACKUP="${BACKUP_MAP[$selected]}"
  success "$(get_str "MSG_MSG_SELECTED_BACKUP"): ${SELECTED_BACKUP}"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Проверка бэкапа
# ══════════════════════════════════════════════════════════════
step_validate_backup() {
  step_title "3" "Проверка целостности бэкапа" "Backup validation"

  # Проверяем наличие критических файлов
  local has_cubiveil=false
  local has_marzban=false

  if [[ -d "${SELECTED_BACKUP}/cubiveil" ]]; then
    has_cubiveil=true
    info "✓ CubiVeil файлы найдены"
  fi

  if [[ -d "${SELECTED_BACKUP}/marzban" ]]; then
    has_marzban=true
    info "✓ Marzban конфиги найдены"
  fi

  if [[ "$has_cubiveil" == "false" ]] && [[ "$has_marzban" == "false" ]]; then
    err "$(get_str "MSG_ERR_BACKUP_INVALID")"
  fi

  # Проверка дополнительных конфигов если есть
  if [[ -f "${SELECTED_BACKUP}/.cubiveil-age-key.txt" ]]; then
    info "✓ Ключ шифрования age найден"
  fi

  if [[ -d "${SELECTED_BACKUP}/marzban" ]]; then
    info "✓ Конфиги /etc/marzban найдены"
  fi

  if [[ -d "${SELECTED_BACKUP}/sing-box" ]]; then
    info "✓ Конфиги /etc/sing-box найдены"
  fi

  if [[ -d "${SELECTED_BACKUP}/letsencrypt" ]]; then
    info "✓ SSL сертификаты найдены"
  fi

  success "Бэкап проверен"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Подтверждение отката
# ══════════════════════════════════════════════════════════════
step_confirm_rollback() {
  step_title "4" "Подтверждение отката" "Confirm rollback"

  warning "$(get_str "MSG_WARN_CURRENT_DATA_REPLACED")"
  echo ""
  info "Бэкап: ${SELECTED_BACKUP}"

  read -rp "  $(get_str "MSG_WARN_CONTINUE_ROLLBACK") [y/N]: " confirm

  if [[ "${confirm,,}" != "y" ]]; then
    info "$(get_str "MSG_INFO_ROLLBACK_CANCELLED")"
    exit 0
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 5: Остановка сервисов
# ══════════════════════════════════════════════════════════════
step_stop_services() {
  step_title "5" "$(get_str "MSG_TITLE_STOP")" "$(get_str "MSG_TITLE_STOP")"

  info "Остановка сервисов..."

  # Останавливаем сервисы в обратном порядке
  systemctl stop cubiveil-bot 2>/dev/null || true
  info "  ✓ Бот остановлен"

  systemctl stop marzban 2>/dev/null || true
  info "  ✓ Marzban остановлен"

  systemctl stop sing-box 2>/dev/null || true
  info "  ✓ Sing-box остановлен"

  success "$(get_str "MSG_INFO_SERVICES_STOPPED")"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 6: Восстановление файлов
# ══════════════════════════════════════════════════════════════
step_restore_files() {
  step_title "6" "$(get_str "MSG_TITLE_RESTORE")" "$(get_str "MSG_TITLE_RESTORE")"

  info "$(get_str "MSG_MSG_RESTORING")..."

  # Восстанавливаем CubiVeil
  if [[ -d "${SELECTED_BACKUP}/cubiveil" ]]; then
    info "  Восстановление CubiVeil..."
    rm -rf "${CUBIVEIL_DIR}" 2>/dev/null || true
    cp -rp "${SELECTED_BACKUP}/cubiveil" "${CUBIVEIL_DIR}"
    info "    ✓ CubiVeil восстановлен"
  fi

  # Восстанавливаем Marzban
  if [[ -d "${SELECTED_BACKUP}/marzban" ]]; then
    info "  Восстановление Marzban..."
    # Не удаляем полностью, а merge
    cp -rp "${SELECTED_BACKUP}/marzban/"* "${MARZBAN_DIR}/" 2>/dev/null || true
    info "    ✓ Marzban восстановлен"
  fi

  # Восстанавливаем ключи шифрования
  if [[ -f "${SELECTED_BACKUP}/.cubiveil-age-key.txt" ]]; then
    info "  Восстановление ключа age..."
    cp "${SELECTED_BACKUP}/.cubiveil-age-key.txt" "/root/.cubiveil-age-key.txt"
    chmod 600 "/root/.cubiveil-age-key.txt"
    info "    ✓ Ключ age восстановлен"
  fi

  # Восстанавливаем SSL сертификаты если есть
  if [[ -d "${SELECTED_BACKUP}/letsencrypt" ]]; then
    info "  Восстановление SSL сертификатов..."
    cp -rp "${SELECTED_BACKUP}/letsencrypt" "/etc/letsencrypt" 2>/dev/null || true
    info "    ✓ SSL сертификаты восстановлены"
  fi

  # Восстанавливаем конфиги из /etc если есть
  if [[ -d "${SELECTED_BACKUP}/marzban" ]]; then
    info "  Восстановление /etc/marzban..."
    mkdir -p "/etc/marzban" 2>/dev/null || true
    cp -rp "${SELECTED_BACKUP}/marzban/"* "/etc/marzban/" 2>/dev/null || true
    info "    ✓ /etc/marzban восстановлена"
  fi

  if [[ -d "${SELECTED_BACKUP}/sing-box" ]]; then
    info "  Восстановление /etc/sing-box..."
    mkdir -p "/etc/sing-box" 2>/dev/null || true
    cp -rp "${SELECTED_BACKUP}/sing-box/"* "/etc/sing-box/" 2>/dev/null || true
    info "    ✓ /etc/sing-box восстановлена"
  fi

  success "$(get_str "MSG_MSG_RESTORED")"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 7: Восстановление конфигурации
# ══════════════════════════════════════════════════════════════
step_restore_config() {
  step_title "7" "$(get_str "MSG_TITLE_CONFIG")" "$(get_str "MSG_TITLE_CONFIG")"

  info "Проверка конфигурации..."

  # Проверяем .env Marzban
  if [[ -f "${MARZBAN_DIR}/.env" ]]; then
    info "  ✓ Конфигурация Marzban найдена"
  fi

  # Проверяем конфиг sing-box
  if [[ -f "/etc/sing-box/config.json" ]]; then
    info "  ✓ Конфигурация Sing-box найдена"
  fi

  success "Конфигурация проверена"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 8: Запуск сервисов
# ══════════════════════════════════════════════════════════════
step_start_services() {
  step_title "8" "$(get_str "MSG_TITLE_START")" "$(get_str "MSG_TITLE_START")"

  info "Запуск сервисов..."

  # Запускаем в правильном порядке
  systemctl start sing-box 2>/dev/null || true
  info "  ✓ Sing-box запущен"

  systemctl start marzban 2>/dev/null || true
  info "  ✓ Marzban запущен"

  systemctl start cubiveil-bot 2>/dev/null || true
  info "  ✓ Бот запущен"

  # Проверка статуса
  sleep 2
  if systemctl is-active --quiet marzban; then
    success "Marzban работает"
  else
    warning "$(get_str "MSG_WARN_SERVICE_NOT_STARTED")"
  fi

  if systemctl is-active --quiet sing-box; then
    success "Sing-box работает"
  else
    warning "$(get_str "MSG_WARN_SINGBOX_NOT_STARTED")"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 9: Завершение
# ══════════════════════════════════════════════════════════════
step_finish() {
  step_title "9" "$(get_str "MSG_TITLE_ROLLBACK_FINISH")" "$(get_str "MSG_TITLE_ROLLBACK_FINISH")"

  success "$(get_str "MSG_MSG_ROLLBACK_SUCCESS")"
  info "$(get_str "MSG_INFO_ROLLBACK_FROM") ${SELECTED_BACKUP}"

  echo ""
  echo "Проверьте работу сервисов:"
  echo "  systemctl status marzban"
  echo "  systemctl status sing-box"
  echo "  systemctl status cubiveil-bot"
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════
main() {
  select_language

  # Если передан путь к бэкапу как аргумент — используем его
  if [[ -n "${1:-}" ]] && [[ -d "$1" ]]; then
    export SELECTED_BACKUP="$1"
    step_check_environment
    step_validate_backup
    step_confirm_rollback
    step_stop_services
    step_restore_files
    step_restore_config
    step_start_services
    step_finish
  else
    step_check_environment
    step_select_backup
    step_validate_backup
    step_confirm_rollback
    step_stop_services
    step_restore_files
    step_restore_config
    step_start_services
    step_finish
  fi
}

main "$@"
