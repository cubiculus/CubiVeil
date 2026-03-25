#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Modular Installer                     ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модульный установщик с использованием manifest           ║
# ╚═══════════════════════════════════════════════════════════╝

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

# Подключаем manifest
if [[ -f "${SCRIPT_DIR}/lib/manifest.sh" ]]; then
  source "${SCRIPT_DIR}/lib/manifest.sh"
fi

# Подключаем install-steps (новый модульный)
if [[ -f "${SCRIPT_DIR}/lib/install-steps-new.sh" ]]; then
  source "${SCRIPT_DIR}/lib/install-steps-new.sh"
fi

# Подключаем utils
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# Подключаем validation
if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
  source "${SCRIPT_DIR}/lib/validation.sh"
fi

# Подключаем output
if [[ -f "${SCRIPT_DIR}/lib/output.sh" ]]; then
  source "${SCRIPT_DIR}/lib/output.sh"
fi

# Подключаем i18n
if [[ -f "${SCRIPT_DIR}/lib/i18n.sh" ]]; then
  source "${SCRIPT_DIR}/lib/i18n.sh"
fi

# ── Конфигурация установки / Installation Configuration ────

# Режим установки
INSTALL_MODE="full" # full | minimal | custom

# Модули для установки
INSTALL_MODULES=()

# Флаги
FORCE_INSTALL=false
SKIP_CHECKS=false
VERBOSE=false
DRY_RUN=false

# ── Функции установки / Installation Functions ────────────────

# Отображение баннера
show_banner() {
  clear

  echo -e "${CYAN}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║     CubiVeil Modular Installer           ║"
  echo "  ║     github.com/cubiculus/cubiveil        ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo "${PLAIN}"
  echo ""
}

# Выбор режима установки
select_install_mode() {
  echo "Select installation mode:"
  echo ""
  echo "  1) Full installation (recommended)"
  echo "     - All modules: system, firewall, fail2ban, ssl, singbox, marzban"
  echo "     - Plus utilities: backup, rollback, monitoring"
  echo ""
  echo "  2) Minimal installation"
  echo "     - Core only: system, firewall, ssl, singbox, marzban"
  echo "     - Faster, for experienced users"
  echo ""
  echo "  3) Custom installation"
  echo "     - Select modules manually"
  echo ""
  echo "  4) Exit"
  echo ""

  while true; do
    read -rp "  Enter choice [1-4]: " choice

    case "$choice" in
    1)
      INSTALL_MODE="full"
      mapfile -t INSTALL_MODULES < <(manifest_get_install_order)
      return
      ;;
    2)
      INSTALL_MODE="minimal"
      mapfile -t INSTALL_MODULES < <(manifest_get_install_order "${MINIMAL_INSTALL_ORDER[@]}")
      return
      ;;
    3)
      INSTALL_MODE="custom"
      select_custom_modules
      return
      ;;
    4)
      echo "Installation cancelled."
      exit 0
      ;;
    *)
      warn "Invalid choice"
      ;;
    esac
  done
}

# Выбор пользовательских модулей
select_custom_modules() {
  echo ""
  echo "Available modules:"
  echo ""

  manifest_list_all

  echo ""
  echo "Enter module names separated by space:"
  echo "Example: system firewall ssl singbox marzban"
  echo ""

  read -rp "  Modules: " input

  IFS=' ' read -ra INSTALL_MODULES <<<"$input"

  if [[ ${#INSTALL_MODULES[@]} -eq 0 ]]; then
    err "No modules selected"
  fi

  # Валидация модулей
  for module in "${INSTALL_MODULES[@]}"; do
    if ! manifest_module_exists "$module"; then
      err "Unknown module: $module"
    fi
  done

  # Валидация порядка и зависимостей
  if ! manifest_validate_order "${INSTALL_MODULES[@]}" 2>/dev/null; then
    err "Invalid module order or missing dependencies"
  fi

  echo ""
  echo "Selected modules: ${INSTALL_MODULES[*]}"
  echo ""
}

# Выбор языка
select_language() {
  echo ""
  echo "Select language / Выберите язык:"
  echo ""
  echo "  1) Русский (Russian)"
  echo "  2) English"
  echo ""

  while true; do
    read -rp "  Enter choice [1-2]: " lang_choice

    case "$lang_choice" in
    1)
      # shellcheck disable=SC2034
      LANG_NAME="Русский"
      return
      ;;
    2)
      # shellcheck disable=SC2034
      LANG_NAME="English"
      return
      ;;
    *)
      warn "Invalid choice"
      ;;
    esac
  done
}

