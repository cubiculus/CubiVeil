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
sed() { echo "<html><body>Test Content</body></html>"; }
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

# ── Тест: _generate_inner_pages функция существует ──────────────────────
test_generate_inner_pages_exists() {
  info "Тестирование существования _generate_inner_pages..."

  if declare -f _generate_inner_pages &>/dev/null; then
    pass "_generate_inner_pages: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_inner_pages: функция не найдена"
  fi
}

# ── Тест: _generate_inner_pages генерирует страницы ─────────────────────
test_generate_inner_pages_creates_files() {
  info "Тестирование генерации внутренних страниц..."

  local test_id="inner-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot/files"
  DECOY_WEBROOT="$test_webroot"

  # Создаём тестовые файлы
  touch "${test_webroot}/files/file1.jpg"
  touch "${test_webroot}/files/file2.pdf"

  # Вызываем функцию
  _generate_inner_pages "portal" "Test Site" "#4a90d9" "2025" || true

  # Проверяем создание страниц
  if [[ -f "${test_webroot}/files/index.html" ]]; then
    pass "_generate_inner_pages: создан /files/index.html"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_inner_pages: не создан /files/index.html"
  fi

  if [[ -f "${test_webroot}/files/upload/index.html" ]]; then
    pass "_generate_inner_pages: создан /files/upload/index.html"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_inner_pages: не создан /files/upload/index.html"
  fi

  if [[ -f "${test_webroot}/audit/logs/index.html" ]]; then
    pass "_generate_inner_pages: создан /audit/logs/index.html"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_inner_pages: не создан /audit/logs/index.html"
  fi

  if [[ -f "${test_webroot}/404.html" ]]; then
    pass "_generate_inner_pages: создан /404.html"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_inner_pages: не создан /404.html"
  fi

  rm -rf "$test_webroot"
}

# ── Тест: _generate_inner_pages содержит правильный HTML ────────────────
test_generate_inner_pages_html_content() {
  info "Тестирование содержимого внутренних страниц..."

  local test_id="inner-html-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot/files"
  DECOY_WEBROOT="$test_webroot"

  # Создаём тестовые файлы
  touch "${test_webroot}/files/test.jpg"

  # Вызываем функцию
  _generate_inner_pages "portal" "Test Site" "#4a90d9" "2025" || true

  # Проверяем содержимое /files/index.html
  if [[ -f "${test_webroot}/files/index.html" ]]; then
    local content
    content=$(cat "${test_webroot}/files/index.html")

    if echo "$content" | grep -q "File Storage"; then
      pass "_generate_inner_pages: /files/index.html содержит заголовок"
      ((TESTS_PASSED++)) || true
    else
      fail "_generate_inner_pages: /files/index.html не содержит заголовок"
    fi

    if echo "$content" | grep -q "Test Site"; then
      pass "_generate_inner_pages: /files/index.html содержит site_name"
      ((TESTS_PASSED++)) || true
    else
      fail "_generate_inner_pages: /files/index.html не содержит site_name"
    fi
  fi

  # Проверяем содержимое /audit/logs/index.html
  if [[ -f "${test_webroot}/audit/logs/index.html" ]]; then
    local audit_content
    audit_content=$(cat "${test_webroot}/audit/logs/index.html")

    if echo "$audit_content" | grep -q "Audit Log"; then
      pass "_generate_inner_pages: /audit/logs/index.html содержит заголовок"
      ((TESTS_PASSED++)) || true
    else
      fail "_generate_inner_pages: /audit/logs/index.html не содержит заголовок"
    fi
  fi

  # Проверяем содержимое /404.html
  if [[ -f "${test_webroot}/404.html" ]]; then
    local err404_content
    err404_content=$(cat "${test_webroot}/404.html")

    if echo "$err404_content" | grep -q "404"; then
      pass "_generate_inner_pages: /404.html содержит код ошибки"
      ((TESTS_PASSED++)) || true
    else
      fail "_generate_inner_pages: /404.html не содержит код ошибки"
    fi
  fi

  rm -rf "$test_webroot"
}

# ── Тест: decoy_build_webroot вызывает _generate_inner_pages ────────────
test_decoy_build_webroot_calls_inner_pages() {
  info "Тестирование вызова _generate_inner_pages из decoy_build_webroot..."

  local test_id="build-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-${test_id}"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1,
    "last_rotated_at": null
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # Создаём шаблон (минимум файлов для теста)
  local templates_dir="${PROJECT_ROOT}/lib/modules/decoy-site/templates"
  mkdir -p "$templates_dir"
  if [[ ! -f "${templates_dir}/_shared/index.html" ]]; then
    echo '<html><body><h1>{{SITE_NAME}}</h1></body></html>' >"${templates_dir}/_shared/index.html"
  fi

  # Вызываем decoy_build_webroot
  decoy_build_webroot || true

  # Проверяем что inner страницы созданы
  if [[ -f "${test_webroot}/files/index.html" ]] || [[ -f "${test_webroot}/404.html" ]]; then
    pass "decoy_build_webroot: вызывает _generate_inner_pages"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_build_webroot: не вызывает _generate_inner_pages"
  fi

  rm -rf "$test_webroot" "$test_config_dir"
}

# ── Основная функция ─────────────────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - Decoy Inner Pages             ║${PLAIN}"
  echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────────────────
  test_generate_inner_pages_exists
  echo ""

  test_generate_inner_pages_creates_files
  echo ""

  test_generate_inner_pages_html_content
  echo ""

  test_decoy_build_webroot_calls_inner_pages
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
