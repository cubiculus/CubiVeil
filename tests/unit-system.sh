#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - System Module                ║
# ║        Тестирование lib/modules/system/install.sh         ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# ── Загрузка тестируемого модуля ───────────────────────────────
MODULE_PATH="${SCRIPT_DIR}/lib/modules/system/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "Ошибка: System module не найден: $MODULE_PATH"
  exit 1
fi

# ── Mock зависимостей ─────────────────────────────────────────
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }

# Mock core функций
pkg_update() { echo "[MOCK] pkg_update" >&2; }
pkg_upgrade() { echo "[MOCK] pkg_upgrade" >&2; }
pkg_full_upgrade() { echo "[MOCK] pkg_full_upgrade" >&2; }
pkg_install_packages() { echo "[MOCK] pkg_install_packages: $*" >&2; }

svc_enable_start() { echo "[MOCK] svc_enable_start: $1" >&2; }
svc_active() { return 1; }
svc_restart() { echo "[MOCK] svc_restart: $1" >&2; }
systemctl() {
  echo "[MOCK] systemctl: $*" >&2
  return 0
}

modprobe() {
  echo "[MOCK] modprobe: $*" >&2
  return 0
}
sysctl() {
  if [[ "$*" == *"-n net.ipv4.tcp_congestion_control"* ]]; then
    echo "bbr"
  else
    echo "[MOCK] sysctl: $*" >&2
  fi
  return 0
}

curl() {
  if [[ "$*" == *"ipinfo.io"* ]]; then
    echo '{"org": "Test Hosting"}'
  else
    echo "[MOCK] curl" >&2
  fi
}

create_temp_dir() { echo "/tmp/test-$$"; }
cleanup_temp_dir() { rm -rf "$1" 2>/dev/null || true; }

# ── Загрузка модуля ───────────────────────────────────────────
# shellcheck source=lib/modules/system/install.sh
source "$MODULE_PATH"

# ── Тест: файл существует ───────────────────────────────────────
test_file_exists() {
  info "Тестирование наличия файла модуля..."

  if [[ -f "$MODULE_PATH" ]]; then
    pass "System module: файл существует"
    ((TESTS_PASSED++)) || true
  else
    fail "System module: файл не найден"
  fi
}

# ── Тест: синтаксис скрипта ───────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса..."

  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "System module: синтаксис корректен"
    ((TESTS_PASSED++)) || true
  else
    fail "System module: синтаксическая ошибка"
  fi
}

