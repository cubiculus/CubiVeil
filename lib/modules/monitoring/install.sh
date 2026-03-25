#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Monitoring Module (Enhanced)          ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль мониторинга с проверкой SSL                       ║
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

# Подключаем security (ENHANCED - использование verify_ssl_cert)
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
  source "${SCRIPT_DIR}/lib/security.sh"
fi

# ── Конфигурация / Configuration ────────────────────────────

MONITORING_LOG_DIR="/var/log/cubiveil/monitoring"
MONITORING_DATA_DIR="/var/lib/cubiveil/monitoring"

# Ключевые сервисы для мониторинга
MONITORED_SERVICES=("marzban" "sing-box" "cubiveil-bot" "ufw" "fail2ban")

# Пороги алертов
ALERT_CPU_THRESHOLD=80    # CPU utilization %
ALERT_RAM_THRESHOLD=80    # RAM utilization %
ALERT_DISK_THRESHOLD=85   # Disk usage %
ALERT_UPTIME_THRESHOLD=99 # Uptime %

# ── Инициализация / Initialization ─────────────────────────────

# Создание директорий для мониторинга
monitor_init() {
  log_step "monitor_init" "Initializing monitoring module"

  dir_ensure "$MONITORING_LOG_DIR"
  dir_ensure "$MONITORING_DATA_DIR"

  log_debug "Monitoring directories created"
}

# ── Мониторинг сервисов / Services Monitoring ────────────

# Проверка статуса сервисов
monitor_check_services() {
  log_step "monitor_check_services" "Checking services status"

  local all_active=true

  echo ""
  echo "Services Status:"
  echo "────────────────"

  for service in "${MONITORED_SERVICES[@]}"; do
    local status
    # shellcheck disable=SC2034
    local enabled

    if svc_active "$service"; then
      status="active"
      echo "  ✓ $service: $status"
    else
      status="inactive"
      echo "  ✗ $service: $status"
      all_active=false
    fi

    # Проверяем, включён ли сервис
    if svc_exists "$service"; then
      # shellcheck disable=SC2034
      enabled="enabled"
    else
      # shellcheck disable=SC2034
      enabled="not installed"
    fi
  done

  echo "────────────────"

  if [[ "$all_active" == "true" ]]; then
    log_success "All services are active"
    return 0
  else
    log_warn "Some services are inactive"
    return 1
  fi
}

# Получение статуса конкретного сервиса
monitor_service_status() {
  local service="$1"

  if svc_active "$service"; then
    echo "active"
    return 0
  elif svc_exists "$service"; then
    echo "inactive"
    return 1
  else
    echo "not installed"
    return 2
  fi
}

# ── Мониторинг ресурсов / Resources Monitoring ────────────────

# Мониторинг CPU
monitor_cpu() {
  local cpu_usage
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int($1)}')

  echo "$cpu_usage"
}

# Мониторинг RAM
monitor_ram() {
  local ram_usage
  ram_usage=$(free | grep Mem | awk '{printf "%.0f", ($3/$2) * 100.0}')

  echo "$ram_usage"
}

# Мониторинг диска
monitor_disk() {
  local disk_usage
  disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

  echo "$disk_usage"
}

# Проверка порогов ресурсов
monitor_check_resources() {
  log_step "monitor_check_resources" "Checking system resources"

  local cpu_usage ram_usage disk_usage
  cpu_usage=$(monitor_cpu)
  ram_usage=$(monitor_ram)
  disk_usage=$(monitor_disk)

  local alerts=0

  echo ""
  echo "Resource Usage:"
  echo "────────────────"

  echo "  CPU:    ${cpu_usage}%"
  if [[ $cpu_usage -ge $ALERT_CPU_THRESHOLD ]]; then
    log_warn "CPU usage is high: ${cpu_usage}%"
    ((alerts++))
  fi

  echo "  RAM:    ${ram_usage}%"
  if [[ $ram_usage -ge $ALERT_RAM_THRESHOLD ]]; then
    log_warn "RAM usage is high: ${ram_usage}%"
    ((alerts++))
  fi

  echo "  Disk:   ${disk_usage}%"
  if [[ $disk_usage -ge $ALERT_DISK_THRESHOLD ]]; then
    log_warn "Disk usage is high: ${disk_usage}%"
    ((alerts++))
  fi

  echo "────────────────"

  if [[ $alerts -gt 0 ]]; then
    log_warn "Found $alerts resource alerts"
    return 1
  else
    log_success "Resource usage is normal"
    return 0
  fi
}

# ── Мониторинг сети / Network Monitoring ─────────────────────

# Проверка сетевого соединения
monitor_network_check() {
  log_step "monitor_network_check" "Checking network connectivity"

  local hosts=("1.1.1.1" "8.8.8.8" "google.com")

  local reachable=0

  for host in "${hosts[@]}"; do
    if ping -c 1 -W 2 "$host" &>/dev/null; then
      log_success "Network: reachable to $host"
      ((reachable++))
      break
    fi
  done

  if [[ $reachable -gt 0 ]]; then
    return 0
  else
    log_error "Network: no connectivity"
    return 1
  fi
}

