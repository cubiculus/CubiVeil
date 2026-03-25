#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Migration Script                   ║
# ║          github.com/cubiculus/cubiveil                   ║
# ╚═════════════════════════════════════════════════════════════╝

set -e

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# ── Конфигурация миграции / Migration Configuration ─────────

BACKUP_DIR="/var/backups/cubiveil/migration"
LEGACY_INSTALL_STEPS="${SCRIPT_DIR}/lib/install-steps.sh.backup"
NEW_INSTALLER="${SCRIPT_DIR}/install-modular.sh"

# ── Баннер / Banner ────────────────────────────────────────

show_banner() {
  clear

  echo -e "${CYAN}"
  echo ""
  echo "  ╔═════════════════════════════════════════════════════╗"
  echo "  ║                                                     ║"
  echo "  ║      CubiVeil — Migration to Modular Architecture      ║"
  echo "  ║      github.com/cubiculus/cubiveil                     ║"
  echo "  ║                                                     ║"
  echo "  ╚═════════════════════════════════════════════════════╝"
  echo "${PLAIN}"
  echo ""
}

# ── Проверка окружения / Environment Check ─────────────────

check_migration_prerequisites() {
  log_step "check_migration_prerequisites" "Checking migration prerequisites"

  local issues=0

  # Проверка наличия старого install-steps.sh
  if [[ ! -f "$LEGACY_INSTALL_STEPS" ]]; then
    log_warn "Legacy install-steps.sh not found, may already be migrated"
    ((issues++))
  fi

  # Проверка наличия нового модульного установщика
  if [[ ! -f "$NEW_INSTALLER" ]]; then
    log_warn "New modular installer not found: $NEW_INSTALLER"
    ((issues++))
  fi

  # Проверка наличия manifest.sh
  if [[ ! -f "${SCRIPT_DIR}/lib/manifest.sh" ]]; then
    log_error "Manifest not found"
    ((issues++))
  fi

  # Проверка наличия модулей
  local required_modules=("system" "firewall" "ssl" "singbox" "marzban")
  for module in "${required_modules[@]}"; do
    local module_file="${SCRIPT_DIR}/lib/modules/${module}/install.sh"
    if [[ ! -f "$module_file" ]]; then
      log_warn "Module not found: $module"
      ((issues++))
    fi
  done

  if [[ $issues -gt 0 ]]; then
    log_error "Migration prerequisites check failed: $issues issues"
    return 1
  fi

  log_success "All migration prerequisites met"
}

# ── Бэкап текущей конфигурации / Backup Current Config ─────

backup_current_config() {
  log_step "backup_current_config" "Backing up current configuration"

  dir_ensure "$BACKUP_DIR"

  # Бэкап .env Marzban если есть
  if [[ -f "/opt/marzban/.env" ]]; then
    cp "/opt/marzban/.env" "${BACKUP_DIR}/marzban.env.backup"
    log_info "Backed up Marzban .env"
  fi

  # Бэкап шаблона Sing-box если есть
  if [[ -f "/var/lib/marzban/sing-box-template.json" ]]; then
    cp "/var/lib/marzban/sing-box-template.json" "${BACKUP_DIR}/sing-box-template.json.backup"
    log_info "Backed up Sing-box template"
  fi

  # Бэкап конфигурации UFW если есть
  if [[ -f "/etc/ufw/user.rules" ]]; then
    cp "/etc/ufw/user.rules" "${BACKUP_DIR}/ufw-user-rules.backup"
    log_info "Backed up UFW user rules"
  fi

  # Сохраняем список установленных пакетов
  dpkg -l 2>/dev/null | grep -E "(marzban|sing-box|ufw|fail2ban)" > "${BACKUP_DIR}/installed-packages.txt"

  log_success "Current configuration backed up"
}

# ── Восстановление из бэкапа / Restore from Backup ─────

restore_config() {
  log_step "restore_config" "Restoring from backup"

  local restored=0

  # Восстанавливаем .env Marzban
  if [[ -f "${BACKUP_DIR}/marzban.env.backup" ]]; then
    cp "${BACKUP_DIR}/marzban.env.backup" "/opt/marzban/.env"
    log_info "Restored Marzban .env"
    ((restored++))
  fi

  # Восстанавливаем шаблон Sing-box
  if [[ -f "${BACKUP_DIR}/sing-box-template.json.backup" ]]; then
    cp "${BACKUP_DIR}/singbox-template.json.backup" "/var/lib/marzban/sing-box-template.json"
    log_info "Restored Sing-box template"
    ((restored++))
  fi

  # Восстанавливаем UFW правила
  if [[ -f "${BACKUP_DIR}/ufw-user-rules.backup" ]]; then
    cp "${BACKUP_DIR}/ufw-user-rules.backup" "/etc/ufw/user.rules"
    log_info "Restored UFW user rules"
    ((restored++))
  fi

  if [[ $restored -gt 0 ]]; then
    log_success "Restored $restored configuration files"
  else
    log_warn "No backup files found to restore"
  fi
}

