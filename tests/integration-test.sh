#!/bin/bash
# shellcheck disable=SC1071,SC1111
# ╔══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Test Suite                           ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                          ║
# ║  Комплексное тестирование всех модулей                   ║
# ╚══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей / Dependencies ─────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# Подключаем manifest
if [[ -f "${SCRIPT_DIR}/lib/manifest.sh" ]]; then
  source "${SCRIPT_DIR}/lib/manifest.sh"
fi

# ── Конфигурация тестирования / Test Configuration ──────────────────────────

TEST_RESULTS_DIR="/tmp/cubiveil-test-results"
TEST_LOG_FILE="${TEST_RESULTS_DIR}/test.log"

# Счётчики тестов
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ── Инициализация / Initialization ──────────────────────────────────────────

# Инициализация тестовой среды
test_init() {
  log_step "test_init" "Initializing test environment"

  dir_ensure "$TEST_RESULTS_DIR"

  # Очищаем лог-файл
  echo "" >"$TEST_LOG_FILE"

  log_debug "Test environment initialized"
}

# ── Утилиты тестирования / Test Utilities ───────────────────────────────────

# Вывод результата теста
test_result() {
  local test_name="$1"
  local result="$2"
  local message="${3:-}"

  TESTS_TOTAL=$((TESTS_TOTAL + 1))

  case "$result" in
  pass)
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "[PASS] $test_name" | tee -a "$TEST_LOG_FILE"
    ;;
  fail)
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "[FAIL] $test_name" | tee -a "$TEST_LOG_FILE"
    if [[ -n "$message" ]]; then
      echo "       $message" | tee -a "$TEST_LOG_FILE"
    fi
    ;;
  skip)
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    echo "[SKIP] $test_name: $message" | tee -a "$TEST_LOG_FILE"
    ;;
  esac
}

# ── Тесты Core модулей / Core Module Tests ──────────────────────────────────

# Тест: Core модули доступны
test_core_modules_available() {
  local test_name="Core modules availability"

  if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]] &&
    [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Core modules not found"
  fi
}

# Тест: Проверка pkg_check
test_pkg_check() {
  local test_name="pkg_check function"

  if pkg_check "bash"; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "pkg_check not working"
  fi
}

# Тест: Проверка svc_active
test_svc_active() {
  local test_name="svc_active function"

  # Проверяем несуществующий сервис
  if ! svc_active "nonexistent-service-12345"; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "svc_active not working correctly"
  fi
}

# ── Тесты Manifest / Manifest Tests ─────────────────────────────────────────

# Тест: Manifest загружается
test_manifest_loads() {
  local test_name="Manifest loading"

  if declare -f manifest_list_all >/dev/null; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Manifest not loaded"
  fi
}

