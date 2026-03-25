#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Output Functions                      ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Унифицированные функции вывода для всех скриптов        ║
# ╚═══════════════════════════════════════════════════════════╝

# Guard check - не подключать повторно
if [[ -n "${_CUBIVEIL_OUTPUT_LOADED:-}" ]]; then
  return 0
fi
_CUBIVEIL_OUTPUT_LOADED=1

# ── Цвета / Colors ───────────────────────────────────────────
# shellcheck disable=SC2034
# ANSI color codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PLAIN='\033[0m'

# ── Константы иконок / Icon constants ────────────────────────
readonly ICON_INFO="ℹ️ "
readonly ICON_SUCCESS="✅ "
readonly ICON_WARNING="⚠️  "
readonly ICON_ERROR="❌ "
readonly ICON_CHECK="[✓]"
readonly ICON_WARN="[!]"

# ── Константы форматирования / Formatting constants ─────────
readonly STEP_SEPARATOR="══════════════════════════════════════════════════════════"
readonly STEP_SEPARATOR_SHORT="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Функции вывода / Output functions ─────────────────────────

# Информационное сообщение / Informational message
info() {
  echo -e "${ICON_INFO}$*"
}

# Успешное сообщение / Success message
success() {
  echo -e "${ICON_SUCCESS}$*"
}

# Предупреждение / Warning message
warning() {
  echo -e "${ICON_WARNING}$*"
}

# Ошибка с выходом / Error with exit
err() {
  echo -e "${ICON_ERROR}$*" >&2
  exit 1
}

# Успешная отметка (совместимость с lib/fallback.sh)
ok() {
  echo -e "${GREEN}${ICON_CHECK}${PLAIN} $1"
}

# Предупреждающая отметка (совместимость с lib/fallback.sh)
warn() {
  echo -e "${YELLOW}${ICON_WARN}${PLAIN} $1"
}

# ── Функции шагов / Step functions ───────────────────────────

# Заголовок шага с номером и локализацией
# Parameters:
#   $1 - step number
#   $2 - Russian description
#   $3 - English description
step_title() {
  local step="$1"
  local ru="$2"
  local en="$3"

  echo ""
  echo "${STEP_SEPARATOR}"
  if [[ "${LANG_NAME:-}" == "Русский" ]]; then
    echo "  ${step}. ${ru}"
  else
    echo "  ${step}. ${en}"
  fi
  echo "${STEP_SEPARATOR}"
}

# Простой заголовок шага (совместимость с lib/fallback.sh)
step() {
  echo -e "\n${BLUE}${STEP_SEPARATOR_SHORT}${PLAIN}"
  echo -e "${BLUE}  $1${PLAIN}"
  echo -e "${BLUE}${STEP_SEPARATOR_SHORT}${PLAIN}"
}
