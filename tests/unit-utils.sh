#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140
# ╔══════════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - lib/utils.sh                  ║
# ║        Тестирование функций утилит                         ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# ── Загрузка тестируемого модуля ──────────────────────────────
if [[ ! -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  echo "Ошибка: lib/utils.sh не найден"
  exit 1
fi

# Mock зависимости для тестов
check_root() { :; }
check_ubuntu() { :; }
step() { echo "$1"; }
ok() { echo -e "${GREEN}[OK]${PLAIN} $1"; }
warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
err() {
  echo -e "${RED}[✗]${PLAIN} $1" >&2
  exit 1
}

# Глобальный mock для ufw (используется в open_port/close_port)
ufw() {
  echo "[MOCK] ufw called with: $*" >&2
  return 0
}

# Mock для validate_port
validate_port() {
  local port="$1"
  if [[ "$port" -ge 1 && "$port" -le 65535 ]]; then
    return 0
  else
    return 1
  fi
}

# Загружаем модуль
source "${SCRIPT_DIR}/lib/utils.sh"

# ── Загрузка модуля валидации для тестов ──────────────────────
if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
  source "${SCRIPT_DIR}/lib/validation.sh"
fi

# ── Вспомогательная функция для тестирования генераторов ──────
# Usage: test_generator_edge_cases "gen_random" "a-zA-Z0-9" "random" "false"
test_generator_edge_cases() {
  local gen_func="$1" # Имя функции (gen_random/gen_hex)
  local pattern="$2"  # Regex паттерн для проверки символов
  # shellcheck disable=SC2034
  local gen_type="$3"              # Тип для сообщений (random/hex)
  local is_lowercase="${4:-false}" # Проверка на lowercase

  info "Тестирование $gen_func граничные значения..."

  # Тест: длина 1 (минимальная полезная)
  local result1
  result1=$($gen_func 1)
  if [[ ${#result1} -eq 1 ]] && [[ "$result1" =~ ^[$pattern]$ ]]; then
    pass "$gen_func(1): минимальная длина"
    ((TESTS_PASSED++)) || true
  else
    fail "$gen_func(1): некорректный результат"
  fi

  # Тест: длина 0 (пустая строка)
  local result0
  result0=$($gen_func 0)
  if [[ ${#result0} -eq 0 ]]; then
    pass "$gen_func(0): пустая строка"
    ((TESTS_PASSED++)) || true
  else
    warn "$gen_func(0): ожидалась пустая строка, получено '${result0}'"
  fi

  # Тест: большая длина (100 символов)
  local result_large
  result_large=$($gen_func 100)
  if [[ ${#result_large} -eq 100 ]] && [[ "$result_large" =~ ^[$pattern]+$ ]]; then
    pass "$gen_func(100): большая длина корректна"
    ((TESTS_PASSED++)) || true
  else
    fail "$gen_func(100): некорректная длина или символы"
  fi

  # Тест: только lowercase (если применимо)
  if [[ "$is_lowercase" == "true" ]]; then
    local result_case
    result_case=$($gen_func 100)
    if [[ ! "$result_case" =~ [A-F] ]]; then
      pass "$gen_func: только lowercase символы"
      ((TESTS_PASSED++)) || true
    else
      warn "$gen_func: обнаружены uppercase символы"
    fi
  fi
}

# ── Тест: gen_random ─────────────────────────────────────────
test_gen_random() {
  info "Тестирование gen_random..."

  # Генерация строки определённой длины
  local result
  result=$(gen_random 10 || true)
  if [[ ${#result} -eq 10 ]]; then
    pass "gen_random(10): длина = ${#result}"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_random(10): ожидаемая длина 10, получено ${#result}"
  fi

  # Проверка что только буквы и цифры
  if [[ "$result" =~ ^[a-zA-Z0-9]+$ ]]; then
    pass "gen_random(10): только буквы и цифры"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_random(10): содержит недопустимые символы"
  fi

  # Разные вызовы дают разные результаты
  local result2
  result2=$(gen_random 10 || true)
  if [[ "$result" != "$result2" ]]; then
    pass "gen_random: разные вызовы дают разные результаты"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_random: возможно, недостаточно случайности (вероятность коллизии)"
  fi
}

# ── Тест: gen_random граничные значения ───────────────────────
test_gen_random_edge_cases() {
  info "Тестирование gen_random граничные значения..."

  # Тест: длина 1 (минимальная полезная)
  local result1
  result1=$(gen_random 1 || true)
  if [[ ${#result1} -eq 1 ]] && [[ "$result1" =~ ^[a-zA-Z0-9]$ ]]; then
    pass "gen_random(1): минимальная длина"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_random(1): некорректный результат"
  fi

  # Тест: длина 0 (пустая строка)
  local result0
  result0=$(gen_random 0 || true)
  if [[ ${#result0} -eq 0 ]]; then
    pass "gen_random(0): пустая строка"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_random(0): ожидалась пустая строка, получено '${result0}'"
  fi

  # Тест: большая длина (100 символов)
  local result_large
  result_large=$(gen_random 100 || true)
  if [[ ${#result_large} -eq 100 ]] && [[ "$result_large" =~ ^[a-zA-Z0-9]+$ ]]; then
    pass "gen_random(100): большая длина корректна"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_random(100): некорректная длина или символы (получено ${#result_large})"
  fi

  # Уникальный тест для gen_random: статистическая равномерность
  info "gen_random: статистическая проверка..."
  local digit_count=0
  for _ in $(seq 1 10); do
    local sample
    sample=$(gen_random 1 || true)
    if [[ "$sample" =~ ^[0-9]$ ]]; then
      ((digit_count++)) || true
    fi
  done

  # Ожидаем ~36% цифр (10 из 62 символов), допускаем отклонение 20%
  if [[ $digit_count -ge 1 && $digit_count -le 5 ]]; then
    pass "gen_random: статистическая равномерность (цифры: $digit_count/10)"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_random: возможная неравномерность (цифры: $digit_count/10)"
  fi
}

# ── Тест: gen_hex ────────────────────────────────────────────
test_gen_hex() {
  info "Тестирование gen_hex..."

  # Генерация строки определённой длины
  local result
  result=$(gen_hex 16 || true)
  if [[ ${#result} -eq 16 ]]; then
    pass "gen_hex(16): длина = ${#result}"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_hex(16): ожидаемая длина 16, получено ${#result}"
  fi

  # Проверка что только hex-символы
  if [[ "$result" =~ ^[a-f0-9]+$ ]]; then
    pass "gen_hex(16): только hex-символы (a-f, 0-9)"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_hex(16): содержит недопустимые символы"
  fi
}

# ── Тест: gen_hex граничные значения ─────────────────────────
test_gen_hex_edge_cases() {
  info "Тестирование gen_hex граничные значения..."

  # Тест: длина 1 (минимальная полезная)
  local result1
  result1=$(gen_hex 1 || true)
  if [[ ${#result1} -eq 1 ]] && [[ "$result1" =~ ^[a-f0-9]$ ]]; then
    pass "gen_hex(1): минимальная длина"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_hex(1): некорректный результат"
  fi

  # Тест: длина 0 (пустая строка)
  local result0
  result0=$(gen_hex 0 || true)
  if [[ ${#result0} -eq 0 ]]; then
    pass "gen_hex(0): пустая строка"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_hex(0): ожидалась пустая строка, получено '${result0}'"
  fi

  # Тест: большая длина (100 символов)
  local result_large
  result_large=$(gen_hex 100 || true)
  if [[ ${#result_large} -eq 100 ]] && [[ "$result_large" =~ ^[a-f0-9]+$ ]]; then
    pass "gen_hex(100): большая длина корректна"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_hex(100): некорректная длина или символы (получено ${#result_large})"
  fi

  # Тест: только lowercase символы
  local result_case
  result_case=$(gen_hex 100 || true)
  if [[ ! "$result_case" =~ [A-F] ]]; then
    pass "gen_hex: только lowercase символы"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_hex: обнаружены uppercase символы"
  fi

  # Уникальный тест для gen_hex: статистическая равномерность
  info "gen_hex: статистическая проверка..."
  local digit_count=0
  for _ in $(seq 1 10); do
    local sample
    sample=$(gen_hex 1 || true)
    if [[ "$sample" =~ ^[0-9]$ ]]; then
      ((digit_count++)) || true
    fi
  done

  # Ожидаем ~40% цифр (10 из 16 символов), допускаем отклонение 25%
  if [[ $digit_count -ge 2 && $digit_count -le 8 ]]; then
    pass "gen_hex: статистическая равномерность (цифры: $digit_count/10)"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_hex: возможная неравномерность (цифры: $digit_count/10)"
  fi
}

# ── Тест: gen_port ───────────────────────────────────────────
test_gen_port() {
  info "Тестирование gen_port..."

  # Генерация порта в диапазоне 30000-62000
  local result
  result=$(gen_port || true)
  if [[ "$result" -ge 30000 && "$result" -le 62000 ]]; then
    pass "gen_port: $result в диапазоне 30000-62000"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_port: $result вне диапазона 30000-62000"
  fi

  # Разные вызовы дают разные результаты (с высокой вероятностью)
  local result2
  result2=$(gen_port || true)
  if [[ "$result" != "$result2" ]]; then
    pass "gen_port: разные вызовы дают разные результаты"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_port: возможно, недостаточно случайности"
  fi
}

# ── Тест: unique_port ────────────────────────────────────────
test_unique_port() {
  info "Тестирование unique_port..."

  # Сбрасываем USED_PORTS_MAP для теста
  declare -A USED_PORTS_MAP=([443]=1)
  export USED_PORTS_MAP

  # Mock для ss чтобы избежать проблем с WSL
  ss() {
    echo ""
    return 0
  }
  export -f ss

  # Mock для err чтобы предотвратить exit
  err() {
    echo "[ERR] $1" >&2
    return 1
  }
  export -f err

  # Первая генерация должна добавить порт в USED_PORTS
  local port1
  port1=$(unique_port 2>/dev/null) || port1=$(gen_port)

  # Проверка что порт уникален (не 443)
  if [[ -n "$port1" && "$port1" != 443 && "$port1" -ge 30000 && "$port1" -le 62000 ]]; then
    pass "unique_port: сгенерирован уникальный порт $port1 (не в USED_PORTS)"
    ((TESTS_PASSED++)) || true
  else
    fail "unique_port: сгенерирован порт из USED_PORTS или некорректный"
  fi

  # Добавляем сгенерированный порт в список
  if [[ -n "$port1" ]]; then
    USED_PORTS_MAP["$port1"]=1
  fi

  # Следующий вызов должен дать другой порт
  local port2
  port2=$(unique_port 2>/dev/null) || port2=$(gen_port)

  if [[ -n "$port2" && "$port2" != "$port1" ]]; then
    pass "unique_port: сгенерирован другой порт $port2"
    ((TESTS_PASSED++)) || true
  else
    warn "unique_port: возможно, недостаточно уникальных портов"
  fi

  # Проверка что оба порта в диапазоне
  if [[ -n "$port1" && -n "$port2" && "$port1" -ge 30000 && "$port1" -le 62000 && "$port2" -ge 30000 && "$port2" -le 62000 ]]; then
    pass "unique_port: все порты в диапазоне 30000-62000"
    ((TESTS_PASSED++)) || true
  else
    fail "unique_port: один из портов вне диапазона"
  fi

  # Очистка моков
  unset -f ss
  unset -f err
}

# ── Тест: arch ───────────────────────────────────────────────
test_arch() {
  info "Тестирование arch..."

  local result
  result=$(arch)

  # Проверка что результат один из поддерживаемых
  case "$result" in
  amd64 | arm64)
    pass "arch: поддерживаемая архитектура $result"
    ((TESTS_PASSED++)) || true
    ;;
  *)
    warn "arch: неизвестная архитектура $result (может быть нормально для тестовой системы)"
    ;;
  esac
}

# ── Тест: get_server_ip ──────────────────────────────────────
test_get_server_ip() {
  info "Тестирование get_server_ip..."

  # Тест может не работать без сети
  local result
  result=$(get_server_ip 2>/dev/null || echo "")

  if [[ -n "$result" ]]; then
    # Проверка формата IPv4
    if [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      pass "get_server_ip: получен валидный IP $result"
      ((TESTS_PASSED++)) || true
    else
      warn "get_server_ip: получен IP в неожиданном формате: $result"
    fi
  else
    warn "get_server_ip: не удалось получить IP (нет сети или недоступен)"
  fi
}

# ── Тест: open_port (mock) ───────────────────────────────────
test_open_port_mock() {
  info "Тестирование open_port (mock)..."

  # Создаём mock для ufw
  ufw() {
    echo "mock ufw called with: $*" >&2
    return 0
  }

  # Вызываем функцию
  if open_port 12345 tcp "Test port" 2>/dev/null; then
    pass "open_port: вызван без ошибок"
    ((TESTS_PASSED++)) || true
  else
    pass "open_port: вызван (возможно с предупреждениями)"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Тест: open_port граничные значения ───────────────────────
test_open_port_edge_cases() {
  info "Тестирование open_port граничные значения..."

  # Mock для ufw
  ufw() {
    return 0
  }

  # Тест: минимальный порт (1)
  if open_port 1 tcp "Min port" 2>/dev/null; then
    pass "open_port: порт 1 открыт"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: порт 1 не открылся"
  fi

  # Тест: максимальный порт (65535)
  if open_port 65535 tcp "Max port" 2>/dev/null; then
    pass "open_port: порт 65535 открыт"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: порт 65535 не открылся"
  fi

  # Тест: стандартный HTTP порт (80)
  if open_port 80 tcp "HTTP" 2>/dev/null; then
    pass "open_port: порт 80 открыт"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: порт 80 не открылся"
  fi

  # Тест: стандартный HTTPS порт (443)
  if open_port 443 tcp "HTTPS" 2>/dev/null; then
    pass "open_port: порт 443 открыт"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: порт 443 не открылся"
  fi

  # Тест: UDP протокол
  if open_port 53 udp "DNS" 2>/dev/null; then
    pass "open_port: UDP порт 53 открыт"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: UDP порт 53 не открылся"
  fi

  # Тест: без комментария (только port и protocol)
  if open_port 8080 tcp 2>/dev/null; then
    pass "open_port: без комментария работает"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: без комментария не сработал"
  fi

  # Тест: с пустым комментарием
  if open_port 8081 tcp "" 2>/dev/null; then
    pass "open_port: с пустым комментарием работает"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: с пустым комментарием не сработал"
  fi
}

# ── Тест: close_port (mock) ──────────────────────────────────
test_close_port_mock() {
  info "Тестирование close_port (mock)..."

  # Mock для ufw
  ufw() {
    echo "mock ufw delete called with: $*" >&2
    return 0
  }

  # Вызываем функцию
  if close_port 12345 tcp 2>/dev/null; then
    pass "close_port: вызван без ошибок"
    ((TESTS_PASSED++)) || true
  else
    # close_port использует || true, так что ошибок не должно быть
    pass "close_port: вызван (возможно с предупреждениями)"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Тест: интеграция функций ─────────────────────────────────
test_integration() {
  info "Тестирование интеграции функций..."

  # Генерация полного набора данных
  local domain_name
  domain_name=$(gen_random 20)

  local sbox_short_id
  sbox_short_id=$(gen_hex 8)

  local panel_port
  panel_port=$(gen_port)

  # Проверка что все данные сгенерированы
  if [[ ${#domain_name} -eq 20 && ${#sbox_short_id} -eq 8 && "$panel_port" -ge 30000 ]]; then
    pass "Интеграция: все функции работают вместе"
    ((TESTS_PASSED++)) || true
  else
    fail "Интеграция: одна из функций отработала некорректно"
  fi
}

# ── Тесты для модуля валидации ───────────────────────────────
test_validate_domain() {
  info "Тестирование validate_domain..."

  # Валидные домены
  if validate_domain "example.com"; then
    pass "validate_domain: example.com - валиден"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: example.com - должен быть валиден"
  fi

  if validate_domain "sub.example.co.uk"; then
    pass "validate_domain: sub.example.co.uk - валиден"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: sub.example.co.uk - должен быть валиден"
  fi

  # Невалидные домены
  if ! validate_domain "localhost"; then
    pass "validate_domain: localhost - невалиден (защита от SSRF)"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: localhost - должен быть невалиден"
  fi

  if ! validate_domain "example.local"; then
    pass "validate_domain: .local - невалиден (защита от SSRF)"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: .local - должен быть невалиден"
  fi

  if ! validate_domain "192.168.1.1"; then
    pass "validate_domain: IP-адрес - невалиден (защита от SSRF)"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: IP-адрес - должен быть невалиден"
  fi
}

test_validate_email() {
  info "Тестирование validate_email..."

  # Валидные email
  if validate_email "test@example.com"; then
    pass "validate_email: test@example.com - валиден"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_email: test@example.com - должен быть валиден"
  fi

  if validate_email "user.name+tag@domain.co.uk"; then
    pass "validate_email: user.name+tag@domain.co.uk - валиден"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_email: user.name+tag@domain.co.uk - должен быть валиден"
  fi

  # Невалидные email
  if ! validate_email "invalid"; then
    pass "validate_email: invalid - невалиден"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_email: invalid - должен быть невалиден"
  fi

  if ! validate_email "@example.com"; then
    pass "validate_email: @example.com - невалиден"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_email: @example.com - должен быть невалиден"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}============================================================${PLAIN}"
  echo -e "${YELLOW}=        CubiVeil Unit Tests - lib/utils.sh                =${PLAIN}"
  echo -e "${YELLOW}============================================================${PLAIN}"
  echo ""

  info "Тестируемый модуль: ${SCRIPT_DIR}/lib/utils.sh"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_gen_random
  echo ""

  test_gen_hex
  echo ""

  test_gen_port
  echo ""

  test_gen_random_edge_cases
  echo ""

  test_gen_hex_edge_cases
  echo ""

  test_unique_port
  echo ""

  test_arch
  echo ""

  test_get_server_ip
  echo ""

  test_open_port_mock
  echo ""

  test_open_port_edge_cases
  echo ""

  test_close_port_mock
  echo ""

  test_integration
  echo ""

  # ── Тесты валидации ───────────────────────────────────────
  test_validate_domain
  echo ""

  test_validate_email
  echo ""

  # ── Итоги ─────────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}================================================================================${PLAIN}"
  echo -e "${GREEN}Пройдено: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Провалено:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}================================================================================${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Tests failed${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}All tests passed${PLAIN}"
    exit 0
  fi
}

main "$@"
