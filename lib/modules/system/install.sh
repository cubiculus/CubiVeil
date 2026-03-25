#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — System Module                         ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль системных настроек                                ║
# ║  - Обновление системы                                     ║
# ║  - Автообновления безопасности                            ║
# ║  - BBR оптимизация                                        ║
# ║  - Проверка IP-соседей                                    ║
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

# Подключаем security
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
  source "${SCRIPT_DIR}/lib/security.sh"
fi

# ── Настройка окружения для обновлений ───────────────────────

# Настройка окружения для безинтерактивного обновления
system_setup_update_env() {
  log_step "system_setup_update_env" "Setting up non-interactive update environment"

  # Отключаем все интерактивные диалоги dpkg/debconf/needrestart
  export DEBIAN_FRONTEND=noninteractive
  export UCF_FORCE_CONFFOLD=1

  # needrestart спрашивает о перезапуске сервисов — переводим в автоматический режим
  if [[ -f /etc/needrestart/needrestart.conf ]]; then
    sed -i "s/#\$nrconf{restart} = 'i'/\$nrconf{restart} = 'a'/" \
      /etc/needrestart/needrestart.conf 2>/dev/null || true
  fi

  log_debug "Non-interactive update environment configured"
}

# ── Обновление системы / System Updates ────────────────────

# Полное обновление системы
system_full_update() {
  log_step "system_full_update" "Performing full system update"

  system_setup_update_env
  pkg_update
  pkg_upgrade
  pkg_full_upgrade

  log_success "System updated successfully"
}

# Быстрое обновление пакетов
system_quick_update() {
  log_step "system_quick_update" "Performing quick package update"

  system_setup_update_env
  pkg_update

  log_success "Package index updated"
}

# ── Автообновления / Auto Updates ─────────────────────────

# Создание конфигурации для автообновлений
system_auto_updates_configure() {
  log_step "system_auto_updates_configure" "Configuring automatic updates"

  cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

  log_debug "Created /etc/apt/apt.conf.d/20auto-upgrades"
}

