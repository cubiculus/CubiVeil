#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140
# ════════════════════════════════════════════════════════════════════════
#        CubiVeil Unit Tests - Decoy Inner Pages
#        Тестирование _generate_inner_pages()
# ════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Подключение тестовых утилит ─────────────────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Загрузка тестируемых модулей ────────────────────────────────────────
GENERATE_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/generate.sh"

if [[ ! -f "$GENERATE_PATH" ]]; then
  echo "Ошибка: generate.sh не найден: $GENERATE_PATH"
  exit 1
fi

# ── Mock зависимостей ───────────────────────────────────────────────────
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

# Mock для jq
jq() {
  local filter="$1"
  if [[ "$filter" == *".template"* ]]; then
    echo "portal"
  elif [[ "$filter" == *".site_name"* ]]; then
    echo "Test Site"
  elif [[ "$filter" == *".accent_color"* ]]; then
    echo "#4a90d9"
  elif [[ "$filter" == *".copyright_year"* ]]; then
    echo "2025"
  elif [[ "$filter" == *".server_token"* ]]; then
    echo "nginx"
  else
    echo ""
  fi
  return 0
}

# Mock системных команд
chmod() { return 0; }
chown() { return 0; }
# Use real sed for template rendering instead of mocking static content.
sed() { command sed "$@"; }
find() {
  if [[ "$*" == *"-printf"* ]]; then
    echo "file1.jpg"
    echo "file2.pdf"
    echo "file3.mp4"
  else
    echo "/tmp/test/files/file1.jpg"
  fi
}
dd() { return 0; }
convert() { return 0; }
stat() { echo "1048576"; }
date() {
  if [[ "$*" == *"-d"* ]]; then
    echo "2025-01-01"
  elif [[ "$*" == *"+%Y"* ]]; then
    echo "2025"
  elif [[ "$*" == *"+%s"* ]]; then
    echo "1735689600"
  elif [[ "$*" == *"-Iseconds"* ]]; then
    echo "2025-01-01T12:00:00+00:00"
  else
    echo "2025-01-01"
  fi
}

# Mock для gen_hex
gen_hex() {
  local length="${1:-6}"
  local result=""
  for ((i = 0; i < length; i++)); do
    result+="a"
  done
  echo "$result"
}

gen_range() {
  local min="$1"
  local max="$2"
  echo "$((min + RANDOM % (max - min + 1)))"
}

# Переопределяем пути для тестов
export DECOY_CONFIG=""
export DECOY_WEBROOT=""

# ── Загрузка модуля ─────────────────────────────────────────────────────
# shellcheck source=lib/modules/decoy-site/generate.sh
source "$GENERATE_PATH"

# ── Тест: decoy_build_webroot функция существует ──────────────
test_decoy_build_webroot_function_exists() {
  info "Тестирование существования decoy_build_webroot..."

  if declare -f decoy_build_webroot &>/dev/null; then
    pass "decoy_build_webroot: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_build_webroot: функция не найдена"
  fi
}

# ── Тест: decoy_build_webroot генерирует файлы ───────────────────
test_decoy_build_webroot_generates_files() {
  info "Тестирование генерации сайта через decoy_build_webroot..."

  local test_id="inner-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot"

  export DECOY_WEBROOT="$test_webroot"
  export OUTPUT_DIR="$test_webroot"
  export DECOY_CONFIG="${test_webroot}/decoy.json"

  # Запускаем генерацию сайта через новый API
  if decoy_build_webroot --variant cloud_storage --lang ru; then
    pass "decoy_build_webroot: выполнен"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_build_webroot: вызов завершился ошибкой"
    ((TESTS_FAILED++)) || true
  fi

  # Проверка обязательных файлов
  for file in "index.html" "style.css" "config.js" "nginx.conf" ".generation_meta.json"; do
    if [[ -f "${test_webroot}/${file}" ]]; then
      pass "decoy_build_webroot: создан ${file}"
      ((TESTS_PASSED++)) || true
    else
      fail "decoy_build_webroot: не создан ${file}"
      ((TESTS_FAILED++)) || true
    fi
  done

  rm -rf "$test_webroot"
}

# ── Тест: decoy_build_webroot содержит правильный HTML ──────────────
test_decoy_build_webroot_html_content() {
  info "Тестирование содержимого сгенерированного index.html..."

  local test_id="inner-html-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot"

  export DECOY_WEBROOT="$test_webroot"
  export OUTPUT_DIR="$test_webroot"
  export DECOY_CONFIG="${test_webroot}/decoy.json"

  # Вызываем генерацию
  decoy_build_webroot --variant cloud_storage --lang ru || true

  # Проверяем содержимое /index.html
  if [[ -f "${test_webroot}/index.html" ]]; then
    if grep -qF "<title>" "${test_webroot}/index.html"; then
      pass "decoy_build_webroot: index.html содержит тег <title>"
      ((TESTS_PASSED++)) || true
    else
      fail "decoy_build_webroot: index.html не содержит тег <title>"
      ((TESTS_FAILED++)) || true
    fi

    if grep -qF "<a href=\"login.html\"" "${test_webroot}/index.html"; then
      pass "decoy_build_webroot: index.html содержит ссылку на login.html"
      ((TESTS_PASSED++)) || true
    else
      fail "decoy_build_webroot: index.html не содержит ссылку на login.html"
      ((TESTS_FAILED++)) || true
    fi
  else
    fail "decoy_build_webroot: index.html не создан"
    ((TESTS_FAILED++)) || true
  fi

  rm -rf "$test_webroot"
}

# ── Тест: decoy_build_webroot создаёт сайт ─────────────────────
test_decoy_build_webroot_has_output() {
  info "Тестирование результата decoy_build_webroot..."

  local test_id="build-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot"
  export DECOY_WEBROOT="$test_webroot"
  export OUTPUT_DIR="$test_webroot"

  decoy_build_webroot --variant cloud_storage --lang ru || true

  if [[ -f "${test_webroot}/index.html" && -f "${test_webroot}/nginx.conf" ]]; then
    pass "decoy_build_webroot: создал index.html и nginx.conf"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_build_webroot: не созданы базовые файлы веб-режима"
    ((TESTS_FAILED++)) || true
  fi

  rm -rf "$test_webroot"
}

# ── Основная функция ─────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - Decoy Inner Pages             ║${PLAIN}"
  echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────────────────
  test_decoy_build_webroot_function_exists
  echo ""

  test_decoy_build_webroot_generates_files
  echo ""

  test_decoy_build_webroot_html_content
  echo ""

  test_decoy_build_webroot_has_output
  echo ""

  # ── Итоги ─────────────────────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo -e "${GREEN}Пройдено: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Провалено:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
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
