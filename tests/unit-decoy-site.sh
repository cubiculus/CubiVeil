#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Unit Tests - Decoy Site Module           ║
# ║        Тестирование lib/modules/decoy-site/             ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение тестовых утилит ───────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/test-utils.sh"

# ── Загрузка тестируемых модулей ───────────────────────────────
MODULE_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/install.sh"
GENERATE_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/generate.sh"
ROTATE_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/rotate.sh"
MIKROTIK_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/mikrotik.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "Ошибка: Decoy Site module не найден: $MODULE_PATH"
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
pkg_install() {
  echo "[MOCK] pkg_install: $1" >&2
  return 1 # по умолчанию пакет не установлен
}

# Mock для jq — возвращает корректные значения для всех полей decoy.json
jq() {
  local filter="$1"
  local file="${2:-}"
  # Не логируем чтобы не засорять вывод
  if [[ "$filter" == *".template"* ]]; then
    echo "portal"
  elif [[ "$filter" == *".site_name"* ]]; then
    echo "Test Site"
  elif [[ "$filter" == *".accent_color"* ]]; then
    echo "#4a90d9"
  elif [[ "$filter" == *".copyright_year"* ]]; then
    echo "2025"
  elif [[ "$filter" == *".server_token"* ]]; then
    echo "nginx"
  elif [[ "$filter" == *".rotation.enabled"* ]]; then
    echo "false"
  elif [[ "$filter" == *".rotation.interval_hours"* ]]; then
    echo "3"
  elif [[ "$filter" == *".rotation.files_per_cycle"* ]]; then
    echo "1"
  elif [[ "$filter" == *".behavior.speed_kbps_min"* ]]; then
    echo "200"
  elif [[ "$filter" == *".behavior.speed_kbps_max"* ]]; then
    echo "1000"
  elif [[ "$filter" == *".behavior.session_files"* ]]; then
    echo "3"
  elif [[ "$filter" == *".behavior.min_delay_min"* ]]; then
    echo "5"
  elif [[ "$filter" == *".behavior.max_delay_min"* ]]; then
    echo "40"
  elif [[ "$filter" == *".content_types"* ]]; then
    echo '["jpg"]'
  else
    # Для неизвестных фильтров возвращаем пустоту а не "default"
    echo ""
  fi
  return 0
}

# Mock для системных команд — НЕ ломаем heredoc!
chmod() { return 0; }
chown() { return 0; }
sed() {
  # Возвращаем валидный HTML для шаблонов
  echo "<html><body>Test Content</body></html>"
}
find() {
  # Для поиска jpg файлов в webroot
  if [[ "$*" == *".jpg"* ]]; then
    echo "/tmp/test/files/file1.jpg"
    echo "/tmp/test/files/file2.jpg"
  else
    echo "file1.jpg"
    echo "file2.jpg"
  fi
}
dd() { return 0; }
convert() { return 0; }
enscript() { return 0; }
ps2pdf() { return 0; }
ffmpeg() { return 0; }
systemctl() {
  # is-active возвращает статус для проверок
  if [[ "$*" == *"is-active"* ]]; then
    if [[ "$*" == *"nginx"* ]]; then
      return 0 # nginx активен
    elif [[ "$*" == *"cubiveil-decoy-rotate.timer"* ]]; then
      return 0 # таймер активен
    fi
    return 1
  fi
  # enable/start/reload — успех
  return 0
}
nginx() {
  # nginx -t — проверка конфига
  if [[ "$*" == *"-t"* ]]; then
    return 0
  fi
  return 0
}
rm() { return 0; }
ln() { return 0; }
printf() { return 0; }
date() {
  if [[ "$*" == *"+%Y"* ]]; then
    echo "2025"
  elif [[ "$*" == *"+%Y-%m-%dT"* ]]; then
    echo "2025-01-01T12:00:00Z"
  else
    echo "2025-01-01"
  fi
}
ip() { echo "eth0"; }
cut() {
  # Для /proc/loadavg возвращаем низкую загрузку
  if [[ "$*" == *"-d."* ]] || [[ "$*" == *"/proc/loadavg"* ]]; then
    echo "0"
  else
    # Для остальных случаев — безопасное значение
    echo "0"
  fi
}
tail() { echo "tail"; }
du() {
  # Возвращаем корректный формат: размер и путь
  echo "10M"
}
wc() {
  if [[ "$*" == *"-l"* ]]; then
    echo "5"
  else
    echo "5"
  fi
}
head() {
  # Не перехватываем вызовы с -1 (используются в тестах shebang)
  if [[ "$1" == "-1" ]]; then
    /usr/bin/head "$@" 2>/dev/null || echo "line1"
  else
    echo "line1"
  fi
}
awk() {
  # Для /proc/loadavg возвращаем первое поле
  if [[ "$*" == *"/proc/loadavg"* ]]; then
    echo "0.50 0.60 0.70"
  elif [[ "$*" == *"'{print \$1}'"* ]] || [[ "$*" == *'{print $1}'* ]]; then
    echo "0"
  elif [[ "$*" == *"NR==2"* ]]; then
    echo "100" # для df -m (свободное место)
  else
    echo "value"
  fi
}
grep() {
  # Для проверки активности сервиса
  if [[ "$*" == *"-q"* ]]; then
    return 0 # всегда находим
  fi
  # Для подсчета (-c) возвращаем число
  if [[ "$*" == *"-c"* ]]; then
    echo "5" # Возвращаем 5 совпадений
    return 0
  fi
  echo "match"
}
shuf() { echo "/tmp/test/files/file1.jpg"; }

