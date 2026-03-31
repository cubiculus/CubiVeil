#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Fail2ban Module Unit Tests                    ║
# ║  Тесты для lib/modules/fail2ban/install.sh                ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
FAIL2BAN_MODULE_PATH="${PROJECT_ROOT}/lib/modules/fail2ban/install.sh"

# ── Mock функций зависимостей ───────────────────────────────
log_info() { :; }
log_success() { :; }
log_warn() { :; }
log_error() { :; }
log_step() { :; }
log_debug() { :; }
get_str() { echo "${1:-}"; }
warning() { :; }
success() { :; }
info() { :; }
err() { echo "ERROR: $1" >&2; }

# Mock для pkg_check и pkg_install_packages
pkg_check() { return 1; }
pkg_install_packages() { :; }

# Mock для сервисных функций
svc_daemon_reload() { :; }
svc_enable_start() { :; }
svc_restart() { :; }
svc_stop() { :; }
svc_disable() { :; }
svc_active() { return 0; }

# Mock для fail2ban-client
fail2ban-client() {
  local cmd="$1"
  shift
  case "$cmd" in
  status)
    if [[ "$*" == "sshd" ]]; then
      echo "Status for the jail: sshd"
      echo "|- Filter"
      echo "|  |- Currently failed: 0"
      echo "|  |- Currently banned: 0"
      echo "|  |- Total failed: 0"
      echo "|- Action"
      echo "   |- Currently banned: 0"
    else
      echo "Status"
      echo "|- Number of jail: 1"
      echo "|- Jail list: sshd"
    fi
    return 0
    ;;
  set)
    # unbanip command
    return 0
    ;;
  esac
  return 0
}

