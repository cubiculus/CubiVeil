#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Backup Utility (Modular)              ║
# ║          github.com/cubiculus/cubiveil                    ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# Подключаем backup модуль
if [[ -f "${SCRIPT_DIR}/lib/modules/backup/install.sh" ]]; then
  source "${SCRIPT_DIR}/lib/modules/backup/install.sh"
fi

# ── Баннер / Banner ────────────────────────────────────────

print_banner_utility() {
  clear
  echo ""
  echo -e "${CYAN}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║     CubiVeil — Backup Utility             ║"
  echo "  ║     github.com/cubiculus/cubiveil         ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo "${PLAIN}"
  echo ""
}

# ── Список утилит / Utility List ───────────────────────

print_utility_list() {
  echo ""
  echo "Available actions:"
  echo "  1) Create backup"
  echo "  2) Quick backup (without stopping services)"
  echo "  3) List backups"
  echo "  4) Cleanup old backups"
  echo "  5) Exit"
  echo ""
}

# ── Создание бэкапа / Create Backup ─────────────────────

run_backup() {
  step "Creating full backup / Создание полного бэкапа"

  # Используем модульный интерфейс
  module_backup

  success "✅ Backup completed / Бэкап создан"
}

# ── Быстрый бэкап / Quick Backup ─────────────────────

run_quick_backup() {
  step "Creating quick backup / Создание быстрого бэкапа"

  # Используем модульный интерфейс
  module_quick_backup

  success "✅ Quick backup completed / Быстрый бэкап создан"
}

# ── Список бэкапов / List Backups ─────────────────────

run_list() {
  module_list
}

# ── Очистка / Cleanup ─────────────────────────────────────

run_cleanup() {
  step "Cleaning up old backups / Очистка старых бэкапов"

  module_cleanup

  success "✅ Cleanup completed / Очистка завершена"
}

# ── Основная точка входа / Main Entry Point ───────────────

main() {
  print_banner_utility

  while true; do
    print_utility_list

    read -rp "  Select action [1-5]: " choice

    case "$choice" in
    1)
      run_backup
      ;;
    2)
      run_quick_backup
      ;;
    3)
      run_list
      ;;
    4)
      run_cleanup
      ;;
    5)
      echo "Exiting..."
      exit 0
      ;;
    *)
      warn "Invalid choice"
      ;;
    esac

    echo ""
    read -rp "Press Enter to continue..."
  done
}

# Запуск
main
