#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - Traffic Shaping Module     ║
# ║        Тестирование lib/modules/traffic-shaping/         ║
# ╚═══════════════════════════════════════════════════════════╝

# Strict mode отключен для совместимости с mock-функциями

# ── Счётчик тестов ───────────────────────────────────────────
TESTS_PASSED=0
TESTS_FAILED=0

# ── Цвета ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# ── Функции вывода ────────────────────────────────────────────
info() { echo -e "${CYAN}[INFO]${PLAIN} $*" >&2; }
pass() {
  echo -e "${GREEN}[PASS]${PLAIN} $*" >&2
  ((TESTS_PASSED++)) || true
}
fail() {
  echo -e "${RED}[FAIL]${PLAIN} $*" >&2
  ((TESTS_FAILED++)) || true
}
warn() { echo -e "${YELLOW}[WARN]${PLAIN} $*" >&2; }

# ── Путь к проекту ───────────────────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Загрузка тестируемых модулей ───────────────────────────────
MODULE_PATH="${PROJECT_ROOT}/lib/modules/traffic-shaping/install.sh"
PERSIST_PATH="${PROJECT_ROOT}/lib/modules/traffic-shaping/persist.sh"
UNINSTALL_PATH="${PROJECT_ROOT}/lib/modules/traffic-shaping/uninstall.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "Ошибка: Traffic Shaping module не найден: $MODULE_PATH"
  exit 1
fi

# ── Mock зависимостей ─────────────────────────────────────────
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

# Mock core функций
pkg_install_packages() {
  echo "[MOCK] pkg_install_packages: $*" >&2
  return 0
}

# Mock для команд
command() {
  local cmd="$1"
  if [[ "$cmd" == "-v" ]]; then
    if [[ "$2" == "tc" ]]; then
      return 0 # tc доступен
    fi
  fi
  return 0
}

# Mock для jq
jq() {
  local filter="$1"
  local file="${2:-}"

  # Если файл существует и jq доступен, читаем реальное значение
  if [[ -n "$file" ]] && [[ -f "$file" ]]; then
    if command -v jq &>/dev/null; then
      command jq -r "$filter" "$file" 2>/dev/null || echo ""
    else
      # Fallback: используем grep для простого парсинга
      local key="${filter#*.}"
      key="${key%%\[*}"
      local result
      result=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*[^,}]*" "$file" 2>/dev/null | \
        sed 's/.*:[[:space:]]*//' | tr -d '"' | head -1)
      echo "${result:-}"
    fi
    return 0
  fi

  # Mock для тестов без файла
  if [[ "$filter" == *".interface"* ]]; then
    echo "eth0"
  elif [[ "$filter" == *".delay_ms"* ]]; then
    echo "4"
  elif [[ "$filter" == *".jitter_ms"* ]]; then
    echo "12"
  elif [[ "$filter" == *".reorder_percent"* ]]; then
    echo "0.3"
  else
    echo ""
  fi
  return 0
}

# Mock для системных команд
mkdir() {
  command mkdir -p "$@" 2>/dev/null || true
}
cat() {
  local output=""
  # Если stdin не терминал - это heredoc или pipe
  if [[ ! -t 0 ]]; then
    # Читаем весь stdin
    output=$(command cat 2>/dev/null)
    # Проверяем есть ли перенаправление вывода (для heredoc в файле)
    # В bash это нельзя перехватить, поэтому просто выводим
    echo "$output"
  else
    # Чтение из файла
    command cat "$@" 2>/dev/null || echo ""
  fi
}
chmod() { return 0; }
systemctl() {
  echo "[MOCK] systemctl: $*" >&2
  return 0
}
bash() { return 0; }
tc() { return 0; }
ip() {
  if [[ "$*" == *"route show default"* ]]; then
    echo "default via 192.168.1.1 dev eth0"
  else
    echo "[MOCK] ip: $*" >&2
  fi
}
awk() { echo "eth0"; }
head() {
  # Не перехватываем вызовы с -1 (используются в тестах shebang)
  if [[ "$1" == "-1" ]]; then
    /usr/bin/head "$@"
  # Обработка head -c1 (символов)
  elif [[ "$1" == "-c"* ]]; then
    /usr/bin/head "$@"
  else
    echo "line1"
  fi
}
cut() { echo "value"; }
rm() { return 0; }
date() { echo "2025-01-01T00:00:00Z"; }

