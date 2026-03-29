#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — S-UI Module                           ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль управления панелью S-UI                           ║
# ║  - Установка через официальный скрипт                     ║
# ║  - Настройка конфигурации                                 ║
# ║  - Интеграция с CubiVeil                                  ║
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

# ── Глобальные переменные / Global Variables ────────────────

# Пути S-UI
SUI_INSTALL_DIR="/usr/local/s-ui"
SUI_DB_DIR="/usr/local/s-ui/db"
SUI_CONFIG_FILE="${SUI_DB_DIR}/s-ui.db"
SUI_SERVICE="/etc/systemd/system/s-ui.service"
SINGBOX_SERVICE="/etc/systemd/system/sing-box.service"

# Порты по умолчанию (из s-ui документации)
SUI_PANEL_PORT="${SUI_PANEL_PORT:-2095}"
SUI_SUB_PORT="${SUI_SUB_PORT:-2096}"
SUI_PATH="${SUI_PATH:-/app/}"
SUI_SUB_PATH="${SUI_SUB_PATH:-/sub/}"

# ── Функции установки / Installation Functions ──────────────

# Проверка установленной панели
sui_check_installed() {
  if [[ -f "${SUI_INSTALL_DIR}/s-ui" ]]; then
    return 0
  fi
  return 1
}

# Получение версии s-ui
sui_get_version() {
  if sui_check_installed; then
    "${SUI_INSTALL_DIR}/s-ui" version 2>/dev/null || echo "unknown"
  else
    echo "not installed"
  fi
}

# Остановка сервисов
sui_stop_services() {
  log_info "Stopping s-ui services..."
  systemctl stop s-ui 2>/dev/null || true
  systemctl stop sing-box 2>/dev/null || true
}

# Запуск сервисов
sui_start_services() {
  log_info "Starting s-ui services..."
  systemctl daemon-reload
  systemctl enable s-ui --now 2>/dev/null || true
  systemctl enable sing-box --now 2>/dev/null || true
}

# Проверка статуса сервисов
sui_check_services() {
  local sui_status=false
  local singbox_status=false

  if systemctl is-active --quiet s-ui 2>/dev/null; then
    sui_status=true
  fi

  if systemctl is-active --quiet sing-box 2>/dev/null; then
    singbox_status=true
  fi

  if [[ "$sui_status" == "true" ]] && [[ "$singbox_status" == "true" ]]; then
    return 0
  fi
  return 1
}

# ── Модульный интерфейс / Module Interface ─────────────────

module_install() {
  log_step "sui_install" "Installing S-UI module"

  # Dry-run mode: skip actual installation
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install S-UI panel"
    log_info "[DRY-RUN] Panel port: ${SUI_PANEL_PORT}"
    log_info "[DRY-RUN] Subscription port: ${SUI_SUB_PORT}"
    log_info "[DRY-RUN] Panel path: ${SUI_PATH}"
    log_info "[DRY-RUN] Subscription path: ${SUI_SUB_PATH}"
    return 0
  fi

  # Проверяем, установлена ли панель
  if sui_check_installed; then
    log_info "S-UI already installed at ${SUI_INSTALL_DIR}"
    log_info "Version: $(sui_get_version)"
    return 0
  fi

  log_info "S-UI panel installation directory: ${SUI_INSTALL_DIR}"
  log_info "Database directory: ${SUI_DB_DIR}"
}

module_configure() {
  log_step "sui_configure" "Configuring S-UI panel"

  # Dry-run mode: skip actual configuration
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would configure S-UI panel"
    return 0
  fi

  # Создаём директорию базы данных если не существует
  mkdir -p "${SUI_DB_DIR}"
  chmod 755 "${SUI_DB_DIR}"

  # Проверяем наличие сервисных файлов
  if [[ -f "${SUI_SERVICE}" ]]; then
    log_info "S-UI systemd service found"
  else
    log_warn "S-UI systemd service not found - installation may be incomplete"
  fi

  if [[ -f "${SINGBOX_SERVICE}" ]]; then
    log_info "Sing-box systemd service found"
  else
    log_warn "Sing-box systemd service not found - installation may be incomplete"
  fi

  # Экспортируем информацию о панели для последующего использования
  mkdir -p /etc/cubiveil
  cat > /etc/cubiveil/s-ui.credentials <<EOF
SUI_PANEL_PORT=${SUI_PANEL_PORT}
SUI_SUB_PORT=${SUI_SUB_PORT}
SUI_PATH=${SUI_PATH}
SUI_SUB_PATH=${SUI_SUB_PATH}
SUI_INSTALL_DIR=${SUI_INSTALL_DIR}
SUI_DB_DIR=${SUI_DB_DIR}
EOF
  chmod 600 /etc/cubiveil/s-ui.credentials

  log_success "S-UI credentials saved to /etc/cubiveil/s-ui.credentials"
}

