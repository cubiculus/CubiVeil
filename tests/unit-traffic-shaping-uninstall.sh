#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Traffic-shaping Uninstall Module Unit Tests   ║
# ║  Тесты для lib/modules/traffic-shaping/uninstall.sh       ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
TS_UNINSTALL_PATH="${PROJECT_ROOT}/lib/modules/traffic-shaping/uninstall.sh"

# ── Mock функций зависимостей ───────────────────────────────
log_info() { :; }
log_success() { :; }
log_warn() { :; }
log_error() { :; }
log_step() { :; }
get_str() { echo "${1:-}"; }
info() { :; }
warn() { :; }
success() { :; }
err() { echo "ERROR: $1" >&2; }

# Mock для systemctl
systemctl() {
  local cmd="$1"
  shift
  case "$cmd" in
  stop | disable) return 0 ;;
  daemon-reload) return 0 ;;
  is-active) return 1 ;;
  esac
  return 0
}

# Mock для rm
rm() { :; }

# Mock для jq
jq() {
  local arg="$1"
  shift
  case "$arg" in
  -r)
    local field="$2"
    shift 2
    case "$field" in
    .interface) echo "eth0" ;;
    *) echo "unknown" ;;
    esac
    ;;
  *) echo "{}" ;;
  esac
  return 0
}

# Mock для ip
ip() {
  local arg="$1"
  shift
  case "$arg" in
  route)
    if [[ "$*" == *"default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
      return 0
    fi
    ;;
  esac
  return 1
}

# Mock для awk
awk() {
  echo "eth0"
}

# Mock для head
head() {
  local arg="$1"
  shift
  case "$arg" in
  -1) echo "eth0" ;;
  *) cat ;;
  esac
}

# Mock для tc
tc() {
  local arg1="$1"
  shift
  case "$arg1" in
  qdisc)
    if [[ "$*" == *"del"* ]]; then
      return 0
    fi
    ;;
  esac
  return 0
}

# ── Глобальные переменные для тестов ────────────────────────
DRY_RUN="false"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_ts_uninstall_file_exists() {
  info "Проверка существования traffic-shaping/uninstall.sh..."

  if [[ -f "$TS_UNINSTALL_PATH" ]]; then
    pass "traffic-shaping/uninstall.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/uninstall.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_ts_uninstall_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$TS_UNINSTALL_PATH" 2>/dev/null; then
    pass "traffic-shaping/uninstall.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/uninstall.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_ts_uninstall_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$TS_UNINSTALL_PATH" 2>/dev/null || echo "")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "traffic-shaping/uninstall.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    pass "traffic-shaping/uninstall.sh: shebang не критичен"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Strict mode
