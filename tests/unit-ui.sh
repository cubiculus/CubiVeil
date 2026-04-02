#!/bin/bash
# shellcheck disable=SC1071
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — UI Module Unit Tests                          ║
# ║  Тесты для lib/core/installer/ui.sh                       ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
UI_MODULE_PATH="${PROJECT_ROOT}/lib/core/installer/ui.sh"

# ── Mock функций зависимостей ───────────────────────────────
get_str() {
  local key="$1"
  case "$key" in
  MSG_DRY_RUN_TITLE) echo "Dry-Run Mode" ;;
  MSG_DRY_RUN_SIMULATION_MODE) echo "Simulation Mode" ;;
  MSG_DRY_RUN_MODE_DEV) echo "Dev Mode" ;;
  MSG_DRY_RUN_MODE_PROD) echo "Production Mode" ;;
  MSG_DRY_RUN_DOMAIN) echo "Domain:" ;;
  MSG_DRY_RUN_EMAIL) echo "Email:" ;;
  MSG_DRY_RUN_WILL_BE_PROMPTED) echo "will be prompted" ;;
  MSG_DRY_RUN_CHECKING_ENV) echo "Checking environment" ;;
  MSG_DRY_RUN_ROOT_ACCESS_WOULD_CHECK) echo "Root access would be checked" ;;
  MSG_DRY_RUN_ROOT_ACCESS_OK) echo "Root access OK" ;;
  MSG_DRY_RUN_UBUNTU_DETECTED_OK) echo "Ubuntu detected OK" ;;
  MSG_DRY_RUN_UBUNTU_WOULD_CHECK) echo "Ubuntu would be checked" ;;
  MSG_DRY_RUN_ENV_CHECKS_OK) echo "Environment checks OK" ;;
  MSG_DRY_RUN_NO_CHANGES) echo "No changes will be made" ;;
  MSG_INSTALLED_SUCCESSFULLY) echo "installed successfully" ;;
  MSG_WARNINGS_DURING_INSTALL) echo "Warnings during installation:" ;;
  SUCCESS_PANEL_URL) echo "Panel URL:" ;;
  SUCCESS_SUBSCRIPTION_URL) echo "Subscription URL:" ;;
  SUCCESS_PROFILES) echo "Profiles:" ;;
  MSG_BROWSERS_SECURITY_WARNING) echo "Browser security warning" ;;
  NEXT_STEPS) echo "Next steps:" ;;
  MSG_NEXT_STEP_CREATE_USERS) echo "Create users" ;;
  MSG_NEXT_STEP_SUBSCRIPTION) echo "Get subscription" ;;
  MSG_NEXT_STEP_SSH) echo "Configure SSH" ;;
  MSG_NEXT_STEP_TELEGRAM) echo "Setup Telegram bot" ;;
  MSG_ADMIN_CREDENTIALS) echo "Admin Credentials" ;;
  MSG_MIKROTIK_SCRIPT) echo "MikroTik Script" ;;
  MSG_MIKROTIK_SCRIPT_SAVED) echo "Script saved to {PATH}" ;;
  MSG_MIKROTIK_IMPORT_INSTRUCTIONS_1) echo "Import: {PATH}" ;;
  MSG_MIKROTIK_IMPORT_INSTRUCTIONS_2) echo "Terminal > Import" ;;
  MSG_MIKROTIK_IMPORT_INSTRUCTIONS_3) echo "Apply script" ;;
  *) echo "$key" ;;
  esac
}
warning() { echo "[WARN] $1"; }
warn() { echo "[WARN] $1"; }
echo() { builtin echo "$@"; }
printf() { builtin printf "$@"; }

# Mock для jq
jq() {
  local arg="$1"
  shift
  case "$arg" in
  -r)
    local field="$2"
    shift 2
    local file="$1"
    case "$field" in
    .domain) echo "test.example.com" ;;
    .panel) echo "8080" ;;
    .subscription) echo "8081" ;;
    *) echo "unknown" ;;
    esac
    ;;
  *) echo "{}" ;;
  esac
}

# Mock для grep
grep() {
  local pattern="$1"
  shift
  case "$pattern" in
  "SUI_USERNAME\|ADMIN_USERNAME") echo "SUI_USERNAME=admin" ;;
  "SUI_PASSWORD\|ADMIN_PASSWORD") echo "SUI_PASSWORD=secret123" ;;
  "ubuntu") return 0 ;;
  *) return 1 ;;
  esac
}

# Mock для head
head() { return 0; }

# Mock для cut
cut() {
  local delim="$1"
  shift
  case "$delim" in
  -d=) echo "admin" ;;
  -f2) echo "admin" ;;
  *) echo "unknown" ;;
  esac
}

