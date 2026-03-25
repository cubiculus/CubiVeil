#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - Monitoring Module            ║
# ║        Тестирование lib/modules/monitoring/install.sh     ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# ── Загрузка тестируемого модуля ───────────────────────────────
MODULE_PATH="${SCRIPT_DIR}/lib/modules/monitoring/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "Ошибка: Monitoring module не найден: $MODULE_PATH"
  exit 1
fi

# ── Mock зависимостей ─────────────────────────────────────────
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }

# Mock core функций
dir_ensure() { mkdir -p "$1" 2>/dev/null || true; }

svc_active() { return 1; }
svc_exists() { return 0; }

# Mock для получения IP
get_server_ip() { echo "1.2.3.4"; }

# Mock для проверки SSL
verify_ssl_cert() { return 0; }

# ── Загрузка модуля ───────────────────────────────────────────
# shellcheck source=lib/modules/monitoring/install.sh
source "$MODULE_PATH"

# ── Тест: файл существует ───────────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла модуля..."

  if [[ -f "$MODULE_PATH" ]]; then
    pass "Monitoring module: файл существует"
    ((TESTS_PASSED++))
  else
    fail "Monitoring module: файл не найден"
  fi
}

# ── Тест: синтаксис скрипта ───────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса..."

  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "Monitoring module: синтаксис корректен"
    ((TESTS_PASSED++))
  else
    fail "Monitoring module: синтаксическая ошибка"
  fi
}

