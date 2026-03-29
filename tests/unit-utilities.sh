#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - Utilities                    ║
# ║        Тестирование утилит                                 ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ───────────────────────────────────
# Use PROJECT_DIR to avoid conflicts with test-utils.sh
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_DIR}/lib/test-utils.sh"
# For testing update steps
source "${PROJECT_DIR}/utils/update.sh" 2>/dev/null || true

# ── Тест: наличие утилит ─────────────────────────────────────────
test_utilities_exist() {
  info "Тестирование наличия утилит..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if [[ -f "${PROJECT_DIR}/${util}" ]]; then
      pass "Утилита существует: $util"
      ((TESTS_PASSED++)) || true
    else
      fail "Утилита отсутствует: $util"
    fi
  done
}

# ── Тест: синтаксис утилит ───────────────────────────────────────
test_utilities_syntax() {
  info "Тестирование синтаксиса утилит..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if [[ -f "${PROJECT_DIR}/${util}" ]]; then
      if bash -n "${PROJECT_DIR}/${util}" 2>/dev/null; then
        pass "Синтаксис OK: $util"
        ((TESTS_PASSED++)) || true
      else
        fail "Синтаксическая ошибка: $util"
      fi
    fi
  done
}

# ── Тест: заголовок shebang ──────────────────────────────────────
test_shebang() {
  info "Тестирование shebang утилит..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    local first_line
    first_line=$(head -1 "${PROJECT_DIR}/${util}" 2>/dev/null || echo "")

    if [[ "$first_line" == "#!/bin/bash" ]]; then
      pass "Shebang OK: $util"
      ((TESTS_PASSED++)) || true
    else
      fail "Неверный shebang: $util ($first_line)"
    fi
  done
}

# ── Тест: безопасность (set -euo pipefail) ───────────────────────
test_safety_flags() {
  info "Тестирование флагов безопасности..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if grep -q "set -euo pipefail" "${PROJECT_DIR}/${util}" 2>/dev/null; then
      pass "Флаги безопасности: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "Нет флагов безопасности: $util"
    fi
  done
}

# ── Тест: локализация ────────────────────────────────────────────
test_localization() {
  info "Тестирование локализации..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    # Проверка подключения lang/main.sh
    if grep -q 'source.*lang/main.sh\|source.*fallback.sh' "${PROJECT_DIR}/${util}" 2>/dev/null; then
      pass "Локализация подключена: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "Локализация не подключена: $util"
    fi
  done
}

# ── Тест: проверка root прав ─────────────────────────────────────
test_root_check() {
  info "Тестирование проверки root прав..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if grep -qE 'EUID.*-ne.*0|root' "${PROJECT_DIR}/${util}" 2>/dev/null; then
      pass "Проверка root: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "Нет проверки root: $util"
    fi
  done
}

