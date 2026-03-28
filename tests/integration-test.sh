#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘          CubiVeil вЂ” Test Suite                            в•‘
# в•‘          github.com/cubiculus/cubiveil                    в•‘
# в•‘                                                           в•‘
# в•‘  РљРѕРјРїР»РµРєСЃРЅРѕРµ С‚РµСЃС‚РёСЂРѕРІР°РЅРёРµ РІСЃРµС… РјРѕРґСѓР»РµР№                    в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ / Dependencies в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# РџРѕРґРєР»СЋС‡Р°РµРј core РјРѕРґСѓР»Рё
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# РџРѕРґРєР»СЋС‡Р°РµРј manifest
if [[ -f "${SCRIPT_DIR}/lib/manifest.sh" ]]; then
  source "${SCRIPT_DIR}/lib/manifest.sh"
fi

# в”Ђв”Ђ РљРѕРЅС„РёРіСѓСЂР°С†РёСЏ С‚РµСЃС‚РёСЂРѕРІР°РЅРёСЏ / Test Configuration в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

TEST_RESULTS_DIR="/tmp/cubiveil-test-results"
TEST_LOG_FILE="${TEST_RESULTS_DIR}/test.log"

# РЎС‡С‘С‚С‡РёРєРё С‚РµСЃС‚РѕРІ
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# в”Ђв”Ђ РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ / Initialization в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ С‚РµСЃС‚РѕРІРѕР№ СЃСЂРµРґС‹
test_init() {
  log_step "test_init" "Initializing test environment"

  dir_ensure "$TEST_RESULTS_DIR"

  # РћС‡РёС‰Р°РµРј Р»РѕРі-С„Р°Р№Р»
  echo "" >"$TEST_LOG_FILE"

  log_debug "Test environment initialized"
}

# в”Ђв”Ђ РЈС‚РёР»РёС‚С‹ С‚РµСЃС‚РёСЂРѕРІР°РЅРёСЏ / Test Utilities в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# Р’С‹РІРѕРґ СЂРµР·СѓР»СЊС‚Р°С‚Р° С‚РµСЃС‚Р°
test_result() {
  local test_name="$1"
  local result="$2"
  local message="${3:-}"

  ((TESTS_TOTAL++))

  case "$result" in
  pass)
    ((TESTS_PASSED++)) || true
    echo "[PASS] $test_name" | tee -a "$TEST_LOG_FILE"
    ;;
  fail)
    ((TESTS_FAILED++)) || true
    echo "[FAIL] $test_name" | tee -a "$TEST_LOG_FILE"
    if [[ -n "$message" ]]; then
      echo "       $message" | tee -a "$TEST_LOG_FILE"
    fi
    ;;
  skip)
    ((TESTS_SKIPPED++))
    echo "[SKIP] $test_name: $message" | tee -a "$TEST_LOG_FILE"
    ;;
  esac
}

# в”Ђв”Ђ РўРµСЃС‚С‹ Core РјРѕРґСѓР»РµР№ / Core Module Tests в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# РўРµСЃС‚: Core РјРѕРґСѓР»Рё РґРѕСЃС‚СѓРїРЅС‹
test_core_modules_available() {
  local test_name="Core modules availability"

  if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]] &&
    [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Core modules not found"
  fi
}

# РўРµСЃС‚: РџСЂРѕРІРµСЂРєР° pkg_check
test_pkg_check() {
  local test_name="pkg_check function"

  if pkg_check "bash"; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "pkg_check not working"
  fi
}

# РўРµСЃС‚: РџСЂРѕРІРµСЂРєР° svc_active
test_svc_active() {
  local test_name="svc_active function"

  # РџСЂРѕРІРµСЂСЏРµРј РЅРµСЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ СЃРµСЂРІРёСЃ
  if ! svc_active "nonexistent-service-12345"; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "svc_active not working correctly"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚С‹ Manifest / Manifest Tests в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# РўРµСЃС‚: Manifest Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ
test_manifest_loads() {
  local test_name="Manifest loading"

  if declare -f manifest_list_all >/dev/null; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Manifest not loaded"
  fi
}

# РўРµСЃС‚: РџСЂРѕРІРµСЂРєР° РїРѕСЂСЏРґРєР° РјРѕРґСѓР»РµР№
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

# в”Ђв”Ђ РўРµСЃС‚С‹ РјРѕРґСѓР»РµР№ / Module Tests в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# РўРµСЃС‚: Firewall РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_firewall_module() {
  local test_name="Firewall module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/firewall/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Firewall module not found"
  fi
}

# РўРµСЃС‚: Fail2ban РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_fail2ban_module() {
  local test_name="Fail2ban module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/fail2ban/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Fail2ban module not found"
  fi
}

# РўРµСЃС‚: SSL РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_ssl_module() {
  local test_name="SSL module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/ssl/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "SSL module not found"
  fi
}

# РўРµСЃС‚: Singbox РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_singbox_module() {
  local test_name="Singbox module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/singbox/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Singbox module not found"
  fi
}

