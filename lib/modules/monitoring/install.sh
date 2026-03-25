#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Monitoring Module                    ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Модуль мониторинга                                         ║
# ║  - Мониторинг сервисов                                    ║
# ║  - Мониторинг ресурсов (CPU, RAM, Disk)                  ║
# ║  - Проверка здоровья системы                               ║
# ║  - Анализ логов                                           ║
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

# ── Конфигурация / Configuration ────────────────────────────

MONITORING_LOG_DIR="/var/log/cubiveil/monitoring"
MONITORING_DATA_DIR="/var/lib/cubiveil/monitoring"

# Ключевые сервисы для мониторинга
MONITORED_SERVICES=("marzban" "sing-box" "cubiveil-bot" "ufw" "fail2ban")

# Пороги алертов
ALERT_CPU_THRESHOLD=80          # CPU utilization %
ALERT_RAM_THRESHOLD=80          # RAM utilization %
ALERT_DISK_THRESHOLD=85        # Disk usage %
ALERT_UPTIME_THRESHOLD=99      # Uptime %

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
      enabled="enabled"
    else
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

# ── Мониторинг логов / Log Monitoring ────────────────────────

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
  local total_checks=5

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

  # 4. Проверка логов Marzban
  if monitor_check_marzban_logs >/dev/null 2>&1; then
    ((health_score++))
    echo "  ✓ Marzban logs: OK"
  else
    echo "  ✗ Marzban logs: WARNING"
  fi

  # 5. Проверка логов Sing-box
  if monitor_check_singbox_logs >/dev/null 2>&1; then
    ((health_score++))
    echo "  ✓ Sing-box logs: OK"
  else
    echo "  ✗ Sing-box logs: WARNING"
  fi

  echo "────────────────────────"

  local health_percent
  health_percent=$(( health_score * 100 / total_checks ))

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

  local report_file="${MONITORING_DATA_DIR}/report-$(date +%Y%m%d_%H%M%S).txt"

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
  } > "$report_file"

  log_success "Report generated: $report_file"
  echo "$report_file"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { monitor_init; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }

# Полная проверка здоровья
module_check() { monitor_health_check; }

# Проверка сервисов
module_check_services() { monitor_check_services; }

# Проверка ресурсов
module_check_resources() { monitor_check_resources; }

# Генерация отчёта
module_report() { monitor_generate_report; }

# Статус конкретного сервиса
module_service_status() {
  local service="$1"
  monitor_service_status "$service"
}