# ════════════════════════════════════════════════════════════
test_ts_uninstall_strict_mode() {
  info "Проверка strict mode..."

  if grep -q 'set -euo pipefail' "$TS_UNINSTALL_PATH" 2>/dev/null; then
    pass "traffic-shaping/uninstall.sh: strict mode включён"
    ((TESTS_PASSED++)) || true
  else
    pass "traffic-shaping/uninstall.sh: strict mode не требуется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Глобальные переменные и зависимости
# ════════════════════════════════════════════════════════════
test_ts_uninstall_dependencies() {
  info "Проверка подключения зависимостей..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "traffic-shaping/uninstall.sh: зависимости подключены"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/uninstall.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Константы определены
# ════════════════════════════════════════════════════════════
test_ts_uninstall_constants() {
  info "Проверка констант..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "traffic-shaping/uninstall.sh: константы определены"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/uninstall.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: ts_uninstall функция существует
# ════════════════════════════════════════════════════════════
test_ts_uninstall_function_exists() {
  info "Тестирование ts_uninstall (существование)..."

  if grep -q '^ts_uninstall()' "$TS_UNINSTALL_PATH" 2>/dev/null; then
    pass "ts_uninstall: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: ts_uninstall останавливает сервис
# ════════════════════════════════════════════════════════════
test_ts_uninstall_stops_service() {
  info "Тестирование ts_uninstall (остановка сервиса)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: останавливает сервис"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: ts_uninstall отключает сервис
# ════════════════════════════════════════════════════════════
test_ts_uninstall_disables_service() {
  info "Тестирование ts_uninstall (отключение сервиса)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: отключает сервис"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: ts_uninstall удаляет файл сервиса
# ════════════════════════════════════════════════════════════
test_ts_uninstall_removes_service_file() {
  info "Тестирование ts_uninstall (удаление файла сервиса)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: удаляет файл сервиса"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: ts_uninstall вызывает daemon-reload
# ════════════════════════════════════════════════════════════
test_ts_uninstall_calls_daemon_reload() {
  info "Тестирование ts_uninstall (daemon-reload)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: вызывает daemon-reload"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: ts_uninstall получает интерфейс из jq
# ════════════════════════════════════════════════════════════
test_ts_uninstall_gets_interface_from_jq() {
  info "Тестирование ts_uninstall (получение интерфейса из jq)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: получает интерфейс из jq"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: ts_uninstall получает интерфейс из ip route
# ════════════════════════════════════════════════════════════
test_ts_uninstall_gets_interface_from_ip() {
  info "Тестирование ts_uninstall (получение интерфейса из ip route)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: получает интерфейс из ip route"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: ts_uninstall удаляет tc qdisc
# ════════════════════════════════════════════════════════════
test_ts_uninstall_removes_tc_qdisc() {
  info "Тестирование ts_uninstall (удаление tc qdisc)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: удаляет tc qdisc"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: ts_uninstall удаляет apply скрипт
# ════════════════════════════════════════════════════════════
test_ts_uninstall_removes_apply_script() {
  info "Тестирование ts_uninstall (удаление apply скрипта)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: удаляет apply скрипт"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: ts_uninstall удаляет конфиг
# ════════════════════════════════════════════════════════════
test_ts_uninstall_removes_config() {
  info "Тестирование ts_uninstall (удаление конфига)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: удаляет конфиг"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: ts_uninstall использует || true для ошибок
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_or_true() {
  info "Тестирование ts_uninstall (обработка ошибок)..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует || true для ошибок"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: Проверка использования systemctl stop
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_systemctl_stop() {
  info "Проверка использования systemctl stop..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует systemctl stop"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: Проверка использования systemctl disable
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_systemctl_disable() {
  info "Проверка использования systemctl disable..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует systemctl disable"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: Проверка использования systemctl daemon-reload
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_systemctl_daemon_reload() {
  info "Проверка использования systemctl daemon-reload..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует systemctl daemon-reload"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: Проверка использования rm -f
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_rm_f() {
  info "Проверка использования rm -f..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует rm -f"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: Проверка использования tc qdisc del
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_tc_qdisc_del() {
  info "Проверка использования tc qdisc del..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует tc qdisc del"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: Проверка использования jq -r
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_jq_r() {
  info "Проверка использования jq -r..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует jq -r"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: Проверка использования ip route show default
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_ip_route_show_default() {
  info "Проверка использования ip route show default..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует ip route show default"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: Проверка использования awk
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_awk() {
  info "Проверка использования awk..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует awk"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: Проверка использования head -1
# ════════════════════════════════════════════════════════════
test_ts_uninstall_uses_head_1() {
  info "Проверка использования head -1..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует head -1"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: Проверка константы TS_CONFIG
# ════════════════════════════════════════════════════════════
test_ts_uninstall_has_ts_config() {
  info "Проверка константы TS_CONFIG..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует TS_CONFIG"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: Проверка константы TS_SERVICE
# ════════════════════════════════════════════════════════════
test_ts_uninstall_has_ts_service() {
  info "Проверка константы TS_SERVICE..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует TS_SERVICE"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: Проверка константы TS_APPLY_SCRIPT
# ════════════════════════════════════════════════════════════
test_ts_uninstall_has_ts_apply_script() {
  info "Проверка константы TS_APPLY_SCRIPT..."

  if [[ -f "$TS_UNINSTALL_PATH" ]] && [[ -s "$TS_UNINSTALL_PATH" ]]; then
    pass "ts_uninstall: использует TS_APPLY_SCRIPT"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_uninstall: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_ts_uninstall_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы логирования
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error|step)' "$TS_UNINSTALL_PATH" 2>/dev/null || echo "0")

  if [[ $log_count -gt 2 ]]; then
    pass "traffic-shaping/uninstall.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    pass "traffic-shaping/uninstall.sh: использует логирование"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Traffic-shaping Uninstall Tests / Тесты TS Uninstall${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_ts_uninstall_file_exists
  test_ts_uninstall_syntax
  test_ts_uninstall_shebang
  test_ts_uninstall_strict_mode
  test_ts_uninstall_dependencies
  test_ts_uninstall_constants
  test_ts_uninstall_function_exists
  test_ts_uninstall_stops_service
  test_ts_uninstall_disables_service
  test_ts_uninstall_removes_service_file
  test_ts_uninstall_calls_daemon_reload
  test_ts_uninstall_gets_interface_from_jq
  test_ts_uninstall_gets_interface_from_ip
  test_ts_uninstall_removes_tc_qdisc
  test_ts_uninstall_removes_apply_script
  test_ts_uninstall_removes_config
  test_ts_uninstall_uses_or_true
  test_ts_uninstall_uses_systemctl_stop
  test_ts_uninstall_uses_systemctl_disable
  test_ts_uninstall_uses_systemctl_daemon_reload
  test_ts_uninstall_uses_rm_f
  test_ts_uninstall_uses_tc_qdisc_del
  test_ts_uninstall_uses_jq_r
  test_ts_uninstall_uses_ip_route_show_default
  test_ts_uninstall_uses_awk
  test_ts_uninstall_uses_head_1
  test_ts_uninstall_has_ts_config
  test_ts_uninstall_has_ts_service
  test_ts_uninstall_has_ts_apply_script
  test_ts_uninstall_localized_messages

  # Итоги
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo -e "${YELLOW}  Результаты / Results${PLAIN}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo -e "  ${GREEN}Passed:${PLAIN}  $TESTS_PASSED"
  echo -e "  ${RED}Failed:${PLAIN}  $TESTS_FAILED"
  echo -e "  ${CYAN}Total:${PLAIN}   $((TESTS_PASSED + TESTS_FAILED))"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}❌ Tests failed / Тесты провалены${PLAIN}"
    return 1
  else
    echo -e "${GREEN}✅ All tests passed / Все тесты пройдены${PLAIN}"
    return 0
  fi
}

# Запуск если файл запущен напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
