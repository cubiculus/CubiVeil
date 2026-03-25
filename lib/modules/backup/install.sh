#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Backup Module (Enhanced)              ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль резервного копирования с шифрованием              ║
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

# Подключаем security (ENHANCED - использование функций)
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
  source "${SCRIPT_DIR}/lib/security.sh"
fi

# ── Конфигурация / Configuration ────────────────────────────

BACKUP_DIR="/var/backups/cubiveil"
BACKUP_RETENTION_DAYS=30
BACKUP_ARCHIVE_DIR="${BACKUP_DIR}/archives"

# Пути к данным для бэкапа
MARZBAN_DIR="/var/lib/marzban"
MARZBAN_ENV="/opt/marzban/.env"
MARZBAN_TEMPLATE="/var/lib/marzban/sing-box-template.json"
SSL_CERT_DIR="/var/lib/marzban/certs"
CREDENTIALS_FILE="/var/lib/marzban/credentials.age"
CREDENTIALS_KEY="/var/lib/marzban/credentials.key"

# ── Инициализация / Initialization ─────────────────────────────

# Создание директории для бэкапов
backup_init() {
  log_step "backup_init" "Initializing backup module"

  dir_ensure "$BACKUP_DIR"
  dir_ensure "$BACKUP_ARCHIVE_DIR"

  log_debug "Backup directories created"
}

# ── Генерация ключей шифрования / Encryption Keys ─────────

# Генерация ключа для шифрования бэкапов
backup_generate_encryption_key() {
  log_step "backup_generate_encryption_key" "Generating encryption key"

  local key_file="${BACKUP_DIR}/backup-key.txt"

  # Генерируем безопасный ключ используя generate_secure_key из security.sh
  local key
  key=$(generate_secure_key 32)

  # Сохраняем ключ
  echo "$key" > "$key_file"
  chmod 600 "$key_file"

  log_debug "Encryption key generated"
  echo "$key"
}

# Получение ключа шифрования
backup_get_encryption_key() {
  local key_file="${BACKUP_DIR}/backup-key.txt"

  if [[ -f "$key_file" ]]; then
    cat "$key_file"
    return 0
  else
    log_warn "Encryption key not found, generating new key..."
    backup_generate_encryption_key
    return 1
  fi
}

# ── Проверка окружения / Environment Check ────────────────

