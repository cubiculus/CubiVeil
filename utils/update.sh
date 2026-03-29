#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Update Utility                        ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Обновление CubiVeil до последней версии                  ║
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
# shellcheck disable=SC2034
REPO_URL="https://github.com/cubiculus/cubiveil"
RAW_URL="https://raw.githubusercontent.com/cubiculus/cubiveil/main"
CUBIVEIL_DIR="/opt/cubiveil"
BACKUP_DIR="/root/cubiveil-backup"
VERSION_FILE="${CUBIVEIL_DIR}/.version"

# ── Списки файлов для обновления ──────────────────────────────
# Основные файлы в корне проекта
ROOT_FILES=(
  "install.sh"
  "setup-telegram.sh"
  "run-tests.sh"
  "pyproject.toml"
  ".version"
  ".pre-commit-config.yaml"
)

# Файлы локализации
LANG_FILES=(
  "lang/main.sh"
  "lang/telegram.sh"
)

# Файлы библиотеки
LIB_FILES=(
  "utils.sh"
  "common.sh"
  "validation.sh"
  "security.sh"
  "output.sh"
  "fallback.sh"
  "i18n.sh"
  "manifest.sh"
  "test-utils.sh"
)

# Тестовые файлы
TEST_FILES=(
  "integration-test.sh"
  "modular-structure.sh"
  "unit-utils.sh"
  "unit-telegram.sh"
  "unit-install.sh"
  "unit-lang.sh"
  "unit-utilities.sh"
)

# Утилиты
UTIL_FILES=(
  "monitor.sh"
  "backup.sh"
  "update.sh"
  "rollback.sh"
  "export-config.sh"
  "import-config.sh"
  "install-aliases.sh"
  "diagnose.sh"
)

# Core модули
CORE_FILES=(
  "system.sh"
  "log.sh"
)

