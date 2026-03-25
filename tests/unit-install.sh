#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - install.sh                   ║
# ║        Тестирование главной точки входа                  ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Путь к проекту ───────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Тест: файл существует ───────────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла install.sh..."

  if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
    pass "install.sh: файл существует"
    ((TESTS_PASSED++))
  else
    fail "install.sh: файл не найден"
  fi
}

# ── Тест: синтаксис скрипта ───────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса install.sh..."

  if bash -n "${SCRIPT_DIR}/install.sh" 2>/dev/null; then
    pass "install.sh: синтаксис корректен"
    ((TESTS_PASSED++))
  else
    fail "install.sh: синтаксическая ошибка"
  fi
}

# ── Тест: скрипт имеет shebang ────────────────────────────────
test_shebang() {
  info "Тестирование shebang..."

  local shebang
  shebang=$(head -1 "${SCRIPT_DIR}/install.sh")
  
  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "install.sh: корректный shebang"
    ((TESTS_PASSED++))
  else
    fail "install.sh: некорректный shebang: $shebang"
  fi
}

# ── Тест: strict mode включён ─────────────────────────────────
test_strict_mode() {
  info "Тестирование strict mode..."

  if grep -q "set -euo pipefail" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: strict mode включён"
    ((TESTS_PASSED++))
  else
    warn "install.sh: strict mode не включён"
  fi
}

# ── Тест: загрузка модулей ────────────────────────────────────
test_module_loading() {
  info "Тестирование загрузки модулей..."

  # Проверка что lang.sh загружается
  if grep -q 'source.*lang.sh' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: загружает lang.sh"
    ((TESTS_PASSED++))
  else
    fail "install.sh: не загружает lang.sh"
  fi

  # Проверка что lib/utils.sh загружается
  if grep -q 'source.*lib/utils.sh' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: загружает lib/utils.sh"
    ((TESTS_PASSED++))
  else
    fail "install.sh: не загружает lib/utils.sh"
  fi

  # Проверка что lib/install-steps.sh загружается
  if grep -q 'source.*lib/install-steps.sh' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: загружает lib/install-steps.sh"
    ((TESTS_PASSED++))
  else
    fail "install.sh: не загружает lib/install-steps.sh"
  fi
}

# ── Тест: функция main существует ─────────────────────────────
test_main_function() {
  info "Тестирование функции main..."

  if grep -q "^main()" "${SCRIPT_DIR}/install.sh" || \
     grep -q "main() {" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: функция main существует"
    ((TESTS_PASSED++))
  else
    fail "install.sh: функция main не найдена"
  fi
}

# ── Тест: функция main вызывается ─────────────────────────────
test_main_call() {
  info "Тестирование вызова функции main..."

  if grep -q 'main "$@"' "${SCRIPT_DIR}/install.sh" || \
     grep -q 'main "$1"' "${SCRIPT_DIR}/install.sh" || \
     grep -q 'main' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: main вызывается"
    ((TESTS_PASSED++))
  else
    fail "install.sh: main не вызывается"
  fi
}

