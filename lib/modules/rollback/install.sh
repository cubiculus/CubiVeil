#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Rollback Module                      ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Модуль отката (restore)                                  ║
# ║  - Восстановление из бэкапов                             ║
# ║  - Откат конфигураций                                    ║
# ║  - Управление точками восстановления                       ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# Подключаем utils
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# ── Конфигурация / Configuration ────────────────────────────

BACKUP_DIR="/var/backups/cubiveil"
BACKUP_ARCHIVE_DIR="${BACKUP_DIR}/archives"
ROLLBACK_TEMP_DIR="${BACKUP_DIR}/temp"

# Пути для восстановления
MARZBAN_DIR="/var/lib/marzban"
MARZBAN_ENV="/opt/marzban/.env"
MARZBAN_TEMPLATE="/var/lib/marzban/sing-box-template.json"
SSL_CERT_DIR="/var/lib/marzban/certs"
CREDENTIALS_FILE="/var/lib/marzban/credentials.age"
CREDENTIALS_KEY="/var/lib/marzban/credentials.key"

# ── Инициализация / Initialization ─────────────────────────────

# Создание временной директории
rollback_init() {
  log_step "rollback_init" "Initializing rollback module"

  dir_ensure "$ROLLBACK_TEMP_DIR"

  log_debug "Rollback temp directory created"
}

# ── Список доступных бэкапов / List Backups ───────────