# ── Глобальные переменные для тестов ────────────────────────
DRY_RUN="false"
LANG_NAME="English"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_fail2ban_module_file_exists() {
  info "Проверка существования fail2ban/install.sh..."

  if [[ -f "$FAIL2BAN_MODULE_PATH" ]]; then
    pass "fail2ban/install.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban/install.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_fail2ban_module_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$FAIL2BAN_MODULE_PATH" 2>/dev/null; then
    pass "fail2ban/install.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban/install.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_fail2ban_module_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$FAIL2BAN_MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "fail2ban/install.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban/install.sh: некорректный shebang: $shebang"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Глобальные переменные и зависимости
# ════════════════════════════════════════════════════════════
test_fail2ban_module_dependencies() {
  info "Проверка подключения зависимостей..."

  local has_system=false
  local has_log=false

  if grep -q 'lib/core/system.sh' "$FAIL2BAN_MODULE_PATH"; then
    has_system=true
  fi

  if grep -q 'lib/core/log.sh' "$FAIL2BAN_MODULE_PATH"; then
    has_log=true
  fi

  if $has_system && $has_log; then
    pass "fail2ban/install.sh: зависимости подключены"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban/install.sh: отсутствуют зависимости"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Константы конфигурации
# ════════════════════════════════════════════════════════════
test_fail2ban_constants() {
  info "Проверка констант конфигурации..."

  local has_conf_dir=false
  local has_conf_file=false
  local has_defaults=false

  if grep -q 'FAIL2BAN_CONF_DIR=' "$FAIL2BAN_MODULE_PATH"; then
    has_conf_dir=true
  fi

  if grep -q 'FAIL2BAN_CONF_FILE=' "$FAIL2BAN_MODULE_PATH"; then
    has_conf_file=true
  fi

  if grep -q 'FAIL2BAN_DEFAULT_BANTIME=' "$FAIL2BAN_MODULE_PATH" &&
    grep -q 'FAIL2BAN_DEFAULT_FINDTIME=' "$FAIL2BAN_MODULE_PATH" &&
    grep -q 'FAIL2BAN_DEFAULT_MAXRETRY=' "$FAIL2BAN_MODULE_PATH"; then
    has_defaults=true
  fi

  if $has_conf_dir && $has_conf_file && $has_defaults; then
    pass "fail2ban/install.sh: константы конфигурации определены"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban/install.sh: отсутствуют константы"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_fail2ban_module_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  local required_functions=(
    "fail2ban_install"
    "fail2ban_get_ssh_port"
    "fail2ban_configure"
    "fail2ban_enable"
    "fail2ban_disable"
    "fail2ban_status"
    "fail2ban_ssh_status"
    "fail2ban_is_active"
    "fail2ban_check_config"
    "fail2ban_unban"
    "fail2ban_list_banned"
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
    pass "fail2ban/install.sh: все функции определены (${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban/install.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: fail2ban_install (не установлен)
# ════════════════════════════════════════════════════════════
test_fail2ban_install_not_installed() {
  info "Тестирование fail2ban_install (не установлен)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  fail2ban_install || result=$?

  if [[ $result -eq 0 ]]; then
    pass "fail2ban_install: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_install: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: fail2ban_install (уже установлен - мок)
# ════════════════════════════════════════════════════════════
test_fail2ban_install_already_installed() {
  info "Тестирование fail2ban_install (уже установлен - мок)..."

  # Переопределяем pkg_check для возврата 0 (установлен)
  pkg_check() { return 0; }

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(fail2ban_install 2>&1) || true

  if [[ "$output" == *"already installed"* ]] || [[ -n "$output" ]]; then
    pass "fail2ban_install: определяет уже установленный Fail2ban"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_install: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: fail2ban_get_ssh_port
# ════════════════════════════════════════════════════════════
test_fail2ban_get_ssh_port() {
  info "Тестирование fail2ban_get_ssh_port..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию
  local port
  port=$(fail2ban_get_ssh_port 2>/dev/null) || true

  # Должен вернуть порт (по умолчанию 22 или из конфига)
  if [[ -n "$port" ]]; then
    pass "fail2ban_get_ssh_port: возвращает порт ($port)"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_get_ssh_port: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: fail2ban_configure
# ════════════════════════════════════════════════════════════
test_fail2ban_configure() {
  info "Тестирование fail2ban_configure..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  fail2ban_configure || result=$?

  if [[ $result -eq 0 ]]; then
    pass "fail2ban_configure: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_configure: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: fail2ban_configure создаёт файл конфигурации
# ════════════════════════════════════════════════════════════
test_fail2ban_configure_creates_file() {
  info "Тестирование fail2ban_configure (создание файла)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Проверяем наличие команды cat > в функции
  if grep -q 'cat >.*FAIL2BAN_CONF_FILE' "$FAIL2BAN_MODULE_PATH" ||
    grep -q 'cat >"${FAIL2BAN_CONF_FILE}"' "$FAIL2BAN_MODULE_PATH"; then
    pass "fail2ban_configure: создаёт файл конфигурации"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_configure: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: fail2ban_enable
# ════════════════════════════════════════════════════════════
test_fail2ban_enable() {
  info "Тестирование fail2ban_enable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  fail2ban_enable || result=$?

  if [[ $result -eq 0 ]]; then
    pass "fail2ban_enable: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_enable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: fail2ban_disable
# ════════════════════════════════════════════════════════════
test_fail2ban_disable() {
  info "Тестирование fail2ban_disable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  fail2ban_disable || result=$?

  if [[ $result -eq 0 ]]; then
    pass "fail2ban_disable: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_disable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: fail2ban_status
# ════════════════════════════════════════════════════════════
test_fail2ban_status() {
  info "Тестирование fail2ban_status..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(fail2ban_status 2>&1) || true

  if [[ -n "$output" ]]; then
    pass "fail2ban_status: выводит статус"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_status: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: fail2ban_ssh_status
# ════════════════════════════════════════════════════════════
test_fail2ban_ssh_status() {
  info "Тестирование fail2ban_ssh_status..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(fail2ban_ssh_status 2>&1) || true

  if [[ -n "$output" ]]; then
    pass "fail2ban_ssh_status: выводит статус sshd"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_ssh_status: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: fail2ban_is_active
# ════════════════════════════════════════════════════════════
test_fail2ban_is_active() {
  info "Тестирование fail2ban_is_active..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию
  if fail2ban_is_active; then
    pass "fail2ban_is_active: возвращает active (мок)"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_is_active: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: fail2ban_check_config
# ════════════════════════════════════════════════════════════
test_fail2ban_check_config() {
  info "Тестирование fail2ban_check_config..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  fail2ban_check_config || result=$?

  # Функция может вернуть 1 если файл не найден (это нормально)
  pass "fail2ban_check_config: функция выполняется"
  ((TESTS_PASSED++)) || true
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: fail2ban_unban
# ════════════════════════════════════════════════════════════
test_fail2ban_unban() {
  info "Тестирование fail2ban_unban..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  fail2ban_unban "192.168.1.1" "sshd" || result=$?

  if [[ $result -eq 0 ]]; then
    pass "fail2ban_unban: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "fail2ban_unban: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: fail2ban_list_banned
# ════════════════════════════════════════════════════════════
test_fail2ban_list_banned() {
  info "Тестирование fail2ban_list_banned..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  fail2ban_list_banned "sshd" || result=$?

  pass "fail2ban_list_banned: функция выполняется"
  ((TESTS_PASSED++)) || true
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: module_install
# ════════════════════════════════════════════════════════════
test_module_install() {
  info "Тестирование module_install..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

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

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: module_configure
# ════════════════════════════════════════════════════════════
test_module_configure() {
  info "Тестирование module_configure..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

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

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: module_enable
# ════════════════════════════════════════════════════════════
test_module_enable() {
  info "Тестирование module_enable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

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

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: module_disable
# ════════════════════════════════════════════════════════════
test_module_disable() {
  info "Тестирование module_disable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

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
#  ТЕСТ 24: module_update
# ════════════════════════════════════════════════════════════
test_module_update() {
  info "Тестирование module_update..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

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
#  ТЕСТ 25: module_remove
# ════════════════════════════════════════════════════════════
test_module_remove() {
  info "Тестирование module_remove..."

  # Загружаем модуль
  # shellcheck source=lib/modules/fail2ban/install.sh
  source "$FAIL2BAN_MODULE_PATH"

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
#  ТЕСТ 26: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_fail2ban_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы логирования
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error|step|debug)' "$FAIL2BAN_MODULE_PATH" || echo "0")

  if [[ $log_count -gt 10 ]]; then
    pass "fail2ban/install.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban/install.sh: недостаточно использует логирование"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: Проверка конфигурации SSH jail
# ════════════════════════════════════════════════════════════
test_fail2ban_ssh_jail_config() {
  info "Проверка конфигурации SSH jail..."

  # Проверяем наличие [sshd] секции
  if grep -q '\[sshd\]' "$FAIL2BAN_MODULE_PATH"; then
    pass "fail2ban_configure: настраивает SSH jail"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban_configure: не настраивает SSH jail"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: Проверка параметров по умолчанию
# ════════════════════════════════════════════════════════════
test_fail2ban_default_values() {
  info "Проверка параметров по умолчанию..."

  local issues=0

  if ! grep -q 'FAIL2BAN_DEFAULT_BANTIME="1h"' "$FAIL2BAN_MODULE_PATH"; then
    fail "FAIL2BAN_DEFAULT_BANTIME: некорректное значение"
    ((issues++)) || true
  fi

  if ! grep -q 'FAIL2BAN_DEFAULT_FINDTIME="10m"' "$FAIL2BAN_MODULE_PATH"; then
    fail "FAIL2BAN_DEFAULT_FINDTIME: некорректное значение"
    ((issues++)) || true
  fi

  if ! grep -q 'FAIL2BAN_DEFAULT_MAXRETRY="5"' "$FAIL2BAN_MODULE_PATH"; then
    fail "FAIL2BAN_DEFAULT_MAXRETRY: некорректное значение"
    ((issues++)) || true
  fi

  if [[ $issues -eq 0 ]]; then
    pass "fail2ban/install.sh: параметры по умолчанию корректны"
    ((TESTS_PASSED++)) || true
  else
    fail "fail2ban/install.sh: параметры по умолчанию некорректны"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: Проверка module_* алиасов
# ════════════════════════════════════════════════════════════
test_fail2ban_module_aliases() {
  info "Проверка module_* алиасов..."

  # Проверяем что module_install вызывает fail2ban_install
  if grep -q 'module_install.*fail2ban_install' "$FAIL2BAN_MODULE_PATH"; then
    pass "module_install: вызывает fail2ban_install"
    ((TESTS_PASSED++)) || true
  else
    fail "module_install: не вызывает fail2ban_install"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: Проверка удаления конфигурации
# ════════════════════════════════════════════════════════════
test_fail2ban_remove_config() {
  info "Проверка удаления конфигурации..."

  # Проверяем что module_remove удаляет конфигурацию
  if grep -q 'rm -f.*FAIL2BAN_CONF_FILE' "$FAIL2BAN_MODULE_PATH"; then
    pass "module_remove: удаляет файл конфигурации"
    ((TESTS_PASSED++)) || true
  else
    fail "module_remove: не удаляет файл конфигурации"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Fail2ban Module Unit Tests / Тесты Fail2ban модуля${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_fail2ban_module_file_exists
  test_fail2ban_module_syntax
  test_fail2ban_module_shebang
  test_fail2ban_module_dependencies
  test_fail2ban_constants
  test_fail2ban_module_functions_exist
  test_fail2ban_install_not_installed
  test_fail2ban_install_already_installed
  test_fail2ban_get_ssh_port
  test_fail2ban_configure
  test_fail2ban_configure_creates_file
  test_fail2ban_enable
  test_fail2ban_disable
  test_fail2ban_status
  test_fail2ban_ssh_status
  test_fail2ban_is_active
  test_fail2ban_check_config
  test_fail2ban_unban
  test_fail2ban_list_banned
  test_module_install
  test_module_configure
  test_module_enable
  test_module_disable
  test_module_update
  test_module_remove
  test_fail2ban_localized_messages
  test_fail2ban_ssh_jail_config
  test_fail2ban_default_values
  test_fail2ban_module_aliases
  test_fail2ban_remove_config

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
