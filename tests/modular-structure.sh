#!/bin/bash
# shellcheck disable=SC1071,SC1111
# ╔══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - Modular Structure           ║
# ║        Тестирование модульной архитектуры                ║
# ╚══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ─────────────────────────────────────────────
# Используем уникальное имя переменной чтобы избежать перезаписи
MODULAR_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${MODULAR_SCRIPT_DIR}/lib/test-utils.sh"

# ── Тест: структура директорий ──────────────────────────────────────────────
test_directory_structure() {
  info "Тестирование структуры директорий..."

  # Проверка основных директорий
  local dirs=(
    "lib"
    "tests"
  )

  for dir in "${dirs[@]}"; do
    if [[ -d "${MODULAR_SCRIPT_DIR}/${dir}" ]]; then
      pass "Директория существует: $dir"
      ((TESTS_PASSED++)) || true
    else
      fail "Директория отсутствует: $dir"
    fi
  done
}

# ── Тест: наличие основных файлов ──────────────────────────────────────────
test_main_files() {
  info "Тестирование наличия основных файлов..."

  local files=(
    "install.sh"
    "setup-telegram.sh"
    "README.md"
    "run-tests.sh"
  )

  for file in "${files[@]}"; do
    if [[ -f "${MODULAR_SCRIPT_DIR}/${file}" ]]; then
      pass "Файл существует: $file"
      ((TESTS_PASSED++)) || true
    else
      warn "Файл отсутствует: $file"
    fi
  done
}

# ── Тест: модули lib ────────────────────────────────────────────────────────
test_lib_modules() {
  info "Тестирование модулей в lib/..."

  local lib_files=(
    "lib/utils.sh"
    "lib/common.sh"
    "lib/validation.sh"
    "lib/security.sh"
    "lib/output.sh"
    "lib/fallback.sh"
    "lib/i18n.sh"
    "lib/manifest.sh"
  )

  for file in "${lib_files[@]}"; do
    if [[ -f "${MODULAR_SCRIPT_DIR}/${file}" ]]; then
      pass "Модуль существует: $file"
      ((TESTS_PASSED++)) || true
    else
      fail "Модуль отсутствует: $file"
    fi
  done
}

# ── Тест: тестовые файлы ────────────────────────────────────────────────────
test_test_files() {
  info "Тестирование тестовых файлов..."

  local test_files=(
    "tests/integration-test.sh"
    "tests/unit-utils.sh"
    "tests/unit-telegram.sh"
    "tests/modular-structure.sh"
  )

  for file in "${test_files[@]}"; do
    if [[ -f "${MODULAR_SCRIPT_DIR}/${file}" ]]; then
      pass "Тестовый файл существует: $file"
      ((TESTS_PASSED++)) || true
    else
      warn "Тестовый файл отсутствует: $file"
    fi
  done
}

# ── Тест: синтаксис всех скриптов ───────────────────────────────────────────
test_all_syntax() {
  info "Тестирование синтаксиса всех скриптов..."

  local scripts=(
    "install.sh"
    "setup-telegram.sh"
    "lib/utils.sh"
    "lib/common.sh"
    "tests/integration-test.sh"
    "tests/unit-utils.sh"
    "tests/unit-telegram.sh"
    "tests/modular-structure.sh"
    "run-tests.sh"
  )

  for script in "${scripts[@]}"; do
    if [[ -f "${MODULAR_SCRIPT_DIR}/${script}" ]]; then
      if bash -n "${MODULAR_SCRIPT_DIR}/${script}" 2>/dev/null; then
        pass "Синтаксис OK: $script"
        ((TESTS_PASSED++)) || true
      else
        fail "Синтаксическая ошибка: $script"
      fi
    fi
  done
}

