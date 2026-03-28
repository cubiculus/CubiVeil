#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - Marzban Module              ║
# ║        Тестирование lib/modules/marzban/install.sh       ║
# ╚═══════════════════════════════════════════════════════════╝

# Strict mode отключен для совместимости с mock-функциями

# ── Счётчики ─────────────────────────────────────────────────
TESTS_PASSED=0
TESTS_FAILED=0

# ── Цвета ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# ── Функции вывода ────────────────────────────────────────────
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

# ── Путь к проекту и модулю ──────────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_PATH="${PROJECT_ROOT}/lib/modules/marzban/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "Ошибка: Marzban module не найден: $MODULE_PATH" >&2
  exit 1
fi

# ── Моки ────────────────────────────────────────────────────
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_info() { echo "[INFO] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

pkg_check() { return 1; }
svc_restart() {
  echo "[MOCK] svc_restart $1" >&2
  return 0
}

# ── Загрузка модуля ──────────────────────────────────────────
# shellcheck source=lib/modules/marzban/install.sh
source "$MODULE_PATH"

# ── Тест: файл существует ───────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла модуля..."
  if [[ -f "$MODULE_PATH" ]]; then
    pass "Marzban module: файл существует"
  else
    fail "Marzban module: файл не найден"
  fi
}

# ── Тест: синтаксис ─────────────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса..."
  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "Marzban module: синтаксис корректен"
  else
    fail "Marzban module: синтаксическая ошибка"
  fi
}

# ── Тест: shebang ───────────────────────────────────────────
test_shebang() {
  info "Тестирование shebang..."
  local shebang
  shebang=$(head -1 "$MODULE_PATH")
  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "Marzban module: корректный shebang"
  else
    fail "Marzban module: некорректный shebang: $shebang"
  fi
}

# ── Тест: marzban_is_installed ──────────────────────────────
test_marzban_is_installed() {
  info "Тестирование marzban_is_installed..."

  pkg_check() { return 0; }
  if marzban_is_installed; then
    pass "marzban_is_installed вернула true при pkg_check=0"
  else
    fail "marzban_is_installed вернула false при pkg_check=0"
  fi

  pkg_check() { return 1; }
  touch "/tmp/marzban"
  MARZBAN_INSTALL_DIR="/tmp"

  if marzban_is_installed; then
    pass "marzban_is_installed вернула true когда файл marzban существует"
  else
    fail "marzban_is_installed вернула false при наличии файла marzban"
  fi

  rm -f "/tmp/test-marzban-binary"
}

# ── Тест: marzban_restart — вызов svc_restart ───────────────
test_marzban_restart() {
  info "Тестирование marzban_restart..."

  called=0
  svc_restart() {
    called=1
    return 0
  }

  marzban_restart

  if [[ "$called" -eq 1 ]]; then
    pass "marzban_restart вызывает svc_restart"
  else
    fail "marzban_restart не вызывает svc_restart"
  fi
}

# ── Тест: module_update — вызывает marzban_restart ───────────
test_module_update() {
  info "Тестирование module_update..."

  called=0
  marzban_restart() {
    called=1
    return 0
  }

  module_update

  if [[ "$called" -eq 1 ]]; then
    pass "module_update вызывает marzban_restart"
  else
    fail "module_update не вызывает marzban_restart"
  fi
}

# ── Основной запуск ──────────────────────────────────────────
main() {
  test_file_exists
  test_syntax
  test_shebang
  test_marzban_is_installed
  test_marzban_restart
  test_module_update

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "Пройдено: $TESTS_PASSED"
  echo "Провалено: $TESTS_FAILED"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ "$TESTS_FAILED" -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

main "$@"