# Получение внешнего IP
monitor_external_ip() {
  local ip
  ip=$(get_server_ip 2>/dev/null)

  if [[ -n "$ip" ]]; then
    echo "$ip"
    return 0
  else
    echo "unknown"
    return 1
  fi
}

# Проверка SSL сертификатов сервера
monitor_check_ssl() {
  log_step "monitor_check_ssl" "Checking SSL certificates"

  local domains=()
  local external_ip
  external_ip=$(monitor_external_ip)

  # Проверяем внешний IP
  if [[ "$external_ip" != "unknown" ]]; then
    domains+=("$external_ip")
  fi

  # Добавляем тестовые домены
  domains+=("google.com" "cloudflare.com")

  local failed=0

  for domain in "${domains[@]}"; do
    log_info "Checking SSL certificate for: $domain"

    if verify_ssl_cert "$domain" 443 5 2>/dev/null; then
      log_success "SSL certificate valid: $domain"
    else
      log_warn "SSL certificate check failed: $domain"
      ((failed++))
    fi
  done

  if [[ $failed -gt 0 ]]; then
    log_warn "$failed SSL certificate checks failed"
    return 1
  fi

  return 0
}

# ── Мониторинг логов / Log Monitoring ───────────────────────

# Проверка ошибок в логах Marzban
monitor_check_marzban_logs() {
  log_step "monitor_check_marzban_logs" "Checking Marzban logs for errors"

  local errors
  errors=$(journalctl -u marzban --since "1 hour ago" --no-pager -p err 2>/dev/null | wc -l)

  if [[ $errors -gt 0 ]]; then
    log_warn "Found $errors errors in Marzban logs (last hour)"
    return 1
  else
    log_success "No errors in Marzban logs (last hour)"
    return 0
  fi
}

# Проверка ошибок в логах Sing-box
monitor_check_singbox_logs() {
  log_step "monitor_check_singbox_logs" "Checking Sing-box logs for errors"

  # Проверяем лог-файл если есть
  if [[ -f "/var/log/sing-box.log" ]]; then
    local errors
    errors=$(grep -i "error" "/var/log/sing-box.log" | wc -l)

    if [[ $errors -gt 0 ]]; then
      log_warn "Found $errors errors in Sing-box logs"
      return 1
    fi
  fi

  log_success "No errors in Sing-box logs"
  return 0
}

# Проверка ошибок в логах Fail2ban
monitor_check_fail2ban_logs() {
  log_step "monitor_check_fail2ban_logs" "Checking Fail2ban logs"

  local bans
  bans=$(fail2ban-client status sshd 2>/dev/null | grep "Banned IP" | awk '{print $4}')

  if [[ -n "$bans" ]]; then
    log_info "Fail2ban: currently banned $bans IPs"
  fi

  return 0
}

# ── Проверка здоровья / Health Check ─────────────────────────

# Полная проверка здоровья системы
monitor_health_check() {
  log_step "monitor_health_check" "Performing system health check"

  local health_score=0
  local total_checks=6

  echo ""
  echo "System Health Check:"
  echo "────────────────────────"

  # 1. Проверка сервисов
  if monitor_check_services >/dev/null 2>&1; then
    ((health_score++))
    echo "  ✓ Services: OK"
  else
    echo "  ✗ Services: FAIL"
  fi

  # 2. Проверка ресурсов
  if monitor_check_resources >/dev/null 2>&1; then
    ((health_score++))
    echo "  ✓ Resources: OK"
  else
    echo "  ✗ Resources: WARNING"
  fi

  # 3. Проверка сети
  if monitor_network_check >/dev/null 2>&1; then
    ((health_score++))
    echo "  ✓ Network: OK"
  else
    echo "  ✗ Network: FAIL"
  fi

  # 4. Проверка SSL
  if monitor_check_ssl >/dev/null 2>&1; then
    ((health_score++))
    echo "  ✓ SSL: OK"
  else
    echo "  ✗ SSL: WARNING"
  fi

  # 5. Проверка логов Marzban
  if monitor_check_marzban_logs >/dev/null 2>&1; then
    ((health_score++))
    echo "  ✓ Marzban logs: OK"
  else
    echo "  ✗ Marzban logs: WARNING"
  fi

  # 6. Проверка логов Sing-box
  if monitor_check_singbox_logs >/dev/null 2>&1; then
    ((health_score++))
    echo "  ✓ Sing-box logs: OK"
  else
    echo "  ✗ Sing-box logs: WARNING"
  fi

  echo "────────────────────────"

  local health_percent
  health_percent=$((health_score * 100 / total_checks))

  echo "Health Score: ${health_percent}%"

  if [[ $health_percent -ge 80 ]]; then
    log_success "System is healthy"
    return 0
  elif [[ $health_percent -ge 60 ]]; then
    log_warn "System health is degraded"
    return 1
  else
    log_error "System health is critical"
    return 2
  fi
}

