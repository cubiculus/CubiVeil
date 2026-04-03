#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140
# ╔══════════════════════════════════════════════════════════════╗
# ║      CubiVeil Unit Tests - install.sh modes                ║
# ║      Тестирование режимов --dev и --dry-run                ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Путь к проекту ───────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Счётчик тестов ───────────────────────────────────────────
TESTS_PASSED=0
TESTS_FAILED=0

# ── Цвета ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# ── Функции вывода ───────────────────────────────────────────
info() { echo -e "${CYAN}[INFO]${PLAIN} $*" >&2; }
pass() {
  echo -e "${GREEN}[PASS]${PLAIN} $*" >&2
  ((TESTS_PASSED++)) || true
}
fail() {
  echo -e "${RED}[FAIL]${PLAIN} $*" >&2
  ((TESTS_FAILED++)) || true
}
warn() { echo -e "${YELLOW}[WARN]${PLAIN} $*" >&2; }

# ── Загрузка модулей ─────────────────────────────────────────
source "${SCRIPT_DIR}/lib/output.sh" 2>/dev/null || true

# ── Тест: файл install.sh существует ─────────────────────────
test_install_file_exists() {
  info "Тестирование наличия файла install.sh..."

  if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
    pass "install.sh: файл существует"
  else
    fail "install.sh: файл не найден"
  fi
}

# ── Тест: синтаксис install.sh ───────────────────────────────
test_install_syntax() {
  info "Тестирование синтаксиса install.sh..."

  if bash -n "${SCRIPT_DIR}/install.sh" 2>/dev/null; then
    pass "install.sh: синтаксис корректен"
  else
    fail "install.sh: синтаксическая ошибка"
  fi
}

# ── Тест: переменная DEV_MODE определена ─────────────────────
test_dev_mode_variable() {
  info "Тестирование переменной DEV_MODE..."

  if grep -q 'DEV_MODE=' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE=' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: переменная DEV_MODE определена"
  else
    fail "install.sh: переменная DEV_MODE не найдена"
  fi
}

# ── Тест: переменная DRY_RUN определена ──────────────────────
test_dry_run_variable() {
  info "Тестирование переменной DRY_RUN..."

  if grep -q 'DRY_RUN=' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DRY_RUN=' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: переменная DRY_RUN определена"
  else
    fail "install.sh: переменная DRY_RUN не найдена"
  fi
}

# ── Тест: аргумент --dev обрабатывается ──────────────────────
test_dev_argument() {
  info "Тестирование обработки аргумента --dev..."

  if grep -q '\-\-dev)' "${SCRIPT_DIR}/install.sh" ||
    grep -q '\-\-dev)' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: аргумент --dev обрабатывается"
  else
    fail "install.sh: аргумент --dev не обрабатывается"
  fi
}

# ── Тест: аргумент --dry-run обрабатывается ──────────────────
test_dry_run_argument() {
  info "Тестирование обработки аргумента --dry-run..."

  if grep -q '\-\-dry-run)' "${SCRIPT_DIR}/install.sh" ||
    grep -q '\-\-dry-run)' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: аргумент --dry-run обрабатывается"
  else
    fail "install.sh: аргумент --dry-run не обрабатывается"
  fi
}

# ── Тест: usage содержит --dev ───────────────────────────────
test_usage_has_dev() {
  info "Тестирование usage: наличие --dev..."

  if grep -q '\-\-dev' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: usage содержит --dev"
  else
    fail "install.sh: usage не содержит --dev"
  fi
}

# ── Тест: usage содержит --dry-run ───────────────────────────
test_usage_has_dry_run() {
  info "Тестирование usage: наличие --dry-run..."

  if grep -q '\-\-dry-run' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: usage содержит --dry-run"
  else
    fail "install.sh: usage не содержит --dry-run"
  fi
}

