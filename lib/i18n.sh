#!/bin/bash
# shellcheck disable=SC1071
set -euo pipefail
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
  local result=""

  if [[ "$LANG_NAME" == "Русский" ]]; then
    # Проверяем существование переменной перед использованием
    if [[ -n "${!ru_key:-}" ]]; then
      result="${!ru_key}"
    elif [[ -n "${!key:-}" ]]; then
      result="${!key}"
    else
      result="[$key]"
    fi
    echo "$result"
  else
    # English / default
    if [[ -n "${!key:-}" ]]; then
      result="${!key}"
    else
      result="[$key]"
    fi
    echo "$result"
  fi
}

# ── Функция для сообщений из ассоциативного массива MSG ──────────
# Используется для сообщений update.sh/rollback.sh
# Аргументы: $1 = ключ в MSG[], $2 = значение по умолчанию (опционально)

msg() {
  local key="$1"
  local default="${2:-}"
  local result=""

  # Проверяем есть ли массив MSG
  if declare -p MSG 2>/dev/null | grep -q 'declare -A'; then
    echo "${MSG[$key]:-$default}"
  else
    # Проверяем обычные переменные
    local ru_key="${key}_RU"
    if [[ "$LANG_NAME" == "Русский" ]]; then
      if [[ -v ru_key ]]; then
        result="${!ru_key}"
      elif [[ -v key ]]; then
        result="${!key}"
      else
        result="$default"
      fi
    else
      if [[ -v key ]]; then
        result="${!key}"
      else
        result="$default"
      fi
    fi
    echo "$result"
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

# ── Telegram-специфичные строки локализации ──────────────────
# ПРИМЕЧАНИЕ: Telegram-специфичные строки и функции определены в lang/telegram.sh
# Использование get_tg_str() из lang/telegram.sh
# Для избежания дублирования и оптимизации, массив TELEGRAM_SETUP и get_setup_str()
# были перемещены в lang/telegram.sh, где используются только когда необходимо.
