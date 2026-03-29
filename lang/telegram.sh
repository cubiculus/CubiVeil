#!/bin/bash
# shellcheck disable=SC2034
# ╔═══════════════════════════════════════════════════════════╗
# ║         CubiVeil — Telegram Bot Localization              ║
# ║                   EN / RU strings                         ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Окружение скрипта / Script environment ───────────────────
TG_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Подключение fallback функций ─────────────────────────────
if [[ -f "${TG_SCRIPT_DIR}/lib/fallback.sh" ]]; then
  source "${TG_SCRIPT_DIR}/lib/fallback.sh"
fi

# ── Подключение унифицированного модуля локализации ──────────
if [[ -f "${TG_SCRIPT_DIR}/lib/i18n.sh" ]]; then
  source "${TG_SCRIPT_DIR}/lib/i18n.sh"
fi

# ── Подключение общих функций вывода ─────────────────────────
if [[ -f "${TG_SCRIPT_DIR}/lib/output.sh" ]]; then
  source "${TG_SCRIPT_DIR}/lib/output.sh"
fi

# ══════════════════════════════════════════════════════════════
# Telegram Bot Setup — локализованные строки
# ══════════════════════════════════════════════════════════════

# Ошибки / Errors
ERR_ROOT_TG="Scripts must be run as root (sudo)"
ERR_ROOT_TG_RU="Запускай от root (sudo)"

ERR_MARZBAN_NOT_FOUND_TG="Marzban not found. Run main installer first: bash install.sh"
ERR_MARZBAN_NOT_FOUND_TG_RU="Marzban не найден. Сначала запусти основной установщик: bash install.sh"

ERR_PYTHON3_NOT_FOUND_TG="Python3 not found. Install: apt-get install python3"
ERR_PYTHON3_NOT_FOUND_TG_RU="Python3 не установлен. Установи: apt-get install python3"

ERR_CURL_NOT_FOUND_TG="curl not found. Install: apt-get install curl"
ERR_CURL_NOT_FOUND_TG_RU="curl не установлен. Установи: apt-get install curl"

ERR_TG_TOKEN_FORMAT="Invalid Telegram token format. Expected: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
ERR_TG_TOKEN_FORMAT_RU="Некорректный формат токена Telegram. Ожидается: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"

ERR_TG_TOKEN_INVALID="Invalid Telegram token. Verify token from @BotFather"
ERR_TG_TOKEN_INVALID_RU="Токен Telegram недействителен. Проверь токен от @BotFather"

WARN_NETWORK_UNREACHABLE="Could not connect to api.telegram.org. Check network connection."
WARN_NETWORK_UNREACHABLE_RU="Не удалось подключиться к api.telegram.org. Проверь сетевое подключение."

PROMPT_CONTINUE_NO_CHECK="Continue without token verification? [y/N]"
PROMPT_CONTINUE_NO_CHECK_RU="Продолжить без проверки токена? [y/N]"

ERR_BOT_FILE_NOT_FOUND="Bot file not found: {PATH}"
ERR_BOT_FILE_NOT_FOUND_RU="Файл бота не найден: {PATH}"

# Информация / Info
INFO_TG_BOT="Telegram bot: needs token from @BotFather and your chat_id (find out: @userinfobot)."
INFO_TG_BOT_RU="Telegram-бот: нужен токен от @BotFather и твой chat_id (узнать: @userinfobot)."

INFO_ALERT_THRESHOLDS="Alert thresholds (in %, Enter = default):"
INFO_ALERT_THRESHOLDS_RU="Пороги алертов (в %, Enter = по умолчанию):"

# Подтверждения / Success messages
OK_ENV_CHECKED="Environment checked"
OK_ENV_CHECKED_RU="Окружение проверено"

OK_TG_TOKEN_VERIFIED="Telegram token verified ✓"
OK_TG_TOKEN_VERIFIED_RU="Токен Telegram проверен ✓"

OK_TG_CONFIGURED="Telegram configured (report at {REPORT_TIME} UTC)"
OK_TG_CONFIGURED_RU="Telegram: настроен (отчёт в {REPORT_TIME} UTC)"

OK_TG_CONFIGURED_SHORT="Thresholds: CPU>{ALERT_CPU}% RAM>{ALERT_RAM}% Disk>{ALERT_DISK}%"
OK_TG_CONFIGURED_SHORT_RU="Пороги: CPU>{ALERT_CPU}% RAM>{ALERT_RAM}% Диск>{ALERT_DISK}%"

OK_BOT_INSTALLED="Python bot script installed from assets/telegram-bot/"
OK_BOT_INSTALLED_RU="Python-скрипт бота установлен из assets/telegram-bot/"

OK_SENSITIVE_FILE_CREATED="Sensitive data file created ({PATH}, 0600)"
OK_SENSITIVE_FILE_CREATED_RU="Файл с чувствительными данными создан ({PATH}, 0600)"

OK_SYSTEMD_CREATED="Systemd service created"
OK_SYSTEMD_CREATED_RU="Systemd сервис создан"

OK_JOURNALD_CONFIGURED="journald log rotation configured"
OK_JOURNALD_CONFIGURED_RU="Ротация логов journald настроена"

OK_LOGROTATE_CONFIGURED="Log rotation configured (logrotate: {WEEKS} weeks, {SIZE})"
OK_LOGROTATE_CONFIGURED_RU="Ротация логов настроена (logrotate: {WEEKS} недели, {SIZE})"

OK_CRON_CONFIGURED="Cron jobs configured"
OK_CRON_CONFIGURED_RU="Cron задания настроены"

