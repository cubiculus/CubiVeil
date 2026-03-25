#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Fail2ban                       ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Настройка защиты от брутфорса (Fail2ban)                 ║
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

# Подключаем fail2ban модуль
if [[ -f "${SCRIPT_DIR}/lib/modules/fail2ban/install.sh" ]]; then
  source "${SCRIPT_DIR}/lib/modules/fail2ban/install.sh"
fi

# ── Функции / Functions ──────────────────────────────────────

# Получение текущего SSH порта
fail2ban_get_ssh_port() {
  local ssh_port
  ssh_port=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
  echo "${ssh_port:-22}"  # По умолчанию 22 если не задан
}

# Создание конфигурации Fail2ban
fail2ban_create_jail_config() {
  log_step "fail2ban_create_jail_config" "Creating Fail2ban jail configuration"

  local ssh_port
  ssh_port=$(fail2ban_get_ssh_port)

  log_info "Detected SSH port: ${ssh_port}"

  cat >/etc/fail2ban/jail.d/cubiveil.conf <<EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ${ssh_port}
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 24h
EOF

  log_debug "Created /etc/fail2ban/jail.d/cubiveil.conf"
}

# Включение и запуск Fail2ban
fail2ban_start_service() {
  log_step "fail2ban_start_service" "Starting Fail2ban service"

  svc_enable_start "fail2ban"
  svc_restart "fail2ban"
}

# Основная функция шага (вызывается из install-steps.sh)
step_fail2ban() {
  step_title "6" "Fail2ban" "Fail2ban"

  fail2ban_create_jail_config
  fail2ban_start_service

  local ssh_port
  ssh_port=$(fail2ban_get_ssh_port)
  ok "Fail2ban: SSH защита на порту ${ssh_port} (3 попытки → бан 24ч)"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { fail2ban_install; }
module_configure() { step_fail2ban; }
module_enable() { fail2ban_enable; }
module_disable() { fail2ban_disable; }
