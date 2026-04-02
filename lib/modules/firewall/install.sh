#!/bin/bash
# shellcheck disable=SC1071
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Firewall Module                       ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль конфигурации файрвола (UFW)                       ║
# ║  - Установка UFW                                          ║
# ║  - Настройка правил                                       ║
# ║  - Управление портами                                     ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей через init.sh ──────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Используем централизованный загрузчик для правильного порядка
if [[ -f "${SCRIPT_DIR}/lib/init.sh" ]]; then
  source "${SCRIPT_DIR}/lib/init.sh"
else
  # Fallback для обратной совместимости
  if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
    source "${SCRIPT_DIR}/lib/core/system.sh"
  fi
  if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
    source "${SCRIPT_DIR}/lib/core/log.sh"
  fi
  if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
    source "${SCRIPT_DIR}/lib/utils.sh"
  fi
  if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
    source "${SCRIPT_DIR}/lib/validation.sh"
  fi
fi

# ── Установка / Installation ────────────────────────────────

# Установка UFW
firewall_install() {
  log_step "firewall_install" "Installing UFW"

  # Проверяем, установлен ли UFW
  if pkg_check "ufw"; then
    log_info "UFW already installed"
    return 0
  fi

  # Устанавливаем UFW
  pkg_install_packages "ufw"

  log_success "UFW installed successfully"
}

# ── Настройка / Configuration ───────────────────────────────

# Сброс текущих правил
firewall_reset() {
  log_step "firewall_reset" "Resetting firewall rules"

  ufw --force reset >/dev/null 2>&1
  ufw default deny incoming >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1

  log_success "Firewall rules reset"
}

# Настройка базовых правил
firewall_configure() {
  log_step "firewall_configure" "Configuring firewall"

  # Сбрасываем текущие правила
  firewall_reset

  # Открываем SSH (предупреждение о смене порта)
  open_port 22 tcp "SSH — смени порт и закрой 22 после установки"

  # Открываем HTTPS для прокси
  open_port 443 tcp "VLESS Reality TCP + gRPC"
  open_port 443 udp "Hysteria2 QUIC"

  log_success "Firewall configured: 22/tcp, 443/tcp, 443/udp"

  # Предупреждение о смене SSH порта
  if [[ "$LANG_NAME" == "Русский" ]]; then
    warning "⚠️  Не забудь изменить SSH порт и закрыть порт 22!"
  else
    warning "⚠️  Don't forget to change SSH port and close port 22!"
  fi
}

# ── Включение / Enabling ───────────────────────────────────

# Включение UFW
firewall_enable() {
  log_step "firewall_enable" "Enabling firewall"

  ufw --force enable >/dev/null 2>&1

  # Проверяем статус
  if ufw status | grep -q "Status: active"; then
    log_success "Firewall enabled successfully"
  else
    log_error "Failed to enable firewall"
    return 1
  fi
}

# Отключение UFW
firewall_disable() {
  log_step "firewall_disable" "Disabling firewall"

  ufw --force disable >/dev/null 2>&1

  log_success "Firewall disabled"
}

# ── Управление портами / Port Management ───────────────────

# Открытие порта
firewall_open_port() {
  local port="$1"
  local proto="${2:-tcp}"

  # Validate port number using validate_port from validation.sh
  if ! validate_port "$port"; then
    log_error "Invalid port number: $port"
    return 1
  fi

  log_step "firewall_open_port" "Opening port ${port}/${proto}"

  ufw allow "${port}/${proto}" >/dev/null 2>&1

  log_success "Port ${port}/${proto} opened"
}

# Закрытие порта
firewall_close_port() {
  local port="$1"
  local proto="${2:-tcp}"

  log_step "firewall_close_port" "Closing port ${port}/${proto}"

  ufw delete allow "${port}/${proto}" >/dev/null 2>&1 || true

  log_success "Port ${port}/${proto} closed"
}

# ── Статус и проверка / Status & Verification ─────────────

# Получение статуса UFW
firewall_status() {
  ufw status numbered
}

# Проверка активности UFW
# Возвращает 0 если активен, 1 если нет
firewall_is_active() {
  ufw status | grep -q "Status: active"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { firewall_install; }
module_configure() { firewall_configure; }
module_enable() { firewall_enable; }
module_disable() { firewall_disable; }

# Обновление конфигурации
module_update() {
  log_step "module_update" "Updating firewall configuration"
  firewall_configure
}

# Удаление модуля
module_remove() {
  log_step "module_remove" "Removing firewall module"

  # Останавливаем UFW
  firewall_disable

  # Сбрасываем правила
  firewall_reset

  log_success "Firewall module removed"
}
