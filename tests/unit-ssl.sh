#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - SSL Module                  ║
# ║        Тестирование lib/modules/ssl/install.sh           ║
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

# ── Путь к проекту и модулю ──────────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_PATH="${PROJECT_ROOT}/lib/modules/ssl/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "Ошибка: SSL module не найден: $MODULE_PATH" >&2
  exit 1
fi

# ── Моки ────────────────────────────────────────────────────
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_info() { echo "[INFO] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }

cmd_check() { return 1; }
pkg_install_packages() {
  echo "[MOCK] pkg_install_packages: $*" >&2
  return 0
}
svc_restart_if_active() {
  echo "[MOCK] svc_restart_if_active: $1" >&2
  return 0
}
systemctl() {
  echo "[MOCK] systemctl: $*" >&2
  return 0
}

# ── Загрузка модуля ──────────────────────────────────────────
# shellcheck source=lib/modules/ssl/install.sh
source "$MODULE_PATH"

# ── Тест: файл существует ───────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла модуля..."
  if [[ -f "$MODULE_PATH" ]]; then
    pass "SSL module: файл существует"
  else
    fail "SSL module: файл не найден"
  fi
}

# ── Тест: синтаксис ────────────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса..."
  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "SSL module: синтаксис корректен"
  else
    fail "SSL module: синтаксическая ошибка"
  fi
}

# ── Тест: shebang ──────────────────────────────────────────
test_shebang() {
  info "Тестирование shebang..."
  local shebang
  shebang=$(head -1 "$MODULE_PATH")
  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "SSL module: корректный shebang"
  else
    fail "SSL module: некорректный shebang: $shebang"
  fi
}

# ── Тест: ssl_generate_self_signed ─────────────────────────
test_ssl_generate_self_signed() {
  info "Тестирование ssl_generate_self_signed..."

  local tmp_dir
  tmp_dir="/tmp/ssl-selfsigned-test-$$"
  export SSL_SELFIGNED_DIR="$tmp_dir"
  export DOMAIN="test.local"

  rm -rf "$tmp_dir" && mkdir -p "$tmp_dir"
  if ! ssl_generate_self_signed; then
    fail "ssl_generate_self_signed вернул ошибку"
    return
  fi

  local expected_files=("privkey.pem" "cert.pem" "fullchain.pem")
  for f in "${expected_files[@]}"; do
    if [[ ! -f "$tmp_dir/$f" ]]; then
      fail "ssl_generate_self_signed: не создал $f"
      return
    fi
  done

  pass "ssl_generate_self_signed создал самоподписанные сертификаты"
  rm -rf "$tmp_dir"
}

# ── Тест: ssl_enable в dev режиме ──────────────────────────
test_ssl_enable_dev_mode() {
  info "Тестирование ssl_enable в dev режиме..."

  local tmp_dir
  tmp_dir="/tmp/ssl-dev-mode-test-$$"
  export SSL_SELFIGNED_DIR="$tmp_dir"
  export DEV_MODE="true"

  rm -rf "$tmp_dir" && mkdir -p "$tmp_dir"
  touch "$tmp_dir/cert.pem"

  local called=0
  svc_restart_if_active() {
    called=1
    echo "[MOCK] svc_restart_if_active: $1" >&2
    return 0
  }

  if ! ssl_enable; then
    fail "ssl_enable вернул ошибку в dev режиме"
    rm -rf "$tmp_dir"
    return
  fi

  if [[ "$called" -eq 1 ]]; then
    pass "ssl_enable в dev режиме перезапускает сервисы"
  else
    fail "ssl_enable в dev режиме не вызвал svc_restart_if_active"
  fi

  rm -rf "$tmp_dir"
}

# ── Основной запуск ────────────────────────────────────────
main() {
  test_file_exists
  test_syntax
  test_shebang
  test_ssl_generate_self_signed
  test_ssl_enable_dev_mode

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
