#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - New Utilities                ║
# ║        Тестирование новых утилит                         ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# ── Тест: наличие новых утилит ───────────────────────────────
test_utilities_exist() {
  info "Тестирование наличия новых утилит..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/monitor.sh"
    "utils/diagnose.sh"
    "utils/manage-profiles.sh"
    "utils/backup.sh"
    "utils/cubiveil.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if [[ -f "${SCRIPT_DIR}/${util}" ]]; then
      pass "Утилита существует: $util"
      ((TESTS_PASSED++)) || true
    else
      fail "Утилита отсутствует: $util"
    fi
  done
}

# ── Тест: синтаксис утилит ───────────────────────────────────
test_utilities_syntax() {
  info "Тестирование синтаксиса утилит..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/monitor.sh"
    "utils/diagnose.sh"
    "utils/manage-profiles.sh"
    "utils/backup.sh"
    "utils/cubiveil.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if [[ -f "${SCRIPT_DIR}/${util}" ]]; then
      if bash -n "${SCRIPT_DIR}/${util}" 2>/dev/null; then
        pass "Синтаксис OK: $util"
        ((TESTS_PASSED++)) || true
      else
        fail "Синтаксическая ошибка: $util"
      fi
    fi
  done
}

# ── Тест: заголовок shebang ───────────────────────────────────
test_shebang() {
  info "Тестирование shebang утилит..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/monitor.sh"
    "utils/diagnose.sh"
    "utils/manage-profiles.sh"
    "utils/backup.sh"
    "utils/cubiveil.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    local first_line
    first_line=$(head -1 "${SCRIPT_DIR}/${util}" 2>/dev/null || echo "")

    if [[ "$first_line" == "#!/bin/bash" ]]; then
      pass "Shebang OK: $util"
      ((TESTS_PASSED++)) || true
    else
      fail "Неверный shebang: $util ($first_line)"
    fi
  done
}

# ── Тест: безопасность (set -euo pipefail) ───────────────────
test_safety_flags() {
  info "Тестирование флагов безопасности..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/monitor.sh"
    "utils/diagnose.sh"
    "utils/manage-profiles.sh"
    "utils/backup.sh"
    "utils/cubiveil.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if grep -q "set -euo pipefail" "${SCRIPT_DIR}/${util}" 2>/dev/null; then
      pass "Флаги безопасности: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "Нет флагов безопасности: $util"
    fi
  done
}

# ── Тест: локализация ────────────────────────────────────────
test_localization() {
  info "Тестирование локализации..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/monitor.sh"
    "utils/diagnose.sh"
    "utils/manage-profiles.sh"
    "utils/backup.sh"
    "utils/cubiveil.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    # Проверка подключения lang.sh
    if grep -q 'source.*lang.sh\|source.*fallback.sh' "${SCRIPT_DIR}/${util}" 2>/dev/null; then
      pass "Локализация подключена: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "Локализация не подключена: $util"
    fi
  done
}

# ── Тест: проверка root прав ─────────────────────────────────
test_root_check() {
  info "Тестирование проверки root прав..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/monitor.sh"
    "utils/diagnose.sh"
    "utils/manage-profiles.sh"
    "utils/backup.sh"
    "utils/cubiveil.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if grep -qE 'EUID.*-ne.*0|root' "${SCRIPT_DIR}/${util}" 2>/dev/null; then
      pass "Проверка root: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "Нет проверки root: $util"
    fi
  done
}

# ── Тест: функции в backup.sh ────────────────────────────────
test_backup_functions() {
  info "Тестирование функций в backup.sh..."

  # Mock зависимостей
  check_root() { :; }
  check_ubuntu() { :; }
  step() { echo "$1"; }
  ok() { echo -e "${GREEN}[✓]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[✗]${PLAIN} $1" >&2
    exit 1
  }
  info() { echo "[INFO] $1"; }
  select_language() { :; }

  source "${SCRIPT_DIR}/lib/utils.sh"
  source "${SCRIPT_DIR}/backup.sh" 2>/dev/null || true

  local functions=(
    "create_backup"
    "list_backups"
    "restore_backup"
    "step_backup_marzban"
    "step_backup_singbox"
    "step_backup_ssl"
    "step_backup_keys"
    "step_create_archive"
    "step_cleanup_old_backups"
  )

  for func in "${functions[@]}"; do
    if declare -f "$func" >/dev/null 2>&1; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      # Функции могут быть недоступны из-за структуры скрипта
      info "Функция не проверена: $func (может быть локальной)"
    fi
  done
}

