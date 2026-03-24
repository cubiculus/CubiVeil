#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Test Runner                               ║
# ║        Запуск всех тестов                                   ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Цвета ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# ── Переменные ───────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$SCRIPT_DIR/tests"

TOTAL_PASSED=0
TOTAL_FAILED=0

# ── Функции ─────────────────────────────────────────────────────
print_header() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${BLUE}║  $1${PLAIN}                                          ║"
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
    "unit-utils.sh:lib/utils.sh"
    "unit-telegram.sh:setup-telegram.sh"
  )

  for test_info in "${unit_tests[@]}"; do
    local test_file="${test_info%%:*}"
    local test_name="${test_info##*:}"
    local test_path="$TESTS_DIR/$test_file"

    echo -e "${BLUE}Запуск: $test_name${PLAIN}"

    if [[ -f "$test_path" ]]; then
      if bash "$test_path"; then
        ((TOTAL_PASSED++))
        echo -e "${GREEN}✓ $test_name пройден${PLAIN}"
      else
        ((TOTAL_FAILED++))
        echo -e "${RED}✗ $test_name провален${PLAIN}"
      fi
    else
      echo -e "${RED}✗ $test_name не найден: $test_path${PLAIN}"
      ((TOTAL_FAILED++))
    fi
    echo ""
  done
}

# ── Запуск unit-тестов через интеграционный тест ──────────────
run_unit_via_integration() {
  print_section "Unit Tests (через integration-tests.sh)"

  echo -e "${BLUE}Запуск unit-тестов через integration-tests.sh${PLAIN}"
  echo ""

  if bash "$TESTS_DIR/integration-tests.sh" . unit; then
    ((TOTAL_PASSED++))
    echo -e "${GREEN}✓ Unit тесты пройдены${PLAIN}"
  else
    ((TOTAL_FAILED++))
    echo -e "${RED}✗ Unit тесты провалены${PLAIN}"
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

  if bash "$TESTS_DIR/integration-tests.sh"; then
    ((TOTAL_PASSED++))
    echo -e "${GREEN}✓ Интеграционные тесты пройдены${PLAIN}"
  else
    ((TOTAL_FAILED++))
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
      --help|-h)
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

  # Запуск тестов в зависимости от режима
  case "$mode" in
    unit)
      run_unit_tests
      ;;
    integration)
      run_integration_tests
      ;;
    full)
      run_unit_tests
      run_integration_tests
      ;;
  esac

  # ── Итоги ─────────────────────────────────────────────────
  print_section "Итоги"

  echo -e "Всего пройдено: ${GREEN}$TOTAL_PASSED${PLAIN}"
  echo -e "Всего провалено: ${RED}$TOTAL_FAILED${PLAIN}"
  echo ""

  if [[ $TOTAL_FAILED -gt 0 ]]; then
    echo -e "${RED}❌ Некоторые тесты провалены${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}✅ Все тесты пройдены!${PLAIN}"
    exit 0
  fi
}

main "$@"
