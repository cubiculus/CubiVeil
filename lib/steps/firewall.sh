#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Firewall                        ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Настройка файрвола (UFW)                                ║
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

# Подключаем firewall модуль
if [[ -f "${SCRIPT_DIR}/lib/modules/firewall/install.sh" ]]; then
  source "${SCRIPT_DIR}/lib/modules/firewall/install.sh"
fi

# Подключаем utils для функций open_port/close_port
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# ── Функции / Functions ──────────────────────────────────────

# Сброс правил UFW
firewall_reset_rules() {
  log_step "firewall_reset_rules" "Resetting firewall rules"

  ufw --force reset >/dev/null 2>&1
  ufw default deny incoming >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
}

# Открытие базовых портов
firewall_open_basic_ports() {
  log_step "firewall_open_basic_ports" "Opening basic ports"

  open_port 22 tcp "SSH — смени порт и закрой 22 после установки"
  open_port 443 tcp "VLESS Reality TCP + gRPC"
  open_port 443 udp "Hysteria2 QUIC"
}

# Включение UFW
firewall_enable_ufw() {
  log_step "firewall_enable_ufw" "Enabling firewall"

  ufw --force enable >/dev/null 2>&1
}

# Основная функция шага (вызывается из install-steps.sh)
step_firewall() {
  step_title "5" "Файрвол (ufw)" "Firewall (ufw)"

  firewall_reset_rules
  firewall_open_basic_ports
  firewall_enable_ufw

  ok "Файрвол включён: 22/tcp, 443/tcp, 443/udp"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    warn "$WARN_SSH_PORT_RU"
  else
    warn "$WARN_SSH_PORT"
  fi
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { firewall_install; }
module_configure() { step_firewall; }
module_enable() { firewall_enable; }
module_disable() { firewall_disable; }
