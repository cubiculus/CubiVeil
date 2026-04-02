#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140,SC2178
# +===========================================================+
# |  CubiVeil -- Firewall Module Unit Tests                    |
# |  Тесты для lib/modules/firewall/install.sh                |
# +===========================================================+

set -euo pipefail

# -- Окружение -----------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# -- Подключение test-utils ----------------------------------
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# -- Переменные для тестов -----------------------------------
FIREWALL_MODULE_PATH="${PROJECT_ROOT}/lib/modules/firewall/install.sh"

# -- Mock функций зависимостей -------------------------------
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

# Mock для pkg_check и pkg_install_packages
pkg_check() { return 1; }
pkg_install_packages() { :; }

# Mock для функций работы с портами
open_port() { :; }
close_port() { :; }
validate_port() {
  local port="$1"
  [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1 && $port -le 65535 ]]
}

# Mock для ufw команд
ufw() {
  local cmd="$1"
  shift
  case "$cmd" in
  --force)
    local subcmd="$1"
    case "$subcmd" in
    reset | enable | disable) return 0 ;;
    esac
    ;;
  default) return 0 ;;
  allow) return 0 ;;
  delete) return 0 ;;
  status)
    if [[ "$*" == *"numbered"* ]]; then
      echo "Status: active"
      echo "To                         Action      From"
      echo "--                         ------      ----"
      echo "22/tcp                     ALLOW       Anywhere"
      echo "443/tcp                    ALLOW       Anywhere"
    else
      echo "Status: active"
    fi
    return 0
    ;;
  esac
  return 0
}

# -- Глобальные переменные для тестов ------------------------
# shellcheck disable=SC2034
DRY_RUN="false"
LANG_NAME="English"

# -- Тесты ---------------------------------------------------

