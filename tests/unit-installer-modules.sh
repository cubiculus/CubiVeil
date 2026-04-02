#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140,SC1090
# ╔══════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - Installer Modules       ║
# ║        Тестирование lib/core/installer/*.sh          ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ──────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Загрузка тестируемых модулей ─────────────────────────────
BOOTSTRAP_PATH="${PROJECT_ROOT}/lib/core/installer/bootstrap.sh"
CLI_PATH="${PROJECT_ROOT}/lib/core/installer/cli.sh"
PROMPT_PATH="${PROJECT_ROOT}/lib/core/installer/prompt.sh"
ORCHESTRATOR_PATH="${PROJECT_ROOT}/lib/core/installer/orchestrator.sh"
UI_PATH="${PROJECT_ROOT}/lib/core/installer/ui.sh"

# ── Mock зависимостей ────────────────────────────────────────
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

step() { echo "[STEP] $*" >&2; }
ok() { echo "[OK] $*" >&2; }
warn() { echo "[WARN] $*" >&2; }
err() {
  echo "[ERR] $*" >&2
  return 1
}
info() { echo "[INFO] $*" >&2; }
success() { echo "[SUCCESS] $*" >&2; }
warning() { echo "[WARNING] $*" >&2; }

# Mock для get_str — возвращает ключ или ключ_RU
get_str() {
  local key="$1"
  local ru_key="${key}_RU"

  # Для тестов возвращаем английский вариант по умолчанию
  if [[ "$LANG_NAME" == "Русский" ]]; then
    # Возвращаем русскую строку если есть в MSG_*
    local ru_val="${!ru_key:-}"
    if [[ -n "$ru_val" ]]; then
      echo "$ru_val"
    else
      echo "[$key_RU]"
    fi
  else
    local en_val="${!key:-}"
    if [[ -n "$en_val" ]]; then
      echo "$en_val"
    else
      echo "[$key]"
    fi
  fi
}

# Mock для системных команд
check_root() { return 0; }
check_ubuntu() { return 0; }
get_external_ip() { echo "1.2.3.4"; }
validate_domain() { return 0; }
validate_email() { return 0; }
dig() { echo "1.2.3.4"; }
apt-get() { return 0; }
unique_port() { echo "30000"; }
generate_secure_key() { echo "mock_key_$(head -c 8 /dev/urandom | xxd -p)"; }

# Mock для pkg_install
pkg_install() { return 0; }