# Проверка окружения перед бэкапом
backup_check_environment() {
  log_step "backup_check_environment" "Checking backup environment"

  local issues=0

  # Проверяем наличие Marzban
  if [[ ! -d "$MARZBAN_DIR" ]]; then
    log_warn "Marzban directory not found: $MARZBAN_DIR"
    ((issues++))
  fi

  # Проверяем наличие Sing-box
  if [[ ! -x "/usr/local/bin/sing-box" ]]; then
    log_warn "Sing-box binary not found"
    ((issues++))
  fi

  # Проверяем наличие SSL сертификатов
  if [[ ! -d "$SSL_CERT_DIR" ]]; then
    log_warn "SSL certificates directory not found: $SSL_CERT_DIR"
    ((issues++))
  fi

  # Проверяем наличие age для шифрования
  if ! command -v age &>/dev/null; then
    log_warn "age encryption tool not found, backups will not be encrypted"
    ((issues++))
  fi

  if [[ $issues -gt 0 ]]; then
    log_warn "Found $issues environment issues, backup may be incomplete"
  else
    log_success "Environment check passed"
  fi

  if [[ $issues -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

# ── Остановка сервисов / Stop Services ──────────────────────

# Остановка сервисов перед бэкапом
backup_stop_services() {
  log_step "backup_stop_services" "Stopping services for backup"

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

# ── Бэкап Marzban / Backup Marzban ────────────────────────

# Бэкап базы данных Marzban с проверкой целостности
backup_marzban_db() {
  log_step "backup_marzban_db" "Backing up Marzban database"

  if [[ ! -f "${MARZBAN_DIR}/db.sqlite3" ]]; then
    log_warn "Marzban database not found"
    return 1
  fi

  local backup_db="${BACKUP_DIR}/marzban-db.sqlite3"

  # Копируем базу данных
  cp "${MARZBAN_DIR}/db.sqlite3" "$backup_db"

  # Генерируем SHA256 для проверки целостности
  local hash
  hash=$(sha256sum "$backup_db" 2>/dev/null | awk '{print $1}')
  echo "$hash" > "${backup_db}.sha256"

  log_success "Marzban database backed up (SHA256: ${hash:0:8}...)"
}

# Бэкап конфигурации Marzban
backup_marzban_config() {
  log_step "backup_marzban_config" "Backing up Marzban configuration"

  local backed_up=false

  # Бэкап .env
  if [[ -f "$MARZBAN_ENV" ]]; then
    cp "$MARZBAN_ENV" "${BACKUP_DIR}/marzban.env"

    # Генерируем SHA256
    local hash
    hash=$(sha256sum "${BACKUP_DIR}/marzban.env" 2>/dev/null | awk '{print $1}')
    echo "$hash" > "${BACKUP_DIR}/marzban.env.sha256"

    backed_up=true
  fi

  # Бэкап шаблона Sing-box
  if [[ -f "$MARZBAN_TEMPLATE" ]]; then
    cp "$MARZBAN_TEMPLATE" "${BACKUP_DIR}/sing-box-template.json"

    # Генерируем SHA256
    local hash
    hash=$(sha256sum "${BACKUP_DIR}/sing-box-template.json" 2>/dev/null | awk '{print $1}')
    echo "$hash" > "${BACKUP_DIR}/sing-box-template.json.sha256"

    backed_up=true
  fi

  if [[ "$backed_up" == "true" ]]; then
    log_success "Marzban configuration backed up with integrity hashes"
  fi
}

# ── Бэкап Sing-box / Backup Sing-box ───────────────────────

# Бэкап конфигурации Sing-box
backup_singbox_config() {
  log_step "backup_singbox_config" "Backing up Sing-box configuration"

  local SINGBOX_CONF="/etc/sing-box/config.json"

  if [[ -f "$SINGBOX_CONF" ]]; then
    cp "$SINGBOX_CONF" "${BACKUP_DIR}/singbox-config.json"

    # Генерируем SHA256
    local hash
    hash=$(sha256sum "${BACKUP_DIR}/singbox-config.json" 2>/dev/null | awk '{print $1}')
    echo "$hash" > "${BACKUP_DIR}/singbox-config.json.sha256"

    log_success "Sing-box configuration backed up (SHA256: ${hash:0:8}...)"
  else
    log_warn "Sing-box configuration not found"
  fi
}

# ── Бэкап SSL сертификатов / Backup SSL ────────────────────

# Бэкап SSL сертификатов с проверкой валидности
backup_ssl_certs() {
  log_step "backup_ssl_certs" "Backing up SSL certificates"

  if [[ ! -d "$SSL_CERT_DIR" ]]; then
    log_warn "SSL certificates directory not found"
    return 1
  fi

  # Копируем все сертификаты
  cp -r "$SSL_CERT_DIR" "${BACKUP_DIR}/ssl-certs/"

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

  log_success "SSL certificates backed up"
}

# ── Бэкап ключей / Backup Keys ───────────────────────────

# Бэкап ключей и credentials с шифрованием
backup_keys() {
  log_step "backup_keys" "Backing up keys and credentials"

  local backed_up=false

  # Проверяем наличие age
  if ! command -v age &>/dev/null; then
    log_warn "age not available, credentials will not be encrypted"
  fi

  # Бэкап credentials.age если есть
  if [[ -f "$CREDENTIALS_FILE" ]]; then
    cp "$CREDENTIALS_FILE" "${BACKUP_DIR}/credentials.age"
    backed_up=true
  fi

  # Бэкап age key
  if [[ -f "$CREDENTIALS_KEY" ]]; then
    cp "$CREDENTIALS_KEY" "${BACKUP_DIR}/credentials.key"
    backed_up=true
  fi

  if [[ "$backed_up" == "true" ]]; then
    log_success "Keys and credentials backed up"
  fi
}

# ── Шифрование архива / Encrypt Archive ───────────────────

# Шифрование архива бэкапа
backup_encrypt_archive() {
  local archive="$1"

  log_step "backup_encrypt_archive" "Encrypting backup archive"

  # Проверяем наличие age
  if ! command -v age &>/dev/null; then
    log_warn "age not available, skipping encryption"
    return 1
  fi

  # Получаем или генерируем ключ шифрования
  local encryption_key
  encryption_key=$(backup_get_encryption_key)

  # Шифруем архив используя encrypt_to_file из security.sh
  local encrypted_file="${archive}.age"
  
  # Читаем содержимое архива и шифруем
  if encrypt_to_file "$(cat "$archive")" "$encryption_key" "$encrypted_file"; then
    # Удаляем оригинальный архив
    rm -f "$archive"

    # Сохраняем ключ в архив
    cp "${BACKUP_DIR}/backup-key.txt" "${encrypted_file}.key"

    log_success "Backup encrypted: $encrypted_file"
    log_info "Encryption key: ${encrypted_file}.key"
  else
    log_warn "Failed to encrypt backup archive"
    return 1
  fi
}

# ── Бэкап системной информации / Backup System Info ───────

# Сбор системной информации
backup_system_info() {
  log_step "backup_system_info" "Backing up system information"

  {
    echo "CubiVeil Backup Information"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "IP Address: $(get_server_ip 2>/dev/null || echo "unknown")"
    echo "Ubuntu Version: $(grep 'VERSION=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
    echo "Kernel: $(uname -r)"
    echo ""
    echo "Installed Packages:"
    dpkg -l 2>/dev/null | grep -E "(marzban|sing-box|cubiveil|ufw|fail2ban)" || echo "N/A"
    echo ""
    echo "Services Status:"
    echo "Marzban: $(svc_active "marzban" && echo "active" || echo "inactive")"
    echo "Sing-box: $(svc_active "sing-box" && echo "active" || echo "inactive")"
    echo "UFW: $(svc_active "ufw" && echo "active" || echo "inactive")"
    echo "Fail2ban: $(svc_active "fail2ban" && echo "active" || echo "inactive")"
  } > "${BACKUP_DIR}/system-info.txt"

  # Генерируем SHA256
  local hash
  hash=$(sha256sum "${BACKUP_DIR}/system-info.txt" 2>/dev/null | awk '{print $1}')
  echo "$hash" > "${BACKUP_DIR}/system-info.txt.sha256"

  log_success "System information backed up (SHA256: ${hash:0:8}...)"
}

# ── Создание архива / Create Archive ───────────────────────

# Создание архива бэкапа
backup_create_archive() {
  local backup_name="${1:-cubiveil-backup}"
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)

  log_step "backup_create_archive" "Creating backup archive"

  local archive_file="${BACKUP_ARCHIVE_DIR}/${backup_name}-${timestamp}.tar.gz"

  # Создаём архив
  tar -czf "$archive_file" -C "$BACKUP_DIR" \
    marzban-db.sqlite3 \
    marzban-db.sqlite3.sha256 \
    marzban.env \
    marzban.env.sha256 \
    sing-box-template.json \
    sing-box-template.json.sha256 \
    singbox-config.json \
    singbox-config.json.sha256 \
    ssl-certs/ \
    credentials.age \
    credentials.key \
    system-info.txt \
    system-info.txt.sha256 2>/dev/null || true

  # Проверяем размер архива
  if [[ -f "$archive_file" ]]; then
    local size
    size=$(du -h "$archive_file" | cut -f1)
    log_success "Backup archive created: $archive_file ($size)"
  else
    log_error "Failed to create backup archive"
    return 1
  fi
}

# ── Запуск сервисов / Start Services ───────────────────────

# Запуск сервисов после бэкапа
backup_start_services() {
  log_step "backup_start_services" "Starting services after backup"

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
  sleep 2
}

# ── Очистка старых бэкапов / Cleanup Old Backups ───────

# Удаление старых бэкапов
backup_cleanup_old() {
  log_step "backup_cleanup_old" "Cleaning up old backups"

  # Удаляем бэкапы старше retention дней
  find "$BACKUP_ARCHIVE_DIR" -name "*.tar.gz" -mtime +$BACKUP_RETENTION_DAYS -delete

  local count
  count=$(find "$BACKUP_ARCHIVE_DIR" -name "*.tar.gz" | wc -l)

  log_info "Kept $count backups (retention: ${BACKUP_RETENTION_DAYS} days)"
}

# ── Полный бэкап / Full Backup ─────────────────────────────

# Выполнение полного бэкапа с шифрованием
backup_full() {
  log_step "backup_full" "Performing full backup"

  backup_init
  backup_check_environment

  # Останавливаем сервисы
  backup_stop_services

  # Выполняем бэкапы
  backup_marzban_db
  backup_marzban_config
  backup_singbox_config
  backup_ssl_certs
  backup_keys
  backup_system_info

  # Создаём архив
  local archive_file
  archive_file=$(backup_create_archive "cubiveil-full")

  # Шифруем архив если доступен age
  if command -v age &>/dev/null; then
    backup_encrypt_archive "$archive_file"
  fi

  # Запускаем сервисы
  backup_start_services

  # Очищаем старые бэкапы
  backup_cleanup_old

  log_success "Full backup completed"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { backup_init; }

# Настройка модуля: проверка окружения и генерация ключей
module_configure() {
  log_step "module_configure" "Configuring backup module"

  # Инициализируем модуль
  backup_init

  # Проверяем окружение
  if ! backup_check_environment; then
    log_warn "Backup environment check failed"
  fi

  # Генерируем ключ шифрования если его нет
  local key_file="${BACKUP_DIR}/backup-key.txt"
  if [[ ! -f "$key_file" ]]; then
    log_info "Generating encryption key..."
    backup_generate_encryption_key
    log_success "Encryption key generated: ${key_file}"
  else
    log_info "Encryption key already exists"
  fi

  log_success "Backup module configured"
}

# Включение модуля: настройка cron для автоматических бэкапов
module_enable() {
  log_step "module_enable" "Enabling backup module"

  # Проверяем наличие cron
  if ! pkg_check "cron"; then
    log_warn "Cron not installed, installing..."
    pkg_install_packages "cron"
  fi

  # Создаём cron job для ежедневного бэкапа
  local cron_job="0 2 * * * /bin/bash -c 'cd ${SCRIPT_DIR} && source lib/modules/backup/install.sh && backup_full >> /var/log/cubiveil/backup-cron.log 2>&1'"
  
  if ! crontab -l 2>/dev/null | grep -q "backup_full"; then
    (crontab -l 2>/dev/null | grep -v "backup_full"; echo "$cron_job") | crontab -
    log_success "Daily backup cron job added"
  else
    log_info "Backup cron job already exists"
  fi

  log_success "Backup module enabled"
}

# Выключение модуля: удаление cron job
module_disable() {
  log_step "module_disable" "Disabling backup module"

  # Удаляем cron job
  if crontab -l 2>/dev/null | grep -q "backup_full"; then
    crontab -l 2>/dev/null | grep -v "backup_full" | crontab -
    log_success "Backup cron job removed"
  else
    log_info "Backup cron job not found"
  fi

  log_success "Backup module disabled"
}

# Создание бэкапа
module_backup() { backup_full; }

# Создание быстрого бэкапа (без остановки сервисов)
module_quick_backup() {
  log_step "module_quick_backup" "Performing quick backup"

  backup_init

  backup_marzban_db
  backup_marzban_config
  backup_ssl_certs

  backup_create_archive "cubiveil-quick"

  log_success "Quick backup completed"
}

# Список бэкапов
module_list() {
  log_step "module_list" "Listing available backups"

  echo ""
  echo "Available backups:"
  echo "────────────────"

  for archive in "${BACKUP_ARCHIVE_DIR}"/*.tar.gz*; do
    if [[ -f "$archive" ]]; then
      local name
      local size
      local date

      name=$(basename "$archive")
      size=$(du -h "$archive" | cut -f1)
      date=$(stat -c %y "$archive" | cut -d' ' -f1)

      echo ""
      echo "  File: $name"
      echo "  Size: $size"
      echo "  Date: $date"
    fi
  done

  echo ""
  echo "────────────────"
}

# Удаление старых бэкапов
module_cleanup() { backup_cleanup_old; }
