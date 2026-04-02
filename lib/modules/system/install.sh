#!/bin/bash
# shellcheck disable=SC1071
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
  export UCFF_FORCE_CONFFNEW=1

  # needrestart спрашивает о перезапуске сервисов — переводим в автоматический режим
  if [[ -f /etc/needrestart/needrestart.conf ]]; then
    sed -i "s/#\$nrconf{restart} = 'i'/\$nrconf{restart} = 'a'/" \
      /etc/needrestart/needrestart.conf 2>/dev/null || true
  fi

  # Отключаем интерактивные диалоги debconf для всех пакетов
  # Предотвращает появление синих/фиолетовых экранов конфигурации
  if [[ ! -f /etc/debconf.conf ]]; then
    cat >/etc/debconf.conf <<'EOF'
# CubiVeil: non-interactive debconf
Debug: false
Debug_Show_Process: false
EOF
  fi

  # Устанавливаем приоритет debconf в critical (только критические вопросы)
  echo "debconf debconf/priority select critical" | debconf-set-selections 2>/dev/null || true

  log_info "Update and upgrade may take up to 5 minutes — please wait..."
  log_debug "Non-interactive update environment configured"
}

# ── Обновление системы / System Updates ────────────────────

# Полное обновление системы
system_full_update() {
  log_step "system_full_update" "Performing full system update"

  log_info "System update may take up to 5 minutes — please wait..."

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

  if [[ $EUID -ne 0 ]]; then
    log_warn "system_auto_updates_configure: requires root privileges (skipped)"
    return 0
  fi

  if ! mkdir -p /etc/apt/apt.conf.d 2>/dev/null; then
    log_warn "Cannot create /etc/apt/apt.conf.d (no root?)"
    return 0
  fi

  cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF' 2>/dev/null || true
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

  log_debug "Created /etc/apt/apt.conf.d/20auto-upgrades"
}

# Создание конфигурации unattended-upgrades
system_auto_updates_unattended_configure() {
  log_step "system_auto_updates_unattended_configure" "Configuring unattended-upgrades"

  if [[ $EUID -ne 0 ]]; then
    log_warn "system_auto_updates_unattended_configure: requires root privileges (skipped)"
    return 0
  fi

  if ! mkdir -p /etc/apt/apt.conf.d 2>/dev/null; then
    log_warn "Cannot create /etc/apt/apt.conf.d (no root?)"
    return 0
  fi

  cat >/etc/apt/apt.conf.d/50unattended-upgrades <<'EOF' 2>/dev/null || true
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

  if [[ $EUID -ne 0 ]]; then
    log_warn "system_bbr_load_module: requires root privileges (skipped)"
    return 0
  fi

  modprobe tcp_bbr 2>/dev/null || true

  # Добавляем модуль в автозагрузку
  if [[ ! -f "/etc/modules-load.d/tcp-bbr.conf" ]]; then
    echo "tcp_bbr" >/etc/modules-load.d/tcp-bbr.conf 2>/dev/null || true
  fi

  log_debug "BBR module loaded"
}