# РўРµСЃС‚: Marzban РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_marzban_module() {
  local test_name="Marzban module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/marzban/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Marzban module not found"
  fi
}

# РўРµСЃС‚: System РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_system_module() {
  local test_name="System module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/system/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "System module not found"
  fi
}

# РўРµСЃС‚: Backup РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_backup_module() {
  local test_name="Backup module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/backup/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Backup module not found"
  fi
}

# РўРµСЃС‚: Rollback РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_rollback_module() {
  local test_name="Rollback module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/rollback/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Rollback module not found"
  fi
}

# РўРµСЃС‚: Monitoring РјРѕРґСѓР»СЊ РґРѕСЃС‚СѓРїРµРЅ
test_monitoring_module() {
  local test_name="Monitoring module availability"

  local module_file="${SCRIPT_DIR}/lib/modules/monitoring/install.sh"

  if [[ -f "$module_file" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Monitoring module not found"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚С‹ Step С„СѓРЅРєС†РёР№ / Step Functions Tests в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# РўРµСЃС‚: Step С„Р°Р№Р»С‹ РґРѕСЃС‚СѓРїРЅС‹
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

# в”Ђв”Ђ РўРµСЃС‚С‹ СѓС‚РёР»РёС‚ / Utility Tests в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# РўРµСЃС‚: Utils.sh РґРѕСЃС‚СѓРїРµРЅ
test_utils_available() {
  local test_name="Utils.sh availability"

  if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Utils.sh not found"
  fi
}

# РўРµСЃС‚: Validation.sh РґРѕСЃС‚СѓРїРµРЅ
test_validation_available() {
  local test_name="Validation.sh availability"

  if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Validation.sh not found"
  fi
}

# РўРµСЃС‚: Security.sh РґРѕСЃС‚СѓРїРµРЅ
test_security_available() {
  local test_name="Security.sh availability"

  if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
    test_result "$test_name" "pass"
  else
    test_result "$test_name" "fail" "Security.sh not found"
  fi
}

# в”Ђв”Ђ Р—Р°РїСѓСЃРє РІСЃРµС… С‚РµСЃС‚РѕРІ / Run All Tests в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# Р—Р°РїСѓСЃРє РІСЃРµС… С‚РµСЃС‚РѕРІ
test_run_all() {
  log_step "test_run_all" "Running all tests"

  echo ""
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo "  CubiVeil Test Suite"
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo ""

  # Core РјРѕРґСѓР»Рё
  test_core_modules_available
  test_pkg_check
  test_svc_active

  # Manifest
  test_manifest_loads
  test_manifest_order

  # РњРѕРґСѓР»Рё
  test_firewall_module
  test_fail2ban_module
  test_ssl_module
  test_singbox_module
  test_marzban_module
  test_system_module
  test_backup_module
  test_rollback_module
  test_monitoring_module

  # Step С„СѓРЅРєС†РёРё
  test_step_files_available

  # РЈС‚РёР»РёС‚С‹
  test_utils_available
  test_validation_available
  test_security_available

  echo ""
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo ""
}

# РћС‚С‡С‘С‚ Рѕ С‚РµСЃС‚Р°С…
test_report() {
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo "  Test Results"
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo ""
  echo "  Total:   $TESTS_TOTAL"
  echo "  Passed:  $TESTS_PASSED"
  echo "  Failed:  $TESTS_FAILED"
  echo "  Skipped: $TESTS_SKIPPED"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "  Status: вњ“ ALL TESTS PASSED"
    echo ""
    return 0
  else
    echo "  Status: вњ— SOME TESTS FAILED"
    echo ""
    echo "  Log file: $TEST_LOG_FILE"
    echo ""
    return 1
  fi
}

# Р‘С‹СЃС‚СЂС‹Р№ С‚РµСЃС‚ (С‚РѕР»СЊРєРѕ РєСЂРёС‚РёС‡РЅС‹Рµ)
test_run_quick() {
  log_step "test_run_quick" "Running quick tests"

  test_core_modules_available
  test_manifest_loads
  test_system_module
  test_marzban_module
}

# в”Ђв”Ђ РњРѕРґСѓР»СЊРЅС‹Р№ РёРЅС‚РµСЂС„РµР№СЃ / Module Interface в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

# РЎС‚Р°РЅРґР°СЂС‚РЅС‹Р№ РёРЅС‚РµСЂС„РµР№СЃ РјРѕРґСѓР»СЏ
module_install() { :; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }

# Р—Р°РїСѓСЃРє РІСЃРµС… С‚РµСЃС‚РѕРІ
module_test_all() {
  test_init
  test_run_all
  test_report
}

# Р—Р°РїСѓСЃРє Р±С‹СЃС‚СЂС‹С… С‚РµСЃС‚РѕРІ
module_test_quick() {
  test_init
  test_run_quick
  test_report
}

# Р—Р°РїСѓСЃРє С‚РѕР»СЊРєРѕ РѕРїСЂРµРґРµР»С‘РЅРЅРѕРіРѕ С‚РµСЃС‚Р°
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