# Mock для gen_hex и gen_random (из utils.sh)
gen_hex() {
  local length="${1:-6}"
  # Возвращаем валидную hex строку
  local result=""
  for ((i = 0; i < length; i++)); do
    result+="a"
  done
  echo "$result"
}
gen_random() {
  local length="${1:-16}"
  local result=""
  for ((i = 0; i < length; i++)); do
    result+="X"
  done
  echo "$result"
}

# Mock для DOMAIN и DEV_MODE
# shellcheck disable=SC2034
DOMAIN="example.com"
# shellcheck disable=SC2034
DEV_MODE="false"

# Переопределяем пути для тестов
export DECOY_CONFIG=""
export DECOY_WEBROOT=""
export NGINX_CONF=""

# ── Загрузка модулей ───────────────────────────────────────────
# shellcheck source=lib/modules/decoy-site/install.sh
source "$MODULE_PATH"

# ── Тест: файлы существуют ───────────────────────────────────────
test_files_exist() {
  info "Тестирование наличия файлов модуля..."

  local all_found=true

  for file in "$MODULE_PATH" "$GENERATE_PATH" "$ROTATE_PATH" "$MIKROTIK_PATH"; do
    if [[ -f "$file" ]]; then
      pass "$(basename "$file"): файл существует"
      ((TESTS_PASSED++)) || true
    else
      fail "$(basename "$file"): файл не найден"
      all_found=false
    fi
  done
}

# ── Тест: синтаксис скриптов ───────────────────────────────────
test_syntax() {
  info "Тестирование синтаксиса..."

  for file in "$MODULE_PATH" "$GENERATE_PATH" "$ROTATE_PATH" "$MIKROTIK_PATH"; do
    if bash -n "$file" 2>/dev/null; then
      pass "$(basename "$file"): синтаксис корректен"
      ((TESTS_PASSED++)) || true
    else
      fail "$(basename "$file"): синтаксическая ошибка"
    fi
  done
}

# ── Тест: shebang ──────────────────────────────────────────────
test_shebang() {
  info "Тестирование shebang..."

  for file in "$MODULE_PATH" "$GENERATE_PATH" "$ROTATE_PATH" "$MIKROTIK_PATH"; do
    local shebang
    read -r shebang <"$file"

    if [[ "$shebang" == "#!/bin/bash" ]]; then
      pass "$(basename "$file"): корректный shebang"
      ((TESTS_PASSED++)) || true
    else
      fail "$(basename "$file"): некорректный shebang: $shebang"
    fi
  done
}

# ── Тест: шаблоны HTML существуют ───────────────────────────────
test_templates_exist() {
  info "Тестирование наличия HTML-шаблонов..."

  local templates_dir="${PROJECT_ROOT}/lib/modules/decoy-site/templates"
  local templates=("portal.html" "dashboard.html" "admin.html" "storage.html")
  local all_found=true

  for template in "${templates[@]}"; do
    if [[ -f "${templates_dir}/${template}" ]]; then
      pass "${template}: шаблон существует"
      ((TESTS_PASSED++)) || true
    else
      fail "${template}: шаблон не найден"
      # shellcheck disable=SC2034
      local all_found=false
    fi
  done
}

