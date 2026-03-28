#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Core Logging Functions                ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Общие функции логирования для всех модулей               ║
# ║  - Логирование в файл                                     ║
# ║  - Вывод сообщений с уровнями                             ║
# ║  - Отслеживание прогресса                                 ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Конфигурация логирования / Logging Configuration ───────

# Путь к лог-файлу по умолчанию
# shellcheck disable=SC2034
CUBIVEIL_LOG_DIR="/var/log/cubiveil"
CUBIVEIL_LOG_FILE="${CUBIVEIL_LOG_FILE:-/var/log/cubiveil/install.log}"
CUBIVEIL_LOG_LEVEL="${CUBIVEIL_LOG_LEVEL:-INFO}"

# Уровни логирования
# shellcheck disable=SC2034
LOG_LEVEL_DEBUG=0
# shellcheck disable=SC2034
LOG_LEVEL_INFO=1
# shellcheck disable=SC2034
LOG_LEVEL_WARN=2
# shellcheck disable=SC2034
LOG_LEVEL_ERROR=3

# Цвета для консоли (переопределяются из output.sh)
if [[ -z "${RED:-}" ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  # shellcheck disable=SC2034
  CYAN='\033[0;36m'
  PLAIN='\033[0m'
fi

# Собираем предупреждения для итогового блока
WARNINGS=()

# Внутренние log_step (submodule) можно отключить, чтобы не показывать слишком много разделителей
CUBIVEIL_HIDE_LOG_STEP="true"


# ── Инициализация логирования / Logging Initialization ────

# Инициализация лог-системы
log_init() {
  local log_file="${1:-$CUBIVEIL_LOG_FILE}"

  # Создаём директорию для логов если нужно
  local log_dir
  log_dir=$(dirname "$log_file")
  if [[ ! -d "$log_dir" ]]; then
    mkdir -p "$log_dir"
  fi

  # Устанавливаем права
  chmod 750 "$log_dir" 2>/dev/null || true

  # Создаём/очищаем лог-файл
  touch "$log_file"
  chmod 640 "$log_file" 2>/dev/null || true

  # Записываем заголовок сессии
  echo "" >>"$log_file"
  echo "══════════════════════════════════════════════════════════" >>"$log_file"
  echo "  CubiVeil Installation Session" >>"$log_file"
  echo "  Start: $(date '+%Y-%m-%d %H:%M:%S')" >>"$log_file"
  echo "  User: $(whoami)@$(hostname)" >>"$log_file"
  echo "══════════════════════════════════════════════════════════" >>"$log_file"
  echo "" >>"$log_file"

  CUBIVEIL_LOG_FILE="$log_file"
}

# ── Базовые функции логирования / Basic Logging Functions ─

# Запись сообщения в лог с уровнем
_log_write() {
  local level="$1"
  local message="$2"
  local log_file="${3:-$CUBIVEIL_LOG_FILE}"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] [$level] ${message}" >>"$log_file"
}

# Логирование уровня DEBUG
log_debug() {
  [[ "$CUBIVEIL_LOG_LEVEL" != "DEBUG" ]] && return 0
  _log_write "DEBUG" "$*"
}

# Логирование уровня INFO
log_info() {
  _log_write "INFO" "$*"
}

# Логирование уровня WARN
log_warn() {
  _log_write "WARN" "$*"
}

# Логирование уровня ERROR
log_error() {
  _log_write "ERROR" "$*"
}

# Логирование уровня SUCCESS
log_success() {
  _log_write "SUCCESS" "$*"
}

# ── Логирование с выводом в консоль / Console Logging ────
# Эти функции комбинируют вывод в консоль и логирование
# Для простого вывода используйте функции из output.sh

# Информационное сообщение (консоль + лог)
log_console_info() {
  echo -e "ℹ️  $*"
  log_info "$*"
}

# Успешное сообщение (консоль + лог)
log_console_success() {
  echo -e "${GREEN}✅${PLAIN} $*"
  log_success "$*"
}

# Предупреждение (консоль + лог)
log_console_warning() {
  local msg="$*"
  echo -e "${YELLOW}⚠️${PLAIN} ${msg}"
  log_warn "${msg}"
  WARNINGS+=("${msg}")
}

# Ошибка (консоль + лог)
log_console_error() {
  echo -e "${RED}❌${PLAIN} $*" >&2
  log_error "$*"
}

# ── Функции совместимости / Compatibility Functions ────────
# Удалены дублирующие info(), success(), warning(), err(), ok(), warn()
# Используйте функции из lib/output.sh для простого вывода
# Используйте log_console_*() для вывода с логированием

# ── Логирование выполнения команд / Command Logging ───────

# Выполнение команды с логированием
# Использование: log_run "описание" "команда"
log_run() {
  local description="$1"
  shift
  local cmd=("$@")

  log_info "Running: ${description}"
  log_debug "Command: ${cmd[*]}"

  local output
  local exit_code

  # Выполняем команду и захватываем вывод
  output=$("${cmd[@]}" 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log_success "${description}: OK"
  else
    log_error "${description}: FAILED (exit code ${exit_code})"
    log_error "Output: ${output}"
  fi

  return $exit_code
}

# Выполнение команды с выводом в реальном времени
# Использование: log_run_verbose "описание" "команда"
log_run_verbose() {
  local description="$1"
  shift
  local cmd=("$@")

  log_info "Running: ${description}"
  echo -e "${BLUE}▶${PLAIN} ${description}"

  "${cmd[@]}"
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log_console_success "${description}: OK"
  else
    log_console_error "${description}: FAILED (exit code ${exit_code})"
  fi

  return $exit_code
}

# ── Логирование прогресса / Progress Logging ──────────────

# Заголовок шага с логированием
# Использование: log_step_title "номер" "описание на русском" "описание на английском"
log_step_title() {
  local step="$1"
  local ru="$2"
  local en="$3"

  echo ""
  echo "══════════════════════════════════════════════════════════"
  if [[ "${LANG_NAME:-}" == "Русский" ]]; then
    echo "  ${step}. ${ru}"
    log_info "Step ${step}: ${ru}"
  else
    echo "  ${step}. ${en}"
    log_info "Step ${step}: ${en}"
  fi
  echo "══════════════════════════════════════════════════════════"
}

# Простой заголовок шага с логированием (совместимость)
log_step() {
  local step_key="$1"
  local msg="${2:-$1}"

  # Показываем визуальный разделитель только для верхнего уровня (по умолчанию скрыто)
  if [[ "${CUBIVEIL_HIDE_LOG_STEP:-true}" != "true" ]]; then
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e "${BLUE}  ${msg}${PLAIN}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  else
    echo -e "· ${msg}"
  fi

  log_info "${msg}"
}

# ── Функции совместимости / Compatibility Functions ────────
# Удалены дублирующие step_title() и step()
# Используйте функции из lib/output.sh для простого вывода
# Используйте log_step_title() и log_step() для вывода с логированием

# ── Логирование с контекстом / Contextual Logging ─────────

# Логирование с контекстом модуля
# Использование: log_module "module_name" "message"
log_module() {
  local module="$1"
  shift
  local message="$*"

  _log_write "INFO" "[${module}] ${message}"
}

# Логирование выполнения шага (с контекстом)
# Использование: log_step "step_name" "message"
# Примечание: существует также log_step(msg) без контекста для совместимости
log_step_with_context() {
  local step_name="$1"
  shift
  local message="$*"

  _log_write "INFO" "[${step_name}] ${message}"
}

# ── Статистика и отчёты / Statistics & Reports ────────────

# Запись метрики
# Использование: log_metric "metric_name" "value"
log_metric() {
  local metric_name="$1"
  local metric_value="$2"
  local metric_file="/var/log/cubiveil/metrics.log"

  mkdir -p "$(dirname "$metric_file")" 2>/dev/null || true

  echo "$(date '+%Y-%m-%d %H:%M:%S') ${metric_name}=${metric_value}" >>"$metric_file"
}

# Запись времени выполнения
# Использование: log_timer_start "operation_name"
log_timer_start() {
  local name="$1"
  local start_time

  start_time=$(date +%s)
  echo "TIMER_${name}=${start_time}" >/tmp/cubiveil_timer_${name}
}

# Завершение таймера и логирование
# Использование: log_timer_stop "operation_name"
log_timer_stop() {
  local name="$1"
  local timer_file="/tmp/cubiveil_timer_${name}"
  local end_time start_time duration

  if [[ -f "$timer_file" ]]; then
    start_time=$(grep "TIMER_${name}=" "$timer_file" | cut -d= -f2)
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    log_info "Timer ${name}: ${duration}s"

    rm -f "$timer_file"
  fi
}

# ── Утилиты работы с логами / Log Utilities ──────────────

# Чтение последних N строк лога
# Использование: log_tail "количество_строк"
log_tail() {
  local lines="${1:-50}"
  tail -n "$lines" "$CUBIVEIL_LOG_FILE" 2>/dev/null || echo "No log file found"
}

# Поиск в логах
# Использование: log_search "шаблон"
log_search() {
  local pattern="$1"
  grep -i "$pattern" "$CUBIVEIL_LOG_FILE" 2>/dev/null || echo "No matches found"
}

# Очистка лога (с архивацией)
log_rotate() {
  local log_file="$CUBIVEIL_LOG_FILE"

  if [[ -f "$log_file" ]]; then
    local archive_name
    archive_name="${log_file}.$(date +%Y%m%d_%H%M%S).old"

    mv "$log_file" "$archive_name"
    gzip "$archive_name" 2>/dev/null || true

    log_init "$log_file"
    log_info "Log rotated, previous archived to ${archive_name}.gz"
  fi
}

# ── Отладка / Debugging ─────────────────────────────────────

# Режим отладки
debug_on() {
  CUBIVEIL_LOG_LEVEL="DEBUG"
  log_info "Debug mode enabled"
}

debug_off() {
  CUBIVEIL_LOG_LEVEL="INFO"
  log_info "Debug mode disabled"
}

# Вывод переменных окружения для отладки
log_env() {
  log_info "=== Environment Variables ==="
  env | sort | while read -r line; do
    log_debug "$line"
  done
}
