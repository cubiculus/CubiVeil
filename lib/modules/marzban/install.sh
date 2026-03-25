#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Marzban Module                        ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Модуль управления Marzban                                 ║
# ║  - Установка Marzban                                       ║
# ║  - Управление конфигурацией                                ║
# ║  - Управление сервисами                                    ║
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

MARZBAN_INSTALL_DIR="/opt/marzban"
MARZBAN_CONFIG_DIR="/var/lib/marzban"
MARZBAN_SERVICE="marzban"
MARZBAN_SCRIPT_URL="https://github.com/Gozargah/Marzban/raw/master/script.sh"

# ── Установка / Installation ────────────────────────────────

# Загрузка скрипта установки Marzban
marzban_download_script() {
  log_step "marzban_download_script" "Downloading Marzban installation script"

  local MARZBAN_SCRIPT="/tmp/marzban-install.sh"

  # Скачиваем скрипт с проверкой
  curl -fsSL "$MARZBAN_SCRIPT_URL" -o "$MARZBAN_SCRIPT" ||
    err "Не удалось скачать скрипт установки Marzban"

  # Проверка что файл не пустой (минимум 1KB)
  if [[ ! -s "$MARZBAN_SCRIPT" ]] || [[ $(stat -c%s "$MARZBAN_SCRIPT") -lt 1024 ]]; then
    rm -f "$MARZBAN_SCRIPT"
    err "Скачанный файл Marzban пуст или повреждён"
  fi

  # Проверка на корректность bash скрипта
  if ! bash -n "$MARZBAN_SCRIPT" 2>/dev/null; then
    rm -f "$MARZBAN_SCRIPT"
    err "Скачанный файл Marzban содержит синтаксические ошибки"
  fi

  log_debug "Marzban script downloaded and validated"
}

# Установка Marzban через официальный скрипт
marzban_install() {
  log_step "marzban_install" "Installing Marzban module"

  # Проверяем, установлен ли Marzban
  if [[ -d "$MARZBAN_INSTALL_DIR" ]]; then
    log_info "Marzban already installed at $MARZBAN_INSTALL_DIR"
    return 0
  fi

  info "Устанавливаю Marzban..."

  marzban_download_script

  local MARZBAN_SCRIPT="/tmp/marzban-install.sh"

  # Запускаем установку
  if ! bash "$MARZBAN_SCRIPT" -s -- install; then
    rm -f "$MARZBAN_SCRIPT"
    err "Установка Marzban не удалась. Лог: journalctl -u marzban -n 50"
  fi
  rm -f "$MARZBAN_SCRIPT"

  # Проверка что скрипт установки существует
  if [[ ! -f "$MARZBAN_INSTALL_DIR/script.sh" ]]; then
    err "Скрипт установки Marzban не найден"
  fi

  log_success "Marzban установлен"
}

# ── Настройка / Configuration ───────────────────────────────

# Создание базовой конфигурации
marzban_configure_basic() {
  log_step "marzban_configure_basic" "Creating basic Marzban configuration"

  # Генерируем базовые credentials
  local SUDO_USERNAME SUDO_PASSWORD SECRET_KEY PANEL_PATH SUB_PATH
  SUDO_USERNAME=$(gen_random 10)
  SUDO_PASSWORD=$(gen_random 16)
  SECRET_KEY=$(gen_random 32)
  PANEL_PATH=$(gen_random 14)
  SUB_PATH=$(gen_random 14)

  # Создаём .env конфигурацию
  cat >"${MARZBAN_INSTALL_DIR}/.env" <<EOF
# ── CubiVeil — Marzban конфигурация ──────────────────────────

UVICORN_HOST      = "0.0.0.0"
UVICORN_PORT      = 8000
UVICORN_ROOT_PATH    = "/${PANEL_PATH}"

SECRET_KEY = "${SECRET_KEY}"
DOCS       = false
DEBUG      = false

SUDO_USERNAME = "${SUDO_USERNAME}"
SUDO_PASSWORD = "${SUDO_PASSWORD}"

SQLALCHEMY_DATABASE_URL = "sqlite:////var/lib/marzban/db.sqlite3"

# Sing-box как основной бэкенд
SING_BOX_ENABLED         = true
SING_BOX_EXECUTABLE_PATH = "/usr/local/bin/sing-box"

# Минимальное логирование
UVICORN_LOG_LEVEL = "warning"
EOF

  log_debug "Basic Marzban configuration created"
}

# Настройка конфигурации
marzban_configure() {
  log_step "marzban_configure" "Configuring Marzban"

  # Создаём базовую конфигурацию если её нет
  if [[ ! -f "${MARZBAN_INSTALL_DIR}/.env" ]]; then
    marzban_configure_basic
  fi

  log_success "Marzban configured"
}

# ── Управление сервисом / Service Management ────────────────

# Включение Marzban
marzban_enable() {
  log_step "marzban_enable" "Enabling Marzban"

  svc_daemon_reload
  svc_enable "$MARZBAN_SERVICE"
  svc_start "$MARZBAN_SERVICE"

  # Проверяем запуск
  sleep 2
  if svc_active "$MARZBAN_SERVICE"; then
    log_success "Marzban enabled and started"
  else
    log_error "Marzban failed to start. Check logs: journalctl -u marzban -n 50"
    return 1
  fi
}

# Отключение Marzban
marzban_disable() {
  log_step "marzban_disable" "Disabling Marzban"

  svc_stop "$MARZBAN_SERVICE"
  svc_disable "$MARZBAN_SERVICE" 2>/dev/null || true

  log_success "Marzban disabled"
}

