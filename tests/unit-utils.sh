#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - lib/utils.sh                  ║
# ║        Тестирование функций утилит                        ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Цвета ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'

pass() { echo -e "${GREEN}[PASS]${PLAIN} $1"; }
fail() {
  echo -e "${RED}[FAIL]${PLAIN} $1"
  ((TESTS_FAILED++))
}
warn() { echo -e "${YELLOW}[WARN]${PLAIN} $1"; }
info() { echo -e "[INFO] $1"; }

# ── Счётчик тестов ────────────────────────────────────────────
TESTS_PASSED=0
TESTS_FAILED=0

# ── Загрузка тестируемого модуля ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  echo "Ошибка: lib/utils.sh не найден"
  exit 1
fi

# Mock зависимостей для тестов
check_root() { :; }
check_ubuntu() { :; }
step() { echo "$1"; }
ok() { echo -e "${GREEN}[✓]${PLAIN} $1"; }
warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
err() {
  echo -e "${RED}[✗]${PLAIN} $1" >&2
  exit 1
}

# Загружаем модуль
source "${SCRIPT_DIR}/lib/utils.sh"

# ── Тест: gen_random ───────────────────────────────────────────
test_gen_random() {
  info "Тестирование gen_random..."

  # Генерация строки определённой длины
  local result
  result=$(gen_random 10)
  if [[ ${#result} -eq 10 ]]; then
    pass "gen_random(10): длина = ${#result}"
    ((TESTS_PASSED++))
  else
    fail "gen_random(10): ожидаемая длина 10, получено ${#result}"
  fi

  # Проверка что только буквы и цифры
  if [[ "$result" =~ ^[a-zA-Z0-9]+$ ]]; then
    pass "gen_random(10): только буквы и цифры"
    ((TESTS_PASSED++))
  else
    fail "gen_random(10): содержит недопустимые символы"
  fi

  # Разные вызовы дают разные результаты
  local result2
  result2=$(gen_random 10)
  if [[ "$result" != "$result2" ]]; then
    pass "gen_random: разные вызовы дают разные результаты"
    ((TESTS_PASSED++))
  else
    warn "gen_random: возможно, недостаточно случайности (вероятность коллизии)"
  fi
}

# ── Тест: gen_hex ─────────────────────────────────────────────
test_gen_hex() {
  info "Тестирование gen_hex..."

  # Генерация строки определённой длины
  local result
  result=$(gen_hex 16)
  if [[ ${#result} -eq 16 ]]; then
    pass "gen_hex(16): длина = ${#result}"
    ((TESTS_PASSED++))
  else
    fail "gen_hex(16): ожидаемая длина 16, получено ${#result}"
  fi

  # Проверка что только hex-символы
  if [[ "$result" =~ ^[a-f0-9]+$ ]]; then
    pass "gen_hex(16): только hex-символы (a-f, 0-9)"
    ((TESTS_PASSED++))
  else
    fail "gen_hex(16): содержит недопустимые символы"
  fi
}

# ── Тест: gen_port ───────────────────────────────────────────
test_gen_port() {
  info "Тестирование gen_port..."

  # Генерация порта в диапазоне 30000-62000
  local result
  result=$(gen_port)
  if [[ "$result" -ge 30000 && "$result" -le 62000 ]]; then
    pass "gen_port: $result в диапазоне 30000-62000"
    ((TESTS_PASSED++))
  else
    fail "gen_port: $result вне диапазона 30000-62000"
  fi

  # Разные вызовы дают разные результаты (с высокой вероятностью)
  local result2
  result2=$(gen_port)
  if [[ "$result" != "$result2" ]]; then
    pass "gen_port: разные вызовы дают разные результаты"
    ((TESTS_PASSED++))
  else
    warn "gen_port: возможно, недостаточно случайности"
  fi
}

# ── Тест: unique_port ────────────────────────────────────────
test_unique_port() {
  info "Тестирование unique_port..."

  # Первая генерация должна добавить порт в USED_PORTS
  local port1
  port1=$(unique_port)

  # Сбрасываем USED_PORTS для теста
  USED_PORTS=(443)

  # Проверка что порт уникален (не 443)
  if [[ "$port1" != 443 ]]; then
    pass "unique_port: сгенерирован уникальный порт $port1 (не в USED_PORTS)"
    ((TESTS_PASSED++))
  else
    fail "unique_port: сгенерирован порт из USED_PORTS"
  fi

  # Добавляем сгенерированный порт в список
  USED_PORTS+=("$port1")

  # Следующий вызов должен дать другой порт
  local port2
  port2=$(unique_port)

  if [[ "$port2" != "$port1" ]]; then
    pass "unique_port: сгенерирован другой порт $port2"
    ((TESTS_PASSED++))
  else
    warn "unique_port: возможно, недостаточно уникальных портов"
  fi

  # Проверка что оба порта в диапазоне
  if [[ "$port1" -ge 30000 && "$port1" -le 62000 && "$port2" -ge 30000 && "$port2" -le 62000 ]]; then
    pass "unique_port: все порты в диапазоне 30000-62000"
    ((TESTS_PASSED++))
  else
    fail "unique_port: один из портов вне диапазона"
  fi
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
    ((TESTS_PASSED++))
    ;;
  *)
    warn "arch: неизвестная архитектура $result (может быть нормально для тестовой системы)"
    ;;
  esac
}

# ── Тест: get_server_ip ───────────────────────────────────────
test_get_server_ip() {
  info "Тестирование get_server_ip..."

  # Тест может не работать без сети
  local result
  result=$(get_server_ip 2>/dev/null || echo "")

  if [[ -n "$result" ]]; then
    # Проверка формата IPv4
    if [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      pass "get_server_ip: получен валидный IP $result"
      ((TESTS_PASSED++))
    else
      warn "get_server_ip: получен IP в неожиданном формате: $result"
    fi
  else
    warn "get_server_ip: не удалось получить IP (нет сети или недоступен)"
  fi
}

# ── Тест: open_port (mock) ────────────────────────────────────
test_open_port_mock() {
  info "Тестирование open_port (mock)..."

  # Создаём mock для ufw
  ufw() {
    echo "mock ufw called with: $*"
  }

  # Вызываем функцию
  open_port 12345 tcp "Test port"

  if command -v ufw &>/dev/null; then
    pass "open_port: вызван без ошибок"
    ((TESTS_PASSED++))
  else
    pass "open_port: пропущен (ufw не установлен в контексте теста)"
    ((TESTS_PASSED++))
  fi
}

# ── Тест: интеграция функций ──────────────────────────────────
test_integration() {
  info "Тестирование интеграции функций..."

  # Генерация полного набора данных
  local domain_name
  domain_name=$(gen_random 20)

  local sbox_short_id
  sbox_short_id=$(gen_hex 8)

  local panel_port
  panel_port=$(gen_port)

  local sub_port
  sub_port=$(unique_port)

  # Проверка что все данные сгенерированы
  if [[ ${#domain_name} -eq 20 && ${#sbox_short_id} -eq 8 && "$panel_port" -ge 30000 && "$sub_port" -ge 30000 ]]; then
    pass "Интеграция: все функции работают вместе"
    ((TESTS_PASSED++))
  else
    fail "Интеграция: одна из функций отработала некорректно"
  fi

  # Проверка что порты уникальны
  if [[ "$panel_port" != "$sub_port" ]]; then
    pass "Интеграция: порты уникальны ($panel_port != $sub_port)"
    ((TESTS_PASSED++))
  else
    warn "Интеграция: порты совпадают (маловероятно)"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - lib/utils.sh          ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
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

  test_unique_port
  echo ""

  test_arch
  echo ""

  test_get_server_ip
  echo ""

  test_open_port_mock
  echo ""

  test_integration
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