# Создание конфигурации unattended-upgrades
system_auto_updates_unattended_configure() {
  log_step "system_auto_updates_unattended_configure" "Configuring unattended-upgrades"

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
system_auto_updates_enable() {
  log_step "system_auto_updates_enable" "Enabling unattended-upgrades service"

  svc_enable_start "unattended-upgrades"

  log_debug "Unattended-upgrades service enabled"
}

# Полная настройка автообновлений
system_auto_updates_setup() {
  log_step "system_auto_updates_setup" "Setting up automatic security updates"

  system_auto_updates_configure
  system_auto_updates_unattended_configure
  system_auto_updates_enable

  log_success "Auto-updates configured"
}

# ── BBR оптимизация / BBR Optimization ───────────────────

# Загрузка модуля BBR
system_bbr_load_module() {
  log_step "system_bbr_load_module" "Loading BBR kernel module"

  modprobe tcp_bbr 2>/dev/null || true

  # Добавляем модуль в автозагрузку
  if [[ ! -f "/etc/modules-load.d/tcp-bbr.conf" ]]; then
    echo "tcp_bbr" >/etc/modules-load.d/tcp-bbr.conf
  fi

  log_debug "BBR module loaded"
}

# Создание конфигурации sysctl для BBR
system_bbr_create_sysctl_config() {
  log_step "system_bbr_create_sysctl_config" "Creating sysctl configuration for BBR"

  cat >/etc/sysctl.d/99-cubiveil.conf <<'EOF'
# CubiVeil — BBR и оптимизация сетевого стека

# BBR снижает задержки и повышает скорость на длинных маршрутах
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Увеличенные буферы для прокси с большим трафиком
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Переиспользование TIME_WAIT соединений
net.ipv4.tcp_tw_reuse = 1

# Лимит файловых дескрипторов
fs.file-max = 1000000
EOF

  log_debug "Created /etc/sysctl.d/99-cubiveil.conf"
}

# Применение настроек sysctl
system_bbr_apply_sysctl() {
  log_step "system_bbr_apply_sysctl" "Applying sysctl settings"

  sysctl -p /etc/sysctl.d/99-cubiveil.conf >/dev/null 2>&1 || true
}

# Полная настройка BBR
system_bbr_setup() {
  log_step "system_bbr_setup" "Setting up BBR optimization"

  system_bbr_load_module
  system_bbr_create_sysctl_config
  system_bbr_apply_sysctl

  local current
  current=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")

  log_success "BBR optimization enabled (current: ${current})"
}

# Проверка текущего контроля перегрузки TCP
system_bbr_check_status() {
  local CURRENT
  CURRENT=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")

  log_info "Current TCP congestion control: ${CURRENT}"

  if [[ "$CURRENT" == "bbr" ]]; then
    log_success "BBR is active"
    return 0
  else
    log_warn "BBR is not active (current: ${CURRENT})"
    return 1
  fi
}

# ── Проверка IP-соседей / IP Neighborhood Check ───────

# Проверка соседних IP адресов на VPN/хостинг
system_check_ip_neighborhood() {
  local SERVER_IP="$1"

  log_step "system_check_ip_neighborhood" "Checking IP neighborhood for VPN/hosting servers"

  # Определяем подсеть (первые 3 октета)
  local SUBNET
  SUBNET=$(echo "$SERVER_IP" | cut -d. -f1-3)

  # Параметры сканирования
  local CHECK_START=1
  local CHECK_END=10
  local STEP=1
  local MAX_CONCURRENT=5

  local VPN_COUNT=0
  local CHECKED=0

  # Время ожидания для curl (в секундах)
  local CURL_TIMEOUT=5

  # Задержка между запусками пакетов (сек)
  local RATE_DELAY=0.2

  # Параллельная проверка IP с rate limiting
  local temp_dir
  temp_dir=$(create_temp_dir "ip-check")
  local pids=()
  local batch_count=0

  for i in $(seq "$CHECK_START" "$STEP" "$CHECK_END"); do
    local CHECK_IP="${SUBNET}.${i}"
    [[ "$CHECK_IP" == "$SERVER_IP" ]] && continue

    # Rate limiting
    if [[ $batch_count -ge $MAX_CONCURRENT ]]; then
      wait "${pids[0]}" 2>/dev/null || true
      pids=("${pids[@]:1}")
      batch_count=0
      sleep "$RATE_DELAY"
    fi

    {
      local RESULT ORG
      RESULT=$(curl -s $CURL_TIMEOUT "https://ipinfo.io/${CHECK_IP}/json" 2>/dev/null || echo "")
      if echo "$RESULT" | grep -qi '"org"'; then
        ORG=$(echo "$RESULT" | grep '"org"' | sed 's/.*"org": *"\(.*\)".*/\1/' | tr '[:upper:]' '[:lower:]')
        if echo "$ORG" | grep -qiE 'vpn|proxy|tunnel|hosting|datacenter|vps|server|cloud'; then
          echo "VPN" >"${temp_dir}/${i}.txt"
        fi
      fi
    } &
    pids+=($!)
    ((batch_count++)) || true
  done

  # Ожидание завершения всех процессов
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  # Подсчет результатов
  for i in $(seq "$CHECK_START" "$STEP" "$CHECK_END"); do
    local CHECK_IP="${SUBNET}.${i}"
    [[ "$CHECK_IP" == "$SERVER_IP" ]] && continue
    if [[ -f "${temp_dir}/${i}.txt" ]]; then
      ((VPN_COUNT++)) || true
    fi
    ((CHECKED++)) || true
  done

  cleanup_temp_dir "$temp_dir"

  echo "$VPN_COUNT:$CHECKED"
}

# ── Управление сервисами / Service Management ─────────────

# Проверка статуса всех ключевых сервисов
system_check_services() {
  log_step "system_check_services" "Checking critical services status"

  local services=("marzban" "sing-box" "ufw" "fail2ban")
  local all_active=true

  for service in "${services[@]}"; do
    if svc_active "$service"; then
      log_success "${service}: active"
    else
      log_warn "${service}: inactive"
      all_active=false
    fi
  done

  if [[ "$all_active" == "true" ]]; then
    return 0
  else
    return 1
  fi
}

# Перезапуск всех ключевых сервисов
system_restart_services() {
  log_step "system_restart_services" "Restarting critical services"

  local services=("marzban" "sing-box" "fail2ban")

  for service in "${services[@]}"; do
    if svc_active "$service"; then
      svc_restart "$service"
      log_info "${service}: restarted"
    fi
  done

  log_success "Services restarted"
}

# ── Установка зависимостей / Dependencies Installation ─────

# Установка базовых зависимостей
system_install_base_dependencies() {
  log_step "system_install_base_dependencies" "Installing base dependencies"

  pkg_install_packages \
    curl wget tar git jq ufw fail2ban \
    unattended-upgrades apt-listchanges \
    ca-certificates gnupg socat cron \
    python3 python3-pip \
    htop

  log_success "Base dependencies installed"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Установка системного модуля
module_install() {
  log_step "module_install" "Installing system module"

  # Обновляем индекс пакетов
  pkg_update

  # Устанавливаем базовые зависимости
  system_install_base_dependencies

  # Настраиваем автоматические обновления безопасности
  system_auto_updates_setup

  # Настраиваем BBR оптимизацию
  system_bbr_setup

  log_success "System module installed successfully"
}

# Конфигурация модуля
module_configure() {
  log_step "module_configure" "Configuring system module"

  # Повторно применяем настройки автообновлений
  system_auto_updates_setup

  # Повторно применяем настройки BBR
  system_bbr_setup

  log_success "System module configured"
}

# Включение модуля
module_enable() {
  log_step "module_enable" "Enabling system module"

  # Включаем сервис автоматических обновлений
  svc_enable_start "unattended-upgrades"

  # Применяем настройки sysctl
  system_bbr_apply_sysctl

  log_success "System module enabled"
}

# Выключение модуля
module_disable() {
  log_step "module_disable" "Disabling system module"

  # Отключаем сервис автоматических обновлений
  systemctl stop "unattended-upgrades" 2>/dev/null || true
  systemctl disable "unattended-upgrades" 2>/dev/null || true

  log_info "System module disabled"
}

# Обновление модуля
module_update() {
  log_step "module_update" "Updating system module"

  system_full_update

  log_success "System module updated"
}

# Проверка статуса модуля
module_status() {
  log_step "module_status" "Checking system module status"

  # Проверяем статус BBR
  system_bbr_check_status

  # Проверяем статус сервисов
  system_check_services

  # Проверяем статус автообновлений
  if svc_active "unattended-upgrades"; then
    log_success "Auto-updates: active"
  else
    log_warn "Auto-updates: inactive"
  fi
}

# Быстрое обновление (для cron)
module_quick_update() {
  system_quick_update
}