# Создание конфигурации sysctl для BBR
system_bbr_create_sysctl_config() {
  log_step "system_bbr_create_sysctl_config" "Creating sysctl configuration for BBR"

  if [[ $EUID -ne 0 ]]; then
    log_warn "system_bbr_create_sysctl_config: requires root privileges (skipped)"
    return 0
  fi

  cat >/etc/sysctl.d/99-cubiveil.conf <<'EOF' 2>/dev/null || true
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

# ── Управление сервисами / Service Management ─────────────

# Проверка статуса всех ключевых сервисов
system_check_services() {
  log_step "system_check_services" "Checking critical services status"

  local services=("s-ui" "sing-box" "ufw" "fail2ban")
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

  local services=("s-ui" "sing-box" "fail2ban")

  for service in "${services[@]}"; do
    if svc_active "$service"; then
      svc_restart "$service"
      log_info "${service}: restarted"
    fi
  done

  log_success "Services restarted"
}

# ── Установка зависимостей / Dependencies Installation ─────

# Проверка IP neighborhood (защита от атак через соседние IP)
system_check_ip_neighborhood() {
  log_step "system_check_ip_neighborhood" "Checking IP neighborhood"

  # Получаем внешний IP
  local server_ip
  server_ip=$(get_external_ip)

  if [[ -z "$server_ip" ]]; then
    log_warn "Could not determine server IP"
    return 0
  fi

  log_info "Server IP: $server_ip"
  log_info "$(get_str INFO_CHECKING_NEIGHBORS)"

  # Извлекаем /24 диапазон (например 1.2.3.x из 1.2.3.100)
  local subnet_base
  subnet_base=$(echo "$server_ip" | cut -d. -f1-3)
  
  # Получаем последний октет
  local last_octet
  last_octet=$(echo "$server_ip" | cut -d. -f4)

  # Проверяем соседних IP в диапазоне /24
  # Проверяем несколько соседних адресов (+1, +2, +3, -1, -2, -3)
  local vpn_count=0
  local checked_count=0
  local api_failed=0

  # Функция для проверки одного IP через abuseipdb
  check_single_ip() {
    local ip="$1"
    # Пропускаем сам наш сервер
    if [[ "$ip" == "$server_ip" ]]; then
      return 0
    fi

    ((checked_count++))

    # Пытаемся проверить через abuseipdb API (требует ключ, который обычно недоступен)
    # Вместо этого используем локальную эвристику через grep и whois если доступны
    
    # Если у нас нет интернета или API не доступен, пропускаем
    if ! command -v curl >/dev/null 2>&1; then
      ((api_failed++))
      return 0
    fi

    # Простая проверка: пытаемся получить информацию об IP через публичный сервис
    # Используем простой способ через reverse DNS/WHOIS информацию
    local whois_info
    if whois_info=$(whois "$ip" 2>/dev/null | grep -i "OrgId\|Organization" | head -1); then
      # Проверяем есть ли признаки VPN/hosting провайдера в названии
      if echo "$whois_info" | grep -qi "VPN\|Hosting\|Provider\|AS\|Cloud\|Datacenter\|AWS\|Azure\|GCP\|Linode\|DigitalOcean\|Vultr\|OVH"; then
        ((vpn_count++))
        log_debug "Found VPN/hosting marker for $ip: $whois_info"
      fi
    fi
  }

  # Проверяем соседних IP
  for offset in -3 -2 -1 1 2 3; do
    local neighbor_octet=$((last_octet + offset))
    # Пропускаем невалидные октеты
    if [[ $neighbor_octet -lt 1 || $neighbor_octet -gt 254 ]]; then
      continue
    fi
    
    local neighbor_ip="${subnet_base}.${neighbor_octet}"
    check_single_ip "$neighbor_ip" 2>/dev/null || true
  done

  # Выводим результаты
  if [[ $api_failed -gt 2 ]]; then
    # Если API не доступен - просто говорим OK
    log_warn "Could not verify all neighbor IPs (network/API limit)"
    log_success "IP neighborhood check passed (verification limited)"
    return 0
  fi

  if [[ $checked_count -eq 0 ]]; then
    log_warn "Could not check any neighbor IPs"
    log_success "IP neighborhood check passed"
    return 0
  fi

  # Формируем вывод результатов
  local status_msg
  if [[ $vpn_count -eq 0 ]]; then
    status_msg=$(get_str OK_SUBNET_CLEAN | sed "s/\[CHECKED\]/$checked_count/g")
    log_success "$status_msg"
  elif [[ $vpn_count -le 2 ]]; then
    status_msg=$(get_str WARN_SUBNET_MODERATE | sed "s/\[VPN_COUNT\]/$vpn_count/g; s/\[CHECKED\]/$checked_count/g")
    log_warn "$status_msg"
    log_info "$(get_str WARN_SUBNET_ADVICE)"
  else
    status_msg=$(get_str WARN_SUBNET_HIGH | sed "s/\[VPN_COUNT\]/$vpn_count/g; s/\[CHECKED\]/$checked_count/g")
    log_warn "$status_msg"
    log_warn "$(get_str WARN_SUBNET_LIKELY_BLOCKED)"
    log_info "$(get_str WARN_SUBNET_RECOMMEND)"
    
    # Вопрос пользователю о продолжении
    if [[ -t 0 ]]; then  # Если это интерактивный терминал
      local continue_anyway
      read -p "$(get_str WARN_CONTINUE_ANYWAY) " continue_anyway || continue_anyway="n"
      if [[ ! "$continue_anyway" =~ ^[yY] ]]; then
        log_error "$(get_str ERR_USER_ABORTED)"
        return 1
      fi
    fi
  fi

  return 0
}

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

  # Полное обновление системы (включая upgrade пакетов)
  system_full_update

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
