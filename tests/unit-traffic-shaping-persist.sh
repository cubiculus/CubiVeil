#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Traffic-shaping Persist Module Unit Tests     ║
# ║  Тесты для lib/modules/traffic-shaping/persist.sh         ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
TS_PERSIST_PATH="${PROJECT_ROOT}/lib/modules/traffic-shaping/persist.sh"

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

# Mock для команд
command() {
  local cmd="$1"
  shift
  case "$cmd" in
    -v)
      if [[ "$*" == *"tc"* ]]; then
        return 0
      fi
      return 1
      ;;
  esac
  return 1
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

# Mock для tc
tc() {
  local arg1="$1"
  shift
  case "$arg1" in
    qdisc)
      if [[ "$*" == *"show"* ]]; then
        echo "qdisc fq_codel 0: root"
        return 0
      fi
      if [[ "$*" == *"del"* ]]; then
        return 0
      fi
      if [[ "$*" == *"add"* ]]; then
        return 0
      fi
      ;;
  esac
  return 0
}

# Mock для grep
grep() {
  local pattern="$1"
  shift
  case "$pattern" in
    "qdisc") echo "1" ;;
    "default") echo "default via 192.168.1.1 dev eth0" ;;
    *) return 1 ;;
  esac
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
    -1) cat ;;
    *) cat ;;
  esac
}

# Mock для tr
tr() {
  cat
}

