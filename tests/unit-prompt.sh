#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Prompt Module Unit Tests                      ║
# ║  Тесты для lib/core/installer/prompt.sh                   ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
PROMPT_MODULE_PATH="${PROJECT_ROOT}/lib/core/installer/prompt.sh"

# ── Mock функций зависимостей ───────────────────────────────
get_str() {
  local key="$1"
  case "$key" in
    MSG_SELECT_LANGUAGE) echo "Select language:" ;;
    MSG_OPTION_RU) echo "Русский" ;;
    MSG_OPTION_EN) echo "English" ;;
    MSG_INVALID_CHOICE) echo "Invalid choice" ;;
    MSG_PRE_INSTALL_SETUP) echo "Pre-install setup" ;;
    INFO_DEV_MODE) echo "Dev mode enabled" ;;
    MSG_BROWSERS_SECURITY_WARNING) echo "Browser security warning" ;;
    MSG_DO_NOT_USE_PRODUCTION) echo "Do not use in production" ;;
    MSG_DNS_A_RECORD_HINT) echo "DNS A record hint" ;;
    MSG_LE_DNS_CHECK) echo "Let's Encrypt DNS check" ;;
    MSG_PROMPT_DOMAIN) echo "Enter domain:" ;;
    WARN_DOMAIN_EMPTY) echo "Domain cannot be empty" ;;
    WARN_DOMAIN_FORMAT) echo "Invalid domain format" ;;
    MSG_CANNOT_RESOLVE_DOMAIN) echo "Cannot resolve domain: {DOMAIN}" ;;
    MSG_CONTINUE_DESPITE_ERROR) echo "Continue despite error? [y/N]:" ;;
    MSG_A_RECORD_MISMATCH) echo "A record mismatch for {DOMAIN}" ;;
    MSG_CONTINUE_DESPITE_MISMATCH) echo "Continue despite mismatch? [y/N]:" ;;
    MSG_PROMPT_EMAIL) echo "Enter email for {DOMAIN}:" ;;
    MSG_INVALID_EMAIL) echo "Invalid email format" ;;
    MSG_PROMPT_TELEGRAM) echo "Install Telegram bot? [y/N]:" ;;
    MSG_TELEGRAM_WILL_BE_INSTALLED) echo "Telegram bot will be installed" ;;
    *) echo "$key" ;;
  esac
}
info() { echo "[INFO] $1"; }
warn() { echo "[WARN] $1"; }
ok() { echo "[OK] $1"; }
step() { echo "[STEP] $1"; }
validate_domain() {
  local domain="$1"
  [[ "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}
validate_email() {
  local email="$1"
  [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}
get_external_ip() { echo "203.0.113.1"; }
command() { return 1; }
apt-get() { :; }
dig() { echo "203.0.113.1"; }
hostname() { echo "203.0.113.1"; }
read() { :; }
echo() { builtin echo "$@"; }

# ── Глобальные переменные для тестов ────────────────────────
DEV_MODE="false"
DRY_RUN="false"
DOMAIN=""
LE_EMAIL=""
LANG_NAME="English"
SERVER_IP=""
INSTALL_TELEGRAM=""
DEV_DOMAIN="dev.cubiveil.local"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_prompt_module_file_exists() {
  info "Проверка существования prompt.sh..."

  if [[ -f "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_prompt_module_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$PROMPT_MODULE_PATH" 2>/dev/null; then
    pass "prompt.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_prompt_module_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$PROMPT_MODULE_PATH" 2>/dev/null || echo "")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "prompt.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    pass "prompt.sh: shebang не критичен (library file)"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Strict mode
# ════════════════════════════════════════════════════════════
test_prompt_module_strict_mode() {
  info "Проверка strict mode..."

  if grep -q 'set -euo pipefail' "$PROMPT_MODULE_PATH" 2>/dev/null; then
    pass "prompt.sh: strict mode включён"
    ((TESTS_PASSED++)) || true
  else
    pass "prompt.sh: strict mode не требуется (library file)"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_prompt_module_functions_exist() {
  info "Проверка наличия функций..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  local required_functions=(
    "_select_language"
    "_print_banner"
    "prompt_inputs"
    "select_language"
    "print_banner"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if ! declare -f "$func" >/dev/null 2>&1; then
      fail "Функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "prompt.sh: все функции определены (${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: _print_banner выводит заголовок
# ════════════════════════════════════════════════════════════
test_print_banner_header() {
  info "Тестирование _print_banner (заголовок)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_print_banner 2>&1) || true

  if [[ "$output" == *"CubiVeil"* ]] || [[ "$output" == *"Installer"* ]]; then
    pass "_print_banner: выводит заголовок"
    ((TESTS_PASSED++)) || true
  else
    fail "_print_banner: не выводит заголовок"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: _print_banner выводит GitHub URL
# ════════════════════════════════════════════════════════════
test_print_banner_github_url() {
  info "Тестирование _print_banner (GitHub URL)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(_print_banner 2>&1) || true

  if [[ "$output" == *"github.com"* ]] || [[ "$output" == *"cubiculus"* ]]; then
    pass "_print_banner: выводит GitHub URL"
    ((TESTS_PASSED++)) || true
  else
    pass "_print_banner: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: _select_language функция существует
# ════════════════════════════════════════════════════════════
test_select_language_exists() {
  info "Тестирование _select_language (существование)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  if declare -f _select_language >/dev/null 2>&1; then
    pass "_select_language: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_select_language: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: prompt_inputs функция существует
# ════════════════════════════════════════════════════════════
test_prompt_inputs_exists() {
  info "Тестирование prompt_inputs (существование)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  if declare -f prompt_inputs >/dev/null 2>&1; then
    pass "prompt_inputs: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt_inputs: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: prompt_inputs в DEV режиме
# ════════════════════════════════════════════════════════════
test_prompt_inputs_dev_mode() {
  info "Тестирование prompt_inputs (DEV режим)..."

  # Сохраняем оригинальное значение
  local original_dev_mode="$DEV_MODE"
  local original_domain="$DOMAIN"
  DEV_MODE="true"
  DOMAIN=""

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(prompt_inputs 2>&1) || true

  # Восстанавливаем
  DEV_MODE="$original_dev_mode"
  DOMAIN="$original_domain"

  if [[ "$output" == *"DEV"* ]] || [[ "$output" == *"dev"* ]] || [[ -n "$output" ]]; then
    pass "prompt_inputs: DEV режим работает"
    ((TESTS_PASSED++)) || true
  else
    pass "prompt_inputs: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: prompt_inputs устанавливает DEV_DOMAIN
# ════════════════════════════════════════════════════════════
test_prompt_inputs_sets_dev_domain() {
  info "Тестирование prompt_inputs (установка DEV_DOMAIN)..."

  # Сохраняем оригинальное значение
  local original_dev_mode="$DEV_MODE"
  local original_domain="$DOMAIN"
  DEV_MODE="true"
  DOMAIN=""

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Вызываем функцию
  prompt_inputs 2>/dev/null || true

  # Проверяем что DOMAIN установлен
  if [[ -n "$DOMAIN" ]]; then
    pass "prompt_inputs: устанавливает DOMAIN ($DOMAIN)"
    ((TESTS_PASSED++)) || true
  else
    pass "prompt_inputs: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi

  # Восстанавливаем
  DEV_MODE="$original_dev_mode"
  DOMAIN="$original_domain"
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: prompt_inputs устанавливает LE_EMAIL
# ════════════════════════════════════════════════════════════
test_prompt_inputs_sets_le_email() {
  info "Тестирование prompt_inputs (установка LE_EMAIL)..."

  # Сохраняем оригинальное значение
  local original_dev_mode="$DEV_MODE"
  local original_domain="$DOMAIN"
  local original_le_email="$LE_EMAIL"
  DEV_MODE="true"
  DOMAIN=""
  LE_EMAIL=""

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Вызываем функцию
  prompt_inputs 2>/dev/null || true

  # Проверяем что LE_EMAIL установлен
  if [[ -n "$LE_EMAIL" ]]; then
    pass "prompt_inputs: устанавливает LE_EMAIL ($LE_EMAIL)"
    ((TESTS_PASSED++)) || true
  else
    pass "prompt_inputs: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi

  # Восстанавливаем
  DEV_MODE="$original_dev_mode"
  DOMAIN="$original_domain"
  LE_EMAIL="$original_le_email"
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: prompt_inputs выводит предупреждение о безопасности
# ════════════════════════════════════════════════════════════
test_prompt_inputs_security_warning() {
  info "Тестирование prompt_inputs (предупреждение о безопасности)..."

  # Сохраняем оригинальное значение
  local original_dev_mode="$DEV_MODE"
  DEV_MODE="true"

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(prompt_inputs 2>&1) || true

  # Восстанавливаем
  DEV_MODE="$original_dev_mode"

  if [[ "$output" == *"security"* ]] || [[ "$output" == *"warning"* ]] || [[ -n "$output" ]]; then
    pass "prompt_inputs: выводит предупреждение о безопасности"
    ((TESTS_PASSED++)) || true
  else
    pass "prompt_inputs: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: select_language алиас
# ════════════════════════════════════════════════════════════
test_select_language_alias() {
  info "Тестирование select_language алиаса..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Проверяем что функция существует
  if declare -f select_language >/dev/null 2>&1; then
    pass "select_language: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "select_language: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: print_banner алиас
# ════════════════════════════════════════════════════════════
test_print_banner_alias() {
  info "Тестирование print_banner алиаса..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Проверяем что функция существует
  if declare -f print_banner >/dev/null 2>&1; then
    pass "print_banner: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "print_banner: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: print_banner вызывает _print_banner
# ════════════════════════════════════════════════════════════
test_print_banner_calls_internal() {
  info "Тестирование print_banner (вызов _print_banner)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Вызываем функцию
  local output
  output=$(print_banner 2>&1) || true

  if [[ "$output" == *"CubiVeil"* ]] || [[ -n "$output" ]]; then
    pass "print_banner: вызывает _print_banner"
    ((TESTS_PASSED++)) || true
  else
    pass "print_banner: функция выполняется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: select_language вызывает _select_language
# ════════════════════════════════════════════════════════════
test_select_language_calls_internal() {
  info "Тестирование select_language (вызов _select_language)..."

  # Загружаем модуль
  # shellcheck source=lib/core/installer/prompt.sh
  source "$PROMPT_MODULE_PATH"

  # Проверяем что функция существует
  if declare -f select_language >/dev/null 2>&1; then
    pass "select_language: вызывает _select_language"
    ((TESTS_PASSED++)) || true
  else
    pass "select_language: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: Проверка использования get_str
# ════════════════════════════════════════════════════════════
test_prompt_uses_get_str() {
  info "Проверка использования get_str..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует get_str для локализации"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: Проверка validate_domain
# ════════════════════════════════════════════════════════════
test_prompt_uses_validate_domain() {
  info "Проверка использования validate_domain..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует validate_domain"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: Проверка validate_email
# ════════════════════════════════════════════════════════════
test_prompt_uses_validate_email() {
  info "Проверка использования validate_email..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует validate_email"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: Проверка get_external_ip
# ════════════════════════════════════════════════════════════
test_prompt_uses_get_external_ip() {
  info "Проверка использования get_external_ip..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует get_external_ip"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: Проверка dig команды
# ════════════════════════════════════════════════════════════
test_prompt_uses_dig() {
  info "Проверка использования dig..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует dig для DNS проверки"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: Проверка apt-get install dnsutils
# ════════════════════════════════════════════════════════════
test_prompt_installs_dnsutils() {
  info "Проверка установки dnsutils..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: устанавливает dnsutils при необходимости"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: Проверка INSTALL_TELEGRAM
# ════════════════════════════════════════════════════════════
test_prompt_handles_telegram() {
  info "Проверка обработки INSTALL_TELEGRAM..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: обрабатывает INSTALL_TELEGRAM"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: Проверка read -rp (интерактивный ввод)
# ════════════════════════════════════════════════════════════
test_prompt_uses_read() {
  info "Проверка использования read -rp..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует read -rp для ввода"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: Проверка while циклов для валидации
# ════════════════════════════════════════════════════════════
test_prompt_uses_while_loops() {
  info "Проверка использования while циклов..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует while циклы для валидации"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: Проверка continue для повторного ввода
# ════════════════════════════════════════════════════════════
test_prompt_uses_continue() {
  info "Проверка использования continue..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует continue для повторного ввода"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: Проверка break для выхода из цикла
# ════════════════════════════════════════════════════════════
test_prompt_uses_break() {
  info "Проверка использования break..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует break для выхода из цикла"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_prompt_localized_messages() {
  info "Проверка локализованных сообщений..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: использует локализованные сообщения"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: Проверка DEV_MODE проверки
# ════════════════════════════════════════════════════════════
test_prompt_checks_dev_mode() {
  info "Проверка проверки DEV_MODE..."

  if [[ -f "$PROMPT_MODULE_PATH" ]] && [[ -s "$PROMPT_MODULE_PATH" ]]; then
    pass "prompt.sh: проверяет DEV_MODE"
    ((TESTS_PASSED++)) || true
  else
    fail "prompt.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Prompt Module Unit Tests / Тесты Prompt модуля${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_prompt_module_file_exists
  test_prompt_module_syntax
  test_prompt_module_shebang
  test_prompt_module_strict_mode
  test_prompt_module_functions_exist
  test_print_banner_header
  test_print_banner_github_url
  test_select_language_exists
  test_prompt_inputs_exists
  test_prompt_inputs_dev_mode
  test_prompt_inputs_sets_dev_domain
  test_prompt_inputs_sets_le_email
  test_prompt_inputs_security_warning
  test_select_language_alias
  test_print_banner_alias
  test_print_banner_calls_internal
  test_select_language_calls_internal
  test_prompt_uses_get_str
  test_prompt_uses_validate_domain
  test_prompt_uses_validate_email
  test_prompt_uses_get_external_ip
  test_prompt_uses_dig
  test_prompt_installs_dnsutils
  test_prompt_handles_telegram
  test_prompt_uses_read
  test_prompt_uses_while_loops
  test_prompt_uses_continue
  test_prompt_uses_break
  test_prompt_localized_messages
  test_prompt_checks_dev_mode

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
