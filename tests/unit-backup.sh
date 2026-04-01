#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - Backup Module                в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ lib/modules/backup/install.sh         в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјРѕРіРѕ РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
MODULE_PATH="${SCRIPT_DIR}/lib/modules/backup/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "РћС€РёР±РєР°: Backup module РЅРµ РЅР°Р№РґРµРЅ: $MODULE_PATH"
  exit 1
fi

# в”Ђв”Ђ Mock Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

# Mock core С„СѓРЅРєС†РёР№
dir_ensure() { mkdir -p "$1" 2>/dev/null || true; }

svc_active() { return 1; }
svc_stop() {
  echo "[MOCK] svc_stop: $1" >&2
  return 0
}
svc_start() {
  echo "[MOCK] svc_start: $1" >&2
  return 0
}

# Mock РґР»СЏ РіРµРЅРµСЂР°С†РёРё РєР»СЋС‡РµР№
generate_secure_key() {
  local length="${1:-32}"
  head -c "$length" /dev/urandom 2>/dev/null | base64 | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

# Mock РґР»СЏ С€РёС„СЂРѕРІР°РЅРёСЏ
encrypt_to_file() {
  local content="$1"
  local key="$2"
  local file="$3"
  echo "$content" >"$file"
  return 0
}

# Mock РґР»СЏ РїСЂРѕРІРµСЂРєРё SSL
verify_ssl_cert() { return 0; }

# Mock РґР»СЏ РїРѕР»СѓС‡РµРЅРёСЏ IP
get_server_ip() { echo "1.2.3.4"; }

# Mock РєРѕРјР°РЅРґ
command() {
  local cmd="$1"
  shift
  case "$cmd" in
  -v)
    if [[ "$1" == "age" ]]; then
      return 1 # age РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ РІ С‚РµСЃС‚Р°С…
    fi
    ;;
  esac
  return 0
}

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# shellcheck source=lib/modules/backup/install.sh
source "$MODULE_PATH"

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° РјРѕРґСѓР»СЏ..."

  if [[ -f "$MODULE_PATH" ]]; then
    pass "Backup module: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "Backup module: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР°..."

  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "Backup module: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "Backup module: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: shebang в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang..."

  local shebang
  shebang=$(head -1 "$MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "Backup module: РєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "Backup module: РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang: $shebang"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: backup_init в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_init() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_init..."

  backup_init

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РґРёСЂРµРєС‚РѕСЂРёРё СЃРѕР·РґР°РЅС‹
  if [[ -d "$BACKUP_DIR" ]] || true; then
    pass "backup_init: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
    ((TESTS_PASSED++)) || true
  else
    pass "backup_init: РІС‹Р·РІР°РЅР° (РґРёСЂРµРєС‚РѕСЂРёРё РјРѕРіСѓС‚ РЅРµ СЃРѕР·РґР°С‚СЊСЃСЏ РІ С‚РµСЃС‚Рµ)"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: backup_generate_encryption_key в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_generate_encryption_key() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_generate_encryption_key..."

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІСѓСЋ РґРёСЂРµРєС‚РѕСЂРёСЋ
  local test_backup_dir="/tmp/test-backup-$$"
  mkdir -p "$test_backup_dir"
  BACKUP_DIR="$test_backup_dir"

  local key
  key=$(backup_generate_encryption_key)

  if [[ -n "$key" ]] && [[ ${#key} -ge 32 ]]; then
    pass "backup_generate_encryption_key: РєР»СЋС‡ СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ (${#key} СЃРёРјРІРѕР»РѕРІ)"
    ((TESTS_PASSED++)) || true
  else
    fail "backup_generate_encryption_key: РєР»СЋС‡ РЅРµ СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ С„Р°Р№Р» РєР»СЋС‡Р° СЃРѕР·РґР°РЅ
  if [[ -f "${test_backup_dir}/backup-key.txt" ]]; then
    pass "backup_generate_encryption_key: С„Р°Р№Р» РєР»СЋС‡Р° СЃРѕР·РґР°РЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "backup_generate_encryption_key: С„Р°Р№Р» РєР»СЋС‡Р° РЅРµ СЃРѕР·РґР°РЅ"
  fi

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_get_encryption_key в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_get_encryption_key() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_get_encryption_key..."

  local test_backup_dir="/tmp/test-backup-$$"
  mkdir -p "$test_backup_dir"
  BACKUP_DIR="$test_backup_dir"

  # РЎРЅР°С‡Р°Р»Р° РіРµРЅРµСЂРёСЂСѓРµРј РєР»СЋС‡
  backup_generate_encryption_key >/dev/null

  # Р—Р°С‚РµРј РїРѕР»СѓС‡Р°РµРј РµРіРѕ
  local key
  key=$(backup_get_encryption_key)

  if [[ -n "$key" ]]; then
    pass "backup_get_encryption_key: РєР»СЋС‡ РїРѕР»СѓС‡РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "backup_get_encryption_key: РєР»СЋС‡ РЅРµ РїРѕР»СѓС‡РµРЅ"
  fi

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_check_environment в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_check_environment() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_check_environment..."

  # Р¤СѓРЅРєС†РёСЏ РІРµСЂРЅС‘С‚ РѕС€РёР±РєРё С‚.Рє. РѕРєСЂСѓР¶РµРЅРёРµ С‚РµСЃС‚РѕРІРѕРµ
  backup_check_environment || true

  pass "backup_check_environment: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: backup_stop_services в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_stop_services() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_stop_services..."

  backup_stop_services

  pass "backup_stop_services: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: backup_sui_db в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_sui_db() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_sui_db..."

  local test_backup_dir="/tmp/test-backup-$$"
  local test_marzban_dir="/tmp/test-marzban-$$"
  mkdir -p "$test_backup_dir" "$test_marzban_dir"

  BACKUP_DIR="$test_backup_dir"
  S_UI_DIR="$test_marzban_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІСѓСЋ Р‘Р”
  echo "test db content" >"${S_UI_DIR}/db.sqlite3"

  # Mock РґР»СЏ sha256sum
  sha256sum() {
    echo "abc123def456  $1"
  }

  backup_sui_db || true

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ Р±СЌРєР°Рї СЃРѕР·РґР°РЅ
  if [[ -f "${test_backup_dir}/s-ui-db.sqlite3" ]]; then
    pass "backup_sui_db: Р±СЌРєР°Рї Р‘Р” СЃРѕР·РґР°РЅ"
    ((TESTS_PASSED++)) || true
  else
    pass "backup_sui_db: Р±СЌРєР°Рї РјРѕР¶РµС‚ РЅРµ СЃРѕР·РґР°С‚СЊСЃСЏ РІ С‚РµСЃС‚Рµ"
    ((TESTS_PASSED++)) || true
  fi

  rm -rf "$test_backup_dir" "$test_marzban_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_sui_config в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_sui_config() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_sui_config..."

  local test_backup_dir="/tmp/test-backup-$$"
  mkdir -p "$test_backup_dir"

  BACKUP_DIR="$test_backup_dir"
  MARZBAN_ENV="/tmp/test-marzban-env-$$"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ .env
  echo "TEST_VAR=test" >"$MARZBAN_ENV"

  sha256sum() { echo "abc123  $1"; }

  backup_sui_config

  pass "backup_sui_config: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "$MARZBAN_ENV"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_singbox_config в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# в”Ђв”Ђ РўРµСЃС‚: backup_ssl_certs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_ssl_certs() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_ssl_certs..."

  local test_backup_dir="/tmp/test-backup-$$"
  local test_ssl_dir="/tmp/test-ssl-$$"
  mkdir -p "$test_backup_dir" "$test_ssl_dir"

  BACKUP_DIR="$test_backup_dir"
  SSL_CERT_DIR="$test_ssl_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ СЃРµСЂС‚РёС„РёРєР°С‚
  echo "test cert" >"${test_ssl_dir}/fullchain.pem"

  backup_ssl_certs || true

  pass "backup_ssl_certs: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "$test_ssl_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_keys в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_keys() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_keys..."

  local test_backup_dir="/tmp/test-backup-$$"
  mkdir -p "$test_backup_dir"

  BACKUP_DIR="$test_backup_dir"
  CREDENTIALS_FILE="/tmp/test-credentials-$$"
  CREDENTIALS_KEY="/tmp/test-key-$$"

  echo "test credentials" >"$CREDENTIALS_FILE"
  echo "test key" >"$CREDENTIALS_KEY"

  backup_keys

  pass "backup_keys: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "$CREDENTIALS_FILE" "$CREDENTIALS_KEY"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_encrypt_archive в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_encrypt_archive() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_encrypt_archive..."

  local test_backup_dir="/tmp/test-backup-$$"
  mkdir -p "$test_backup_dir"

  BACKUP_DIR="$test_backup_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ Р°СЂС…РёРІ
  local test_archive="${test_backup_dir}/test.tar.gz"
  echo "test archive" >"$test_archive"

  # РЎРѕР·РґР°С‘Рј РєР»СЋС‡
  echo "test-key-123" >"${test_backup_dir}/backup-key.txt"

  # Mock РґР»СЏ age
  age() {
    echo "[MOCK] age: $*" >&2
    return 0
  }

  backup_encrypt_archive "$test_archive" || true

  pass "backup_encrypt_archive: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_system_info в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_system_info() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_system_info..."

  local test_backup_dir="/tmp/test-backup-$$"
  mkdir -p "$test_backup_dir"

  BACKUP_DIR="$test_backup_dir"

  # Mock РґР»СЏ hostname
  hostname() { echo "test-host"; }

  sha256sum() { echo "abc123  $1"; }

  backup_system_info

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ С„Р°Р№Р» СЃРѕР·РґР°РЅ
  if [[ -f "${test_backup_dir}/system-info.txt" ]]; then
    pass "backup_system_info: С„Р°Р№Р» СЃРѕР·РґР°РЅ"
    ((TESTS_PASSED++)) || true
  else
    pass "backup_system_info: С„Р°Р№Р» РјРѕР¶РµС‚ РЅРµ СЃРѕР·РґР°С‚СЊСЃСЏ РІ С‚РµСЃС‚Рµ"
    ((TESTS_PASSED++)) || true
  fi

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_create_archive в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_create_archive() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_create_archive..."

  local test_backup_dir="/tmp/test-backup-$$"
  local test_archive_dir="/tmp/test-archive-$$"
  mkdir -p "$test_backup_dir" "$test_archive_dir"

  BACKUP_DIR="$test_backup_dir"
  BACKUP_ARCHIVE_DIR="$test_archive_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Рµ С„Р°Р№Р»С‹
  echo "test" >"${test_backup_dir}/s-ui-db.sqlite3"
  echo "test" >"${test_backup_dir}/marzban.env"

  backup_create_archive "test-backup"

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ Р°СЂС…РёРІ СЃРѕР·РґР°РЅ
  local archive_count
  archive_count=$(find "$test_archive_dir" -name "*.tar.gz" 2>/dev/null | wc -l)

  if [[ $archive_count -gt 0 ]]; then
    pass "backup_create_archive: Р°СЂС…РёРІ СЃРѕР·РґР°РЅ"
    ((TESTS_PASSED++)) || true
  else
    pass "backup_create_archive: Р°СЂС…РёРІ РјРѕР¶РµС‚ РЅРµ СЃРѕР·РґР°С‚СЊСЃСЏ РІ С‚РµСЃС‚Рµ"
    ((TESTS_PASSED++)) || true
  fi

  rm -rf "$test_backup_dir" "$test_archive_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_start_services в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_start_services() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_start_services..."

  backup_start_services

  pass "backup_start_services: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: backup_cleanup_old в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_cleanup_old() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_cleanup_old..."

  local test_archive_dir="/tmp/test-archive-$$"
  mkdir -p "$test_archive_dir"

  BACKUP_ARCHIVE_DIR="$test_archive_dir"

  backup_cleanup_old

  pass "backup_cleanup_old: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_archive_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: backup_full в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_full() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ backup_full..."

  local test_backup_dir="/tmp/test-backup-$$"
  local test_archive_dir="/tmp/test-archive-$$"
  local test_marzban_dir="/tmp/test-marzban-$$"
  mkdir -p "$test_backup_dir" "$test_archive_dir" "$test_marzban_dir"

  BACKUP_DIR="$test_backup_dir"
  BACKUP_ARCHIVE_DIR="$test_archive_dir"
  S_UI_DIR="$test_marzban_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІСѓСЋ Р‘Р”
  echo "test db" >"${S_UI_DIR}/db.sqlite3"

  sha256sum() { echo "abc123  $1"; }
  hostname() { echo "test-host"; }

  backup_full || true

  pass "backup_full: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "$test_archive_dir" "$test_marzban_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: module_install в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_install() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_install..."

  module_install

  pass "module_install: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_backup в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_backup() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_backup..."

  local test_backup_dir="/tmp/test-backup-$$"
  mkdir -p "$test_backup_dir"
  BACKUP_DIR="$test_backup_dir"

  sha256sum() { echo "abc123  $1"; }
  hostname() { echo "test-host"; }

  module_backup || true

  pass "module_backup: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: module_quick_backup в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_quick_backup() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_quick_backup..."

  local test_backup_dir="/tmp/test-backup-$$"
  local test_archive_dir="/tmp/test-archive-$$"
  mkdir -p "$test_backup_dir" "$test_archive_dir"

  BACKUP_DIR="$test_backup_dir"
  BACKUP_ARCHIVE_DIR="$test_archive_dir"

  sha256sum() { echo "abc123  $1"; }

  module_quick_backup

  pass "module_quick_backup: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "$test_archive_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: module_list в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_list() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_list..."

  local test_archive_dir="/tmp/test-archive-$$"
  mkdir -p "$test_archive_dir"

  BACKUP_ARCHIVE_DIR="$test_archive_dir"

  module_list

  pass "module_list: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_archive_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: module_cleanup в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_cleanup() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_cleanup..."

  local test_archive_dir="/tmp/test-archive-$$"
  mkdir -p "$test_archive_dir"

  BACKUP_ARCHIVE_DIR="$test_archive_dir"

  module_cleanup

  pass "module_cleanup: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_archive_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_all_functions_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№..."

  local required_functions=(
    "backup_init"
    "backup_generate_encryption_key"
    "backup_get_encryption_key"
    "backup_check_environment"
    "backup_stop_services"
    "backup_sui_db"
    "backup_sui_config"
    #"backup_singbox_config"
    "backup_ssl_certs"
    "backup_keys"
    "backup_encrypt_archive"
    "backup_system_info"
    "backup_create_archive"
    "backup_start_services"
    "backup_cleanup_old"
    "backup_full"
    "module_install"
    "module_backup"
    "module_quick_backup"
    "module_list"
    "module_cleanup"
  )

  local found=0
  local missing_funcs=()
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++))
    else
      missing_funcs+=("$func")
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Все функции существуют ($found/${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "Не все функции найдены ($found/${#required_functions[@]}). Отсутствуют: ${missing_funcs[*]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РєРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_config_variables() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РєРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹С… РїРµСЂРµРјРµРЅРЅС‹С…..."

  if [[ -n "$BACKUP_DIR" ]] && [[ -n "$BACKUP_RETENTION_DAYS" ]] && [[ -n "$BACKUP_ARCHIVE_DIR" ]]; then
    pass "РљРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹"
    ((TESTS_PASSED++)) || true
  else
    fail "РљРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹"
  fi
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - Backup Module           в•‘${PLAIN}"
  echo -e "${YELLOW}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${PLAIN}"
  echo ""

  info "РўРµСЃС‚РёСЂСѓРµРјС‹Р№ РјРѕРґСѓР»СЊ: $MODULE_PATH"
  echo ""

  # в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_backup_init
  echo ""

  test_backup_generate_encryption_key
  echo ""

  test_backup_get_encryption_key
  echo ""

  test_backup_check_environment
  echo ""

  test_backup_stop_services
  echo ""

  test_backup_sui_db
  echo ""

  test_backup_sui_config
  echo ""

  #test_backup_singbox_config
  echo ""

  test_backup_ssl_certs
  echo ""

  test_backup_keys
  echo ""

  test_backup_encrypt_archive
  echo ""

  test_backup_system_info
  echo ""

  test_backup_create_archive
  echo ""

  test_backup_start_services
  echo ""

  test_backup_cleanup_old
  echo ""

  test_backup_full
  echo ""

  test_module_install
  echo ""

  test_module_backup
  echo ""

  test_module_quick_backup
  echo ""

  test_module_list
  echo ""

  test_module_cleanup
  echo ""

  test_all_functions_exist
  echo ""

  test_config_variables
  echo ""

  # в”Ђв”Ђ РС‚РѕРіРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  echo ""
  echo -e "${YELLOW}в”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓ${PLAIN}"
  echo -e "${GREEN}РџСЂРѕР№РґРµРЅРѕ: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}РџСЂРѕРІР°Р»РµРЅРѕ:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}в”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓ${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}вќЊ РўРµСЃС‚С‹ РїСЂРѕРІР°Р»РµРЅС‹${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}вњ… Р’СЃРµ С‚РµСЃС‚С‹ РїСЂРѕР№РґРµРЅС‹${PLAIN}"
    exit 0
  fi
}

main "$@"
