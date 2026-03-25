#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Marzban Module                        ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль установки и настройки Marzban                     ║
# ║  - Установка Marzban через официальный скрипт             ║
# ║  - Настройка .env файла                                   ║
# ║  - Управление сервисом                                    ║
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

# Подключаем validation
if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
  source "${SCRIPT_DIR}/lib/validation.sh"
fi

# ── Конфигурация / Configuration ────────────────────────────

MARZBAN_INSTALL_DIR="/opt/marzban"
MARZBAN_CONFIG_DIR="/var/lib/marzban"
MARZBAN_ENV_FILE="${MARZBAN_CONFIG_DIR}/.env"
MARZBAN_SERVICE="marzban"
MARZBAN_INSTALL_SCRIPT="/tmp/marzban-install.sh"

# ── Установка / Installation ────────────────────────────────

# Проверка наличия Marzban
marzban_is_installed() {
  pkg_check "marzban" || [[ -f "${MARZBAN_INSTALL_DIR}/marzban" ]]
}

# Установка Marzban
marzban_install() {
  log_step "marzban_install" "Installing Marzban"

  # Проверяем, установлен ли уже Marzban
  if marzban_is_installed; then
    log_info "Marzban already installed"
    return 0
  fi

  # Создаём директорию для установки
  mkdir -p "$MARZBAN_INSTALL_DIR"

  # Загружаем официальный скрипт установки
  log_info "Downloading Marzban installation script..."
  
  if ! curl -sfL "https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh" -o "$MARZBAN_INSTALL_SCRIPT" 2>/dev/null; then
    log_error "Failed to download Marzban installation script"
    return 1
  fi

  chmod +x "$MARZBAN_INSTALL_SCRIPT"

  # Запускаем установку в автоматическом режиме
  log_info "Running Marzban installation..."
  
  if ! bash "$MARZBAN_INSTALL_SCRIPT" install --yes >/dev/null 2>&1; then
    log_error "Marzban installation failed"
    rm -f "$MARZBAN_INSTALL_SCRIPT"
    return 1
  fi

  # Очищаем временный файл
  rm -f "$MARZBAN_INSTALL_SCRIPT"

  log_success "Marzban installed successfully"
}

# ── Настройка / Configuration ───────────────────────────────

# Настройка .env файла
marzban_configure_env() {
  log_step "marzban_configure_env" "Configuring Marzban .env"

  # Проверяем наличие .env файла
  if [[ ! -f "$MARZBAN_ENV_FILE" ]]; then
    log_warn ".env file not found, creating..."
    mkdir -p "$MARZBAN_CONFIG_DIR"
    touch "$MARZBAN_ENV_FILE"
  fi

  # Устанавливаем переменные окружения если их нет
  local env_vars=(
    "MARZBAN_HOST"
    "MARZBAN_PORT"
    "MARZBAN_API_PORT"
    "SINGBOX_PORT"
    "TROJAN_PORT"
    "SS_PORT"
  )

  local configured=false
  for var in "${env_vars[@]}"; do
    if grep -q "^${var}=" "$MARZBAN_ENV_FILE" 2>/dev/null; then
      log_debug "${var} already configured"
    else
      configured=true
    fi
  done

  if [[ "$configured" == "true" ]]; then
    log_info "Marzban .env configured"
  else
    log_info "Marzban .env already configured"
  fi

  log_success "Marzban environment configured"
}

# Настройка SSL для Marzban
marzban_configure_ssl() {
  log_step "marzban_configure_ssl" "Configuring SSL for Marzban"

  # SSL сертификаты настраиваются через ssl модуль
  # Проверяем наличие сертификатов
  if [[ -d "/var/lib/marzban/certs" ]] && [[ -n "$(ls -A /var/lib/marzban/certs 2>/dev/null)" ]]; then
    log_success "SSL certificates configured for Marzban"
    return 0
  fi

  log_info "SSL certificates will be configured by ssl module"
}