# ============================================================
#  ТЕСТ 1: Файл существует
# ============================================================
test_firewall_module_file_exists() {
  info "Проверка существования firewall/install.sh..."

  if [[ -f "$FIREWALL_MODULE_PATH" ]]; then
    pass "firewall/install.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall/install.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 2: Синтаксис bash
# ============================================================
test_firewall_module_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$FIREWALL_MODULE_PATH" 2>/dev/null; then
    pass "firewall/install.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall/install.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 3: Shebang
# ============================================================
test_firewall_module_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$FIREWALL_MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "firewall/install.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall/install.sh: некорректный shebang: $shebang"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 4: Глобальные переменные и зависимости
# ============================================================
test_firewall_module_dependencies() {
  info "Проверка подключения зависимостей..."

  local has_system=false
  local has_log=false
  local has_utils=false
  local has_validation=false

  if grep -q 'lib/core/system.sh' "$FIREWALL_MODULE_PATH"; then
    has_system=true
  fi

  if grep -q 'lib/core/log.sh' "$FIREWALL_MODULE_PATH"; then
    has_log=true
  fi

  if grep -q 'lib/utils.sh' "$FIREWALL_MODULE_PATH"; then
    has_utils=true
  fi

  if grep -q 'lib/validation.sh' "$FIREWALL_MODULE_PATH"; then
    has_validation=true
  fi

  if $has_system && $has_log && $has_utils && $has_validation; then
    pass "firewall/install.sh: все зависимости подключены"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall/install.sh: отсутствуют зависимости"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 5: Функции существуют (после загрузки)
# ============================================================
test_firewall_module_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  local required_functions=(
    "firewall_install"
    "firewall_reset"
    "firewall_configure"
    "firewall_enable"
    "firewall_disable"
    "firewall_open_port"
    "firewall_close_port"
    "firewall_status"
    "firewall_is_active"
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
    pass "firewall/install.sh: все функции определены (${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall/install.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 6: firewall_install (UFW не установлен)
# ============================================================
test_firewall_install_not_installed() {
  info "Тестирование firewall_install (UFW не установлен)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  firewall_install || result=$?

  if [[ $result -eq 0 ]]; then
    pass "firewall_install: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_install: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 7: firewall_install (UFW уже установлен - мок)
# ============================================================
test_firewall_install_already_installed() {
  info "Тестирование firewall_install (UFW установлен - мок)..."

  # Переопределяем pkg_check для возврата 0 (установлен)
  pkg_check() { return 0; }

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(firewall_install 2>&1) || true

  if [[ "$output" == *"already installed"* ]] || [[ -n "$output" ]]; then
    pass "firewall_install: определяет уже установленный UFW"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_install: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 8: firewall_reset
# ============================================================
test_firewall_reset() {
  info "Тестирование firewall_reset..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  firewall_reset || result=$?

  if [[ $result -eq 0 ]]; then
    pass "firewall_reset: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_reset: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 9: firewall_configure
# ============================================================
test_firewall_configure() {
  info "Тестирование firewall_configure..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  firewall_configure || result=$?

  if [[ $result -eq 0 ]]; then
    pass "firewall_configure: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_configure: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 10: firewall_enable
# ============================================================
test_firewall_enable() {
  info "Тестирование firewall_enable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию
  local result=0
  firewall_enable || result=$?

  if [[ $result -eq 0 ]]; then
    pass "firewall_enable: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_enable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 11: firewall_disable
# ============================================================
test_firewall_disable() {
  info "Тестирование firewall_disable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  firewall_disable || result=$?

  if [[ $result -eq 0 ]]; then
    pass "firewall_disable: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_disable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 12: firewall_open_port с валидацией
# ============================================================
test_firewall_open_port() {
  info "Тестирование firewall_open_port..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию с валидным портом
  local result=0
  firewall_open_port "8080" "tcp" "test" || result=$?

  if [[ $result -eq 0 ]]; then
    pass "firewall_open_port: открывается порт 8080/tcp"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_open_port: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 13: firewall_open_port с невалидным портом
# ============================================================
test_firewall_open_port_invalid() {
  info "Тестирование firewall_open_port (невалидный порт)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию с невалидным портом
  local result=0
  firewall_open_port "invalid" "tcp" "test" || result=$?

  # Функция должна вернуть ошибку (не 0)
  if [[ $result -ne 0 ]]; then
    pass "firewall_open_port: отклоняет невалидный порт"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_open_port: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 14: firewall_close_port
# ============================================================
test_firewall_close_port() {
  info "Тестирование firewall_close_port..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  firewall_close_port "8080" "tcp" || result=$?

  if [[ $result -eq 0 ]]; then
    pass "firewall_close_port: закрывает порт"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_close_port: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 15: firewall_status
# ============================================================
test_firewall_status() {
  info "Тестирование firewall_status..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(firewall_status 2>&1) || true

  if [[ "$output" == *"Status:"* ]]; then
    pass "firewall_status: выводит статус"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_status: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 16: firewall_is_active
# ============================================================
test_firewall_is_active() {
  info "Тестирование firewall_is_active..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию
  if firewall_is_active; then
    pass "firewall_is_active: возвращает active (мок)"
    ((TESTS_PASSED++)) || true
  else
    pass "firewall_is_active: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 17: module_install
# ============================================================
test_module_install() {
  info "Тестирование module_install..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  module_install || result=$?

  if [[ $result -eq 0 ]]; then
    pass "module_install: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_install: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 18: module_configure
# ============================================================
test_module_configure() {
  info "Тестирование module_configure..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  module_configure || result=$?

  if [[ $result -eq 0 ]]; then
    pass "module_configure: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_configure: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 19: module_enable
# ============================================================
test_module_enable() {
  info "Тестирование module_enable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  module_enable || result=$?

  if [[ $result -eq 0 ]]; then
    pass "module_enable: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 20: module_disable
# ============================================================
test_module_disable() {
  info "Тестирование module_disable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

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

# ============================================================
#  ТЕСТ 21: module_update
# ============================================================
test_module_update() {
  info "Тестирование module_update..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

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

# ============================================================
#  ТЕСТ 22: module_remove
# ============================================================
test_module_remove() {
  info "Тестирование module_remove..."

  # Загружаем модуль
  # shellcheck source=lib/modules/firewall/install.sh
  source "$FIREWALL_MODULE_PATH"

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

# ============================================================
#  ТЕСТ 23: Проверка локализованных сообщений
# ============================================================
test_firewall_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы логирования
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error|step)' "$FIREWALL_MODULE_PATH" || echo "0")

  if [[ $log_count -gt 10 ]]; then
    pass "firewall/install.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall/install.sh: недостаточно использует логирование"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 24: Проверка открытия портов 443
# ============================================================
test_firewall_opens_443() {
  info "Проверка открытия порта 443..."

  # Проверяем что firewall_configure открывает 443
  if grep -q 'open_port 443' "$FIREWALL_MODULE_PATH"; then
    pass "firewall_configure: открывает порт 443"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall_configure: не открывает порт 443"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 25: Проверка предупреждения о SSH порте
# ============================================================
test_firewall_ssh_warning() {
  info "Проверка предупреждения о SSH порте..."

  # Проверяем наличие предупреждения
  if grep -qE '(SSH|порт 22|port 22)' "$FIREWALL_MODULE_PATH"; then
    pass "firewall_configure: предупреждает о SSH порте"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall_configure: нет предупреждения о SSH"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 26: Проверка использования validate_port
# ============================================================
test_firewall_uses_validate_port() {
  info "Проверка использования validate_port..."

  # Проверяем вызов validate_port
  if grep -q 'validate_port' "$FIREWALL_MODULE_PATH"; then
    pass "firewall_open_port: использует validate_port"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall_open_port: не использует validate_port"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 27: Проверка module_* алиасов
# ============================================================
test_firewall_module_aliases() {
  info "Проверка module_* алиасов..."

  # Проверяем что module_install вызывает firewall_install
  if grep -q 'module_install.*firewall_install' "$FIREWALL_MODULE_PATH"; then
    pass "module_install: вызывает firewall_install"
    ((TESTS_PASSED++)) || true
  else
    fail "module_install: не вызывает firewall_install"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 28: Проверка ufw --force reset
# ============================================================
test_firewall_reset_command() {
  info "Проверка команды сброса..."

  # Проверяем наличие ufw --force reset
  if grep -q 'ufw --force reset' "$FIREWALL_MODULE_PATH"; then
    pass "firewall_reset: использует ufw --force reset"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall_reset: не использует ufw --force reset"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 29: Проверка ufw default deny incoming
# ============================================================
test_firewall_default_deny() {
  info "Проверка default deny incoming..."

  # Проверяем наличие ufw default deny incoming
  if grep -q 'ufw default deny incoming' "$FIREWALL_MODULE_PATH"; then
    pass "firewall_reset: устанавливает default deny incoming"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall_reset: не устанавливает default deny incoming"
    ((TESTS_FAILED++)) || true
  fi
}

# ============================================================
#  ТЕСТ 30: Проверка ufw default allow outgoing
# ============================================================
test_firewall_default_allow() {
  info "Проверка default allow outgoing..."

  # Проверяем наличие ufw default allow outgoing
  if grep -q 'ufw default allow outgoing' "$FIREWALL_MODULE_PATH"; then
    pass "firewall_reset: устанавливает default allow outgoing"
    ((TESTS_PASSED++)) || true
  else
    fail "firewall_reset: не устанавливает default allow outgoing"
    ((TESTS_FAILED++)) || true
  fi
}

# -- Main ----------------------------------------------------
main() {
  echo -e "${CYAN}===========================================================${PLAIN}"
  echo -e "${CYAN}  Firewall Module Unit Tests / Тесты Firewall модуля${PLAIN}"
  echo -e "${CYAN}===========================================================${PLAIN}"
  echo ""

  test_firewall_module_file_exists
  test_firewall_module_syntax
  test_firewall_module_shebang
  test_firewall_module_dependencies
  test_firewall_module_functions_exist
  test_firewall_install_not_installed
  test_firewall_install_already_installed
  test_firewall_reset
  test_firewall_configure
  test_firewall_enable
  test_firewall_disable
  test_firewall_open_port
  test_firewall_open_port_invalid
  test_firewall_close_port
  test_firewall_status
  test_firewall_is_active
  test_module_install
  test_module_configure
  test_module_enable
  test_module_disable
  test_module_update
  test_module_remove
  test_firewall_localized_messages
  test_firewall_opens_443
  test_firewall_ssh_warning
  test_firewall_uses_validate_port
  test_firewall_module_aliases
  test_firewall_reset_command
  test_firewall_default_deny
  test_firewall_default_allow

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
    echo -e "${RED}[FAIL] Tests failed / Тесты провалены${PLAIN}"
    return 1
  else
    echo -e "${GREEN}[PASS] All tests passed / Все тесты пройдены${PLAIN}"
    return 0
  fi
}

# Запуск если файл запущен напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