OK_BOT_STARTED="Telegram bot started (systemd: {SERVICE})"
OK_BOT_STARTED_RU="Telegram-бот запущен (systemd: {SERVICE})"

OK_DAILY_REPORT="Daily report + backup: {TIME} UTC"
OK_DAILY_REPORT_RU="Ежедневный отчёт + бэкап: {TIME} UTC"

OK_ALERTS_CONFIGURED="Alerts every 15 min: CPU>{CPU}% RAM>{RAM}% Disk>{DISK}%"
OK_ALERTS_CONFIGURED_RU="Алерты каждые 15 мин: CPU>{CPU}% RAM>{RAM}% Диск>{DISK}%"

OK_COMMANDS="Commands: /status /backup /restart /help"
OK_COMMANDS_RU="Команды: /status /backup /restart /help"

OK_SERVICE_ACTIVE="{SERVICE} is active"
OK_SERVICE_ACTIVE_RU="{SERVICE} активен"

# Предупреждения / Warnings
WARN_INVALID_CHAT_ID="Invalid Chat ID. Expected a number (e.g., 123456789)"
WARN_INVALID_CHAT_ID_RU="Некорректный Chat ID. Ожидается число (например: 123456789)"

WARN_INVALID_TIME="Invalid time. Format: HH:MM (e.g., 09:00)"
WARN_INVALID_TIME_RU="Некорректное время. Формат: ЧЧ:ММ (например: 09:00)"

WARN_SERVICE_TIMEOUT="{SERVICE} did not become active in {SECONDS}s"
WARN_SERVICE_TIMEOUT_RU="{SERVICE} не стал активным за {SECONDS}с"

WARN_BOT_MODULE_NOT_FOUND="Bot module not found: {MODULE}"
WARN_BOT_MODULE_NOT_FOUND_RU="Модуль бота не найден: {MODULE}"

# Подсказки / Prompts
PROMPT_TG_TOKEN="Telegram Bot Token: "
PROMPT_TG_TOKEN_RU="Telegram Bot Token: "

PROMPT_TG_CHAT_ID="Telegram Chat ID: "
PROMPT_TG_CHAT_ID_RU="Telegram Chat ID: "

PROMPT_REPORT_TIME="Daily report time UTC [09:00]: "
PROMPT_REPORT_TIME_RU="Время ежедневного отчёта UTC [09:00]: "

PROMPT_ALERT_CPU="CPU  > ? % [80]: "
PROMPT_ALERT_CPU_RU="CPU  > ? % [80]: "

PROMPT_ALERT_RAM="RAM  > ? % [85]: "
PROMPT_ALERT_RAM_RU="RAM  > ? % [85]: "

PROMPT_ALERT_DISK="Disk > ? % [90]: "
PROMPT_ALERT_DISK_RU="Диск > ? % [90]: "

# Заголовки шагов / Step titles
STEP_TITLE_ENV_CHECK="Environment check"
STEP_TITLE_ENV_CHECK_RU="Проверка окружения"

STEP_TITLE_TG_CONFIG="Telegram configuration"
STEP_TITLE_TG_CONFIG_RU="Настройка Telegram"

STEP_TITLE_BOT_INSTALL="Bot installation"
STEP_TITLE_BOT_INSTALL_RU="Установка бота"

STEP_TITLE_SERVICE_CONFIG="Service configuration"
STEP_TITLE_SERVICE_CONFIG_RU="Настройка сервисов"

# Финальные сообщения / Final messages
FINAL_SUCCESS_TITLE="Telegram bot installed successfully! 🎉"
FINAL_SUCCESS_TITLE_RU="Telegram-бот установлен успешно! 🎉"

FINAL_BOT_SECTION="BOT"
FINAL_BOT_SECTION_RU="БОТ"

FINAL_STATUS="Status"
FINAL_STATUS_RU="Статус"

FINAL_LOGS="Logs"
FINAL_LOGS_RU="Логи"

FINAL_COMMANDS_SECTION="COMMANDS"
FINAL_COMMANDS_SECTION_RU="КОМАНДЫ"

FINAL_NAVIGATION="Use menu buttons for navigation!"
FINAL_NAVIGATION_RU="Используйте кнопки в меню для навигации!"

FINAL_WARNINGS_TITLE="Warnings during Telegram install:"
FINAL_WARNINGS_TITLE_RU="Предупреждения при установке Telegram:"

# ══════════════════════════════════════════════════════════════
# Функция для получения локализованной строки
# ══════════════════════════════════════════════════════════════
get_tg_str() {
  local key="$1"
  local ru_key="${key}_TG_RU"
  local en_key="${key}_TG"
  local key_ru="${key}_RU"

  # Сначала пробуем специфичные для TG переменные
  if [[ "$LANG_NAME" == "Русский" ]]; then
    # Для RU: пробуем ключ_TG_RU, потом ключ_RU, потом ключ_TG, потом ключ
    if [[ -n "${!ru_key:-}" ]]; then
      echo "${!ru_key}"
    elif [[ -n "${!key_ru:-}" ]]; then
      echo "${!key_ru}"
    elif [[ -n "${!en_key:-}" ]]; then
      echo "${!en_key}"
    else
      echo "${!key:-$key}"
    fi
  else
    # Для EN: пробуем ключ_TG, потом ключ
    if [[ -n "${!en_key:-}" ]]; then
      echo "${!en_key}"
    else
      echo "${!key:-$key}"
    fi
  fi
}
