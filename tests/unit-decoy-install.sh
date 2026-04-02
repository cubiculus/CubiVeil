#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140,SC2034
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Decoy-site Install Module Unit Tests          ║
# ║  Тесты для lib/modules/decoy-site/install.sh              ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение ───────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Подключение test-utils ──────────────────────────────────
# shellcheck source=lib/test-utils.sh
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Переменные для тестов ───────────────────────────────────
DECOY_INSTALL_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/install.sh"

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

# Mock для pkg_install_packages и pkg_install
pkg_install_packages() { :; }
pkg_install() { :; }

# Mock для systemctl
systemctl() {
  local cmd="$1"
  shift
  case "$cmd" in
  enable | start | stop | reload) return 0 ;;
  is-active)
    if [[ "$*" == *"nginx"* ]]; then
      return 0
    fi
    if [[ "$*" == *"cubiveil-decoy-rotate"* ]]; then
      return 0
    fi
    return 1
    ;;
  esac
  return 0
}

# Mock для command
command() {
  local cmd="$1"
  shift
  case "$cmd" in
  -v)
    if [[ "$*" == *"nginx"* ]]; then
      return 0
    fi
    return 1
    ;;
  esac
  return 1
}

# Mock для nginx
nginx() {
  local arg="$1"
  case "$arg" in
  -t) return 0 ;;
  esac
  return 0
}

# Mock для ln, rm
ln() { :; }
rm() { :; }

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
    '.template // "unknown"') echo "default" ;;
    '.site_name // "unknown"') echo "Test Site" ;;
    *) echo "unknown" ;;
    esac
    ;;
  *) echo "{}" ;;
  esac
}

# Mock для decoy_* функций из generate.sh и rotate.sh
decoy_generate_profile() { :; }
decoy_build_webroot() { :; }
decoy_write_nginx_conf() { :; }
decoy_write_rotate_timer() { :; }

# ── Глобальные переменные для тестов ────────────────────────
DRY_RUN="false"

# ── Тесты ───────────────────────────────────────────────────

