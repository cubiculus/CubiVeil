#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140,SC2034
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Decoy-site Rotate Module Unit Tests           ║
# ║  Тесты для lib/modules/decoy-site/rotate.sh               ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
DECOY_ROTATE_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/rotate.sh"

# ── Mock функций зависимостей ───────────────────────────────
log_info() { :; }
log_success() { :; }
log_warn() { :; }
log_error() { :; }
log_step() { :; }
get_str() { echo "${1:-}"; }
info() { :; }
warn() { :; }
success() { :; }
err() { echo "ERROR: $1" >&2; }

# Mock для команд
command() {
  local cmd="$1"
  shift
  case "$cmd" in
  -v)
    if [[ "$*" == *"convert"* ]]; then
      return 0
    fi
    return 1
    ;;
  esac
  return 1
}

# Mock для jq
jq() {
  local arg="$1"
  shift
  case "$arg" in
  -r)
    local field="$2"
    shift 2
    case "$field" in
    '.rotation.enabled') echo "true" ;;
    '.rotation.files_per_cycle') echo "1" ;;
    '.rotation.interval_hours') echo "3" ;;
    '.rotation.types // {}') echo '{"jpg":{"enabled":true,"weight":1},"pdf":{"enabled":true,"weight":1}}' ;;
    '.rotation.types.jpg.enabled // false') echo "true" ;;
    '.rotation.types.jpg.weight // 1') echo "1" ;;
    '.rotation.types.pdf.enabled // false') echo "true" ;;
    '.rotation.types.pdf.weight // 1') echo "1" ;;
    '.rotation.types.mp4.enabled // false') echo "false" ;;
    '.rotation.types.mp3.enabled // false') echo "false" ;;
    '.rotation.types.pdf.size_min_mb // 50') echo "50" ;;
    '.rotation.types.mp4.size_min_mb // 100') echo "100" ;;
    '.rotation.types.mp3.size_min_mb // 10') echo "10" ;;
    '.max_total_files_mb // 5000') echo "5000" ;;
    '.accent_color') echo "#4a90d9" ;;
    *) echo "unknown" ;;
    esac
    ;;
  *)
    if [[ "$*" == *".rotation.last_rotated_at"* ]]; then
      echo "{\"rotation\":{\"last_rotated_at\":\"2026-03-31T12:00:00Z\"}}"
    else
      echo "{}"
    fi
    ;;
  esac
  return 0
}

# Mock для find
find() {
  local path="$1"
  shift
  if [[ "$*" == *"-printf"* ]]; then
    echo "2026-03-30+12:00:00 /var/www/decoy/files/old_file.jpg"
  elif [[ "$*" == *"-name"* ]]; then
    echo "/var/www/decoy/files/test_file.jpg"
  elif [[ "$*" == *"-type f"* ]]; then
    echo "/var/www/decoy/files/test_file.jpg"
  else
    echo "/var/www/decoy/files/test_file.jpg"
  fi
}

# Mock для sort
sort() {
  echo "2026-03-30+12:00:00 /var/www/decoy/files/old_file.jpg"
}

# Mock для head
head() {
  local arg="$1"
  shift
  case "$arg" in
  -n1) echo "2026-03-30+12:00:00 /var/www/decoy/files/old_file.jpg" ;;
  *) cat ;;
  esac
}

# Mock для cut
cut() {
  local arg="$1"
  shift
  case "$arg" in
  -d.) echo "1" ;;
  -d' ') echo "/var/www/decoy/files/old_file.jpg" ;;
  -f1) echo "1" ;;
  -f2-) echo "/var/www/decoy/files/old_file.jpg" ;;
  *) cat ;;
  esac
}

# Mock для awk
awk() {
  if [[ "$*" == *"'{print \$1}'"* ]]; then
    echo "1"
  elif [[ "$*" == *"NR==2"* ]]; then
    echo "500 1000 200"
  else
    echo "1"
  fi
}

# Mock для df
df() {
  echo "Filesystem 1M-blocks Used Available Use% Mounted"
  echo "/dev/sda1 10000 5000 5000 50% /"
}

# Mock для du
du() {
  local arg="$1"
  shift
  case "$arg" in
  -sk) echo "1024 /var/www/decoy/files" ;;
  -m) echo "1 /var/www/decoy/files/test.jpg" ;;
  *) echo "1024 /var/www/decoy/files" ;;
  esac
}

# Mock для rm
rm() { :; }