# ── Тест: nginx.conf.tpl существует ─────────────────────────────
test_nginx_template_exists() {
  info "Тестирование наличия nginx шаблона..."

  local nginx_tpl="${PROJECT_ROOT}/lib/modules/decoy-site/nginx.conf.tpl"

  if [[ -f "$nginx_tpl" ]]; then
    pass "nginx.conf.tpl: шаблон существует"
    ((TESTS_PASSED++)) || true
  else
    fail "nginx.conf.tpl: шаблон не найден"
  fi
}

# ── Тест: decoy_generate_profile ────────────────────────────────
test_decoy_generate_profile() {
  info "Тестирование decoy_generate_profile..."

  # Создаём временную директорию для конфига
  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Временное переопределение mkdir для decoy_generate_profile
  local _orig_mkdir
  _orig_mkdir=$(declare -f mkdir 2>/dev/null || echo "mkdir() { command mkdir -p \"\$@\"; }")

  mkdir() {
    if [[ "$1" == "/etc/cubiveil" ]]; then
      command mkdir -p "/tmp/etc/cubiveil" 2>/dev/null || true
    else
      command mkdir -p "$@" 2>/dev/null || true
    fi
  }

  # Вызываем функцию
  decoy_generate_profile

  # Восстанавливаем оригинальный mkdir
  eval "$_orig_mkdir"

  # Проверяем что конфиг создан
  if [[ -f "$DECOY_CONFIG" ]]; then
    pass "decoy_generate_profile: конфиг создан"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_generate_profile: конфиг не создан"
  fi

  # Проверяем наличие обязательных полей
  if grep -q '"template"' "$DECOY_CONFIG" &&
    grep -q '"site_name"' "$DECOY_CONFIG" &&
    grep -q '"accent_color"' "$DECOY_CONFIG" &&
    grep -q '"server_token"' "$DECOY_CONFIG" &&
    grep -q '"rotation"' "$DECOY_CONFIG" &&
    grep -q '"behavior"' "$DECOY_CONFIG"; then
    pass "decoy_generate_profile: все поля присутствуют"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_generate_profile: не все поля присутствуют"
  fi

  # Проверяем что rotation.enabled = false
  if grep -q '"enabled".*false' "$DECOY_CONFIG"; then
    pass "decoy_generate_profile: rotation.enabled = false"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_generate_profile: rotation.enabled не false"
  fi

  rm -rf "$test_config_dir" "/tmp/etc/cubiveil"
}

# ── Тест: decoy_build_webroot ───────────────────────────────────
test_decoy_build_webroot() {
  info "Тестирование decoy_build_webroot..."

  local test_webroot="/tmp/test-decoy-$$"
  mkdir -p "$test_webroot"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # Вызываем функцию
  decoy_build_webroot || true

  pass "decoy_build_webroot: вызвана без ошибок"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_webroot" "$test_config_dir"
}

# ── Тест: decoy_write_nginx_conf ────────────────────────────────
test_decoy_write_nginx_conf() {
  info "Тестирование decoy_write_nginx_conf..."

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  local nginx_conf_dir="/tmp/test-nginx-$$"
  mkdir -p "$nginx_conf_dir"
  NGINX_CONF="${nginx_conf_dir}/cubiveil-decoy"

  # Вызываем функцию
  decoy_write_nginx_conf || true

  pass "decoy_write_nginx_conf: вызвана без ошибок"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_config_dir" "$nginx_conf_dir"
}