# Проверка окружения
check_environment() {
  step "Checking environment / Проверка окружения"

  # Проверка root
  check_root

  # Проверка Ubuntu
  check_ubuntu

  # Проверка команд
  require_commands "curl" "wget" "jq" "tar" "systemctl"

  ok "Environment check passed / Проверка окружения пройдена"
}

# Установка модулей через manifest
install_modules() {
  local modules=("$@")

  log_info "Installing modules: ${modules[*]}"

  for module in "${modules[@]}"; do
    local module_file="${SCRIPT_DIR}/lib/modules/${module}/install.sh"

    if [[ ! -f "$module_file" ]]; then
      log_error "Module file not found: $module_file"
      return 1
    fi

    # Подключаем модуль
    # shellcheck source=lib/modules/MODULE/install.sh
    source "$module_file"

    # Проверяем зависимости
    if ! manifest_check_dependencies "$module"; then
      log_error "Missing dependencies for module: $module"
      return 1
    fi

    # Устанавливаем
    if declare -f module_install >/dev/null; then
      module_install
      log_success "Module $module installed"
    else
      log_error "Module $module does not have module_install function"
      return 1
    fi
  done

  log_success "All modules installed successfully"
}

# Конфигурация модулей
configure_modules() {
  local modules=("$@")

  log_info "Configuring modules: ${modules[*]}"

  for module in "${modules[@]}"; do
    local module_file="${SCRIPT_DIR}/lib/modules/${module}/install.sh"

    if [[ -f "$module_file" ]]; then
      # shellcheck source=lib/modules/MODULE/install.sh
      source "$module_file"

      if declare -f module_configure >/dev/null; then
        module_configure
        log_success "Module $module configured"
      fi
    fi
  done

  log_success "All modules configured successfully"
}

# Включение модулей
enable_modules() {
  local modules=("$@")

  log_info "Enabling modules: ${modules[*]}"

  for module in "${modules[@]}"; do
    local module_file="${SCRIPT_DIR}/lib/modules/${module}/install.sh"

    if [[ -f "$module_file" ]]; then
      # shellcheck source=lib/modules/MODULE/install.sh
      source "$module_file"

      if declare -f module_enable >/dev/null; then
        module_enable
        log_success "Module $module enabled"
      fi
    fi
  done

  log_success "All modules enabled successfully"
}

# ── Выполнение установки / Run Installation ─────────────────

# Основная функция установки
run_installation() {
  echo ""
  echo "═══════════════════════════════════════════════════"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  DRY-RUN MODE / Режим симуляции"
    echo "  No changes will be made / Изменения не будут внесены"
    echo "═══════════════════════════════════════════════════"
    echo ""

    log_info "DRY-RUN: Would install CubiVeil with mode: $INSTALL_MODE"
    log_info "DRY-RUN: Would install modules: ${INSTALL_MODULES[*]}"

    # Проверка окружения (без изменений)
    check_environment

    # Симуляция установки модулей
    for module in "${INSTALL_MODULES[@]}"; do
      local module_file="${SCRIPT_DIR}/lib/modules/${module}/install.sh"

      if [[ ! -f "$module_file" ]]; then
        log_error "DRY-RUN: Module file not found: $module_file"
        return 1
      fi

      log_info "DRY-RUN: Would install module: $module"

      # Проверка зависимостей
      if ! manifest_check_dependencies "$module"; then
        log_error "DRY-RUN: Missing dependencies for module: $module"
        return 1
      fi

      log_info "DRY-RUN: Would configure module: $module"
      log_info "DRY-RUN: Would enable module: $module"
    done

    log_success "DRY-RUN: All modules would be installed successfully"

    echo ""
    echo "═══════════════════════════════════════════════════"
    echo "  DRY-RUN Complete / Симуляция завершена"
    echo "═══════════════════════════════════════════════════"
    echo ""

    # Вывод информации
    echo "Modules that would be installed / Модули для установки:"
    echo "────────────────────────────────────────────────────────────"

    for module in "${INSTALL_MODULES[@]}"; do
      local info
      info=$(manifest_get_info "$module")
      IFS='|' read -r type deps desc <<<"$info"
      echo "  ✓ $module - $desc"
    done

    echo "────────────────────────────────────────────────────────────"
    echo ""

    return 0
  fi

  echo "  Starting Installation / Начало установки"
  echo "═══════════════════════════════════════════════════"
  echo ""

  # Проверка окружения
  check_environment

  # Установка модулей
  install_modules "${INSTALL_MODULES[@]}"

  # Конфигурация
  configure_modules "${INSTALL_MODULES[@]}"

  # Включение
  enable_modules "${INSTALL_MODULES[@]}"

  echo ""
  echo "═══════════════════════════════════════════════════"
  echo "  Installation Complete / Установка завершена"
  echo "═══════════════════════════════════════════════════"
  echo ""

  # Вывод информации
  echo "Installed modules / Установленные модули:"
  echo "────────────────────────────────────────────────────────────"

  for module in "${INSTALL_MODULES[@]}"; do
    local info
    info=$(manifest_get_info "$module")
    IFS='|' read -r type deps desc <<<"$info"
    echo "  ✓ $module - $desc"
  done

  echo "────────────────────────────────────────────────────────────"
  echo ""
}

