#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Backup Module                        ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Модуль резервного копирования                            ║
# ║  - Резервное копирование Marzban                           ║
# ║  - Резервное копирование Sing-box                          ║
# ║  - Резервное копирование SSL сертификатов                   ║
# ║  - Создание архивов                                       ║
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

# Подключаем security
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

  if [[ $issues -gt 0 ]]; then
    log_warn "Found $issues environment issues, backup may be incomplete"
  else
    log_success "Environment check passed"
  fi

  return $([[ $issues -eq 0 ]] && echo 0 || echo 1)
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

# Бэкап базы данных Marzban
backup_marzban_db() {
  log_step "backup_marzban_db" "Backing up Marzban database"

  if [[ ! -f "${MARZBAN_DIR}/db.sqlite3" ]]; then
    log_warn "Marzban database not found"
    return 1
  fi

  cp "${MARZBAN_DIR}/db.sqlite3" "${BACKUP_DIR}/marzban-db.sqlite3"

  log_success "Marzban database backed up"
}

# Бэкап конфигурации Marzban
backup_marzban_config() {
  log_step "backup_marzban_config" "Backing up Marzban configuration"

  local backed_up=false

  # Бэкап .env
  if [[ -f "$MARZBAN_ENV" ]]; then
    cp "$MARZBAN_ENV" "${BACKUP_DIR}/marzban.env"
    backed_up=true
  fi

  # Бэкап шаблона Sing-box
  if [[ -f "$MARZBAN_TEMPLATE" ]]; then
    cp "$MARZBAN_TEMPLATE" "${BACKUP_DIR}/sing-box-template.json"
    backed_up=true
  fi

  if [[ "$backed_up" == "true" ]]; then
    log_success "Marzban configuration backed up"
  fi
}

# ── Бэкап Sing-box / Backup Sing-box ───────────────────────

# Бэкап конфигурации Sing-box
backup_singbox_config() {
  log_step "backup_singbox_config" "Backing up Sing-box configuration"

  local SINGBOX_CONF="/etc/sing-box/config.json"

  if [[ -f "$SINGBOX_CONF" ]]; then
    cp "$SINGBOX_CONF" "${BACKUP_DIR}/singbox-config.json"
    log_success "Sing-box configuration backed up"
  else
    log_warn "Sing-box configuration not found"
  fi
}

# ── Бэкап SSL сертификатов / Backup SSL ────────────────────

# Бэкап SSL сертификатов
backup_ssl_certs() {
  log_step "backup_ssl_certs" "Backing up SSL certificates"

  if [[ ! -d "$SSL_CERT_DIR" ]]; then
    log_warn "SSL certificates directory not found"
    return 1
  fi

  # Копируем все сертификаты
  cp -r "$SSL_CERT_DIR" "${BACKUP_DIR}/ssl-certs/"

  log_success "SSL certificates backed up"
}

# ── Бэкап ключей / Backup Keys ───────────────────────────

# Бэкап ключей и credentials
backup_keys() {
  log_step "backup_keys" "Backing up keys and credentials"

  local backed_up=false

  # Бэкап credentials.age
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

# ── Бэкап системной информации / Backup System Info ───────

# Сбор системной информации
backup_system_info() {
  log_step "backup_system_info" "Backing up system information"

  # Создаём файл с информацией о системе
  cat >"${BACKUP_DIR}/system-info.txt" <<EOF
CubiVeil Backup Information
Generated: $(date '+%Y-%m-%d %H:%M:%S')
Hostname: $(hostname)
IP Address: $(get_server_ip 2>/dev/null || echo "unknown")
Ubuntu Version: $(grep 'VERSION=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
Kernel: $(uname -r)

Installed Packages:
$(dpkg -l 2>/dev/null | grep -E "(marzban|sing-box|cubiveil|ufw|fail2ban)" || echo "N/A")

Services Status:
Marzban: $(svc_active "marzban" && echo "active" || echo "inactive")
Sing-box: $(svc_active "sing-box" && echo "active" || echo "inactive")
UFW: $(svc_active "ufw" && echo "active" || echo "inactive")
Fail2ban: $(svc_active "fail2ban" && echo "active" || echo "inactive")
EOF

  log_success "System information backed up"
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
    marzban.env \
    sing-box-template.json \
    singbox-config.json \
    ssl-certs/ \
    credentials.age \
    credentials.key \
    system-info.txt 2>/dev/null || true

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

# Выполнение полного бэкапа
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
  backup_create_archive "cubiveil-full"

  # Запускаем сервисы
  backup_start_services

  # Очищаем старые бэкапы
  backup_cleanup_old

  log_success "Full backup completed"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { backup_init; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }

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

  for archive in "${BACKUP_ARCHIVE_DIR}"/*.tar.gz; do
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