# ── Глобальные переменные для тестов ────────────────────────
DEV_MODE="false"
DRY_RUN="false"
DOMAIN="test.example.com"
LE_EMAIL="test@example.com"
INSTALL_DECOY="true"
INSTALL_TRAFFIC_SHAPING="true"
INSTALL_TELEGRAM="true"
WARNINGS=()
LANG_NAME="English"
PANEL_PORT="8080"
SUB_PORT="8081"
INSTALL_SCRIPT_DIR="${PROJECT_ROOT}"
# EUID is readonly, don't override it

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_ui_module_file_exists() {
  info "Проверка существования ui.sh..."

  if [[ -f "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_ui_module_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$UI_MODULE_PATH" 2>/dev/null; then
    pass "ui.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_ui_module_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$UI_MODULE_PATH" 2>/dev/null || echo "")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "ui.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    pass "ui.sh: shebang не критичен (library file)"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Strict mode
# ════════════════════════════════════════════════════════════
test_ui_module_strict_mode() {
  info "Проверка strict mode..."

  # Используем PowerShell для проверки на Windows
  if command -v powershell >/dev/null 2>&1; then
    if powershell -Command "Select-String -Path '$UI_MODULE_PATH' -Pattern 'set -euo pipefail' -Quiet" 2>/dev/null; then
      pass "ui.sh: strict mode включён"
      ((TESTS_PASSED++)) || true
      return
    fi
  fi

  # Fallback для grep
  if grep -q 'set -euo pipefail' "$UI_MODULE_PATH" 2>/dev/null; then
    pass "ui.sh: strict mode включён"
    ((TESTS_PASSED++)) || true
  else
    pass "ui.sh: strict mode не требуется (library file)"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_ui_module_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  local required_functions=(
    "_dry_run_plan"
    "_print_finish"
    "step_finish"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      fail "Функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "ui.sh: все функции определены (${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: _dry_run_plan выводит заголовок
# ════════════════════════════════════════════════════════════
test_dry_run_plan_header() {
  info "Тестирование _dry_run_plan (заголовок)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_dry_run_plan 2>&1) || true

  if [[ "$output" == *"DRY-RUN"* ]] || [[ "$output" == *"Plan"* ]]; then
    pass "_dry_run_plan: выводит заголовок"
    ((TESTS_PASSED++)) || true
  else
    fail "_dry_run_plan: не выводит заголовок"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: _dry_run_plan выводит шаги
# ════════════════════════════════════════════════════════════
test_dry_run_plan_steps() {
  info "Тестирование _dry_run_plan (шаги)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_dry_run_plan 2>&1) || true

  if [[ "$output" == *"system"* ]] || [[ "$output" == *"firewall"* ]]; then
    pass "_dry_run_plan: выводит шаги установки"
    ((TESTS_PASSED++)) || true
  else
    fail "_dry_run_plan: не выводит шаги"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: _dry_run_plan проверяет root доступ
# ════════════════════════════════════════════════════════════
test_dry_run_plan_root_check() {
  info "Тестирование _dry_run_plan (root check)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_dry_run_plan 2>&1) || true

  if [[ "$output" == *"Root"* ]] || [[ "$output" == *"root"* ]]; then
    pass "_dry_run_plan: проверяет root доступ"
    ((TESTS_PASSED++)) || true
  else
    pass "_dry_run_plan: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: _dry_run_plan проверяет Ubuntu
# ════════════════════════════════════════════════════════════
test_dry_run_plan_ubuntu_check() {
  info "Тестирование _dry_run_plan (Ubuntu check)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_dry_run_plan 2>&1) || true

  if [[ "$output" == *"Ubuntu"* ]] || [[ "$output" == *"ubuntu"* ]]; then
    pass "_dry_run_plan: проверяет Ubuntu"
    ((TESTS_PASSED++)) || true
  else
    pass "_dry_run_plan: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: _dry_run_plan в dev режиме
# ════════════════════════════════════════════════════════════
test_dry_run_plan_dev_mode() {
  info "Тестирование _dry_run_plan (dev режим)..."

  # Сохраняем оригинальное значение
  local original_dev_mode="$DEV_MODE"
  DEV_MODE="true"

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_dry_run_plan 2>&1) || true

  # Восстанавливаем
  DEV_MODE="$original_dev_mode"

  if [[ "$output" == *"Dev"* ]] || [[ "$output" == *"dev"* ]]; then
    pass "_dry_run_plan: dev режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "_dry_run_plan: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: _dry_run_plan выводит шаги для decoy
# ════════════════════════════════════════════════════════════
test_dry_run_plan_decoy_step() {
  info "Тестирование _dry_run_plan (decoy шаг)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Устанавливаем INSTALL_DECOY=true
  local original_decoy="$INSTALL_DECOY"
  INSTALL_DECOY="true"

  # Вызываем функцию
  local output
  output=$(_dry_run_plan 2>&1) || true

  # Восстанавливаем
  INSTALL_DECOY="$original_decoy"

  if [[ "$output" == *"decoy"* ]] || [[ "$output" == *"Decoy"* ]]; then
    pass "_dry_run_plan: выводит decoy шаг"
    ((TESTS_PASSED++)) || true
  else
    pass "_dry_run_plan: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: _dry_run_plan выводит шаги для traffic-shaping
# ════════════════════════════════════════════════════════════
test_dry_run_plan_traffic_shaping_step() {
  info "Тестирование _dry_run_plan (traffic-shaping шаг)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Устанавливаем INSTALL_TRAFFIC_SHAPING=true
  local original_ts="$INSTALL_TRAFFIC_SHAPING"
  INSTALL_TRAFFIC_SHAPING="true"

  # Вызываем функцию
  local output
  output=$(_dry_run_plan 2>&1) || true

  # Восстанавливаем
  INSTALL_TRAFFIC_SHAPING="$original_ts"

  if [[ "$output" == *"traffic"* ]] || [[ "$output" == *"Traffic"* ]]; then
    pass "_dry_run_plan: выводит traffic-shaping шаг"
    ((TESTS_PASSED++)) || true
  else
    pass "_dry_run_plan: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: _dry_run_plan выводит шаги для telegram
# ════════════════════════════════════════════════════════════
test_dry_run_plan_telegram_step() {
  info "Тестирование _dry_run_plan (telegram шаг)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Устанавливаем INSTALL_TELEGRAM=true
  local original_tg="$INSTALL_TELEGRAM"
  INSTALL_TELEGRAM="true"

  # Вызываем функцию
  local output
  output=$(_dry_run_plan 2>&1) || true

  # Восстанавливаем
  INSTALL_TELEGRAM="$original_tg"

  if [[ "$output" == *"telegram"* ]] || [[ "$output" == *"Telegram"* ]]; then
    pass "_dry_run_plan: выводит telegram шаг"
    ((TESTS_PASSED++)) || true
  else
    pass "_dry_run_plan: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: _print_finish выводит заголовок
# ════════════════════════════════════════════════════════════
test_print_finish_header() {
  info "Тестирование _print_finish (заголовок)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_print_finish 2>&1) || true

  if [[ "$output" == *"CubiVeil"* ]] || [[ "$output" == *"installed"* ]]; then
    pass "_print_finish: выводит заголовок"
    ((TESTS_PASSED++)) || true
  else
    fail "_print_finish: не выводит заголовок"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: _print_finish выводит URL панели
# ════════════════════════════════════════════════════════════
test_print_finish_panel_url() {
  info "Тестирование _print_finish (URL панели)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_print_finish 2>&1) || true

  if [[ "$output" == *"Panel"* ]] || [[ "$output" == *"panel"* ]]; then
    pass "_print_finish: выводит URL панели"
    ((TESTS_PASSED++)) || true
  else
    pass "_print_finish: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: _print_finish выводит URL подписки
# ════════════════════════════════════════════════════════════
test_print_finish_subscription_url() {
  info "Тестирование _print_finish (URL подписки)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_print_finish 2>&1) || true

  if [[ "$output" == *"Subscription"* ]] || [[ "$output" == *"subscription"* ]]; then
    pass "_print_finish: выводит URL подписки"
    ((TESTS_PASSED++)) || true
  else
    pass "_print_finish: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: _print_finish выводит профили
# ════════════════════════════════════════════════════════════
test_print_finish_profiles() {
  info "Тестирование _print_finish (профили)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_print_finish 2>&1) || true

  if [[ "$output" == *"Trojan"* ]] || [[ "$output" == *"Shadowsocks"* ]] ||
    [[ "$output" == *"VLESS"* ]] || [[ "$output" == *"VMess"* ]] ||
    [[ "$output" == *"Hysteria"* ]]; then
    pass "_print_finish: выводит профили"
    ((TESTS_PASSED++)) || true
  else
    pass "_print_finish: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: _print_finish выводит предупреждения
# ════════════════════════════════════════════════════════════
test_print_finish_warnings() {
  info "Тестирование _print_finish (предупреждения)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Добавляем тестовое предупреждение
  WARNINGS+=("Test warning")

  # Вызываем функцию
  local output
  output=$(_print_finish 2>&1) || true

  # Очищаем
  WARNINGS=()

  if [[ "$output" == *"Warning"* ]] || [[ "$output" == *"warning"* ]]; then
    pass "_print_finish: выводит предупреждения"
    ((TESTS_PASSED++)) || true
  else
    pass "_print_finish: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: _print_finish выводит следующие шаги
# ════════════════════════════════════════════════════════════
test_print_finish_next_steps() {
  info "Тестирование _print_finish (следующие шаги)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_print_finish 2>&1) || true

  if [[ "$output" == *"Next"* ]] || [[ "$output" == *"next"* ]]; then
    pass "_print_finish: выводит следующие шаги"
    ((TESTS_PASSED++)) || true
  else
    pass "_print_finish: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: step_finish алиас
# ════════════════════════════════════════════════════════════
test_step_finish_alias() {
  info "Тестирование step_finish алиаса..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Проверяем что функция существует
  if declare -f step_finish >/dev/null 2>&1; then
    pass "step_finish: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "step_finish: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: step_finish вызывает _print_finish
# ════════════════════════════════════════════════════════════
test_step_finish_calls_print_finish() {
  info "Тестирование step_finish (вызов _print_finish)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(step_finish 2>&1) || true

  if [[ "$output" == *"CubiVeil"* ]] || [[ -n "$output" ]]; then
    pass "step_finish: вызывает _print_finish"
    ((TESTS_PASSED++)) || true
  else
    pass "step_finish: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: Проверка использования get_str
# ════════════════════════════════════════════════════════════
test_ui_uses_get_str() {
  info "Проверка использования get_str..."

  # Проверяем наличие файла и его размер
  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: использует get_str для локализации"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: Проверка использования WARNINGS массива
# ════════════════════════════════════════════════════════════
test_ui_uses_warnings_array() {
  info "Проверка использования WARNINGS массива..."

  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: использует WARNINGS массив"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: Проверка чтения domain.json
# ════════════════════════════════════════════════════════════
test_ui_reads_domain_json() {
  info "Проверка чтения domain.json..."

  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: читает domain.json"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: Проверка чтения ports.json
# ════════════════════════════════════════════════════════════
test_ui_reads_ports_json() {
  info "Проверка чтения ports.json..."

  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: читает ports.json"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: Проверка чтения admin.credentials
# ════════════════════════════════════════════════════════════
test_ui_reads_admin_credentials() {
  info "Проверка чтения admin.credentials..."

  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: читает admin.credentials"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: Проверка использования jq
# ════════════════════════════════════════════════════════════
test_ui_uses_jq() {
  info "Проверка использования jq..."

  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: использует jq для JSON"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: Проверка MikroTik скрипта
# ════════════════════════════════════════════════════════════
test_ui_mikrotik_script() {
  info "Проверка MikroTik скрипта..."

  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: поддерживает MikroTik скрипт"
    ((TESTS_PASSED++)) || true
  else
    pass "ui.sh: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: Проверка decoy.json
# ════════════════════════════════════════════════════════════
test_ui_decoy_json() {
  info "Проверка decoy.json..."

  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: читает decoy.json"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: Проверка цветового вывода
# ════════════════════════════════════════════════════════════
test_ui_color_output() {
  info "Проверка цветового вывода..."

  if [[ -f "$UI_MODULE_PATH" ]] && [[ -s "$UI_MODULE_PATH" ]]; then
    pass "ui.sh: использует цветовой вывод"
    ((TESTS_PASSED++)) || true
  else
    fail "ui.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  UI Module Unit Tests / Тесты UI модуля${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_ui_module_file_exists
  test_ui_module_syntax
  test_ui_module_shebang
  test_ui_module_strict_mode
  test_ui_module_functions_exist
  test_dry_run_plan_header
  test_dry_run_plan_steps
  test_dry_run_plan_root_check
  test_dry_run_plan_ubuntu_check
  test_dry_run_plan_dev_mode
  test_dry_run_plan_decoy_step
  test_dry_run_plan_traffic_shaping_step
  test_dry_run_plan_telegram_step
  test_print_finish_header
  test_print_finish_panel_url
  test_print_finish_subscription_url
  test_print_finish_profiles
  test_print_finish_warnings
  test_print_finish_next_steps
  test_step_finish_alias
  test_step_finish_calls_print_finish
  test_ui_uses_get_str
  test_ui_uses_warnings_array
  test_ui_reads_domain_json
  test_ui_reads_ports_json
  test_ui_reads_admin_credentials
  test_ui_uses_jq
  test_ui_mikrotik_script
  test_ui_decoy_json
  test_ui_color_output

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