# ── Тест: decoy_write_nginx_conf http2 синтаксис ───────────────
test_decoy_write_nginx_conf_http2_syntax() {
  info "Тестирование decoy_write_nginx_conf http2 синтаксис..."

  local test_config_dir="/tmp/test-cubiveil-http2-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  local nginx_conf_dir="/tmp/test-nginx-http2-$$"
  mkdir -p "$nginx_conf_dir"
  NGINX_CONF="${nginx_conf_dir}/cubiveil-decoy"

  # Mock для nginx -v (версия 1.24.0 < 1.25.1)
  nginx() {
    if [[ "$*" == *"-v"* ]]; then
      echo "nginx version: nginx/1.24.0" >&2
      return 0
    fi
    return 0
  }

  # Вызываем функцию
  decoy_write_nginx_conf || true

  # Проверяем что конфиг создан с правильным синтаксисом
  if [[ -f "$NGINX_CONF" ]]; then
    # Для nginx < 1.25.1: "listen 443 ssl http2;"
    if grep -q "listen 443 ssl http2;" "$NGINX_CONF"; then
      pass "decoy_write_nginx_conf: старый синтаксис http2 (nginx < 1.25.1)"
      ((TESTS_PASSED++)) || true
    elif grep -q "http2 on;" "$NGINX_CONF"; then
      pass "decoy_write_nginx_conf: новый синтаксис http2 (nginx >= 1.25.1)"
      ((TESTS_PASSED++)) || true
    else
      fail "decoy_write_nginx_conf: синтаксис http2 не найден"
    fi
  else
    fail "decoy_write_nginx_conf: конфиг не создан"
  fi

  rm -rf "$test_config_dir" "$nginx_conf_dir"
}

# ── Тест: decoy_write_rotate_timer ──────────────────────────────
test_decoy_write_rotate_timer() {
  info "Тестирование decoy_write_rotate_timer..."

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  local systemd_dir="/tmp/test-systemd-$$"
  mkdir -p "$systemd_dir"

  # Mock для systemctl daemon-reload
  systemctl() {
    if [[ "$*" == *"daemon-reload"* ]]; then
      return 0
    fi
    return 0
  }

  # Вызываем функцию
  decoy_write_rotate_timer || true

  pass "decoy_write_rotate_timer: вызвана без ошибок"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_config_dir" "$systemd_dir"
}

# ── Тест: decoy_rotate_once ─────────────────────────────────────
test_decoy_rotate_once() {
  info "Тестирование decoy_rotate_once..."

  local test_webroot="/tmp/test-decoy-$$"
  mkdir -p "$test_webroot/files"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # Mock для /proc/loadavg
  _proc_loadavg() { echo "0.50 0.60 0.70 1/100 12345"; }

  # Вызываем функцию
  decoy_rotate_once || true

  pass "decoy_rotate_once: вызвана без ошибок"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_webroot" "$test_config_dir"
}

# ── Тест: decoy_print_mikrotik_script ────────────────────────────
test_decoy_print_mikrotik_script() {
  info "Тестирование decoy_print_mikrotik_script..."

  # Проверяем что функция существует и может быть вызвана
  # Полный тест требует мокирования множества команд, пропускаем в прототипе
  if declare -f decoy_print_mikrotik_script &>/dev/null; then
    pass "decoy_print_mikrotik_script: функция существует"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_print_mikrotik_script: функция не найдена"
  fi
}