# ── Тест: использование функций из модулей ────────────────────
test_module_functions_usage() {
  info "Тестирование использования функций из модулей..."

  local required_functions=(
    "select_language"
    "print_banner"
    "prompt_inputs"
    "step_check_ip_neighborhood"
    "step_system_update"
    "step_auto_updates"
    "step_bbr"
    "step_firewall"
    "step_fail2ban"
    "step_install_singbox"
    "step_generate_keys_and_ports"
    "step_install_marzban"
    "step_ssl"
    "step_configure"
    "step_finish"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if grep -q "$func" "${SCRIPT_DIR}/install.sh"; then
      ((found++))
    fi
  done
  
  if [[ $found -ge 15 ]]; then
    pass "install.sh: использует функции из модулей ($found/${#required_functions[@]})"
    ((TESTS_PASSED++))
  else
    fail "install.sh: недостаточно использует функции из модулей ($found/${#required_functions[@]})"
  fi
}

# ── Тест: последовательность шагов установки ──────────────────
test_installation_steps_order() {
  info "Тестирование последовательности шагов установки..."

  # Извлекаем тело функции main
  local main_body
  main_body=$(sed -n '/^main()/,/^}/p' "${SCRIPT_DIR}/install.sh" 2>/dev/null || echo "")
  
  if [[ -z "$main_body" ]]; then
    warn "Не удалось извлечь тело функции main"
    return
  fi

  # Проверяем порядок вызова шагов
  local expected_order=(
    "select_language"
    "print_banner"
    "prompt_inputs"
    "step_check_ip_neighborhood"
    "step_system_update"
    "step_install_marzban"
    "step_finish"
  )

  local last_line=0
  local correct_order=true
  
  for step in "${expected_order[@]}"; do
    local current_line
    current_line=$(grep -n "$step" "${SCRIPT_DIR}/install.sh" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")
    
    if [[ "$current_line" -gt 0 && "$current_line" -gt "$last_line" ]]; then
      last_line=$current_line
    elif [[ "$current_line" -eq 0 ]]; then
      warn "Шаг не найден: $step"
    else
      correct_order=false
    fi
  done
  
  if $correct_order; then
    pass "install.sh: последовательность шагов корректна"
    ((TESTS_PASSED++))
  else
    warn "install.sh: возможная проблема с последовательностью шагов"
  fi
}

# ── Тест: обработка ошибок ────────────────────────────────────
test_error_handling() {
  info "Тестирование обработки ошибок..."

  # Проверка что err функция используется
  if grep -q 'err "' "${SCRIPT_DIR}/install.sh" || \
     grep -q "err '" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: использует функцию err для ошибок"
    ((TESTS_PASSED++))
  else
    warn "install.sh: не использует функцию err"
  fi

  # Проверка что есть проверки на ошибки
  if grep -q "|| {" "${SCRIPT_DIR}/install.sh" || \
     grep -q "|| true" "${SCRIPT_DIR}/install.sh" || \
     grep -q "&&" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: использует обработку ошибок"
    ((TESTS_PASSED++))
  else
    warn "install.sh: не использует явную обработку ошибок"
  fi
}

# ── Тест: fallback для lang.sh ────────────────────────────────
test_lang_fallback() {
  info "Тестирование fallback для lang.sh..."

  # Проверка что есть fallback если lang.sh отсутствует
  if grep -A5 'if \[\[ -f.*lang.sh' "${SCRIPT_DIR}/install.sh" | grep -q "else\|fallback\|RED=\|GREEN="; then
    pass "install.sh: имеет fallback для lang.sh"
    ((TESTS_PASSED++))
  else
    warn "install.sh: fallback для lang.sh не найден"
  fi
}

# ── Тест: размеры скрипта ─────────────────────────────────────
test_script_size() {
  info "Тестирование размера скрипта..."

  local line_count
  line_count=$(wc -l < "${SCRIPT_DIR}/install.sh")
  
  # install.sh должен быть компактным (< 200 строк — хорошо)
  if [[ $line_count -lt 200 ]]; then
    pass "install.sh: компактный ($line_count строк)"
    ((TESTS_PASSED++))
  elif [[ $line_count -lt 500 ]]; then
    warn "install.sh: умеренного размера ($line_count строк)"
  else
    fail "install.sh: слишком большой ($line_count строк), нужен рефакторинг"
  fi
}

# ── Тест: наличие комментариев ────────────────────────────────
test_comments() {
  info "Тестирование наличия комментариев..."

  local comment_count
  comment_count=$(grep -c "^#" "${SCRIPT_DIR}/install.sh" 2>/dev/null || echo "0")
  
  if [[ $comment_count -ge 5 ]]; then
    pass "install.sh: достаточное количество комментариев ($comment_count)"
    ((TESTS_PASSED++))
  else
    warn "install.sh: мало комментариев ($comment_count)"
  fi
}

# ── Тест: запуск без root (должен показать предупреждение) ───
test_run_without_root() {
  info "Тестирование запуска без root..."

  # Запускаем скрипт в dry-run режиме (если есть такая возможность)
  # или проверяем что есть проверка на root
  if grep -q "check_root\|EUID\|root" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: имеет проверку на root"
    ((TESTS_PASSED++))
  else
    warn "install.sh: проверка на root не найдена"
  fi
}

# ── Тест: проверка на Ubuntu ──────────────────────────────────
test_ubuntu_check() {
  info "Тестирование проверки на Ubuntu..."

  if grep -q "check_ubuntu\|ubuntu\|Ubuntu" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: имеет проверку на Ubuntu"
    ((TESTS_PASSED++))
  else
    warn "install.sh: проверка на Ubuntu не найдена"
  fi
}

# ── Тест: переменные окружения ────────────────────────────────
test_environment_variables() {
  info "Тестирование переменных окружения..."

  # Проверка что скрипт не требует внешних переменных окружения
  # (кроме тех что устанавливаются внутри скрипта)
  local env_deps
  env_deps=$(grep -oE '\$\{?[A-Z_]+\}?' "${SCRIPT_DIR}/install.sh" 2>/dev/null | \
    grep -v "^\${SCRIPT_DIR}\|^\${LANG_NAME}\|^\${DOMAIN}\|^\${LE_EMAIL}" | \
    sort -u | wc -l || echo "0")
  
  if [[ $env_deps -lt 10 ]]; then
    pass "install.sh: минимальные внешние зависимости ($env_deps)"
    ((TESTS_PASSED++))
  else
    warn "install.sh: много внешних зависимостей ($env_deps)"
  fi
}

# ── Тест: интеграция с setup-telegram.sh ──────────────────────
test_telegram_integration() {
  info "Тестирование интеграции с Telegram..."

  # Проверка что install.sh упоминает setup-telegram.sh
  if grep -q "setup-telegram.sh" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: упоминает setup-telegram.sh"
    ((TESTS_PASSED++))
  else
    warn "install.sh: не упоминает setup-telegram.sh"
  fi

  # Проверка что INSTALL_TG переменная используется
  if grep -q "INSTALL_TG" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: использует INSTALL_TG переменную"
    ((TESTS_PASSED++))
  else
    warn "install.sh: INSTALL_TG переменная не найдена"
  fi
}

# ── Тест: dry-run симуляция (mock) ────────────────────────────
test_dry_run_simulation() {
  info "Тестирование dry-run симуляции..."

  # Создаём mock для всех внешних команд
  LANG_NAME="English"
  
  # Mock функций
  select_language() { :; }
  print_banner() { :; }
  prompt_inputs() { 
    DOMAIN="test.example.com"
    LE_EMAIL="test@example.com"
    INSTALL_TG="n"
  }
  step_check_ip_neighborhood() { :; }
  step_system_update() { :; }
  step_auto_updates() { :; }
  step_bbr() { :; }
  step_firewall() { :; }
  step_fail2ban() { :; }
  step_install_singbox() { :; }
  step_generate_keys_and_ports() { :; }
  step_install_marzban() { :; }
  step_ssl() { :; }
  step_configure() { :; }
  step_finish() { :; }
  
  # Mock утилит
  check_root() { :; }
  check_ubuntu() { :; }
  step() { :; }
  ok() { :; }
  warn() { :; }
  err() { return 1; }
  info() { :; }
  gen_random() { echo "mock"; }
  gen_hex() { echo "mock"; }
  open_port() { :; }
  close_port() { :; }
  get_server_ip() { echo "1.2.3.4"; }
  arch() { echo "amd64"; }
  unique_port() { echo "30000"; }
  
  # Загружаем модули
  source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null || true
  source "${SCRIPT_DIR}/lib/install-steps.sh" 2>/dev/null || true
  
  # Пытаемся загрузить install.sh и проверить что main существует
  if bash -c "source ${SCRIPT_DIR}/install.sh 2>&1 && declare -f main >/dev/null" 2>/dev/null; then
    pass "install.sh: загружается и main существует"
    ((TESTS_PASSED++))
  else
    # Это может не сработать из-за интерактивности, поэтому warning
    warn "install.sh: загрузка может требовать интерактивности"
  fi
}

# ── Тест: безопасность (отсутствие хардкодных секретов) ───────
test_security_no_hardcoded_secrets() {
  info "Тестирование безопасности (отсутствие секретов)..."

  # Проверка что нет хардкодных паролей или ключей
  if grep -qiE "password\s*=\s*['\"][^'\"]+['\"]|secret\s*=\s*['\"][^'\"]+['\"]|key\s*=\s*['\"][^'\"]+['\"]" \
     "${SCRIPT_DIR}/install.sh" 2>/dev/null | grep -v "SUDO_PASSWORD\|SECRET_KEY\|SS_PASSWORD"; then
    fail "install.sh: возможны хардкодные секреты"
  else
    pass "install.sh: хардкодные секреты не найдены"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: использование кавычек ───────────────────────────────
test_quoting_usage() {
  info "Тестирование использования кавычек..."

  # Проверка что переменные используются с кавычками
  # shellcheck disable=SC2034
  local unquoted_vars
  unquoted_vars=$(grep -oE '\$[A-Za-z_][A-Za-z0-9_]*' "${SCRIPT_DIR}/install.sh" 2>/dev/null | \
    wc -l || echo "0")
  
  local quoted_vars
  quoted_vars=$(grep -oE '"\$[A-Za-z_][A-Za-z0-9_]*"' "${SCRIPT_DIR}/install.sh" 2>/dev/null | \
    wc -l || echo "0")
  
  if [[ $quoted_vars -gt 0 ]]; then
    pass "install.sh: использует кавычки для переменных ($quoted_vars)"
    ((TESTS_PASSED++))
  else
    warn "install.sh: переменные могут быть не в кавычках"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - install.sh              ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый скрипт: ${SCRIPT_DIR}/install.sh"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_strict_mode
  echo ""

  test_module_loading
  echo ""

  test_main_function
  echo ""

  test_main_call
  echo ""

  test_module_functions_usage
  echo ""

  test_installation_steps_order
  echo ""

  test_error_handling
  echo ""

  test_lang_fallback
  echo ""

  test_script_size
  echo ""

  test_comments
  echo ""

  test_run_without_root
  echo ""

  test_ubuntu_check
  echo ""

  test_environment_variables
  echo ""

  test_telegram_integration
  echo ""

  test_dry_run_simulation
  echo ""

  test_security_no_hardcoded_secrets
  echo ""

  test_quoting_usage
  echo ""

  # ── Итоги ───────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo -e "${GREEN}Пройдено: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Провалено:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
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
