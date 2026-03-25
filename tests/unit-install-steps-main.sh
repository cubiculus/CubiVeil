#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║      CubiVeil Unit Tests - lib/steps/install-steps-main.sh ║
# ║      Тестирование шагов установки                         ║
# ╚═══════════════════════════════════════════════════════════╝

# Strict mode отключен для совместимости с mock-функциями

# ── Путь к проекту ───────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STEPS_FILE="${SCRIPT_DIR}/lib/steps/install-steps-main.sh"

# ── Счётчик тестов ───────────────────────────────────────────
TESTS_PASSED=0
TESTS_FAILED=0

# ── Цвета ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# ── Функции вывода ───────────────────────────────────────────
info() { echo -e "${CYAN}[INFO]${PLAIN} $*" >&2; }
pass() {
  echo -e "${GREEN}[PASS]${PLAIN} $*" >&2
  ((TESTS_PASSED++))
}
fail() {
  echo -e "${RED}[FAIL]${PLAIN} $*" >&2
  ((TESTS_FAILED++))
}
warn() { echo -e "${YELLOW}[WARN]${PLAIN} $*" >&2; }

# ── Mock зависимостей ────────────────────────────────────────
# shellcheck disable=SC2034
LANG_NAME="English"
SERVER_IP="1.2.3.4"
DOMAIN="test.example.com"
LE_EMAIL="test@example.com"
# shellcheck disable=SC2034
INSTALL_TG="n"
TROJAN_PORT="10443"
SS_PORT="10444"
PANEL_PORT="10445"
SUB_PORT="10446"
REALITY_SNI="www.microsoft.com"
DEV_MODE="false"
# shellcheck disable=SC2034
DRY_RUN="false"

# Mock функций из output.sh
step() { echo "[STEP] $1" >&2; }
ok() { echo "[OK] $1" >&2; }
warn() { echo "[WARN] $1" >&2; }
err() { echo "[ERR] $1" >&2; }
info() { echo "[INFO] $1" >&2; }

# Mock функций из utils.sh
get_server_ip_info() { echo "Server IP: ${SERVER_IP:-1.2.3.4}"; }
get_server_ip_info_en() { echo "Server IP: ${SERVER_IP:-1.2.3.4}"; }

