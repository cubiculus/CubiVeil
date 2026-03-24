#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Integration Tests                        ║
# ║        Проверка корректности установки                   ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# shellcheck disable=SC2317
# ── Подключение тестовых утилит ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# ── Проверка: сервис активен ─────────────────────────────────
check_service_active() {
  local service="$1"
  local expected="${2:-active}"

  if systemctl is-active "$service" 2>/dev/null | grep -q "^${expected}$"; then
    pass "Сервис $service: $(systemctl is-active $service)"
    ((TESTS_PASSED++))
  else
    local status
    status=$(systemctl is-active "$service" 2>/dev/null || echo "not-found")
    fail "Сервис $service: $status (ожидался: $expected)"
    ((TESTS_FAILED++))
    [[ "${FORCE_EXIT:-}" == "true" ]] && exit 1
  fi
}

# ── Проверка: порт открыт ────────────────────────────────────
check_port_open() {
  local port="$1"
  local proto="${2:-tcp}"
  local name="${3:-port $port}"

  if ss -tlnp 2>/dev/null | grep -q ":${port} " ||
    ss -ulnp 2>/dev/null | grep -q ":${port} "; then
    pass "Порт открыт: $name ($port/$proto)"
    ((TESTS_PASSED++))
  else
    fail "Порт закрыт: $name ($port/$proto)"
    ((TESTS_FAILED++))
  fi
}

# ── Проверка: файл существует ────────────────────────────────
check_file_exists() {
  local file="$1"
  local description="${2:-$file}"

  if [[ -f "$file" ]]; then
    pass "Файл существует: $description"
    ((TESTS_PASSED++))
  else
    fail "Файл отсутствует: $description ($file)"
    ((TESTS_FAILED++))
  fi
}

# ── Проверка: файл зашифрован ────────────────────────────────
check_file_encrypted() {
  local file="$1"
  local description="${2:-$file}"

  if [[ -f "$file" ]] && file "$file" | grep -q "age encrypted"; then
    pass "Файл зашифрован: $description"
    ((TESTS_PASSED++))
  elif [[ -f "$file" ]]; then
    fail "Файл НЕ зашифрован: $description"
    ((TESTS_FAILED++))
  else
    fail "Файл отсутствует: $description"
    ((TESTS_FAILED++))
  fi
}

# ── Проверка: директория существует ──────────────────────────
check_dir_exists() {
  local dir="$1"
  local description="${2:-$dir}"

  if [[ -d "$dir" ]]; then
    pass "Директория существует: $description"
    ((TESTS_PASSED++))
  else
    fail "Директория отсутствует: $description ($dir)"
    ((TESTS_FAILED++))
  fi
}

# ── Проверка: health-check работает ──────────────────────────
check_health_endpoint() {
  local host="${1:-localhost}"
  local port="$2"
  local endpoint="${3:-/health}"
  local timeout="${4:-5}"

  local http_code

  if command -v curl &>/dev/null; then
    http_code=$(curl -sf -o /dev/null -w "%{http_code}" \
      --max-time "$timeout" \
      "http://${host}:${port}${endpoint}" 2>/dev/null || echo "000")

    if [[ "$http_code" == "200" ]]; then
      pass "Health-check отвечает: http://${host}:${port}${endpoint} ($http_code)"
      ((TESTS_PASSED++))
    else
      fail "Health-check не отвечает: http://${host}:${port}${endpoint} ($http_code)"
      ((TESTS_FAILED++))
    fi
  else
    warn "curl не установлен — пропускаю проверку health-check"
  fi
}

# ── Проверка: SSL сертификат ─────────────────────────────────
check_ssl_cert() {
  local cert_path="$1"

  if [[ -f "$cert_path" ]]; then
    # Проверка что сертификат валидный
    if openssl x509 -in "$cert_path" -noout -checkend 0 2>/dev/null; then
      pass "SSL сертификат валиден: $cert_path"
      ((TESTS_PASSED++))
    else
      fail "SSL сертификат истёк или невалиден: $cert_path"
      ((TESTS_FAILED++))
    fi
  else
    fail "SSL сертификат не найден: $cert_path"
    ((TESTS_FAILED++))
  fi
}