# ── Тест: usage содержит примеры ─────────────────────────────
test_usage_has_examples() {
  info "Тестирование usage: наличие примеров..."

  local examples_count
  examples_count=$(grep -c 'Examples:' "${SCRIPT_DIR}/install.sh" 2>/dev/null || echo "0")
  examples_count="${examples_count%%[^0-9]*}" # Удаляем все нецифровые символы

  if [[ "$examples_count" -ge 1 ]]; then
    pass "install.sh: usage содержит примеры"
  else
    fail "install.sh: usage не содержит примеры"
  fi
}

# ── Тест: dry-run режим показывает план установки ────────────
test_dry_run_shows_plan() {
  info "Тестирование dry-run: план установки..."

  if grep -q 'Installation Plan' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'Installation Plan' "${SCRIPT_DIR}/lib/core/installer/ui.sh" ||
    grep -q 'План установки' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'План установки' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run показывает план установки"
  else
    fail "install.sh: dry-run не показывает план установки"
  fi
}

# ── Тест: dry-run проверяет root ─────────────────────────────
test_dry_run_checks_root() {
  info "Тестирование dry-run: проверка root..."

  if grep -q 'EUID' "${SCRIPT_DIR}/lib/core/installer/ui.sh" &&
    grep -q 'Root access' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run проверяет root доступ"
  else
    fail "install.sh: dry-run не проверяет root доступ"
  fi
}

# ── Тест: dry-run проверяет Ubuntu ───────────────────────────
test_dry_run_checks_ubuntu() {
  info "Тестирование dry-run: проверка Ubuntu..."

  if grep -q 'ubuntu' "${SCRIPT_DIR}/lib/core/installer/ui.sh" &&
    grep -q 'Ubuntu' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run проверяет Ubuntu"
  else
    fail "install.sh: dry-run не проверяет Ubuntu"
  fi
}

# ── Тест: dev режим показывает предупреждение ─────────────────
test_dev_mode_warning() {
  info "Тестирование dev-режим: предупреждение..."

  if grep -q 'DEV MODE' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV-режим' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE' "${SCRIPT_DIR}/lib/core/installer/cli.sh" ||
    grep -q 'DEV_MODE' "${SCRIPT_DIR}/lib/core/installer/prompt.sh"; then
    pass "install.sh: dev-режим показывает предупреждение"
  else
    fail "install.sh: dev-режим не показывает предупреждение"
  fi
}

# ── Тест: dry-run показывает сообщение о симуляции ───────────
test_dry_run_simulation_message() {
  info "Тестирование dry-run: сообщение о симуляции..."

  if grep -q 'Simulation' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'Simulation' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run показывает сообщение о симуляции"
  else
    fail "install.sh: dry-run не показывает сообщение о симуляции"
  fi
}

# ── Тест: dry-run не вносит изменения ────────────────────────
test_dry_run_no_changes() {
  info "Тестирование dry-run: отсутствие изменений..."

  if grep -q 'No changes' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'No changes' "${SCRIPT_DIR}/lib/core/installer/ui.sh" ||
    grep -q 'изменения не будут' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'изменения не будут' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run указывает на отсутствие изменений"
  else
    fail "install.sh: dry-run не указывает на отсутствие изменений"
  fi
}

# ── Тест: parse_args функция существует ──────────────────────
test_parse_args_exists() {
  info "Тестирование функции parse_args..."

  if grep -q 'parse_args()' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'parse_args()' "${SCRIPT_DIR}/lib/core/installer/cli.sh" ||
    grep -q 'parse_args() {' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: функция parse_args существует"
  else
    fail "install.sh: функция parse_args не найдена"
  fi
}

# ── Тест: usage функция существует ───────────────────────────
test_usage_exists() {
  info "Тестирование функции usage..."

  if grep -q 'usage()' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: функция usage существует"
  else
    fail "install.sh: функция usage не найдена"
  fi
}

# ── Тест: --help обрабатывается ──────────────────────────────
test_help_argument() {
  info "Тестирование обработки --help..."

  if grep -q '\-\-help' "${SCRIPT_DIR}/install.sh" &&
    grep -q 'usage' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: --help обрабатывается"
  else
    fail "install.sh: --help не обрабатывается"
  fi
}