# ── Очистка старых временных файлов / Cleanup ─────────────

cleanup_temp_files() {
  log_step "cleanup_temp_files" "Cleaning up temporary files"

  # Удаляем временные файлы из предыдущих миграций
  find /tmp/cubiveil* -mtime +7 -delete 2>/dev/null || true

  log_success "Temporary files cleaned up"
}

# ── Проверка статуса миграции / Migration Status Check ─────

check_migration_status() {
  log_step "check_migration_status" "Checking migration status"

  local migrated=0

  # Проверяем наличие новых модулей
  local modules=("system" "firewall" "ssl" "singbox" "marzban")
  for module in "${modules[@]}"; do
    if [[ -f "${SCRIPT_DIR}/lib/modules/${module}/install.sh" ]]; then
      ((migrated++))
    fi
  done

  echo ""
  echo "Migration status:"
  echo "────────────────"
  echo "  Modules found: $migrated / ${#modules[@]}"
  echo "  Modules required: ${#modules[@]}"
  echo ""

  if [[ $migrated -eq ${#modules[@]} ]]; then
    echo "  Status: ✓ All modules present"
    echo "────────────────"
    return 0
  else
    echo "  Status: ✗ Some modules missing"
    echo "────────────────"
    return 1
  fi
}

# ── Основная миграция / Main Migration ─────────────────────────

run_migration() {
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Starting Migration to Modular Architecture"
  echo "═════════════════════════════════════════════════════════"
  echo ""

  # Проверка окружения
  if ! check_migration_prerequisites; then
    err "Migration prerequisites check failed"
  fi

  # Проверка текущего статуса
  if ! check_migration_status; then
    echo ""
    read -rp "Continue anyway? (y/n): " continue
    [[ "$continue" != "y" && "$continue" != "Y" ]] && exit 0
  fi

  # Бэкап текущей конфигурации
  backup_current_config

  # Очистка временных файлов
  cleanup_temp_files

  echo ""
  info "Migration will:"
  echo "  1) Create backups of current configuration"
  echo "  2. Install/update modules using manifest"
  echo "  3. Verify all components are working"
  echo ""

  read -rp "Proceed with migration? (y/n): " proceed
  [[ "$proceed" != "y" && "$proceed" != "Y" ]] && exit 0

  echo ""
  echo "Migration in progress..."

  # Запускаем новый модульный установщик
  if ! bash "$NEW_INSTALLER" --mode=full; then
    echo ""
    err "Migration failed! Check logs for details."
    echo ""
    echo "Would you like to:"
    echo "  1) Restore from backup?"
    echo "   2) Exit and investigate?"
    echo ""
    read -rp "Choose [1-2]: " choice

    case "$choice" in
      1)
        echo ""
        info "Restoring from backup..."
        restore_config
        success "✅ Configuration restored"
        ;;
      2)
        echo ""
        exit 1
        ;;
    esac
  fi

  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "  Migration Complete"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  success "✅ Migration completed successfully!"
  echo ""
  echo "Next steps:"
  echo "  1. Run tests: ./tests/integration-test.sh"
  echo "  2. Verify all services are working"
  echo "  3. Update utils to use new modules"
  echo ""
}

# ── Rollback миграции / Rollback Migration ───────────────────

run_rollback() {
  echo ""
  echo "═════════════════════════════════════════════════════════"
  echo "  Migration Rollback"
  echo "═════════════════════════════════════════════════════════"
  echo ""

  # Восстанавливаем конфигурацию
  restore_config

  echo ""
  success "✅ Configuration restored from backup"
  echo ""
  echo "The system has been rolled back to pre-migration state."
  echo ""
}

# ── Главное меню / Main Menu ─────────────────────────────

show_menu() {
  echo ""
  echo "Select action:"
  echo ""
  echo "  1) Run migration"
  echo "  2) Check migration status"
  echo "  3) Rollback migration"
  echo " 4) Exit"
  echo ""
}

# ── Основная точка входа / Main Entry Point ───────────────

main() {
  show_banner

  while true; do
    show_menu

    read -rp "  Select action [1-4]: " choice

    case "$choice" in
      1)
        run_migration
        ;;
      2)
        check_migration_status
        ;;
      3)
        run_rollback
        ;;
      4)
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