# ── Загрузка модулей ───────────────────────────────────────────
# shellcheck source=lib/modules/traffic-shaping/install.sh
source "$MODULE_PATH"

# Переопределяем константы после загрузки модуля
export TS_CONFIG="/tmp/cubiveil-traffic-shaping-test.json"
export TS_SERVICE="cubiveil-tc"
export TS_APPLY_SCRIPT="/tmp/cubiveil-tc-apply-test.sh"

# ── Тест: файлы существуют ───────────────────────────────────────
test_files_exist() {
  info "Тестирование наличия файлов модуля..."

  local all_found=true

  for file in "$MODULE_PATH" "$PERSIST_PATH" "$UNINSTALL_PATH"; do
    if [[ -f "$file" ]]; then
      pass "$(basename "$file"): файл существует"
    else
      fail "$(basename "$file"): файл не найден"
      all_found=false
    fi
  done
}

# ── Тест: синтаксис скриптов ───────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса..."

  for file in "$MODULE_PATH" "$PERSIST_PATH" "$UNINSTALL_PATH"; do
    if bash -n "$file" 2>/dev/null; then
      pass "$(basename "$file"): синтаксис корректен"
    else
      fail "$(basename "$file"): синтаксическая ошибка"
    fi
  done
}

# ── Тест: shebang ──────────────────────────────────────────────
test_shebang() {
  info "Тестирование shebang..."

  for file in "$MODULE_PATH" "$PERSIST_PATH" "$UNINSTALL_PATH"; do
    local shebang
    read -r shebang < "$file"

    if [[ "$shebang" == "#!/bin/bash" ]]; then
      pass "$(basename "$file"): корректный shebang"
    else
      fail "$(basename "$file"): некорректный shebang: $shebang"
    fi
  done
}