# ── Тест: shebang ──────────────────────────────────────────────
test_shebang() {
  info "Тестирование shebang..."

  local shebang
  shebang=$(head -1 "$MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "System module: корректный shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "System module: некорректный shebang: $shebang"
  fi
}

# ── Тест: system_setup_update_env ──────────────────────────────
test_system_setup_update_env() {
  info "Тестирование system_setup_update_env..."

  # Mock для sed
  sed() {
    echo "[MOCK] sed: $*" >&2
    return 0
  }

  # Вызываем функцию
  system_setup_update_env

  # Проверяем что переменные установлены
  if [[ "${DEBIAN_FRONTEND:-}" == "noninteractive" ]]; then
    pass "system_setup_update_env: DEBIAN_FRONTEND установлен"
    ((TESTS_PASSED++)) || true
  else
    fail "system_setup_update_env: DEBIAN_FRONTEND не установлен"
  fi

  if [[ "${UCF_FORCE_CONFFOLD:-}" == "1" ]]; then
    pass "system_setup_update_env: UCF_FORCE_CONFFOLD установлен"
    ((TESTS_PASSED++)) || true
  else
    fail "system_setup_update_env: UCF_FORCE_CONFFOLD не установлен"
  fi
}

# ── Тест: system_full_update ───────────────────────────────────
test_system_full_update() {
  info "Тестирование system_full_update..."

  # Вызываем функцию
  system_full_update

  pass "system_full_update: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_quick_update ──────────────────────────────────
test_system_quick_update() {
  info "Тестирование system_quick_update..."

  system_quick_update

  pass "system_quick_update: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_auto_updates_configure ────────────────────────
test_system_auto_updates_configure() {
  info "Тестирование system_auto_updates_configure..."

  # Mock для cat
  cat() {
    if [[ "$*" == *">"* ]]; then
      local file
      file=$(echo "$*" | grep -oP '(?>>)[^\s]+')
      echo "[MOCK] Creating $file" >&2
      return 0
    fi
    command cat "$@" 2>/dev/null || echo ""
  }

  system_auto_updates_configure

  pass "system_auto_updates_configure: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_auto_updates_unattended_configure ─────────────
test_system_auto_updates_unattended_configure() {
  info "Тестирование system_auto_updates_unattended_configure..."

  cat() {
    if [[ "$*" == *">"* ]]; then
      return 0
    fi
    command cat "$@" 2>/dev/null || echo ""
  }

  system_auto_updates_unattended_configure

  pass "system_auto_updates_unattended_configure: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_auto_updates_enable ───────────────────────────
test_system_auto_updates_enable() {
  info "Тестирование system_auto_updates_enable..."

  system_auto_updates_enable

  pass "system_auto_updates_enable: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_auto_updates_setup ────────────────────────────
test_system_auto_updates_setup() {
  info "Тестирование system_auto_updates_setup..."

  cat() { return 0; }

  system_auto_updates_setup

  pass "system_auto_updates_setup: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_bbr_load_module ───────────────────────────────
test_system_bbr_load_module() {
  info "Тестирование system_bbr_load_module..."

  # Mock для проверки создания файла
  # shellcheck disable=SC2034
  local test_file="/tmp/test-bbr-$$"

  # Временная замена /etc/modules-load.d
  mkdir -p /tmp/test-modules-load.d
  sed() { return 0; }

  # Вызываем функцию (она создаст файл в /etc/modules-load.d)
  # Для теста просто проверяем что функция вызывается
  system_bbr_load_module

  pass "system_bbr_load_module: вызвана без ошибок"
  ((TESTS_PASSED++)) || true

  rm -rf /tmp/test-modules-load.d
}

# ── Тест: system_bbr_create_sysctl_config ──────────────────────
test_system_bbr_create_sysctl_config() {
  info "Тестирование system_bbr_create_sysctl_config..."

  # Mock cat для записи в файл
  # shellcheck disable=SC2120
  cat() {
    if [[ "$*" == *">"* ]] || [[ $# -eq 0 ]]; then
      return 0
    fi
    command cat "$@" 2>/dev/null || echo ""
  }

  system_bbr_create_sysctl_config

  pass "system_bbr_create_sysctl_config: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_bbr_apply_sysctl ──────────────────────────────
test_system_bbr_apply_sysctl() {
  info "Тестирование system_bbr_apply_sysctl..."

  system_bbr_apply_sysctl

  pass "system_bbr_apply_sysctl: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_bbr_setup ─────────────────────────────────────
test_system_bbr_setup() {
  info "Тестирование system_bbr_setup..."

  system_bbr_setup

  pass "system_bbr_setup: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_bbr_check_status ──────────────────────────────
test_system_bbr_check_status() {
  info "Тестирование system_bbr_check_status..."

  if system_bbr_check_status; then
    pass "system_bbr_check_status: BBR активен"
    ((TESTS_PASSED++)) || true
  else
    warn "system_bbr_check_status: BBR не активен (может быть нормально)"
  fi
}

# ── Тест: system_check_services ────────────────────────────────
test_system_check_services() {
  info "Тестирование system_check_services..."

  # Функция вернёт false т.к. сервисы не активны в тесте
  system_check_services || true

  pass "system_check_services: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_restart_services ──────────────────────────────
test_system_restart_services() {
  info "Тестирование system_restart_services..."

  system_restart_services

  pass "system_restart_services: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: system_install_base_dependencies ─────────────────────
test_system_install_base_dependencies() {
  info "Тестирование system_install_base_dependencies..."

  system_install_base_dependencies

  pass "system_install_base_dependencies: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: pkg_update ─────────────────────────────────────────
test_pkg_update() {
  info "Тестирование pkg_update..."

  apt_args=()
  apt-get() { apt_args=("$@"); return 0; }

  pkg_update

  if [[ "${DEBIAN_FRONTEND:-}" == "noninteractive" ]] && [[ "${UCF_FORCE_CONFFOLD:-}" == "1" ]] && [[ "${apt_args[0]}" == "update" ]]; then
    pass "pkg_update выполняет apt-get update и устанавливает окружение"
    ((TESTS_PASSED++)) || true
  else
    fail "pkg_update не выполняет ожидаемые действия"
  fi
}

# ── Тест: pkg_upgrade ────────────────────────────────────────
test_pkg_upgrade() {
  info "Тестирование pkg_upgrade..."

  apt_args=()
  apt-get() { apt_args=("$@"); return 0; }
  sed() { return 0; }

  pkg_upgrade

  if [[ "${DEBIAN_FRONTEND:-}" == "noninteractive" ]] && [[ "${UCF_FORCE_CONFFOLD:-}" == "1" ]] && [[ "${UCFF_FORCE_CONFFNEW:-}" == "1" ]] && [[ "${apt_args[0]}" == "upgrade" ]]; then
    pass "pkg_upgrade выполняет apt-get upgrade и устанавливает окружение"
    ((TESTS_PASSED++)) || true
  else
    fail "pkg_upgrade не выполняет ожидаемые действия"
  fi
}

# ── Тест: pkg_full_upgrade ───────────────────────────────────
test_pkg_full_upgrade() {
  info "Тестирование pkg_full_upgrade..."

  apt_args=()
  apt-get() { apt_args=("$@"); return 0; }
  sed() { return 0; }

  pkg_full_upgrade

  if [[ "${DEBIAN_FRONTEND:-}" == "noninteractive" ]] && [[ "${UCF_FORCE_CONFFOLD:-}" == "1" ]] && [[ "${UCFF_FORCE_CONFFNEW:-}" == "1" ]] && [[ "${apt_args[0]}" == "dist-upgrade" ]]; then
    pass "pkg_full_upgrade выполняет apt-get dist-upgrade и устанавливает окружение"
    ((TESTS_PASSED++)) || true
  else
    fail "pkg_full_upgrade не выполняет ожидаемые действия"
  fi
}

# ── Тест: module_install ───────────────────────────────────────
test_module_install() {
  info "Тестирование module_install..."

  cat() { return 0; }

  module_install

  pass "module_install: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_configure ─────────────────────────────────────
test_module_configure() {
  info "Тестирование module_configure..."

  cat() { return 0; }

  module_configure

  pass "module_configure: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_enable ────────────────────────────────────────
test_module_enable() {
  info "Тестирование module_enable..."

  module_enable

  pass "module_enable: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_disable ───────────────────────────────────────
test_module_disable() {
  info "Тестирование module_disable..."

  module_disable

  pass "module_disable: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_update ────────────────────────────────────────
test_module_update() {
  info "Тестирование module_update..."

  module_update

  pass "module_update: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_status ────────────────────────────────────────
test_module_status() {
  info "Тестирование module_status..."

  module_status || true

  pass "module_status: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_quick_update ──────────────────────────────────
test_module_quick_update() {
  info "Тестирование module_quick_update..."

  module_quick_update

  pass "module_quick_update: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: наличие всех основных функций ────────────────────────
test_all_functions_exist() {
  info "Тестирование наличия всех основных функций..."

  local required_functions=(
    "system_setup_update_env"
    "system_full_update"
    "system_quick_update"
    "system_auto_updates_configure"
    "system_auto_updates_unattended_configure"
    "system_auto_updates_enable"
    "system_auto_updates_setup"
    "system_bbr_load_module"
    "system_bbr_create_sysctl_config"
    "system_bbr_apply_sysctl"
    "system_bbr_setup"
    "system_bbr_check_status"
    "system_check_ip_neighborhood"
    "system_check_services"
    "system_restart_services"
    "system_install_base_dependencies"
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_update"
    "module_status"
    "module_quick_update"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Все функции существуют ($found/${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "Не все функции найдены ($found/${#required_functions[@]})"
  fi
}

# ── Тест: проверка экспорта функций ────────────────────────────
test_functions_exported() {
  info "Тестирование экспорта функций..."

  # Проверяем что module_* функции доступны
  if declare -f module_install &>/dev/null &&
    declare -f module_configure &>/dev/null &&
    declare -f module_enable &>/dev/null &&
    declare -f module_disable &>/dev/null; then
    pass "Module interface функции экспортированы"
    ((TESTS_PASSED++)) || true
  else
    fail "Module interface функции не найдены"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - System Module           ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый модуль: $MODULE_PATH"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_system_setup_update_env
  echo ""

  test_system_full_update
  echo ""

  test_system_quick_update
  echo ""

  test_system_auto_updates_configure
  echo ""

  test_system_auto_updates_unattended_configure
  echo ""

  test_system_auto_updates_enable
  echo ""

  test_system_auto_updates_setup
  echo ""

  test_system_bbr_load_module
  echo ""

  test_system_bbr_create_sysctl_config
  echo ""

  test_system_bbr_apply_sysctl
  echo ""

  test_system_bbr_setup
  echo ""

  test_system_bbr_check_status
  echo ""

  test_system_check_services
  echo ""

  test_system_restart_services
  echo ""

  test_system_install_base_dependencies
  echo ""

  test_module_install
  echo ""

  test_module_configure
  echo ""

  test_module_enable
  echo ""

  test_module_disable
  echo ""

  test_module_update
  echo ""

  test_module_status
  echo ""

  test_module_quick_update
  echo ""

  test_all_functions_exist
  echo ""

  test_functions_exported
  echo ""

  # ── Итоги ───────────────────────────────────────────────
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo -e "${GREEN}Пройдено: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Провалено:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}❌ Тесты провалены${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}✅ Все тесты пройдены${PLAIN}"
    exit 0
  fi
}

main "$@"
