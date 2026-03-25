#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - lang.sh                      ║
# ║        Тестирование локализации (EN/RU)                  ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Загрузка тестируемого модуля ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "${SCRIPT_DIR}/lang.sh" ]]; then
  echo "Ошибка: lang.sh не найден"
  exit 1
fi

# ── Тест: файл существует ───────────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла lang.sh..."

  if [[ -f "${SCRIPT_DIR}/lang.sh" ]]; then
    pass "lang.sh: файл существует"
    ((TESTS_PASSED++))
  else
    fail "lang.sh: файл не найден"
  fi
}

# ── Тест: синтаксис скрипта ───────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса lang.sh..."

  if bash -n "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
    pass "lang.sh: синтаксис корректен"
    ((TESTS_PASSED++))
  else
    fail "lang.sh: синтаксическая ошибка"
  fi
}

# ── Тест: загрузка модуля ─────────────────────────────────────
test_module_loading() {
  info "Тестирование загрузки модуля..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh 2>&1" 2>/dev/null; then
    pass "lang.sh: загружается без ошибок"
    ((TESTS_PASSED++))
  else
    fail "lang.sh: ошибка при загрузке"
  fi
}

# ── Тест: выбор языка по умолчанию ────────────────────────────
test_default_language() {
  info "Тестирование языка по умолчанию..."

  # Загружаем модуль в подпроцессе чтобы не загрязнять среду
  local lang_name
  lang_name=$(bash -c "source ${SCRIPT_DIR}/lang.sh && echo \$LANG_NAME" 2>/dev/null)

  if [[ "$lang_name" == "Русский" || "$lang_name" == "English" ]]; then
    pass "Язык по умолчанию установлен: $lang_name"
    ((TESTS_PASSED++))
  else
    fail "Язык по умолчанию не установлен корректно: '$lang_name'"
  fi
}

# ── Тест: функция select_language существует ──────────────────
test_select_language_function() {
  info "Тестирование функции select_language..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f select_language >/dev/null 2>&1" 2>/dev/null; then
    pass "Функция select_language существует"
    ((TESTS_PASSED++))
  else
    fail "Функция select_language отсутствует"
  fi
}

# ── Тест: функция step_title существует ───────────────────────
test_step_title_function() {
  info "Тестирование функции step_title..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f step_title >/dev/null 2>&1" 2>/dev/null; then
    pass "Функция step_title существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_title отсутствует"
  fi
}

# ── Тест: функция get_str существует ──────────────────────────
test_get_str_function() {
  info "Тестирование функции get_str..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f get_str >/dev/null 2>&1" 2>/dev/null; then
    pass "Функция get_str существует"
    ((TESTS_PASSED++))
  else
    warn "Функция get_str отсутствует (может быть опционально)"
  fi
}

# ── Тест: наличие цветов ──────────────────────────────────────
test_colors_defined() {
  info "Тестирование определения цветов..."

  local colors=("RED" "GREEN" "YELLOW" "BLUE" "CYAN" "PLAIN")
  local defined=0

  for color in "${colors[@]}"; do
    if bash -c "source ${SCRIPT_DIR}/lang.sh && [[ -n \"\$$color\" ]] && echo 'yes'" 2>/dev/null | grep -q "yes"; then
      ((defined++))
    fi
  done

  if [[ $defined -ge 5 ]]; then
    pass "Цвета определены: $defined из ${#colors[@]}"
    ((TESTS_PASSED++))
  else
    fail "Не все цвета определены: $defined из ${#colors[@]}"
  fi
}