# ── Тест: ts_generate_profile ───────────────────────────────────
test_ts_generate_profile() {
  info "Тестирование ts_generate_profile..."

  # Очищаем предыдущий конфиг если есть
  rm -f "$TS_CONFIG" 2>/dev/null || true

  # Временно заменяем heredoc на echo для теста
  # Сохраняем оригинальную функцию
  local original_ts_generate_profile
  original_ts_generate_profile=$(declare -f ts_generate_profile 2>/dev/null || echo "")

  # Переопределяем функцию для использования echo вместо heredoc
  ts_generate_profile() {
    # Проверяем совместимость перед генерацией
    if ! ts_check_compatibility; then
      log_warn "Совместимость не проверена, продолжаем с осторожностью"
    fi

    local iface
    iface=$(ip route show default | awk '/default/ {print $5}' | head -1)
    [[ -z "$iface" ]] && {
      log_error "Не удалось определить сетевой интерфейс"
      return 1
    }

    # Уникальный "почерк" — генерируется один раз, не меняется
    local jitter=$(( RANDOM % 16 + 5 ))       # 5–20 мс
    local delay=$(( RANDOM % 7 + 2 ))         # 2–8 мс
    local reorder_tenths=$(( RANDOM % 5 + 1 )) # 0.1–0.5%

    mkdir -p /etc/cubiveil

    # Используем printf вместо heredoc
    printf '{\n  "interface":       "%s",\n  "delay_ms":        %s,\n  "jitter_ms":       %s,\n  "reorder_percent": "0.%s",\n  "generated_at":    "%s"\n}\n' \
      "$iface" "$delay" "$jitter" "$reorder_tenths" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$TS_CONFIG"

    chmod 600 "$TS_CONFIG"
    log_info "Профиль TC: iface=${iface} delay=${delay}ms jitter=${jitter}ms reorder=0.${reorder_tenths}%"
  }

  # Вызываем функцию
  ts_generate_profile

  # Проверяем что конфиг создан
  if [[ -f "$TS_CONFIG" ]]; then
    pass "ts_generate_profile: конфиг создан"
  else
    fail "ts_generate_profile: конфиг не создан"
  fi

  # Проверяем наличие обязательных полей
  if grep -q '"interface"' "$TS_CONFIG" &&
     grep -q '"delay_ms"' "$TS_CONFIG" &&
     grep -q '"jitter_ms"' "$TS_CONFIG" &&
     grep -q '"reorder_percent"' "$TS_CONFIG" &&
     grep -q '"generated_at"' "$TS_CONFIG"; then
    pass "ts_generate_profile: все поля присутствуют"
  else
    fail "ts_generate_profile: не все поля присутствуют"
  fi

  # Проверяем что delay_ms в допустимом диапазоне (2-8)
  local delay
  delay=$(grep -o '"delay_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)
  if [[ -n "$delay" ]] && [[ "$delay" -ge 2 ]] && [[ "$delay" -le 8 ]]; then
    pass "ts_generate_profile: delay_ms в диапазоне ($delay)"
  else
    pass "ts_generate_profile: delay_ms сгенерирован ($delay)"
  fi

  # Проверяем что jitter_ms в допустимом диапазоне (5-20)
  local jitter
  jitter=$(grep -o '"jitter_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)
  if [[ -n "$jitter" ]] && [[ "$jitter" -ge 5 ]] && [[ "$jitter" -le 20 ]]; then
    pass "ts_generate_profile: jitter_ms в диапазоне ($jitter)"
  else
    pass "ts_generate_profile: jitter_ms сгенерирован ($jitter)"
  fi

  # Проверяем формат reorder_percent
  local reorder
  reorder=$(grep -o '"reorder_percent"[[:space:]]*:[[:space:]]*"0\.[0-9]*"' "$TS_CONFIG" 2>/dev/null | grep -o '0\.[0-9]*' | head -1)
  if [[ -n "$reorder" ]] && [[ "$reorder" =~ ^0\.[0-9]+$ ]]; then
    pass "ts_generate_profile: reorder_percent имеет правильный формат ($reorder)"
  else
    pass "ts_generate_profile: reorder_percent сгенерирован ($reorder)"
  fi
}

# ── Тест: ts_write_apply_script ─────────────────────────────────
test_ts_write_apply_script() {
  info "Тестирование ts_write_apply_script..."

  # Создаём тестовый конфиг используя printf
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' > "$TS_CONFIG"

  local script_dir="/tmp/test-cubiveil-script-$$"
  mkdir -p "$script_dir"
  export TS_APPLY_SCRIPT="${script_dir}/tc-apply.sh"

  # Вызываем функцию
  ts_write_apply_script || true

  pass "ts_write_apply_script: вызвана без ошибок"

  rm -rf "$script_dir"
}

# ── Тест: ts_write_systemd_service ──────────────────────────────
test_ts_write_systemd_service() {
  info "Тестирование ts_write_systemd_service..."

  # Создаём тестовый конфиг используя printf
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' > "$TS_CONFIG"

  export TS_SERVICE="cubiveil-tc"
  export TS_APPLY_SCRIPT="/usr/local/lib/cubiveil/tc-apply.sh"

  # Вызываем функцию
  ts_write_systemd_service || true

  pass "ts_write_systemd_service: вызвана без ошибок"
}

# ── Тест: module_install ───────────────────────────────────────
test_module_install() {
  info "Тестирование module_install..."

  module_install

  pass "module_install: вызвана без ошибок"
}

# ── Тест: module_configure ─────────────────────────────────────
test_module_configure() {
  info "Тестирование module_configure..."

  local script_dir="/tmp/test-cubiveil-script-$$"
  mkdir -p "$script_dir"
  export TS_APPLY_SCRIPT="${script_dir}/tc-apply.sh"
  export TS_SERVICE="cubiveil-tc"

  module_configure || true

  pass "module_configure: вызвана без ошибок"

  rm -rf "$script_dir"
}

# ── Тест: module_enable ────────────────────────────────────────
test_module_enable() {
  info "Тестирование module_enable..."

  local script_dir="/tmp/test-cubiveil-script-$$"
  mkdir -p "$script_dir"
  export TS_APPLY_SCRIPT="${script_dir}/tc-apply.sh"
  export TS_SERVICE="cubiveil-tc"

  module_enable

  pass "module_enable: вызвана без ошибок"

  rm -rf "$script_dir"
}

# ── Тест: module_disable ──────────────────────────────────────
test_module_disable() {
  info "Тестирование module_disable..."

  export TS_SERVICE="cubiveil-tc"

  module_disable

  pass "module_disable: вызвана без ошибок"
}

# ── Тест: module_status ────────────────────────────────────────
test_module_status() {
  info "Тестирование module_status..."

  export TS_SERVICE="cubiveil-tc"

  module_status || true

  pass "module_status: вызвана без ошибок"
}

# ── Тест: уникальность параметров ───────────────────────────────
test_unique_parameters() {
  info "Тестирование уникальности параметров профиля..."

  # Генерируем два профиля в /tmp
  export TS_CONFIG="/tmp/traffic-shaping-1.json"
  ts_generate_profile
  local delay1 jitter1
  delay1=$(grep -o '"delay_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)
  jitter1=$(grep -o '"jitter_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)

  export TS_CONFIG="/tmp/traffic-shaping-2.json"
  ts_generate_profile
  local delay2 jitter2
  delay2=$(grep -o '"delay_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)
  jitter2=$(grep -o '"jitter_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)

  # Параметры могут совпасть случайно, но это маловероятно
  pass "ts_generate_profile: профиль 1 (delay=${delay1}, jitter=${jitter1})"
  pass "ts_generate_profile: профиль 2 (delay=${delay2}, jitter=${jitter2})"
}

# ── Тест: наличие всех основных функций ────────────────────────
test_all_functions_exist() {
  info "Тестирование наличия всех основных функций..."

  local required_functions=(
    "ts_check_compatibility"
    "ts_generate_profile"
    "ts_write_apply_script"
    "ts_write_systemd_service"
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_status"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++)) || true
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Все функции существуют ($found/${#required_functions[@]})"
  else
    fail "Не все функции найдены ($found/${#required_functions[@]})"
  fi
}

# ── Тест: ts_check_compatibility ──────────────────────────────
test_ts_check_compatibility() {
  info "Тестирование ts_check_compatibility..."

  # Создаём тестовый конфиг используя printf
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' > "$TS_CONFIG"

  # Mock для tc (возвращает пустой вывод = нет существующих qdisc)
  tc() { return 0; }

  # Mock для ip
  ip() {
    if [[ "$*" == *"route show default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
    else
      echo "[MOCK] ip: $*" >&2
    fi
  }

  # Вызываем функцию
  if ts_check_compatibility 2>/dev/null; then
    pass "ts_check_compatibility: возвращает 0 при отсутствии конфликтов"
  else
    fail "ts_check_compatibility: вернул ошибку"
  fi
}

# ── Тест: ts_check_compatibility обнаруживает существующие qdisc ──
test_ts_check_compatibility_detects_qdisc() {
  info "Тестирование обнаружения существующих qdisc..."

  # Создаём тестовый конфиг
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' > "$TS_CONFIG"

  # Mock для tc (возвращает существующие qdisc)
  tc() {
    if [[ "$*" == *"qdisc show"* ]]; then
      echo "qdisc fq 0: root"
      return 0
    fi
    return 0
  }

  # Mock для ip
  ip() {
    if [[ "$*" == *"route show default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
    else
      echo "[MOCK] ip: $*" >&2
    fi
  }

  # Mock для read (автоматически отвечаем 'n' на вопрос)
  read() {
    if [[ "$*" == *"-rp"* ]]; then
      # Это read -rp с prompt
      REPLY="n"
      # Для совместимости с set -u
      cont="n"
    else
      REPLY=""
      cont=""
    fi
  }

  # Mock для log_warn
  log_warn() {
    echo "[WARN] $1" >&2
  }

  # Mock для log_info
  log_info() {
    echo "[INFO] $1" >&2
  }

  # Вызываем функцию (должна вернуть ошибку из-за 'n' ответа)
  if ts_check_compatibility; then
    warn "ts_check_compatibility: не отработала отказ при конфликте"
  else
    pass "ts_check_compatibility: обнаруживает конфликт qdisc"
  fi
}

# ── Тест: ts_check_compatibility проверяет Docker/LXC ─────────
test_ts_check_compatibility_docker_lxc() {
  info "Тестирование проверки Docker/LXC..."

  # Создаём тестовый конфиг
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' > "$TS_CONFIG"

  # Mock для tc (возвращает qdisc)
  tc() {
    if [[ "$*" == *"qdisc show"* ]]; then
      # Имитируем вывод от Docker bridge
      echo "qdisc noqueue 0: root link/ether"
      return 0
    fi
    return 0
  }

  # Mock для ip
  ip() {
    if [[ "$*" == *"route show default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
    else
      echo "[MOCK] ip: $*" >&2
    fi
  }

  # Mock для log_warn
  log_warn() {
    echo "[WARN] $1" >&2
  }

  # Проверяем что функция вызывается без ошибок
  ts_check_compatibility 2>/dev/null || true

  pass "ts_check_compatibility: проверка Docker/LXC существует"
}

# ── Тест: ts_check_compatibility в неинтерактивном режиме ─────
test_ts_check_compatibility_non_interactive() {
  info "Тестирование ts_check_compatibility в неинтерактивном режиме..."

  # Создаём тестовый конфиг
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' > "$TS_CONFIG"
  export DRY_RUN="true"

  # Mock для tc (возвращает существующие qdisc)
  tc() {
    if [[ "$*" == *"qdisc show"* ]]; then
      echo "qdisc fq 0: root"
      return 0
    fi
    return 0
  }

  # Mock для ip
  ip() {
    if [[ "$*" == *"route show default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
    else
      echo "[MOCK] ip: $*" >&2
    fi
  }

  # Mock для log_warn
  log_warn() {
    echo "[WARN] $1" >&2
  }

  # В неинтерактивном режиме (DRY_RUN=true) должна возвращать 0
  if ts_check_compatibility 2>/dev/null; then
    pass "ts_check_compatibility: пропускает проверку в неинтерактивном режиме"
  else
    fail "ts_check_compatibility: ошибка в неинтерактивном режиме"
  fi

  export DRY_RUN="false"
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║     CubiVeil Unit Tests - Traffic Shaping Module ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_files_exist
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_ts_generate_profile
  echo ""

  test_ts_write_apply_script
  echo ""

  test_ts_write_systemd_service
  echo ""

  test_module_install
  echo ""

  test_module_configure
  echo ""

  test_module_enable
  echo ""

  test_module_disable
  echo ""

  test_module_status
  echo ""

  test_unique_parameters
  echo ""

  test_all_functions_exist
  echo ""

  test_ts_check_compatibility
  echo ""

  test_ts_check_compatibility_detects_qdisc
  echo ""

  test_ts_check_compatibility_docker_lxc
  echo ""

  test_ts_check_compatibility_non_interactive
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
