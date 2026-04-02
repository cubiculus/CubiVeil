#!/bin/bash
# shellcheck disable=SC1071
# shellcheck disable=SC2034
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Output Functions                      ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Унифицированные функции вывода для всех скриптов        ║
# ╚═══════════════════════════════════════════════════════════╝

# Strict mode отключён для совместимости

# Guard check - не подключать повторно
if [[ -n "${_CUBIVEIL_OUTPUT_LOADED:-}" ]]; then
  return 0
fi
_CUBIVEIL_OUTPUT_LOADED=1

# ── Цвета / Colors ───────────────────────────────────────────
# ANSI color codes for terminal output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PLAIN='\033[0m'

# ── Глобальные переменные / Global variables ────────────────
# Массив для сбора предупреждений (инициализируется с защитой от set -u)
# Если уже определён (например, в log.sh) — сохраняем существующие значения
WARNINGS=("${WARNINGS[@]+"${WARNINGS[@]}"}")

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
  echo -e "· $*"
}

# Успешное сообщение / Success message
success() {
  echo -e "${GREEN}✓ $*${PLAIN}"
}

# Предупреждение / Warning message
warning() {
  local msg="$*"
  echo -e "${YELLOW}⚠ ${msg}${PLAIN}"

  # Собираем предупреждения для итоговой сводки
  WARNINGS+=("${msg}")
}

# Ошибка с выходом / Error with exit
err() {
  echo -e "${ICON_ERROR}$*" >&2
  exit 1
}

# Успешная отметка (совместимость с lib/fallback.sh)
ok() {
  echo -e "${GREEN}✓ $1${PLAIN}"
}

# Предупреждающая отметка (совместимость с lib/fallback.sh)
warn() {
  echo -e "${YELLOW}⚠ $1${PLAIN}"
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
  if [[ $# -eq 3 ]]; then
    local step_num="$1"
    local total_steps="$2"
    local title="$3"
    echo -e "\n${CYAN}══ [${step_num}/${total_steps}] ${title} ══${PLAIN}"
  else
    local title="$1"
    echo -e "\n${CYAN}══ ${title} ══${PLAIN}"
  fi
}

# Шаг модуля (универсальный): поддержка счетчика
step_module() {
  local step_num="$1"
  local total_steps="$2"
  local title="$3"
  step "$step_num" "$total_steps" "$title"
}
