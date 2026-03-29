#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Manifest                              ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Манифест модулей и порядок их установки                 ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# ── Список доступных модулей / Available Modules ─────────────

# Все доступные модули
AVAILABLE_MODULES=(
  "system"
  "firewall"
  "fail2ban"
  "ssl"
  "s-ui"
  "backup"
  "rollback"
  "monitoring"
)

# Информация о модулях (зависимости, описание)
MODULE_INFO=(
  # Модуль:Состояние:Зависимости:Описание
  "system:system_base:none:Системные настройки (обновления, BBR, проверка IP)"
  "firewall:security_base:none:Файрвол UFW и управление портами"
  "fail2ban:security_base:none:Защита от брутфорса (Fail2ban)"
  "ssl:security_base:firewall:SSL сертификаты (Let's Encrypt)"
  "s-ui:proxy:ssl:Панель управления S-UI со встроенным Sing-box"
  "backup:utility:none:Резервное копирование данных"
  "rollback:utility:none:Откат к предыдущим бэкапам"
  "monitoring:utility:none:Мониторинг системы и сервисов"
)

# ── Порядок установки / Installation Order ─────────────────────

# Порядок модулей для установки (с учётом зависимостей)
DEFAULT_INSTALL_ORDER=(
  "system"     # 1. Базовые системные настройки
  "firewall"   # 2. Файрвол
  "fail2ban"   # 3. Защита от брутфорса
  "ssl"        # 4. SSL сертификаты (зависит от firewall)
  "s-ui"       # 5. S-UI панель (зависит от ssl)
  "backup"     # 6. Бэкап (установка после настройки)
  "rollback"   # 7. Rollback (всегда после backup)
  "monitoring" # 8. Мониторинг (после всех сервисов)
)

# Минимальный набор модулей для базовой установки
MINIMAL_INSTALL_ORDER=(
  "system"
  "firewall"
  "ssl"
  "s-ui"
)

# ── Функции манифеста / Manifest Functions ─────────────────

# Получение информации о модуле
manifest_get_info() {
  local module="$1"

  for info in "${MODULE_INFO[@]}"; do
    IFS=':' read -r mod type deps desc <<<"$info"
    if [[ "$mod" == "$module" ]]; then
      echo "$type|$deps|$desc"
      return 0
    fi
  done

  echo "unknown||Unknown module"
  return 1
}

# Проверка существования модуля
manifest_module_exists() {
  local module="$1"

  for mod in "${AVAILABLE_MODULES[@]}"; do
    if [[ "$mod" == "$module" ]]; then
      return 0
    fi
  done

  return 1
}

# Проверка зависимостей модуля
manifest_check_dependencies() {
  local module="$1"
  local missing_deps=()

  local info
  info=$(manifest_get_info "$module")
  IFS='|' read -r type deps desc <<<"$info"

  if [[ -n "$deps" ]] && [[ "$deps" != "none" ]]; then
    IFS=',' read -ra dep_array <<<"$deps"
    for dep in "${dep_array[@]}"; do
      dep=$(echo "$dep" | xargs) # trim whitespace
      if ! manifest_module_exists "$dep"; then
        missing_deps+=("$dep")
      fi
    done
  fi

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    log_error "Missing dependencies for $module: ${missing_deps[*]}"
    return 1
  fi

  return 0
}

# Проверка порядка установки (topological sort)
manifest_validate_order() {
  local modules=("$@")

  log_step "manifest_validate_order" "Validating module installation order"

  local validated=()
  local modules_copy=("${modules[@]}")

  while [[ ${#modules_copy[@]} -gt 0 ]]; do
    local found=false

    for i in "${!modules_copy[@]}"; do
      local module="${modules_copy[$i]}"

      if manifest_check_dependencies "$module" 2>/dev/null; then
        validated+=("$module")
        unset "modules_copy[$i]"
        found=true
        break
      fi
    done

    if [[ "$found" == "false" ]]; then
      log_warn "Circular dependency detected or missing dependencies"
      return 1
    fi
  done

  log_success "Installation order validated: ${validated[*]}"
}

# Получение порядка установки с учётом зависимостей
# Usage: manifest_get_install_order [modules...]
# shellcheck disable=SC2120
manifest_get_install_order() {
  local modules=("$@")

  # Если модули не указаны, используем дефолтный порядок
  if [[ ${#modules[@]} -eq 0 ]]; then
    echo "${DEFAULT_INSTALL_ORDER[@]}"
    return 0
  fi

  # Валидируем порядок
  if ! manifest_validate_order "${modules[@]}" 2>/dev/null; then
    # Если валидация не удалась, возвращаем дефолтный порядок
    log_warn "Using default installation order"
    echo "${DEFAULT_INSTALL_ORDER[@]}"
    return 1
  fi

  echo "${modules[@]}"
}

# Список всех доступных модулей
manifest_list_all() {
  echo ""
  echo "Available Modules:"
  echo "─────────────────────────────────────────────────────"

  for info in "${MODULE_INFO[@]}"; do
    IFS=':' read -r mod type deps desc <<<"$info"
    echo ""
    echo "  Module:  $mod"
    echo "  Type:    $type"
    echo "  Deps:    ${deps:-none}"
    echo "  Desc:    $desc"
  done

  echo ""
  echo "─────────────────────────────────────────────────────"
  echo ""
}

# Список включённых модулей
manifest_list_enabled() {
  echo ""
  echo "Enabled Modules:"
  echo "─────────────────────────────────────────────────────"

  for mod in "${DEFAULT_INSTALL_ORDER[@]}"; do
    echo "  ✓ $mod"
  done

  echo ""
  echo "─────────────────────────────────────────────────────"
  echo ""
}

# ── Установка модулей / Module Installation ────────────────

# Установка модуля через module_install
manifest_install_module() {
  local module="$1"

  log_step "manifest_install_module" "Installing module: $module"

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
}

# Установка всех модулей в правильном порядке
manifest_install_all() {
  log_step "manifest_install_all" "Installing all modules"

  local modules
  mapfile -t modules < <(manifest_get_install_order)

  for module in "${modules[@]}"; do
    if ! manifest_install_module "$module"; then
      log_error "Failed to install module: $module"
      return 1
    fi
  done

  log_success "All modules installed successfully"
}

# Конфигурация всех модулей
manifest_configure_all() {
  log_step "manifest_configure_all" "Configuring all modules"

  local modules
  mapfile -t modules < <(manifest_get_install_order)

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

# Включение всех модулей
manifest_enable_all() {
  log_step "manifest_enable_all" "Enabling all modules"

  local modules
  mapfile -t modules < <(manifest_get_install_order)

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

# ── Экспорт переменных / Export Variables ─────────────────────

# Экспорт списка модулей для использования в скриптах
export AVAILABLE_MODULES
export DEFAULT_INSTALL_ORDER
export MINIMAL_INSTALL_ORDER

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { :; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }

# Функции манифеста для внешнего использования
module_list() { manifest_list_all; }
module_list_enabled() { manifest_list_enabled; }
module_install_all() { manifest_install_all; }
module_configure_all() { manifest_configure_all; }
module_enable_all() { manifest_enable_all; }
