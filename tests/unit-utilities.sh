#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140
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
    "step_check_environment"
    "step_check_versions"
    "step_confirm_update"
    "step_create_backup"
    "step_download_update"
    "step_install_update"
    "step_update_sui"
    "step_restart_services"
    "step_finish"
    "main"
  )

  local found=0
  local missing_funcs=()
  for func in "${functions[@]}"; do
    if grep -q "${func}()" "${PROJECT_DIR}/utils/update.sh" 2>/dev/null; then
      ((found++)) || true
    else
      missing_funcs+=("$func")
    fi
  done

  if [[ $found -eq ${#functions[@]} ]]; then
    pass "update.sh: все функции существуют ($found/${#functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "update.sh: не все функции найдены ($found/${#functions[@]}). Отсутствуют: ${missing_funcs[*]}"
  fi
}

# ── Тест: функции в rollback.sh ──────────────────────────────────
test_rollback_functions() {
  info "Тестирование функций в rollback.sh..."

  local functions=(
    "step_check_environment"
    "step_select_backup"
    "step_validate_backup"
    "step_confirm_rollback"
    "step_stop_services"
    "step_restore_files"
    "step_restore_config"
    "step_start_services"
    "step_finish"
    "main"
  )

  local found=0
  local missing_funcs=()
  for func in "${functions[@]}"; do
    if grep -q "${func}()" "${PROJECT_DIR}/utils/rollback.sh" 2>/dev/null; then
      ((found++)) || true
    else
      missing_funcs+=("$func")
    fi
  done

  if [[ $found -eq ${#functions[@]} ]]; then
    pass "rollback.sh: все функции существуют ($found/${#functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "rollback.sh: не все функции найдены ($found/${#functions[@]}). Отсутствуют: ${missing_funcs[*]}"
  fi
}

# ── Тест: функции в diagnose.sh ──────────────────────────────────
test_diagnose_functions() {
  info "Тестирование функций в diagnose.sh..."

  local functions=(
    "step_check_environment"
    "step_check_dns"
    "step_check_ssl"
    "step_check_connections"
    "step_check_services"
    "step_check_ports"
    "step_analyze_logs"
    "step_check_resources"
    "step_generate_report"
    "step_recommendations"
    "main"
  )

  local found=0
  local missing_funcs=()
  for func in "${functions[@]}"; do
    if grep -q "${func}()" "${PROJECT_DIR}/utils/diagnose.sh" 2>/dev/null; then
      ((found++)) || true
    else
      missing_funcs+=("$func")
    fi
  done

  if [[ $found -eq ${#functions[@]} ]]; then
    pass "diagnose.sh: все функции существуют ($found/${#functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "diagnose.sh: не все функции найдены ($found/${#functions[@]}). Отсутствуют: ${missing_funcs[*]}"
  fi
}

# ── Тест: функции в export-config.sh ─────────────────────────────
test_export_functions() {
  info "Тестирование функций в export-config.sh..."

  local functions=(
    "step_check_environment"
    "step_prepare_export_dir"
    "step_collect_config"
    "step_collect_keys"
    "step_generate_manifest"
    "step_encrypt_sensitive"
    "step_create_archive"
    "step_finish"
    "main"
  )

  local found=0
  local missing_funcs=()
  for func in "${functions[@]}"; do
    if grep -q "${func}()" "${PROJECT_DIR}/utils/export-config.sh" 2>/dev/null; then
      ((found++)) || true
    else
      missing_funcs+=("$func")
    fi
  done

  if [[ $found -eq ${#functions[@]} ]]; then
    pass "export-config.sh: все функции существуют ($found/${#functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "export-config.sh: не все функции найдены ($found/${#functions[@]}). Отсутствуют: ${missing_funcs[*]}"
  fi
}

# ── Тест: функции в import-config.sh ─────────────────────────────
test_import_functions() {
  info "Тестирование функций в import-config.sh..."

  local functions=(
    "check_environment"
    "import_sui_config"
    "import_singbox_config"
    "import_cubiveil_config"
    "set_permissions"
    "restart_services"
    "step_finish"
    "main"
  )

  local found=0
  local missing_funcs=()
  for func in "${functions[@]}"; do
    if grep -q "${func}()" "${PROJECT_DIR}/utils/import-config.sh" 2>/dev/null; then
      ((found++)) || true
    else
      missing_funcs+=("$func")
    fi
  done

  if [[ $found -eq ${#functions[@]} ]]; then
    pass "import-config.sh: все функции существуют ($found/${#functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "import-config.sh: не все функции найдены ($found/${#functions[@]}). Отсутствуют: ${missing_funcs[*]}"
  fi
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