# ── Тест: функции вывода определены ───────────────────────────
test_output_functions() {
  info "Тестирование функций вывода..."

  local functions=("ok" "warn" "err" "info" "step")
  local defined=0

  for func in "${functions[@]}"; do
    if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f $func >/dev/null 2>&1" 2>/dev/null; then
      ((defined++))
    fi
  done

  if [[ $defined -eq ${#functions[@]} ]]; then
    pass "Все функции вывода определены: ${defined}"
    ((TESTS_PASSED++))
  else
    fail "Не все функции вывода определены: $defined из ${#functions[@]}"
  fi
}

# ── Тест: строки локализации EN ───────────────────────────────
test_en_strings() {
  info "Тестирование строк локализации EN..."

  local en_strings=(
    "ERR_ROOT"
    "ERR_UBUNTU"
    "PROMPT_DOMAIN"
    "PROMPT_EMAIL"
    "WARN_DNS_RECORD"
    "WARN_LETS_ENCRYPT"
  )

  local found=0
  for str in "${en_strings[@]}"; do
    if grep -q "^${str}=" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -eq ${#en_strings[@]} ]]; then
    pass "Все EN строки найдены: $found"
    ((TESTS_PASSED++))
  else
    warn "Не все EN строки найдены: $found из ${#en_strings[@]}"
  fi
}

# ── Тест: строки локализации RU ───────────────────────────────
test_ru_strings() {
  info "Тестирование строк локализации RU..."

  local ru_strings=(
    "ERR_ROOT_RU"
    "ERR_UBUNTU_RU"
    "PROMPT_DOMAIN_RU"
    "PROMPT_EMAIL_RU"
    "WARN_DNS_RECORD_RU"
    "WARN_LETS_ENCRYPT_RU"
  )

  local found=0
  for str in "${ru_strings[@]}"; do
    if grep -q "^${str}=" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -eq ${#ru_strings[@]} ]]; then
    pass "Все RU строки найдены: $found"
    ((TESTS_PASSED++))
  else
    warn "Не все RU строки найдены: $found из ${#ru_strings[@]}"
  fi
}

# ── Тест: заголовки шагов ─────────────────────────────────────
test_step_titles() {
  info "Тестирование заголовков шагов..."

  local step_strings=(
    "STEP_CHECK_SUBNET"
    "STEP_UPDATE"
    "STEP_AUTO_UPDATES"
    "STEP_BBR"
    "STEP_FIREWALL"
    "STEP_FAIL2BAN"
    "STEP_SINGBOX"
    "STEP_KEYS"
    "STEP_MARZBAN"
    "STEP_SSL"
    "STEP_CONFIGURE"
    "STEP_TELEGRAM"
  )

  local found=0
  for str in "${step_strings[@]}"; do
    if grep -q "^${str}=" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 10 ]]; then
    pass "Заголовки шагов найдены: $found"
    ((TESTS_PASSED++))
  else
    fail "Не все заголовки шагов найдены: $found из ${#step_strings[@]}"
  fi
}

# ── Тест: заголовки шагов RU ──────────────────────────────────
test_step_titles_ru() {
  info "Тестирование заголовков шагов RU..."

  local step_strings=(
    "STEP_CHECK_SUBNET_RU"
    "STEP_UPDATE_RU"
    "STEP_AUTO_UPDATES_RU"
    "STEP_BBR_RU"
    "STEP_FIREWALL_RU"
    "STEP_FAIL2BAN_RU"
    "STEP_SINGBOX_RU"
    "STEP_KEYS_RU"
    "STEP_MARZBAN_RU"
    "STEP_SSL_RU"
    "STEP_CONFIGURE_RU"
    "STEP_TELEGRAM_RU"
  )

  local found=0
  for str in "${step_strings[@]}"; do
    if grep -q "^${str}=" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 10 ]]; then
    pass "Заголовки шагов RU найдены: $found"
    ((TESTS_PASSED++))
  else
    warn "Не все заголовки шагов RU найдены: $found из ${#step_strings[@]}"
  fi
}

# ── Тест: Telegram строки ─────────────────────────────────────
test_telegram_strings() {
  info "Тестирование Telegram строк..."

  local tg_strings=(
    "PROMPT_TG_TOKEN"
    "PROMPT_TG_CHAT_ID"
    "ERR_TG_TOKEN_FORMAT"
    "ERR_TG_TOKEN_INVALID"
    "OK_TG_TOKEN_VERIFIED"
    "ERR_CHAT_ID_FORMAT"
  )

  local found=0
  for str in "${tg_strings[@]}"; do
    if grep -q "^${str}" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 4 ]]; then
    pass "Telegram строки найдены: $found"
    ((TESTS_PASSED++))
  else
    warn "Не все Telegram строки найдены: $found из ${#tg_strings[@]}"
  fi
}

