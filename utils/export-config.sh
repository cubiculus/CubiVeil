#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Export Config Utility                ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                          ║
# ║  Экспорт конфигурации для миграции на другой сервер      ║
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
EXPORT_DIR="/root/cubiveil-export"

# ── Локализация сообщений ─────────────────────────────────────
declare -A MSG=(
  [TITLE_EXPORT]="CubiVeil — Export Config"
  [TITLE_PREPARE]="Подготовка"
  [TITLE_COLLECT]="Сбор конфигурации"
  [TITLE_KEYS]="Ключи и сертификаты"
  [TITLE_ENCRYPT]="Шифрование"
  [TITLE_FINISH]="Экспорт завершён"

  [MSG_EXPORT_DIR]="Директория экспорта"
  [MSG_COLLECTING]="Сбор конфигурации..."
  [MSG_ENCRYPTING]="Шифрование чувствительных данных..."
  [MSG_SUCCESS]="Конфигурация экспортирована"
  [MSG_EXPORT_SIZE]="Размер экспорта"
  [MSG_NEXT_STEP]="Следующий шаг"

  [ERR_NOT_ROOT]="Требуется запуск от root"
  [ERR_MARZBAN_NOT_FOUND]="Marzban не найден в ${MARZBAN_DIR}"
  [ERR_NO_CONFIG]="Конфигурация не найдена"
  [ERR_ENCRYPT_FAILED]="Не удалось зашифровать данные"
  [ERR_AGE_NOT_FOUND]="age не установлен — требуется для шифрования"

  [PROMPT_PASSWORD]="Пароль для шифрования"
  [PROMPT_OUTPUT]="Путь для сохранения"
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
# ШАГ 1: Проверка окружения
# ══════════════════════════════════════════════════════════════
step_check_environment() {
  step_title "1" "Проверка окружения" "Environment check"

  if [[ $EUID -ne 0 ]]; then
    err "${MSG[ERR_NOT_ROOT]}"
  fi

  if ! command -v age &>/dev/null; then
    err "${MSG[ERR_AGE_NOT_FOUND]}"
  fi

  if [[ ! -d "${MARZBAN_DIR}" ]]; then
    err "${MSG[ERR_MARZBAN_NOT_FOUND]}"
  fi

  success "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Подготовка директории экспорта
# ══════════════════════════════════════════════════════════════
step_prepare_export_dir() {
  step_title "2" "${MSG[TITLE_PREPARE]}" "Preparation"

  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local export_path="${EXPORT_DIR}/${timestamp}"

  # Спрашиваем путь если нужно
  if [[ "$LANG_NAME" == "Русский" ]]; then
    read -rp "  ${MSG[PROMPT_OUTPUT]} [${export_path}]: " custom_path
  else
    read -rp "  ${MSG[PROMPT_OUTPUT]} [${export_path}]: " custom_path
  fi

  if [[ -n "${custom_path:-}" ]]; then
    export_path="$custom_path"
  fi

  mkdir -p "${export_path}"

  info "${MSG[MSG_EXPORT_DIR]}: ${export_path}"
  export EXPORT_PATH="$export_path"
  export TIMESTAMP="$timestamp"

  success "Директория создана"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Сбор конфигурации
# ══════════════════════════════════════════════════════════════
step_collect_config() {
  step_title "3" "${MSG[TITLE_COLLECT]}" "Collect config"

  info "${MSG[MSG_COLLECTING]}..."

  # Создаём структуру
  mkdir -p "${EXPORT_PATH}/marzban"
  mkdir -p "${EXPORT_PATH}/sing-box"
  mkdir -p "${EXPORT_PATH}/cubiveil"
  mkdir -p "${EXPORT_PATH}/system"

  # Копируем конфиг Marzban
  if [[ -d "${MARZBAN_DIR}" ]]; then
    info "  Копирование Marzban..."
    cp -rp "${MARZBAN_DIR}/"* "${EXPORT_PATH}/marzban/" 2>/dev/null || true

    # Отдельно копируем .env
    if [[ -f "${MARZBAN_DIR}/.env" ]]; then
      cp "${MARZBAN_DIR}/.env" "${EXPORT_PATH}/marzban/.env"
    fi

    # Копируем базу данных
    if [[ -f "${MARZBAN_DIR}/db.sqlite3" ]]; then
      cp "${MARZBAN_DIR}/db.sqlite3" "${EXPORT_PATH}/marzban/db.sqlite3"
    fi

    success "  ✓ Marzban скопирован"
  fi

  # Копируем конфиг Sing-box
  if [[ -d "${SINGBOX_DIR}" ]]; then
    info "  Копирование Sing-box..."
    cp -rp "${SINGBOX_DIR}/"* "${EXPORT_PATH}/sing-box/" 2>/dev/null || true
    success "  ✓ Sing-box скопирован"
  fi

  # Копируем CubiVeil
  if [[ -d "${CUBIVEIL_DIR}" ]]; then
    info "  Копирование CubiVeil..."
    cp -rp "${CUBIVEIL_DIR}/"* "${EXPORT_PATH}/cubiveil/" 2>/dev/null || true
    success "  ✓ CubiVeil скопирован"
  fi

  # Собираем системную информацию
  info "  Сбор системной информации..."
  {
    echo "# System Information"
    echo "# Generated: $(date -Iseconds)"
    echo ""
    echo "## Hostname"
    hostname
    echo ""
    echo "## Network Interfaces"
    ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "N/A"
    echo ""
    echo "## UFW Status"
    ufw status verbose 2>/dev/null || echo "N/A"
    echo ""
    echo "## Cron Jobs"
    crontab -l 2>/dev/null || echo "N/A"
    echo ""
    echo "## Installed Packages"
    dpkg -l 2>/dev/null | grep -E "(marzban|sing-box|cubiveil)" || echo "N/A"
  } > "${EXPORT_PATH}/system/info.txt"

  success "  ✓ Системная информация собрана"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Ключи и сертификаты
# ══════════════════════════════════════════════════════════════
step_collect_keys() {
  step_title "4" "${MSG[TITLE_KEYS]}" "Keys and certificates"

  mkdir -p "${EXPORT_PATH}/keys"

  info "Сбор ключей и сертификатов..."

  # Ключ age
  if [[ -f "/root/.cubiveil-age-key.txt" ]]; then
    cp "/root/.cubiveil-age-key.txt" "${EXPORT_PATH}/keys/"
    info "  ✓ Ключ age скопирован"
  fi

  # SSL сертификаты Let's Encrypt
  if [[ -d "/etc/letsencrypt/live" ]]; then
    mkdir -p "${EXPORT_PATH}/keys/letsencrypt"
    cp -rp "/etc/letsencrypt/live/"* "${EXPORT_PATH}/keys/letsencrypt/" 2>/dev/null || true
    info "  ✓ SSL сертификаты скопированы"
  fi

  # Ключи Sing-box
  if [[ -d "/etc/sing-box" ]]; then
    for file in /etc/sing-box/*.key /etc/sing-box/*.pem; do
      if [[ -f "$file" ]]; then
        cp "$file" "${EXPORT_PATH}/keys/" 2>/dev/null || true
      fi
    done
    info "  ✓ Ключи Sing-box скопированы"
  fi

  # Ключи из .env (извлекаем имена переменных)
  if [[ -f "${EXPORT_PATH}/marzban/.env" ]]; then
    info "  ✓ Ключи из .env сохранены в конфиге"
  fi

  success "Ключи собраны"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 5: Генерация манифеста
# ══════════════════════════════════════════════════════════════
step_generate_manifest() {
  step_title "5" "Генерация манифеста" "Generate manifest"

  info "Создание манифеста экспорта..."

  local manifest="${EXPORT_PATH}/manifest.json"

  # Считаем размеры
  local total_size
  total_size=$(du -sh "${EXPORT_PATH}" 2>/dev/null | cut -f1)

  # Количество пользователей Marzban
  local user_count=0
  if [[ -f "${EXPORT_PATH}/marzban/db.sqlite3" ]]; then
    user_count=$(sqlite3 "${EXPORT_PATH}/marzban/db.sqlite3" \
      "SELECT COUNT(*) FROM users;" 2>/dev/null || echo "0")
  fi

  # Генерируем JSON манифест
  cat > "${manifest}" << EOF
{
  "version": "1.0",
  "timestamp": "$(date -Iseconds)",
  "hostname": "$(hostname)",
  "export_size": "${total_size}",
  "marzban": {
    "users_count": ${user_count},
    "db_size": "$(du -sh "${EXPORT_PATH}/marzban/db.sqlite3" 2>/dev/null | cut -f1 || echo "0")"
  },
  "components": {
    "marzban": $([[ -d "${EXPORT_PATH}/marzban" ]] && echo "true" || echo "false"),
    "singbox": $([[ -d "${EXPORT_PATH}/sing-box" ]] && echo "true" || echo "false"),
    "cubiveil": $([[ -d "${EXPORT_PATH}/cubiveil" ]] && echo "true" || echo "false"),
    "keys": $([[ -d "${EXPORT_PATH}/keys" ]] && echo "true" || echo "false")
  },
  "encryption": {
    "method": "age",
    "encrypted_files": []
  }
}
EOF

  success "Манифест создан: ${manifest}"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 6: Шифрование чувствительных данных
# ══════════════════════════════════════════════════════════════
step_encrypt_sensitive() {
  step_title "6" "${MSG[TITLE_ENCRYPT]}" "Encrypt sensitive data"

  info "${MSG[MSG_ENCRYPTING]}..."

  # Генерируем пароль если не передан
  local encrypt_password
  if [[ -n "${EXPORT_PASSWORD:-}" ]]; then
    encrypt_password="$EXPORT_PASSWORD"
  else
    if [[ "$LANG_NAME" == "Русский" ]]; then
      read -rsp "  ${MSG[PROMPT_PASSWORD]}: " encrypt_password
      echo ""
    else
      read -rsp "  ${MSG[PROMPT_PASSWORD]}: " encrypt_password
      echo ""
    fi
  fi

  if [[ -z "$encrypt_password" ]]; then
    warning "Пароль не введён — файлы останутся незашифрованными"
    return 0
  fi

  # Создаём passphrase файл для age
  local passphrase_file
  passphrase_file=$(mktemp)
  echo "$encrypt_password" > "$passphrase_file"
  chmod 600 "$passphrase_file"

  # Список файлов для шифрования
  local files_to_encrypt=(
    "marzban/.env"
    "marzban/db.sqlite3"
    "keys/.cubiveil-age-key.txt"
  )

  local encrypted_files=()

  for file in "${files_to_encrypt[@]}"; do
    local full_path="${EXPORT_PATH}/${file}"
    if [[ -f "$full_path" ]]; then
      info "  Шифрование: ${file}"
      if age -p -P "$passphrase_file" -o "${full_path}.age" "$full_path" 2>/dev/null; then
        rm "$full_path"
        encrypted_files+=("${file}.age")
        success "    ✓ Зашифровано"
      else
        warning "    ⚠️  Не удалось зашифровать"
      fi
    fi
  done

  # Обновляем манифест
  if [[ ${#encrypted_files[@]} -gt 0 ]]; then
    # Добавляем информацию о зашифрованных файлах
    local encrypted_json="["
    local first=true
    for f in "${encrypted_files[@]}"; do
      if [[ "$first" == "true" ]]; then
        encrypted_json+="\"$f\""
        first=false
      else
        encrypted_json+=",\"$f\""
      fi
    done
    encrypted_json+="]"

    # Простая замена в JSON
    sed -i "s/\"encrypted_files\": \[\]/\"encrypted_files\": ${encrypted_json}/" \
      "${EXPORT_PATH}/manifest.json" 2>/dev/null || true
  fi

  rm -f "$passphrase_file"
  success "Шифрование завершено"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 7: Создание архива
# ══════════════════════════════════════════════════════════════
step_create_archive() {
  step_title "7" "Создание архива" "Create archive"

  local archive_name="cubiveil-export-${TIMESTAMP}.tar.gz"
  local archive_path="${EXPORT_DIR}/${archive_name}"

  info "Создание архива: ${archive_path}"

  # Создаём tar.gz архив
  tar -czf "${archive_path}" -C "$(dirname "${EXPORT_PATH}")" \
    "$(basename "${EXPORT_PATH}")" 2>/dev/null

  if [[ -f "${archive_path}" ]]; then
    local archive_size
    archive_size=$(du -h "${archive_path}" | cut -f1)
    success "Архив создан: ${archive_path} (${archive_size})"

    # Выводим инструкцию для расшифровки
    echo ""
    if [[ "$LANG_NAME" == "Русский" ]]; then
      echo "══════════════════════════════════════════════════════════"
      echo "  Для импорта на другом сервере:"
      echo "    1. Скопируйте архив на новый сервер"
      echo "    2. Распакуйте: tar -xzf ${archive_name}"
      echo "    3. Расшифруйте: age -d -i ключ.txt файл.age > файл"
      echo "    4. Запустите импорт: bash import-config.sh <распакованная_директория>"
      echo "══════════════════════════════════════════════════════════"
    else
      echo "══════════════════════════════════════════════════════════"
      echo "  To import on another server:"
      echo "    1. Copy archive to new server"
      echo "    2. Extract: tar -xzf ${archive_name}"
      echo "    3. Decrypt: age -d -i key.txt file.age > file"
      echo "    4. Run import: bash import-config.sh <extracted_dir>"
      echo "══════════════════════════════════════════════════════════"
    fi

    export ARCHIVE_PATH="$archive_path"
  else
    err "Не удалось создать архив"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 8: Завершение
# ══════════════════════════════════════════════════════════════
step_finish() {
  step_title "8" "${MSG[TITLE_FINISH]}" "${MSG[TITLE_FINISH]}"

  success "${MSG[MSG_SUCCESS]}"

  local total_size
  total_size=$(du -sh "${EXPORT_PATH}" 2>/dev/null | cut -f1)
  info "${MSG[MSG_EXPORT_SIZE]}: ${total_size}"

  echo ""
  info "Экспорт сохранён: ${EXPORT_PATH}"
  info "Архив: ${ARCHIVE_PATH:-N/A}"

  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "${MSG[MSG_NEXT_STEP]}:"
    echo "  Скопируйте архив на новый сервер и запустите import-config.sh"
  else
    echo "${MSG[MSG_NEXT_STEP]}:"
    echo "  Copy archive to new server and run import-config.sh"
  fi
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════
main() {
  select_language
  step_check_environment
  step_prepare_export_dir
  step_collect_config
  step_collect_keys
  step_generate_manifest
  step_encrypt_sensitive
  step_create_archive
  step_finish
}

main "$@"