# ══════════════════════════════════════════════════════════════
# ШАГ 1: Проверка окружения
# ══════════════════════════════════════════════════════════════
step_check_environment() {
  step_title "1" "Проверка окружения" "Environment check"

  if [[ $EUID -ne 0 ]]; then
    err "$(get_str "MSG_ERR_ROOT_REQUIRED")"
  fi

  if [[ ! -d "${CUBIVEIL_DIR}" ]]; then
    err "$(get_str "MSG_ERR_NOT_INSTALLED")"
  fi

  # Проверка зависимостей
  for cmd in curl git age; do
    if ! command -v "$cmd" &>/dev/null; then
      err "$(get_str "MSG_ERR_COMMAND_REQUIRED")"
    fi
  done

  success "$(get_str "MSG_INFO_ENV_CHECKED")"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Проверка версий
# ══════════════════════════════════════════════════════════════
step_check_versions() {
  step_title "2" "$(get_str "MSG_TITLE_CHECK")" "$(get_str "MSG_TITLE_CHECK")"

  # Получаем текущую версию
  local current_version="unknown"
  if [[ -f "${VERSION_FILE}" ]]; then
    current_version=$(cat "${VERSION_FILE}" | head -1)
  else
    # Пытаемся получить из git если есть
    if [[ -d "${CUBIVEIL_DIR}/.git" ]]; then
      current_version=$(git -C "${CUBIVEIL_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown")
    fi
  fi

  # Получаем последнюю версию из GitHub
  local latest_version
  latest_version=$(curl -sf --max-time 10 "${RAW_URL}/.version" 2>/dev/null | head -1 || echo "unknown")

  if [[ "$current_version" == "unknown" ]]; then
    warning "$(get_str "MSG_ERR_GIT_FAILED")"
    current_version="local"
  fi

  info "$(get_str "MSG_MSG_CURRENT_VERSION"): ${current_version}"
  info "$(get_str "MSG_MSG_LATEST_VERSION"): ${latest_version}"

  if [[ "$current_version" == "$latest_version" ]] && [[ "$latest_version" != "unknown" ]]; then
    success "$(get_str "MSG_MSG_UP_TO_DATE")"
    if [[ "$current_version" != "unknown" ]]; then
      exit 0
    fi
  else
    success "$(get_str "MSG_MSG_NEW_VERSION_AVAILABLE")"
  fi

  export CURRENT_VERSION="$current_version"
  export LATEST_VERSION="$latest_version"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Подтверждение обновления
# ══════════════════════════════════════════════════════════════
step_confirm_update() {
  step_title "3" "$(get_str "MSG_TITLE_UPDATE")" "$(get_str "MSG_TITLE_UPDATE")"

  read -rp "  $(get_str "MSG_PROMPT_UPDATE") [y/N]: " confirm

  if [[ "${confirm,,}" != "y" ]]; then
    info "$(get_str "MSG_INFO_UPDATE_CANCELLED")"
    exit 0
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Создание бэкапа
# ══════════════════════════════════════════════════════════════
step_create_backup() {
  step_title "4" "$(get_str "MSG_TITLE_BACKUP")" "$(get_str "MSG_TITLE_BACKUP")"

  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local backup_path="${BACKUP_DIR}/${timestamp}"

  info "$(get_str "MSG_MSG_BACKING_UP") → ${backup_path}"

  mkdir -p "${backup_path}"

  # Бэкап текущей установки
  if [[ -d "${CUBIVEIL_DIR}" ]]; then
    cp -rp "${CUBIVEIL_DIR}" "${backup_path}/cubiveil" 2>/dev/null || true
  fi

  # Бэкап конфигов S-UI
  if [[ -d "/usr/local/s-ui" ]]; then
    cp -rp "/usr/local/s-ui" "${backup_path}/s-ui" 2>/dev/null || true
  fi

  # Бэкап ключей и сертификатов
  for dir in "/root/.cubiveil-age-key.txt" "/etc/cubiveil" "/etc/letsencrypt"; do
    if [[ -e "$dir" ]]; then
      cp -rp "$dir" "${backup_path}/$(basename "$dir")" 2>/dev/null || true
    fi
  done

  # Сохраняем информацию о бэкапе
  echo "${timestamp}" >"${backup_path}/.timestamp"
  echo "${CURRENT_VERSION}" >"${backup_path}/.version"

  success "$(get_str "MSG_INFO_BACKUP_CREATED") ${backup_path}"
  export BACKUP_PATH="$backup_path"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 5: Загрузка новой версии
# ══════════════════════════════════════════════════════════════
step_download_update() {
  step_title "5" "$(get_str "MSG_TITLE_DOWNLOAD")" "$(get_str "MSG_TITLE_DOWNLOAD")"

  local temp_dir
  temp_dir=$(mktemp -d)
  info "$(get_str "MSG_MSG_DOWNLOADING") → ${temp_dir}"

  local download_failed=0

  # Загружаем основные файлы
  for file in "${ROOT_FILES[@]}"; do
    if ! curl -sf --max-time 30 "${RAW_URL}/${file}" -o "${temp_dir}/${file}" 2>/dev/null; then
      warning "Не удалось загрузить ${file}"
      download_failed=1
    fi
  done

  # Загружаем lang/*.sh
  mkdir -p "${temp_dir}/lang"
  for file in "${LANG_FILES[@]}"; do
    if ! curl -sf --max-time 30 "${RAW_URL}/${file}" -o "${temp_dir}/${file}" 2>/dev/null; then
      warning "Не удалось загрузить ${file}"
      download_failed=1
    fi
  done

  # Загружаем lib/*.sh
  mkdir -p "${temp_dir}/lib"
  for file in "${LIB_FILES[@]}"; do
    if ! curl -sf --max-time 30 "${RAW_URL}/lib/${file}" -o "${temp_dir}/lib/${file}" 2>/dev/null; then
      warning "Не удалось загрузить lib/${file}"
      download_failed=1
    fi
  done

  # Загружаем core/*.sh
  mkdir -p "${temp_dir}/lib/core"
  for file in "${CORE_FILES[@]}"; do
    if ! curl -sf --max-time 30 "${RAW_URL}/lib/core/${file}" -o "${temp_dir}/lib/core/${file}" 2>/dev/null; then
      warning "Не удалось загрузить lib/core/${file}"
      download_failed=1
    fi
  done

  # Загружаем тесты
  mkdir -p "${temp_dir}/tests"
  for file in "${TEST_FILES[@]}"; do
    if ! curl -sf --max-time 30 "${RAW_URL}/tests/${file}" -o "${temp_dir}/tests/${file}" 2>/dev/null; then
      warning "Не удалось загрузить tests/${file}"
      download_failed=1
    fi
  done

  # Загружаем утилиты
  mkdir -p "${temp_dir}/utils"
  for file in "${UTIL_FILES[@]}"; do
    if ! curl -sf --max-time 30 "${RAW_URL}/utils/${file}" -o "${temp_dir}/utils/${file}" 2>/dev/null; then
      warning "Не удалось загрузить utils/${file}"
      download_failed=1
    fi
  done

  if [[ $download_failed -eq 1 ]]; then
    warning "$(get_str "MSG_ERR_DOWNLOAD_FAILED") (частично)"
  fi

  success "Файлы загружены"
  export TEMP_DIR="$temp_dir"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 6: Установка обновления
# ══════════════════════════════════════════════════════════════
step_install_update() {
  step_title "6" "$(get_str "MSG_TITLE_INSTALL")" "$(get_str "MSG_TITLE_INSTALL")"

  info "$(get_str "MSG_MSG_INSTALLING")..."

  # Сохраняем текущие конфиги
  local config_backup
  config_backup=$(mktemp -d)

  # Бэкап критических конфигов перед обновлением
  if [[ -f "/etc/cubiveil/s-ui.credentials" ]]; then
    cp "/etc/cubiveil/s-ui.credentials" "${config_backup}/s-ui.credentials"
  fi

  # Копируем новые файлы
  if [[ -d "${TEMP_DIR}" ]]; then
    # Копируем основные файлы
    for file in "${ROOT_FILES[@]}"; do
      if [[ -f "${TEMP_DIR}/${file}" ]]; then
        cp "${TEMP_DIR}/${file}" "${PROJECT_DIR}/${file}"
      fi
    done

    # Копируем lang
    if [[ -d "${TEMP_DIR}/lang" ]]; then
      cp -rp "${TEMP_DIR}/lang/"* "${PROJECT_DIR}/lang/" 2>/dev/null || true
    fi

    # Копируем lib
    if [[ -d "${TEMP_DIR}/lib" ]]; then
      cp -rp "${TEMP_DIR}/lib/"* "${PROJECT_DIR}/lib/" 2>/dev/null || true
    fi

    # Копируем тесты
    if [[ -d "${TEMP_DIR}/tests" ]]; then
      cp -rp "${TEMP_DIR}/tests/"* "${PROJECT_DIR}/tests/" 2>/dev/null || true
    fi

    # Копируем утилиты
    if [[ -d "${TEMP_DIR}/utils" ]]; then
      cp -rp "${TEMP_DIR}/utils/"* "${PROJECT_DIR}/utils/" 2>/dev/null || true
    fi

    # Обновляем .version
    if [[ -f "${TEMP_DIR}/.version" ]]; then
      cp "${TEMP_DIR}/.version" "${VERSION_FILE}"
    fi
  fi

  # Восстанавливаем конфиги
  if [[ -f "${config_backup}/s-ui.credentials" ]]; then
    info "S-UI config preserved"
  fi

  # Очистка
  rm -rf "${config_backup}"

  success "$(get_str "MSG_INFO_UPDATE_INSTALLED")"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 7: Обновление S-UI
# ══════════════════════════════════════════════════════════════
step_update_sui() {
  step_title "7" "Обновление S-UI" "Update S-UI"

  read -rp "  Обновить S-UI до последней версии? [y/N]: " update_sui

  if [[ "${update_sui,,}" != "y" ]]; then
    info "Пропуск обновления S-UI"
    return 0
  fi

  # Проверяем, установлена ли S-UI
  if [[ ! -f "/usr/local/s-ui/s-ui" ]]; then
    warn "S-UI не найдена"
    return 0
  fi

  info "S-UI updates are managed by the official installation script"
  info "To update manually, run the official install script again:"
  info "  bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh)"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 8: Перезапуск сервисов
# ══════════════════════════════════════════════════════════════
step_restart_services() {
  step_title "8" "Перезапуск сервисов" "Restart services"

  read -rp "  Перезапустить сервисы сейчас? [y/N]: " restart

  if [[ "${restart,,}" != "y" ]]; then
    info "Сервисы не перезапущены. Перезапустите вручную после обновления."
    return 0
  fi

  local services=("s-ui" "sing-box" "cubiveil-bot")

  for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
      info "Перезапуск $service..."
      if systemctl restart "$service" 2>/dev/null; then
        success "$service перезапущен"
      else
        warn "Не удалось перезапустить $service"
      fi
    else
      info "$service не активен — пропуск"
    fi
  done

  success "Перезапуск завершён"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 10: Завершение
# ══════════════════════════════════════════════════════════════
step_finish() {
  step_title "10" "$(get_str "MSG_TITLE_FINISH")" "$(get_str "MSG_TITLE_FINISH")"

  success "$(get_str "MSG_MSG_SUCCESS")"
  info "$(get_str "MSG_INFO_BACKUP_CREATED") ${BACKUP_PATH}"

  echo ""
  echo "  $(get_str "MSG_INFO_ROLLBACK_FROM")"
  echo "  bash ${SCRIPT_DIR}/rollback.sh ${BACKUP_PATH}"

  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  Статус сервисов:"
  echo "══════════════════════════════════════════════════════════"

  for service in s-ui sing-box cubiveil-bot; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
      echo -e "  ${GREEN}●${PLAIN} $service — активен"
    else
      echo -e "  ${YELLOW}○${PLAIN} $service — не активен"
    fi
  done

  echo "══════════════════════════════════════════════════════════"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════
main() {
  select_language
  step_check_environment
  step_check_versions
  step_confirm_update
  step_create_backup
  step_download_update
  step_install_update
  step_update_sui
  step_restart_services
  step_finish
}

# Only execute main if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
