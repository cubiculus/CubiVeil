#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Unified Localization                  ║
# ║          github.com/cubiculus/cubiveil                    ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Базовый модуль локализации ───────────────────────────────
# Этот файл предоставляет унифицированный API для локализации
# Функции вывода (step_title, step, ok, warn, err, info) импортируются из output.sh

# ── Основные функции локализации ────────────────────────────────
# get_str() - получить локализованную строку по ключу
# Аргументы: $1 = ключ (например, "ERR_ROOT")
# Возвращает: локализованную строку

get_str() {
  local key="$1"
  local ru_key="${key}_RU"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "${!ru_key:-${!key}}"
  else
    echo "${!key}"
  fi
}

# ── Функция для сообщений из ассоциативного массива MSG ──────────
# Используется для сообщений update.sh/rollback.sh
# Аргументы: $1 = ключ в MSG[], $2 = значение по умолчанию (опционально)

msg() {
  local key="$1"
  local default="${2:-}"

  # Проверяем есть ли массив MSG
  if declare -p MSG 2>/dev/null | grep -q 'declare -A'; then
    echo "${MSG[$key]:-$default}"
  else
    # Проверяем обычные переменные
    local ru_key="${key}_RU"
    if [[ "$LANG_NAME" == "Русский" ]]; then
      echo "${!ru_key:-${!key:-$default}}"
    else
      echo "${!key:-$default}"
    fi
  fi
}

# ── Проверка инициализации локализации ───────────────────────────
# Проверяет что LANG_NAME установлен, если нет - устанавливает дефолт

ensure_lang_initialized() {
  if [[ -z "${LANG_NAME:-}" ]]; then
    LANG_NAME="Русский"
  fi
}

# Инициализируем при загрузке
ensure_lang_initialized

# ── Расширенные функции локализации ──────────────────────────────

# msg_safe() - безопасная версия msg (не выводит ошибку если массив не найден)
msg_safe() {
  local key="$1"
  local default="${2:-$key}"
  msg "$key" "$default"
}

# ── Функции для работы с локализованными массивами ───────────────

# init_msg_array() - инициализирует MSG массив если нужно
init_msg_array() {
  if ! declare -p MSG 2>/dev/null | grep -q 'declare -A'; then
    declare -gA MSG
  fi
}

# set_msg() - устанавливает сообщение в MSG массив
# Аргументы: $1 = ключ, $2 = русский текст, $3 = английский текст
set_msg() {
  local key="$1"
  local ru="$2"
  local en="$3"

  init_msg_array
  MSG[$key]="$en"
  MSG[${key}_RU]="$ru"
}

# get_msg() - получает сообщение из MSG массива с учётом языка
get_msg() {
  local key="$1"
  local default="${2:-}"

  if ! declare -p MSG 2>/dev/null | grep -q 'declare -A'; then
    echo "$default"
    return
  fi

  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "${MSG[${key}_RU]:-${MSG[$key]:-$default}}"
  else
    echo "${MSG[$key]:-$default}"
  fi
}

# ── Словарь локализации для setup-telegram.sh ─────────────

# Telegram Bot Setup
declare -A TELEGRAM_SETUP=(
  [INFO_TG_BOT_RU]="Telegram-бот: нужен токен от @BotFather и твой chat_id (узнать: @userinfobot)."
  [INFO_TG_BOT]="Telegram bot: needs token from @BotFather and your chat_id (find out: @userinfobot)."
  [PROMPT_TG_TOKEN_RU]="  Telegram Bot Token: "
  [PROMPT_TG_TOKEN]="  Telegram Bot Token: "
  [ERR_TG_TOKEN_FORMAT_RU]="Некорректный формат токена Telegram. Ожидается: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
  [ERR_TG_TOKEN_FORMAT]="Invalid Telegram token format. Expected: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
  [ERR_TG_TOKEN_INVALID_RU]="Токен Telegram недействителен. Проверь токен от @BotFather"
  [ERR_TG_TOKEN_INVALID]="Invalid Telegram token. Verify token from @BotFather"
  [OK_TG_TOKEN_VERIFIED_RU]="Токен Telegram проверен ✓"
  [OK_TG_TOKEN_VERIFIED]="Telegram token verified ✓"
  [PROMPT_TG_CHAT_ID_RU]="  Telegram Chat ID: "
  [PROMPT_TG_CHAT_ID]="  Telegram Chat ID: "
  [WARN_INVALID_CHAT_ID_RU]="Некорректный Chat ID. Ожидается число (например: 123456789)"
  [WARN_INVALID_CHAT_ID]="Invalid Chat ID. Expected a number (e.g., 123456789)"
  [PROMPT_REPORT_TIME_RU]="  Время ежедневного отчёта UTC [09:00]: "
  [PROMPT_REPORT_TIME]="  Daily report time UTC [09:00]: "
  [WARN_INVALID_TIME_RU]="Некорректное время. Формат: ЧЧ:ММ (например: 09:00)"
  [WARN_INVALID_TIME]="Invalid time. Format: HH:MM (e.g., 09:00)"
  [INFO_ALERT_THRESHOLDS_RU]="Пороги алертов (в %, Enter = по умолчанию):"
  [INFO_ALERT_THRESHOLDS]="Alert thresholds (in %, Enter = default):"
  [PROMPT_ALERT_CPU_RU]="  CPU  > ? % [80]: "
  [PROMPT_ALERT_CPU]="  CPU  > ? % [80]: "
  [PROMPT_ALERT_RAM_RU]="  RAM  > ? % [85]: "
  [PROMPT_ALERT_RAM]="  RAM  > ? % [85]: "
  [PROMPT_ALERT_DISK_RU]="  Диск > ? % [90]: "
  [PROMPT_ALERT_DISK]="  Disk > ? % [90]: "
  [OK_TG_CONFIGURED_RU]="Telegram: настроен (отчёт в ${REPORT_TIME} UTC)"
  [OK_TG_CONFIGURED]="Telegram configured (report at ${REPORT_TIME} UTC)"
  [OK_TG_CONFIGURED_SHORT_RU]="Пороги: CPU>${ALERT_CPU}% RAM>${ALERT_RAM}% Диск>${ALERT_DISK}%"
  [OK_TG_CONFIGURED_SHORT]="Thresholds: CPU>${ALERT_CPU}% RAM>${ALERT_RAM}% Disk>${ALERT_DISK}%"
)

# Функция для получения локализованной строки из словаря
get_setup_str() {
  local key="$1"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "${TELEGRAM_SETUP[${key}_RU]:-${TELEGRAM_SETUP[$key]}}"
  else
    echo "${TELEGRAM_SETUP[$key]}"
  fi
}