# Mock внешних команд
curl() {
  local url=""
  for arg in "$@"; do
    if [[ "$arg" =~ ^https?:// ]]; then
      url="$arg"
      break
    fi
  done

  case "$url" in
  *api4.ipify.org*) echo "1.2.3.4" ;;
  *api.github.com*) echo '{"tag_name": "v1.10.1"}' ;;
  *ip-api.com/json/*)
    # Mock ответ от ip-api.com (чистый IP, без proxy/hosting)
    echo '{"status":"success","message":"","proxy":false,"hosting":false,"mobile":false}'
    ;;
  *) echo "mock_response" ;;
  esac
}

apt-get() {
  local action="$1"
  shift
  case "$action" in
  update) echo "[MOCK] apt-get update" >&2 ;;
  upgrade) echo "[MOCK] apt-get upgrade" >&2 ;;
  install) echo "[MOCK] apt-get install $*" >&2 ;;
  esac
}

systemctl() {
  local action="$1"
  shift
  echo "[MOCK] systemctl $action $*" >&2
}

grep() {
  local pattern="$1"
  shift
  if [[ "$pattern" == "ubuntu" ]]; then
    echo "ID=ubuntu"
    return 0
  fi
  command grep "$pattern" "$@" 2>/dev/null || true
}

jq() {
  local filter="$1"
  shift
  if [[ "$filter" == "-r" ]]; then
    shift
    filter="$1"
    shift
  fi
  echo "1.10.1"
}

uname() {
  local arg="$1"
  case "$arg" in
  -m) echo "x86_64" ;;
  *) echo "Linux" ;;
  esac
}

seq() {
  local start="$1"
  local end="$2"
  # Для тестов возвращаем только несколько IP
  local i
  for ((i=start; i<=end && i<=5; i++)); do
    echo "$i"
  done
}

sleep() {
  # Игнорируем sleep в тестах
  true
}

openssl() {
  local action="$1"
  shift
  case "$action" in
  req)
    # Mock генерации сертификата
    touch /tmp/mock_cert.pem 2>/dev/null || true
    touch /tmp/mock_key.pem 2>/dev/null || true
    ;;
  rand) echo "mock_random_$(date +%s)" ;;
  *) echo "mock_openssl_output" ;;
  esac
}

# ── Загрузка тестируемого модуля ─────────────────────────────
load_module() {
  if [[ -f "$STEPS_FILE" ]]; then
    # shellcheck source=lib/steps/install-steps-main.sh
    source "$STEPS_FILE"
  fi
}

# ── Тест: файл существует ────────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла install-steps-main.sh..."

  if [[ -f "$STEPS_FILE" ]]; then
    pass "install-steps-main.sh: файл существует"
  else
    fail "install-steps-main.sh: файл не найден"
  fi
}

# ── Тест: синтаксис корректен ────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса install-steps-main.sh..."

  if bash -n "$STEPS_FILE" 2>/dev/null; then
    pass "install-steps-main.sh: синтаксис корректен"
  else
    fail "install-steps-main.sh: синтаксическая ошибка"
  fi
}

# ── Тест: step_check_ip_neighborhood существует ──────────────
test_step_check_ip_neighborhood() {
  info "Тестирование функции step_check_ip_neighborhood..."

  load_module

  if declare -f step_check_ip_neighborhood >/dev/null; then
    pass "step_check_ip_neighborhood: функция существует"
  else
    fail "step_check_ip_neighborhood: функция не найдена"
  fi
}

# ── Тест: step_check_ip_neighborhood использует curl ─────────
test_step_check_ip_neighborhood_uses_curl() {
  info "Тестирование step_check_ip_neighborhood: использование curl..."

  load_module

  local func_content
  func_content=$(declare -f step_check_ip_neighborhood 2>/dev/null || echo "")

  if [[ "$func_content" == *"curl"* ]] && [[ "$func_content" == *"ip-api.com"* ]]; then
    pass "step_check_ip_neighborhood: использует curl и ip-api.com"
  else
    fail "step_check_ip_neighborhood: не использует curl/ip-api.com"
  fi
}

# ── Тест: step_check_ip_neighborhood проверяет proxy/hosting ─
test_step_check_ip_neighborhood_checks_proxy_hosting() {
  info "Тестирование step_check_ip_neighborhood: проверка proxy/hosting..."

  load_module

  local func_content
  func_content=$(declare -f step_check_ip_neighborhood 2>/dev/null || echo "")

  if [[ "$func_content" == *"proxy"* ]] && [[ "$func_content" == *"hosting"* ]]; then
    pass "step_check_ip_neighborhood: проверяет proxy и hosting"
  else
    fail "step_check_ip_neighborhood: не проверяет proxy/hosting"
  fi
}

# ── Тест: step_check_ip_neighborhood имеет цикл проверки ─────
test_step_check_ip_neighborhood_has_loop() {
  info "Тестирование step_check_ip_neighborhood: наличие цикла..."

  load_module

  local func_content
  func_content=$(declare -f step_check_ip_neighborhood 2>/dev/null || echo "")

  if [[ "$func_content" == *"for"* ]] || [[ "$func_content" == *"seq"* ]]; then
    pass "step_check_ip_neighborhood: имеет цикл для проверки IP"
  else
    fail "step_check_ip_neighborhood: нет цикла для проверки IP"
  fi
}

# ── Тест: step_system_update существует ──────────────────────
test_step_system_update() {
  info "Тестирование функции step_system_update..."

  load_module

  if declare -f step_system_update >/dev/null; then
    pass "step_system_update: функция существует"
  else
    fail "step_system_update: функция не найдена"
  fi
}

# ── Тест: step_auto_updates существует ───────────────────────
test_step_auto_updates() {
  info "Тестирование функции step_auto_updates..."

  load_module

  if declare -f step_auto_updates >/dev/null; then
    pass "step_auto_updates: функция существует"
  else
    fail "step_auto_updates: функция не найдена"
  fi
}

# ── Тест: step_bbr существует ────────────────────────────────
test_step_bbr() {
  info "Тестирование функции step_bbr..."

  load_module

  if declare -f step_bbr >/dev/null; then
    pass "step_bbr: функция существует"
  else
    fail "step_bbr: функция не найдена"
  fi
}

# ── Тест: step_firewall существует ───────────────────────────
test_step_firewall() {
  info "Тестирование функции step_firewall..."

  load_module

  if declare -f step_firewall >/dev/null; then
    pass "step_firewall: функция существует"
  else
    fail "step_firewall: функция не найдена"
  fi
}

# ── Тест: step_fail2ban существует ───────────────────────────
test_step_fail2ban() {
  info "Тестирование функции step_fail2ban..."

  load_module

  if declare -f step_fail2ban >/dev/null; then
    pass "step_fail2ban: функция существует"
  else
    fail "step_fail2ban: функция не найдена"
  fi
}

# ── Тест: step_install_singbox существует ────────────────────
test_step_install_singbox() {
  info "Тестирование функции step_install_singbox..."

  load_module

  if declare -f step_install_singbox >/dev/null; then
    pass "step_install_singbox: функция существует"
  else
    fail "step_install_singbox: функция не найдена"
  fi
}

# ── Тест: step_generate_keys_and_ports существует ────────────
test_step_generate_keys_and_ports() {
  info "Тестирование функции step_generate_keys_and_ports..."

  load_module

  if declare -f step_generate_keys_and_ports >/dev/null; then
    pass "step_generate_keys_and_ports: функция существует"
  else
    fail "step_generate_keys_and_ports: функция не найдена"
  fi
}

# ── Тест: step_install_marzban существует ────────────────────
test_step_install_marzban() {
  info "Тестирование функции step_install_marzban..."

  load_module

  if declare -f step_install_marzban >/dev/null; then
    pass "step_install_marzban: функция существует"
  else
    fail "step_install_marzban: функция не найдена"
  fi
}

# ── Тест: step_ssl существует ────────────────────────────────
test_step_ssl() {
  info "Тестирование функции step_ssl..."

  load_module

  if declare -f step_ssl >/dev/null; then
    pass "step_ssl: функция существует"
  else
    fail "step_ssl: функция не найдена"
  fi
}

# ── Тест: step_ssl_dev существует ────────────────────────────
test_step_ssl_dev() {
  info "Тестирование функции step_ssl_dev..."

  load_module

  if declare -f step_ssl_dev >/dev/null; then
    pass "step_ssl_dev: функция существует"
  else
    fail "step_ssl_dev: функция не найдена"
  fi
}

# ── Тест: step_ssl вызывает step_ssl_dev в dev-режиме ────────
test_step_ssl_calls_dev() {
  info "Тестирование step_ssl: вызов dev-режима..."

  load_module

  # Проверяем что step_ssl проверяет DEV_MODE
  local func_content
  func_content=$(declare -f step_ssl 2>/dev/null || echo "")

  if [[ "$func_content" == *"DEV_MODE"* ]] || [[ "$func_content" == *"step_ssl_dev"* ]]; then
    pass "step_ssl: проверяет DEV_MODE и вызывает step_ssl_dev"
  else
    fail "step_ssl: не проверяет DEV_MODE"
  fi
}

# ── Тест: step_ssl_dev генерирует self-signed сертификат ─────
test_step_ssl_dev_generates_cert() {
  info "Тестирование step_ssl_dev: генерация сертификата..."

  load_module

  local func_content
  func_content=$(declare -f step_ssl_dev 2>/dev/null || echo "")

  if [[ "$func_content" == *"openssl"* ]] && [[ "$func_content" == *"-x509"* ]]; then
    pass "step_ssl_dev: использует openssl для генерации self-signed"
  else
    fail "step_ssl_dev: не использует openssl"
  fi
}

# ── Тест: step_ssl_dev создаёт директорию для сертификатов ───
test_step_ssl_dev_creates_dir() {
  info "Тестирование step_ssl_dev: создание директории..."

  load_module

  local func_content
  func_content=$(declare -f step_ssl_dev 2>/dev/null || echo "")

  if [[ "$func_content" == *"mkdir -p"* ]] && [[ "$func_content" == *"/var/lib/marzban/certs"* ]]; then
    pass "step_ssl_dev: создаёт директорию для сертификатов"
  else
    fail "step_ssl_dev: не создаёт директорию для сертификатов"
  fi
}

# ── Тест: step_configure существует ──────────────────────────
test_step_configure() {
  info "Тестирование функции step_configure..."

  load_module

  if declare -f step_configure >/dev/null; then
    pass "step_configure: функция существует"
  else
    fail "step_configure: функция не найдена"
  fi
}

# ── Тест: step_finish существует ─────────────────────────────
test_step_finish() {
  info "Тестирование функции step_finish..."

  load_module

  if declare -f step_finish >/dev/null; then
    pass "step_finish: функция существует"
  else
    fail "step_finish: функция не найдена"
  fi
}

# ── Тест: step_finish показывает URL панели ──────────────────
test_step_finish_shows_url() {
  info "Тестирование step_finish: отображение URL..."

  load_module

  local func_content
  func_content=$(declare -f step_finish 2>/dev/null || echo "")

  if [[ "$func_content" == *"Panel URL"* ]] || [[ "$func_content" == *"URL панели"* ]]; then
    pass "step_finish: показывает URL панели"
  else
    fail "step_finish: не показывает URL панели"
  fi
}

# ── Тест: step_finish предупреждает о dev-режиме ─────────────
test_step_finish_dev_warning() {
  info "Тестирование step_finish: предупреждение о dev-режиме..."

  load_module

  local func_content
  func_content=$(declare -f step_finish 2>/dev/null || echo "")

  if [[ "$func_content" == *"DEV MODE"* ]] || [[ "$func_content" == *"DEV-РЕЖИМ"* ]] ||
    [[ "$func_content" == *"DEV_MODE"* ]]; then
    pass "step_finish: предупреждает о dev-режиме"
  else
    fail "step_finish: не предупреждает о dev-режиме"
  fi
}

# ── Тест: step_finish предупреждает о self-signed SSL ────────
test_step_finish_ssl_warning() {
  info "Тестирование step_finish: предупреждение о self-signed SSL..."

  load_module

  local func_content
  func_content=$(declare -f step_finish 2>/dev/null || echo "")

  if [[ "$func_content" == *"self-signed"* ]] || [[ "$func_content" == *"самоподписной"* ]] ||
    [[ "$func_content" == *"security warning"* ]]; then
    pass "step_finish: предупреждает о self-signed SSL"
  else
    fail "step_finish: не предупреждает о self-signed SSL"
  fi
}

# ── Тест: все step_ функции экспортированы ───────────────────
test_all_steps_exported() {
  info "Тестирование экспорта всех step_ функций..."

  load_module

  local required_steps=(
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
    "step_ssl_dev"
    "step_configure"
    "step_finish"
  )

  local missing=()
  for step_func in "${required_steps[@]}"; do
    if ! declare -f "$step_func" >/dev/null 2>&1; then
      missing+=("$step_func")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    pass "Все step_ функции экспортированы"
  else
    fail "Отсутствуют функции: ${missing[*]}"
  fi
}

# ── Тест: локализация в функциях ─────────────────────────────
test_localization_in_steps() {
  info "Тестирование локализации в step_ функциях..."

  load_module

  local func_content
  func_content=$(declare -f step_finish 2>/dev/null || echo "")

  if [[ "$func_content" == *"LANG_NAME"* ]] || [[ "$func_content" == *"Русский"* ]]; then
    pass "step_ функции поддерживают локализацию"
  else
    warn "step_ функции могут не поддерживать локализацию"
  fi
}

# ── Запуск тестов ────────────────────────────────────────────
main() {
  echo "══════════════════════════════════════════════════════════"
  echo "  CubiVeil Unit Tests - lib/steps/install-steps-main.sh"
  echo "  Тестирование шагов установки"
  echo "══════════════════════════════════════════════════════════"
  echo ""

  # Базовые тесты
  test_file_exists
  test_syntax

  # Тесты функций
  test_step_check_ip_neighborhood
  test_step_check_ip_neighborhood_uses_curl
  test_step_check_ip_neighborhood_checks_proxy_hosting
  test_step_check_ip_neighborhood_has_loop
  test_step_system_update
  test_step_auto_updates
  test_step_bbr
  test_step_firewall
  test_step_fail2ban
  test_step_install_singbox
  test_step_generate_keys_and_ports
  test_step_install_marzban
  test_step_ssl
  test_step_ssl_dev
  test_step_ssl_calls_dev
  test_step_ssl_dev_generates_cert
  test_step_ssl_dev_creates_dir
  test_step_configure
  test_step_finish
  test_step_finish_shows_url
  test_step_finish_dev_warning
  test_step_finish_ssl_warning

  # Дополнительные тесты
  test_all_steps_exported
  test_localization_in_steps

  # ── Итоги ────────────────────────────────────────────────────
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  Результаты / Results"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo -e "  Пройдено ${GREEN}(${TESTS_PASSED})${PLAIN}"
  echo -e "  Провалено ${RED}(${TESTS_FAILED})${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}  Тесты не пройдены${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}  Все тесты пройдены ✓${PLAIN}"
    exit 0
  fi
}

main "$@"
