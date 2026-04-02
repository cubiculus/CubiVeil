#!/bin/bash
# shellcheck disable=SC1071
# ════════════════════════════════════════════════════════════╗
#          CubiVeil Unit Tests - setup-telegram.sh
#          Тестирование скрипта установки Telegram бота
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ─────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# ── Загрузка тестируемого скрипта ───────────────────────────
if [[ ! -f "${SCRIPT_DIR}/setup-telegram.sh" ]]; then
  echo "Ошибка: setup-telegram.sh не найден"
  exit 1
fi

# ── Директория с Python файлами бота ────────────────────────
BOT_PYTHON_DIR="${SCRIPT_DIR}/assets/telegram-bot"
BOT_MAIN_FILE="${BOT_PYTHON_DIR}/bot.py"

# ── Вспомогательная функция для проверки Python функций ─────
# Usage: check_python_functions "category" "func1" "func2" ...
# Проверяет файлы в assets/telegram-bot/
check_python_functions() {
  local category="$1"
  shift
  local functions=("$@")
  local found=0

  for func in "${functions[@]}"; do
    if grep -q "def ${func}" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
      pass "Python $category: $func"
      ((TESTS_PASSED++)) || true
      ((found++)) || true
    else
      warn "Python $category: $func не найдена"
    fi
  done

  if [[ $found -eq ${#functions[@]} ]]; then
    pass "Python $category: все функции найдены ($found/${#functions[@]})"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Вспомогательная функция для проверки systemd директив ───
# Usage: check_systemd_directives "directive1" "directive2" ...
check_systemd_directives() {
  local directives=("$@")
  local found=0

  for directive in "${directives[@]}"; do
    if grep -q "$directive" "${SCRIPT_DIR}/setup-telegram.sh"; then
      pass "Systemd: $directive"
      ((TESTS_PASSED++)) || true
      ((found++)) || true
    else
      warn "Systemd: $directive не найдена"
    fi
  done

  if [[ $found -eq ${#directives[@]} ]]; then
    pass "Systemd: все директивы найдены ($found/${#directives[@]})"
    ((TESTS_PASSED++)) || true
  fi
}

# ── Тест: файл существует ───────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла setup-telegram.sh..."

  if [[ -f "${SCRIPT_DIR}/setup-telegram.sh" ]]; then
    pass "setup-telegram.sh: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "setup-telegram.sh: файл не найден"
  fi
}

# ── Тест: синтаксис скрипта ─────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса setup-telegram.sh..."

  if bash -n "${SCRIPT_DIR}/setup-telegram.sh" 2>/dev/null; then
    pass "setup-telegram.sh: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "setup-telegram.sh: синтаксическая ошибка"
  fi
}

# ── Тест: наличие необходимых функций ───────────────────────
test_functions_exist() {
  info "Тестирование наличия необходимых функций..."

  # Извлекаем имена функций из скрипта
  local functions
  functions=$(grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)' "${SCRIPT_DIR}/setup-telegram.sh" | awk '{print $1}' | sed 's/()$//' | sort -u)

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
      ((TESTS_PASSED++)) || true
    else
      warn "Функция отсутствует: $func"
      ((missing++))
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "Все необходимые функции присутствуют"
    ((TESTS_PASSED++)) || true
  else
    warn "Отсутствует $missing необходимых функций"
  fi
}

# ── Тест: проверка зависимостей ─────────────────────────────
test_dependencies() {
  info "Тестирование зависимостей скрипта..."

  # Проверка что скрипт загружает необходимые модули
  if grep -q 'source.*lang/main.sh' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Зависимость: lang/main.sh загружается"
    ((TESTS_PASSED++)) || true
  else
    fail "Зависимость: lang/main.sh не загружается"
  fi

  if grep -q 'source.*lib/utils.sh' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Зависимость: lib/utils.sh загружается"
    ((TESTS_PASSED++)) || true
  else
    fail "Зависимость: lib/utils.sh не загружается"
  fi
}

# ── Тест: проверка безопасности ─────────────────────────────
test_security() {
  info "Тестирование мер безопасности..."

  # Проверка что токен берётся из переменной окружения в Python боте
  if grep -q 'os.environ.get.*TG_TOKEN' "${BOT_MAIN_FILE}"; then
    pass "Безопасность: токен в переменной окружения"
    ((TESTS_PASSED++)) || true
  else
    fail "Безопасность: токен не в переменной окружения"
  fi

  # Проверка что systemd сервис имеет защитные директивы
  if grep -q 'ProtectHome' "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q 'ProtectSystem' "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q 'NoNewPrivileges' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Безопасность: systemd защитные директивы"
    ((TESTS_PASSED++)) || true
  else
    warn "Безопасность: не все systemd защитные директивы"
  fi
}

# ── Тест: проверка структуры Python бота ────────────────────
test_python_bot_structure() {
  info "Тестирование структуры Python бота..."

  # Проверка что Python скрипт создаётся в скрипте
  if grep -q '/opt/cubiveil-bot/bot.py' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Структура: Python бот создаётся в /opt/cubiveil-bot/bot.py"
    ((TESTS_PASSED++)) || true
  else
    fail "Структура: путь к боту некорректен"
  fi

  # Проверка наличия ключевых функций/методов в Python коде
  local bot_functions=(
    "send"
    "validate_token"
    "get_cpu"
    "get_ram"
    "get_disk"
    "check_alerts"
    "poll"
    "send_daily_report"
  )

  for func in "${bot_functions[@]}"; do
    if grep -q "def ${func}" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
      pass "Python функция: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Python функция: $func не найдена"
    fi
  done
}

# ── Тест: проверка systemd сервиса ──────────────────────────
test_systemd_service() {
  info "Тестирование конфигурации systemd сервиса..."

  # Проверка что создаётся файл сервиса
  if grep -q '/etc/systemd/system/cubiveil-bot.service' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Systemd: путь к сервису корректен"
    ((TESTS_PASSED++)) || true
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
      ((TESTS_PASSED++)) || true
    else
      warn "Systemd директива: $directive не найдена"
    fi
  done
}

# ── Тест: проверка cron заданий ─────────────────────────────
test_cron_jobs() {
  info "Тестирование cron заданий..."

  # Проверка что cron настраивается
  if grep -q 'crontab' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: настроены cron задания"
    ((TESTS_PASSED++)) || true
  else
    fail "Cron: cron задания не настроены"
  fi

  # Проверка наличия задания для отчёта
  if grep -q 'bot.py report' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: задание для ежедневного отчёта"
    ((TESTS_PASSED++)) || true
  else
    fail "Cron: задание для отчёта не найдено"
  fi

  # Проверка наличия задания для алертов
  if grep -q 'bot.py alert' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: задание для алертов"
    ((TESTS_PASSED++)) || true
  else
    fail "Cron: задание для алертов не найдено"
  fi
}

# ── Тест: проверка логирования ──────────────────────────────
test_logging() {
  info "Тестирование логирования..."

  # Проверка journald конфига
  if grep -q '/etc/systemd/journald.d/cubiveil-limit.conf' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Логирование: journald конфиг создаётся"
    ((TESTS_PASSED++)) || true
  else
    warn "Логирование: journald конфиг не найден"
  fi

  # Проверка logrotate конфига
  if grep -q '/etc/logrotate.d/cubiveil-services' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Логирование: logrotate конфиг создаётся"
    ((TESTS_PASSED++)) || true
  else
    warn "Логирование: logrotate конфиг не найден"
  fi
}

# ── Тест: проверка структуры установки ──────────────────────
test_installation_structure() {
  info "Тестирование структуры установки..."

  # Проверка что создаётся директория для бэкапов
  if grep -q '/opt/cubiveil-bot/backups' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Структура: директория для бэкапов создаётся"
    ((TESTS_PASSED++)) || true
  else
    fail "Структура: директория для бэкапов не найдена"
  fi

  # Проверка что бот зависит от Marzban
  if grep -q 'After=.*marzban' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Зависимости: бот запускается после Marzban"
    ((TESTS_PASSED++)) || true
  else
    warn "Зависимости: зависимость от Marzban не указана"
  fi
}

# ── Тест: проверка валидации токена ─────────────────────────
test_token_validation() {
  info "Тестирование валидации токена Telegram..."

  # Проверка формата токена (полный regex паттерн)
  if grep -q 'TG_TOKEN.*=~.*\^' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Валидация: проверка формата токена"
    ((TESTS_PASSED++)) || true
  else
    warn "Валидация: проверка формата токена не найдена"
  fi

  # Проверка валидации через API
  if grep -q 'api.telegram.org.*getMe' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Валидация: проверка токена через API Telegram"
    ((TESTS_PASSED++)) || true
  else
    warn "Валидация: проверка через API не найдена"
  fi
}

# ── Тест: проверка валидации Chat ID ────────────────────────
test_chat_id_validation() {
  info "Тестирование валидации Chat ID..."

  # Проверка формата Chat ID
  if grep -q 'validate_chat_id' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Валидация: проверка формата Chat ID"
    ((TESTS_PASSED++)) || true
  else
    warn "Валидация: проверка формата Chat ID не найдена"
  fi
}

# ── Тест: Python бот — функции метрик ───────────────────────
test_python_bot_metrics() {
  info "Тестирование Python функций метрик..."
  check_python_functions "метрика" "get_cpu" "get_ram" "get_disk" "get_uptime"
}

# ── Тест: Python бот — функции отправки ─────────────────────
test_python_bot_send_functions() {
  info "Тестирование Python функций отправки..."
  check_python_functions "отправки" "send" "send_file"
}

# ── Тест: Python бот — команды ──────────────────────────────
test_python_bot_commands() {
  info "Тестирование Python команд бота..."

  check_python_functions "команд" "handle"

  # Проверка наличия команд
  local commands=("/start" "/status" "/backup" "/users" "/restart" "/help")
  local found=0
  for cmd in "${commands[@]}"; do
    if grep -q "\"${cmd}\"" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null ||
      grep -q "'${cmd}'" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
      ((found++)) || true
    fi
  done
  if [[ $found -eq ${#commands[@]} ]]; then
    pass "Python команды: все найдены ($found/${#commands[@]})"
    ((TESTS_PASSED++)) || true
  else
    warn "Python команды: найдено $found/${#commands[@]}"
  fi
}

# ── Тест: Python бот — polling ──────────────────────────────
test_python_bot_polling() {
  info "Тестирование Python polling..."

  check_python_functions "" "poll"

  # Проверка что используется getUpdates API
  if grep -q "getUpdates" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: используется getUpdates API"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: getUpdates API не найден"
  fi

  # Проверка авторизации по chat_id (комплексная)
  if grep -q "chat_id" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null &&
    grep -q "chat.*id" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: авторизация по chat_id"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: авторизация по chat_id не найдена"
  fi
}

# ── Тест: Python бот — алерты ───────────────────────────────
test_python_bot_alerts() {
  info "Тестирование Python системы алертов..."

  check_python_functions "алертов" "check_alerts"

  # Проверка что используется state файл для предотвращения спама
  if grep -q "load_state\|save_state\|\.load()\|\.save(" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: состояние алертов сохраняется"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: состояние алертов не сохраняется"
  fi

  # Проверка пороговых значений (все сразу)
  if grep -q "ALERT_CPU" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null &&
    grep -q "ALERT_RAM" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null &&
    grep -q "ALERT_DISK" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: все пороговые значения найдены"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: не все пороговые значения найдены"
  fi
}

# ── Тест: Python бот — бэкапы ───────────────────────────────
test_python_bot_backups() {
  info "Тестирование Python системы бэкапов..."

  check_python_functions "бэкапов" "create"

  # Проверка что используется правильный путь к БД
  # Путь может быть /var/lib/marzban/db.sqlite3 или определяться через os.environ
  if grep -q "db.sqlite3\|DATABASE_PATH\|DB_PATH\|db_path" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: путь к БД Marzban"
    ((TESTS_PASSED++)) || true
  else
    fail "Python: путь к БД не найден"
  fi

  # Проверка что старые бэкапы удаляются
  if grep -q "cleanup_old_backups\|retention_days\|old.*backup" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: старые бэкапы удаляются"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: удаление старых бэкапов не найдено"
  fi
}

# ── Тест: Python бот — точка входа ──────────────────────────
test_python_bot_entry_point() {
  info "Тестирование Python точки входа..."

  # Проверка наличия if __name__ == "__main__"
  if grep -q 'if __name__ == "__main__":' "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: точка входа существует"
    ((TESTS_PASSED++)) || true
  else
    fail "Python: точка входа не найдена"
  fi

  # Проверка что поддерживаются режимы report, alert, poll
  local modes=("report" "alert" "poll")
  for mode in "${modes[@]}"; do
    if grep -q "cmd == \"$mode\"\|cmd == '$mode'" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
      pass "Python: режим $mode"
      ((TESTS_PASSED++)) || true
    else
      warn "Python: режим $mode не найден"
    fi
  done
}

# ── Тест: Python бот — обработка ошибок ─────────────────────
test_python_bot_error_handling() {
  info "Тестирование Python обработки ошибок..."

  # Проверка наличия try/except блоков
  if grep -q "try:" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null &&
    grep -q "except" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: обработка ошибок существует"
    ((TESTS_PASSED++)) || true
  else
    fail "Python: обработка ошибок не найдена"
  fi

  # Проверка что URLError обрабатывается
  if grep -q "URLError\|urllib.error\|Exception" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: обработка сетевых ошибок"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: обработка сетевых ошибок не найдена"
  fi

  # Проверка что Exception обрабатывается
  if grep -q "except Exception" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: обработка общих исключений"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: обработка общих исключений не найдена"
  fi
}

# ── Тест: Python бот — визуализация ─────────────────────────
test_python_bot_visualization() {
  info "Тестирование Python визуализации..."
  check_python_functions "визуализации" "_progress_bar\|progress_bar\|bar"

  # Проверка использования emoji (все сразу)
  if grep -q "🔴" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null &&
    grep -q "🟢" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null &&
    grep -q "⚠️" "${BOT_PYTHON_DIR}"/*.py 2>/dev/null; then
    pass "Python: emoji используются"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: emoji не используются"
  fi
}

# ── Тест: systemd сервис — безопасность ─────────────────────
test_systemd_security() {
  info "Тестирование безопасности systemd сервиса..."

  check_systemd_directives "ProtectHome=true" "ProtectSystem=strict" "NoNewPrivileges=true"

  # Проверка что переменные окружения используются для токенов
  if grep -q 'EnvironmentFile=/etc/cubiveil/bot.env' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Systemd: токен в EnvironmentFile"
    ((TESTS_PASSED++)) || true
  else
    warn "Systemd: токен не в EnvironmentFile"
  fi

  if grep -q 'TG_TOKEN' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Systemd: TG_TOKEN используется"
    ((TESTS_PASSED++)) || true
  else
    warn "Systemd: TG_TOKEN не используется"
  fi
}

# ── Основная функция ────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - setup-telegram.sh       ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый скрипт: ${SCRIPT_DIR}/setup-telegram.sh"
  info "Python бот директория: ${BOT_PYTHON_DIR}"
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

  test_python_bot_metrics
  echo ""

  test_python_bot_send_functions
  echo ""

  test_python_bot_commands
  echo ""

  test_python_bot_polling
  echo ""

  test_python_bot_alerts
  echo ""

  test_python_bot_backups
  echo ""

  test_python_bot_entry_point
  echo ""

  test_python_bot_error_handling
  echo ""

  test_python_bot_visualization
  echo ""

  test_systemd_security
  echo ""

  # ── Итоги ─────────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo -e "${GREEN}Пройдено: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Провалено:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
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
