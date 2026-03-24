#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║            CubiVeil — Backup Utility                      ║
# ║         github.com/cubiculus/cubiveil                     ║
# ║                                                           ║
# ║  Полный бэкап установки: конфиги, SSL, ключи, база данных ║
# ║  Автоматические бэкапы по расписанию                      ║
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

# ── Подключение унифицированных функций вывода ───────────────
source "${PROJECT_DIR}/lib/output.sh" || {
  echo "❌ Не удалось загрузить lib/output.sh" >&2
  exit 1
}

# ── Подключение общих утилит ───────────────────────────────────
source "${PROJECT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}

# ── Константы ─────────────────────────────────────────────────
MARZBAN_DIR="/opt/marzban"
SINGBOX_DIR="/etc/sing-box"
CUBIVEIL_DIR="/opt/cubiveil"
BACKUP_DIR="/root/cubiveil-backups"
BACKUP_RETENTION_DAYS=30
CRON_SCHEDULE="0 3 * * *"  # Ежедневно в 03:00

# ── Локализация сообщений ─────────────────────────────────────
declare -A MSG=(
  [TITLE_BACKUP]="CubiVeil — Backup Utility"
  [TITLE_CHECK]="Проверка окружения"
  [TITLE_STOP]="Остановка сервисов"
  [TITLE_MARZBAN]="Бэкап Marzban"
  [TITLE_SINGBOX]="Бэкап Sing-box"
  [TITLE_SSL]="Бэкап SSL сертификатов"
  [TITLE_KEYS]="Бэкап ключей"
  [TITLE_ARCHIVE]="Создание архива"
  [TITLE_START]="Запуск сервисов"
  [TITLE_CLEANUP]="Очистка старых бэкапов"
  [TITLE_CRON]="Настройка автобэкапа"
  [TITLE_FINISH]="Бэкап завершён"

  [MSG_BACKUP_DIR]="Директория бэкапа"
  [MSG_BACKUP_SIZE]="Размер бэкапа"
  [MSG_BACKUP_NAME]="Имя бэкапа"
  [MSG_CREATING]="Создание бэкапа..."
  [MSG_STOPPING]="Остановка сервисов..."
  [MSG_STARTING]="Запуск сервисов..."
  [MSG_SUCCESS]="Бэкап успешно создан"
  [MSG_RETENTION]="Хранение бэкапов: ${BACKUP_RETENTION_DAYS} дней"
  [MSG_CRON_ENABLED]="Автобэкап включён"
  [MSG_CRON_DISABLED]="Автобэкап отключён"

  [ERR_NOT_ROOT]="Требуется запуск от root"
  [ERR_BACKUP_FAILED]="Не удалось создать бэкап"
  [ERR_RESTORE_FAILED]="Не удалось восстановить бэкап"
  [ERR_NO_BACKUP]="Бэкап не найден"
  [ERR_AGE_NOT_FOUND]="age не установлен"

  [PROMPT_ENCRYPT]="Зашифровать бэкап"
  [PROMPT_PASSWORD]="Пароль для шифрования"
  [PROMPT_RESTORE]="Восстановить из бэкапа"
  [PROMPT_SCHEDULE]="Включить автобэкап"
  [PROMPT_STOP_SERVICES]="Останавливать сервисы"

  [CMD_CREATE]="create"
  [CMD_LIST]="list"
  [CMD_RESTORE]="restore"
  [CMD_SCHEDULE]="schedule"
  [CMD_CLEANUP]="cleanup"
  [CMD_HELP]="help"
)

msg() {
  local key="$1"
  local default="${2:-}"
  echo "${MSG[$key]:-$default}"
}

step_title() {
  local step="$1"
  local ru="$2"
  local en="$3"
  echo ""
  echo "══════════════════════════════════════════════════════════"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "  ${step}. ${ru}"
  else
    echo "  ${step}. ${en}"
  fi
  echo "══════════════════════════════════════════════════════════"
}