module_enable() {
  log_step "sui_enable" "Enabling S-UI services"

  # Dry-run mode: skip actual enable
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would enable s-ui and sing-box services"
    return 0
  fi

  # Проверяем статус сервисов
  if sui_check_services; then
    log_success "S-UI services are running"
    return 0
  fi

  # Пытаемся запустить сервисы
  sui_start_services

  # Ждём запуска до 30 секунд
  local max_wait=30
  local start_time
  start_time=$(date +%s)

  while true; do
    local now_time
    now_time=$(date +%s)
    local elapsed=$((now_time - start_time))

    if [[ $elapsed -ge $max_wait ]]; then
      break
    fi

    if sui_check_services; then
      log_success "S-UI services enabled and running"
      return 0
    fi

    sleep 2
  done

  log_warn "S-UI services may not be running - check with: systemctl status s-ui"
  return 1
}

module_disable() {
  log_step "sui_disable" "Disabling S-UI services"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would disable s-ui and sing-box services"
    return 0
  fi

  sui_stop_services
  systemctl disable s-ui 2>/dev/null || true
  systemctl disable sing-box 2>/dev/null || true

  log_success "S-UI services disabled"
}

module_update() {
  log_step "sui_update" "Updating S-UI panel"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would update S-UI to latest version"
    return 0
  fi

  if ! sui_check_installed; then
    log_warn "S-UI not installed - skipping update"
    return 0
  fi

  log_info "Current version: $(sui_get_version)"
  log_info "S-UI updates are managed by the official installation script"
  log_info "To update manually, run the official install script again"
}

module_remove() {
  log_step "sui_remove" "Removing S-UI panel"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would remove S-UI panel"
    return 0
  fi

  log_warn "This will remove S-UI panel and all configurations"
  log_warn "Database and certificates will be preserved"

  # Останавливаем сервисы
  sui_stop_services

  # Отключаем сервисы
  systemctl disable s-ui 2>/dev/null || true
  systemctl disable sing-box 2>/dev/null || true

  # Удаляем сервисные файлы
  rm -f "${SUI_SERVICE}" 2>/dev/null || true
  rm -f "${SINGBOX_SERVICE}" 2>/dev/null || true

  # Перезагружаем systemd
  systemctl daemon-reload

  # Удаляем установочную директорию
  if [[ -d "${SUI_INSTALL_DIR}" ]]; then
    rm -rf "${SUI_INSTALL_DIR}"
    log_info "S-UI installation directory removed"
  fi

  # Сохраняем базу данных
  if [[ -d "${SUI_DB_DIR}" ]]; then
    log_info "Database directory preserved at ${SUI_DB_DIR}"
  fi

  log_success "S-UI panel removed"
}

module_status() {
  log_step "sui_status" "Checking S-UI status"

  echo ""
  echo "══════════════════════════════════════════════════════"
  echo "  S-UI Panel Status"
  echo "══════════════════════════════════════════════════════"
  echo ""

  # Статус установки
  if sui_check_installed; then
    echo -e "  Installation: \033[0;32mInstalled\033[0m"
    echo "  Version: $(sui_get_version)"
    echo "  Install Dir: ${SUI_INSTALL_DIR}"
    echo "  Database: ${SUI_DB_DIR}"
  else
    echo -e "  Installation: \033[0;31mNot Installed\033[0m"
  fi

  echo ""

  # Статус сервисов
  echo "  Services:"
  if systemctl is-active --quiet s-ui 2>/dev/null; then
    echo -e "    s-ui: \033[0;32mActive (running)\033[0m"
  else
    echo -e "    s-ui: \033[0;31mInactive\033[0m"
  fi

  if systemctl is-active --quiet sing-box 2>/dev/null; then
    echo -e "    sing-box: \033[0;32mActive (running)\033[0m"
  else
    echo -e "    sing-box: \033[0;31mInactive\033[0m"
  fi

  echo ""

  # Информация из credentials
  if [[ -f /etc/cubiveil/s-ui.credentials ]]; then
    echo "  Configuration:"
    source /etc/cubiveil/s-ui.credentials
    echo "    Panel Port: ${SUI_PANEL_PORT}"
    echo "    Panel Path: ${SUI_PATH}"
    echo "    Subscription Port: ${SUI_SUB_PORT}"
    echo "    Subscription Path: ${SUI_SUB_PATH}"
  fi

  echo ""
  echo "══════════════════════════════════════════════════════"
  echo ""
}

module_health_check() {
  local errors=0

  # Check if installed
  if ! sui_check_installed; then
    log_error "S-UI not installed"
    errors=$((errors + 1))
  fi

  # Check s-ui service
  if ! systemctl is-active --quiet s-ui 2>/dev/null; then
    log_warn "S-UI service is not running"
    errors=$((errors + 1))
  fi

  # Check sing-box service
  if ! systemctl is-active --quiet sing-box 2>/dev/null; then
    log_warn "Sing-box service is not running"
    errors=$((errors + 1))
  fi

  # Check database directory
  if [[ ! -d "${SUI_DB_DIR}" ]]; then
    log_error "S-UI database directory not found"
    errors=$((errors + 1))
  fi

  return $errors
}

# ── Экспорт переменных / Export Variables ─────────────────────

export SUI_INSTALL_DIR
export SUI_DB_DIR
export SUI_PANEL_PORT
export SUI_SUB_PORT
export SUI_PATH
export SUI_SUB_PATH
