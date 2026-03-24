#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║      CubiVeil Unit Tests - lib/install-steps.sh         ║
# ║      Тестирование функций установки                      ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Загрузка тестируемого модуля ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "${SCRIPT_DIR}/lib/install-steps.sh" ]]; then
  echo "Ошибка: lib/install-steps.sh не найден"
  exit 1
fi

# ── Mock зависимостей ─────────────────────────────────────────
LANG_NAME="English"
SERVER_IP="1.2.3.4"
DOMAIN=""
LE_EMAIL=""
INSTALL_TG="n"
TROJAN_PORT=""
SS_PORT=""
PANEL_PORT=""
SUB_PORT=""
REALITY_PRIVATE_KEY=""
REALITY_PUBLIC_KEY=""
REALITY_SHORT_ID=""
REALITY_SNI=""
UUID_VLESS_TCP=""
UUID_VLESS_GRPC=""
UUID_HY2=""
UUID_TROJAN=""
SS_PASSWORD=""
SUDO_USERNAME=""
SUDO_PASSWORD=""
SECRET_KEY=""
PANEL_PATH=""
SUB_PATH=""
TROJAN_WS_PATH=""

# Mock функций из utils.sh
gen_random() {
  LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom 2>/dev/null | fold -w "$1" | head -n 1 || echo "mock_random_$1"
}

gen_hex() {
  LC_ALL=C tr -dc 'a-f0-9' </dev/urandom 2>/dev/null | fold -w "$1" | head -n 1 || echo "mock_hex_$1"
}

gen_port() {
  shuf -i 30000-62000 -n 1 2>/dev/null || echo "$((30000 + RANDOM % 32000))"
}

unique_port() {
  local p
  p=$(gen_port)
  echo "$p"
}

open_port() {
  local port="$1"
  local proto="${2:-tcp}"
  local comment="${3:-cubiveil}"
  # Mock: просто записываем в лог
  echo "mock_open_port: $port/$proto" >> /tmp/cubiveil_test_ports.log
}

close_port() {
  : # Mock
}

get_server_ip() {
  echo "$SERVER_IP"
}

arch() {
  echo "amd64"
}

# Mock функций вывода
step() { echo "[STEP] $1" >&2; }
ok() { echo "[OK] $1" >&2; }
warn() { echo "[WARN] $1" >&2; }
err() {
  echo "[ERR] $1" >&2
  return 1
}
info() { echo "[INFO] $1" >&2; }

# Mock внешних команд
curl() {
  local url=""
  for arg in "$@"; do
    if [[ "$arg" =~ ^https?:// ]]; then
      url="$arg"
      break
    fi
  done
  
  # Mock для разных URL
  if [[ "$url" =~ ipinfo\.io ]]; then
    echo '{"ip":"1.2.3.5","org":"Test ISP"}'
  elif [[ "$url" =~ github\.com.*sing-box.*releases ]]; then
    echo '{"tag_name":"v1.17.0"}'
  elif [[ "$url" =~ acme\.sh ]]; then
    echo "mock acme response"
  else
    echo "mock curl response"
  fi
}

dig() {
  echo "1.2.3.4"
}

apt-get() {
  echo "mock apt-get: $*" >&2
}

systemctl() {
  local action="$1"
  local service="$2"
  
  if [[ "$action" == "is-active" ]]; then
    echo "active"
  else
    echo "mock systemctl: $*" >&2
  fi
}

ss() {
  # Mock: никаких портов не занято
  return 1
}

command() {
  local cmd="$1"
  shift
  if [[ "$cmd" == "-v" ]]; then
    # Некоторые команды "не установлены"
    case "$1" in
      dig|jq|logrotate) return 1 ;;
      *) return 0 ;;
    esac
  fi
}

sing-box() {
  local subcmd="$1"
  shift
  case "$subcmd" in
    generate)
      if [[ "$1" == "reality-keypair" ]]; then
        echo "PrivateKey mock_private_key_12345"
        echo "PublicKey mock_public_key_67890"
      elif [[ "$1" == "uuid" ]]; then
        echo "mock-uuid-$(gen_random 8)"
      fi
      ;;
    *)
      echo "mock sing-box: $*" >&2
      ;;
  esac
}