# ── Тест: исполнимость скриптов ─────────────────────────────────────────────
test_executable() {
  info "Тестирование исполнимости скриптов..."

  local exec_scripts=(
    "install.sh"
    "setup-telegram.sh"
    "lib/utils.sh"
    "tests/integration-test.sh"
    "tests/unit-utils.sh"
    "tests/unit-telegram.sh"
    "tests/modular-structure.sh"
    "run-tests.sh"
  )

  for script in "${exec_scripts[@]}"; do
    local script_path="${MODULAR_SCRIPT_DIR}/${script}"
    if [[ -f "$script_path" ]]; then
      if [[ -x "$script_path" ]]; then
        pass "Исполнимый: $script"
        ((TESTS_PASSED++)) || true
      else
        warn "Не исполнимый: $script (chmod +x может понадобиться)"
      fi
    fi
  done
}

# ── Тест: загрузка модулей ──────────────────────────────────────────────────
test_module_loading() {
  info "Тестирование загрузки модулей..."

  # Mock зависимостей
  check_root() { :; }
  check_ubuntu() { :; }
  step() { echo "$1"; }
  ok() { echo -e "${GREEN}[✓]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[✗]${PLAIN} $1" >&2
    exit 1
  }

  # Проверка загрузки lib/utils.sh
  if bash -c "source ${MODULAR_SCRIPT_DIR}/lib/utils.sh 2>&1"; then
    pass "Модуль загружается: lib/utils.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "Модуль не загружается: lib/utils.sh"
  fi

  # Проверка загрузки lib/common.sh
  if bash -c "source ${MODULAR_SCRIPT_DIR}/lib/common.sh 2>&1"; then
    pass "Модуль загружается: lib/common.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "Модуль не загружается: lib/common.sh"
  fi

  # Проверка загрузки lang/main.sh
  if [[ -f "${MODULAR_SCRIPT_DIR}/lang/main.sh" ]]; then
    if bash -c "source ${MODULAR_SCRIPT_DIR}/lang/main.sh 2>&1"; then
      pass "Модуль загружается: lang/main.sh"
      ((TESTS_PASSED++)) || true
    else
      warn "Модуль не загружается: lang/main.sh"
    fi
  fi
}

# ── Тест: функции в lib/utils.sh ────────────────────────────────────────────
test_utils_functions() {
  info "Тестирование функций в lib/utils.sh..."

  # Mock зависимостей
  check_root() { :; }
  check_ubuntu() { :; }
  step() { echo "$1"; }
  ok() { echo -e "${GREEN}[✓]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[✗]${PLAIN} $1" >&2
    exit 1
  }

  # Загружаем модуль
  source "${MODULAR_SCRIPT_DIR}/lib/utils.sh"

  local functions=(
    "gen_random"
    "gen_hex"
    "gen_port"
    "unique_port"
    "arch"
    "get_server_ip"
    "open_port"
  )

  for func in "${functions[@]}"; do
    if declare -f "$func" >/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция отсутствует: $func"
    fi
  done
}

# ── Тест: функции в install.sh ──────────────────────────────────────────────
test_install_functions() {
  # Mock зависимостей (должны быть определены до использования)
  check_root() { :; }
  check_ubuntu() { :; }
  step() { echo "$1"; }
  step_title() { echo "$1"; }
  ok() { echo -e "${GREEN}[✓]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[✗]${PLAIN} $1" >&2
    exit 1
  }
  info() { echo "[INFO] $1"; }

  info "Тестирование функций в install.sh..."

  # Загружаем модули
  source "${MODULAR_SCRIPT_DIR}/lib/utils.sh"
  source "${MODULAR_SCRIPT_DIR}/lib/common.sh"

  local functions=(
    "prompt_inputs"
    "_step_system"
    "_step_firewall"
    "_step_fail2ban"
    "_step_singbox"
    "_step_ssl"
    "_step_decoy"
    "_step_traffic_shaping"
    "_step_telegram"
    "_generate_keys_and_ports"
  )

  for func in "${functions[@]}"; do
    if declare -f "$func" >/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция отсутствует: $func"
    fi
  done
}

