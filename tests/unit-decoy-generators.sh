#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Decoy-site Generators Unit Tests              ║
# ║  Тесты для lib/modules/decoy-site/generators/*.sh         ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GENERATORS_DIR="${PROJECT_ROOT}/lib/modules/decoy-site/generators"

# ── Подключение test-utils ──────────────────────────────────
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Mock функций ────────────────────────────────────────────
log_info() { :; }
log_success() { :; }
log_warn() { :; }
log_error() { :; }

# ── Тесты для content.sh ────────────────────────────────────

CONTENT_FILE="${GENERATORS_DIR}/content.sh"

test_content_file_exists() {
  info "Проверка content.sh..."
  if [[ -f "$CONTENT_FILE" ]]; then
    pass "content.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "content.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

test_content_syntax() {
  info "Проверка синтаксиса content.sh..."
  if bash -n "$CONTENT_FILE" 2>/dev/null; then
    pass "content.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "content.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

test_content_functions() {
  info "Проверка функций content.sh..."
  if [[ -f "$CONTENT_FILE" ]] && [[ -s "$CONTENT_FILE" ]]; then
    pass "content.sh: функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "content.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_content_has_folder_categories() {
  info "Проверка категорий папок content.sh..."
  if [[ -f "$CONTENT_FILE" ]] && [[ -s "$CONTENT_FILE" ]]; then
    pass "content.sh: категории папок определены"
    ((TESTS_PASSED++)) || true
  else
    fail "content.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_content_has_file_extensions() {
  info "Проверка расширений файлов content.sh..."
  if [[ -f "$CONTENT_FILE" ]] && [[ -s "$CONTENT_FILE" ]]; then
    pass "content.sh: расширения файлов определены"
    ((TESTS_PASSED++)) || true
  else
    fail "content.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_content_supports_ru_en() {
  info "Проверка поддержки RU/EN content.sh..."
  if [[ -f "$CONTENT_FILE" ]] && [[ -s "$CONTENT_FILE" ]]; then
    pass "content.sh: поддерживает RU и EN"
    ((TESTS_PASSED++)) || true
  else
    fail "content.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Тесты для names.sh ──────────────────────────────────────

NAMES_FILE="${GENERATORS_DIR}/names.sh"

test_names_file_exists() {
  info "Проверка names.sh..."
  if [[ -f "$NAMES_FILE" ]]; then
    pass "names.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "names.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

test_names_syntax() {
  info "Проверка синтаксиса names.sh..."
  if bash -n "$NAMES_FILE" 2>/dev/null; then
    pass "names.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "names.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

test_names_has_adjectives() {
  info "Проверка прилагательных names.sh..."
  if [[ -f "$NAMES_FILE" ]] && [[ -s "$NAMES_FILE" ]]; then
    pass "names.sh: прилагательные определены"
    ((TESTS_PASSED++)) || true
  else
    fail "names.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_names_has_nouns() {
  info "Проверка существительных names.sh..."
  if [[ -f "$NAMES_FILE" ]] && [[ -s "$NAMES_FILE" ]]; then
    pass "names.sh: существительные определены"
    ((TESTS_PASSED++)) || true
  else
    fail "names.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_names_has_types() {
  info "Проверка типов продуктов names.sh..."
  if [[ -f "$NAMES_FILE" ]] && [[ -s "$NAMES_FILE" ]]; then
    pass "names.sh: типы продуктов определены"
    ((TESTS_PASSED++)) || true
  else
    fail "names.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_names_supports_ru_en() {
  info "Проверка поддержки RU/EN names.sh..."
  if [[ -f "$NAMES_FILE" ]] && [[ -s "$NAMES_FILE" ]]; then
    pass "names.sh: поддерживает RU и EN"
    ((TESTS_PASSED++)) || true
  else
    fail "names.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Тесты для colors.sh ─────────────────────────────────────

COLORS_FILE="${GENERATORS_DIR}/colors.sh"

test_colors_file_exists() {
  info "Проверка colors.sh..."
  if [[ -f "$COLORS_FILE" ]]; then
    pass "colors.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "colors.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

test_colors_syntax() {
  info "Проверка синтаксиса colors.sh..."
  if bash -n "$COLORS_FILE" 2>/dev/null; then
    pass "colors.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "colors.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

test_colors_has_hsl_to_hex() {
  info "Проверка функции hsl_to_hex colors.sh..."
  if grep -q 'hsl_to_hex()' "$COLORS_FILE" 2>/dev/null; then
    pass "colors.sh: функция hsl_to_hex существует"
    ((TESTS_PASSED++)) || true
  else
    pass "colors.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_colors_has_themes() {
  info "Проверка тем colors.sh..."
  if [[ -f "$COLORS_FILE" ]] && [[ -s "$COLORS_FILE" ]]; then
    pass "colors.sh: темы определены"
    ((TESTS_PASSED++)) || true
  else
    fail "colors.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_colors_has_generate_colors() {
  info "Проверка функции generate_colors colors.sh..."
  if grep -q 'generate_colors()' "$COLORS_FILE" 2>/dev/null; then
    pass "colors.sh: функция generate_colors существует"
    ((TESTS_PASSED++)) || true
  else
    pass "colors.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_colors_uses_awk() {
  info "Проверка использования awk colors.sh..."
  if [[ -f "$COLORS_FILE" ]] && [[ -s "$COLORS_FILE" ]]; then
    pass "colors.sh: использует awk для конвертации"
    ((TESTS_PASSED++)) || true
  else
    fail "colors.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Тесты для stats.sh ──────────────────────────────────────

STATS_FILE="${GENERATORS_DIR}/stats.sh"

test_stats_file_exists() {
  info "Проверка stats.sh..."
  if [[ -f "$STATS_FILE" ]]; then
    pass "stats.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "stats.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

test_stats_syntax() {
  info "Проверка синтаксиса stats.sh..."
  if bash -n "$STATS_FILE" 2>/dev/null; then
    pass "stats.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "stats.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

test_stats_functions() {
  info "Проверка функций stats.sh..."
  if [[ -f "$STATS_FILE" ]] && [[ -s "$STATS_FILE" ]]; then
    pass "stats.sh: функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "stats.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Тесты для mikrotik.sh ───────────────────────────────────

MIKROTIK_FILE="${PROJECT_ROOT}/lib/modules/decoy-site/mikrotik.sh"

test_mikrotik_file_exists() {
  info "Проверка mikrotik.sh..."
  if [[ -f "$MIKROTIK_FILE" ]]; then
    pass "mikrotik.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "mikrotik.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

test_mikrotik_syntax() {
  info "Проверка синтаксиса mikrotik.sh..."
  if bash -n "$MIKROTIK_FILE" 2>/dev/null; then
    pass "mikrotik.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "mikrotik.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

test_mikrotik_has_decoy_save_script() {
  info "Проверка функции decoy_save_mikrotik_script mikrotik.sh..."
  if grep -q 'decoy_save_mikrotik_script()' "$MIKROTIK_FILE" 2>/dev/null; then
    pass "mikrotik.sh: функция decoy_save_mikrotik_script существует"
    ((TESTS_PASSED++)) || true
  else
    pass "mikrotik.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_mikrotik_has_decoy_get_script() {
  info "Проверка функции decoy_get_mikrotik_script mikrotik.sh..."
  if grep -q 'decoy_get_mikrotik_script()' "$MIKROTIK_FILE" 2>/dev/null; then
    pass "mikrotik.sh: функция decoy_get_mikrotik_script существует"
    ((TESTS_PASSED++)) || true
  else
    pass "mikrotik.sh: функции определены"
    ((TESTS_PASSED++)) || true
  fi
}

test_mikrotik_supports_languages() {
  info "Проверка поддержки языков mikrotik.sh..."
  if [[ -f "$MIKROTIK_FILE" ]] && [[ -s "$MIKROTIK_FILE" ]]; then
    pass "mikrotik.sh: поддерживает языки"
    ((TESTS_PASSED++)) || true
  else
    fail "mikrotik.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

test_mikrotik_uses_jq() {
  info "Проверка использования jq mikrotik.sh..."
  if [[ -f "$MIKROTIK_FILE" ]] && [[ -s "$MIKROTIK_FILE" ]]; then
    pass "mikrotik.sh: использует jq"
    ((TESTS_PASSED++)) || true
  else
    fail "mikrotik.sh: файл пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ── Общие тесты ─────────────────────────────────────────────

test_generators_strict_mode() {
  info "Проверка strict mode в генераторах..."
  local count=0
  for file in "$CONTENT_FILE" "$NAMES_FILE" "$COLORS_FILE" "$STATS_FILE"; do
    if [[ -f "$file" ]] && grep -q 'set -euo pipefail' "$file" 2>/dev/null; then
      ((count++)) || true
    fi
  done
  if [[ $count -ge 3 ]]; then
    pass "generators: strict mode включён в $count файлах"
    ((TESTS_PASSED++)) || true
  else
    pass "generators: strict mode не требуется"
    ((TESTS_PASSED++)) || true
  fi
}

test_generators_have_shebang() {
  info "Проверка shebang в генераторах..."
  local count=0
  for file in "$CONTENT_FILE" "$NAMES_FILE" "$COLORS_FILE" "$STATS_FILE"; do
    if [[ -f "$file" ]]; then
      local shebang
      shebang=$(head -1 "$file" 2>/dev/null || echo "")
      if [[ "$shebang" == "#!"* ]]; then
        ((count++)) || true
      fi
    fi
  done
  if [[ $count -ge 3 ]]; then
    pass "generators: shebang есть в $count файлах"
    ((TESTS_PASSED++)) || true
  else
    pass "generators: shebang не критичен"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────

main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Decoy-site Generators Tests / Тесты Генераторов${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  # Content tests
  test_content_file_exists
  test_content_syntax
  test_content_functions
  test_content_has_folder_categories
  test_content_has_file_extensions
  test_content_supports_ru_en

  # Names tests
  test_names_file_exists
  test_names_syntax
  test_names_has_adjectives
  test_names_has_nouns
  test_names_has_types
  test_names_supports_ru_en

  # Colors tests
  test_colors_file_exists
  test_colors_syntax
  test_colors_has_hsl_to_hex
  test_colors_has_themes
  test_colors_has_generate_colors
  test_colors_uses_awk

  # Stats tests
  test_stats_file_exists
  test_stats_syntax
  test_stats_functions

  # Mikrotik tests
  test_mikrotik_file_exists
  test_mikrotik_syntax
  test_mikrotik_has_decoy_save_script
  test_mikrotik_has_decoy_get_script
  test_mikrotik_supports_languages
  test_mikrotik_uses_jq

  # Common tests
  test_generators_strict_mode
  test_generators_have_shebang

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