# ── Проверка: конфиг Marzban ─────────────────────────────────
check_marzban_config() {
  local env_file="/opt/marzban/.env"

  if [[ -f "$env_file" ]]; then
    # Проверка ключевых переменных
    local required_vars=(
      "SECRET_KEY"
      "SUDO_USERNAME"
      "SUDO_PASSWORD"
      "UVICORN_PORT"
      "SING_BOX_ENABLED"
    )

    local missing=0
    for var in "${required_vars[@]}"; do
      if ! grep -q "^${var}=" "$env_file"; then
        warn "В .env отсутствует: $var"
        ((missing++))
      fi
    done

    if [[ $missing -eq 0 ]]; then
      pass "Конфигурация Marzban: все переменные на месте"
      ((TESTS_PASSED++))
    else
      fail "Конфигурация Marzban: отсутствует $missing переменных"
      ((TESTS_FAILED++))
    fi
  else
    fail "Конфигурация Marzban не найдена: $env_file"
    ((TESTS_FAILED++))
  fi
}

# ── Проверка: шаблон Sing-box ────────────────────────────────
check_singbox_template() {
  local template="/var/lib/marzban/sing-box-template.json"

  if [[ -f "$template" ]]; then
    # Проверка JSON синтаксиса
    if command -v jq &>/dev/null; then
      if jq empty "$template" 2>/dev/null; then
        pass "Sing-box шаблон: валидный JSON"
        ((TESTS_PASSED++))

        # Проверка наличия 5 профилей
        local profiles
        profiles=$(jq '.inbounds | length' "$template" 2>/dev/null || echo "0")
        if [[ "$profiles" -ge 5 ]]; then
          pass "Sing-box шаблон: $profiles профилей"
          ((TESTS_PASSED++))
        else
          fail "Sing-box шаблон: только $profiles профилей (ожидалось 5)"
          ((TESTS_FAILED++))
        fi
      else
        fail "Sing-box шаблон: невалидный JSON"
        ((TESTS_FAILED++))
      fi
    else
      warn "jq не установлен — пропускаю проверку JSON"
    fi
  else
    fail "Sing-box шаблон не найден: $template"
    ((TESTS_FAILED++))
  fi
}

# ── Проверка: Fail2ban ───────────────────────────────────────
check_fail2ban() {
  if systemctl is-active fail2ban 2>/dev/null | grep -q "^active$"; then
    pass "Fail2ban активен"
    ((TESTS_PASSED++))

    # Проверка что jail создан
    if [[ -f /etc/fail2ban/jail.d/cubiveil.conf ]]; then
      pass "Fail2ban: CubiVeil jail настроен"
      ((TESTS_PASSED++))
    else
      fail "Fail2ban: CubiVeil jail не найден"
      ((TESTS_FAILED++))
    fi
  else
    warn "Fail2ban не активен"
  fi
}

# ── Проверка: UFW ────────────────────────────────────────────
check_ufw() {
  if command -v ufw &>/dev/null; then
    if ufw status 2>/dev/null | grep -q "Status: active"; then
      pass "UFW активен"
      ((TESTS_PASSED++))

      # Проверка что порты 443 открыты
      if ufw status 2>/dev/null | grep -q "443"; then
        pass "UFW: порт 443 открыт"
        ((TESTS_PASSED++))
      else
        fail "UFW: порт 443 не найден в правилах"
        ((TESTS_FAILED++))
      fi
    else
      warn "UFW не активен"
    fi
  fi
}

# ── Проверка: ротация логов ──────────────────────────────────
check_log_rotation() {
  # Проверка journald конфига
  if [[ -f /etc/systemd/journald.d/cubiveil-limit.conf ]]; then
    pass "Ротация логов: journald конфиг создан"
    ((TESTS_PASSED++))
  else
    warn "Ротация логов: journald конфиг не найден"
  fi

  # Проверка logrotate конфига
  if [[ -f /etc/logrotate.d/cubiveil-services ]]; then
    pass "Ротация логов: logrotate конфиг создан"
    ((TESTS_PASSED++))
  else
    warn "Ротация логов: logrotate конфиг не найден"
  fi
}

