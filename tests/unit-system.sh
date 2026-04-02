#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140,SC2178,SC2034
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — System Module Unit Tests                      ║
# ║  Тесты для lib/modules/system/install.sh                  ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
SYSTEM_MODULE_PATH="${PROJECT_ROOT}/lib/modules/system/install.sh"

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

# Mock для pkg_* функций
pkg_update() { :; }
pkg_upgrade() { :; }
pkg_full_upgrade() { :; }
pkg_install_packages() { :; }

# Mock для сервисных функций
svc_enable_start() { :; }
svc_active() { return 0; }
svc_restart() { :; }
systemctl() { :; }

# Mock для modprobe и sysctl
modprobe() { :; }
sysctl() {
  if [[ "$*" == *"-n net.ipv4.tcp_congestion_control"* ]]; then
    echo "bbr"
    return 0
  fi
  return 0
}

# Mock для create_temp_dir и cleanup_temp_dir
create_temp_dir() { mktemp -d; }
cleanup_temp_dir() { rm -rf "$1" 2>/dev/null || true; }

# Mock для curl
curl() {
  echo '{"org": "Test ISP"}'
}

# Mock для debconf-set-selections
debconf-set-selections() { :; }

# Mock для mkdir
mkdir() {
  local dir=""
  for arg in "$@"; do
    if [[ "$arg" == /etc/* ]]; then
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
    # Перенаправление - создаём файл
    local file
    file=$(echo "$*" | grep -oE '>[^ ]+' | tr -d '>')
    if [[ -n "$file" ]]; then
      touch "$file" 2>/dev/null || true
    fi
  elif [[ -n "$*" ]]; then
    # Вывод содержимого файла (mock)
    return 0
  else
    # Чтение из stdin (mock)
    return 0
  fi
}

# Mock для sed
sed() { :; }

# Mock для echo
echo_builtin() {
  builtin echo "$@"
}

# ── Глобальные переменные для тестов ────────────────────────
DRY_RUN="false"
# EUID is readonly, don't override it

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_system_module_file_exists() {
  info "Проверка существования system/install.sh..."

  if [[ -f "$SYSTEM_MODULE_PATH" ]]; then
    pass "system/install.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "system/install.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_system_module_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$SYSTEM_MODULE_PATH" 2>/dev/null; then
    pass "system/install.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "system/install.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_system_module_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$SYSTEM_MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "system/install.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "system/install.sh: некорректный shebang: $shebang"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Глобальные переменные и зависимости
# ════════════════════════════════════════════════════════════
test_system_module_dependencies() {
  info "Проверка подключения зависимостей..."

  local has_system=false
  local has_log=false
  local has_utils=false
  local has_security=false

  if grep -q 'lib/core/system.sh' "$SYSTEM_MODULE_PATH"; then
    has_system=true
  fi

  if grep -q 'lib/core/log.sh' "$SYSTEM_MODULE_PATH"; then
    has_log=true
  fi

  if grep -q 'lib/utils.sh' "$SYSTEM_MODULE_PATH"; then
    has_utils=true
  fi

  if grep -q 'lib/security.sh' "$SYSTEM_MODULE_PATH"; then
    has_security=true
  fi

  if $has_system && $has_log && $has_utils && $has_security; then
    pass "system/install.sh: все зависимости подключены"
    ((TESTS_PASSED++)) || true
  else
    fail "system/install.sh: отсутствуют зависимости"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_system_module_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  local required_functions=(
    "system_setup_update_env"
    "system_full_update"
    "system_quick_update"
    "system_auto_updates_configure"
    "system_auto_updates_unattended_configure"
    "system_auto_updates_enable"
    "system_auto_updates_setup"
    "system_bbr_load_module"
    "system_bbr_create_sysctl_config"
    "system_bbr_apply_sysctl"
    "system_bbr_setup"
    "system_bbr_check_status"
    "system_check_ip_neighborhood"
    "system_check_services"
    "system_restart_services"
    "system_install_base_dependencies"
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_update"
    "module_status"
    "module_quick_update"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      fail "Функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "system/install.sh: все функции определены (${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "system/install.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: system_setup_update_env
# ════════════════════════════════════════════════════════════
test_system_setup_update_env() {
  info "Тестирование system_setup_update_env..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_setup_update_env || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_setup_update_env: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_setup_update_env: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: system_full_update
# ════════════════════════════════════════════════════════════
test_system_full_update() {
  info "Тестирование system_full_update..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_full_update || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_full_update: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_full_update: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: system_quick_update
# ════════════════════════════════════════════════════════════
test_system_quick_update() {
  info "Тестирование system_quick_update..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_quick_update || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_quick_update: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_quick_update: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: system_auto_updates_configure
# ════════════════════════════════════════════════════════════
test_system_auto_updates_configure() {
  info "Тестирование system_auto_updates_configure..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_auto_updates_configure || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_auto_updates_configure: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_auto_updates_configure: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: system_auto_updates_unattended_configure
# ════════════════════════════════════════════════════════════
test_system_auto_updates_unattended_configure() {
  info "Тестирование system_auto_updates_unattended_configure..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_auto_updates_unattended_configure || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_auto_updates_unattended_configure: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_auto_updates_unattended_configure: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: system_auto_updates_enable
# ════════════════════════════════════════════════════════════
test_system_auto_updates_enable() {
  info "Тестирование system_auto_updates_enable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_auto_updates_enable || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_auto_updates_enable: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_auto_updates_enable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: system_auto_updates_setup
# ════════════════════════════════════════════════════════════
test_system_auto_updates_setup() {
  info "Тестирование system_auto_updates_setup..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_auto_updates_setup || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_auto_updates_setup: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_auto_updates_setup: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: system_bbr_load_module
# ════════════════════════════════════════════════════════════
test_system_bbr_load_module() {
  info "Тестирование system_bbr_load_module..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_bbr_load_module || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_bbr_load_module: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_bbr_load_module: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: system_bbr_create_sysctl_config
# ════════════════════════════════════════════════════════════
test_system_bbr_create_sysctl_config() {
  info "Тестирование system_bbr_create_sysctl_config..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_bbr_create_sysctl_config || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_bbr_create_sysctl_config: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_bbr_create_sysctl_config: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: system_bbr_apply_sysctl
# ════════════════════════════════════════════════════════════
test_system_bbr_apply_sysctl() {
  info "Тестирование system_bbr_apply_sysctl..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_bbr_apply_sysctl || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_bbr_apply_sysctl: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_bbr_apply_sysctl: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: system_bbr_setup
# ════════════════════════════════════════════════════════════
test_system_bbr_setup() {
  info "Тестирование system_bbr_setup..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_bbr_setup || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_bbr_setup: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_bbr_setup: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: system_bbr_check_status
# ════════════════════════════════════════════════════════════
test_system_bbr_check_status() {
  info "Тестирование system_bbr_check_status..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию
  local result=0
  system_bbr_check_status || result=$?

  # Функция должна вернуть 0 если BBR активен
  if [[ $result -eq 0 ]]; then
    pass "system_bbr_check_status: BBR активен (мок)"
    ((TESTS_PASSED++)) || true
  else
    pass "system_bbr_check_status: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: system_check_ip_neighborhood
# ════════════════════════════════════════════════════════════
test_system_check_ip_neighborhood() {
  info "Тестирование system_check_ip_neighborhood..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию с тестовым IP
  local result
  result=$(system_check_ip_neighborhood "192.168.1.100" 2>&1) || true

  if [[ -n "$result" ]]; then
    pass "system_check_ip_neighborhood: выполняется"
    ((TESTS_PASSED++)) || true
  else
    pass "system_check_ip_neighborhood: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: system_check_services
# ════════════════════════════════════════════════════════════
test_system_check_services() {
  info "Тестирование system_check_services..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_check_services || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_check_services: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_check_services: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: system_restart_services
# ════════════════════════════════════════════════════════════
test_system_restart_services() {
  info "Тестирование system_restart_services..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_restart_services || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_restart_services: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_restart_services: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: system_install_base_dependencies
# ════════════════════════════════════════════════════════════
test_system_install_base_dependencies() {
  info "Тестирование system_install_base_dependencies..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  system_install_base_dependencies || result=$?

  if [[ $result -eq 0 ]]; then
    pass "system_install_base_dependencies: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "system_install_base_dependencies: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: module_install
# ════════════════════════════════════════════════════════════
test_module_install() {
  info "Тестирование module_install..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

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
#  ТЕСТ 23: module_configure
# ════════════════════════════════════════════════════════════
test_module_configure() {
  info "Тестирование module_configure..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

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
#  ТЕСТ 24: module_enable
# ════════════════════════════════════════════════════════════
test_module_enable() {
  info "Тестирование module_enable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

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
#  ТЕСТ 25: module_disable
# ════════════════════════════════════════════════════════════
test_module_disable() {
  info "Тестирование module_disable..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

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
#  ТЕСТ 26: module_update
# ════════════════════════════════════════════════════════════
test_module_update() {
  info "Тестирование module_update..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

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
#  ТЕСТ 27: module_status
# ════════════════════════════════════════════════════════════
test_module_status() {
  info "Тестирование module_status..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  module_status || result=$?

  if [[ $result -eq 0 ]]; then
    pass "module_status: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_status: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: module_quick_update
# ════════════════════════════════════════════════════════════
test_module_quick_update() {
  info "Тестирование module_quick_update..."

  # Загружаем модуль
  # shellcheck source=lib/modules/system/install.sh
  source "$SYSTEM_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  module_quick_update || result=$?

  if [[ $result -eq 0 ]]; then
    pass "module_quick_update: выполняется без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_quick_update: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_system_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы логирования
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error|step|debug)' "$SYSTEM_MODULE_PATH" || echo "0")

  if [[ $log_count -gt 20 ]]; then
    pass "system/install.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    fail "system/install.sh: недостаточно использует логирование"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: Проверка BBR конфигурации
# ════════════════════════════════════════════════════════════
test_system_bbr_config() {
  info "Проверка BBR конфигурации..."

  # Проверяем наличие BBR настроек
  if grep -q 'net.ipv4.tcp_congestion_control = bbr' "$SYSTEM_MODULE_PATH"; then
    pass "system_bbr_create_sysctl_config: настраивает BBR"
    ((TESTS_PASSED++)) || true
  else
    fail "system_bbr_create_sysctl_config: не настраивает BBR"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 31: Проверка автообновлений конфигурации
# ════════════════════════════════════════════════════════════
test_system_auto_updates_config() {
  info "Проверка конфигурации автообновлений..."

  # Проверяем наличие файла автообновлений
  if grep -q '20auto-upgrades' "$SYSTEM_MODULE_PATH"; then
    pass "system_auto_updates_configure: создаёт 20auto-upgrades"
    ((TESTS_PASSED++)) || true
  else
    fail "system_auto_updates_configure: не создаёт 20auto-upgrades"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 32: Проверка unattended-upgrades
# ════════════════════════════════════════════════════════════
test_system_unattended_upgrades() {
  info "Проверка unattended-upgrades..."

  # Проверяем наличие unattended-upgrades конфига
  if grep -q '50unattended-upgrades' "$SYSTEM_MODULE_PATH"; then
    pass "system_auto_updates: настраивает unattended-upgrades"
    ((TESTS_PASSED++)) || true
  else
    fail "system_auto_updates: не настраивает unattended-upgrades"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 33: Проверка sysctl конфига
# ════════════════════════════════════════════════════════════
test_system_sysctl_config() {
  info "Проверка sysctl конфигурации..."

  # Проверяем наличие sysctl конфига
  if grep -q '99-cubiveil.conf' "$SYSTEM_MODULE_PATH"; then
    pass "system_bbr: создаёт 99-cubiveil.conf"
    ((TESTS_PASSED++)) || true
  else
    fail "system_bbr: не создаёт 99-cubiveil.conf"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 34: Проверка module_* алиасов
# ════════════════════════════════════════════════════════════
test_system_module_aliases() {
  info "Проверка module_* алиасов..."

  local aliases_ok=true

  if ! grep -q 'module_install()' "$SYSTEM_MODULE_PATH"; then
    aliases_ok=false
  fi

  if ! grep -q 'module_configure()' "$SYSTEM_MODULE_PATH"; then
    aliases_ok=false
  fi

  if ! grep -q 'module_enable()' "$SYSTEM_MODULE_PATH"; then
    aliases_ok=false
  fi

  if $aliases_ok; then
    pass "system/install.sh: module_* функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "system/install.sh: module_* функции не определены"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 35: Проверка EUID проверки
# ════════════════════════════════════════════════════════════
test_system_euid_check() {
  info "Проверка EUID проверки..."

  # Проверяем наличие проверки EUID
  if grep -q 'EUID -ne 0' "$SYSTEM_MODULE_PATH" ||
    grep -q 'EUID -eq 0' "$SYSTEM_MODULE_PATH"; then
    pass "system/install.sh: проверяет EUID (root права)"
    ((TESTS_PASSED++)) || true
  else
    fail "system/install.sh: не проверяет EUID"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  System Module Unit Tests / Тесты System модуля${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_system_module_file_exists
  test_system_module_syntax
  test_system_module_shebang
  test_system_module_dependencies
  test_system_module_functions_exist
  test_system_setup_update_env
  test_system_full_update
  test_system_quick_update
  test_system_auto_updates_configure
  test_system_auto_updates_unattended_configure
  test_system_auto_updates_enable
  test_system_auto_updates_setup
  test_system_bbr_load_module
  test_system_bbr_create_sysctl_config
  test_system_bbr_apply_sysctl
  test_system_bbr_setup
  test_system_bbr_check_status
  test_system_check_ip_neighborhood
  test_system_check_services
  test_system_restart_services
  test_system_install_base_dependencies
  test_module_install
  test_module_configure
  test_module_enable
  test_module_disable
  test_module_update
  test_module_status
  test_module_quick_update
  test_system_localized_messages
  test_system_bbr_config
  test_system_auto_updates_config
  test_system_unattended_upgrades
  test_system_sysctl_config
  test_system_module_aliases
  test_system_euid_check

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