# Перезагрузка Marzban
marzban_reload() {
  log_step "marzban_reload" "Reloading Marzban"

  svc_restart "$MARZBAN_SERVICE"

  log_success "Marzban reloaded"
}

# ── Утилиты / Utilities ────────────────────────────────────

# Получение текущей версии
marzban_get_version() {
  if [[ -f "${MARZBAN_INSTALL_DIR}/script.sh" ]]; then
    # Пытаемся получить версию из скрипта
    grep "VERSION=" "${MARZBAN_INSTALL_DIR}/script.sh" 2>/dev/null | head -1 | cut -d= -f2 | tr -d '"' || echo "unknown"
  else
    echo "not installed"
  fi
}

# Проверка статуса
marzban_status() {
  if svc_active "$MARZBAN_SERVICE"; then
    local version
    version=$(marzban_get_version)
    log_success "Marzban is active (version: ${version})"
    return 0
  else
    log_warn "Marzban is not active"
    return 1
  fi
}

# Проверка готовности (ready state)
marzban_is_ready() {
  # Проверяем HTTP endpoint если сервис активен
  if svc_active "$MARZBAN_SERVICE"; then
    # Проверяем порт 8000 (по умолчанию)
    if nc -z localhost 8000 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# ── Обновление / Update ─────────────────────────────────────

# Обновление Marzban
marzban_update() {
  log_step "marzban_update" "Updating Marzban"

  local current_version
  current_version=$(marzban_get_version)

  log_info "Current version: ${current_version}"

  info "Updating Marzban..."

  # Загружаем скрипт обновления
  marzban_download_script

  local MARZBAN_SCRIPT="/tmp/marzban-install.sh"

  # Запускаем обновление
  if ! bash "$MARZBAN_SCRIPT" -s -- update; then
    rm -f "$MARZBAN_SCRIPT"
    log_error "Обновление Marzban не удалось. Лог: journalctl -u marzban -n 50"
    return 1
  fi
  rm -f "$MARZBAN_SCRIPT"

  # Перезапускаем сервис
  if svc_active "$MARZBAN_SERVICE"; then
    marzban_reload
  fi

  local new_version
  new_version=$(marzban_get_version)
  log_success "Marzban updated from ${current_version} to ${new_version}"
}

# ── Управление пользователями / User Management ─────────────

# Создание пользователя через Marzban CLI
marzban_create_user() {
  local username="$1"
  local traffic_limit="${2:-0}"  # 0 = безлимит

  log_step "marzban_create_user" "Creating user: ${username}"

  if [[ ! -f "${MARZBAN_INSTALL_DIR}/scripts/cli.py" ]]; then
    log_error "Marzban CLI not found"
    return 1
  fi

  # Создаём пользователя через Marzban CLI
  python3 "${MARZBAN_INSTALL_DIR}/scripts/cli.py" \
    user add -u "$username" --traffic-limit "$traffic_limit" >/dev/null 2>&1

  log_success "User ${username} created"
}

# Список пользователей
marzban_list_users() {
  log_step "marzban_list_users" "Listing Marzban users"

  if [[ ! -f "${MARZBAN_INSTALL_DIR}/scripts/cli.py" ]]; then
    log_error "Marzban CLI not found"
    return 1
  fi

  python3 "${MARZBAN_INSTALL_DIR}/scripts/cli.py" user list
}

# Удаление пользователя
marzban_delete_user() {
  local username="$1"

  log_step "marzban_delete_user" "Deleting user: ${username}"

  if [[ ! -f "${MARZBAN_INSTALL_DIR}/scripts/cli.py" ]]; then
    log_error "Marzban CLI not found"
    return 1
  fi

  python3 "${MARZBAN_INSTALL_DIR}/scripts/cli.py" \
    user delete -u "$username" >/dev/null 2>&1

  log_success "User ${username} deleted"
}

# ── Удаление / Removal ───────────────────────────────────────

# Удаление Marzban
marzban_remove() {
  log_step "marzban_remove" "Removing Marzban"

  # Останавливаем сервис
  if svc_active "$MARZBAN_SERVICE" ]]; then
    svc_stop "$MARZBAN_SERVICE"
  fi

  # Удаляем сервис
  if [[ -f "/etc/systemd/system/marzban.service" ]]; then
    rm -f "/etc/systemd/system/marzban.service"
    svc_daemon_reload
  fi

  # Удаляем Marzban через официальный скрипт
  if [[ -f "${MARZBAN_INSTALL_DIR}/script.sh" ]]; then
    bash "${MARZBAN_INSTALL_DIR}/script.sh" -s -- uninstall >/dev/null 2>&1 || true
  fi

  # Оставляем конфигурацию на случай восстановления

  log_success "Marzban removed"
}

# ── Резервное копирование / Backup ────────────────────────

# Создание бэкапа базы данных
marzban_backup_db() {
  local backup_dir="${1:-/tmp}"

  log_step "marzban_backup_db" "Backing up Marzban database"

  local backup_file="${backup_dir}/marzban-db-$(date +%Y%m%d_%H%M%S).sqlite3"

  if [[ -f "${MARZBAN_CONFIG_DIR}/db.sqlite3" ]]; then
    cp "${MARZBAN_CONFIG_DIR}/db.sqlite3" "$backup_file"
    log_success "Database backed up to ${backup_file}"
  else
    log_warn "Database file not found"
  fi
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { marzban_install; }
module_configure() { marzban_configure; }
module_enable() { marzban_enable; }
module_disable() { marzban_disable; }

# Обновление модуля
module_update() { marzban_update; }

# Удаление модуля
module_remove() { marzban_remove; }

# Статус модуля
module_status() { marzban_status; }

# Перезагрузка модуля
module_reload() { marzban_reload; }