# Тест: Проверка порядка модулей
test_manifest_order() {
  local test_name="Manifest order validation"

  local order
  mapfile -t order < <(manifest_get_install_order)

  if [[ ${#order[@]} -gt 0 ]]; then
    test_result "$test_name" "pass" "Found ${#order[@]} modules"
  else
    test_result "$test_name" "fail" "No modules in order"
  fi
}

# ── Тесты модулей / Module Tests ────────────────────────────────────────────

# Тест: Firewall модуль доступен
test_firewall_module() {
  local test_name="Firewall module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/firewall/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Firewall module not found"
  fi
}

# Тест: Fail2ban модуль доступен
test_fail2ban_module() {
  local test_name="Fail2ban module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/fail2ban/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Fail2ban module not found"
  fi
}

# Тест: SSL модуль доступен
test_ssl_module() {
  local test_name="SSL module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/ssl/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "SSL module not found"
  fi
}

# Тест: Singbox модуль доступен
test_singbox_module() {
  local test_name="Singbox module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/singbox/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Singbox module not found"
  fi
}

# Тест: System модуль доступен
test_system_module() {
  local test_name="System module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/system/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "System module not found"
  fi
}

# Тест: Backup модуль доступен
test_backup_module() {
  local test_name="Backup module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/backup/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Backup module not found"
  fi
}

# Тест: Rollback модуль доступен
test_rollback_module() {
  local test_name="Rollback module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/rollback/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Rollback module not found"
  fi
}

# Тест: Monitoring модуль доступен
test_monitoring_module() {
  local test_name="Monitoring module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/monitoring/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Monitoring module not found"
  fi
}

# ── Тесты Step функций / Step Functions Tests ───────────────────────────────

# Тест: Step файлы доступны
test_step_files_available() {
  local test_name="Step files availability"

  local steps_dir="${SCRIPT_DIR}/lib/steps"

  if [[ -d "$steps_dir" ]]; then
    local step_count
    step_count=$(ls "$steps_dir"/*.sh 2>/dev/null | wc -l)

    test_result "$test_name" "pass" "Found $step_count step files"
  else
    test_result "$test_name" "fail" "Steps directory not found"
  fi
}

# ── Тесты утилит / Utility Tests ────────────────────────────────────────────

# Тест: Utils.sh доступен
test_utils_available() {
  local test_name="Utils.sh availability"

  if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Utils.sh not found"
  fi
}

# Тест: Validation.sh доступен
test_validation_available() {
  local test_name="Validation.sh availability"

  if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Validation.sh not found"
  fi
}

# Тест: Security.sh доступен
test_security_available() {
  local test_name="Security.sh availability"

  if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Security.sh not found"
  fi
}

# Тест: bootstrap setup_remote_install + ensure_file fallback
test_bootstrap_setup_remote_install_fallback() {
  local test_name="Bootstrap curl installer fallback"

  if [[ ! -f "${SCRIPT_DIR}/lib/core/installer/bootstrap.sh" ]]; then
    test_result "$test_name" "fail" "bootstrap.sh not found"
    return
  fi

  # Загружаем bootstrap, чтобы доступны функции
  source "${SCRIPT_DIR}/lib/core/installer/bootstrap.sh"

  local saved_install_dir="${INSTALL_SCRIPT_DIR:-}"
  local get_str_def=""

  INSTALL_SCRIPT_DIR="" # Состояние curl installer

  # Отключаем wget/curl через перехват CLI-вызыва "command -v"
  command() {
    if [[ "$1" == "-v" && ("$2" == "wget" || "$2" == "curl") ]]; then
      return 1
    fi
    builtin command "$@"
  }

  if declare -f get_str >/dev/null 2>&1; then
    get_str_def="$(declare -f get_str)"
    unset -f get_str
  fi

  # Проверяем fallback поведение
  if setup_remote_install; then
    test_result "$test_name" "fail" "setup_remote_install должен завершаться ошибкой при отсутствии wget/curl"
  else
    test_result "$test_name" "pass"
  fi

  # Проверка ensure_file fallback без get_str
  mkdir -p /tmp/cubiveil-test-integration || true
  if ensure_file "nonexistent-file.txt" "/tmp/cubiveil-test-integration"; then
    test_result "$test_name" "fail" "ensure_file должен вернуть ошибку для несуществующего URL"
  else
    test_result "$test_name" "pass"
  fi

  # Восстановление окружения
  INSTALL_SCRIPT_DIR="$saved_install_dir"
  if [[ -n "$get_str_def" ]]; then
    eval "$get_str_def"
  fi
  unset -f command

}

# ── Запуск всех тестов / Run All Tests ──────────────────────────────────────

# Запуск всех тестов
test_run_all() {
  log_step "test_run_all" "Running all tests"

  echo ""
  echo "════════════════════════════════════════════════════════"
  echo "  CubiVeil Test Suite"
  echo "════════════════════════════════════════════════════════"
  echo ""

  # Core модули
  test_core_modules_available
  test_pkg_check
  test_svc_active

  # Manifest
  test_manifest_loads
  test_manifest_order

  # Модули
  test_firewall_module
  test_fail2ban_module
  test_ssl_module
  test_singbox_module
  test_system_module
  test_backup_module
  test_rollback_module
  test_monitoring_module

  # Step функции
  test_step_files_available

  # Утилиты
  test_utils_available
  test_validation_available
  test_security_available

  # Bootstrap curl installer fallback
  test_bootstrap_setup_remote_install_fallback

  echo ""
  echo "════════════════════════════════════════════════════════"
  echo ""
}

# Отчёт о тестах
test_report() {
  echo "════════════════════════════════════════════════════════"
  echo "  Test Results"
  echo "════════════════════════════════════════════════════════"
  echo ""
  echo "  Total:   $TESTS_TOTAL"
  echo "  Passed:  $TESTS_PASSED"
  echo "  Failed:  $TESTS_FAILED"
  echo "  Skipped: $TESTS_SKIPPED"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "  Status: ✓ ALL TESTS PASSED"
    echo ""
    return 0
  else
    echo "  Status: ✗ SOME TESTS FAILED"
    echo ""
    echo "  Log file: $TEST_LOG_FILE"
    echo ""
    return 1
  fi
}

# Быстрый тест (только критичные)
test_run_quick() {
  log_step "test_run_quick" "Running quick tests"

  test_core_modules_available
  test_manifest_loads
  test_system_module
}

# ── Модульный интерфейс / Module Interface ──────────────────────────────────

# Стандартный интерфейс модуля
module_install() { :; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }

# Запуск всех тестов
module_test_all() {
  test_init
  test_run_all
  test_report
}

# Запуск быстрых тестов
module_test_quick() {
  test_init
  test_run_quick
  test_report
}

# Запуск только определённого теста
module_test_one() {
  local test_func="$1"

  test_init

  if declare -f "$test_func" >/dev/null; then
    $test_func
  else
    log_error "Test function not found: $test_func"
  fi

  test_report
}

# Автоматический запуск модуля, если скрипт вызван напрямую.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  module_test_all
fi
