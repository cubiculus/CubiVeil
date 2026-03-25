#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — CLI Utility Manager                   ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Единая точка доступа ко всем утилитам CubiVeil           ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Подключаем i18n модуль для единых функций локализации
if [[ -f "${PROJECT_DIR}/lib/i18n.sh" ]]; then
  source "${PROJECT_DIR}/lib/i18n.sh"
elif [[ -f "${PROJECT_DIR}/lang.sh" ]]; then
  source "${PROJECT_DIR}/lang.sh"
else
  source "${PROJECT_DIR}/lib/fallback.sh"
fi

# ── Константы ─────────────────────────────────────────────────
UTILITIES_DIR="$SCRIPT_DIR"

# ── Локализация ───────────────────────────────────────────────
declare -A MSG=(
  [TITLE]="CubiVeil CLI — Utility Manager"
  [USAGE]="Использование"
  [COMMANDS]="Команды"
  [EXAMPLES]="Примеры"
  [RUNNING]="Запуск"
  [NOT_FOUND]="Утилита не найдена"
  [REQUIRES_ROOT]="Требуется запуск от root"
  [AVAILABLE]="Доступные утилиты"

  [CMD_UPDATE]="update"
  [CMD_ROLLBACK]="rollback"
  [CMD_EXPORT]="export"
  [CMD_MONITOR]="monitor"
  [CMD_DIAGNOSE]="diagnose"
  [CMD_PROFILES]="profiles"
  [CMD_BACKUP]="backup"
  [CMD_HELP]="help"

  [DESC_UPDATE]="Обновление системы до последней версии"
  [DESC_ROLLBACK]="Откат к предыдущей версии"
  [DESC_EXPORT]="Экспорт конфигурации для миграции"
  [DESC_MONITOR]="Мониторинг сервера в реальном времени"
  [DESC_DIAGNOSE]="Диагностика проблем"
  [DESC_PROFILES]="Управление профилями прокси"
  [DESC_BACKUP]="Полное резервное копирование"

  [ERR_NO_ROOT]="❌ Эта команда требует прав root. Запустите с sudo"
  [ERR_NOT_FOUND]="❌ Утилита не найдена"
)

# Функция msg импортируется из lib/i18n.sh

# ── Вспомогательные функции ───────────────────────────────────
print_header() {
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "           $(msg TITLE)"
  echo "══════════════════════════════════════════════════════════"
  echo ""
}

print_utility_list() {
  echo "  $(msg AVAILABLE):"
  echo ""
  printf "  %-12s  %s\n" "$(msg CMD_UPDATE)" "$(msg DESC_UPDATE)"
  printf "  %-12s  %s\n" "$(msg CMD_ROLLBACK)" "$(msg DESC_ROLLBACK)"
  printf "  %-12s  %s\n" "$(msg CMD_EXPORT)" "$(msg DESC_EXPORT)"
  printf "  %-12s  %s\n" "$(msg CMD_MONITOR)" "$(msg DESC_MONITOR)"
  printf "  %-12s  %s\n" "$(msg CMD_DIAGNOSE)" "$(msg DESC_DIAGNOSE)"
  printf "  %-12s  %s\n" "$(msg CMD_PROFILES)" "$(msg DESC_PROFILES)"
  printf "  %-12s  %s\n" "$(msg CMD_BACKUP)" "$(msg DESC_BACKUP)"
  echo ""
}

print_help() {
  print_header

  echo "  $(msg USAGE):"
  echo "    $0 <команда> [аргументы]"
  echo ""

  echo "  $(msg COMMANDS):"
  echo ""
  print_utility_list

  echo "  Опции:"
  echo "    --help, -h      Показать эту справку"
  echo "    --list, -l      Список доступных утилит"
  echo ""

  echo "  $(msg EXAMPLES):"
  echo ""
  echo "    # Обновить систему"
  echo "    sudo $0 update"
  echo ""
  echo "    # Запустить мониторинг"
  echo "    sudo $0 monitor"
  echo ""
  echo "    # Создать бэкап"
  echo "    sudo $0 backup create"
  echo ""
  echo "    # Список профилей"
  echo "    sudo $0 profiles list"
  echo ""
  echo "    # Диагностика"
  echo "    sudo $0 diagnose"
  echo ""
  echo "  ───────────────────────────────────────────────────────────"
  echo "  Прямой запуск утилит:"
  echo ""
  echo "    sudo bash update.sh"
  echo "    sudo bash backup.sh create"
  echo "    sudo bash manage-profiles.sh list"
  echo ""
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "$(msg ERR_NO_ROOT)"
    exit 1
  fi
}

# ── Функции запуска утилит ────────────────────────────────────

run_update() {
  check_root
  if [[ -f "${UTILITIES_DIR}/update.sh" ]]; then
    bash "${UTILITIES_DIR}/update.sh" "$@"
  else
    echo "$(msg ERR_NOT_FOUND): update.sh"
    exit 1
  fi
}

run_rollback() {
  check_root
  if [[ -f "${UTILITIES_DIR}/rollback.sh" ]]; then
    bash "${UTILITIES_DIR}/rollback.sh" "$@"
  else
    echo "$(msg ERR_NOT_FOUND): rollback.sh"
    exit 1
  fi
}

run_export() {
  check_root
  if [[ -f "${UTILITIES_DIR}/export-config.sh" ]]; then
    bash "${UTILITIES_DIR}/export-config.sh" "$@"
  else
    echo "$(msg ERR_NOT_FOUND): export-config.sh"
    exit 1
  fi
}

run_monitor() {
  check_root
  if [[ -f "${UTILITIES_DIR}/monitor.sh" ]]; then
    bash "${UTILITIES_DIR}/monitor.sh" "$@"
  else
    echo "$(msg ERR_NOT_FOUND): monitor.sh"
    exit 1
  fi
}

run_diagnose() {
  check_root
  if [[ -f "${UTILITIES_DIR}/diagnose.sh" ]]; then
    bash "${UTILITIES_DIR}/diagnose.sh" "$@"
  else
    echo "$(msg ERR_NOT_FOUND): diagnose.sh"
    exit 1
  fi
}

run_profiles() {
  check_root
  if [[ -f "${UTILITIES_DIR}/manage-profiles.sh" ]]; then
    bash "${UTILITIES_DIR}/manage-profiles.sh" "$@"
  else
    echo "$(msg ERR_NOT_FOUND): manage-profiles.sh"
    exit 1
  fi
}

run_backup() {
  check_root
  if [[ -f "${UTILITIES_DIR}/backup.sh" ]]; then
    bash "${UTILITIES_DIR}/backup.sh" "$@"
  else
    echo "$(msg ERR_NOT_FOUND): backup.sh"
    exit 1
  fi
}

# ── Основная функция ──────────────────────────────────────────

main() {
  select_language

  local command="${1:-help}"
  shift || true

  case "$command" in
  update | u)
    run_update "$@"
    ;;
  rollback | rb)
    run_rollback "$@"
    ;;
  export | exp)
    run_export "$@"
    ;;
  monitor | mon)
    run_monitor "$@"
    ;;
  diagnose | diag)
    run_diagnose "$@"
    ;;
  profiles | prof | p)
    run_profiles "$@"
    ;;
  backup | bak | b)
    run_backup "$@"
    ;;
  help | --help | -h | h)
    print_help
    ;;
  list | --list | -l)
    print_header
    print_utility_list
    ;;
  *)
    echo "❌ Неизвестная команда: $command"
    echo ""
    print_help
    exit 1
    ;;
  esac
}

main "$@"