# ── Тест: отсутствие дублирования кода ──────────────────────────────────────
test_code_duplication() {
  info "Тестирование отсутствия дублирования кода..."

  # Проверка что install.sh не содержит код Telegram бота
  if ! grep -q 'cubiveil-bot' "${MODULAR_SCRIPT_DIR}/install.sh" 2>/dev/null; then
    pass "install.sh: не содержит код Telegram бота (правильно)"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: содержит код Telegram бота (дублирование!)"
  fi

  # Проверка что lib/utils.sh не содержит специфичный код установки
  if ! grep -q 'step_' "${MODULAR_SCRIPT_DIR}/lib/utils.sh" 2>/dev/null; then
    pass "lib/utils.sh: не содержит функции step_* (правильно)"
    ((TESTS_PASSED++)) || true
  else
    warn "lib/utils.sh: содержит функции step_* (возможное дублирование)"
  fi
}

# ── Тест: размеры файлов ────────────────────────────────────────────────────
test_file_sizes() {
  info "Тестирование размеров файлов..."

  # Проверка что install.sh не слишком большой (рефакторинг удался)
  local install_size
  install_size=$(wc -l <"${MODULAR_SCRIPT_DIR}/install.sh" 2>/dev/null || echo "0")

  if [[ $install_size -lt 200 ]]; then
    pass "install.sh: компактный (${install_size} строк)"
    ((TESTS_PASSED++)) || true
  elif [[ $install_size -lt 500 ]]; then
    warn "install.sh: умеренного размера (${install_size} строк)"
  else
    fail "install.sh: слишком большой (${install_size} строк), нужен рефакторинг"
  fi

  # Проверка что setup-telegram.sh имеет разумный размер
  local telegram_size
  telegram_size=$(wc -l <"${MODULAR_SCRIPT_DIR}/setup-telegram.sh" 2>/dev/null || echo "0")

  if [[ $telegram_size -gt 0 ]]; then
    pass "setup-telegram.sh: содержит код (${telegram_size} строк)"
    ((TESTS_PASSED++)) || true
  else
    fail "setup-telegram.sh: пуст или не найден"
  fi

  # Проверка что lib/utils.sh имеет разумный размер
  local utils_size
  utils_size=$(wc -l <"${MODULAR_SCRIPT_DIR}/lib/utils.sh" 2>/dev/null || echo "0")

  if [[ $utils_size -gt 0 ]]; then
    pass "lib/utils.sh: содержит код (${utils_size} строк)"
    ((TESTS_PASSED++)) || true
  else
    fail "lib/utils.sh: пуст или не найден"
  fi
}

# ── Тест: интеграция модулей в install.sh ───────────────────────────────────
test_install_sh_integration() {
  info "Тестирование интеграции модулей в install.sh..."

  # Проверка что install.sh загружает модули
  if grep -q 'source.*lib/utils.sh' "${MODULAR_SCRIPT_DIR}/install.sh"; then
    pass "install.sh: загружает lib/utils.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: не загружает lib/utils.sh"
  fi

  # Проверка загрузки модулей из lib/core/ (s-ui архитектура)
  # install.sh использует lib/core/system.sh, lib/core/log.sh для s-ui
  if grep -qE 'source.*lib/core/' "${MODULAR_SCRIPT_DIR}/install.sh"; then
    pass "install.sh: загружает модули из lib/core/ (s-ui архитектура)"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: не загружает модули из lib/core/"
  fi

  # Проверка что install.sh использует функции из модулей
  if grep -q 'prompt_inputs\|_step_system\|_step_finish' "${MODULAR_SCRIPT_DIR}/install.sh"; then
    pass "install.sh: использует функции из модулей"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: не использует функции из модулей"
  fi
}

# shellcheck disable=SC2218
# ── Основная функция ────────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - Modular Structure           ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый проект: ${MODULAR_SCRIPT_DIR}"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────────────────────
  test_directory_structure
  echo ""

  test_main_files
  echo ""

  test_lib_modules
  echo ""

  test_test_files
  echo ""

  test_all_syntax
  echo ""

  test_executable
  echo ""

  test_module_loading
  echo ""

  test_utils_functions
  echo ""

  echo ""

  test_code_duplication
  echo ""

  test_file_sizes
  echo ""

  test_install_sh_integration
  echo ""

  # ── Итоги ─────────────────────────────────────────────────────────────────
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