# Получение списка бэкапов
rollback_list_backups() {
  log_step "rollback_list_backups" "Listing available backups"

  echo ""
  echo "Available restore points:"
  echo "─────────────────────────────"

  local i=1
  declare -A BACKUP_MAP

  for archive in "${BACKUP_ARCHIVE_DIR}"/*.tar.gz; do
    if [[ -f "$archive" ]]; then
      local name
      local size
      local date

      name=$(basename "$archive")
      size=$(du -h "$archive" | cut -f1)
      date=$(stat -c %y "$archive" | cut -d' ' -f1)

      BACKUP_MAP[$i]="$archive"
      echo ""
      echo "  [$i] $name"
      echo "      Size: $size"
      echo "      Date: $date"

      ((i++))
    fi
  done

  echo ""
  echo "─────────────────────────────"

  # Если нет бэкапов
  if [[ $i -eq 1 ]]; then
    log_warn "No backups found"
    return 1
  fi
}

# ── Выбор бэкапа / Select Backup ─────────────────────────

# Интерактивный выбор бэкапа
rollback_select_backup() {
  log_step "rollback_select_backup" "Selecting backup for restore"

  rollback_list_backups

  while true; do
    read -rp "  Select backup number (or 'q' to cancel): " selection

    if [[ "$selection" == "q" ]]; then
      log_info "Rollback cancelled"
      exit 0
    fi

    if [[ -n "$BACKUP_MAP[$selection]" ]]; then
      echo "${BACKUP_MAP[$selection]}"
      return 0
    fi

    log_warn "Invalid selection"
  done
}

# ── Подготовка бэкапа / Prepare Backup ───────────────────

# Распаковка бэкапа
rollback_extract_backup() {
  local archive="$1"

  log_step "rollback_extract_backup" "Extracting backup archive"

  # Очищаем временную директорию
  rm -rf "${ROLLBACK_TEMP_DIR:?}"/*
  mkdir -p "$ROLLBACK_TEMP_DIR"

  # Распаковываем архив
  if ! tar -xzf "$archive" -C "$ROLLBACK_TEMP_DIR"; then
    log_error "Failed to extract backup archive"
    return 1
  fi

  log_success "Backup extracted"
}

# ── Остановка сервисов / Stop Services ──────────────────────

# Остановка сервисов перед откатом
rollback_stop_services() {
  log_step "rollback_stop_services" "Stopping services for rollback"

  # Останавливаем Marzban
  if svc_active "marzban"; then
    svc_stop "marzban"
    log_info "Marzban stopped"
  fi

  # Останавливаем Sing-box
  if svc_active "sing-box"; then
    svc_stop "sing-box"
    log_info "Sing-box stopped"
  fi

  # Ждём завершения
  sleep 2
}

# ── Восстановление Marzban / Restore Marzban ───────────────

# Восстановление базы данных Marzban
rollback_marzban_db() {
  log_step "rollback_marzban_db" "Restoring Marzban database"

  local backup_db="${ROLLBACK_TEMP_DIR}/marzban-db.sqlite3"

  if [[ ! -f "$backup_db" ]]; then
    log_warn "Marzban database backup not found"
    return 1
  fi

  # Останавливаем Marzban если активен
  if svc_active "marzban"; then
    svc_stop "marzban"
  fi

  # Копируем базу данных
  cp "$backup_db" "${MARZBAN_DIR}/db.sqlite3"

  # Устанавливаем права
  chmod 640 "${MARZBAN_DIR}/db.sqlite3"
  chown root:root "${MARZBAN_DIR}/db.sqlite3"

  log_success "Marzban database restored"
}

# Восстановление конфигурации Marzban
rollback_marzban_config() {
  log_step "rollback_marzban_config" "Restoring Marzban configuration"

  # Восстанавливаем .env
  if [[ -f "${ROLLBACK_TEMP_DIR}/marzban.env" ]]; then
    cp "${ROLLBACK_TEMP_DIR}/marzban.env" "$MARZBAN_ENV"
    chmod 640 "$MARZBAN_ENV"
    log_success "Marzban .env restored"
  else
    log_warn "Marzban .env backup not found"
  fi

  # Восстанавливаем шаблон Sing-box
  if [[ -f "${ROLLBACK_TEMP_DIR}/sing-box-template.json" ]]; then
    cp "${ROLLBACK_TEMP_DIR}/sing-box-template.json" "$MARZBAN_TEMPLATE"
    chmod 640 "$MARZBAN_TEMPLATE"
    log_success "Sing-box template restored"
  else
    log_warn "Sing-box template backup not found"
  fi
}

# ── Восстановление Sing-box / Restore Sing-box ───────────────

# Восстановление конфигурации Sing-box
rollback_singbox_config() {
  log_step "rollback_singbox_config" "Restoring Sing-box configuration"

  local backup_conf="${ROLLBACK_TEMP_DIR}/singbox-config.json"

  if [[ ! -f "$backup_conf" ]]; then
    log_warn "Sing-box configuration backup not found"
    return 1
  fi

  local SINGBOX_CONF="/etc/sing-box/config.json"

  # Создаём директорию если нужно
  dir_ensure "$(dirname "$SINGBOX_CONF")"

  # Копируем конфигурацию
  cp "$backup_conf" "$SINGBOX_CONF"
  chmod 640 "$SINGBOX_CONF"

  log_success "Sing-box configuration restored"
}

# ── Восстановление SSL сертификатов / Restore SSL ───────────

# Восстановление SSL сертификатов
rollback_ssl_certs() {
  log_step "rollback_ssl_certs" "Restoring SSL certificates"

  local backup_certs="${ROLLBACK_TEMP_DIR}/ssl-certs"

  if [[ ! -d "$backup_certs" ]]; then
    log_warn "SSL certificates backup not found"
    return 1
  fi

  # Копируем сертификаты
  cp -r "$backup_certs"/* "$SSL_CERT_DIR/"

  # Устанавливаем права
  chmod 640 "${SSL_CERT_DIR}"/*.pem
  chown root:root "${SSL_CERT_DIR}"/*.pem

  log_success "SSL certificates restored"
}

# ── Восстановление ключей / Restore Keys ───────────────────

# Восстановление ключей и credentials
rollback_keys() {
  log_step "rollback_keys" "Restoring keys and credentials"

  # Восстанавливаем credentials.age
  if [[ -f "${ROLLBACK_TEMP_DIR}/credentials.age" ]]; then
    cp "${ROLLBACK_TEMP_DIR}/credentials.age" "$CREDENTIALS_FILE"
    chmod 600 "$CREDENTIALS_FILE"
    log_success "Credentials restored"
  else
    log_warn "Credentials backup not found"
  fi

  # Восстанавливаем age key
  if [[ -f "${ROLLBACK_TEMP_DIR}/credentials.key" ]]; then
    cp "${ROLLBACK_TEMP_DIR}/credentials.key" "$CREDENTIALS_KEY"
    chmod 600 "$CREDENTIALS_KEY"
    log_success "Age key restored"
  else
    log_warn "Age key backup not found"
  fi
}

# ── Запуск сервисов / Start Services ───────────────────────

# Запуск сервисов после отката
rollback_start_services() {
  log_step "rollback_start_services" "Starting services after rollback"

  # Запускаем Sing-box
  if [[ -x "/usr/local/bin/sing-box" ]] && [[ -f "/etc/sing-box/config.json" ]]; then
    svc_start "sing-box"
    log_info "Sing-box started"
  fi

  # Запускаем Marzban
  if [[ -d "$MARZBAN_DIR" ]]; then
    svc_start "marzban"
    log_info "Marzban started"
  fi

  # Ждём запуска
  sleep 3
}

# ── Полный откат / Full Rollback ────────────────────────────

# Выполнение полного отката
rollback_full() {
  log_step "rollback_full" "Performing full rollback"

  rollback_init

  # Выбор бэкапа
  local archive
  archive=$(rollback_select_backup)

  # Распаковка
  rollback_extract_backup "$archive"

  # Останавливаем сервисы
  rollback_stop_services

  # Восстанавливаем данные
  rollback_marzban_db
  rollback_marzban_config
  rollback_singbox_config
  rollback_ssl_certs
  rollback_keys

  # Запускаем сервисы
  rollback_start_services

  # Очищаем временную директорию
  rm -rf "${ROLLBACK_TEMP_DIR:?}"/*

  log_success "Full rollback completed"
}

# ── Быстрый откат (без выбора) / Quick Rollback ─────────

# Откат из последнего бэкапа
rollback_latest() {
  log_step "rollback_latest" "Performing rollback from latest backup"

  rollback_init

  # Находим последний бэкап
  local latest_backup
  latest_backup=$(ls -t "${BACKUP_ARCHIVE_DIR}"/*.tar.gz 2>/dev/null | head -1)

  if [[ -z "$latest_backup" ]]; then
    log_error "No backups found"
    return 1
  fi

  log_info "Using latest backup: $(basename "$latest_backup")"

  # Распаковка
  rollback_extract_backup "$latest_backup"

  # Останавливаем сервисы
  rollback_stop_services

  # Восстанавливаем данные
  rollback_marzban_db
  rollback_marzban_config
  rollback_ssl_certs

  # Запускаем сервисы
  rollback_start_services

  # Очищаем временную директорию
  rm -rf "${ROLLBACK_TEMP_DIR:?}"/*

  log_success "Rollback from latest backup completed"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { rollback_init; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }

# Полный откат с интерактивным выбором
module_rollback() { rollback_full; }

# Быстрый откат из последнего бэкапа
module_rollback_latest() { rollback_latest; }

# Список доступных бэкапов
module_list() { rollback_list_backups; }