# ══════════════════════════════════════════════════════════════
# Глобальные переменные
# ══════════════════════════════════════════════════════════════

BACKUP_TIMESTAMP=""
BACKUP_PATH=""
ENCRYPT_BACKUP=false
BACKUP_PASSWORD=""
STOP_SERVICES=true

# ══════════════════════════════════════════════════════════════
# ШАГ 1: Проверка окружения
# ══════════════════════════════════════════════════════════════

step_check_environment() {
  step_title "1" "${MSG[TITLE_CHECK]}" "${MSG[TITLE_CHECK]}"

  if [[ $EUID -ne 0 ]]; then
    err "${MSG[ERR_NOT_ROOT]}"
  fi

  # Проверка age для шифрования
  if ! command -v age &>/dev/null; then
    warning "${MSG[ERR_AGE_NOT_FOUND]} — шифрование будет недоступно"
  fi

  # Создаём директорию бэкапов
  mkdir -p "${BACKUP_DIR}"

  success "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Остановка сервисов (опционально)
# ══════════════════════════════════════════════════════════════

step_stop_services() {
  if [[ "$STOP_SERVICES" != "true" ]]; then
    info "Пропуск остановки сервисов"
    return 0
  fi

  step_title "2" "${MSG[TITLE_STOP]}" "Stop services"

  info "${MSG[MSG_STOPPING]}..."

  local services_to_stop=()

  # Проверяем какие сервисы активны
  for service in cubiveil-bot marzban sing-box; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
      services_to_stop+=("$service")
    fi
  done

  if [[ ${#services_to_stop[@]} -eq 0 ]]; then
    info "  Нет активных сервисов для остановки"
    return 0
  fi

  # Останавливаем в обратном порядке
  for ((i=${#services_to_stop[@]}-1; i>=0; i--)); do
    local service="${services_to_stop[$i]}"
    info "  Остановка ${service}..."
    systemctl stop "$service" 2>/dev/null || warning "  Не удалось остановить ${service}"
  done

  # Ждём освобождения файлов
  sleep 2

  success "Сервисы остановлены"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Бэкап Marzban
# ══════════════════════════════════════════════════════════════

step_backup_marzban() {
  step_title "3" "${MSG[TITLE_MARZBAN]}" "Marzban backup"

  local marzban_backup="${BACKUP_PATH}/marzban"
  mkdir -p "$marzban_backup"

  info "Бэкап Marzban..."

  # Копируем директорию
  if [[ -d "${MARZBAN_DIR}" ]]; then
    cp -rp "${MARZBAN_DIR}/"* "$marzban_backup/" 2>/dev/null || true
    success "  ✓ Файлы Marzban скопированы"
  fi

  # Копируем базу данных отдельно (для консистентности)
  if [[ -f "${MARZBAN_DIR}/db.sqlite3" ]]; then
    cp "${MARZBAN_DIR}/db.sqlite3" "$marzban_backup/" 2>/dev/null || true
    success "  ✓ База данных скопирована"
  fi

  # Копируем .env
  if [[ -f "${MARZBAN_DIR}/.env" ]]; then
    cp "${MARZBAN_DIR}/.env" "$marzban_backup/" 2>/dev/null || true
    success "  ✓ Конфигурация скопирована"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Бэкап Sing-box
# ══════════════════════════════════════════════════════════════

step_backup_singbox() {
  step_title "4" "${MSG[TITLE_SINGBOX]}" "Sing-box backup"

  local singbox_backup="${BACKUP_PATH}/sing-box"
  mkdir -p "$singbox_backup"

  info "Бэкап Sing-box..."

  if [[ -d "${SINGBOX_DIR}" ]]; then
    cp -rp "${SINGBOX_DIR}/"* "$singbox_backup/" 2>/dev/null || true
    success "  ✓ Файлы Sing-box скопированы"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 5: Бэкап SSL сертификатов
# ══════════════════════════════════════════════════════════════

step_backup_ssl() {
  step_title "5" "${MSG[TITLE_SSL]}" "SSL certificates backup"

  local ssl_backup="${BACKUP_PATH}/ssl"
  mkdir -p "$ssl_backup"

  info "Бэкап SSL сертификатов..."

  # Let's Encrypt
  if [[ -d "/etc/letsencrypt" ]]; then
    cp -rp "/etc/letsencrypt" "$ssl_backup/" 2>/dev/null || true
    success "  ✓ Let's Encrypt скопирован"
  fi

  # Другие сертификаты
  for cert_dir in "/etc/ssl/cubiveil" "${MARZBAN_DIR}/certs" "${SINGBOX_DIR}/certs"; do
    if [[ -d "$cert_dir" ]]; then
      cp -rp "$cert_dir" "$ssl_backup/" 2>/dev/null || true
      success "  ✓ ${cert_dir} скопирован"
    fi
  done
}

# ══════════════════════════════════════════════════════════════
# ШАГ 6: Бэкап ключей
# ══════════════════════════════════════════════════════════════

step_backup_keys() {
  step_title "6" "${MSG[TITLE_KEYS]}" "Keys backup"

  local keys_backup="${BACKUP_PATH}/keys"
  mkdir -p "$keys_backup"

  info "Бэкап ключей..."

  # Ключ age
  if [[ -f "/root/.cubiveil-age-key.txt" ]]; then
    cp "/root/.cubiveil-age-key.txt" "$keys_backup/" 2>/dev/null || true
    success "  ✓ Ключ age скопирован"
  fi

  # Ключи SSH (опционально, с предупреждением)
  if [[ -d "/root/.ssh" ]]; then
    # Копируем только authorized_keys и config
    for file in authorized_keys config; do
      if [[ -f "/root/.ssh/${file}" ]]; then
        cp "/root/.ssh/${file}" "$keys_backup/ssh_${file}" 2>/dev/null || true
      fi
    done
    success "  ✓ SSH ключи скопированы"
  fi

  # Ключи из конфигов
  if [[ -d "${CUBIVEIL_DIR}" ]]; then
    cp -rp "${CUBIVEIL_DIR}/"* "$keys_backup/cubiveil/" 2>/dev/null || true
    success "  ✓ Ключи CubiVeil скопированы"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 7: Создание системной информации
# ══════════════════════════════════════════════════════════════

step_backup_system_info() {
  local info_backup="${BACKUP_PATH}/system"
  mkdir -p "$info_backup"

  info "Сбор системной информации..."

  {
    echo "# System Information"
    echo "# Generated: $(date -Iseconds)"
    echo ""
    echo "## Hostname"
    hostname
    echo ""
    echo "## Network"
    ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "N/A"
    echo ""
    echo "## UFW Status"
    ufw status verbose 2>/dev/null || echo "N/A"
    echo ""
    echo "## Cron Jobs"
    crontab -l 2>/dev/null || echo "N/A"
    echo ""
    echo "## Installed Packages"
    dpkg -l 2>/dev/null | grep -E "(marzban|sing-box|cubiveil|ufw|fail2ban)" || echo "N/A"
    echo ""
    echo "## Disk Usage"
    df -h 2>/dev/null
    echo ""
    echo "## Memory"
    free -h 2>/dev/null
  } > "${info_backup}/system-info.txt"

  success "  ✓ Системная информация сохранена"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 8: Создание архива
# ══════════════════════════════════════════════════════════════

step_create_archive() {
  step_title "8" "${MSG[TITLE_ARCHIVE]}" "Create archive"

  local archive_name="cubiveil-backup-${BACKUP_TIMESTAMP}.tar.gz"
  local archive_path="${BACKUP_DIR}/${archive_name}"

  info "Создание архива: ${archive_path}"

  # Создаём tar.gz
  tar -czf "${archive_path}" -C "$(dirname "${BACKUP_PATH}")" \
    "$(basename "${BACKUP_PATH}")" 2>/dev/null

  if [[ -f "${archive_path}" ]]; then
    local archive_size
    archive_size=$(du -h "${archive_path}" | cut -f1)
    success "Архив создан: ${archive_path} (${archive_size})"

    # Шифрование если запрошено
    if [[ "$ENCRYPT_BACKUP" == "true" ]] && command -v age &>/dev/null; then
      info "Шифрование бэкапа..."

      if [[ -z "$BACKUP_PASSWORD" ]]; then
        if [[ "$LANG_NAME" == "Русский" ]]; then
          read -rsp "  ${MSG[PROMPT_PASSWORD]}: " BACKUP_PASSWORD
          echo ""
        else
          read -rsp "  ${MSG[PROMPT_PASSWORD]}: " BACKUP_PASSWORD
          echo ""
        fi
      fi

      if [[ -n "$BACKUP_PASSWORD" ]]; then
        local passphrase_file
        passphrase_file=$(mktemp)
        echo "$BACKUP_PASSWORD" > "$passphrase_file"
        chmod 600 "$passphrase_file"

        if age -p -P "$passphrase_file" -o "${archive_path}.age" "${archive_path}" 2>/dev/null; then
          rm "${archive_path}"
          archive_path="${archive_path}.age"
          success "Бэкап зашифрован"
        else
          warning "Не удалось зашифровать бэкап"
        fi

        rm -f "$passphrase_file"
      fi
    fi

    export ARCHIVE_PATH="$archive_path"
  else
    err "${MSG[ERR_BACKUP_FAILED]}"
  fi

  # Сохраняем метаданные
  local manifest="${BACKUP_DIR}/.backup-${BACKUP_TIMESTAMP}.json"
  cat > "$manifest" << EOF
{
  "timestamp": "${BACKUP_TIMESTAMP}",
  "archive": "$(basename "${ARCHIVE_PATH}")",
  "encrypted": ${ENCRYPT_BACKUP},
  "size": "$(du -h "${ARCHIVE_PATH}" | cut -f1)",
  "components": {
    "marzban": $([[ -d "${BACKUP_PATH}/marzban" ]] && echo "true" || echo "false"),
    "singbox": $([[ -d "${BACKUP_PATH}/sing-box" ]] && echo "true" || echo "false"),
    "ssl": $([[ -d "${BACKUP_PATH}/ssl" ]] && echo "true" || echo "false"),
    "keys": $([[ -d "${BACKUP_PATH}/keys" ]] && echo "true" || echo "false")
  }
}
EOF
}

# ══════════════════════════════════════════════════════════════
# ШАГ 9: Запуск сервисов
# ══════════════════════════════════════════════════════════════

step_start_services() {
  if [[ "$STOP_SERVICES" != "true" ]]; then
    return 0
  fi

  step_title "9" "${MSG[TITLE_START]}" "Start services"

  info "${MSG[MSG_STARTING]}..."

  # Запускаем в правильном порядке
  for service in sing-box marzban cubiveil-bot; do
    if systemctl list-unit-files "$service" &>/dev/null; then
      info "  Запуск ${service}..."
      systemctl start "$service" 2>/dev/null || warning "  Не удалось запустить ${service}"
    fi
  done

  # Проверка статуса
  sleep 3
  for service in marzban sing-box; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
      success "  ✓ ${service} работает"
    else
      warning "  ⚠️  ${service} не запустился"
    fi
  done
}

# ══════════════════════════════════════════════════════════════
# ШАГ 10: Очистка старых бэкапов
# ══════════════════════════════════════════════════════════════

step_cleanup_old_backups() {
  step_title "10" "${MSG[TITLE_CLEANUP]}" "Cleanup old backups"

  info "${MSG[MSG_RETENTION]}"

  local deleted_count=0

  # Находим и удаляем старые бэкапы
  while IFS= read -r -d '' file; do
    local file_date
    file_date=$(stat -c %Y "$file" 2>/dev/null || echo "0")
    local current_date
    current_date=$(date +%s)
    local age_days=$(( (current_date - file_date) / 86400 ))

    if [[ $age_days -gt $BACKUP_RETENTION_DAYS ]]; then
      info "  Удаление старого бэкапа: $(basename "$file") (${age_days} дней)"
      rm -f "$file"
      ((deleted_count++))
    fi
  done < <(find "${BACKUP_DIR}" -name "cubiveil-backup-*.tar.gz*" -print0 2>/dev/null)

  # Удаляем старые манифесты
  while IFS= read -r -d '' file; do
    local file_date
    file_date=$(stat -c %Y "$file" 2>/dev/null || echo "0")
    local current_date
    current_date=$(date +%s)
    local age_days=$(( (current_date - file_date) / 86400 ))

    if [[ $age_days -gt $BACKUP_RETENTION_DAYS ]]; then
      rm -f "$file"
      ((deleted_count++))
    fi
  done < <(find "${BACKUP_DIR}" -name ".backup-*.json" -print0 2>/dev/null)

  if [[ $deleted_count -gt 0 ]]; then
    success "Удалено старых бэкапов: ${deleted_count}"
  else
    info "Старых бэкапов не найдено"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 11: Настройка автобэкапа
# ══════════════════════════════════════════════════════════════

step_setup_cron() {
  step_title "11" "${MSG[TITLE_CRON]}" "Setup auto-backup"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_SCHEDULE]}? [y/N]: " setup_cron
  else
    read -rp "  ${MSG[PROMPT_SCHEDULE]}? [y/N]: " setup_cron
  fi

  if [[ "${setup_cron,,}" != "y" ]]; then
    info "Пропуск настройки автобэкапа"
    return 0
  fi

  local cron_job="${CRON_SCHEDULE} ${SCRIPT_DIR}/backup.sh create --no-interact >> /var/log/cubiveil-backup.log 2>&1"

  # Проверяем существующие cron jobs
  local existing_cron
  existing_cron=$(crontab -l 2>/dev/null | grep -v "^#" | grep "backup.sh" || echo "")

  if [[ -n "$existing_cron" ]]; then
    info "Автобэкап уже настроен"
    success "${MSG[MSG_CRON_ENABLED]}"
    return 0
  fi

  # Добавляем cron job
  local current_crontab
  current_crontab=$(crontab -l 2>/dev/null || echo "")

  {
    echo "$current_crontab"
    echo "# CubiVeil Auto-Backup"
    echo "$cron_job"
  } | crontab -

  success "${MSG[MSG_CRON_ENABLED]}"
  info "Расписание: ${CRON_SCHEDULE}"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 12: Завершение
# ══════════════════════════════════════════════════════════════

step_finish() {
  step_title "12" "${MSG[TITLE_FINISH]}" "${MSG[TITLE_FINISH]}"

  success "${MSG[MSG_SUCCESS]}"

  local archive_size
  archive_size=$(du -h "${ARCHIVE_PATH}" 2>/dev/null | cut -f1 || echo "N/A")

  echo ""
  info "${MSG[MSG_BACKUP_NAME]}: $(basename "${ARCHIVE_PATH}")"
  info "${MSG[MSG_BACKUP_SIZE]}: ${archive_size}"
  info "${MSG[MSG_BACKUP_DIR]}: $(dirname "${ARCHIVE_PATH}")"

  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "Для восстановления выполните:"
    echo "  bash ${SCRIPT_DIR}/backup.sh restore ${ARCHIVE_PATH}"
  else
    echo "To restore run:"
    echo "  bash ${SCRIPT_DIR}/backup.sh restore ${ARCHIVE_PATH}"
  fi
}

# ══════════════════════════════════════════════════════════════
# Создание бэкапа (основная функция)
# ══════════════════════════════════════════════════════════════

create_backup() {
  BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  BACKUP_PATH="${BACKUP_DIR}/temp-${BACKUP_TIMESTAMP}"

  mkdir -p "${BACKUP_PATH}"

  step_check_environment
  step_stop_services
  step_backup_marzban
  step_backup_singbox
  step_backup_ssl
  step_backup_keys
  step_backup_system_info
  step_create_archive
  step_start_services
  step_cleanup_old_backups
  step_finish

  # Очистка временной директории
  rm -rf "${BACKUP_PATH}"
}

# ══════════════════════════════════════════════════════════════
# Список бэкапов
# ══════════════════════════════════════════════════════════════

list_backups() {
  step_title "" "Список бэкапов" "Backup list"

  if [[ ! -d "${BACKUP_DIR}" ]]; then
    info "Бэкапы не найдены"
    return 0
  fi

  local backups=()
  while IFS= read -r -d '' file; do
    backups+=("$file")
  done < <(find "${BACKUP_DIR}" -name "cubiveil-backup-*.tar.gz*" -print0 2>/dev/null | sort -z -r)

  if [[ ${#backups[@]} -eq 0 ]]; then
    info "Бэкапы не найдены"
    return 0
  fi

  printf "  %-40s %-10s %-15s\n" "Имя" "Размер" "Дата"
  echo "  ────────────────────────────────────────────────────────────────"

  for backup in "${backups[@]}"; do
    local name size date
    name=$(basename "$backup")
    size=$(du -h "$backup" | cut -f1)
    date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1)

    # Обрезаем имя если длинное
    if [[ ${#name} -gt 38 ]]; then
      name="${name:0:35}..."
    fi

    printf "  %-40s %-10s %-15s\n" "$name" "$size" "$date"
  done

  echo ""
  info "Всего бэкапов: ${#backups[@]}"
}

# ══════════════════════════════════════════════════════════════
# Восстановление из бэкапа
# ══════════════════════════════════════════════════════════════

restore_backup() {
  local archive_path="$1"

  step_title "" "Восстановление из бэкапа" "Restore from backup"

  if [[ ! -f "$archive_path" ]]; then
    err "${MSG[ERR_NO_BACKUP]}"
  fi

  info "Бэкап: ${archive_path}"

  # Расшифровка если зашифрован
  local extract_path
  extract_path=$(mktemp -d)

  if [[ "$archive_path" == *.age ]]; then
    if ! command -v age &>/dev/null; then
      err "${MSG[ERR_AGE_NOT_FOUND]}"
    fi

    if [[ "$LANG_NAME" == "Русский" ]]; then
      read -rsp "  Введите пароль для расшифровки: " BACKUP_PASSWORD
      echo ""
    else
      read -rsp "  Enter password for decryption: " BACKUP_PASSWORD
      echo ""
    fi

    local passphrase_file
    passphrase_file=$(mktemp)
    echo "$BACKUP_PASSWORD" > "$passphrase_file"
    chmod 600 "$passphrase_file"

    info "Расшифровка..."
    if ! age -d -P "$passphrase_file" -o "${extract_path}/backup.tar.gz" "$archive_path" 2>/dev/null; then
      err "Неверный пароль или повреждённый файл"
    fi
    rm -f "$passphrase_file"

    archive_path="${extract_path}/backup.tar.gz"
  fi

  # Остановка сервисов
  info "Остановка сервисов..."
  for service in cubiveil-bot marzban sing-box; do
    systemctl stop "$service" 2>/dev/null || true
  done
  sleep 2

  # Распаковка
  info "Распаковка..."
  tar -xzf "$archive_path" -C "${extract_path}" 2>/dev/null

  # Восстановление файлов
  local backup_content
  backup_content=$(find "${extract_path}" -maxdepth 1 -type d -name "temp-*" | head -1)

  if [[ -z "$backup_content" ]]; then
    backup_content=$(find "${extract_path}" -maxdepth 1 -type d | tail -1)
  fi

  info "Восстановление файлов..."

  if [[ -d "${backup_content}/marzban" ]]; then
    info "  Восстановление Marzban..."
    cp -rp "${backup_content}/marzban/"* "${MARZBAN_DIR}/" 2>/dev/null || true
    success "  ✓ Marzban восстановлен"
  fi

  if [[ -d "${backup_content}/sing-box" ]]; then
    info "  Восстановление Sing-box..."
    cp -rp "${backup_content}/sing-box/"* "${SINGBOX_DIR}/" 2>/dev/null || true
    success "  ✓ Sing-box восстановлен"
  fi

  if [[ -d "${backup_content}/ssl/letsencrypt" ]]; then
    info "  Восстановление SSL..."
    cp -rp "${backup_content}/ssl/letsencrypt/"* "/etc/letsencrypt/" 2>/dev/null || true
    success "  ✓ SSL восстановлен"
  fi

  if [[ -d "${backup_content}/keys" ]]; then
    info "  Восстановление ключей..."
    if [[ -f "${backup_content}/keys/.cubiveil-age-key.txt" ]]; then
      cp "${backup_content}/keys/.cubiveil-age-key.txt" "/root/.cubiveil-age-key.txt"
      chmod 600 "/root/.cubiveil-age-key.txt"
    fi
    success "  ✓ Ключи восстановлены"
  fi

  # Запуск сервисов
  info "Запуск сервисов..."
  for service in sing-box marzban cubiveil-bot; do
    systemctl start "$service" 2>/dev/null || true
  done
  sleep 3

  # Проверка
  if systemctl is-active --quiet marzban 2>/dev/null; then
    success "Marzban работает"
  else
    warning "Marzban не запустился"
  fi

  # Очистка
  rm -rf "$extract_path"

  success "Восстановление завершено"
}

# ══════════════════════════════════════════════════════════════
# Справка
# ══════════════════════════════════════════════════════════════

show_help() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  CubiVeil — Backup Utility"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo "  Использование: $0 <команда> [опции]"
  echo ""
  echo "  Команды:"
  echo "    create            Создать бэкап"
  echo "    list              Список бэкапов"
  echo "    restore <файл>    Восстановить из бэкапа"
  echo "    cleanup           Очистить старые бэкапы"
  echo "    help              Эта справка"
  echo ""
  echo "  Опции:"
  echo "    --no-encrypt      Не шифровать бэкап"
  echo "    --no-stop         Не останавливать сервисы"
  echo "    --no-interact     Неинтерактивный режим (для cron)"
  echo ""
  echo "  Примеры:"
  echo "    $0 create"
  echo "    $0 list"
  echo "    $0 restore /root/cubiveil-backups/cubiveil-backup-20260324_030000.tar.gz"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════

main() {
  select_language

  local command="${1:-help}"
  shift || true

  # Парсинг опций
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-encrypt)
        ENCRYPT_BACKUP=false
        shift
        ;;
      --no-stop)
        STOP_SERVICES=false
        shift
        ;;
      --no-interact)
        ENCRYPT_BACKUP=false
        STOP_SERVICES=false
        shift
        ;;
      *)
        if [[ "$command" == "restore" ]]; then
          restore_backup "$1"
          exit $?
        fi
        shift
        ;;
    esac
  done

  case "$command" in
    create)
      create_backup
      ;;
    list)
      list_backups
      ;;
    restore)
      if [[ -n "${1:-}" ]]; then
        restore_backup "$1"
      else
        err "Укажите путь к бэкапу"
      fi
      ;;
    cleanup)
      step_check_environment
      step_cleanup_old_backups
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      err "Неизвестная команда: ${command}. Используйте '$0 help'"
      ;;
  esac
}

main "$@"