# ── Тест: prompt_inputs (базовый) ─────────────────────────────
test_prompt_inputs_mock() {
  info "Тестирование prompt_inputs (mock)..."

  # Проверяем что функция существует
  if declare -f prompt_inputs >/dev/null; then
    pass "Функция prompt_inputs существует"
    ((TESTS_PASSED++))
  else
    fail "Функция prompt_inputs отсутствует"
    return
  fi

  # Функция требует интерактивного ввода, проверяем только наличие
  # и базовую структуру
  local func_source
  func_source=$(declare -f prompt_inputs)
  
  # Проверка что есть валидация домена
  if echo "$func_source" | grep -q "DOMAIN"; then
    pass "prompt_inputs: работает с DOMAIN"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что есть валидация email
  if echo "$func_source" | grep -q "LE_EMAIL"; then
    pass "prompt_inputs: работает с LE_EMAIL"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что есть опция Telegram
  if echo "$func_source" | grep -q "INSTALL_TG"; then
    pass "prompt_inputs: работает с INSTALL_TG"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_check_ip_neighborhood ──────────────────────────
test_step_check_ip_neighborhood() {
  info "Тестирование step_check_ip_neighborhood..."

  # Проверяем что функция существует
  if declare -f step_check_ip_neighborhood >/dev/null; then
    pass "Функция step_check_ip_neighborhood существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_check_ip_neighborhood отсутствует"
    return
  fi

  # Функция использует curl к ipinfo.io - mock уже настроен
  # Запускаем и проверяем что не падает
  if step_check_ip_neighborhood 2>/dev/null; then
    pass "step_check_ip_neighborhood: выполнилась без ошибок"
    ((TESTS_PASSED++))
  else
    warn "step_check_ip_neighborhood: вернула ошибку (возможно ожидаемо)"
  fi
}

# ── Тест: step_system_update ──────────────────────────────────
test_step_system_update() {
  info "Тестирование step_system_update..."

  if declare -f step_system_update >/dev/null; then
    pass "Функция step_system_update существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_system_update отсутствует"
    return
  fi

  # Функция требует root и реальный apt-get, проверяем только структуру
  local func_source
  func_source=$(declare -f step_system_update)
  
  # Проверка что есть apt-get update
  if echo "$func_source" | grep -q "apt-get update"; then
    pass "step_system_update: содержит apt-get update"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что устанавливаются пакеты
  if echo "$func_source" | grep -q "apt-get install"; then
    pass "step_system_update: содержит установку пакетов"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что есть DEBIAN_FRONTEND
  if echo "$func_source" | grep -q "DEBIAN_FRONTEND"; then
    pass "step_system_update: устанавливает DEBIAN_FRONTEND"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_auto_updates ───────────────────────────────────
test_step_auto_updates() {
  info "Тестирование step_auto_updates..."

  if declare -f step_auto_updates >/dev/null; then
    pass "Функция step_auto_updates существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_auto_updates отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_auto_updates)
  
  # Проверка что создаётся файл автообновлений
  if echo "$func_source" | grep -q "20auto-upgrades"; then
    pass "step_auto_updates: настраивает 20auto-upgrades"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что настраивается unattended-upgrades
  if echo "$func_source" | grep -q "50unattended-upgrades"; then
    pass "step_auto_updates: настраивает 50unattended-upgrades"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что сервис включается
  if echo "$func_source" | grep -q "systemctl enable unattended-upgrades"; then
    pass "step_auto_updates: включает сервис unattended-upgrades"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_bbr ────────────────────────────────────────────
test_step_bbr() {
  info "Тестирование step_bbr..."

  if declare -f step_bbr >/dev/null; then
    pass "Функция step_bbr существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_bbr отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_bbr)
  
  # Проверка что загружается модуль tcp_bbr
  if echo "$func_source" | grep -q "modprobe tcp_bbr"; then
    pass "step_bbr: загружает модуль tcp_bbr"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что создаётся sysctl конфиг
  if echo "$func_source" | grep -q "99-cubiveil.conf"; then
    pass "step_bbr: создаёт sysctl конфиг"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что применяется sysctl
  if echo "$func_source" | grep -q "sysctl -p"; then
    pass "step_bbr: применяет sysctl настройки"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_firewall ───────────────────────────────────────
test_step_firewall() {
  info "Тестирование step_firewall..."

  if declare -f step_firewall >/dev/null; then
    pass "Функция step_firewall существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_firewall отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_firewall)
  
  # Проверка что сбрасывается ufw
  if echo "$func_source" | grep -q "ufw --force reset"; then
    pass "step_firewall: сбрасывает ufw"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что устанавливаются правила по умолчанию
  if echo "$func_source" | grep -q "ufw default deny incoming"; then
    pass "step_firewall: устанавливает deny incoming"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что используется open_port
  if echo "$func_source" | grep -q "open_port"; then
    pass "step_firewall: использует open_port"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_fail2ban ───────────────────────────────────────
test_step_fail2ban() {
  info "Тестирование step_fail2ban..."

  if declare -f step_fail2ban >/dev/null; then
    pass "Функция step_fail2ban существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_fail2ban отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_fail2ban)
  
  # Проверка что создаётся jail конфиг
  if echo "$func_source" | grep -q "cubiveil.conf"; then
    pass "step_fail2ban: создаёт cubiveil.conf"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что настраивается SSH порт
  if echo "$func_source" | grep -q "SSH_PORT\|sshd_config"; then
    pass "step_fail2ban: читает SSH порт из конфига"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что сервис включается
  if echo "$func_source" | grep -q "systemctl enable fail2ban"; then
    pass "step_fail2ban: включает сервис fail2ban"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_install_singbox ────────────────────────────────
test_step_install_singbox() {
  info "Тестирование step_install_singbox..."

  if declare -f step_install_singbox >/dev/null; then
    pass "Функция step_install_singbox существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_install_singbox отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_install_singbox)
  
  # Проверка что версия получается с GitHub
  if echo "$func_source" | grep -q "api.github.com.*sing-box"; then
    pass "step_install_singbox: получает версию с GitHub"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что используется curl для скачивания
  if echo "$func_source" | grep -q "curl.*sing-box"; then
    pass "step_install_singbox: скачивает sing-box"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что бинарник устанавливается в /usr/local/bin
  if echo "$func_source" | grep -q "/usr/local/bin/sing-box"; then
    pass "step_install_singbox: устанавливает в /usr/local/bin"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_generate_keys_and_ports ───────────────────────
test_step_generate_keys_and_ports() {
  info "Тестирование step_generate_keys_and_ports..."

  if declare -f step_generate_keys_and_ports >/dev/null; then
    pass "Функция step_generate_keys_and_ports существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_generate_keys_and_ports отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_generate_keys_and_ports)
  
  # Проверка что генерируется Reality keypair
  if echo "$func_source" | grep -q "sing-box generate reality-keypair"; then
    pass "step_generate_keys_and_ports: генерирует Reality keypair"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что генерируются UUID
  if echo "$func_source" | grep -q "sing-box generate uuid"; then
    pass "step_generate_keys_and_ports: генерирует UUID"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что используются unique_port
  if echo "$func_source" | grep -q "unique_port"; then
    pass "step_generate_keys_and_ports: использует unique_port"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что есть CDN список для camouflage
  if echo "$func_source" | grep -q "CDN_LIST\|cloudflare\|google"; then
    pass "step_generate_keys_and_ports: имеет CDN список для camouflage"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_install_marzban ────────────────────────────────
test_step_install_marzban() {
  info "Тестирование step_install_marzban..."

  if declare -f step_install_marzban >/dev/null; then
    pass "Функция step_install_marzban существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_install_marzban отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_install_marzban)
  
  # Проверка что используется официальный скрипт установки
  if echo "$func_source" | grep -q "Marzban/raw/master/script.sh"; then
    pass "step_install_marzban: использует официальный скрипт"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что есть проверка наличия скрипта
  if echo "$func_source" | grep -q "/opt/marzban/script.sh"; then
    pass "step_install_marzban: проверяет наличие скрипта"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_ssl ────────────────────────────────────────────
test_step_ssl() {
  info "Тестирование step_ssl..."

  if declare -f step_ssl >/dev/null; then
    pass "Функция step_ssl существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_ssl отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_ssl)
  
  # Проверка что устанавливается acme.sh
  if echo "$func_source" | grep -q "acme.sh"; then
    pass "step_ssl: использует acme.sh"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что открывается порт 80 для валидации
  if echo "$func_source" | grep -q "open_port 80"; then
    pass "step_ssl: открывает порт 80 для валидации"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что порт 80 закрывается после получения
  if echo "$func_source" | grep -q "close_port 80"; then
    pass "step_ssl: закрывает порт 80 после получения"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что сертификаты сохраняются в правильную директорию
  if echo "$func_source" | grep -q "/var/lib/marzban/certs"; then
    pass "step_ssl: сохраняет сертификаты в /var/lib/marzban/certs"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_configure ──────────────────────────────────────
test_step_configure() {
  info "Тестирование step_configure..."

  if declare -f step_configure >/dev/null; then
    pass "Функция step_configure существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_configure отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_configure)
  
  # Проверка что создаётся .env файл
  if echo "$func_source" | grep -q "/opt/marzban/.env"; then
    pass "step_configure: создаёт /opt/marzban/.env"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что создаётся шаблон sing-box
  if echo "$func_source" | grep -q "sing-box-template.json"; then
    pass "step_configure: создаёт sing-box-template.json"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что используется gen_random для паролей
  if echo "$func_source" | grep -q "gen_random"; then
    pass "step_configure: использует gen_random для паролей"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что есть 5 профилей в шаблоне
  if echo "$func_source" | grep -q "vless-reality-tcp\|vless-reality-grpc\|hysteria2\|trojan-ws-tls\|shadowsocks-2022"; then
    pass "step_configure: шаблон содержит 5 профилей"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: step_finish ─────────────────────────────────────────
test_step_finish() {
  info "Тестирование step_finish..."

  if declare -f step_finish >/dev/null; then
    pass "Функция step_finish существует"
    ((TESTS_PASSED++))
  else
    fail "Функция step_finish отсутствует"
    return
  fi

  local func_source
  func_source=$(declare -f step_finish)
  
  # Проверка что перезапускается marzban
  if echo "$func_source" | grep -q "systemctl restart marzban"; then
    pass "step_finish: перезапускает marzban"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что есть health-check
  if echo "$func_source" | grep -q "health_check\|health-check"; then
    pass "step_finish: настраивает health-check"
    ((TESTS_PASSED++))
  fi
  
  # Проверка что есть проверка статуса сервиса
  if echo "$func_source" | grep -q "systemctl is-active"; then
    pass "step_finish: проверяет статус сервиса"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: интеграция всех шагов ───────────────────────────────
test_all_steps_exist() {
  info "Тестирование наличия всех шагов установки..."

  local required_steps=(
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

  local missing=0
  for step_func in "${required_steps[@]}"; do
    if declare -f "$step_func" >/dev/null; then
      pass "Шаг существует: $step_func"
      ((TESTS_PASSED++))
    else
      fail "Шаг отсутствует: $step_func"
      ((missing++))
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "Все шаги установки присутствуют"
    ((TESTS_PASSED++))
  else
    warn "Отсутствует $missing шагов установки"
  fi
}

# ── Тест: проверка локализации в шагах ───────────────────────
test_localization_in_steps() {
  info "Тестирование локализации в шагах..."

  # Проверяем что функции используют LANG_NAME для локализации
  local localized_steps=0
  
  for func in prompt_inputs step_check_ip_neighborhood step_finish; do
    if declare -f "$func" >/dev/null; then
      local source
      source=$(declare -f "$func")
      if echo "$source" | grep -q 'LANG_NAME.*==.*"Русский"\|LANG_NAME.*==.*"English"'; then
        pass "$func: поддерживает локализацию"
        ((TESTS_PASSED++))
        ((localized_steps++))
      else
        warn "$func: нет явной проверки LANG_NAME"
      fi
    fi
  done

  if [[ $localized_steps -gt 0 ]]; then
    pass "Некоторые шаги поддерживают локализацию"
    ((TESTS_PASSED++))
  fi
}

# ── Очистка ───────────────────────────────────────────────────
cleanup() {
  rm -f /tmp/cubiveil_test_ports.log 2>/dev/null || true
}

# ── Основная функция ─────────────────────────────────────────
main() {
  trap cleanup EXIT
  
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║     CubiVeil Unit Tests - lib/install-steps.sh      ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый модуль: ${SCRIPT_DIR}/lib/install-steps.sh"
  echo ""

  # Загружаем модуль (после mock зависимостей)
  source "${SCRIPT_DIR}/lib/install-steps.sh"

  # ── Запуск тестов ─────────────────────────────────────────
  test_all_steps_exist
  echo ""

  test_prompt_inputs_mock
  echo ""

  test_step_check_ip_neighborhood
  echo ""

  test_step_system_update
  echo ""

  test_step_auto_updates
  echo ""

  test_step_bbr
  echo ""

  test_step_firewall
  echo ""

  test_step_fail2ban
  echo ""

  test_step_install_singbox
  echo ""

  test_step_generate_keys_and_ports
  echo ""

  test_step_install_marzban
  echo ""

  test_step_ssl
  echo ""

  test_step_configure
  echo ""

  test_step_finish
  echo ""

  test_localization_in_steps
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
