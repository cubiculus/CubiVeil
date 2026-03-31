#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Rollback Module (Enhanced)            ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль отката с проверкой целостности                    ║
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

# Подключаем security (ENHANCED - использование verify_sha256)
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
  source "${SCRIPT_DIR}/lib/security.sh"
fi

# ── Конфигурация / Configuration ────────────────────────────

BACKUP_DIR="/var/backups/cubiveil"
BACKUP_ARCHIVE_DIR="${BACKUP_DIR}/archives"
ROLLBACK_TEMP_DIR="${BACKUP_DIR}/temp"

# Пути для восстановления
SSL_CERT_DIR="/etc/ssl/certs"
CREDENTIALS_FILE="/etc/cubiveil/credentials.age"
CREDENTIALS_KEY="/etc/cubiveil/credentials.key"

# ── Инициализация / Initialization ─────────────────────────────

# Создание временной директории
rollback_init() {
  log_step "rollback_init" "Initializing rollback module"

  dir_ensure "$ROLLBACK_TEMP_DIR"

  log_debug "Rollback temp directory created"
}

# ── Список доступных бэкапов / List Backups ───────────

# Получение списка бэкапов с информацией о шифровании
rollback_list_backups() {
  log_step "rollback_list_backups" "Listing available backups"

  echo ""
  echo "Available restore points:"
  echo "─────────────────────────────"

  local i=1
  declare -A BACKUP_MAP

  for archive in "${BACKUP_ARCHIVE_DIR}"/*.tar.gz*; do
    if [[ -f "$archive" ]]; then
      local name
      local size
      local date
      local encrypted

      name=$(basename "$archive")
      size=$(du -h "$archive" | cut -f1)
      date=$(stat -c %y "$archive" | cut -d' ' -f1)

      # Проверяем, зашифрован ли архив
      if [[ "$name" == *.age ]]; then
        encrypted=" [ENCRYPTED]"
      else
        encrypted=""
      fi

      BACKUP_MAP[$i]="$archive"
      echo ""
      echo "  [$i] $name$encrypted"
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
      return 1
    fi

    if [[ -n "${BACKUP_MAP[$selection]}" ]]; then
      echo "${BACKUP_MAP[$selection]}"
      return 0
    fi

    log_warn "Invalid selection"
  done
}

# ── Подготовка бэкапа / Prepare Backup ───────────────────

# Распаковка архива
rollback_extract_backup() {
  local archive="$1"

  log_step "rollback_extract_backup" "Extracting backup archive"

  # Очищаем временную директорию
  rm -rf "${ROLLBACK_TEMP_DIR:?}"/*
  mkdir -p "$ROLLBACK_TEMP_DIR"

  # Проверяем, зашифрован ли архив
  if [[ "$archive" == *.age ]]; then
    log_info "Encrypted archive detected, decrypting..."

    # Получаем ключ шифрования
    local key_file="${BACKUP_DIR}/backup-key.txt"
    if [[ ! -f "$key_file" ]]; then
      log_error "Encryption key not found: $key_file"
      return 1
    fi

    local key
    key=$(cat "$key_file")

    # Расшифровываем архив
    local decrypted_file="${archive%.age}"
    if ! age --decrypt -i "$key_file" -o "$decrypted_file" "$archive" 2>/dev/null; then
      log_error "Failed to decrypt archive"
      return 1
    fi

    archive="$decrypted_file"
    log_info "Archive decrypted successfully"
  fi

  # Распаковываем архив
  if ! tar -xzf "$archive" -C "$ROLLBACK_TEMP_DIR"; then
    log_error "Failed to extract backup archive"
    return 1
  fi

  log_success "Backup extracted"
}

# ── Проверка целостности / Integrity Check ───────────────

# Проверка целостности восстановленных файлов
rollback_verify_integrity() {
  log_step "rollback_verify_integrity" "Verifying backup integrity"

  local issues=0

  # Проверяем SHA256 конфигурации Sing-box
  if [[ -f "${ROLLBACK_TEMP_DIR}/singbox-config.json" ]] &&
    [[ -f "${ROLLBACK_TEMP_DIR}/singbox-config.json.sha256" ]]; then
    local expected_hash
    expected_hash=$(cat "${ROLLBACK_TEMP_DIR}/singbox-config.json.sha256")

    if ! verify_sha256 "${ROLLBACK_TEMP_DIR}/singbox-config.json" "$expected_hash"; then
      log_warn "Sing-box configuration integrity check FAILED"
      ((issues++))
    else
      log_success "Sing-box configuration integrity verified"
    fi
  fi

  if [[ $issues -gt 0 ]]; then
    log_error "Integrity checks failed: $issues files corrupted"
    return 1
  fi

  log_success "All integrity checks passed"
}

# ── Остановка сервисов / Stop Services ──────────────────────

# Остановка сервисов перед откатом
rollback_stop_services() {
  log_step "rollback_stop_services" "Stopping services for rollback"

  # Останавливаем Sing-box
  if svc_active "sing-box"; then
    svc_stop "sing-box"
    log_info "Sing-box stopped"
  fi

  # Ждём завершения
  sleep 2
}

# ── Восстановление Sing-box / Restore Sing-box ───────────────

# Восстановление конфигурации Sing-box с проверкой целостности
rollback_singbox_config() {
  log_step "rollback_singbox_config" "Restoring Sing-box configuration"

  # Проверяем целостность конфигурации
  if [[ -f "${ROLLBACK_TEMP_DIR}/singbox-config.json.sha256" ]]; then
    local expected_hash
    expected_hash=$(cat "${ROLLBACK_TEMP_DIR}/singbox-config.json.sha256")

    if ! verify_sha256 "${ROLLBACK_TEMP_DIR}/singbox-config.json" "$expected_hash"; then
      log_error "Sing-box configuration integrity check failed, skipping restore"
      return 1
    fi
  fi

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

# Восстановление SSL сертификатов с проверкой валидности
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

  # Проверяем валидность сертификатов используя verify_ssl_cert из security.sh
  local cert_file="${SSL_CERT_DIR}/fullchain.pem"
  if [[ -f "$cert_file" ]]; then
    # Извлекаем домен из сертификата
    local domain
    domain=$(openssl x509 -in "$cert_file" -noout -subject 2>/dev/null | grep -oP '(?<=CN=)[^,]+' || echo "unknown")

    if [[ "$domain" != "unknown" ]]; then
      log_info "Checking SSL certificate for: $domain"
      if verify_ssl_cert "$domain" 443 5 2>/dev/null; then
        log_success "SSL certificate is valid: $domain"
      else
        log_warn "SSL certificate validation failed: $domain"
      fi
    fi
  fi

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

  # Ждём запуска
  sleep 3
}

# ── Полный откат / Full Rollback ────────────────────────────

# Выполнение полного отката с проверкой целостности
rollback_full() {
  log_step "rollback_full" "Performing full rollback with integrity checks"

  rollback_init

  # Выбор бэкапа
  local archive
  archive=$(rollback_select_backup)

  # Распаковка
  rollback_extract_backup "$archive"

  # Проверка целостности
  if ! rollback_verify_integrity; then
    log_error "Integrity checks failed, aborting rollback"
    return 1
  fi

  # Останавливаем сервисы
  rollback_stop_services

  # Восстанавливаем данные
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

# Откат из последнего бэкапа с проверкой целостности
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

  # Проверка целостности
  if ! rollback_verify_integrity; then
    log_error "Integrity checks failed, aborting rollback"
    return 1
  fi

  # Останавливаем сервисы
  rollback_stop_services

  # Восстанавливаем данные
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

# Настройка модуля: проверка целостности бэкапов
module_configure() {
  log_step "module_configure" "Configuring rollback module"

  # Инициализируем модуль
  rollback_init

  # Проверяем наличие бэкапов
  if [[ ! -d "$BACKUP_ARCHIVE_DIR" ]] || [[ -z "$(ls -A "$BACKUP_ARCHIVE_DIR" 2>/dev/null)" ]]; then
    log_warn "No backups found in ${BACKUP_ARCHIVE_DIR}"
    log_info "Run backup module first to create backups"
    return 1
  fi

  # Проверяем целостность последнего бэкапа
  local latest_backup
  latest_backup=$(ls -t "${BACKUP_ARCHIVE_DIR}"/*.tar.gz* 2>/dev/null | head -1)

  if [[ -n "$latest_backup" ]]; then
    log_info "Latest backup: $(basename "$latest_backup")"

    # Проверяем SHA256 если есть файл проверки
    local sha_file="${latest_backup}.sha256"
    if [[ -f "$sha_file" ]]; then
      local expected_hash
      expected_hash=$(cat "$sha_file")
      if verify_sha256 "$latest_backup" "$expected_hash"; then
        log_success "Backup integrity verified"
      else
        log_error "Backup integrity check failed"
        return 1
      fi
    fi
  fi

  log_success "Rollback module configured"
}

# Включение модуля: не требуется (утилитный модуль)
module_enable() {
  log_step "module_enable" "Enabling rollback module"

  log_info "Rollback module is a utility module"
  log_info "No services to enable"
  log_info "Use 'module_rollback' to perform rollback"

  log_success "Rollback module ready"
}

# Выключение модуля: не требуется (утилитный модуль)
module_disable() {
  log_step "module_disable" "Disabling rollback module"

  log_info "Rollback module is a utility module"
  log_info "No services to disable"

  log_success "Rollback module disabled"
}

# Полный откат с интерактивным выбором бэкапа
module_rollback() { rollback_full; }

# Быстрый откат из последнего бэкапа
module_rollback_latest() { rollback_latest; }

# Список доступных бэкапов
module_list() { rollback_list_backups; }