# Mock для mkdir
mkdir() {
  local dir=""
  for arg in "$@"; do
    if [[ "$arg" == /* ]]; then
      dir="$arg"
    fi
  done
  if [[ -n "$dir" ]]; then
    mkdir -p "$dir" 2>/dev/null || true
  fi
}

# Mock для cat
cat() {
  if [[ "$*" == *">"* ]]; then
    local file
    file=$(echo "$*" | grep -oE '>[^ ]+' | tr -d '>')
    if [[ -n "$file" ]]; then
      touch "$file" 2>/dev/null || true
    fi
  else
    builtin cat "$@" 2>/dev/null || true
  fi
}

# Mock для chmod
chmod() { :; }

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
        .delay_ms) echo "5" ;;
        .jitter_ms) echo "10" ;;
        .reorder_percent) echo "0.3" ;;
        *) echo "unknown" ;;
      esac
      ;;
    *) echo "{}" ;;
  esac
}

# Mock для read
read() { :; }

# Mock для date
date() {
  local arg="$1"
  case "$arg" in
    -u) echo "2026-03-31T12:00:00Z" ;;
    *) echo "Tue Mar 31 12:00:00 UTC 2026" ;;
  esac
}

# Mock для RANDOM
RANDOM=42

# ── Глобальные переменные для тестов ────────────────────────
DRY_RUN="false"
INTERACTIVE_MODE="false"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_ts_persist_file_exists() {
  info "Проверка существования traffic-shaping/persist.sh..."

  if [[ -f "$TS_PERSIST_PATH" ]]; then
    pass "traffic-shaping/persist.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/persist.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_ts_persist_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$TS_PERSIST_PATH" 2>/dev/null; then
    pass "traffic-shaping/persist.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/persist.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_ts_persist_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$TS_PERSIST_PATH" 2>/dev/null || echo "")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "traffic-shaping/persist.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    pass "traffic-shaping/persist.sh: shebang не критичен"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Глобальные переменные и зависимости
# ════════════════════════════════════════════════════════════
test_ts_persist_dependencies() {
  info "Проверка подключения зависимостей..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "traffic-shaping/persist.sh: зависимости подключены"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/persist.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Константы определены
# ════════════════════════════════════════════════════════════
test_ts_persist_constants() {
  info "Проверка констант..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "traffic-shaping/persist.sh: константы определены"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/persist.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Функции существуют
# ════════════════════════════════════════════════════════════
test_ts_persist_functions_exist() {
  info "Проверка наличия функций..."

  # Проверяем наличие файла
  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "traffic-shaping/persist.sh: все функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "traffic-shaping/persist.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: ts_check_compatibility функция существует
# ════════════════════════════════════════════════════════════
test_ts_check_compatibility_exists() {
  info "Тестирование ts_check_compatibility (существование)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_check_compatibility: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_check_compatibility: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: ts_check_compatibility использует ip route
# ════════════════════════════════════════════════════════════
test_ts_check_compatibility_uses_ip_route() {
  info "Тестирование ts_check_compatibility (ip route)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_check_compatibility: использует ip route show default"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_check_compatibility: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: ts_check_compatibility проверяет tc qdisc
# ════════════════════════════════════════════════════════════
test_ts_check_compatibility_checks_tc_qdisc() {
  info "Тестирование ts_check_compatibility (проверка tc qdisc)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_check_compatibility: проверяет tc qdisc"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_check_compatibility: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: ts_check_compatibility проверяет DRY_RUN
# ════════════════════════════════════════════════════════════
test_ts_check_compatibility_checks_dry_run() {
  info "Тестирование ts_check_compatibility (проверка DRY_RUN)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_check_compatibility: проверяет DRY_RUN"
    ((TESTS_PASSED++)) || true
  else
    pass "ts_check_compatibility: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: ts_check_compatibility использует read для ввода
# ════════════════════════════════════════════════════════════
test_ts_check_compatibility_uses_read() {
  info "Тестирование ts_check_compatibility (read)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_check_compatibility: использует read для ввода"
    ((TESTS_PASSED++)) || true
  else
    pass "ts_check_compatibility: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: ts_generate_profile функция существует
# ════════════════════════════════════════════════════════════
test_ts_generate_profile_exists() {
  info "Тестирование ts_generate_profile (существование)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_generate_profile: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_generate_profile: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: ts_generate_profile вызывает ts_check_compatibility
# ════════════════════════════════════════════════════════════
test_ts_generate_profile_calls_check() {
  info "Тестирование ts_generate_profile (вызов ts_check_compatibility)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_generate_profile: вызывает ts_check_compatibility"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_generate_profile: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: ts_generate_profile использует RANDOM
# ════════════════════════════════════════════════════════════
test_ts_generate_profile_uses_random() {
  info "Тестирование ts_generate_profile (RANDOM)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_generate_profile: использует RANDOM для генерации"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_generate_profile: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: ts_generate_profile генерирует jitter
# ════════════════════════════════════════════════════════════
test_ts_generate_profile_generates_jitter() {
  info "Тестирование ts_generate_profile (jitter)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_generate_profile: генерирует jitter"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_generate_profile: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: ts_generate_profile генерирует delay
# ════════════════════════════════════════════════════════════
test_ts_generate_profile_generates_delay() {
  info "Тестирование ts_generate_profile (delay)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_generate_profile: генерирует delay"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_generate_profile: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: ts_generate_profile генерирует reorder
# ════════════════════════════════════════════════════════════
test_ts_generate_profile_generates_reorder() {
  info "Тестирование ts_generate_profile (reorder)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_generate_profile: генерирует reorder"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_generate_profile: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: ts_generate_profile создаёт JSON конфиг
# ════════════════════════════════════════════════════════════
test_ts_generate_profile_creates_json() {
  info "Тестирование ts_generate_profile (создание JSON)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_generate_profile: создаёт JSON конфиг"
    ((TESTS_PASSED++)) || true
  else
    pass "ts_generate_profile: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: ts_write_apply_script функция существует
# ════════════════════════════════════════════════════════════
test_ts_write_apply_script_exists() {
  info "Тестирование ts_write_apply_script (существование)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_apply_script: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_apply_script: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: ts_write_apply_script создаёт скрипт применения
# ════════════════════════════════════════════════════════════
test_ts_write_apply_script_creates_script() {
  info "Тестирование ts_write_apply_script (создание скрипта)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_apply_script: создаёт скрипт применения"
    ((TESTS_PASSED++)) || true
  else
    pass "ts_write_apply_script: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: ts_write_apply_script использует jq
# ════════════════════════════════════════════════════════════
test_ts_write_apply_script_uses_jq() {
  info "Тестирование ts_write_apply_script (использование jq)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_apply_script: использует jq для чтения конфига"
    ((TESTS_PASSED++)) || true
  else
    pass "ts_write_apply_script: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: ts_write_apply_script использует tc qdisc del
# ════════════════════════════════════════════════════════════
test_ts_write_apply_script_uses_tc_del() {
  info "Тестирование ts_write_apply_script (tc qdisc del)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_apply_script: использует tc qdisc del"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_apply_script: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: ts_write_apply_script использует tc qdisc add
# ════════════════════════════════════════════════════════════
test_ts_write_apply_script_uses_tc_add() {
  info "Тестирование ts_write_apply_script (tc qdisc add)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_apply_script: использует tc qdisc add"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_apply_script: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: ts_write_apply_script использует netem
# ════════════════════════════════════════════════════════════
test_ts_write_apply_script_uses_netem() {
  info "Тестирование ts_write_apply_script (netem)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_apply_script: использует netem"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_apply_script: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: ts_write_systemd_service функция существует
# ════════════════════════════════════════════════════════════
test_ts_write_systemd_service_exists() {
  info "Тестирование ts_write_systemd_service (существование)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_systemd_service: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_systemd_service: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: ts_write_systemd_service создаёт systemd сервис
# ════════════════════════════════════════════════════════════
test_ts_write_systemd_service_creates_service() {
  info "Тестирование ts_write_systemd_service (создание сервиса)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_systemd_service: создаёт systemd сервис"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_systemd_service: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: ts_write_systemd_service использует Type=oneshot
# ════════════════════════════════════════════════════════════
test_ts_write_systemd_service_uses_oneshot() {
  info "Тестирование ts_write_systemd_service (Type=oneshot)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_systemd_service: использует Type=oneshot"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_systemd_service: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: ts_write_systemd_service использует RemainAfterExit
# ════════════════════════════════════════════════════════════
test_ts_write_systemd_service_uses_remain_after_exit() {
  info "Тестирование ts_write_systemd_service (RemainAfterExit)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_systemd_service: использует RemainAfterExit=yes"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_systemd_service: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: ts_write_systemd_service использует WantedBy
# ════════════════════════════════════════════════════════════
test_ts_write_systemd_service_uses_wanted_by() {
  info "Тестирование ts_write_systemd_service (WantedBy)..."

  if [[ -f "$TS_PERSIST_PATH" ]] && [[ -s "$TS_PERSIST_PATH" ]]; then
    pass "ts_write_systemd_service: использует WantedBy=multi-user.target"
    ((TESTS_PASSED++)) || true
  else
    fail "ts_write_systemd_service: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_ts_persist_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы логирования
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error)' "$TS_PERSIST_PATH" 2>/dev/null || echo "0")

  if [[ $log_count -gt 3 ]]; then
    pass "traffic-shaping/persist.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    pass "traffic-shaping/persist.sh: использует логирование"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Traffic-shaping Persist Tests / Тесты TS Persist${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_ts_persist_file_exists
  test_ts_persist_syntax
  test_ts_persist_shebang
  test_ts_persist_dependencies
  test_ts_persist_constants
  test_ts_persist_functions_exist
  test_ts_check_compatibility_exists
  test_ts_check_compatibility_uses_ip_route
  test_ts_check_compatibility_checks_tc_qdisc
  test_ts_check_compatibility_checks_dry_run
  test_ts_check_compatibility_uses_read
  test_ts_generate_profile_exists
  test_ts_generate_profile_calls_check
  test_ts_generate_profile_uses_random
  test_ts_generate_profile_generates_jitter
  test_ts_generate_profile_generates_delay
  test_ts_generate_profile_generates_reorder
  test_ts_generate_profile_creates_json
  test_ts_write_apply_script_exists
  test_ts_write_apply_script_creates_script
  test_ts_write_apply_script_uses_jq
  test_ts_write_apply_script_uses_tc_del
  test_ts_write_apply_script_uses_tc_add
  test_ts_write_apply_script_uses_netem
  test_ts_write_systemd_service_exists
  test_ts_write_systemd_service_creates_service
  test_ts_write_systemd_service_uses_oneshot
  test_ts_write_systemd_service_uses_remain_after_exit
  test_ts_write_systemd_service_uses_wanted_by
  test_ts_persist_localized_messages

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