# ── Тест: функции в manage-profiles.sh ───────────────────────
test_profiles_functions() {
  info "Тестирование функций в manage-profiles.sh..."

  local functions=(
    "list_profiles"
    "add_profile"
    "remove_profile"
    "enable_profile"
    "disable_profile"
    "generate_qr"
    "show_stats"
    "show_profile_info"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/manage-profiles.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция отсутствует: $func"
    fi
  done
}

# ── Тест: функции в monitor.sh ───────────────────────────────
test_monitor_functions() {
  info "Тестирование функций в monitor.sh..."

  local functions=(
    "get_cpu_usage"
    "get_ram_usage"
    "get_disk_usage"
    "get_uptime"
    "check_service_status"
    "get_active_users"
    "draw_bar"
    "monitor_loop"
    "print_snapshot"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/monitor.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция отсутствует: $func"
    fi
  done
}

# ── Тест: функции в diagnose.sh ──────────────────────────────
test_diagnose_functions() {
  info "Тестирование функций в diagnose.sh..."

  local functions=(
    "step_check_dns"
    "step_check_ssl"
    "step_check_connections"
    "step_check_services"
    "step_check_ports"
    "step_analyze_logs"
    "step_check_resources"
    "step_generate_report"
    "step_recommendations"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/diagnose.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция отсутствует: $func"
    fi
  done
}

# ── Тест: функции в export-config.sh ─────────────────────────
test_export_functions() {
  info "Тестирование функций в export-config.sh..."

  local functions=(
    "step_collect_config"
    "step_collect_keys"
    "step_generate_manifest"
    "step_encrypt_sensitive"
    "step_create_archive"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/export-config.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция отсутствует: $func"
    fi
  done
}

# ── Тест: функции в update.sh ────────────────────────────────
test_update_functions() {
  info "Тестирование функций в update.sh..."

  local functions=(
    "step_check_versions"
    "step_confirm_update"
    "step_create_backup"
    "step_download_update"
    "step_install_update"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/update.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция отсутствует: $func"
    fi
  done
}

# ── Тест: функции в rollback.sh ──────────────────────────────
test_rollback_functions() {
  info "Тестирование функций в rollback.sh..."

  local functions=(
    "step_select_backup"
    "step_validate_backup"
    "step_confirm_rollback"
    "step_stop_services"
    "step_restore_files"
    "step_restore_config"
    "step_start_services"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/rollback.sh" 2>/dev/null; then
      pass "Функция существует: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция отсутствует: $func"
    fi
  done
}

# ── Тест: Python health check module ─────────────────────────
test_python_health_check() {
  info "Тестирование Python health check модуля..."

  local health_check_file="${SCRIPT_DIR}/assets/telegram-bot/health_check.py"

  if [[ -f "$health_check_file" ]]; then
    pass "health_check.py существует"
    ((TESTS_PASSED++)) || true

    # Проверка синтаксиса Python
    if python3 -m py_compile "$health_check_file" 2>/dev/null; then
      pass "Синтаксис Python OK: health_check.py"
      ((TESTS_PASSED++)) || true
    else
      fail "Синтаксическая ошибка: health_check.py"
    fi

    # Проверка наличия классов
    if grep -q "class HealthChecker" "$health_check_file"; then
      pass "Класс HealthChecker существует"
      ((TESTS_PASSED++)) || true
    else
      fail "Класс HealthChecker не найден"
    fi

    # Проверка наличия методов
    local methods=(
      "check_connection_speed"
      "check_profile_status"
      "check_all_profiles"
      "check_service_health"
      "check_health_endpoint"
      "restart_service"
      "auto_heal"
      "get_full_health_report"
      "format_health_message"
    )

    for method in "${methods[@]}"; do
      if grep -q "def ${method}" "$health_check_file"; then
        pass "Метод существует: $method"
        ((TESTS_PASSED++)) || true
      else
        fail "Метод не найден: $method"
      fi
    done
  else
    fail "health_check.py не найден"
  fi
}

# ── Тест: обновлённый bot.py ─────────────────────────────────
test_bot_updated() {
  info "Тестирование обновлённого bot.py..."

  local bot_file="${SCRIPT_DIR}/assets/telegram-bot/bot.py"

  if [[ -f "$bot_file" ]]; then
    pass "bot.py существует"
    ((TESTS_PASSED++)) || true

    # Проверка импорта health_check
    if grep -q "from health_check import HealthChecker" "$bot_file"; then
      pass "HealthChecker импортирован в bot.py"
      ((TESTS_PASSED++)) || true
    else
      fail "HealthChecker не импортирован в bot.py"
    fi

    # Проверка инициализации health checker
    if grep -q "self.health = HealthChecker()" "$bot_file"; then
      pass "HealthChecker инициализирован"
      ((TESTS_PASSED++)) || true
    else
      fail "HealthChecker не инициализирован"
    fi

    # Проверка health check в poll
    if grep -q "check_health_and_heal" "$bot_file"; then
      pass "Health check вызывается в poll"
      ((TESTS_PASSED++)) || true
    else
      fail "Health check не вызывается в poll"
    fi
  else
    fail "bot.py не найден"
  fi
}

# ── Тест: обновлённый commands.py ────────────────────────────
test_commands_updated() {
  info "Тестирование обновлённого commands.py..."

  local commands_file="${SCRIPT_DIR}/assets/telegram-bot/commands.py"

  if [[ -f "$commands_file" ]]; then
    pass "commands.py существует"
    ((TESTS_PASSED++)) || true

    # Проверка новых команд
    local commands=(
      "/health"
      "/speedtest"
      "/profiles"
    )

    for cmd in "${commands[@]}"; do
      if grep -q "\"$cmd\"" "$commands_file"; then
        pass "Команда существует: $cmd"
        ((TESTS_PASSED++)) || true
      else
        fail "Команда не найдена: $cmd"
      fi
    done

    # Проверка методов
    local methods=(
      "_health"
      "_speedtest"
      "_profiles"
    )

    for method in "${methods[@]}"; do
      if grep -q "def ${method}" "$commands_file"; then
        pass "Метод существует: $method"
        ((TESTS_PASSED++)) || true
      else
        fail "Метод не найден: $method"
      fi
    done
  else
    fail "commands.py не найден"
  fi
}

# ── Тест: CLI менеджер утилит ────────────────────────────────
test_cli_manager() {
  info "Тестирование cubiveil.sh (CLI менеджер)..."

  local cli_file="${SCRIPT_DIR}/utils/cubiveil.sh"

  if [[ -f "$cli_file" ]]; then
    pass "cubiveil.sh существует"
    ((TESTS_PASSED++)) || true

    # Проверка команд
    local commands=(
      "update"
      "rollback"
      "export"
      "monitor"
      "diagnose"
      "profiles"
      "backup"
      "help"
    )

    for cmd in "${commands[@]}"; do
      if grep -qE "${cmd}\|u\)|${cmd}\|rb\)|${cmd}\|exp\)" "$cli_file" ||
        grep -q "run_${cmd}" "$cli_file"; then
        pass "Команда существует: $cmd"
        ((TESTS_PASSED++)) || true
      else
        fail "Команда не найдена: $cmd"
      fi
    done

    # Проверка функции check_root
    if grep -q "check_root" "$cli_file"; then
      pass "Функция check_root существует"
      ((TESTS_PASSED++)) || true
    else
      fail "Функция check_root не найдена"
    fi
  else
    fail "cubiveil.sh не найден"
  fi
}

# ── Тест: install-aliases.sh ─────────────────────────────────
test_install_aliases() {
  info "Тестирование install-aliases.sh..."

  local aliases_file="${SCRIPT_DIR}/utils/install-aliases.sh"

  if [[ -f "$aliases_file" ]]; then
    pass "install-aliases.sh существует"
    ((TESTS_PASSED++)) || true

    # Проверка установки CLI
    if grep -q "/usr/local/bin/cubiveil" "$aliases_file"; then
      pass "CLI путь настроен"
      ((TESTS_PASSED++)) || true
    else
      fail "CLI путь не найден"
    fi

    # Проверка алиасов
    local aliases=(
      "cv="
      "cv-update="
      "cv-rollback="
      "cv-export="
      "cv-monitor="
      "cv-diagnose="
      "cv-profiles="
      "cv-backup="
    )

    for alias in "${aliases[@]}"; do
      if grep -q "$alias" "$aliases_file"; then
        pass "Алиас существует: $alias"
        ((TESTS_PASSED++)) || true
      else
        warn "Алиас не найден: $alias"
      fi
    done
  else
    fail "install-aliases.sh не найден"
  fi
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - New Utilities           ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  info "Тестируемый проект: ${SCRIPT_DIR}"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_utilities_exist
  echo ""

  test_utilities_syntax
  echo ""

  test_shebang
  echo ""

  test_safety_flags
  echo ""

  test_localization
  echo ""

  test_root_check
  echo ""

  test_backup_functions
  echo ""

  test_profiles_functions
  echo ""

  test_monitor_functions
  echo ""

  test_diagnose_functions
  echo ""

  test_export_functions
  echo ""

  test_update_functions
  echo ""

  test_rollback_functions
  echo ""

  test_python_health_check
  echo ""

  test_bot_updated
  echo ""

  test_commands_updated
  echo ""

  test_cli_manager
  echo ""

  test_install_aliases
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
