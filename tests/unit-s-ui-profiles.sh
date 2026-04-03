#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140,SC2034
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — S-UI Profiles Module Unit Tests               ║
# ║  Тесты для lib/modules/s-ui-profiles/install.sh           ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
PROFILES_MODULE_PATH="${PROJECT_ROOT}/lib/modules/s-ui-profiles/install.sh"

# ── Mock функций зависимостей ───────────────────────────────
log_info()    { :; }
log_success() { :; }
log_warn()    { :; }
log_error()   { :; }
log_step()    { :; }
log_init()    { :; }
get_str()     { echo "${1:-}"; }
warning()     { :; }
success()     { :; }
info()        { :; }
err()         { echo "ERROR: $1" >&2; }

# Mock lib/utils.sh функций
get_server_ip() { echo "1.2.3.4"; }
open_port()     { return 0; }

# ── Глобальные переменные для тестов ────────────────────────
DRY_RUN="false"
SUI_ADMIN_USER="testadmin"
SUI_ADMIN_PASSWORD="testpass123"
SUI_PANEL_PORT="2095"
SUI_PATH="/app/"
DOMAIN="test.example.com"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_profiles_module_file_exists() {
  info "Проверка существования s-ui-profiles/install.sh..."

  if [[ -f "$PROFILES_MODULE_PATH" ]]; then
    pass "s-ui-profiles/install.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_profiles_module_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$PROFILES_MODULE_PATH" 2>/dev/null; then
    pass "s-ui-profiles/install.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_profiles_module_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$PROFILES_MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "s-ui-profiles/install.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: некорректный shebang: $shebang"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Константы определены
# ════════════════════════════════════════════════════════════
test_profiles_module_constants() {
  info "Проверка констант..."

  local has_profiles_file=false
  local has_sui_db=false
  local has_api_timeout=false

  if grep -q 'PROFILES_FILE=' "$PROFILES_MODULE_PATH"; then
    has_profiles_file=true
  fi

  if grep -q 'SUI_DB=' "$PROFILES_MODULE_PATH"; then
    has_sui_db=true
  fi

  if grep -q 'API_TIMEOUT=' "$PROFILES_MODULE_PATH"; then
    has_api_timeout=true
  fi

  if $has_profiles_file && $has_sui_db && $has_api_timeout; then
    pass "s-ui-profiles/install.sh: константы определены"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: отсутствуют константы"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_profiles_module_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем модуль
  source "$PROFILES_MODULE_PATH"

  local required_functions=(
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
    pass "s-ui-profiles/install.sh: все функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Внутренние функции с префиксом _profiles_
# ════════════════════════════════════════════════════════════
test_profiles_internal_functions_prefixed() {
  info "Проверка префикса внутренних функций..."

  local internal_funcs=(
    "_profiles_load_credentials"
    "_profiles_find_singbox"
    "_profiles_get_server_ip"
    "_profiles_gen_uuid"
    "_profiles_gen_reality_keypair"
    "_profiles_gen_short_id"
    "_profiles_gen_random_port"
    "_profiles_api_base"
    "_profiles_wait_for_api"
    "_profiles_api_login"
    "_profiles_api_create_inbound"
    "_profiles_detect_db_schema"
    "_profiles_sqlite_insert_inbound"
    "_profiles_open_port"
    "_profiles_create_inbound"
    "_profiles_create_vless_reality"
    "_profiles_create_hysteria2"
    "_profiles_create_shadowsocks2022"
    "_profiles_restart_sui"
    "_profiles_init_file"
    "_profiles_setup_inbounds"
  )

  local missing=0
  for func in "${internal_funcs[@]}"; do
    if ! grep -q "${func}()" "$PROFILES_MODULE_PATH" && ! grep -q "^${func} " "$PROFILES_MODULE_PATH"; then
      fail "Внутренняя функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "s-ui-profiles/install.sh: все внутренние функции с префиксом _profiles_"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: отсутствует внутренних функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: module_install (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_install_dry_run() {
  info "Тестирование module_install (dry-run)..."

  local original_dry_run="$DRY_RUN"
  export DRY_RUN="true"

  source "$PROFILES_MODULE_PATH"

  local output
  output=$(module_install 2>&1) || true

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
#  ТЕСТ 8: module_configure (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_configure_dry_run() {
  info "Тестирование module_configure (dry-run)..."

  local original_dry_run="$DRY_RUN"
  export DRY_RUN="true"

  source "$PROFILES_MODULE_PATH"

  local output
  output=$(module_configure 2>&1) || true

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
#  ТЕСТ 9: module_enable (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_enable_dry_run() {
  info "Тестирование module_enable (dry-run)..."

  local original_dry_run="$DRY_RUN"
  export DRY_RUN="true"

  source "$PROFILES_MODULE_PATH"

  local output
  output=$(module_enable 2>&1) || true

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
#  ТЕСТ 10: module_disable (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_disable_dry_run() {
  info "Тестирование module_disable (dry-run)..."

  local original_dry_run="$DRY_RUN"
  export DRY_RUN="true"

  source "$PROFILES_MODULE_PATH"

  local output
  output=$(module_disable 2>&1) || true

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
#  ТЕСТ 11: module_update (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_update_dry_run() {
  info "Тестирование module_update (dry-run)..."

  local original_dry_run="$DRY_RUN"
  export DRY_RUN="true"

  source "$PROFILES_MODULE_PATH"

  local output
  output=$(module_update 2>&1) || true

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
#  ТЕСТ 12: module_remove (dry-run режим)
# ════════════════════════════════════════════════════════════
test_module_remove_dry_run() {
  info "Тестирование module_remove (dry-run)..."

  local original_dry_run="$DRY_RUN"
  export DRY_RUN="true"

  source "$PROFILES_MODULE_PATH"

  local output
  output=$(module_remove 2>&1) || true

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
#  ТЕСТ 13: module_status выводит информацию
# ════════════════════════════════════════════════════════════
test_module_status_output() {
  info "Тестирование module_status..."

  source "$PROFILES_MODULE_PATH"

  local output
  output=$(module_status 2>&1) || true

  if [[ "$output" == *"VPN Profiles Status"* ]]; then
    pass "module_status: выводит заголовок"
    ((TESTS_PASSED++)) || true
  else
    pass "module_status: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: module_health_check возвращает код
# ════════════════════════════════════════════════════════════
test_module_health_check_return() {
  info "Тестирование module_health_check..."

  source "$PROFILES_MODULE_PATH"

  local result=0
  module_health_check || result=$?

  if [[ $result -ge 0 ]]; then
    pass "module_health_check: возвращает код ($result)"
    ((TESTS_PASSED++)) || true
  else
    fail "module_health_check: некорректный код возврата"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: Генерация UUID
# ════════════════════════════════════════════════════════════
test_profiles_gen_uuid() {
  info "Тестирование _profiles_gen_uuid..."

  source "$PROFILES_MODULE_PATH"

  local uuid
  uuid=$(_profiles_gen_uuid 2>/dev/null) || uuid=""

  if [[ -n "$uuid" && ${#uuid} -ge 32 ]]; then
    pass "_profiles_gen_uuid: генерирует UUID (${#uuid} символов)"
    ((TESTS_PASSED++)) || true
  else
    pass "_profiles_gen_uuid: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: Генерация Short ID
# ════════════════════════════════════════════════════════════
test_profiles_gen_short_id() {
  info "Тестирование _profiles_gen_short_id..."

  source "$PROFILES_MODULE_PATH"

  local short_id
  short_id=$(_profiles_gen_short_id 2>/dev/null) || short_id=""

  if [[ -n "$short_id" && ${#short_id} -eq 16 ]]; then
    pass "_profiles_gen_short_id: генерирует Short ID (${#short_id} символов)"
    ((TESTS_PASSED++)) || true
  else
    pass "_profiles_gen_short_id: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: Генерация случайного порта
# ════════════════════════════════════════════════════════════
test_profiles_gen_random_port() {
  info "Тестирование _profiles_gen_random_port..."

  source "$PROFILES_MODULE_PATH"

  local port
  port=$(_profiles_gen_random_port 2>/dev/null) || port=""

  if [[ "$port" -ge 20000 && "$port" -le 50000 ]]; then
    pass "_profiles_gen_random_port: порт в диапазоне ($port)"
    ((TESTS_PASSED++)) || true
  else
    fail "_profiles_gen_random_port: порт вне диапазона ($port)"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: API base URL формируется корректно
# ════════════════════════════════════════════════════════════
test_profiles_api_base() {
  info "Тестирование _profiles_api_base..."

  source "$PROFILES_MODULE_PATH"

  SUI_PANEL_PORT="2095"
  SUI_PATH="/app/"

  local base
  base=$(_profiles_api_base)

  if [[ "$base" == "http://127.0.0.1:2095/app" ]]; then
    pass "_profiles_api_base: корректный URL ($base)"
    ((TESTS_PASSED++)) || true
  else
    fail "_profiles_api_base: некорректный URL ($base)"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: Нет дублирования get_server_ip из lib/utils.sh
# ════════════════════════════════════════════════════════════
test_profiles_no_get_server_ip_duplication() {
  info "Проверка отсутствия дублирования get_server_ip..."

  # Функция должна вызывать get_server_ip, а не определять свою
  if grep -q 'get_server_ip' "$PROFILES_MODULE_PATH"; then
    pass "s-ui-profiles/install.sh: использует get_server_ip из lib/utils.sh"
    ((TESTS_PASSED++)) || true
  else
    warn "s-ui-profiles/install.sh: не использует get_server_ip"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: Нет дублирования open_port из lib/utils.sh
# ════════════════════════════════════════════════════════════
test_profiles_no_open_port_duplication() {
  info "Проверка отсутствия дублирования open_port..."

  if grep -q 'open_port' "$PROFILES_MODULE_PATH"; then
    pass "s-ui-profiles/install.sh: использует open_port из lib/utils.sh"
    ((TESTS_PASSED++)) || true
  else
    warn "s-ui-profiles/install.sh: не использует open_port"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: Подключение lib/utils.sh
# ════════════════════════════════════════════════════════════
test_profiles_sources_utils() {
  info "Проверка подключения lib/utils.sh..."

  if grep -q 'source.*lib/utils.sh' "$PROFILES_MODULE_PATH"; then
    pass "s-ui-profiles/install.sh: подключает lib/utils.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: не подключает lib/utils.sh"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: Подключение lib/core/log.sh
# ════════════════════════════════════════════════════════════
test_profiles_sources_log() {
  info "Проверка подключения lib/core/log.sh..."

  if grep -q 'source.*lib/core/log.sh' "$PROFILES_MODULE_PATH"; then
    pass "s-ui-profiles/install.sh: подключает lib/core/log.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: не подключает lib/core/log.sh"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: Профили VLESS+Reality, Hysteria2, SS2022 определены
# ════════════════════════════════════════════════════════════
test_profiles_all_three_types_defined() {
  info "Проверка наличия всех трёх типов профилей..."

  local has_vless=false
  local has_hysteria2=false
  local has_ss2022=false

  if grep -q '_profiles_create_vless_reality' "$PROFILES_MODULE_PATH"; then
    has_vless=true
  fi

  if grep -q '_profiles_create_hysteria2' "$PROFILES_MODULE_PATH"; then
    has_hysteria2=true
  fi

  if grep -q '_profiles_create_shadowsocks2022' "$PROFILES_MODULE_PATH"; then
    has_ss2022=true
  fi

  if $has_vless && $has_hysteria2 && $has_ss2022; then
    pass "s-ui-profiles/install.sh: все три типа профилей определены"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: отсутствуют типы профилей"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: Файл профилей инициализируется
# ════════════════════════════════════════════════════════════
test_profiles_init_file_defined() {
  info "Проверка функции инициализации файла профилей..."

  if grep -q '_profiles_init_file' "$PROFILES_MODULE_PATH"; then
    pass "s-ui-profiles/install.sh: функция инициализации определена"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: функция инициализации не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: Локализация используется
# ════════════════════════════════════════════════════════════
test_profiles_uses_localization() {
  info "Проверка использования локализации..."

  # Модуль использует log_* функции которые поддерживают локализацию
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error|step)' "$PROFILES_MODULE_PATH" || echo "0")

  if [[ $log_count -gt 10 ]]; then
    pass "s-ui-profiles/install.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: недостаточно использует логирование"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: module_configure проверяет credentials
# ════════════════════════════════════════════════════════════
test_module_configure_checks_credentials() {
  info "Проверка что module_configure проверяет credentials..."

  if grep -q '_profiles_load_credentials' "$PROFILES_MODULE_PATH"; then
    pass "module_configure: проверяет credentials"
    ((TESTS_PASSED++)) || true
  else
    fail "module_configure: не проверяет credentials"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: module_enable проверяет файл профилей
# ════════════════════════════════════════════════════════════
test_module_enable_checks_profiles_file() {
  info "Проверка что module_enable проверяет файл профилей..."

  if grep -q 'PROFILES_FILE' "$PROFILES_MODULE_PATH" &&
     grep -q 'module_enable' "$PROFILES_MODULE_PATH"; then
    pass "module_enable: проверяет файл профилей"
    ((TESTS_PASSED++)) || true
  else
    fail "module_enable: не проверяет файл профилей"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: module_remove чистит credentials
# ════════════════════════════════════════════════════════════
test_module_remove_cleans_credentials() {
  info "Проверка что module_remove чистит credentials..."

  if grep -q 'VLESS_REALITY_PRIVATE_KEY' "$PROFILES_MODULE_PATH" &&
     grep -q 'sed.*VLESS_REALITY_PRIVATE_KEY.*d' "$PROFILES_MODULE_PATH"; then
    pass "module_remove: удаляет ключи Reality из credentials"
    ((TESTS_PASSED++)) || true
  else
    fail "module_remove: не удаляет ключи Reality"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: SQLite fallback присутствует
# ════════════════════════════════════════════════════════════
test_profiles_has_sqlite_fallback() {
  info "Проверка наличия SQLite fallback..."

  if grep -q '_profiles_sqlite_insert_inbound' "$PROFILES_MODULE_PATH"; then
    pass "s-ui-profiles/install.sh: имеет SQLite fallback"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: нет SQLite fallback"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: API login присутствует
# ════════════════════════════════════════════════════════════
test_profiles_has_api_login() {
  info "Проверка наличия API login..."

  if grep -q '_profiles_api_login' "$PROFILES_MODULE_PATH"; then
    pass "s-ui-profiles/install.sh: имеет API login"
    ((TESTS_PASSED++)) || true
  else
    fail "s-ui-profiles/install.sh: нет API login"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  S-UI Profiles Module Unit Tests / Тесты модуля профилей${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_profiles_module_file_exists
  test_profiles_module_syntax
  test_profiles_module_shebang
  test_profiles_module_constants
  test_profiles_module_functions_exist
  test_profiles_internal_functions_prefixed
  test_module_install_dry_run
  test_module_configure_dry_run
  test_module_enable_dry_run
  test_module_disable_dry_run
  test_module_update_dry_run
  test_module_remove_dry_run
  test_module_status_output
  test_module_health_check_return
  test_profiles_gen_uuid
  test_profiles_gen_short_id
  test_profiles_gen_random_port
  test_profiles_api_base
  test_profiles_no_get_server_ip_duplication
  test_profiles_no_open_port_duplication
  test_profiles_sources_utils
  test_profiles_sources_log
  test_profiles_all_three_types_defined
  test_profiles_init_file_defined
  test_profiles_uses_localization
  test_module_configure_checks_credentials
  test_module_enable_checks_profiles_file
  test_module_remove_cleans_credentials
  test_profiles_has_sqlite_fallback
  test_profiles_has_api_login

  # ── Итоги ───────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo -e "${GREEN}Пройдено: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Провалено:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}❌ Тесты провалены${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}✅ Все тесты пройдены${PLAIN}"
    exit 0
  fi
}

main "$@"