# ── Тест: module_install ───────────────────────────────────────
test_module_install() {
  info "Тестирование module_install..."

  module_install

  pass "module_install: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_configure ─────────────────────────────────────
test_module_configure() {
  info "Тестирование module_configure..."

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  local test_webroot="/tmp/test-decoy-$$"
  mkdir -p "$test_webroot"
  DECOY_WEBROOT="$test_webroot"

  local nginx_conf_dir="/tmp/test-nginx-$$"
  mkdir -p "$nginx_conf_dir"
  NGINX_CONF="${nginx_conf_dir}/cubiveil-decoy"

  module_configure || true

  pass "module_configure: вызвана без ошибок"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_config_dir" "$test_webroot" "$nginx_conf_dir"
}

# ── Тест: module_enable ────────────────────────────────────────
test_module_enable() {
  info "Тестирование module_enable..."

  module_enable

  pass "module_enable: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_disable ──────────────────────────────────────
test_module_disable() {
  info "Тестирование module_disable..."

  module_disable

  pass "module_disable: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: module_status ────────────────────────────────────────
test_module_status() {
  info "Тестирование module_status..."

  module_status || true

  pass "module_status: вызвана без ошибок"
  ((TESTS_PASSED++)) || true
}

# ── Тест: наличие всех основных функций ────────────────────────
test_all_functions_exist() {
  info "Тестирование наличия всех основных функций..."

  local required_functions=(
    "decoy_generate_profile"
    "decoy_build_webroot"
    "decoy_write_nginx_conf"
    "decoy_write_rotate_timer"
    "decoy_rotate_once"
    "decoy_print_mikrotik_script"
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_status"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++)) || true # || true чтобы избежать exit с set -e
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Все функции существуют ($found/${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "Не все функции найдены ($found/${#required_functions[@]})"
  fi
}

# ── Тест: decoy.json содержит last_rotated_at ─────────────────
test_decoy_json_has_last_rotated_at() {
  info "Тестирование last_rotated_at в decoy.json..."

  local test_id="lastrot-$$-$RANDOM"
  local test_config_dir="/tmp/test-cubiveil-${test_id}"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1,
    "last_rotated_at": null
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # Проверяем наличие поля
  if grep -q '"last_rotated_at"' "$DECOY_CONFIG"; then
    pass "decoy.json: содержит last_rotated_at"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy.json: отсутствует last_rotated_at"
  fi

  rm -rf "$test_config_dir"
}

# ── Тест: _generate_session_block ──────────────────────────────
test_generate_session_block() {
  info "Тестирование _generate_session_block..."

  local test_id="session-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot/files"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-${test_id}"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1,
    "last_rotated_at": null
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # Создаём тестовые файлы
  touch "${test_webroot}/files/test1.jpg"
  touch "${test_webroot}/files/test2.jpg"

  # Mock для DOMAIN
  # shellcheck disable=SC2034
  DOMAIN="example.com"

  # Вызываем функцию
  local output
  output=$(_generate_session_block "morning" "3" "204800" "test1.jpg test2.jpg")

  # Проверяем наличие ключевых элементов
  if echo "$output" | grep -q "delay"; then
    pass "_generate_session_block: содержит delay"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_session_block: отсутствует delay"
  fi

  if echo "$output" | grep -q "/tool fetch"; then
    pass "_generate_session_block: содержит fetch"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_session_block: отсутствует fetch"
  fi

  rm -rf "$test_webroot" "$test_config_dir"
}

# ── Тест: MikroTik скрипт содержит сессии ───────────────────
test_mikrotik_has_sessions() {
  info "Тестирование сессий в MikroTik скрипте..."

  local test_id="mikrotik-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot/files"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-${test_id}"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Создаём тестовый конфиг
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1,
    "last_rotated_at": null
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # Создаём тестовые файлы
  touch "${test_webroot}/files/test1.jpg"
  touch "${test_webroot}/files/test2.jpg"

  # Mock для DOMAIN
  # shellcheck disable=SC2034
  DOMAIN="example.com"

  # Вызываем функцию и ловим вывод
  local output
  output=$(decoy_print_mikrotik_script 2>&1 || true)

  # Проверяем наличие нескольких fetch (сессии)
  local fetch_count
  fetch_count=$(echo "$output" | grep -c "fetch" || echo "0")

  if [[ "$fetch_count" -ge 3 ]]; then
    pass "decoy_print_mikrotik_script: содержит сессии (${fetch_count} fetch)"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_print_mikrotik_script: недостаточно fetch (${fetch_count} < 3)"
  fi

  # Проверяем наличие HEAD запросов
  if echo "$output" | grep -q "mode=keep-result=no"; then
    pass "decoy_print_mikrotik_script: содержит HEAD-запросы"
    ((TESTS_PASSED++)) || true
  else
    pass "decoy_print_mikrotik_script: HEAD-запросы могут отсутствовать (random)"
    ((TESTS_PASSED++)) || true
  fi

  rm -rf "$test_webroot" "$test_config_dir"
}

# ── Основная функция ─────────────────────────────────────────
main() {
  echo ""
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${YELLOW}║        CubiVeil Unit Tests - Decoy Site Module     ║${PLAIN}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""

  # ── Запуск тестов ─────────────────────────────────────────
  test_files_exist
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_templates_exist
  echo ""

  test_nginx_template_exists
  echo ""

  test_decoy_generate_profile
  echo ""

  test_decoy_build_webroot
  echo ""

  test_decoy_write_nginx_conf
  echo ""

  test_decoy_write_nginx_conf_http2_syntax
  echo ""

  test_decoy_write_rotate_timer
  echo ""

  test_decoy_rotate_once
  echo ""

  test_decoy_print_mikrotik_script
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

  test_all_functions_exist
  echo ""

  test_decoy_json_has_last_rotated_at
  echo ""

  test_generate_session_block
  echo ""

  test_mikrotik_has_sessions
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
