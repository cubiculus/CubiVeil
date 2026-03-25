#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Fail2ban Module                       ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль защиты от брутфорса (Fail2ban)                    ║
# ║  - Установка Fail2ban                                     ║
# ║  - Настройка SSH защиты                                   ║
# ║  - Управление правилами                                   ║
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

# ── Конфигурация / Configuration ────────────────────────────

FAIL2BAN_CONF_DIR="/etc/fail2ban/jail.d"
FAIL2BAN_CONF_FILE="${FAIL2BAN_CONF_DIR}/cubiveil.conf"

# Параметры по умолчанию
FAIL2BAN_DEFAULT_BANTIME="1h"
FAIL2BAN_DEFAULT_FINDTIME="10m"
FAIL2BAN_DEFAULT_MAXRETRY="5"
FAIL2BAN_SSH_BANTIME="24h"
FAIL2BAN_SSH_MAXRETRY="3"

# ── Установка / Installation ───────────────────────────────

# Установка Fail2ban
fail2ban_install() {
  log_step "fail2ban_install" "Installing Fail2ban"

  # Проверяем, установлен ли Fail2ban
  if pkg_check "fail2ban"; then
    log_info "Fail2ban already installed"
    return 0
  fi

  # Устанавливаем Fail2ban
  pkg_install_packages "fail2ban"

  log_success "Fail2ban installed successfully"
}

# ── Настройка / Configuration ───────────────────────────────

# Получение текущего SSH порта
fail2ban_get_ssh_port() {
  local ssh_port
  ssh_port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
  echo "${ssh_port:-22}"
}

# Создание конфигурации Fail2ban
fail2ban_configure() {
  log_step "fail2ban_configure" "Configuring Fail2ban"

  # Создаём директорию если нужно
  mkdir -p "$FAIL2BAN_CONF_DIR"

  # Получаем SSH порт
  local ssh_port
  ssh_port=$(fail2ban_get_ssh_port)

  log_info "Detected SSH port: ${ssh_port}"

  # Создаём конфигурацию
  cat >"${FAIL2BAN_CONF_FILE}" <<EOF
[DEFAULT]
bantime  = ${FAIL2BAN_DEFAULT_BANTIME}
findtime = ${FAIL2BAN_DEFAULT_FINDTIME}
maxretry = ${FAIL2BAN_DEFAULT_MAXRETRY}
backend  = systemd

[sshd]
enabled  = true
port     = ${ssh_port}
logpath  = %(sshd_log)s
maxretry = ${FAIL2BAN_SSH_MAXRETRY}
bantime  = ${FAIL2BAN_SSH_BANTIME}
EOF

  log_success "Fail2ban configured: SSH protection on port ${ssh_port}"
}

# ── Включение / Enabling ───────────────────────────────────

# Включение Fail2ban
fail2ban_enable() {
  log_step "fail2ban_enable" "Enabling Fail2ban"

  # Перезагружаем конфигурацию
  svc_daemon_reload

  # Включаем и запускаем сервис
  svc_enable_start "fail2ban"

  # Перезапускаем для применения конфигурации
  svc_restart "fail2ban"

  log_success "Fail2ban enabled successfully"
}

# Отключение Fail2ban
fail2ban_disable() {
  log_step "fail2ban_disable" "Disabling Fail2ban"

  svc_stop "fail2ban"
  svc_disable "fail2ban" 2>/dev/null || true

  log_success "Fail2ban disabled"
}

# ── Статус и проверка / Status & Verification ─────────────

# Получение статуса Fail2ban
fail2ban_status() {
  fail2ban-client status
}

# Получение статуса SSH jail
fail2ban_ssh_status() {
  fail2ban-client status sshd
}

# Проверка активности Fail2ban
# Возвращает 0 если активен, 1 если нет
fail2ban_is_active() {
  svc_active "fail2ban"
}

# Проверка конфигурации
fail2ban_check_config() {
  log_step "fail2ban_check_config" "Checking Fail2ban configuration"

  if [[ ! -f "$FAIL2BAN_CONF_FILE" ]]; then
    log_error "Fail2ban configuration file not found: $FAIL2BAN_CONF_FILE"
    return 1
  fi

  log_success "Fail2ban configuration found at $FAIL2BAN_CONF_FILE"
  cat "$FAIL2BAN_CONF_FILE" | while IFS= read -r line; do
    log_debug "  $line"
  done
}

# ── Управление банами / Ban Management ──────────────────────

# Разбан IP
fail2ban_unban() {
  local ip="$1"
  local jail="${2:-sshd}"

  log_step "fail2ban_unban" "Unbanning ${ip} from ${jail}"

  fail2ban-client set "$jail" unbanip "$ip" 2>/dev/null

  log_success "Unbanned ${ip} from ${jail}"
}

# Показать список забаненных IP
fail2ban_list_banned() {
  local jail="${1:-sshd}"

  fail2ban-client status "$jail" | grep "Banned IP" | cut -d: -f2 | tr -d ' '
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { fail2ban_install; }
module_configure() { fail2ban_configure; }
module_enable() { fail2ban_enable; }
module_disable() { fail2ban_disable; }

# Обновление конфигурации
module_update() {
  log_step "module_update" "Updating Fail2ban configuration"
  fail2ban_configure
  fail2ban_enable
}

# Удаление модуля
module_remove() {
  log_step "module_remove" "Removing Fail2ban module"

  # Останавливаем Fail2ban
  fail2ban_disable

  # Удаляем конфигурацию
  rm -f "$FAIL2BAN_CONF_FILE"

  log_success "Fail2ban module removed"
}
