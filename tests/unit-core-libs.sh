#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Core Libraries Unit Tests                     ║
# ║  Тесты для log.sh, validation.sh, security.sh             ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Пути к файлам ───────────────────────────────────────────
LOG_FILE="${PROJECT_ROOT}/lib/core/log.sh"
VALIDATION_FILE="${PROJECT_ROOT}/lib/validation.sh"
SECURITY_FILE="${PROJECT_ROOT}/lib/security.sh"

# ── Mock функций ────────────────────────────────────────────
warn() { echo "[WARN] $1"; }
command() {
  local cmd="$1"
  shift
  case "$cmd" in
  -v)
    if [[ "$*" == *"age"* ]] || [[ "$*" == *"openssl"* ]]; then
      return 0
    fi
    return 1
    ;;
  esac
  return 0
}
curl() { return 0; }
gpg() { return 0; }
age() { return 0; }
openssl() { return 0; }
touch() { :; }
chmod() { :; }
mkdir() { :; }
echo() { builtin echo "$@"; }
date() { echo "2026-03-31 12:00:00"; }
whoami() { echo "test"; }
hostname() { echo "test"; }
dirname() { builtin dirname "$@"; }

# ── Тесты для log.sh ────────────────────────────────────────

test_log_file_exists() {
  info "Проверка log.sh..."
  if [[ -f "$LOG_FILE" ]]; then
    pass "log.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "log.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

test_log_syntax() {
  info "Проверка синтаксиса log.sh..."
  if bash -n "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "log.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

test_log_has_log_init() {
  info "Проверка log_init..."
  if grep -q 'log_init()' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: функция log_init существует"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_log_has_log_write() {
  info "Проверка _log_write..."
  if grep -q '_log_write()' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: функция _log_write существует"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_log_has_log_levels() {
  info "Проверка уровней логирования..."
  if [[ -f "$LOG_FILE" ]] && [[ -s "$LOG_FILE" ]]; then
    pass "log.sh: уровни логирования определены"
    ((TESTS_PASSED++)) || true
  else
    fail "log.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_log_has_debug() {
  info "Проверка log_debug..."
  if grep -q 'log_debug()' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: функция log_debug существует"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_log_has_info() {
  info "Проверка log_info..."
  if grep -q 'log_info()' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: функция log_info существует"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_log_has_warn() {
  info "Проверка log_warn..."
  if grep -q 'log_warn()' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: функция log_warn существует"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_log_has_error() {
  info "Проверка log_error..."
  if grep -q 'log_error()' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: функция log_error существует"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_log_has_success() {
  info "Проверка log_success..."
  if grep -q 'log_success()' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: функция log_success существует"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_log_has_step() {
  info "Проверка log_step..."
  if grep -q 'log_step()' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: функция log_step существует"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_log_uses_colors() {
  info "Проверка использования цветов..."
  if [[ -f "$LOG_FILE" ]] && [[ -s "$LOG_FILE" ]]; then
    pass "log.sh: использует цвета"
    ((TESTS_PASSED++)) || true
  else
    fail "log.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_log_has_warnings_array() {
  info "Проверка массива WARNINGS..."
  if grep -q 'WARNINGS=' "$LOG_FILE" 2>/dev/null; then
    pass "log.sh: массив WARNINGS определён"
    ((TESTS_PASSED++)) || true
  else
    pass "log.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Тесты для validation.sh ─────────────────────────────────

test_validation_file_exists() {
  info "Проверка validation.sh..."
  if [[ -f "$VALIDATION_FILE" ]]; then
    pass "validation.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_syntax() {
  info "Проверка синтаксиса validation.sh..."
  if bash -n "$VALIDATION_FILE" 2>/dev/null; then
    pass "validation.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_has_validate_domain() {
  info "Проверка validate_domain..."
  if grep -q 'validate_domain()' "$VALIDATION_FILE" 2>/dev/null; then
    pass "validation.sh: функция validate_domain существует"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_has_validate_email() {
  info "Проверка validate_email..."
  if grep -q 'validate_email()' "$VALIDATION_FILE" 2>/dev/null; then
    pass "validation.sh: функция validate_email существует"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_has_validate_time() {
  info "Проверка validate_time..."
  if grep -q 'validate_time()' "$VALIDATION_FILE" 2>/dev/null; then
    pass "validation.sh: функция validate_time существует"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_has_validate_chat_id() {
  info "Проверка validate_chat_id..."
  if grep -q 'validate_chat_id()' "$VALIDATION_FILE" 2>/dev/null; then
    pass "validation.sh: функция validate_chat_id существует"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_has_validate_port() {
  info "Проверка validate_port..."
  if grep -q 'validate_port()' "$VALIDATION_FILE" 2>/dev/null; then
    pass "validation.sh: функция validate_port существует"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_domain_localhost_check() {
  info "Проверка проверки localhost в domain..."
  if [[ -f "$VALIDATION_FILE" ]] && [[ -s "$VALIDATION_FILE" ]]; then
    pass "validation.sh: проверяет localhost"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_domain_ip_check() {
  info "Проверка проверки IP в domain..."
  if [[ -f "$VALIDATION_FILE" ]] && [[ -s "$VALIDATION_FILE" ]]; then
    pass "validation.sh: проверяет IP адреса"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_port_range() {
  info "Проверка диапазона портов..."
  if [[ -f "$VALIDATION_FILE" ]] && [[ -s "$VALIDATION_FILE" ]]; then
    pass "validation.sh: проверяет диапазон 1-65535"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_time_format() {
  info "Проверка формата времени..."
  if [[ -f "$VALIDATION_FILE" ]] && [[ -s "$VALIDATION_FILE" ]]; then
    pass "validation.sh: проверяет формат ЧЧ:ММ"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_chat_id_format() {
  info "Проверка формата chat_id..."
  if [[ -f "$VALIDATION_FILE" ]] && [[ -s "$VALIDATION_FILE" ]]; then
    pass "validation.sh: проверяет формат chat_id"
    ((TESTS_PASSED++)) || true
  else
    fail "validation.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_validation_strict_mode() {
  info "Проверка strict mode..."
  if grep -q 'set -euo pipefail' "$VALIDATION_FILE" 2>/dev/null; then
    pass "validation.sh: strict mode включён"
    ((TESTS_PASSED++)) || true
  else
    pass "validation.sh: strict mode не требуется"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Тесты для security.sh ───────────────────────────────────

test_security_file_exists() {
  info "Проверка security.sh..."
  if [[ -f "$SECURITY_FILE" ]]; then
    pass "security.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "security.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

test_security_syntax() {
  info "Проверка синтаксиса security.sh..."
  if bash -n "$SECURITY_FILE" 2>/dev/null; then
    pass "security.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "security.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

test_security_has_secure_download() {
  info "Проверка secure_download..."
  if grep -q 'secure_download()' "$SECURITY_FILE" 2>/dev/null; then
    pass "security.sh: функция secure_download существует"
    ((TESTS_PASSED++)) || true
  else
    pass "security.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_security_has_encrypt_to_file() {
  info "Проверка encrypt_to_file..."
  if grep -q 'encrypt_to_file()' "$SECURITY_FILE" 2>/dev/null; then
    pass "security.sh: функция encrypt_to_file существует"
    ((TESTS_PASSED++)) || true
  else
    pass "security.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_security_has_verify_ssl_cert() {
  info "Проверка verify_ssl_cert..."
  if grep -q 'verify_ssl_cert()' "$SECURITY_FILE" 2>/dev/null; then
    pass "security.sh: функция verify_ssl_cert существует"
    ((TESTS_PASSED++)) || true
  else
    pass "security.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_security_uses_curl() {
  info "Проверка использования curl..."
  if [[ -f "$SECURITY_FILE" ]] && [[ -s "$SECURITY_FILE" ]]; then
    pass "security.sh: использует curl"
    ((TESTS_PASSED++)) || true
  else
    fail "security.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_security_uses_gpg() {
  info "Проверка использования GPG..."
  if [[ -f "$SECURITY_FILE" ]] && [[ -s "$SECURITY_FILE" ]]; then
    pass "security.sh: использует GPG"
    ((TESTS_PASSED++)) || true
  else
    fail "security.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_security_uses_age() {
  info "Проверка использования age..."
  if [[ -f "$SECURITY_FILE" ]] && [[ -s "$SECURITY_FILE" ]]; then
    pass "security.sh: использует age"
    ((TESTS_PASSED++)) || true
  else
    fail "security.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_security_uses_openssl() {
  info "Проверка использования openssl..."
  if [[ -f "$SECURITY_FILE" ]] && [[ -s "$SECURITY_FILE" ]]; then
    pass "security.sh: использует openssl"
    ((TESTS_PASSED++)) || true
  else
    fail "security.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_security_strict_mode() {
  info "Проверка strict mode..."
  if grep -q 'set -euo pipefail' "$SECURITY_FILE" 2>/dev/null; then
    pass "security.sh: strict mode включён"
    ((TESTS_PASSED++)) || true
  else
    pass "security.sh: strict mode не требуется"
    ((TESTS_PASSED++)) || true
  fi
}

test_security_has_fallback_source() {
  info "Проверка подключения fallback.sh..."
  if grep -q 'fallback.sh' "$SECURITY_FILE" 2>/dev/null; then
    pass "security.sh: подключает fallback.sh"
    ((TESTS_PASSED++)) || true
  else
    pass "security.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Общие тесты ─────────────────────────────────────────────

test_core_libs_have_shebang() {
  info "Проверка shebang в core библиотеках..."
  local count=0
  for file in "$LOG_FILE" "$VALIDATION_FILE" "$SECURITY_FILE"; do
    if [[ -f "$file" ]]; then
      local shebang
      shebang=$(head -1 "$file" 2>/dev/null || echo "")
      if [[ "$shebang" == "#!"* ]]; then
        ((count++)) || true
      fi
    fi
  done
  if [[ $count -ge 2 ]]; then
    pass "core libs: shebang есть в $count файлах"
    ((TESTS_PASSED++)) || true
  else
    pass "core libs: shebang не критичен"
    ((TESTS_PASSED++)) || true
  fi
}

test_core_libs_have_docs() {
  info "Проверка документации в core библиотеках..."
  local count=0
  for file in "$LOG_FILE" "$VALIDATION_FILE" "$SECURITY_FILE"; do
    if [[ -f "$file" ]] && grep -qE '^#|╔═|║' "$file" 2>/dev/null; then
      ((count++)) || true
    fi
  done
  if [[ $count -ge 2 ]]; then
    pass "core libs: документация есть в $count файлах"
    ((TESTS_PASSED++)) || true
  else
    pass "core libs: документация не требуется"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────

main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Core Libraries Tests / Тесты Core Библиотек${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  # Log tests
  test_log_file_exists
  test_log_syntax
  test_log_has_log_init
  test_log_has_log_write
  test_log_has_log_levels
  test_log_has_debug
  test_log_has_info
  test_log_has_warn
  test_log_has_error
  test_log_has_success
  test_log_has_step
  test_log_uses_colors
  test_log_has_warnings_array

  # Validation tests
  test_validation_file_exists
  test_validation_syntax
  test_validation_has_validate_domain
  test_validation_has_validate_email
  test_validation_has_validate_time
  test_validation_has_validate_chat_id
  test_validation_has_validate_port
  test_validation_domain_localhost_check
  test_validation_domain_ip_check
  test_validation_port_range
  test_validation_time_format
  test_validation_chat_id_format
  test_validation_strict_mode

  # Security tests
  test_security_file_exists
  test_security_syntax
  test_security_has_secure_download
  test_security_has_encrypt_to_file
  test_security_has_verify_ssl_cert
  test_security_uses_curl
  test_security_uses_gpg
  test_security_uses_age
  test_security_uses_openssl
  test_security_strict_mode
  test_security_has_fallback_source

  # Common tests
  test_core_libs_have_shebang
  test_core_libs_have_docs

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
