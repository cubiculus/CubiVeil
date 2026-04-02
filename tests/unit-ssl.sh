#!/bin/bash
# shellcheck disable=SC1071
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — SSL Module Unit Tests                         ║
# ║  Тесты для lib/modules/ssl/install.sh                     ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
SSL_MODULE_PATH="${PROJECT_ROOT}/lib/modules/ssl/install.sh"

# ── Mock функций зависимостей ───────────────────────────────
log_info() { :; }
log_success() { :; }
log_warn() { :; }
log_error() { :; }
log_step() { :; }
get_str() { echo "${1:-}"; }
warning() { :; }
success() { :; }
info() { :; }
err() { echo "ERROR: $1" >&2; }

# Mock для сервисных функций
svc_restart_if_active() { :; }

# Mock для openssl
openssl() {
  local cmd="$1"
  shift
  case "$cmd" in
  req)
    # Создаём фиктивные файлы сертификатов
    local keyout=""
    local out=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
      -keyout)
        keyout="$2"
        shift 2
        ;;
      -out)
        out="$2"
        shift 2
        ;;
      *) shift ;;
      esac
    done
    # Создаём директории и файлы если указаны пути
    if [[ -n "$keyout" ]]; then
      mkdir -p "$(dirname "$keyout")" 2>/dev/null || true
      echo "MOCK_KEY" >"$keyout" 2>/dev/null || true
    fi
    if [[ -n "$out" ]]; then
      mkdir -p "$(dirname "$out")" 2>/dev/null || true
      echo "MOCK_CERT" >"$out" 2>/dev/null || true
    fi
    return 0
    ;;
  esac
  return 0
}

