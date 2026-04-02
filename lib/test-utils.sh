#!/bin/bash
# shellcheck disable=SC1071
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Test Utilities                        ║
# ║          Общие функции для тестовых скриптов              ║
# ╚═══════════════════════════════════════════════════════════╝

# Strict mode отключён для совместимости с тестами

# ── Подключение унифицированных функций вывода ───────────────
# Используем TEST_UTILS_DIR вместо SCRIPT_DIR чтобы не перезаписывать
TEST_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${TEST_UTILS_DIR}/output.sh" ]]; then
  source "${TEST_UTILS_DIR}/output.sh"
fi

# ── Функции вывода ────────────────────────────────────────────
pass() {
  echo -e "${GREEN}[PASS]${PLAIN} $1"
  ((TESTS_PASSED++)) || true
}
fail() {
  echo -e "${RED}[FAIL]${PLAIN} $1"
  ((TESTS_FAILED++)) || true
}
warn() { echo -e "${YELLOW}[WARN]${PLAIN} $1"; }
info() { echo -e "[INFO] $1"; }

# ── Инициализация счётчиков ───────────────────────────────────
init_test_counters() {
  TESTS_PASSED=0
  TESTS_FAILED=0
}

# ── Вывод итогов ──────────────────────────────────────────────
print_test_summary() {
  echo ""
  echo "━━━ Итоги ━━━"
  echo "Пройдено: $TESTS_PASSED"
  echo "Провалено: $TESTS_FAILED"
  [[ $TESTS_FAILED -eq 0 ]] && return 0 || return 1
}

# ── Счётчик тестов ────────────────────────────────────────────
TESTS_PASSED=0
TESTS_FAILED=0