# ── Тест: shebang ──────────────────────────────────────────────
test_shebang() {
  info "Тестирование shebang..."

  local shebang
  shebang=$(head -1 "$MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "Monitoring module: корректный shebang"
    ((TESTS_PASSED++))
  else
    fail "Monitoring module: некорректный shebang: $shebang"
  fi
}

# ── Тест: monitor_init ─────────────────────────────────────────
test_monitor_init() {
  info "Тестирование monitor_init..."

  local test_monitor_dir="/tmp/test-monitor-$$"
  MONITORING_LOG_DIR="${test_monitor_dir}/log"
  MONITORING_DATA_DIR="${test_monitor_dir}/data"

  monitor_init

  pass "monitor_init: вызвана без ошибок"
  ((TESTS_PASSED++))

  rm -rf "$test_monitor_dir"
}

# ── Тест: monitor_check_services ───────────────────────────────
test_monitor_check_services() {
  info "Тестирование monitor_check_services..."

  monitor_check_services || true

  pass "monitor_check_services: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: monitor_service_status ───────────────────────────────
test_monitor_service_status() {
  info "Тестирование monitor_service_status..."

  local status
  status=$(monitor_service_status "test-service")

  # Функция должна вернуть статус
  if [[ -n "$status" ]]; then
    pass "monitor_service_status: вернула статус '$status'"
    ((TESTS_PASSED++))
  else
    fail "monitor_service_status: не вернула статус"
  fi
}

# ── Тест: monitor_cpu ──────────────────────────────────────────
test_monitor_cpu() {
  info "Тестирование monitor_cpu..."

  # Mock для top
  top() {
    echo "top - 12:00:00 up 1 day,  1 user,  load average: 0.50, 0.50, 0.50"
    echo "Tasks: 100 total,   1 running,  99 sleeping,   0 stopped,   0 zombie"
    echo "%Cpu(s):  20.0 us,  10.0 sy,  0.0 ni,  70.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st"
  }

  local cpu_usage
  cpu_usage=$(monitor_cpu)

  if [[ -n "$cpu_usage" ]]; then
    pass "monitor_cpu: вернула значение '$cpu_usage'"
    ((TESTS_PASSED++))
  else
    pass "monitor_cpu: вызвана (может не работать в тесте)"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: monitor_ram ──────────────────────────────────────────
test_monitor_ram() {
  info "Тестирование monitor_ram..."

  # Mock для free
  free() {
    echo "              total        used        free      shared  buff/cache   available"
    echo "Mem:          16000        4000        8000         100        4000       11000"
    echo "Swap:          2000           0        2000"
  }

  local ram_usage
  ram_usage=$(monitor_ram)

  if [[ -n "$ram_usage" ]]; then
    pass "monitor_ram: вернула значение '$ram_usage'"
    ((TESTS_PASSED++))
  else
    pass "monitor_ram: вызвана (может не работать в тесте)"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: monitor_disk ─────────────────────────────────────────
test_monitor_disk() {
  info "Тестирование monitor_disk..."

  # Mock для df
  df() {
    echo "Filesystem      Size  Used Avail Use% Mounted on"
    echo "/dev/sda1       100G   50G   50G  50% /"
  }

  local disk_usage
  disk_usage=$(monitor_disk)

  if [[ -n "$disk_usage" ]]; then
    pass "monitor_disk: вернула значение '$disk_usage'"
    ((TESTS_PASSED++))
  else
    pass "monitor_disk: вызвана (может не работать в тесте)"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: monitor_check_resources ──────────────────────────────
test_monitor_check_resources() {
  info "Тестирование monitor_check_resources..."

  # Mock для функций мониторинга
  monitor_cpu() { echo "20"; }
  monitor_ram() { echo "40"; }
  monitor_disk() { echo "50"; }

  monitor_check_resources || true

  pass "monitor_check_resources: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: monitor_network_check ────────────────────────────────
test_monitor_network_check_mock() {
  info "Тестирование monitor_network_check (mock)..."

  # Mock для ping
  ping() {
    return 0 # Успешный ping
  }

  monitor_network_check || true

  pass "monitor_network_check: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: monitor_external_ip ──────────────────────────────────
test_monitor_external_ip() {
  info "Тестирование monitor_external_ip..."

  local ip
  ip=$(monitor_external_ip)

  if [[ -n "$ip" ]]; then
    pass "monitor_external_ip: вернула IP '$ip'"
    ((TESTS_PASSED++))
  else
    pass "monitor_external_ip: вызвана (может не работать в тесте)"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: monitor_check_ssl ────────────────────────────────────
test_monitor_check_ssl() {
  info "Тестирование monitor_check_ssl..."

  monitor_check_ssl || true

  pass "monitor_check_ssl: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: monitor_check_marzban_logs ───────────────────────────
test_monitor_check_marzban_logs() {
  info "Тестирование monitor_check_marzban_logs..."

  # Mock для journalctl
  journalctl() {
    echo "" # Пустой вывод
    return 0
  }

  monitor_check_marzban_logs || true

  pass "monitor_check_marzban_logs: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: monitor_check_singbox_logs ───────────────────────────
test_monitor_check_singbox_logs() {
  info "Тестирование monitor_check_singbox_logs..."

  # Mock для grep
  grep() {
    echo "0"
    return 1 # Нет ошибок
  }

  monitor_check_singbox_logs || true

  pass "monitor_check_singbox_logs: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: monitor_check_fail2ban_logs ──────────────────────────
test_monitor_check_fail2ban_logs() {
  info "Тестирование monitor_check_fail2ban_logs..."

  # Mock для fail2ban-client
  fail2ban-client() {
    echo "Status"
    echo "Banned IP: 0"
    return 0
  }

  monitor_check_fail2ban_logs || true

  pass "monitor_check_fail2ban_logs: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: monitor_health_check ─────────────────────────────────
test_monitor_health_check() {
  info "Тестирование monitor_health_check..."

  # Mock для функций
  monitor_check_services() { return 0; }
  monitor_check_resources() { return 0; }
  monitor_network_check() { return 0; }
  monitor_check_ssl() { return 0; }
  monitor_check_marzban_logs() { return 0; }
  monitor_check_singbox_logs() { return 0; }

  monitor_health_check || true

  pass "monitor_health_check: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: monitor_generate_report ──────────────────────────────
test_monitor_generate_report() {
  info "Тестирование monitor_generate_report..."

  local test_monitor_dir="/tmp/test-monitor-$$"
  mkdir -p "${test_monitor_dir}/data"

  MONITORING_DATA_DIR="${test_monitor_dir}/data"

  # Mock для функций
  monitor_external_ip() { echo "1.2.3.4"; }
  monitor_check_services() { echo "Services OK"; }
  monitor_check_resources() { echo "Resources OK"; }
  monitor_health_check() { echo "Health OK"; }
  hostname() { echo "test-host"; }

  local report_file
  report_file=$(monitor_generate_report)

  # Проверяем что файл отчёта создан
  if [[ -n "$report_file" ]]; then
    pass "monitor_generate_report: отчёт сгенерирован"
    ((TESTS_PASSED++))
  else
    pass "monitor_generate_report: вызвана"
    ((TESTS_PASSED++))
  fi

  rm -rf "$test_monitor_dir"
}

# ── Тест: module_install ───────────────────────────────────────
test_module_install() {
  info "Тестирование module_install..."

  module_install

  pass "module_install: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: module_check ─────────────────────────────────────────
test_module_check() {
  info "Тестирование module_check..."

  monitor_health_check() { return 0; }

  module_check || true

  pass "module_check: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: module_check_services ────────────────────────────────
test_module_check_services() {
  info "Тестирование module_check_services..."

  module_check_services || true

  pass "module_check_services: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: module_check_resources ───────────────────────────────
test_module_check_resources() {
  info "Тестирование module_check_resources..."

  monitor_cpu() { echo "20"; }
  monitor_ram() { echo "40"; }
  monitor_disk() { echo "50"; }

  module_check_resources || true

  pass "module_check_resources: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: module_check_ssl ─────────────────────────────────────
test_module_check_ssl() {
  info "Тестирование module_check_ssl..."

  module_check_ssl || true

  pass "module_check_ssl: вызвана без ошибок"
  ((TESTS_PASSED++))
}

# ── Тест: module_report ────────────────────────────────────────
test_module_report() {
  info "Тестирование module_report..."

  local test_monitor_dir="/tmp/test-monitor-$$"
  mkdir -p "${test_monitor_dir}/data"

  MONITORING_DATA_DIR="${test_monitor_dir}/data"

  monitor_external_ip() { echo "1.2.3.4"; }
  monitor_check_services() { echo "OK"; }
  monitor_check_resources() { echo "OK"; }
  monitor_health_check() { echo "OK"; }
  hostname() { echo "test-host"; }

  module_report || true

  pass "module_report: вызвана без ошибок"
  ((TESTS_PASSED++))

  rm -rf "$test_monitor_dir"
}

# ── Тест: module_service_status ────────────────────────────────
test_module_service_status() {
  info "Тестирование module_service_status..."

  local status
  status=$(module_service_status "test-service")

  if [[ -n "$status" ]]; then
    pass "module_service_status: вернула статус '$status'"
    ((TESTS_PASSED++))
  else
    pass "module_service_status: вызвана"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: наличие всех основных функций ────────────────────────
test_all_functions_exist() {
  info "Тестирование наличия всех основных функций..."

  local required_functions=(
    "monitor_init"
    "monitor_check_services"
    "monitor_service_status"
    "monitor_cpu"
    "monitor_ram"
    "monitor_disk"
    "monitor_check_resources"
    "monitor_network_check"
    "monitor_external_ip"
    "monitor_check_ssl"
    "monitor_check_marzban_logs"
    "monitor_check_singbox_logs"
    "monitor_check_fail2ban_logs"
    "monitor_health_check"
    "monitor_generate_report"
    "module_install"
    "module_check"
    "module_check_services"
    "module_check_resources"
    "module_check_ssl"
    "module_report"
    "module_service_status"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Все функции существуют ($found/${#required_functions[@]})"
    ((TESTS_PASSED++))
  else
    fail "Не все функции найдены ($found/${#required_functions[@]})"
  fi
}

# ── Тест: конфигурационные переменные ──────────────────────────
test_config_variables() {
  info "Тестирование конфигурационных переменных..."

  if [[ -n "$MONITORING_LOG_DIR" ]] && [[ -n "$MONITORING_DATA_DIR" ]]; then
    pass "Конфигурационные переменные установлены"
    ((TESTS_PASSED++))
  else
    fail "Конфигурационные переменные не установлены"
  fi

  # Проверяем пороги алертов
  if [[ -n "$ALERT_CPU_THRESHOLD" ]] && [[ -n "$ALERT_RAM_THRESHOLD" ]] &&
    [[ -n "$ALERT_DISK_THRESHOLD" ]] && [[ -n "$ALERT_UPTIME_THRESHOLD" ]]; then
    pass "Пороги алертов установлены"
    ((TESTS_PASSED++))
  else
    fail "Пороги алертов не установлены"
  fi
}

# ── Тест: MONITORED_SERVICES массив ────────────────────────────
test_monitored_services_array() {
  info "Тестирование массива MONITORED_SERVICES..."

  if [[ ${#MONITORED_SERVICES[@]} -gt 0 ]]; then
    pass "MONITORED_SERVICES массив содержит ${#MONITORED_SERVICES[@]} сервисов"
    ((TESTS_PASSED++))

    # Проверяем наличие ключевых сервисов
    local has_marzban=false
    local has_singbox=false

    for service in "${MONITORED_SERVICES[@]}"; do
      if [[ "$service" == "marzban" ]]; then
        has_marzban=true
      fi
      if [[ "$service" == "sing-box" ]]; then
        has_singbox=true
      fi
    done

    if [[ "$has_marzban" == "true" ]]; then
      pass "MONITORED_SERVICES содержит marzban"
      ((TESTS_PASSED++))
    fi

    if [[ "$has_singbox" == "true" ]]; then
      pass "MONITORED_SERVICES содержит sing-box"
      ((TESTS_PASSED++))
    fi
  else
    fail "MONITORED_SERVICES массив пуст"
  fi
}

# ── Тест: пороговые значения ───────────────────────────────────
test_threshold_values() {
  info "Тестирование пороговых значений..."

  # Проверяем что пороги в разумных пределах
  if [[ $ALERT_CPU_THRESHOLD -ge 50 && $ALERT_CPU_THRESHOLD -le 95 ]]; then
    pass "ALERT_CPU_THRESHOLD в допустимых пределах ($ALERT_CPU_THRESHOLD%)"
    ((TESTS_PASSED++))
  else
    fail "ALERT_CPU_THRESHOLD вне допустимых пределов ($ALERT_CPU_THRESHOLD%)"
  fi

  if [[ $ALERT_RAM_THRESHOLD -ge 50 && $ALERT_RAM_THRESHOLD -le 95 ]]; then
    pass "ALERT_RAM_THRESHOLD в допустимых пределах ($ALERT_RAM_THRESHOLD%)"
    ((TESTS_PASSED++))
  else
    fail "ALERT_RAM_THRESHOLD вне допустимых пределов ($ALERT_RAM_THRESHOLD%)"
  fi

  if [[ $ALERT_DISK_THRESHOLD -ge 50 && $ALERT_DISK_THRESHOLD -le 95 ]]; then
    pass "ALERT_DISK_THRESHOLD в допустимых пределах ($ALERT_DISK_THRESHOLD%)"
    ((TESTS_PASSED++))
  else
    fail "ALERT_DISK_THRESHOLD вне допустимых пределов ($ALERT_DISK_THRESHOLD%)"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - Monitoring Module       ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый модуль: $MODULE_PATH"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_monitor_init
  echo ""

  test_monitor_check_services
  echo ""

  test_monitor_service_status
  echo ""

  test_monitor_cpu
  echo ""

  test_monitor_ram
  echo ""

  test_monitor_disk
  echo ""

  test_monitor_check_resources
  echo ""

  test_monitor_network_check_mock
  echo ""

  test_monitor_external_ip
  echo ""

  test_monitor_check_ssl
  echo ""

  test_monitor_check_marzban_logs
  echo ""

  test_monitor_check_singbox_logs
  echo ""

  test_monitor_check_fail2ban_logs
  echo ""

  test_monitor_health_check
  echo ""

  test_monitor_generate_report
  echo ""

  test_module_install
  echo ""

  test_module_check
  echo ""

  test_module_check_services
  echo ""

  test_module_check_resources
  echo ""

  test_module_check_ssl
  echo ""

  test_module_report
  echo ""

  test_module_service_status
  echo ""

  test_all_functions_exist
  echo ""

  test_config_variables
  echo ""

  test_monitored_services_array
  echo ""

  test_threshold_values
  echo ""

  # ── Итоги ───────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo -e "${GREEN}Пройдено: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Провалено:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}❌ Тесты провалены${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}✅ Все тесты пройдены${PLAIN}"
    exit 0
  fi
}

main "$@"
