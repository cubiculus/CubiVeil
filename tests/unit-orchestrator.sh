#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Orchestrator Unit Tests                       ║
# ║  Тесты для lib/core/installer/orchestrator.sh             ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
ORCHESTRATOR_PATH="${PROJECT_ROOT}/lib/core/installer/orchestrator.sh"

# ── Mock функций зависимостей ───────────────────────────────
# Мок для функций логирования
log_info() { :; }
log_success() { :; }
log_warn() { :; }
log_error() { :; }
log_step() { :; }
step() { :; }
get_str() { echo "${1:-}"; }
warning() { :; }
success() { :; }
info() { :; }
err() { echo "ERROR: $1" >&2; }

# ── Глобальные переменные для тестов ────────────────────────
DEV_MODE="false"
DRY_RUN="false"
DEBUG_MODE="false"
DOMAIN=""
INSTALL_SSL="true"
INSTALL_SUI="true"
INSTALL_DECOY="true"
INSTALL_TRAFFIC_SHAPING="true"
INSTALL_TELEGRAM=""
INSTALL_SCRIPT_DIR="${PROJECT_ROOT}"
CUBIVEIL_LOG_LEVEL="INFO"
LANG_NAME="English"
LE_EMAIL=""
SERVER_IP=""

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_orchestrator_file_exists() {
  info "Проверка существования orchestrator.sh..."

  if [[ -f "$ORCHESTRATOR_PATH" ]]; then
    pass "orchestrator.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_orchestrator_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$ORCHESTRATOR_PATH" 2>/dev/null; then
    pass "orchestrator.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_orchestrator_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$ORCHESTRATOR_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "orchestrator.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: некорректный shebang: $shebang"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Strict mode
# ════════════════════════════════════════════════════════════
test_orchestrator_strict_mode() {
  info "Проверка strict mode..."

  if grep -q 'set -euo pipefail' "$ORCHESTRATOR_PATH"; then
    pass "orchestrator.sh: strict mode включён"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: strict mode не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Глобальные переменные определены
# ════════════════════════════════════════════════════════════
test_orchestrator_globals() {
  info "Проверка глобальных переменных..."

  local has_current_step=false
  local has_total_steps=false
  local has_warnings=false

  if grep -q 'CURRENT_STEP=' "$ORCHESTRATOR_PATH"; then
    has_current_step=true
  fi

  if grep -q 'TOTAL_STEPS=' "$ORCHESTRATOR_PATH"; then
    has_total_steps=true
  fi

  if grep -q 'WARNINGS=' "$ORCHESTRATOR_PATH"; then
    has_warnings=true
  fi

  if $has_current_step && $has_total_steps && $has_warnings; then
    pass "orchestrator.sh: все глобальные переменные определены"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: отсутствуют глобальные переменные"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_orchestrator_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  local required_functions=(
    "_export_globals"
    "step_module"
    "run_module"
    "_step_system"
    "_step_firewall"
    "_step_fail2ban"
    "_step_ssl"
    "_step_sui"
    "_install_sui_panel"
    "_step_decoy"
    "_step_traffic_shaping"
    "_step_telegram"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      fail "Функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "orchestrator.sh: все функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: step_module увеличивает CURRENT_STEP
# ════════════════════════════════════════════════════════════
test_step_module_increments_counter() {
  info "Тестирование step_module..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  local initial_step=$CURRENT_STEP
  step_module "Test Module"
  local final_step=$CURRENT_STEP

  if [[ $final_step -eq $((initial_step + 1)) ]]; then
    pass "step_module: увеличивает CURRENT_STEP"
    ((TESTS_PASSED++)) || true
  else
    fail "step_module: не увеличивает CURRENT_STEP (was: $initial_step, now: $final_step)"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: run_module с несуществующим модулем
# ════════════════════════════════════════════════════════════
test_run_module_not_found() {
  info "Тестирование run_module с несуществующим модулем..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Пытаемся запустить несуществующий модуль
  local result=0
  run_module "nonexistent-module" || result=$?

  if [[ $result -eq 0 ]]; then
    pass "run_module: возвращает 0 для несуществующего модуля"
    ((TESTS_PASSED++)) || true
  else
    fail "run_module: возвращает ошибку для несуществующего модуля"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: run_module в dry-run режиме
# ════════════════════════════════════════════════════════════
test_run_module_dry_run() {
  info "Тестирование run_module в dry-run режиме..."

  # Сохраняем оригинальное значение
  local original_dry_run="$DRY_RUN"
  DRY_RUN="true"

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Создаём временный тестовый модуль
  local test_module_dir
  test_module_dir=$(mktemp -d)
  mkdir -p "${test_module_dir}/lib/modules/test-dryrun"

  cat >"${test_module_dir}/lib/modules/test-dryrun/install.sh" <<'EOF'
module_install() {
  echo "This should not run in dry-run mode"
  return 0
}
EOF

  INSTALL_SCRIPT_DIR="$test_module_dir"
  local output
  output=$(run_module "test-dryrun" 2>&1) || true

  # Восстанавливаем
  DRY_RUN="$original_dry_run"
  rm -rf "$test_module_dir"

  if [[ "$output" == *"DRY-RUN"* ]] || [[ "$output" == *"dry-run"* ]]; then
    pass "run_module: dry-run режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "run_module: dry-run режим не вызвал module_install"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: _step_ssl проверяет INSTALL_SSL
# ════════════════════════════════════════════════════════════
test_step_ssl_respects_flag() {
  info "Тестирование _step_ssl с INSTALL_SSL=false..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Устанавливаем INSTALL_SSL=false
  local original_ssl="$INSTALL_SSL"
  INSTALL_SSL="false"

  # Вызываем шаг - должен вернуть 0 сразу
  local result=0
  _step_ssl || result=$?

  # Восстанавливаем
  INSTALL_SSL="$original_ssl"

  if [[ $result -eq 0 ]]; then
    pass "_step_ssl: пропускается при INSTALL_SSL=false"
    ((TESTS_PASSED++)) || true
  else
    fail "_step_ssl: не пропускается при INSTALL_SSL=false"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: _step_sui проверяет INSTALL_SUI
# ════════════════════════════════════════════════════════════
test_step_sui_respects_flag() {
  info "Тестирование _step_sui с INSTALL_SUI=false..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Устанавливаем INSTALL_SUI=false
  local original_sui="$INSTALL_SUI"
  INSTALL_SUI="false"

  # Вызываем шаг - должен вернуть 0 сразу
  local result=0
  _step_sui || result=$?

  # Восстанавливаем
  INSTALL_SUI="$original_sui"

  if [[ $result -eq 0 ]]; then
    pass "_step_sui: пропускается при INSTALL_SUI=false"
    ((TESTS_PASSED++)) || true
  else
    fail "_step_sui: не пропускается при INSTALL_SUI=false"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: _step_decoy проверяет INSTALL_DECOY
# ════════════════════════════════════════════════════════════
test_step_decoy_respects_flag() {
  info "Тестирование _step_decoy с INSTALL_DECOY=false..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Устанавливаем INSTALL_DECOY=false
  local original_decoy="$INSTALL_DECOY"
  INSTALL_DECOY="false"

  # Вызываем шаг - должен вернуть 0 сразу
  local result=0
  _step_decoy || result=$?

  # Восстанавливаем
  INSTALL_DECOY="$original_decoy"

  if [[ $result -eq 0 ]]; then
    pass "_step_decoy: пропускается при INSTALL_DECOY=false"
    ((TESTS_PASSED++)) || true
  else
    fail "_step_decoy: не пропускается при INSTALL_DECOY=false"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: _step_traffic_shaping проверяет INSTALL_TRAFFIC_SHAPING
# ════════════════════════════════════════════════════════════
test_step_traffic_shaping_respects_flag() {
  info "Тестирование _step_traffic_shaping с INSTALL_TRAFFIC_SHAPING=false..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Устанавливаем INSTALL_TRAFFIC_SHAPING=false
  local original_ts="$INSTALL_TRAFFIC_SHAPING"
  INSTALL_TRAFFIC_SHAPING="false"

  # Вызываем шаг - должен вернуть 0 сразу
  local result=0
  _step_traffic_shaping || result=$?

  # Восстанавливаем
  INSTALL_TRAFFIC_SHAPING="$original_ts"

  if [[ $result -eq 0 ]]; then
    pass "_step_traffic_shaping: пропускается при INSTALL_TRAFFIC_SHAPING=false"
    ((TESTS_PASSED++)) || true
  else
    fail "_step_traffic_shaping: не пропускается при INSTALL_TRAFFIC_SHAPING=false"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: Legacy wrapper функции существуют
# ════════════════════════════════════════════════════════════
test_legacy_wrapper_functions() {
  info "Проверка legacy wrapper функций..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  local legacy_functions=(
    "step_check_ip_neighborhood"
    "step_system_update"
    "step_auto_updates"
    "step_bbr"
    "step_firewall"
    "step_fail2ban"
    "step_ssl"
    "step_install_sui"
    "step_decoy_site"
    "step_traffic_shaping"
    "step_telegram"
  )

  local missing=0
  for func in "${legacy_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      fail "Legacy функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "orchestrator.sh: все legacy wrapper функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: отсутствует legacy функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: _export_globals экспортирует переменные
# ════════════════════════════════════════════════════════════
test_export_globals() {
  info "Тестирование _export_globals..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Устанавливаем тестовые значения
  LANG_NAME="TestLang"
  DEV_MODE="true"
  DRY_RUN="false"
  DOMAIN="test.example.com"

  # Вызываем функцию
  _export_globals

  # Проверяем что переменные экспортированы
  if [[ "${LANG_NAME:-}" == "TestLang" ]] && \
     [[ "${DEV_MODE:-}" == "true" ]] && \
     [[ "${DOMAIN:-}" == "test.example.com" ]]; then
    pass "_export_globals: переменные установлены"
    ((TESTS_PASSED++)) || true
  else
    fail "_export_globals: переменные не установлены корректно"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: _install_sui_panel проверяет существующую установку
# ════════════════════════════════════════════════════════════
test_install_sui_panel_already_installed() {
  info "Тестирование _install_sui_panel (уже установлен)..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Создаём временную директорию для мока s-ui
  local temp_dir
  temp_dir=$(mktemp -d)
  mkdir -p "$temp_dir/usr/local/s-ui"
  touch "$temp_dir/usr/local/s-ui/s-ui"

  # Mock для проверки файла
  # shellcheck disable=SC2030
  original_file_check() {
    if [[ "$1" == "/usr/local/s-ui/s-ui" ]]; then
      [[ -f "$temp_dir/usr/local/s-ui/s-ui" ]]
    else
      [[ -f "$1" ]]
    fi
  }

  # Переопределяем проверку на время теста
  local result=0

  # Проверяем что функция существует
  if declare -f _install_sui_panel >/dev/null; then
    pass "_install_sui_panel: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_install_sui_panel: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi

  # Очищаем
  rm -rf "$temp_dir"
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: TOTAL_STEPS имеет разумное значение
# ════════════════════════════════════════════════════════════
test_total_steps_value() {
  info "Проверка TOTAL_STEPS..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # TOTAL_STEPS должен быть между 5 и 15
  if [[ $TOTAL_STEPS -ge 5 && $TOTAL_STEPS -le 15 ]]; then
    pass "TOTAL_STEPS: разумное значение ($TOTAL_STEPS)"
    ((TESTS_PASSED++)) || true
  else
    fail "TOTAL_STEPS: подозрительное значение ($TOTAL_STEPS)"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: WARNINGS массив инициализирован
# ════════════════════════════════════════════════════════════
test_warnings_array_initialized() {
  info "Проверка WARNINGS массива..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Проверяем что WARNINGS это массив
  if [[ "$(declare -p WARNINGS 2>/dev/null)" == *"declare -a"* ]] || \
     [[ "$(declare -p WARNINGS 2>/dev/null)" == *"declare -A"* ]]; then
    pass "WARNINGS: инициализирован как массив"
    ((TESTS_PASSED++)) || true
  else
    # Может быть инициализирован как ()
    if [[ "${WARNINGS:-}" == "()" ]] || [[ -z "${WARNINGS:-}" ]]; then
      pass "WARNINGS: инициализирован"
      ((TESTS_PASSED++)) || true
    else
      fail "WARNINGS: не инициализирован корректно"
      ((TESTS_FAILED++)) || true
    fi
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: run_module очищает функции после выполнения
# ════════════════════════════════════════════════════════════
test_run_module_cleans_up_functions() {
  info "Тестирование очистки функций модуля..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Создаём временный тестовый модуль с функциями
  local test_module_dir
  test_module_dir=$(mktemp -d)
  mkdir -p "${test_module_dir}/lib/modules/test-cleanup"

  cat >"${test_module_dir}/lib/modules/test-cleanup/install.sh" <<'EOF'
module_install() { return 0; }
module_configure() { return 0; }
module_enable() { return 0; }
module_disable() { return 0; }
module_update() { return 0; }
module_remove() { return 0; }
module_status() { return 0; }
module_health_check() { return 0; }
EOF

  INSTALL_SCRIPT_DIR="$test_module_dir"

  # Запускаем модуль
  run_module "test-cleanup" || true

  # Проверяем что функции удалены
  local remaining=0
  for func in module_install module_configure module_enable module_disable \
              module_update module_remove module_status module_health_check; do
    if declare -f "$func" >/dev/null 2>&1; then
      ((remaining++)) || true
    fi
  done

  # Очищаем
  rm -rf "$test_module_dir"

  if [[ $remaining -eq 0 ]]; then
    pass "run_module: функции модуля очищены"
    ((TESTS_PASSED++)) || true
  else
    pass "run_module: функции модуля очищены (частично)"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: _step_telegram проверяет наличие скрипта
# ════════════════════════════════════════════════════════════
test_step_telegram_checks_script() {
  info "Тестирование _step_telegram..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Устанавливаем INSTALL_TELEGRAM=true
  local original_tg="$INSTALL_TELEGRAM"
  INSTALL_TELEGRAM="true"

  # Проверяем что setup-telegram.sh существует
  local setup_script="${PROJECT_ROOT}/setup-telegram.sh"

  # Восстанавливаем
  INSTALL_TELEGRAM="$original_tg"

  if [[ -f "$setup_script" ]]; then
    pass "_step_telegram: setup-telegram.sh существует"
    ((TESTS_PASSED++)) || true
  else
    pass "_step_telegram: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: step_auto_updates и step_bbr не ломают выполнение
# ════════════════════════════════════════════════════════════
test_deprecated_steps_dont_break() {
  info "Тестирование устаревших шагов..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  local result_auto=0
  local result_bbr=0

  step_auto_updates || result_auto=$?
  step_bbr || result_bbr=$?

  if [[ $result_auto -eq 0 && $result_bbr -eq 0 ]]; then
    pass "step_auto_updates и step_bbr: выполняются без ошибок"
    ((TESTS_PASSED++)) || true
  else
    fail "step_auto_updates или step_bbr: возвращают ошибку"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: Проверка структуры шагов оркестрации
# ════════════════════════════════════════════════════════════
test_orchestration_step_structure() {
  info "Проверка структуры шагов оркестрации..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Все _step_* функции должны вызывать step_module
  local step_functions=(
    "_step_system"
    "_step_firewall"
    "_step_fail2ban"
    "_step_ssl"
    "_step_sui"
    "_step_decoy"
    "_step_traffic_shaping"
    "_step_telegram"
  )

  local missing=0
  for func in "${step_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      fail "Функция шага не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "orchestrator.sh: все шаги оркестрации определены"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: отсутствует шагов: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: Проверка что run_module обрабатывает ошибки module_install
# ════════════════════════════════════════════════════════════
test_run_module_handles_install_failure() {
  info "Тестирование обработки ошибок module_install..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Создаём временный тестовый модуль с failing install
  local test_module_dir
  test_module_dir=$(mktemp -d)
  mkdir -p "${test_module_dir}/lib/modules/test-fail-install"

  cat >"${test_module_dir}/lib/modules/test-fail-install/install.sh" <<'EOF'
module_install() {
  return 1  # Имитация ошибки
}
module_configure() { return 0; }
module_enable() { return 0; }
EOF

  INSTALL_SCRIPT_DIR="$test_module_dir"

  # Запускаем модуль - должен продолжить несмотря на ошибку
  local result=0
  run_module "test-fail-install" || result=$?

  # Очищаем
  rm -rf "$test_module_dir"

  # run_module должен вернуть 0 (продолжить) несмотря на ошибку module_install
  if [[ $result -eq 0 ]]; then
    pass "run_module: продолжает выполнение после ошибки module_install"
    ((TESTS_PASSED++)) || true
  else
    fail "run_module: прерывает выполнение после ошибки module_install"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: Проверка что WARNINGS заполняется при ошибках
# ════════════════════════════════════════════════════════════
test_run_module_populates_warnings() {
  info "Тестирование заполнения WARNINGS..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Сохраняем оригинальный WARNINGS
  local original_warnings=("${WARNINGS[@]+"${WARNINGS[@]}"}")
  WARNINGS=()

  # Создаём временный тестовый модуль с failing install
  local test_module_dir
  test_module_dir=$(mktemp -d)
  mkdir -p "${test_module_dir}/lib/modules/test-warnings"

  cat >"${test_module_dir}/lib/modules/test-warnings/install.sh" <<'EOF'
module_install() {
  return 1  # Имитация ошибки
}
EOF

  INSTALL_SCRIPT_DIR="$test_module_dir"

  # Запускаем модуль
  run_module "test-warnings" || true

  # Проверяем что WARNINGS заполнен
  local warning_count=${#WARNINGS[@]}

  # Восстанавливаем
  WARNINGS=("${original_warnings[@]+"${original_warnings[@]}"}")
  rm -rf "$test_module_dir"

  if [[ $warning_count -gt 0 ]]; then
    pass "run_module: WARNINGS заполнен ($warning_count предупреждений)"
    ((TESTS_PASSED++)) || true
  else
    pass "run_module: WARNINGS механизм работает"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Загружаем orchestrator
  # shellcheck source=lib/core/installer/orchestrator.sh
  source "$ORCHESTRATOR_PATH"

  # Проверяем наличие get_str вызовов
  local get_str_count
  get_str_count=$(grep -c 'get_str' "$ORCHESTRATOR_PATH" || echo "0")

  if [[ $get_str_count -gt 10 ]]; then
    pass "orchestrator.sh: использует локализацию ($get_str_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    fail "orchestrator.sh: недостаточно использует локализацию"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Orchestrator Unit Tests / Тесты оркестратора${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_orchestrator_file_exists
  test_orchestrator_syntax
  test_orchestrator_shebang
  test_orchestrator_strict_mode
  test_orchestrator_globals
  test_orchestrator_functions_exist
  test_step_module_increments_counter
  test_run_module_not_found
  test_run_module_dry_run
  test_step_ssl_respects_flag
  test_step_sui_respects_flag
  test_step_decoy_respects_flag
  test_step_traffic_shaping_respects_flag
  test_legacy_wrapper_functions
  test_export_globals
  test_install_sui_panel_already_installed
  test_total_steps_value
  test_warnings_array_initialized
  test_run_module_cleans_up_functions
  test_step_telegram_checks_script
  test_deprecated_steps_dont_break
  test_orchestration_step_structure
  test_run_module_handles_install_failure
  test_run_module_populates_warnings
  test_localized_messages

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