# ── Проверка: Telegram бот (опционально) ─────────────────────
check_telegram_bot() {
  # Проверка что файл бота существует
  if [[ -f /opt/cubiveil-bot/bot.py ]]; then
    pass "Telegram бот: файл существует"
    ((TESTS_PASSED++))

    # Проверка что сервис существует
    if [[ -f /etc/systemd/system/cubiveil-bot.service ]]; then
      pass "Telegram бот: systemd сервис создан"
      ((TESTS_PASSED++))
    else
      warn "Telegram бот: systemd сервис не найден"
    fi

    # Проверка что токен НЕ в файле (берётся из Environment)
    if grep -q 'os.environ.get("TG_TOKEN")' /opt/cubiveil-bot/bot.py; then
      pass "Telegram бот: токен в переменной окружения (безопасно)"
      ((TESTS_PASSED++))
    else
      warn "Telegram бот: токен не в переменной окружения!"
    fi
  else
    info "Telegram бот: не установлен (опционально)"
  fi
}

# ── Проверка: зашифрованные credentials ──────────────────────
check_encrypted_credentials() {
  # Проверка что файл зашифрован
  check_file_encrypted "/root/cubiveil-credentials.age" "Учётные данные (age)"

  # Проверка что ключ существует
  check_file_exists "/root/.cubiveil-age-key.txt" "Ключ age"

  # Проверка что инструкция существует
  check_file_exists "/root/DECRYPT_INSTRUCTIONS.txt" "Инструкция по расшифровке"

  # Проверка что незашифрованный файл УДАЛЁН
  if [[ ! -f /root/cubiveil-credentials.txt ]]; then
    pass "Безопасность: незашифрованный файл удалён"
    ((TESTS_PASSED++))
  else
    fail "Безопасность: незашифрованный файл существует!"
    ((TESTS_FAILED++))
  fi
}

# ── Проверка: health-check сервис ────────────────────────────
check_health_service() {
  check_service_active "marzban-health" "active"

  # Проверка что файл health-check существует
  check_file_exists "/opt/marzban/health_check.py" "Health-check скрипт"
}

# ── Проверка: модульная структура ────────────────────────────
check_modular_structure() {
  local base_dir="${1:-.}"

  # Проверка наличия lib директории
  check_dir_exists "${base_dir}/lib" "lib директория"

  # Проверка наличия модулей
  check_file_exists "${base_dir}/lib/utils.sh" "lib/utils.sh"
  check_file_exists "${base_dir}/lib/install-steps.sh" "lib/install-steps.sh"

  # Проверка наличия setup-telegram.sh
  check_file_exists "${base_dir}/setup-telegram.sh" "setup-telegram.sh"

  # Проверка что основной install.sh существует
  check_file_exists "${base_dir}/install.sh" "install.sh"
}

# ── Проверка: загрузка модулей ───────────────────────────────
check_module_loading() {
  local base_dir="${1:-.}"

  # Проверка что модули могут быть загружены
  if bash -c "source ${base_dir}/lib/utils.sh 2>&1"; then
    pass "Модуль lib/utils.sh загружается корректно"
    ((TESTS_PASSED++))
  else
    fail "Модуль lib/utils.sh не загружается"
    ((TESTS_FAILED++))
  fi

  if bash -c "source ${base_dir}/lib/lang.sh 2>&1" 2>/dev/null; then
    pass "Модуль lib/lang.sh загружается корректно"
    ((TESTS_PASSED++))
  else
    warn "Модуль lib/lang.sh не найден или не загружается"
  fi
}

# ── Проверка: синтаксис скриптов ─────────────────────────────
check_script_syntax() {
  local base_dir="${1:-.}"
  local scripts=(
    "install.sh"
    "setup-telegram.sh"
    "lib/utils.sh"
    "lib/install-steps.sh"
  )

  for script in "${scripts[@]}"; do
    if bash -n "${base_dir}/${script}" 2>/dev/null; then
      pass "Синтаксис OK: $script"
      ((TESTS_PASSED++))
    else
      fail "Синтаксическая ошибка: $script"
      ((TESTS_FAILED++))
    fi
  done
}

# ── Проверка: Uptime ─────────────────────────────────────────
check_uptime() {
  local uptime
  uptime=$(cat /proc/uptime | awk '{print int($1)}')

  if [[ $uptime -gt 0 ]]; then
    pass "Сервер работает: $((uptime / 60)) мин"
    ((TESTS_PASSED++))
  fi
}

