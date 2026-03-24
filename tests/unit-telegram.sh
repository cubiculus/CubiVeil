#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - setup-telegram.sh              ║
# ║        Тестирование скрипта установки Telegram бота        ║
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

# ── Загрузка тестируемого скрипта ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "${SCRIPT_DIR}/setup-telegram.sh" ]]; then
  echo "Ошибка: setup-telegram.sh не найден"
  exit 1
fi

# ── Тест: файл существует ───────────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла setup-telegram.sh..."

  if [[ -f "${SCRIPT_DIR}/setup-telegram.sh" ]]; then
    pass "setup-telegram.sh: файл существует"
    ((TESTS_PASSED++))
  else
    fail "setup-telegram.sh: файл не найден"
  fi
}

# ── Тест: синтаксис скрипта ───────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса setup-telegram.sh..."

  if bash -n "${SCRIPT_DIR}/setup-telegram.sh" 2>/dev/null; then
    pass "setup-telegram.sh: синтаксис корректен"
    ((TESTS_PASSED++))
  else
    fail "setup-telegram.sh: синтаксическая ошибка"
  fi
}

# ── Тест: наличие необходимых функций ───────────────────────────
test_functions_exist() {
  info "Тестирование наличия необходимых функций..."

  # Извлекаем имена функций из скрипта
  local functions
  functions=$(grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)' "${SCRIPT_DIR}/setup-telegram.sh" | awk '{print $1}' | sort -u)

  local required_functions=(
    "step_check_environment"
    "step_prompt_telegram_config"
    "step_install_bot"
    "step_configure_services"
    "main"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if echo "$functions" | grep -q "^${func}$"; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++))
    else
      warn "Функция отсутствует: $func"
      ((missing++))
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "Все необходимые функции присутствуют"
    ((TESTS_PASSED++))
  else
    warn "Отсутствует $missing необходимых функций"
  fi
}

# ── Тест: проверка зависимостей ───────────────────────────────
test_dependencies() {
  info "Тестирование зависимостей скрипта..."

  # Проверка что скрипт загружает необходимые модули
  if grep -q 'source.*lang.sh' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Зависимость: lang.sh загружается"
    ((TESTS_PASSED++))
  else
    fail "Зависимость: lang.sh не загружается"
  fi

  if grep -q 'source.*lib/utils.sh' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Зависимость: lib/utils.sh загружается"
    ((TESTS_PASSED++))
  else
    fail "Зависимость: lib/utils.sh не загружается"
  fi
}

# ── Тест: проверка безопасности ───────────────────────────────
test_security() {
  info "Тестирование мер безопасности..."

  # Проверка что токен берётся из переменной окружения
  if grep -q 'os.environ.get("TG_TOKEN")' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Безопасность: токен в переменной окружения"
    ((TESTS_PASSED++))
  else
    fail "Безопасность: токен не в переменной окружения"
  fi

  # Проверка что systemd сервис имеет защитные директивы
  if grep -q 'ProtectHome' "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q 'ProtectSystem' "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q 'NoNewPrivileges' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Безопасность: systemd защитные директивы"
    ((TESTS_PASSED++))
  else
    warn "Безопасность: не все systemd защитные директивы"
  fi
}

# ── Тест: проверка структуры Python бота ───────────────────────
test_python_bot_structure() {
  info "Тестирование структуры Python бота..."

  # Проверка что Python скрипт создаётся в скрипте
  if grep -q '/opt/cubiveil-bot/bot.py' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Структура: Python бот создаётся в /opt/cubiveil-bot/bot.py"
    ((TESTS_PASSED++))
  else
    fail "Структура: путь к боту некорректен"
  fi

  # Проверка наличия ключевых функций в Python коде
  local bot_functions=(
    "tg_send"
    "get_cpu"
    "get_ram"
    "get_disk"
    "check_alerts"
    "poll"
    "send_daily_report"
  )

  for func in "${bot_functions[@]}"; do
    if grep -q "def ${func}" "${SCRIPT_DIR}/setup-telegram.sh"; then
      pass "Python функция: $func"
      ((TESTS_PASSED++))
    else
      warn "Python функция: $func не найдена"
    fi
  done
}