# ── Тест: функции в update.sh ────────────────────────────────────
test_update_functions() {
  info "Тестирование функций в update.sh..."

  local functions=(
    "step_update_marzban"
    "step_update_singbox"
    "step_update_cubiveil"
    "run_update"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${PROJECT_DIR}/utils/update.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Функция не найдена: $func"
    fi
  done
}

# ── Тест: функции в rollback.sh ──────────────────────────────────
test_rollback_functions() {
  info "Тестирование функций в rollback.sh..."

  local functions=(
    "step_check_environment"
    "step_select_backup"
    "step_restore"
    "run_rollback"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${PROJECT_DIR}/utils/rollback.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Функция не найдена: $func"
    fi
  done
}

# ── Тест: функции в diagnose.sh ──────────────────────────────────
test_diagnose_functions() {
  info "Тестирование функций в diagnose.sh..."

  local functions=(
    "check_system"
    "check_services"
    "check_network"
    "run_diagnose"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${PROJECT_DIR}/utils/diagnose.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Функция не найдена: $func"
    fi
  done
}

# ── Тест: функции в export-config.sh ─────────────────────────────
test_export_functions() {
  info "Тестирование функций в export-config.sh..."

  local functions=(
    "export_config"
    "run_export"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${PROJECT_DIR}/utils/export-config.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Функция не найдена: $func"
    fi
  done
}

# ── Тест: функции в import-config.sh ─────────────────────────────
test_import_functions() {
  info "Тестирование функций в import-config.sh..."

  local functions=(
    "import_config"
    "run_import"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${PROJECT_DIR}/utils/import-config.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Функция не найдена: $func"
    fi
  done
}

# ── Тест: install-aliases.sh ─────────────────────────────────────
test_install_aliases() {
  info "Тестирование install-aliases.sh..."

  local aliases_file="${PROJECT_DIR}/utils/install-aliases.sh"

  if [[ ! -f "$aliases_file" ]]; then
    fail "install-aliases.sh не найден"
    return
  fi

  # Проверка синтаксиса
  if bash -n "$aliases_file" 2>/dev/null; then
    pass "install-aliases.sh: синтаксис OK"
    ((TESTS_PASSED++)) || true
  else
    fail "install-aliases.sh: синтаксическая ошибка"
  fi

  # Проверка shebang
  local first_line
  first_line=$(head -1 "$aliases_file" 2>/dev/null || echo "")
  if [[ "$first_line" == "#!/bin/bash" ]]; then
    pass "install-aliases.sh: shebang OK"
    ((TESTS_PASSED++)) || true
  else
    fail "install-aliases.sh: неверный shebang"
  fi

  # Проверка флагов безопасности
  if grep -q "set -euo pipefail" "$aliases_file" 2>/dev/null; then
    pass "install-aliases.sh: флаги безопасности"
    ((TESTS_PASSED++)) || true
  else
    warn "install-aliases.sh: нет флагов безопасности"
  fi
}

# ── Тест: Python health check модуль ─────────────────────────────
test_python_health_check() {
  info "Тестирование Python health check модуля..."

  local health_check_file="${PROJECT_DIR}/assets/telegram-bot/health_check.py"

  if [[ ! -f "$health_check_file" ]]; then
    warn "health_check.py не найден"
    return
  fi

  # Проверка синтаксиса
  if python3 -m py_compile "$health_check_file" 2>/dev/null; then
    pass "health_check.py: синтаксис OK"
    ((TESTS_PASSED++)) || true
  else
    fail "health_check.py: синтаксическая ошибка"
  fi
}

# ── Тест: обновлённый bot.py ─────────────────────────────────────
test_bot_py() {
  info "Тестирование обновлённого bot.py..."

  local bot_file="${PROJECT_DIR}/assets/telegram-bot/bot.py"

  if [[ ! -f "$bot_file" ]]; then
    warn "bot.py не найден"
    return
  fi

  # Проверка синтаксиса
  if python3 -m py_compile "$bot_file" 2>/dev/null; then
    pass "bot.py: синтаксис OK"
    ((TESTS_PASSED++)) || true
  else
    fail "bot.py: синтаксическая ошибка"
  fi
}

# ── Тест: обновлённый commands.py ────────────────────────────────
test_commands_py() {
  info "Тестирование обновлённого commands.py..."

  local commands_file="${PROJECT_DIR}/assets/telegram-bot/commands.py"

  if [[ ! -f "$commands_file" ]]; then
    warn "commands.py не найден"
    return
  fi

  # Проверка синтаксиса
  if python3 -m py_compile "$commands_file" 2>/dev/null; then
    pass "commands.py: синтаксис OK"
    ((TESTS_PASSED++)) || true
  else
    fail "commands.py: синтаксическая ошибка"
  fi

  # Проверка наличия SERVICE_LOG_MAP
  if grep -q "SERVICE_LOG_MAP" "$commands_file" 2>/dev/null; then
    pass "commands.py: SERVICE_LOG_MAP существует"
    ((TESTS_PASSED++)) || true
  else
    warn "commands.py: SERVICE_LOG_MAP не найден"
  fi

  # Проверка наличия MarzbanClient
  if grep -q "class MarzbanClient" "$commands_file" 2>/dev/null; then
    pass "commands.py: MarzbanClient существует"
    ((TESTS_PASSED++)) || true
  else
    warn "commands.py: MarzbanClient не найден"
  fi
}

# ── Основная функция ─────────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - New Utilities                 ║${PLAIN}"
  echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый проект: ${PROJECT_DIR}"
  echo ""

  # ── Запуск тестов ───────────────────────────────────────────────
  test_utilities_exist
  echo ""

  test_utilities_syntax
  echo ""

  test_shebang
  echo ""

  test_safety_flags
  echo ""

  test_localization
  echo ""

  test_root_check
  echo ""

  test_update_functions
  echo ""

  test_rollback_functions
  echo ""

  test_diagnose_functions
  echo ""

  test_export_functions
  echo ""

  test_import_functions
  echo ""

  test_install_aliases
  echo ""

  test_python_health_check
  echo ""

  test_bot_py
  echo ""

  test_commands_py
  echo ""

  # ── Итоги ─────────────────────────────────────────────────────
  print_test_summary
}

main "$@"