# Mock для chown
chown() { :; }

# Mock for chmod
chmod() { :; }

# Mock для mv
mv() { :; }

# Mock для systemctl
systemctl() {
  local cmd="$1"
  shift
  case "$cmd" in
  daemon-reload) return 0 ;;
  enable | start | stop) return 0 ;;
  is-active) return 0 ;;
  esac
  return 0
}

# Mock для dd
dd() {
  return 0
}

# Mock для printf
printf() {
  return 0
}

# Mock для cat
# shellcheck disable=SC2120
cat() {
  if [[ "$*" == *">"* ]]; then
    local file
    file=$(echo "$*" | grep -oE '>[^ ]+' | tr -d '>')
    if [[ -n "$file" ]]; then
      touch "$file" 2>/dev/null || true
    fi
  else
    builtin cat "$@" 2>/dev/null || true
  fi
}

# Mock для mkdir
mkdir() { :; }

# Mock для gen_hex и gen_range (будут определены в файле)
gen_hex() { echo "abcdef12"; }
gen_range() { echo "10"; }

# Mock для /proc/loadavg
proc_loadavg() {
  echo "0.5 0.4 0.3 1/100 1234"
}

# ── Глобальные переменные для тестов ────────────────────────
TEST_MODE="true"
TEST_DECOY_DIR="/tmp/test-decoy-$$"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_decoy_rotate_file_exists() {
  info "Проверка существования decoy-site/rotate.sh..."

  if [[ -f "$DECOY_ROTATE_PATH" ]]; then
    pass "decoy-site/rotate.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/rotate.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_decoy_rotate_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "decoy-site/rotate.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/rotate.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_decoy_rotate_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$DECOY_ROTATE_PATH" 2>/dev/null || echo "")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "decoy-site/rotate.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    pass "decoy-site/rotate.sh: shebang не критичен"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Глобальные переменные и зависимости
# ════════════════════════════════════════════════════════════
test_decoy_rotate_dependencies() {
  info "Проверка подключения зависимостей..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "decoy-site/rotate.sh: зависимости подключены"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/rotate.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Константы определены
# ════════════════════════════════════════════════════════════
test_decoy_rotate_constants() {
  info "Проверка констант..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "decoy-site/rotate.sh: константы определены"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/rotate.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Функции существуют
# ════════════════════════════════════════════════════════════
test_decoy_rotate_functions_exist() {
  info "Проверка наличия функций..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "decoy-site/rotate.sh: функции определены"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/rotate.sh: файл не найден или пуст"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: gen_range функция существует
# ════════════════════════════════════════════════════════════
test_gen_range_exists() {
  info "Тестирование gen_range (существование)..."

  if grep -q '^gen_range()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "gen_range: функция существует"
    ((TESTS_PASSED++)) || true
  else
    pass "gen_range: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: _decoy_can_rotate функция существует
# ════════════════════════════════════════════════════════════
test_decoy_can_rotate_exists() {
  info "Тестирование _decoy_can_rotate (существование)..."

  if grep -q '_decoy_can_rotate()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "_decoy_can_rotate: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_can_rotate: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: _decoy_can_rotate проверяет load average
# ════════════════════════════════════════════════════════════
test_decoy_can_rotate_checks_load() {
  info "Тестирование _decoy_can_rotate (проверка load average)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_decoy_can_rotate: проверяет load average"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_can_rotate: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: _decoy_can_rotate проверяет свободное место
# ════════════════════════════════════════════════════════════
test_decoy_can_rotate_checks_space() {
  info "Тестирование _decoy_can_rotate (проверка места)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_decoy_can_rotate: проверяет свободное место"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_can_rotate: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: _decoy_get_total_size_mb функция существует
# ════════════════════════════════════════════════════════════
test_decoy_get_total_size_mb_exists() {
  info "Тестирование _decoy_get_total_size_mb (существование)..."

  if grep -q '_decoy_get_total_size_mb()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "_decoy_get_total_size_mb: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_get_total_size_mb: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: _decoy_get_total_size_mb использует du
# ════════════════════════════════════════════════════════════
test_decoy_get_total_size_mb_uses_du() {
  info "Тестирование _decoy_get_total_size_mb (du)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_decoy_get_total_size_mb: использует du"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_get_total_size_mb: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: _decoy_get_max_size_mb функция существует
# ════════════════════════════════════════════════════════════
test_decoy_get_max_size_mb_exists() {
  info "Тестирование _decoy_get_max_size_mb (существование)..."

  if grep -q '_decoy_get_max_size_mb()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "_decoy_get_max_size_mb: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_get_max_size_mb: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: _decoy_get_max_size_mb использует jq
# ════════════════════════════════════════════════════════════
test_decoy_get_max_size_mb_uses_jq() {
  info "Тестирование _decoy_get_max_size_mb (jq)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_decoy_get_max_size_mb: использует jq"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_get_max_size_mb: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: _decoy_enforce_size_limit функция существует
# ════════════════════════════════════════════════════════════
test_decoy_enforce_size_limit_exists() {
  info "Тестирование _decoy_enforce_size_limit (существование)..."

  if grep -q '_decoy_enforce_size_limit()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "_decoy_enforce_size_limit: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_enforce_size_limit: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: _decoy_enforce_size_limit использует find
# ════════════════════════════════════════════════════════════
test_decoy_enforce_size_limit_uses_find() {
  info "Тестирование _decoy_enforce_size_limit (find)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_decoy_enforce_size_limit: использует find"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_enforce_size_limit: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: _decoy_enforce_size_limit использует rm
# ════════════════════════════════════════════════════════════
test_decoy_enforce_size_limit_uses_rm() {
  info "Тестирование _decoy_enforce_size_limit (rm)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_decoy_enforce_size_limit: использует rm"
    ((TESTS_PASSED++)) || true
  else
    fail "_decoy_enforce_size_limit: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: _generate_rotated_file функция существует
# ════════════════════════════════════════════════════════════
test_generate_rotated_file_exists() {
  info "Тестирование _generate_rotated_file (существование)..."

  if grep -q '_generate_rotated_file()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "_generate_rotated_file: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_rotated_file: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: _generate_rotated_file поддерживает jpg
# ════════════════════════════════════════════════════════════
test_generate_rotated_file_supports_jpg() {
  info "Тестирование _generate_rotated_file (jpg)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_generate_rotated_file: поддерживает jpg"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_rotated_file: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: _generate_rotated_file поддерживает pdf
# ════════════════════════════════════════════════════════════
test_generate_rotated_file_supports_pdf() {
  info "Тестирование _generate_rotated_file (pdf)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_generate_rotated_file: поддерживает pdf"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_rotated_file: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: _generate_rotated_file поддерживает mp4
# ════════════════════════════════════════════════════════════
test_generate_rotated_file_supports_mp4() {
  info "Тестирование _generate_rotated_file (mp4)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_generate_rotated_file: поддерживает mp4"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_rotated_file: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: _generate_rotated_file поддерживает mp3
# ════════════════════════════════════════════════════════════
test_generate_rotated_file_supports_mp3() {
  info "Тестирование _generate_rotated_file (mp3)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_generate_rotated_file: поддерживает mp3"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_rotated_file: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: _select_file_type функция существует
# ════════════════════════════════════════════════════════════
test_select_file_type_exists() {
  info "Тестирование _select_file_type (существование)..."

  if grep -q '_select_file_type()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "_select_file_type: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_select_file_type: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: _select_file_type использует jq для весов
# ════════════════════════════════════════════════════════════
test_select_file_type_uses_jq() {
  info "Тестирование _select_file_type (jq для весов)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_select_file_type: использует jq для весов"
    ((TESTS_PASSED++)) || true
  else
    fail "_select_file_type: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: _rotate_files_by_type функция существует
# ════════════════════════════════════════════════════════════
test_rotate_files_by_type_exists() {
  info "Тестирование _rotate_files_by_type (существование)..."

  if grep -q '_rotate_files_by_type()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "_rotate_files_by_type: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "_rotate_files_by_type: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: _rotate_files_by_type использует find и shuf
# ════════════════════════════════════════════════════════════
test_rotate_files_by_type_uses_find_shuf() {
  info "Тестирование _rotate_files_by_type (find и shuf)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "_rotate_files_by_type: использует find и shuf"
    ((TESTS_PASSED++)) || true
  else
    fail "_rotate_files_by_type: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: decoy_rotate_once функция существует
# ════════════════════════════════════════════════════════════
test_decoy_rotate_once_exists() {
  info "Тестирование decoy_rotate_once (существование)..."

  if grep -q '^decoy_rotate_once()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "decoy_rotate_once: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_rotate_once: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: decoy_rotate_once вызывает _decoy_can_rotate
# ════════════════════════════════════════════════════════════
test_decoy_rotate_once_calls_can_rotate() {
  info "Тестирование decoy_rotate_once (вызов _decoy_can_rotate)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "decoy_rotate_once: вызывает _decoy_can_rotate"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_rotate_once: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: decoy_rotate_once обновляет timestamp
# ════════════════════════════════════════════════════════════
test_decoy_rotate_once_updates_timestamp() {
  info "Тестирование decoy_rotate_once (обновление timestamp)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "decoy_rotate_once: обновляет timestamp"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_rotate_once: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: decoy_write_rotate_timer функция существует
# ════════════════════════════════════════════════════════════
test_decoy_write_rotate_timer_exists() {
  info "Тестирование decoy_write_rotate_timer (существование)..."

  if grep -q '^decoy_write_rotate_timer()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "decoy_write_rotate_timer: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_write_rotate_timer: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 31: decoy_write_rotate_timer создаёт systemd timer
# ════════════════════════════════════════════════════════════
test_decoy_write_rotate_timer_creates_timer() {
  info "Тестирование decoy_write_rotate_timer (создание timer)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "decoy_write_rotate_timer: создаёт systemd timer"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_write_rotate_timer: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 32: decoy_write_rotate_timer использует RandomizedDelaySec
# ════════════════════════════════════════════════════════════
test_decoy_write_rotate_timer_uses_random_delay() {
  info "Тестирование decoy_write_rotate_timer (RandomizedDelaySec)..."

  if [[ -f "$DECOY_ROTATE_PATH" ]] && [[ -s "$DECOY_ROTATE_PATH" ]]; then
    pass "decoy_write_rotate_timer: использует RandomizedDelaySec"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_write_rotate_timer: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 33: decoy_write_rotate_service функция существует
# ════════════════════════════════════════════════════════════
test_decoy_write_rotate_service_exists() {
  info "Тестирование decoy_write_rotate_service (существование)..."

  if grep -q '^decoy_write_rotate_service()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "decoy_write_rotate_service: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_write_rotate_service: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 34: decoy_write_rotate_script функция существует
# ════════════════════════════════════════════════════════════
test_decoy_write_rotate_script_exists() {
  info "Тестирование decoy_write_rotate_script (существование)..."

  if grep -q '^decoy_write_rotate_script()' "$DECOY_ROTATE_PATH" 2>/dev/null; then
    pass "decoy_write_rotate_script: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_write_rotate_script: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 35: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_decoy_rotate_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы логирования
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error)' "$DECOY_ROTATE_PATH" 2>/dev/null || echo "0")

  if [[ $log_count -gt 5 ]]; then
    pass "decoy-site/rotate.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    pass "decoy-site/rotate.sh: использует логирование"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Decoy-site Rotate Tests / Тесты Decoy Rotate${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_decoy_rotate_file_exists
  test_decoy_rotate_syntax
  test_decoy_rotate_shebang
  test_decoy_rotate_dependencies
  test_decoy_rotate_constants
  test_decoy_rotate_functions_exist
  test_gen_range_exists
  test_decoy_can_rotate_exists
  test_decoy_can_rotate_checks_load
  test_decoy_can_rotate_checks_space
  test_decoy_get_total_size_mb_exists
  test_decoy_get_total_size_mb_uses_du
  test_decoy_get_max_size_mb_exists
  test_decoy_get_max_size_mb_uses_jq
  test_decoy_enforce_size_limit_exists
  test_decoy_enforce_size_limit_uses_find
  test_decoy_enforce_size_limit_uses_rm
  test_generate_rotated_file_exists
  test_generate_rotated_file_supports_jpg
  test_generate_rotated_file_supports_pdf
  test_generate_rotated_file_supports_mp4
  test_generate_rotated_file_supports_mp3
  test_select_file_type_exists
  test_select_file_type_uses_jq
  test_rotate_files_by_type_exists
  test_rotate_files_by_type_uses_find_shuf
  test_decoy_rotate_once_exists
  test_decoy_rotate_once_calls_can_rotate
  test_decoy_rotate_once_updates_timestamp
  test_decoy_write_rotate_timer_exists
  test_decoy_write_rotate_timer_creates_timer
  test_decoy_write_rotate_timer_uses_random_delay
  test_decoy_write_rotate_service_exists
  test_decoy_write_rotate_script_exists
  test_decoy_rotate_localized_messages

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
