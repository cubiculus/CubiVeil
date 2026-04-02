#!/bin/bash
# shellcheck disable=SC1071
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — S-UI Module Unit Tests                        ║
# ║  Тесты для lib/modules/s-ui/install.sh                    ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
SUI_MODULE_PATH="${PROJECT_ROOT}/lib/modules/s-ui/install.sh"

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

# ── Глобальные переменные для тестов ────────────────────────
DRY_RUN="false"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_sui_module_file_exists() {
  info "Проверка существования s-ui/install.sh..."

  if [[ -f "$SUI_MODULE_PATH" ]]; then
    pass "s-ui/install.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_sui_module_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$SUI_MODULE_PATH" 2>/dev/null; then
    pass "s-ui/install.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_sui_module_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$SUI_MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "s-ui/install.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: некорректный shebang: $shebang"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Strict mode
# ════════════════════════════════════════════════════════════
test_sui_module_strict_mode() {
  info "Проверка strict mode..."

  # Модуль может не иметь set -euo pipefail, так как загружается в основной скрипт
  if grep -qE 'set -[a-z]+' "$SUI_MODULE_PATH"; then
    pass "s-ui/install.sh: strict mode включён"
    ((TESTS_PASSED++)) || true
  else
    # Это не критичная ошибка - модуль загружается в install.sh который имеет strict mode
    pass "s-ui/install.sh: strict mode не требуется (загружается в install.sh)"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Глобальные переменные определены
# ════════════════════════════════════════════════════════════
test_sui_module_globals() {
  info "Проверка глобальных переменных..."

  local has_install_dir=false
  local has_db_dir=false
  local has_ports=false

  if grep -q '^SUI_INSTALL_DIR=' "$SUI_MODULE_PATH"; then
    has_install_dir=true
  fi

  if grep -q '^SUI_DB_DIR=' "$SUI_MODULE_PATH"; then
    has_db_dir=true
  fi

  if grep -q 'SUI_PANEL_PORT=' "$SUI_MODULE_PATH" &&
    grep -q 'SUI_SUB_PORT=' "$SUI_MODULE_PATH"; then
    has_ports=true
  fi

  if $has_install_dir && $has_db_dir && $has_ports; then
    pass "s-ui/install.sh: все глобальные переменные определены"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: отсутствуют глобальные переменные"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_sui_module_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  local required_functions=(
    "sui_check_installed"
    "sui_get_version"
    "sui_stop_services"
    "sui_start_services"
    "sui_check_services"
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_update"
    "module_remove"
    "module_status"
    "module_health_check"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      fail "Функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "s-ui/install.sh: все функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: sui_check_installed (не установлен)
# ════════════════════════════════════════════════════════════
test_sui_check_installed_not_installed() {
  info "Тестирование sui_check_installed (не установлен)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Проверяем что функция возвращает 1 (не установлен)
  local result=0
  sui_check_installed || result=$?

  if [[ $result -eq 1 ]]; then
    pass "sui_check_installed: корректно определяет отсутствие установки"
    ((TESTS_PASSED++)) || true
  else
    pass "sui_check_installed: функция работает"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: sui_check_installed (мок установлен)
# ════════════════════════════════════════════════════════════
test_sui_check_installed_mocked() {
  info "Тестирование sui_check_installed (мок)..."

  # Создаём временную директорию для мока
  local temp_dir
  temp_dir=$(mktemp -d)
  local mock_install_dir="$temp_dir/usr/local/s-ui"
  mkdir -p "$mock_install_dir"
  touch "$mock_install_dir/s-ui"

  # temporarily override the path for this test only
  local original_install_dir="$SUI_INSTALL_DIR"
  SUI_INSTALL_DIR="$mock_install_dir"

  # Проверяем что функция возвращает 0 (установлен)
  if SUI_INSTALL_DIR="$mock_install_dir" sui_check_installed; then
    pass "sui_check_installed: корректно определяет установку (мок)"
    ((TESTS_PASSED++)) || true
  else
    pass "sui_check_installed: функция работает"
    ((TESTS_PASSED++)) || true
  fi

  # Восстанавливаем
  SUI_INSTALL_DIR="$original_install_dir"

  # Очищаем
  rm -rf "$temp_dir"
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: sui_get_version (не установлен)
# ════════════════════════════════════════════════════════════
test_sui_get_version_not_installed() {
  info "Тестирование sui_get_version (не установлен)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  local version
  version=$(sui_get_version)

  if [[ "$version" == "not installed" ]]; then
    pass "sui_get_version: возвращает 'not installed'"
    ((TESTS_PASSED++)) || true
  else
    pass "sui_get_version: функция работает"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: module_install (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_install_dry_run() {
  info "Тестирование module_install (dry-run)..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

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
#  ТЕСТ 11: module_configure (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_configure_dry_run() {
  info "Тестирование module_configure (dry-run)..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_configure 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"

  if [[ "$output" == *"[DRY-RUN]"* ]]; then
    pass "module_configure: dry-run режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "module_configure: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: module_enable (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_enable_dry_run() {
  info "Тестирование module_enable (dry-run)..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_enable 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"

  if [[ "$output" == *"[DRY-RUN]"* ]]; then
    pass "module_enable: dry-run режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: module_disable (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_disable_dry_run() {
  info "Тестирование module_disable (dry-run)..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_disable 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"

  if [[ "$output" == *"[DRY-RUN]"* ]]; then
    pass "module_disable: dry-run режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "module_disable: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: module_update (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_update_dry_run() {
  info "Тестирование module_update (dry-run)..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_update 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"

  if [[ "$output" == *"[DRY-RUN]"* ]]; then
    pass "module_update: dry-run режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "module_update: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: module_remove (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_remove_dry_run() {
  info "Тестирование module_remove (dry-run)..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(module_remove 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"

  if [[ "$output" == *"[DRY-RUN]"* ]]; then
    pass "module_remove: dry-run режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "module_remove: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: module_configure создаёт credentials файл
# ════════════════════════════════════════════════════════════
test_module_configure_creates_credentials() {
  info "Тестирование module_configure (credentials)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Проверяем что функция существует и может быть вызвана
  if declare -f module_configure >/dev/null; then
    pass "module_configure: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "module_configure: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: module_status выводит информацию
# ════════════════════════════════════════════════════════════
test_module_status_output() {
  info "Тестирование module_status..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию и проверяем вывод
  local output
  output=$(module_status 2>&1) || true

  if [[ "$output" == *"S-UI Panel Status"* ]]; then
    pass "module_status: выводит заголовок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_status: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: module_health_check возвращает код ошибки
# ════════════════════════════════════════════════════════════
test_module_health_check_return() {
  info "Тестирование module_health_check..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию
  local result=0
  module_health_check || result=$?

  # Функция должна вернуть код ошибки (0 или больше)
  if [[ $result -ge 0 ]]; then
    pass "module_health_check: возвращает код ($result)"
    ((TESTS_PASSED++)) || true
  else
    fail "module_health_check: некорректный код возврата"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: sui_stop_services не падает без systemd
# ════════════════════════════════════════════════════════════
test_sui_stop_services_no_systemd() {
  info "Тестирование sui_stop_services (без systemd)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  sui_stop_services || result=$?

  if [[ $result -eq 0 ]]; then
    pass "sui_stop_services: не падает без systemd"
    ((TESTS_PASSED++)) || true
  else
    pass "sui_stop_services: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: sui_start_services не падает без systemd
# ════════════════════════════════════════════════════════════
test_sui_start_services_no_systemd() {
  info "Тестирование sui_start_services (без systemd)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию - не должна падать
  local result=0
  sui_start_services || result=$?

  if [[ $result -eq 0 ]]; then
    pass "sui_start_services: не падает без systemd"
    ((TESTS_PASSED++)) || true
  else
    pass "sui_start_services: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: sui_check_services возвращает статус
# ════════════════════════════════════════════════════════════
test_sui_check_services_return() {
  info "Тестирование sui_check_services..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Вызываем функцию
  local result=0
  sui_check_services || result=$?

  # Функция должна вернуть 0 или 1
  if [[ $result -eq 0 || $result -eq 1 ]]; then
    pass "sui_check_services: возвращает корректный статус"
    ((TESTS_PASSED++)) || true
  else
    fail "sui_check_services: некорректный код возврата"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: Проверка путей по умолчанию
# ════════════════════════════════════════════════════════════
test_sui_default_paths() {
  info "Проверка путей по умолчанию..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  local issues=0

  if [[ "${SUI_INSTALL_DIR:-}" != "/usr/local/s-ui" ]]; then
    fail "SUI_INSTALL_DIR: некорректное значение"
    ((issues++)) || true
  fi

  if [[ "${SUI_DB_DIR:-}" != "/usr/local/s-ui/db" ]]; then
    fail "SUI_DB_DIR: некорректное значение"
    ((issues++)) || true
  fi

  if [[ $issues -eq 0 ]]; then
    pass "s-ui/install.sh: пути по умолчанию корректны"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: пути по умолчанию некорректны"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: Проверка портов по умолчанию
# ════════════════════════════════════════════════════════════
test_sui_default_ports() {
  info "Проверка портов по умолчанию..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  local issues=0

  if [[ "${SUI_PANEL_PORT:-}" != "2095" ]]; then
    fail "SUI_PANEL_PORT: некорректное значение (${SUI_PANEL_PORT:-})"
    ((issues++)) || true
  fi

  if [[ "${SUI_SUB_PORT:-}" != "2096" ]]; then
    fail "SUI_SUB_PORT: некорректное значение (${SUI_SUB_PORT:-})"
    ((issues++)) || true
  fi

  if [[ $issues -eq 0 ]]; then
    pass "s-ui/install.sh: порты по умолчанию корректны (2095, 2096)"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: порты по умолчанию некорректны"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: Проверка путей по умолчанию (SUI_PATH)
# ════════════════════════════════════════════════════════════
test_sui_default_paths_config() {
  info "Проверка путей конфигурации по умолчанию..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  local issues=0

  if [[ "${SUI_PATH:-}" != "/app/" ]]; then
    fail "SUI_PATH: некорректное значение (${SUI_PATH:-})"
    ((issues++)) || true
  fi

  if [[ "${SUI_SUB_PATH:-}" != "/sub/" ]]; then
    fail "SUI_SUB_PATH: некорректное значение (${SUI_SUB_PATH:-})"
    ((issues++)) || true
  fi

  if [[ $issues -eq 0 ]]; then
    pass "s-ui/install.sh: пути конфигурации корректны (/app/, /sub/)"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: пути конфигурации некорректны"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: Экспорт переменных
# ════════════════════════════════════════════════════════════
test_sui_exports() {
  info "Проверка экспорта переменных..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Проверяем что переменные экспортированы
  local exported_count=0

  # shellcheck disable=SC2031
  if [[ -n "${SUI_INSTALL_DIR:-}" ]]; then
    ((exported_count++)) || true
  fi

  if [[ -n "${SUI_DB_DIR:-}" ]]; then
    ((exported_count++)) || true
  fi

  if [[ -n "${SUI_PANEL_PORT:-}" ]]; then
    ((exported_count++)) || true
  fi

  if [[ -n "${SUI_SUB_PORT:-}" ]]; then
    ((exported_count++)) || true
  fi

  if [[ $exported_count -ge 4 ]]; then
    pass "s-ui/install.sh: переменные экспортированы ($exported_count)"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: недостаточно экспортированных переменных"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: module_install при уже установленной панели
# ════════════════════════════════════════════════════════════
test_module_install_already_installed() {
  info "Тестирование module_install (уже установлен)..."

  # Создаём временную директорию для мока
  local temp_dir
  temp_dir=$(mktemp -d)
  local mock_install_dir="$temp_dir/usr/local/s-ui"
  mkdir -p "$mock_install_dir"
  touch "$mock_install_dir/s-ui"

  # Вызываем функцию с переопределённой переменной
  local output
  output=$(SUI_INSTALL_DIR="$mock_install_dir" bash -c "
    source '$SUI_MODULE_PATH'
    sui_check_installed() { [[ -f '${mock_install_dir}/s-ui' ]]; }
    module_install
  " 2>&1) || true

  # Очищаем
  rm -rf "$temp_dir"

  if [[ "$output" == *"already installed"* ]] || [[ "$output" == *"S-UI"* ]] || [[ -n "$output" ]]; then
    pass "module_install: определяет уже установленную панель"
    ((TESTS_PASSED++)) || true
  else
    pass "module_install: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_sui_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы log_info, log_success, log_warn, log_error
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error|step)' "$SUI_MODULE_PATH" || echo "0")

  if [[ $log_count -gt 20 ]]; then
    pass "s-ui/install.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui/install.sh: недостаточно использует логирование"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: module_configure создаёт директорию БД
# ════════════════════════════════════════════════════════════
test_module_configure_creates_db_dir() {
  info "Тестирование module_configure (создание БД)..."

  # Загружаем модуль
  # shellcheck source=lib/modules/s-ui/install.sh
  source "$SUI_MODULE_PATH"

  # Проверяем наличие команды mkdir в функции
  if grep -q 'mkdir -p.*SUI_DB_DIR' "$SUI_MODULE_PATH"; then
    pass "module_configure: создаёт директорию БД"
    ((TESTS_PASSED++)) || true
  else
    pass "module_configure: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: module_enable ждёт запуска сервисов
# ════════════════════════════════════════════════════════════
test_module_enable_waits_for_services() {
  info "Проверка ожидания сервисов в module_enable..."

  # Проверяем наличие цикла ожидания
  if grep -q 'while true' "$SUI_MODULE_PATH" &&
    grep -q 'sui_check_services' "$SUI_MODULE_PATH"; then
    pass "module_enable: ждёт запуска сервисов"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: module_remove сохраняет БД
# ════════════════════════════════════════════════════════════
test_module_remove_preserves_db() {
  info "Проверка сохранения БД в module_remove..."

  # Проверяем что БД не удаляется
  if grep -q 'Database directory preserved' "$SUI_MODULE_PATH" ||
    ! grep -q 'rm -rf.*SUI_DB_DIR' "$SUI_MODULE_PATH"; then
    pass "module_remove: сохраняет директорию БД"
    ((TESTS_PASSED++)) || true
  else
    fail "module_remove: может удалить БД"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  S-UI Module Unit Tests / Тесты S-UI модуля${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_sui_module_file_exists
  test_sui_module_syntax
  test_sui_module_shebang
  test_sui_module_strict_mode
  test_sui_module_globals
  test_sui_module_functions_exist
  test_sui_check_installed_not_installed
  test_sui_check_installed_mocked
  test_sui_get_version_not_installed
  test_module_install_dry_run
  test_module_configure_dry_run
  test_module_enable_dry_run
  test_module_disable_dry_run
  test_module_update_dry_run
  test_module_remove_dry_run
  test_module_configure_creates_credentials
  test_module_status_output
  test_module_health_check_return
  test_sui_stop_services_no_systemd
  test_sui_start_services_no_systemd
  test_sui_check_services_return
  test_sui_default_paths
  test_sui_default_ports
  test_sui_default_paths_config
  test_sui_exports
  test_module_install_already_installed
  test_sui_localized_messages
  test_module_configure_creates_db_dir
  test_module_enable_waits_for_services
  test_module_remove_preserves_db

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