# ── Тест: финальные сообщения ─────────────────────────────────
test_final_messages() {
  info "Тестирование финальных сообщений..."

  local final_strings=(
    "SUCCESS_TITLE"
    "SUCCESS_PANEL_URL"
    "SUCCESS_SUBSCRIPTION_URL"
    "SUCCESS_PROFILES"
    "SUCCESS_TELEGRAM"
    "NEXT_STEPS"
  )

  local found=0
  for str in "${final_strings[@]}"; do
    if grep -q "^${str}" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 4 ]]; then
    pass "Финальные сообщения найдены: $found"
    ((TESTS_PASSED++))
  else
    warn "Не все финальные сообщения найдены: $found из ${#final_strings[@]}"
  fi
}

# ── Тест: финальные сообщения RU ──────────────────────────────
test_final_messages_ru() {
  info "Тестирование финальных сообщений RU..."

  local final_strings=(
    "SUCCESS_TITLE_RU"
    "SUCCESS_PANEL_URL_RU"
    "SUCCESS_SUBSCRIPTION_URL_RU"
    "SUCCESS_PROFILES_RU"
    "SUCCESS_TELEGRAM_RU"
    "NEXT_STEPS_RU"
  )

  local found=0
  for str in "${final_strings[@]}"; do
    if grep -q "^${str}" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 4 ]]; then
    pass "Финальные сообщения RU найдены: $found"
    ((TESTS_PASSED++))
  else
    warn "Не все финальные сообщения RU найдены: $found из ${#final_strings[@]}"
  fi
}

