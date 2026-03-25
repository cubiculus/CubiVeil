#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Auto Updates                    ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Настройка автоматических обновлений безопасности          ║
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

# ── Функции / Functions ──────────────────────────────────────

# Создание конфигурации для автообновлений
auto_updates_create_config() {
  log_step "auto_updates_create_config" "Creating auto-updates configuration"

  cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

  log_debug "Created /etc/apt/apt.conf.d/20auto-upgrades"
}

# Создание конфигурации unattended-upgrades
auto_updates_create_unattended_config() {
  log_step "auto_updates_create_unattended_config" "Creating unattended-upgrades configuration"

  cat >/etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
// Только security-патчи — мажорные обновления вручную
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Dpkg::Options {
  "--force-confdef";
  "--force-confold";
};
EOF

  log_debug "Created /etc/apt/apt.conf.d/50unattended-upgrades"
}

# Включение сервиса unattended-upgrades
auto_updates_enable_service() {
  log_step "auto_updates_enable_service" "Enabling unattended-upgrades service"

  svc_enable_start "unattended-upgrades"
}

# Основная функция шага (вызывается из install-steps.sh)
step_auto_updates() {
  step_title "3" "Автообновления безопасности" "Security auto-updates"

  auto_updates_create_config
  auto_updates_create_unattended_config
  auto_updates_enable_service

  ok "Автообновления security-патчей настроены (без интерактивных диалогов)"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { :; }
module_configure() { step_auto_updates; }
module_enable() { :; }
module_disable() { :; }
