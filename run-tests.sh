#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Test Runner                               ║
# ║        Запуск всех тестов                                 ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение унифицированных функций вывода ───────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/output.sh" || {
  echo "❌ Не удалось загрузить lib/output.sh" >&2
  exit 1
}

# ── Переменные ───────────────────────────────────────────────────
TESTS_DIR="$SCRIPT_DIR/tests"

TOTAL_PASSED=0
TOTAL_FAILED=0

# ── Подключение тестовых утилит ───────────────────────────────
source "${SCRIPT_DIR}/lib/test-utils.sh"

# ── Функции ─────────────────────────────────────────────────────
print_header() {
  local raw_title="  $1"
  local width=54
  local title_len=${#raw_title}
  local padding=$((width - title_len - 2))
  local spaces=""
  for ((i = 0; i < padding; i++)); do
    spaces+=" "
  done

  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${BLUE}║${raw_title}${spaces}║${PLAIN}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""
}

print_section() {
  echo ""
  echo -e "${YELLOW}━━━ $1 ━━━${PLAIN}"
  echo ""
}

# ── Запуск unit-тестов (без root) ─────────────────────────────
run_unit_tests() {
  print_section "Unit Tests (без root)"

  local unit_tests=(
    "modular-structure.sh:Модульная структура"
    "test-install-modes.sh:install.sh режимы"
    "unit-utils.sh:lib/utils.sh"
    "unit-install-steps.sh:lib/install-steps.sh"
    "unit-lang.sh:lang.sh"
    "unit-install.sh:install.sh"
    "unit-telegram.sh:setup-telegram.sh"
    "unit-decoy-site.sh:decoy-site module"
    "unit-traffic-shaping.sh:Traffic Shaping module"
    "unit-system.sh:System module"
    "unit-backup.sh:Backup module"
    "unit-rollback.sh:Rollback module"
    "unit-monitoring.sh:Monitoring module"
    "unit-utilities.sh:Новые утилиты"
    "unit-ssl.sh:SSL module"
  )

  for test_info in "${unit_tests[@]}"; do
    local test_file="${test_info%%:*}"
    local test_name="${test_info##*:}"
    local test_path="$TESTS_DIR/$test_file"

    echo -e "${BLUE}Запуск: $test_name${PLAIN}"

    if [[ -f "$test_path" ]]; then
      if bash "$test_path"; then
        ((TOTAL_PASSED++)) || true
        echo -e "${GREEN}✓ $test_name пройден${PLAIN}"
      else
        ((TOTAL_FAILED++)) || true
        echo -e "${RED}✗ $test_name провален${PLAIN}"
      fi
    else
      echo -e "${RED}✗ $test_name не найден: $test_path${PLAIN}"
      ((TOTAL_FAILED++)) || true
    fi
    echo ""
  done
}

# ── Запуск unit-тестов через интеграционный тест ──────────────
run_unit_via_integration() {
  print_section "Unit Tests (через integration-test.sh)"

  echo -e "${BLUE}Запуск unit-тестов через integration-test.sh${PLAIN}"
  echo ""

  if bash "$TESTS_DIR/integration-test.sh" . unit; then
    ((TOTAL_PASSED++)) || true
    echo -e "${GREEN}✓ Unit тесты пройдены${PLAIN}"
  else
    ((TOTAL_FAILED++)) || true
    echo -e "${RED}✗ Unit тесты провалены${PLAIN}"
  fi
}

# ── Запуск Telegram-bot (Python) тестов ──────────────────────
run_telegram_bot_tests() {
  print_section "Telegram-bot Tests (Python)"

  local bot_tests_dir="$TESTS_DIR/telegram-bot"

  if [[ ! -f "$bot_tests_dir/run_tests.py" ]]; then
    echo -e "${YELLOW}⚠ Telegram-bot test runner не найден: $bot_tests_dir/run_tests.py${PLAIN}"
    return 0
  fi

  echo -e "${BLUE}Запуск Telegram-bot тестов...${PLAIN}"
  echo ""

  if python3 "$bot_tests_dir/run_tests.py"; then
    ((TOTAL_PASSED++)) || true
    echo -e "${GREEN}✓ Telegram-bot тесты пройдены${PLAIN}"
  else
    ((TOTAL_FAILED++)) || true
    echo -e "${RED}✗ Telegram-bot тесты провалены${PLAIN}"
  fi
}

# ── Запуск интеграционных тестов (требует root) ────────────
run_integration_tests() {
  print_section "Integration Tests (требует root)"

  # Проверка root прав
  if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}⚠ Интеграционные тесты требуют прав root${PLAIN}"
    echo -e "${YELLOW}⚠ Запустите: sudo ./run-tests.sh --full${PLAIN}"
    echo ""
    return 0
  fi

  echo -e "${BLUE}Запуск интеграционных тестов...${PLAIN}"
  echo ""

  if bash "$TESTS_DIR/integration-test.sh"; then
    ((TOTAL_PASSED++)) || true
    echo -e "${GREEN}✓ Интеграционные тесты пройдены${PLAIN}"
  else
    ((TOTAL_FAILED++)) || true
    echo -e "${RED}✗ Интеграционные тесты провалены${PLAIN}"
  fi
}

# ── Вывод справки ─────────────────────────────────────────────
show_help() {
  cat <<EOF
CubiVeil Test Runner
====================

Использование:
  ./run-tests.sh [опции]

Опции:
  --unit           Запуск только unit-тестов (без root)
  --integration    Запуск только интеграционных тестов (требует root)
  --full          Запуск всех тестов (требует root для интеграционных)
  --help, -h      Показать эту справку

Примеры:
  ./run-tests.sh                    # Запуск unit-тестов
  sudo ./run-tests.sh --full       # Запуск всех тестов
  sudo ./run-tests.sh --integration # Только интеграционные тесты

EOF
}

# ── Основная функция ─────────────────────────────────────────────
main() {
  local mode="unit"

  # Обработка аргументов
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --unit)
      mode="unit"
      shift
      ;;
    --integration)
      mode="integration"
      shift
      ;;
    --full)
      mode="full"
      shift
      ;;
    --help | -h)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Неизвестная опция: $1${PLAIN}"
      echo ""
      show_help
      exit 1
      ;;
    esac
  done

  print_header "CubiVeil Test Runner"

  # Инициализация счётчиков тестов
  init_test_counters

  # Запуск тестов в зависимости от режима
  case "$mode" in
  unit)
    run_unit_tests
    run_telegram_bot_tests
    ;;
  integration)
    run_integration_tests
    ;;
  full)
    run_unit_tests
    run_telegram_bot_tests
    run_integration_tests
    ;;
  esac

  # ── Итоги ─────────────────────────────────────────────────
  print_section "Итоги"
  print_test_summary

  # Явный выход с успехом если все тесты пройдены
  if [[ ${TOTAL_FAILED:-0} -eq 0 ]]; then
    exit 0
  else
    exit 1
  fi
}

main "$@"