# ── Основная точка входа / Main Entry Point ───────────────

main() {
  show_banner

  # Выбор языка
  select_language

  # Выбор режима установки
  select_install_mode

  # Подтверждение
  echo ""
  echo "You are about to install CubiVeil with mode: $INSTALL_MODE"
  echo "Modules: ${INSTALL_MODULES[*]}"
  echo ""

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Proceeding without confirmation..."
    echo ""
  elif [[ "$FORCE_INSTALL" != "true" ]]; then
    read -rp "Continue? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Installation cancelled."
      exit 0
    fi
  fi

  # Запуск установки
  run_installation

  # Сохранение информации об установке (только не в dry-run)
  if [[ "$DRY_RUN" != "true" ]]; then
    local install_log="/var/log/cubiveil/install.log"
    mkdir -p "$(dirname "$install_log")"

    {
      echo "CubiVeil Installation Log"
      echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
      echo "Mode: $INSTALL_MODE"
      echo "Modules: ${INSTALL_MODULES[*]}"
    } >"$install_log"

    success "✅ Installation complete!"
    echo ""
    echo "For help and troubleshooting, visit:"
    echo "  https://github.com/cubiculus/cubiveil"
    echo ""
  else
    echo ""
    echo "[DRY-RUN] No changes were made to the system."
  fi
}

# ── Обработка аргументов / Argument Parsing ─────────────────

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --mode=MODE      Installation mode (full|minimal|custom)"
  echo "  --modules=MODS   Comma-separated list of modules"
  echo "  --force          Skip confirmation"
  echo "  --skip-checks    Skip environment checks"
  echo "  --verbose        Verbose output"
  echo "  --dry-run        Simulate installation without making changes"
  echo "  --help           Show this help"
  echo ""
  echo "Examples:"
  echo "  $0                          # Interactive mode"
  echo "  $0 --mode=full              # Full installation"
  echo "  $0 --mode=minimal           # Minimal installation"
  echo "  $0 --modules=system,firewall,ssl,singbox,marzban"
  echo "  $0 --dry-run                # Dry-run mode (simulation)"
  echo ""
}

# Парсинг аргументов
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --mode=*)
      INSTALL_MODE="${1#*=}"
      shift
      ;;
    --modules=*)
      IFS=',' read -ra INSTALL_MODULES <<<"${1#*=}"
      INSTALL_MODE="custom"
      shift
      ;;
    --force)
      FORCE_INSTALL=true
      shift
      ;;
    --skip-checks)
      # shellcheck disable=SC2034
      SKIP_CHECKS=true
      shift
      ;;
    --verbose)
      # shellcheck disable=SC2034
      VERBOSE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *)
      err "Unknown option: $1. Use --help for usage."
      ;;
    esac
  done
}

# ── Запуск / Execution ───────────────────────────────────────

# Парсим аргументы
parse_args "$@"

# Запуск main функции
main