# ── Тест: переменная DEV_DOMAIN определена ───────────────────
test_dev_domain_variable() {
  info "Тестирование переменной DEV_DOMAIN..."

  if grep -q 'DEV_DOMAIN=' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_DOMAIN=' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: переменная DEV_DOMAIN определена"
  else
    fail "install.sh: переменная DEV_DOMAIN не найдена"
  fi
}

# ── Тест: dev.cubiveil.local используется по умолчанию ───────
test_default_dev_domain() {
  info "Тестирование домена по умолчанию для dev..."

  if grep -q 'dev.cubiveil.local' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'dev.cubiveil.local' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: dev.cubiveil.local используется по умолчанию"
  else
    fail "install.sh: dev.cubiveil.local не найдено"
  fi
}

# ── Тест: --domain аргумент обрабатывается ───────────────────
test_domain_argument() {
  info "Тестирование обработки --domain..."

  if grep -q '\-\-domain=' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: --domain обрабатывается"
  else
    fail "install.sh: --domain не обрабатывается"
  fi
}

# ── Тест: prompt_inputs проверяет DEV_MODE ───────────────────
test_prompt_inputs_checks_dev_mode() {
  info "Тестирование prompt_inputs: проверка DEV_MODE..."

  if grep -q 'DEV_MODE.*true' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE:-false' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE' "${SCRIPT_DIR}/lib/core/installer/prompt.sh"; then
    pass "prompt_inputs: проверяет DEV_MODE"
  else
    fail "prompt_inputs: не проверяет DEV_MODE"
  fi
}

# ── Тест: prompt_inputs пропускает ввод в dev-режиме ─────────
test_prompt_inputs_skips_in_dev_mode() {
  info "Тестирование prompt_inputs: пропуск ввода в dev-режиме..."

  if grep -q 'return 0' "${SCRIPT_DIR}/lib/core/installer/prompt.sh" &&
    grep -q 'DEV-режим\|DEV mode\|DEV_MODE' "${SCRIPT_DIR}/lib/core/installer/prompt.sh"; then
    pass "prompt_inputs: пропускает ввод в dev-режиме"
  else
    fail "prompt_inputs: не пропускает ввод в dev-режиме"
  fi
}

# ── Запуск тестов ────────────────────────────────────────────
main() {
  echo "══════════════════════════════════════════════════════════"
  echo "  CubiVeil Unit Tests - install.sh modes"
  echo "  Тестирование режимов --dev и --dry-run"
  echo "══════════════════════════════════════════════════════════"
  echo ""

  # Базовые тесты
  test_install_file_exists
  test_install_syntax

  # Тесты переменных
  test_dev_mode_variable
  test_dry_run_variable
  test_dev_domain_variable

  # Тесты аргументов
  test_dev_argument
  test_dry_run_argument
  test_domain_argument
  test_help_argument

  # Тесты usage
  test_usage_exists
  test_usage_has_dev
  test_usage_has_dry_run
  test_usage_has_examples

  # Тесты dry-run
  test_dry_run_shows_plan
  test_dry_run_checks_root
  test_dry_run_checks_ubuntu
  test_dry_run_simulation_message
  test_dry_run_no_changes

  # Тесты dev-режима
  test_dev_mode_warning
  test_default_dev_domain

  # Тесты функций
  test_parse_args_exists
  test_prompt_inputs_checks_dev_mode
  test_prompt_inputs_skips_in_dev_mode

  # ── Итоги ──────────────────────────────────────────────────
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  Результаты / Results"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo -e "  Пройдено ${GREEN}(${TESTS_PASSED})${PLAIN}"
  echo -e "  Провалено ${RED}(${TESTS_FAILED})${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}  Тесты не пройдены${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}  Все тесты пройдены ✓${PLAIN}"
    exit 0
  fi
}

main "$@"