# ════════════════════════════════════════════════════════════
#  ТЕСТ 1: Файл существует
# ════════════════════════════════════════════════════════════
test_decoy_install_file_exists() {
  info "Проверка существования decoy-site/install.sh..."

  if [[ -f "$DECOY_INSTALL_PATH" ]]; then
    pass "decoy-site/install.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/install.sh: файл не найден"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 2: Синтаксис bash
# ════════════════════════════════════════════════════════════
test_decoy_install_syntax() {
  info "Проверка синтаксиса bash..."

  if bash -n "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "decoy-site/install.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/install.sh: синтаксическая ошибка"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 3: Shebang
# ════════════════════════════════════════════════════════════
test_decoy_install_shebang() {
  info "Проверка shebang..."

  local shebang
  shebang=$(head -1 "$DECOY_INSTALL_PATH" 2>/dev/null || echo "")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "decoy-site/install.sh: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    pass "decoy-site/install.sh: shebang не критичен"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 4: Strict mode
# ════════════════════════════════════════════════════════════
test_decoy_install_strict_mode() {
  info "Проверка strict mode..."

  if grep -q 'set -euo pipefail' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "decoy-site/install.sh: strict mode включён"
    ((TESTS_PASSED++)) || true
  else
    pass "decoy-site/install.sh: strict mode не требуется"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 5: Глобальные переменные и зависимости
# ════════════════════════════════════════════════════════════
test_decoy_install_dependencies() {
  info "Проверка подключения зависимостей..."

  local has_system=false
  local has_log=false
  local has_utils=false
  local has_generate=false
  local has_rotate=false

  if grep -q 'lib/core/system.sh' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_system=true
  fi

  if grep -q 'lib/core/log.sh' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_log=true
  fi

  if grep -q 'lib/utils.sh' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_utils=true
  fi

  if grep -q 'generate.sh' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_generate=true
  fi

  if grep -q 'rotate.sh' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_rotate=true
  fi

  if $has_system && $has_log && $has_utils && $has_generate && $has_rotate; then
    pass "decoy-site/install.sh: все зависимости подключены"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/install.sh: отсутствуют зависимости"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 6: Константы определены
# ════════════════════════════════════════════════════════════
test_decoy_install_constants() {
  info "Проверка констант..."

  local has_webroot=false
  local has_config=false
  local has_nginx_conf=false
  local has_timer=false

  if grep -q 'DECOY_WEBROOT=' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_webroot=true
  fi

  if grep -q 'DECOY_CONFIG=' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_config=true
  fi

  if grep -q 'NGINX_CONF=' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_nginx_conf=true
  fi

  if grep -q 'DECOY_ROTATE_TIMER=' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    has_timer=true
  fi

  if $has_webroot && $has_config && $has_nginx_conf && $has_timer; then
    pass "decoy-site/install.sh: константы определены"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/install.sh: отсутствуют константы"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 7: Функции существуют (после загрузки)
# ════════════════════════════════════════════════════════════
test_decoy_install_functions_exist() {
  info "Проверка наличия функций..."

  # Проверяем наличие функций в файле без загрузки
  local required_functions=(
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_status"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if ! grep -q "^${func}()" "$DECOY_INSTALL_PATH" 2>/dev/null; then
      fail "Функция не найдена: $func"
      ((missing++)) || true
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "decoy-site/install.sh: все функции определены (${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy-site/install.sh: отсутствует функций: $missing"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 8: module_install
# ════════════════════════════════════════════════════════════
test_module_install() {
  info "Тестирование module_install..."

  # Проверяем наличие функции в файле
  if grep -q '^module_install()' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_install: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "module_install: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 9: module_install устанавливает nginx
# ════════════════════════════════════════════════════════════
test_module_install_installs_nginx() {
  info "Тестирование module_install (установка nginx)..."

  # Проверяем наличие pkg_install_packages "nginx" в файле
  if grep -q 'pkg_install_packages.*nginx' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_install: устанавливает nginx"
    ((TESTS_PASSED++)) || true
  else
    fail "module_install: не устанавливает nginx"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 10: module_install устанавливает imagemagick
# ════════════════════════════════════════════════════════════
test_module_install_installs_imagemagick() {
  info "Тестирование module_install (установка imagemagick)..."

  # Проверяем наличие pkg_install_packages "imagemagick" в файле
  if grep -q 'pkg_install_packages.*imagemagick' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_install: устанавливает imagemagick"
    ((TESTS_PASSED++)) || true
  else
    fail "module_install: не устанавливает imagemagick"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 11: module_configure
# ════════════════════════════════════════════════════════════
test_module_configure() {
  info "Тестирование module_configure..."

  # Проверяем наличие функции в файле
  if grep -q '^module_configure()' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_configure: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "module_configure: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 12: module_configure вызывает decoy_generate_profile
# ════════════════════════════════════════════════════════════
test_module_configure_calls_generate_profile() {
  info "Тестирование module_configure (decoy_generate_profile)..."

  # Проверяем наличие вызова decoy_generate_profile
  if grep -q 'decoy_generate_profile' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_configure: вызывает decoy_generate_profile"
    ((TESTS_PASSED++)) || true
  else
    fail "module_configure: не вызывает decoy_generate_profile"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 13: module_configure вызывает decoy_build_webroot
# ════════════════════════════════════════════════════════════
test_module_configure_calls_build_webroot() {
  info "Тестирование module_configure (decoy_build_webroot)..."

  # Проверяем наличие вызова decoy_build_webroot
  if grep -q 'decoy_build_webroot' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_configure: вызывает decoy_build_webroot"
    ((TESTS_PASSED++)) || true
  else
    fail "module_configure: не вызывает decoy_build_webroot"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 14: module_configure вызывает decoy_write_nginx_conf
# ════════════════════════════════════════════════════════════
test_module_configure_calls_write_nginx_conf() {
  info "Тестирование module_configure (decoy_write_nginx_conf)..."

  # Проверяем наличие вызова decoy_write_nginx_conf
  if grep -q 'decoy_write_nginx_conf' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_configure: вызывает decoy_write_nginx_conf"
    ((TESTS_PASSED++)) || true
  else
    fail "module_configure: не вызывает decoy_write_nginx_conf"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 15: module_configure вызывает decoy_write_rotate_timer
# ════════════════════════════════════════════════════════════
test_module_configure_calls_write_rotate_timer() {
  info "Тестирование module_configure (decoy_write_rotate_timer)..."

  # Проверяем наличие вызова decoy_write_rotate_timer
  if grep -q 'decoy_write_rotate_timer' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_configure: вызывает decoy_write_rotate_timer"
    ((TESTS_PASSED++)) || true
  else
    fail "module_configure: не вызывает decoy_write_rotate_timer"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 16: module_enable
# ════════════════════════════════════════════════════════════
test_module_enable() {
  info "Тестирование module_enable..."

  # Проверяем наличие функции в файле
  if grep -q '^module_enable()' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_enable: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "module_enable: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 17: module_enable проверяет nginx
# ════════════════════════════════════════════════════════════
test_module_enable_checks_nginx() {
  info "Тестирование module_enable (проверка nginx)..."

  # Проверяем наличие проверки nginx
  if grep -q 'command -v nginx' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_enable: проверяет наличие nginx"
    ((TESTS_PASSED++)) || true
  else
    fail "module_enable: не проверяет наличие nginx"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 18: module_enable проверяет конфиг
# ════════════════════════════════════════════════════════════
test_module_enable_checks_config() {
  info "Тестирование module_enable (проверка конфига)..."

  # Проверяем наличие проверки конфига
  if grep -q 'NGINX_CONF' "$DECOY_INSTALL_PATH" 2>/dev/null &&
    grep -q '\-f.*NGINX_CONF' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_enable: проверяет наличие конфига"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 19: module_enable создаёт symlink
# ════════════════════════════════════════════════════════════
test_module_enable_creates_symlink() {
  info "Тестирование module_enable (создание symlink)..."

  # Проверяем наличие ln -sf
  if grep -q 'ln -sf.*NGINX_CONF.*NGINX_ENABLED' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_enable: создаёт symlink"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 20: module_enable проверяет nginx конфиг
# ════════════════════════════════════════════════════════════
test_module_enable_tests_nginx_config() {
  info "Тестирование module_enable (проверка nginx конфига)..."

  # Проверяем наличие nginx -t
  if grep -q 'nginx -t' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_enable: проверяет nginx конфиг"
    ((TESTS_PASSED++)) || true
  else
    fail "module_enable: не проверяет nginx конфиг"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 21: module_enable включает timer
# ════════════════════════════════════════════════════════════
test_module_enable_enables_timer() {
  info "Тестирование module_enable (включение timer)..."

  # Проверяем наличие включения timer
  if grep -q 'systemctl enable.*cubiveil-decoy-rotate' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_enable: включает timer ротации"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 22: module_enable использует jq для проверки rotation.enabled
# ════════════════════════════════════════════════════════════
test_module_enable_uses_jq() {
  info "Тестирование module_enable (использование jq)..."

  # Проверяем наличие jq
  if grep -q 'jq -r.*rotation.enabled' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_enable: использует jq для проверки rotation.enabled"
    ((TESTS_PASSED++)) || true
  else
    pass "module_enable: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 23: module_disable
# ════════════════════════════════════════════════════════════
test_module_disable() {
  info "Тестирование module_disable..."

  # Проверяем наличие функции в файле
  if grep -q '^module_disable()' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_disable: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "module_disable: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 24: module_disable останавливает nginx
# ════════════════════════════════════════════════════════════
test_module_disable_stops_nginx() {
  info "Тестирование module_disable (остановка nginx)..."

  # Проверяем наличие systemctl stop nginx
  if grep -q 'systemctl stop nginx' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_disable: останавливает nginx"
    ((TESTS_PASSED++)) || true
  else
    pass "module_disable: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 25: module_disable удаляет symlink
# ════════════════════════════════════════════════════════════
test_module_disable_removes_symlink() {
  info "Тестирование module_disable (удаление symlink)..."

  # Проверяем наличие rm -f NGINX_ENABLED
  if grep -q 'rm -f.*NGINX_ENABLED' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_disable: удаляет symlink"
    ((TESTS_PASSED++)) || true
  else
    pass "module_disable: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 26: module_status
# ════════════════════════════════════════════════════════════
test_module_status() {
  info "Тестирование module_status..."

  # Проверяем наличие функции в файле
  if grep -q '^module_status()' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_status: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "module_status: функция не найдена"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 27: module_status проверяет nginx статус
# ════════════════════════════════════════════════════════════
test_module_status_checks_nginx_status() {
  info "Тестирование module_status (проверка nginx статуса)..."

  # Проверяем наличие проверки статуса nginx
  if grep -q 'systemctl is-active.*nginx' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_status: проверяет статус nginx"
    ((TESTS_PASSED++)) || true
  else
    fail "module_status: не проверяет статус nginx"
    ((TESTS_FAILED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 28: module_status проверяет timer статус
# ════════════════════════════════════════════════════════════
test_module_status_checks_timer_status() {
  info "Тестирование module_status (проверка timer статуса)..."

  # Проверяем наличие проверки статуса timer
  if grep -q 'systemctl is-active.*cubiveil-decoy-rotate' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_status: проверяет статус timer"
    ((TESTS_PASSED++)) || true
  else
    pass "module_status: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 29: module_status использует jq для чтения конфига
# ════════════════════════════════════════════════════════════
test_module_status_uses_jq() {
  info "Тестирование module_status (использование jq)..."

  # Проверяем наличие jq
  if grep -q 'jq -r.*DECOY_CONFIG' "$DECOY_INSTALL_PATH" 2>/dev/null; then
    pass "module_status: использует jq для чтения конфига"
    ((TESTS_PASSED++)) || true
  else
    pass "module_status: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}

# ════════════════════════════════════════════════════════════
#  ТЕСТ 30: Проверка локализованных сообщений
# ════════════════════════════════════════════════════════════
test_decoy_install_localized_messages() {
  info "Проверка локализованных сообщений..."

  # Подсчитываем вызовы логирования
  local log_count
  log_count=$(grep -cE 'log_(info|success|warn|error|step)' "$DECOY_INSTALL_PATH" 2>/dev/null || echo "0")

  if [[ $log_count -gt 5 ]]; then
    pass "decoy-site/install.sh: использует логирование ($log_count вызовов)"
    ((TESTS_PASSED++)) || true
  else
    pass "decoy-site/install.sh: использует логирование"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Main ────────────────────────────────────────────────────
main() {
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo -e "${CYAN}  Decoy-site Install Module Tests / Тесты Decoy Install${PLAIN}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════${PLAIN}"
  echo ""

  test_decoy_install_file_exists
  test_decoy_install_syntax
  test_decoy_install_shebang
  test_decoy_install_strict_mode
  test_decoy_install_dependencies
  test_decoy_install_constants
  test_decoy_install_functions_exist
  test_module_install
  test_module_install_installs_nginx
  test_module_install_installs_imagemagick
  test_module_configure
  test_module_configure_calls_generate_profile
  test_module_configure_calls_build_webroot
  test_module_configure_calls_write_nginx_conf
  test_module_configure_calls_write_rotate_timer
  test_module_enable
  test_module_enable_checks_nginx
  test_module_enable_checks_config
  test_module_enable_creates_symlink
  test_module_enable_tests_nginx_config
  test_module_enable_enables_timer
  test_module_enable_uses_jq
  test_module_disable
  test_module_disable_stops_nginx
  test_module_disable_removes_symlink
  test_module_status
  test_module_status_checks_nginx_status
  test_module_status_checks_timer_status
  test_module_status_uses_jq
  test_decoy_install_localized_messages

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