# ── Проверка: свободное место на диске ───────────────────────
check_disk_space() {
  local available
  available=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')

  if [[ $available -gt 1 ]]; then
    pass "Диск: свободно ${available}ГБ"
    ((TESTS_PASSED++))
  else
    warn "Диск: мало места (${available}ГБ)"
  fi
}

# ── Проверка: использование RAM ──────────────────────────────
check_ram_usage() {
  local available
  available=$(free -m | awk '/^Mem:/ {print $7}')
  local total
  total=$(free -m | awk '/^Mem:/ {print $2}')
  local pct
  pct=$(((total - available) * 100 / total))

  if [[ $pct -lt 90 ]]; then
    pass "RAM: использовано ${pct}%"
    ((TESTS_PASSED++))
  else
    warn "RAM: высокое использование ${pct}%"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  local base_dir="${1:-.}"
  local mode="${2:-full}"

  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Integration Tests                    ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  # Режим unit-тестов (проверка структуры без root)
  if [[ "$mode" == "unit" ]]; then
    info "Режим unit-тестов: проверка модульной структуры"
    echo ""
    echo -e "${YELLOW}━━━ Модульная структура ━━━${PLAIN}"
    check_modular_structure "$base_dir"
    echo ""
    echo -e "${YELLOW}━━━ Загрузка модулей ━━━${PLAIN}"
    check_module_loading "$base_dir"
    echo ""
    echo -e "${YELLOW}━━━ Синтаксис скриптов ━━━${PLAIN}"
    check_script_syntax "$base_dir"
    echo ""

    # ── Итоги ───────────────────────────────────────────
    print_test_summary
    exit $?
  fi

  # Режим интеграционных тестов (требует root)
  # Проверка что запущено от root
  if [[ $EUID -ne 0 ]]; then
    fail "Требуются права root. Для unit-тестов используйте: $0 . unit"
  fi

  info "Запуск тестов..."
  echo ""

  # ── Базовые проверки ─────────────────────────────────────
  echo -e "${YELLOW}━━━ Базовые проверки ━━━${PLAIN}"
  check_uptime
  check_disk_space
  check_ram_usage
  echo ""

  # ── Сервисы ─────────────────────────────────────────────
  echo -e "${YELLOW}━━━ Сервисы ━━━${PLAIN}"
  check_service_active "marzban" "active"
  check_service_active "sing-box" "active"
  check_health_service
  check_telegram_bot
  echo ""

  # ── Сеть ────────────────────────────────────────────────
  echo -e "${YELLOW}━━━ Сеть ━━━${PLAIN}"
  check_port_open 443 tcp "VLESS Reality TCP"
  check_port_open 443 udp "Hysteria2 UDP"
  # Health-check порт нужно получить из конфига
  if [[ -f /opt/marzban/.env ]]; then
    local hc_port
    hc_port=$(grep "HEALTH_CHECK_PORT" /opt/marzban/.env 2>/dev/null | cut -d= -f2 | tr -d ' "')
    if [[ -n "$hc_port" ]]; then
      check_port_open "$hc_port" tcp "Health Check"
      check_health_endpoint "localhost" "$hc_port" "/health"
      check_health_endpoint "localhost" "$hc_port" "/ready"
    fi
  fi
  echo ""

  # ── Безопасность ────────────────────────────────────────
  echo -e "${YELLOW}━━━ Безопасность ━━━${PLAIN}"
  check_ufw
  check_fail2ban
  check_encrypted_credentials
  echo ""

  # ── SSL и сертификаты ───────────────────────────────────
  echo -e "${YELLOW}━━━ SSL ━━━${PLAIN}"
  check_ssl_cert "/var/lib/marzban/certs/cert.pem"
  echo ""

  # ── Конфигурация ────────────────────────────────────────
  echo -e "${YELLOW}━━━ Конфигурация ━━━${PLAIN}"
  check_marzban_config
  check_singbox_template
  echo ""

  # ── Логирование ─────────────────────────────────────────
  echo -e "${YELLOW}━━━ Логирование ━━━${PLAIN}"
  check_log_rotation
  echo ""

  # ── Итоги ───────────────────────────────────────────────
  print_test_summary
  exit $?
}

main "$@"