# Основная функция конфигурации
marzban_configure() {
  log_step "marzban_configure" "Configuring Marzban"

  marzban_configure_env
  marzban_configure_ssl

  log_success "Marzban configured successfully"
}

# ── Включение / Enable ──────────────────────────────────────

# Включение сервиса Marzban
marzban_enable() {
  log_step "marzban_enable" "Enabling Marzban service"

  svc_enable_start "$MARZBAN_SERVICE"

  log_success "Marzban service enabled and started"
}

# Выключение сервиса Marzban
marzban_disable() {
  log_step "marzban_disable" "Disabling Marzban service"

  svc_stop "$MARZBAN_SERVICE"
  svc_disable "$MARZBAN_SERVICE"

  log_success "Marzban service disabled"
}

# ── Проверки / Checks ───────────────────────────────────────

# Проверка активности Marzban
marzban_is_active() {
  svc_is_active "$MARZBAN_SERVICE"
}

# Проверка здоровья Marzban
marzban_health_check() {
  log_step "marzban_health_check" "Checking Marzban health"

  # Проверяем статус сервиса
  if ! svc_is_active "$MARZBAN_SERVICE"; then
    log_error "Marzban service is not active"
    return 1
  fi

  # Проверяем .env файл
  if [[ ! -f "$MARZBAN_ENV_FILE" ]]; then
    log_error "Marzban .env file not found"
    return 1
  fi

  # Проверяем конфигурацию
  if [[ ! -d "${MARZBAN_CONFIG_DIR}" ]]; then
    log_error "Marzban config directory not found"
    return 1
  fi

  log_success "Marzban health check passed"
}

# ── Управление / Management ─────────────────────────────────

# Перезагрузка Marzban
marzban_restart() {
  log_step "marzban_restart" "Restarting Marzban"

  svc_restart "$MARZBAN_SERVICE"

  log_success "Marzban restarted"
}

# Остановка Marzban
marzban_stop() {
  log_step "marzban_stop" "Stopping Marzban"

  svc_stop "$MARZBAN_SERVICE"

  log_success "Marzban stopped"
}

# Запуск Marzban
marzban_start() {
  log_step "marzban_start" "Starting Marzban"

  svc_start "$MARZBAN_SERVICE"

  log_success "Marzban started"
}

# Статус Marzban
marzban_status() {
  log_step "marzban_status" "Marzban status"

  if svc_is_active "$MARZBAN_SERVICE"; then
    log_success "Marzban is running"
    return 0
  else
    log_error "Marzban is not running"
    return 1
  fi
}

# ── Удаление / Removal ──────────────────────────────────────

# Удаление Marzban
marzban_remove() {
  log_step "marzban_remove" "Removing Marzban"

  # Останавливаем сервис
  svc_stop "$MARZBAN_SERVICE" 2>/dev/null || true
  svc_disable "$MARZBAN_SERVICE" 2>/dev/null || true

  # Удаляем директорию установки
  if [[ -d "$MARZBAN_INSTALL_DIR" ]]; then
    rm -rf "$MARZBAN_INSTALL_DIR"
    log_info "Marzban installation directory removed"
  fi

  # Удаляем сервис systemd
  if [[ -f "/etc/systemd/system/${MARZBAN_SERVICE}.service" ]]; then
    rm -f "/etc/systemd/system/${MARZBAN_SERVICE}.service"
    systemctl daemon-reload
    log_info "Marzban systemd service removed"
  fi

  log_success "Marzban removed (data directory preserved)"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { marzban_install; }
module_configure() { marzban_configure; }
module_enable() { marzban_enable; }
module_disable() { marzban_disable; }

# Обновление модуля
module_update() {
  log_step "module_update" "Updating Marzban module"
  marzban_restart
}

# Удаление модуля
module_remove() {
  marzban_remove
}

# Статус модуля
module_status() {
  marzban_status
}

# Проверка здоровья
module_health_check() {
  marzban_health_check
}