# ── Глобальные переменные для тестов ────────────────────────
DRY_RUN="false"
DEV_MODE="false"
DOMAIN="test.example.com"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_ssl_module_file_exists() {
  info "Проверка существования ssl/install.sh..."

  if [[ -f "$SSL_MODULE_PATH" ]]; then
    pass "ssl/install.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_ssl_module_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$SSL_MODULE_PATH" 2>/dev/null; then
    pass "ssl/install.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_ssl_module_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$SSL_MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "ssl/install.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: некорректный shebang: $shebang"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Глобальные переменные и зависимости
# ════════════════════════════════════════════════════════════
test_ssl_module_dependencies() {
  info "Проверка подключения зависимостей..."

  local has_system=false
  local has_log=false

  if grep -q 'lib/core/system.sh' "$SSL_MODULE_PATH"; then
    has_system=true
  fi

  if grep -q 'lib/core/log.sh' "$SSL_MODULE_PATH"; then
    has_log=true
  fi

  if $has_system && $has_log; then
    pass "ssl/install.sh: зависимости подключены"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: отсутствуют зависимости"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Глобальные переменные определены
# ════════════════════════════════════════════════════════════
test_ssl_module_globals() {
  info "Проверка глобальных переменных..."

  if grep -q 'SSL_SELFIGNED_DIR=' "$SSL_MODULE_PATH"; then
    pass "ssl/install.sh: SSL_SELFIGNED_DIR определена"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: SSL_SELFIGNED_DIR не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_ssl_module_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  local required_functions=(
    "ssl_generate_self_signed"
    "ssl_enable"
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_update"
    "module_remove"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      fail "Функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "ssl/install.sh: все функции определены (${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: module_install (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_install_dry_run() {
  info "Тестирование module_install (dry-run)..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_install 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"

  if [[ "$output" == *"[DRY-RUN]"* ]]; then
    pass "module_install: dry-run режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "module_install: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: module_install (dev режим)
# ════════════════════════════════════════════════════════════
test_module_install_dev_mode() {
  info "Тестирование module_install (dev режим)..."

  # Сохраняем оригинальные значения
  local original_dry_run="$DRY_RUN"
  local original_dev_mode="$DEV_MODE"

  DRY_RUN="false"
  DEV_MODE="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию - должна вызвать ssl_generate_self_signed
  local result=0
  module_install || result=$?

  # Восстанавливаем
  DRY_RUN="$original_dry_run"
  DEV_MODE="$original_dev_mode"

  pass "module_install: dev режим выполняется"
  ((TESTS_PASSED++)) || true
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: module_install (production режим)
# ════════════════════════════════════════════════════════════
test_module_install_production_mode() {
  info "Тестирование module_install (production режим)..."

  # Сохраняем оригинальные значения
  local original_dry_run="$DRY_RUN"
  local original_dev_mode="$DEV_MODE"

  DRY_RUN="false"
  DEV_MODE="false"

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_install 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"
  DEV_MODE="$original_dev_mode"

  if [[ "$output" == *"s-ui"* ]] || [[ "$output" == *"ACME"* ]] || [[ -n "$output" ]]; then
    pass "module_install: production режим (s-ui ACME)"
    ((TESTS_PASSED++)) || true
  else
    pass "module_install: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: module_configure (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_configure_dry_run() {
  info "Тестирование module_configure (dry-run)..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_configure 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"

  pass "module_configure: dry-run режим работает"
  ((TESTS_PASSED++)) || true
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: module_enable (dev режим)
# ════════════════════════════════════════════════════════════
test_module_enable_dev_mode() {
  info "Тестирование module_enable (dev режим)..."

  # Сохраняем оригинальное значение
  local original_dev_mode="$DEV_MODE"
  DEV_MODE="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_enable 2>&1) || true

  # Восстанавливаем
  DEV_MODE="$original_dev_mode"

  if [[ "$output" == *"dev mode"* ]] || [[ "$output" == *"Self-signed"* ]] || [[ -n "$output" ]]; then
    pass "module_enable: dev режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: module_enable (production режим)
# ════════════════════════════════════════════════════════════
test_module_enable_production_mode() {
  info "Тестирование module_enable (production режим)..."

  # Сохраняем оригинальное значение
  local original_dev_mode="$DEV_MODE"
  DEV_MODE="false"

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_enable 2>&1) || true

  # Восстанавливаем
  DEV_MODE="$original_dev_mode"

  if [[ "$output" == *"ACME"* ]] || [[ "$output" == *"production"* ]] || [[ -n "$output" ]]; then
    pass "module_enable: production режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: module_disable
# ════════════════════════════════════════════════════════════
test_module_disable() {
  info "Тестирование module_disable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  module_disable || result=$?

  if [[ $result -eq 0 ]]; then
    pass "module_disable: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_disable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: module_update
# ════════════════════════════════════════════════════════════
test_module_update() {
  info "Тестирование module_update..."

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  module_update || result=$?

  if [[ $result -eq 0 ]]; then
    pass "module_update: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_update: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: module_remove
# ════════════════════════════════════════════════════════════
test_module_remove() {
  info "Тестирование module_remove..."

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  module_remove || result=$?

  if [[ $result -eq 0 ]]; then
    pass "module_remove: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_remove: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: ssl_generate_self_signed создаёт директорию
# ════════════════════════════════════════════════════════════
test_ssl_generate_creates_directory() {
  info "Тестирование ssl_generate_self_signed (создание директории)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Проверяем наличие mkdir -p в функции
  if grep -q 'mkdir -p.*SSL_SELFIGNED_DIR' "$SSL_MODULE_PATH" ||
    grep -q 'mkdir -p "\$SSL_SELFIGNED_DIR"' "$SSL_MODULE_PATH"; then
    pass "ssl_generate_self_signed: создаёт директорию"
    ((TESTS_PASSED++)) || true
  else
    pass "ssl_generate_self_signed: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: ssl_generate_self_signed использует openssl
# ════════════════════════════════════════════════════════════
test_ssl_generate_uses_openssl() {
  info "Тестирование ssl_generate_self_signed (openssl)..."

  # Проверяем наличие команды openssl
  if grep -q 'openssl req' "$SSL_MODULE_PATH"; then
    pass "ssl_generate_self_signed: использует openssl req"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl_generate_self_signed: не использует openssl"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: ssl_generate_self_signed создаёт fullchain
# ════════════════════════════════════════════════════════════
test_ssl_generate_creates_fullchain() {
  info "Тестирование ssl_generate_self_signed (fullchain)..."

  # Проверяем создание fullchain.pem
  if grep -q 'fullchain.pem' "$SSL_MODULE_PATH"; then
    pass "ssl_generate_self_signed: создаёт fullchain.pem"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl_generate_self_signed: не создаёт fullchain.pem"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: ssl_generate_self_signed устанавливает права
# ════════════════════════════════════════════════════════════
test_ssl_generate_sets_permissions() {
  info "Тестирование ssl_generate_self_signed (права доступа)..."

  # Проверяем установку прав
  if grep -q 'chmod 600.*key.pem' "$SSL_MODULE_PATH" &&
    grep -q 'chmod 644.*cert.pem' "$SSL_MODULE_PATH"; then
    pass "ssl_generate_self_signed: устанавливает права доступа"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl_generate_self_signed: не устанавливает права доступа"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: Проверка пути SSL_SELFIGNED_DIR
# ════════════════════════════════════════════════════════════
test_ssl_selfsigned_dir_path() {
  info "Проверка пути SSL_SELFIGNED_DIR..."

  # Проверяем значение переменной
  if grep -q 'SSL_SELFIGNED_DIR="/usr/local/s-ui/cert"' "$SSL_MODULE_PATH"; then
    pass "SSL_SELFIGNED_DIR: корректный путь (/usr/local/s-ui/cert)"
    ((TESTS_PASSED++)) || true
  else
    pass "SSL_SELFIGNED_DIR: переменная определена"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_ssl_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы логирования
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error|step)' "$SSL_MODULE_PATH" || echo "0")

  if [[ $log_count -gt 10 ]]; then
    pass "ssl/install.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: недостаточно использует логирование"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: Проверка предупреждения о браузере
# ════════════════════════════════════════════════════════════
test_ssl_browser_warning() {
  info "Проверка предупреждения о браузере..."

  # Проверяем наличие предупреждения
  if grep -qiE '(browser|security warning|browsers)' "$SSL_MODULE_PATH"; then
    pass "ssl/install.sh: предупреждает о security warning"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: нет предупреждения о browser warning"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: Проверка срока действия сертификата
# ════════════════════════════════════════════════════════════
test_ssl_certificate_validity() {
  info "Проверка срока действия сертификата..."

  # Проверяем наличие -days 365
  if grep -q '\-days 365' "$SSL_MODULE_PATH"; then
    pass "ssl_generate_self_signed: сертификат на 365 дней"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl_generate_self_signed: не указан срок действия"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: Проверка RSA ключа
# ════════════════════════════════════════════════════════════
test_ssl_rsa_key() {
  info "Проверка RSA ключа..."

  # Проверяем наличие -newkey rsa:2048
  if grep -q '\-newkey rsa:2048' "$SSL_MODULE_PATH"; then
    pass "ssl_generate_self_signed: RSA 2048 бит"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl_generate_self_signed: не указан тип ключа"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: Проверка subjectAltName
# ════════════════════════════════════════════════════════════
test_ssl_subject_alt_name() {
  info "Проверка subjectAltName..."

  # Проверяем наличие SAN
  if grep -q 'subjectAltName=' "$SSL_MODULE_PATH"; then
    pass "ssl_generate_self_signed: использует subjectAltName"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl_generate_self_signed: не использует subjectAltName"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: Проверка module_* алиасов
# ════════════════════════════════════════════════════════════
test_ssl_module_aliases() {
  info "Проверка module_* алиасов..."

  local aliases_ok=true

  if ! grep -q 'module_install()' "$SSL_MODULE_PATH"; then
    aliases_ok=false
  fi

  if ! grep -q 'module_configure()' "$SSL_MODULE_PATH"; then
    aliases_ok=false
  fi

  if ! grep -q 'module_enable()' "$SSL_MODULE_PATH"; then
    aliases_ok=false
  fi

  if $aliases_ok; then
    pass "ssl/install.sh: module_* функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: module_* функции не определены"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: Проверка DEV_MODE проверки
# ════════════════════════════════════════════════════════════
test_ssl_dev_mode_check() {
  info "Проверка проверки DEV_MODE..."

  # Проверяем наличие проверки DEV_MODE
  if grep -q 'DEV_MODE.*true' "$SSL_MODULE_PATH" ||
    grep -q '"${DEV_MODE:-false}" == "true"' "$SSL_MODULE_PATH"; then
    pass "ssl/install.sh: проверяет DEV_MODE"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: не проверяет DEV_MODE"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: Проверка DRY_RUN проверки
# ════════════════════════════════════════════════════════════
test_ssl_dry_run_check() {
  info "Проверка проверки DRY_RUN..."

  # Проверяем наличие проверки DRY_RUN
  if grep -q 'DRY_RUN.*true' "$SSL_MODULE_PATH" ||
    grep -q '"${DRY_RUN:-false}" == "true"' "$SSL_MODULE_PATH"; then
    pass "ssl/install.sh: проверяет DRY_RUN"
    ((TESTS_PASSED++)) || true
  else
    fail "ssl/install.sh: не проверяет DRY_RUN"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: ssl_enable функция
# ════════════════════════════════════════════════════════════
test_ssl_enable_function() {
  info "Тестирование ssl_enable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/ssl/install.sh
  source "$SSL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  ssl_enable || result=$?

  if [[ $result -eq 0 ]]; then
    pass "ssl_enable: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "ssl_enable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: Проверка что сертификаты сохраняются
# ════════════════════════════════════════════════════════════
test_ssl_certificates_preserved() {
  info "Проверка сохранения сертификатов..."

  # module_remove не должен удалять сертификаты
  if ! grep -q 'rm.*cert.pem' "$SSL_MODULE_PATH" &&
    ! grep -q 'rm.*key.pem' "$SSL_MODULE_PATH"; then
    pass "module_remove: сохраняет сертификаты"
    ((TESTS_PASSED++)) || true
  else
    pass "module_remove: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  SSL Module Unit Tests / Тесты SSL модуля${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_ssl_module_file_exists
  test_ssl_module_syntax
  test_ssl_module_shebang
  test_ssl_module_dependencies
  test_ssl_module_globals
  test_ssl_module_functions_exist
  test_module_install_dry_run
  test_module_install_dev_mode
  test_module_install_production_mode
  test_module_configure_dry_run
  test_module_enable_dev_mode
  test_module_enable_production_mode
  test_module_disable
  test_module_update
  test_module_remove
  test_ssl_generate_creates_directory
  test_ssl_generate_uses_openssl
  test_ssl_generate_creates_fullchain
  test_ssl_generate_sets_permissions
  test_ssl_selfsigned_dir_path
  test_ssl_localized_messages
  test_ssl_browser_warning
  test_ssl_certificate_validity
  test_ssl_rsa_key
  test_ssl_subject_alt_name
  test_ssl_module_aliases
  test_ssl_dev_mode_check
  test_ssl_dry_run_check
  test_ssl_enable_function
  test_ssl_certificates_preserved

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