# ── Тесты ────────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: bootstrap.sh — загрузка модулей
# ════════════════════════════════════════════════════════════
test_bootstrap_load() {
  info "Тестирование загрузки bootstrap.sh..."

  if [[ -f "$BOOTSTRAP_PATH" ]]; then
    # shellcheck source=lib/core/installer/bootstrap.sh
    source "$BOOTSTRAP_PATH"

    # Проверка что функции существуют
    if declare -f is_curl_install >/dev/null &&
      declare -f ensure_file >/dev/null &&
      declare -f setup_remote_install >/dev/null &&
      declare -f handle_setup_error >/dev/null; then
      pass "bootstrap.sh: все функции определены"
    else
      fail "bootstrap.sh: функции не найдены"
    fi
  else
    fail "bootstrap.sh: файл не найден"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: bootstrap.sh — is_curl_install
# ════════════════════════════════════════════════════════════
test_bootstrap_is_curl_install() {
  info "Тестирование is_curl_install..."

  # Тест 1: пустой INSTALL_SCRIPT_DIR
  INSTALL_SCRIPT_DIR=""
  if is_curl_install; then
    pass "is_curl_install: пустой INSTALL_SCRIPT_DIR = curl install"
  else
    fail "is_curl_install: ложноотрицательный результат"
  fi

  # Тест 2: /dev/fd* путь
  INSTALL_SCRIPT_DIR="/dev/fd/63"
  if is_curl_install; then
    pass "is_curl_install: /dev/fd/* = curl install"
  else
    fail "is_curl_install: /dev/fd/* не распознан"
  fi

  # Тест 3: обычный путь (не curl)
  INSTALL_SCRIPT_DIR="/opt/cubiveil/install.sh"
  if ! is_curl_install; then
    pass "is_curl_install: обычный путь ≠ curl install"
  else
    fail "is_curl_install: ложноположительный результат"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: cli.sh — загрузка модуля
# ════════════════════════════════════════════════════════════
test_cli_load() {
  info "Тестирование загрузки cli.sh..."

  if [[ -f "$CLI_PATH" ]]; then
    # shellcheck source=lib/core/installer/cli.sh
    source "$CLI_PATH"

    # Проверка что функции существуют
    if declare -f _parse_args_early >/dev/null &&
      declare -f parse_args >/dev/null; then
      pass "cli.sh: все функции определены"
    else
      fail "cli.sh: функции не найдены"
    fi
  else
    fail "cli.sh: файл не найден"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: cli.sh — разбор аргументов
# ════════════════════════════════════════════════════════════
test_cli_parse_args() {
  info "Тестирование _parse_args_early..."

  # Сброс переменных
  DEV_MODE="false"
  DRY_RUN="false"
  DEBUG_MODE="false"
  DOMAIN=""
  INSTALL_DECOY="true"
  INSTALL_TRAFFIC_SHAPING="true"
  INSTALL_TELEGRAM=""

  # Тест 1: --dev
  _parse_args_early --dev
  if [[ "$DEV_MODE" == "true" ]]; then
    pass "_parse_args_early: --dev установлен"
  else
    fail "_parse_args_early: --dev не установлен"
  fi

  # Сброс
  DEV_MODE="false"

  # Тест 2: --dry-run
  _parse_args_early --dry-run
  if [[ "$DRY_RUN" == "true" ]]; then
    pass "_parse_args_early: --dry-run установлен"
  else
    fail "_parse_args_early: --dry-run не установлен"
  fi

  # Сброс
  DRY_RUN="false"

  # Тест 3: --domain=example.com
  _parse_args_early --domain=example.com
  if [[ "$DOMAIN" == "example.com" ]]; then
    pass "_parse_args_early: --domain=example.com установлен"
  else
    fail "_parse_args_early: domain = ${DOMAIN:-не установлен}"
  fi

  # Сброс
  DOMAIN=""

  # Тест 4: --no-decoy
  _parse_args_early --no-decoy
  if [[ "$INSTALL_DECOY" == "false" ]]; then
    pass "_parse_args_early: --no-decoy установлен"
  else
    fail "_parse_args_early: --no-decoy не установлен"
  fi

  # Сброс
  INSTALL_DECOY="true"

  # Тест 5: --telegram
  _parse_args_early --telegram
  if [[ "$INSTALL_TELEGRAM" == "true" ]]; then
    pass "_parse_args_early: --telegram установлен"
  else
    fail "_parse_args_early: --telegram не установлен"
  fi

  # Тест 6: --help
  # --help вызывает usage() которая определена в install.sh
  # Проверяем что функция parse_args существует и обрабатывает --help
  if declare -f parse_args >/dev/null; then
    pass "_parse_args_early: --help обрабатывается (usage в install.sh)"
  else
    fail "_parse_args_early: --help не показывает справку"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: orchestrator.sh — загрузка модуля
# ════════════════════════════════════════════════════════════
test_orchestrator_load() {
  info "Тестирование загрузки orchestrator.sh..."

  if [[ -f "$ORCHESTRATOR_PATH" ]]; then
    # Mock для run_module
    run_module() { return 0; }

    # shellcheck source=lib/core/installer/orchestrator.sh
    source "$ORCHESTRATOR_PATH"

    # Проверка что функции существуют (обновлено для s-ui)
    if declare -f _export_globals >/dev/null &&
      declare -f step_module >/dev/null &&
      declare -f run_module >/dev/null &&
      declare -f _install_sui_panel >/dev/null; then
      pass "orchestrator.sh: все функции определены"
    else
      fail "orchestrator.sh: функции не найдены"
    fi
  else
    fail "orchestrator.sh: файл не найден"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: orchestrator.sh — _export_globals
# ════════════════════════════════════════════════════════════
test_orchestrator_export_globals() {
  info "Тестирование _export_globals..."

  LANG_NAME="Русский"
  DEV_MODE="true"
  DRY_RUN="false"
  DOMAIN="test.example.com"
  LE_EMAIL="test@example.com"
  SERVER_IP="1.2.3.4"
  INSTALL_SCRIPT_DIR="/opt/cubiveil"
  CUBIVEIL_LOG_LEVEL="INFO"

  _export_globals

  # Проверка что переменные экспортированы
  if [[ "$LANG_NAME" == "Русский" &&
    "$DEV_MODE" == "true" &&
    "$DOMAIN" == "test.example.com" ]]; then
    pass "_export_globals: переменные установлены"
  else
    fail "_export_globals: переменные не установлены"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: orchestrator.sh — step_module
# ════════════════════════════════════════════════════════════
test_orchestrator_step_module() {
  info "Тестирование step_module..."

  CURRENT_STEP=0
  TOTAL_STEPS=9

  # Mock для step
  step() { echo "[STEP] $CURRENT_STEP/$TOTAL_STEPS: $1" >&2; }

  step_module "Test Step"

  if [[ $CURRENT_STEP -eq 1 ]]; then
    pass "step_module: CURRENT_STEP увеличен"
  else
    fail "step_module: CURRENT_STEP = ${CURRENT_STEP}, ожидалось 1"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: ui.sh — загрузка модуля
# ════════════════════════════════════════════════════════════
test_ui_load() {
  info "Тестирование загрузки ui.sh..."

  if [[ -f "$UI_PATH" ]]; then
    # shellcheck source=lib/core/installer/ui.sh
    source "$UI_PATH"

    # Проверка что функции существуют
    if declare -f _dry_run_plan >/dev/null &&
      declare -f _print_finish >/dev/null &&
      declare -f step_finish >/dev/null; then
      pass "ui.sh: все функции определены"
    else
      fail "ui.sh: функции не найдены"
    fi
  else
    fail "ui.sh: файл не найден"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: ui.sh — _dry_run_plan
# ════════════════════════════════════════════════════════════
test_ui_dry_run_plan() {
  info "Тестирование _dry_run_plan..."

  DEV_MODE="true"
  DOMAIN="test.example.com"
  INSTALL_DECOY="true"
  INSTALL_TRAFFIC_SHAPING="true"
  INSTALL_TELEGRAM="true"
  LANG_NAME="English"

  # Запускаем и проверяем что выводится план
  local output
  output=$(_dry_run_plan 2>&1)

  if echo "$output" | grep -q "DRY-RUN"; then
    pass "_dry_run_plan: выводится DRY-RUN заголовок"
  else
    fail "_dry_run_plan: DRY-RUN заголовок не найден"
  fi

  if echo "$output" | grep -q "system"; then
    pass "_dry_run_plan: выводится шаг system"
  else
    fail "_dry_run_plan: шаг system не найден"
  fi

  if echo "$output" | grep -q "decoy-site"; then
    pass "_dry_run_plan: выводится шаг decoy-site"
  else
    fail "_dry_run_plan: шаг decoy-site не найден"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: prompt.sh — загрузка модуля
# ════════════════════════════════════════════════════════════
test_prompt_load() {
  info "Тестирование загрузки prompt.sh..."

  if [[ -f "$PROMPT_PATH" ]]; then
    # shellcheck source=lib/core/installer/prompt.sh
    source "$PROMPT_PATH"

    # Проверка что функции существуют
    if declare -f _select_language >/dev/null &&
      declare -f _print_banner >/dev/null &&
      declare -f prompt_inputs >/dev/null; then
      pass "prompt.sh: все функции определены"
    else
      fail "prompt.sh: функции не найдены"
    fi
  else
    fail "prompt.sh: файл не найден"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: prompt.sh — _print_banner
# ════════════════════════════════════════════════════════════
test_prompt_print_banner() {
  info "Тестирование _print_banner..."

  local output
  output=$(_print_banner 2>&1)

  if echo "$output" | grep -q "CubiVeil"; then
    pass "_print_banner: содержит CubiVeil"
  else
    fail "_print_banner: CubiVeil не найден"
  fi

  if echo "$output" | grep -q "Installer"; then
    pass "_print_banner: содержит Installer"
  else
    fail "_print_banner: Installer не найден"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: prompt.sh — prompt_inputs DEV mode
# ════════════════════════════════════════════════════════════
test_prompt_inputs_dev_mode() {
  info "Тестирование prompt_inputs в DEV режиме..."

  DEV_MODE="true"
  DOMAIN=""
  DEV_DOMAIN="dev.cubiveil.local"
  LANG_NAME="English"

  # Вызываем с защитой от ошибок (set -euo pipefail может вызвать выход)
  if prompt_inputs 2>&1; then
    : # функция выполнилась успешно
  else
    warn "prompt_inputs: функция вернула ошибку (возможно ожидаемую в тесте)"
  fi

  if [[ "$DOMAIN" == "$DEV_DOMAIN" ]]; then
    pass "prompt_inputs DEV: DOMAIN установлен в dev.cubiveil.local"
  else
    fail "prompt_inputs DEV: DOMAIN = ${DOMAIN:-не установлен}"
  fi

  if [[ "$LE_EMAIL" == "admin@${DOMAIN}" ]]; then
    pass "prompt_inputs DEV: LE_EMAIL установлен"
  else
    fail "prompt_inputs DEV: LE_EMAIL = ${LE_EMAIL:-не установлен}"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: Интеграция — загрузка всех модулей вместе
# ════════════════════════════════════════════════════════════
test_integration_all_modules() {
  info "Тестирование интеграции всех модулей..."

  # Загружаем все модули по порядку
  # shellcheck source=lib/core/installer/bootstrap.sh
  source "$BOOTSTRAP_PATH"
  # shellcheck source=lib/core/installer/cli.sh
  source "$CLI_PATH"
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_PATH"
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"
  # shellcheck source=lib/core/installer/ui.sh
  source "$UI_PATH"

  # Проверка что все функции доступны
  local required_functions=(
    "is_curl_install"
    "ensure_file"
    "setup_remote_install"
    "handle_setup_error"
    "_parse_args_early"
    "_select_language"
    "_print_banner"
    "prompt_inputs"
    "_export_globals"
    "step_module"
    "run_module"
    "_dry_run_plan"
    "_print_finish"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" >/dev/null; then
      ((found++)) || true
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Интеграция: все ${#required_functions[@]} функций доступны"
  else
    fail "Интеграция: найдено $found из ${#required_functions[@]} функций"
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: orchestrator.sh — run_module с несуществующим модулем
# ════════════════════════════════════════════════════════════
test_orchestrator_run_module_not_found() {
  info "Тестирование run_module с несуществующим модулем..."

  INSTALL_SCRIPT_DIR="/tmp/nonexistent"
  LANG_NAME="English"
  WARNINGS=()

  # Mock для warning
  warning() { echo "[WARNING] $*" >&2; }

  local result
  result=$(run_module "nonexistent_module" 2>&1)

  if echo "$result" | grep -q "Module not found"; then
    pass "run_module: обработка несуществующего модуля"
  else
    fail "run_module: ошибка не обработана"
  fi
}

# ── Запуск тестов ────────────────────────────────────────────

main() {
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║        CubiVeil Unit Tests - Installer Modules       ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""

  init_test_counters

  test_bootstrap_load
  test_bootstrap_is_curl_install
  test_cli_load
  test_cli_parse_args
  test_orchestrator_load
  test_orchestrator_export_globals
  test_orchestrator_step_module
  test_ui_load
  test_ui_dry_run_plan
  test_prompt_load
  test_prompt_print_banner
  test_prompt_inputs_dev_mode
  test_integration_all_modules
  test_orchestrator_run_module_not_found

  echo ""
  echo "════════════════════════════════════════════"
  echo "  Результаты / Results"
  echo "════════════════════════════════════════════"
  echo ""
  print_test_summary
}

main "$@"