# ── Тест: проверка systemd сервиса ─────────────────────────────
test_systemd_service() {
  info "Тестирование конфигурации systemd сервиса..."

  # Проверка что создаётся файл сервиса
  if grep -q '/etc/systemd/system/cubiveil-bot.service' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Systemd: путь к сервису корректен"
    ((TESTS_PASSED++))
  else
    fail "Systemd: путь к сервису некорректен"
  fi

  # Проверка ключевых директив
  local systemd_directives=(
    "Description="
    "Type=simple"
    "ExecStart="
    "Restart=always"
    "WantedBy=multi-user.target"
  )

  for directive in "${systemd_directives[@]}"; do
    if grep -q "$directive" "${SCRIPT_DIR}/setup-telegram.sh"; then
      pass "Systemd директива: $directive"
      ((TESTS_PASSED++))
    else
      warn "Systemd директива: $directive не найдена"
    fi
  done
}

# ── Тест: проверка cron заданий ────────────────────────────────
test_cron_jobs() {
  info "Тестирование cron заданий..."

  # Проверка что cron настраивается
  if grep -q 'crontab' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: настроены cron задания"
    ((TESTS_PASSED++))
  else
    fail "Cron: cron задания не настроены"
  fi

  # Проверка наличия задания для отчёта
  if grep -q 'bot.py report' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: задание для ежедневного отчёта"
    ((TESTS_PASSED++))
  else
    fail "Cron: задание для отчёта не найдено"
  fi

  # Проверка наличия задания для алертов
  if grep -q 'bot.py alert' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: задание для алертов"
    ((TESTS_PASSED++))
  else
    fail "Cron: задание для алертов не найдено"
  fi
}

# ── Тест: проверка логирования ─────────────────────────────────
test_logging() {
  info "Тестирование логирования..."

  # Проверка journald конфига
  if grep -q '/etc/systemd/journald.d/cubiveil-limit.conf' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Логирование: journald конфиг создается"
    ((TESTS_PASSED++))
  else
    warn "Логирование: journald конфиг не найден"
  fi

  # Проверка logrotate конфига
  if grep -q '/etc/logrotate.d/cubiveil-services' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Логирование: logrotate конфиг создается"
    ((TESTS_PASSED++))
  else
    warn "Логирование: logrotate конфиг не найден"
  fi
}

# ── Тест: проверка структуры установки ─────────────────────────
test_installation_structure() {
  info "Тестирование структуры установки..."

  # Проверка что создаётся директория для бэкапов
  if grep -q '/opt/cubiveil-bot/backups' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Структура: директория для бэкапов создается"
    ((TESTS_PASSED++))
  else
    fail "Структура: директория для бэкапов не найдена"
  fi

  # Проверка что бот зависит от Marzban
  if grep -q 'After=marzban' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Зависимости: бот запускается после Marzban"
    ((TESTS_PASSED++))
  else
    warn "Зависимости: зависимость от Marzban не указана"
  fi
}

# ── Тест: проверка валидации токена ───────────────────────────
test_token_validation() {
  info "Тестирование валидации токена Telegram..."

  # Проверка формата токена
  if grep -q '^[0-9]+:[A-Za-z0-9_-]{35}$' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Валидация: проверка формата токена"
    ((TESTS_PASSED++))
  else
    warn "Валидация: проверка формата токена не найдена"
  fi

  # Проверка валидации через API
  if grep -q 'api.telegram.org.*getMe' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Валидация: проверка токена через API Telegram"
    ((TESTS_PASSED++))
  else
    warn "Валидация: проверка через API не найдена"
  fi
}

# ── Тест: проверка валидации Chat ID ─────────────────────────
test_chat_id_validation() {
  info "Тестирование валидации Chat ID..."

  # Проверка формата Chat ID
  if grep -q '^-?\[0-9\]+$' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Валидация: проверка формата Chat ID"
    ((TESTS_PASSED++))
  else
    warn "Валидация: проверка формата Chat ID не найдена"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - setup-telegram.sh       ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый скрипт: ${SCRIPT_DIR}/setup-telegram.sh"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_functions_exist
  echo ""

  test_dependencies
  echo ""

  test_security
  echo ""

  test_python_bot_structure
  echo ""

  test_systemd_service
  echo ""

  test_cron_jobs
  echo ""

  test_logging
  echo ""

  test_installation_structure
  echo ""

  test_token_validation
  echo ""

  test_chat_id_validation
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