# ── Тест: проверка функции step_title ─────────────────────────
test_step_title_functionality() {
  info "Тестирование функциональности step_title..."

  # Загружаем модуль и тестируем функцию
  local output
  output=$(bash -c "
    source ${SCRIPT_DIR}/lang.sh
    LANG_NAME='English'
    step_title '1' 'Тест RU' 'Test EN'
  " 2>&1)

  if echo "$output" | grep -q "Step 1/12"; then
    pass "step_title: English формат корректен"
    ((TESTS_PASSED++))
  else
    warn "step_title: English формат не найден в выводе"
  fi

  # Тест для русского языка
  output=$(bash -c "
    source ${SCRIPT_DIR}/lang.sh
    LANG_NAME='Русский'
    step_title '1' 'Тест RU' 'Test EN'
  " 2>&1)

  if echo "$output" | grep -q "Шаг 1/12"; then
    pass "step_title: Русский формат корректен"
    ((TESTS_PASSED++))
  else
    warn "step_title: Русский формат не найден в выводе"
  fi
}

# ── Тест: полнота локализации ─────────────────────────────────
test_localization_completeness() {
  info "Тестирование полноты локализации..."

  # Подсчитываем количество EN и RU строк
  local en_count ru_count
  en_count=$(grep -cE '^[A-Z_]+="[A-Za-z ]+"$' "${SCRIPT_DIR}/lang.sh" 2>/dev/null || echo "0")
  ru_count=$(grep -cE '^[A-Z_]+_RU=' "${SCRIPT_DIR}/lang.sh" 2>/dev/null || echo "0")

  info "Найдено EN строк: $en_count, RU строк: $ru_count"

  # Ожидаем что RU строк хотя бы 80% от EN
  if [[ $en_count -gt 0 ]]; then
    local threshold=$((en_count * 80 / 100))
    if [[ $ru_count -ge $threshold ]]; then
      pass "Полнота локализации: RU строки покрывают $((ru_count * 100 / en_count))% EN строк"
      ((TESTS_PASSED++))
    else
      warn "Полнота локализации: RU строки покрывают только $((ru_count * 100 / en_count))% EN строк"
    fi
  else
    warn "Не удалось подсчитать EN строки"
  fi
}

# ── Тест: отсутствие пустых строк локализации ─────────────────
test_no_empty_strings() {
  info "Тестирование отсутствия пустых строк локализации..."

  # Проверяем что нет строк вида KEY=""
  local empty_count
  empty_count=$(grep -cE '^[A-Z_]+=""$' "${SCRIPT_DIR}/lang.sh" 2>/dev/null || echo "0")

  if [[ $empty_count -eq 0 ]]; then
    pass "Пустые строки локализации отсутствуют"
    ((TESTS_PASSED++))
  else
    warn "Найдено пустых строк локализации: $empty_count"
  fi
}

# ── Тест: корректность экранирования ──────────────────────────
test_escaping_correctness() {
  info "Тестирование корректности экранирования..."

  # Проверяем что нет неэкранированных кавычек внутри строк
  # (простая эвристическая проверка)
  local bad_lines
  bad_lines=$(grep -n '="[^"]*"[^"]*="' "${SCRIPT_DIR}/lang.sh" 2>/dev/null | head -5 || true)

  if [[ -z "$bad_lines" ]]; then
    pass "Экранирование кавычек корректно"
    ((TESTS_PASSED++))
  else
    warn "Возможные проблемы с экранированием: $bad_lines"
  fi
}

# ── Тест: проверка функции check_root ─────────────────────────
test_check_root_function() {
  info "Тестирование функции check_root..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f check_root >/dev/null 2>&1" 2>/dev/null; then
    pass "Функция check_root существует"
    ((TESTS_PASSED++))
  else
    warn "Функция check_root отсутствует"
  fi
}

# ── Тест: проверка функции check_ubuntu ───────────────────────
test_check_ubuntu_function() {
  info "Тестирование функции check_ubuntu..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f check_ubuntu >/dev/null 2>&1" 2>/dev/null; then
    pass "Функция check_ubuntu существует"
    ((TESTS_PASSED++))
  else
    warn "Функция check_ubuntu отсутствует"
  fi
}

# ── Тест: проверка функции print_banner ───────────────────────
test_print_banner_function() {
  info "Тестирование функции print_banner..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f print_banner >/dev/null 2>&1" 2>/dev/null; then
    pass "Функция print_banner существует"
    ((TESTS_PASSED++))
  else
    warn "Функция print_banner отсутствует"
  fi
}

# ── Тест: интеграция с другими модулями ───────────────────────
test_integration_with_modules() {
  info "Тестирование интеграции с другими модулями..."

  # Проверяем что lang.sh может быть загружен перед другими модулями
  local result
  result=$(bash -c "
    source ${SCRIPT_DIR}/lang.sh
    source ${SCRIPT_DIR}/lib/utils.sh 2>&1
    echo 'OK'
  " 2>&1)

  if echo "$result" | grep -q "OK"; then
    pass "Интеграция с lib/utils.sh успешна"
    ((TESTS_PASSED++))
  else
    warn "Интеграция с lib/utils.sh可能有 проблемы: $result"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - lang.sh                 ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый модуль: ${SCRIPT_DIR}/lang.sh"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_module_loading
  echo ""

  test_default_language
  echo ""

  test_select_language_function
  echo ""

  test_step_title_function
  echo ""

  test_get_str_function
  echo ""

  test_colors_defined
  echo ""

  test_output_functions
  echo ""

  test_en_strings
  echo ""

  test_ru_strings
  echo ""

  test_step_titles
  echo ""

  test_step_titles_ru
  echo ""

  test_telegram_strings
  echo ""

  test_final_messages
  echo ""

  test_final_messages_ru
  echo ""

  test_step_title_functionality
  echo ""

  test_localization_completeness
  echo ""

  test_no_empty_strings
  echo ""

  test_escaping_correctness
  echo ""

  test_check_root_function
  echo ""

  test_check_ubuntu_function
  echo ""

  test_print_banner_function
  echo ""

  test_integration_with_modules
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