# ── Отчёты / Reports ──────────────────────────────────────

# Генерация отчёта о системе
monitor_generate_report() {
  log_step "monitor_generate_report" "Generating system report"

  local report_file
  report_file="${MONITORING_DATA_DIR}/report-$(date +%Y%m%d_%H%M%S).txt"

  {
    echo "CubiVeil System Report"
    echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "IP Address: $(monitor_external_ip)"
    echo ""
    echo "=== Services ==="
    monitor_check_services
    echo ""
    echo "=== Resources ==="
    monitor_check_resources
    echo ""
    echo "=== Health ==="
    monitor_health_check
  } >"$report_file"

  log_success "Report generated: $report_file"
  echo "$report_file"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { monitor_init; }

# Настройка модуля: проверка порогов и создание конфигов
module_configure() {
  log_step "module_configure" "Configuring monitoring module"

  # Инициализируем модуль
  monitor_init

  # Создаём конфиг с порогами алертов
  local config_file="${MONITORING_DATA_DIR}/config.conf"

  cat >"$config_file" <<EOF
# CubiVeil Monitoring Configuration
# Generated: $(date)

# CPU Threshold (%)
ALERT_CPU_THRESHOLD=${ALERT_CPU_THRESHOLD}

# RAM Threshold (%)
ALERT_RAM_THRESHOLD=${ALERT_RAM_THRESHOLD}

# Disk Threshold (%)
ALERT_DISK_THRESHOLD=${ALERT_DISK_THRESHOLD}

# Uptime Threshold (%)
ALERT_UPTIME_THRESHOLD=${ALERT_UPTIME_THRESHOLD}

# Monitored Services
MONITORED_SERVICES="${MONITORED_SERVICES[*]}"
EOF

  chmod 644 "$config_file"
  log_info "Configuration file created: ${config_file}"

  # Проверяем наличие необходимых утилит
  local required_tools=("systemctl" "free" "df" "uptime")
  for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
      log_warn "Required tool not found: $tool"
    fi
  done

  log_success "Monitoring module configured"
}

# Включение модуля: настройка cron для периодических проверок
module_enable() {
  log_step "module_enable" "Enabling monitoring module"

  # Проверяем наличие cron
  if ! pkg_check "cron"; then
    log_warn "Cron not installed, installing..."
    pkg_install_packages "cron"
  fi

  # Создаём cron job для почасовой проверки здоровья
  local health_job="0 * * * * /bin/bash -c 'cd ${SCRIPT_DIR} && source lib/modules/monitoring/install.sh && monitor_health_check >> /var/log/cubiveil/monitoring-health.log 2>&1'"

  # Создаём cron job для ежедневного отчёта
  local report_job="0 6 * * * /bin/bash -c 'cd ${SCRIPT_DIR} && source lib/modules/monitoring/install.sh && monitor_generate_report >> /var/log/cubiveil/monitoring-report.log 2>&1'"

  local jobs_added=0

  if ! crontab -l 2>/dev/null | grep -q "monitor_health_check"; then
    (
      crontab -l 2>/dev/null | grep -v "monitor_health_check"
      echo "$health_job"
    ) | crontab -
    log_info "Hourly health check cron job added"
    ((jobs_added++))
  fi

  if ! crontab -l 2>/dev/null | grep -q "monitor_generate_report"; then
    (
      crontab -l 2>/dev/null | grep -v "monitor_generate_report"
      echo "$report_job"
    ) | crontab -
    log_info "Daily report cron job added"
    ((jobs_added++))
  fi

  if [[ $jobs_added -gt 0 ]]; then
    log_success "Monitoring cron jobs added"
  else
    log_info "Monitoring cron jobs already exist"
  fi

  log_success "Monitoring module enabled"
}

# Выключение модуля: удаление cron job
module_disable() {
  log_step "module_disable" "Disabling monitoring module"

  # Удаляем cron job для проверок
  if crontab -l 2>/dev/null | grep -q "monitor_health_check"; then
    crontab -l 2>/dev/null | grep -v "monitor_health_check" | crontab -
    log_success "Health check cron job removed"
  else
    log_info "Health check cron job not found"
  fi

  # Удаляем cron job для отчётов
  if crontab -l 2>/dev/null | grep -q "monitor_generate_report"; then
    crontab -l 2>/dev/null | grep -v "monitor_generate_report" | crontab -
    log_success "Report cron job removed"
  else
    log_info "Report cron job not found"
  fi

  log_success "Monitoring module disabled"
}

# Полная проверка здоровья
module_check() { monitor_health_check; }

# Проверка сервисов
module_check_services() { monitor_check_services; }

# Проверка ресурсов
module_check_resources() { monitor_check_resources; }

# Проверка SSL сертификатов
module_check_ssl() { monitor_check_ssl; }

# Генерация отчёта
module_report() { monitor_generate_report; }

# Статус конкретного сервиса
module_service_status() {
  local service="$1"
  monitor_service_status "$service"
}
