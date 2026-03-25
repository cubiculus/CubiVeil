#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: System Update                   ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Обновление системы и установка зависимостей               ║
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

# Настройка окружения для безинтерактивного обновления
system_update_setup_env() {
  log_step "system_update_setup_env" "Setting up non-interactive update environment"

  # Отключаем все интерактивные диалоги dpkg/debconf/needrestart
  export DEBIAN_FRONTEND=noninteractive
  export UCF_FORCE_CONFFOLD=1

  # needrestart спрашивает о перезапуске сервисов — переводим в автоматический режим
  if [[ -f /etc/needrestart/needrestart.conf ]]; then
    sed -i "s/#\$nrconf{restart} = 'i'/\$nrconf{restart} = 'a'/" \
      /etc/needrestart/needrestart.conf 2>/dev/null || true
  fi
}

# Обновление индекса пакетов
system_update_apt() {
  log_step "system_update_apt" "Updating package index"
  pkg_update
}

# Обновление установленных пакетов
system_upgrade() {
  log_step "system_upgrade" "Upgrading installed packages"
  pkg_upgrade
}

# Установка зависимостей
system_install_dependencies() {
  log_step "system_install_dependencies" "Installing dependencies"

  pkg_install_packages \
    curl wget tar git jq ufw fail2ban \
    unattended-upgrades apt-listchanges \
    ca-certificates gnupg socat cron \
    python3 python3-pip \
    htop
}

# Основная функция шага (вызывается из install-steps.sh)
step_system_update() {
  step_title "2" "Обновление системы" "System update"

  system_update_setup_env
  system_update_apt
  system_upgrade
  system_install_dependencies

  ok "Система обновлена, зависимости установлены"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { :; }
module_configure() { step_system_update; }
module_enable() { :; }
module_disable() { :; }
