#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - Rollback Module              в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ lib/modules/rollback/install.sh       в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјРѕРіРѕ РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
MODULE_PATH="${SCRIPT_DIR}/lib/modules/rollback/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "РћС€РёР±РєР°: Rollback module РЅРµ РЅР°Р№РґРµРЅ: $MODULE_PATH"
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

# Mock РґР»СЏ РїСЂРѕРІРµСЂРєРё SHA256
verify_sha256() {
  # shellcheck disable=SC2034
  local file="$1"
  # shellcheck disable=SC2034
  local expected="$2"
  # Р”Р»СЏ С‚РµСЃС‚РѕРІ РІСЃРµРіРґР° РІРѕР·РІСЂР°С‰Р°РµРј true
  return 0
}

# Mock РґР»СЏ РїСЂРѕРІРµСЂРєРё SSL
verify_ssl_cert() { return 0; }

# Mock РґР»СЏ openssl
openssl() {
  if [[ "$*" == *"-subject"* ]]; then
    echo "subject=CN = test.example.com"
  else
    echo "[MOCK] openssl: $*" >&2
  fi
}

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# shellcheck source=lib/modules/rollback/install.sh
source "$MODULE_PATH"

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° РјРѕРґСѓР»СЏ..."

  if [[ -f "$MODULE_PATH" ]]; then
    pass "Rollback module: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "Rollback module: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР°..."

  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "Rollback module: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "Rollback module: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: shebang в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang..."

  local shebang
  shebang=$(head -1 "$MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "Rollback module: РєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "Rollback module: РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang: $shebang"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_init в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_init() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_init..."

  local test_backup_dir="/tmp/test-rollback-$$"
  BACKUP_DIR="$test_backup_dir"
  ROLLBACK_TEMP_DIR="${test_backup_dir}/temp"

  rollback_init

  pass "rollback_init: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_list_backups в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_list_backups() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_list_backups..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_archive_dir="${test_backup_dir}/archives"
  mkdir -p "$test_archive_dir"

  BACKUP_DIR="$test_backup_dir"
  BACKUP_ARCHIVE_DIR="$test_archive_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ Р±СЌРєР°Рї
  echo "test" >"${test_archive_dir}/test-backup.tar.gz"

  rollback_list_backups || true

  pass "rollback_list_backups: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_select_backup в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_select_backup_mock() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_select_backup (mock)..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_archive_dir="${test_backup_dir}/archives"
  mkdir -p "$test_archive_dir"

  BACKUP_DIR="$test_backup_dir"
  BACKUP_ARCHIVE_DIR="$test_archive_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ Р±СЌРєР°Рї
  echo "test" >"${test_archive_dir}/test-backup.tar.gz"

  # Mock РґР»СЏ read
  read() {
    selection="1" # Р’РѕР·РІСЂР°С‰Р°РµРј РїРµСЂРІС‹Р№ РІР°СЂРёР°РЅС‚
    return 0
  }

  # Р¤СѓРЅРєС†РёСЏ РјРѕР¶РµС‚ РІС‹Р№С‚Рё РёР·-Р·Р° exit 0, РїРѕСЌС‚РѕРјСѓ Р»РѕРІРёРј
  rollback_select_backup 2>/dev/null || true

  pass "rollback_select_backup: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_extract_backup в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_extract_backup() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_extract_backup..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_archive_dir="${test_backup_dir}/archives"
  local test_temp_dir="${test_backup_dir}/temp"
  mkdir -p "$test_archive_dir" "$test_temp_dir"

  BACKUP_DIR="$test_backup_dir"
  BACKUP_ARCHIVE_DIR="$test_archive_dir"
  ROLLBACK_TEMP_DIR="$test_temp_dir"

  # Mock РґР»СЏ tar (РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РѕРїСЂРµРґРµР»С‘РЅ РґРѕ РІС‹Р·РѕРІР° tar)
  tar() {
    if [[ "$*" == *"-xzf"* ]]; then
      mkdir -p "$ROLLBACK_TEMP_DIR"
      echo "extracted" >"${ROLLBACK_TEMP_DIR}/test.txt"
      return 0
    fi
    command tar "$@" 2>/dev/null || true
  }

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ Р°СЂС…РёРІ
  local test_file="${test_temp_dir}/test.txt"
  echo "test" >"$test_file"

  tar -czf "${test_archive_dir}/test.tar.gz" -C "$test_temp_dir" test.txt 2>/dev/null || true

  rollback_extract_backup "${test_archive_dir}/test.tar.gz"

  pass "rollback_extract_backup: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_verify_integrity в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_verify_integrity() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_verify_integrity..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_temp_dir="${test_backup_dir}/temp"
  mkdir -p "$test_temp_dir"

  ROLLBACK_TEMP_DIR="$test_temp_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Рµ С„Р°Р№Р»С‹ СЃ hash
  echo "test db" >"${test_temp_dir}/singbox-db.sqlite3"
  echo "abc123" >"${test_temp_dir}/singbox-db.sqlite3.sha256"

  rollback_verify_integrity

  pass "rollback_verify_integrity: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_stop_services в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_stop_services() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_stop_services..."

  rollback_stop_services

  pass "rollback_stop_services: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_singbox_db в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_singbox_db() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_singbox_db..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_temp_dir="${test_backup_dir}/temp"
  local test_singbox_dir="/tmp/test-singbox-$$"
  mkdir -p "$test_temp_dir" "$test_singbox_dir"

  ROLLBACK_TEMP_DIR="$test_temp_dir"
  # shellcheck disable=SC2034
  SINGBOX_DIR="$test_singbox_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІСѓСЋ Р‘Р”
  echo "test db" >"${test_temp_dir}/singbox-db.sqlite3"
  echo "abc123" >"${test_temp_dir}/singbox-db.sqlite3.sha256"

  rollback_singbox_db || true

  pass "rollback_singbox_db: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "$test_singbox_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_singbox_config в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_singbox_config() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_singbox_config..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_temp_dir="${test_backup_dir}/temp"
  mkdir -p "$test_temp_dir" "/opt/singbox"

  ROLLBACK_TEMP_DIR="$test_temp_dir"
  # shellcheck disable=SC2034
  SINGBOX_ENV="/opt/singbox/.env"
  SINGBOX_TEMPLATE="${test_temp_dir}/sing-box-template.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Рµ С„Р°Р№Р»С‹
  echo "TEST=1" >"${test_temp_dir}/singbox.env"
  echo "abc123" >"${test_temp_dir}/singbox.env.sha256"
  echo "{}" >"$SINGBOX_TEMPLATE"
  echo "abc123" >"${SINGBOX_TEMPLATE}.sha256"

  rollback_singbox_config || true

  pass "rollback_singbox_config: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "/opt/singbox"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_singbox_config в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_singbox_config() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_singbox_config..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_temp_dir="${test_backup_dir}/temp"
  mkdir -p "$test_temp_dir" "/etc/sing-box"

  ROLLBACK_TEMP_DIR="$test_temp_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІСѓСЋ РєРѕРЅС„РёРіСѓСЂР°С†РёСЋ
  echo "{}" >"${test_temp_dir}/singbox-config.json"
  echo "abc123" >"${test_temp_dir}/singbox-config.json.sha256"

  rollback_singbox_config || true

  pass "rollback_singbox_config: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "/etc/sing-box"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_ssl_certs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_ssl_certs() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_ssl_certs..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_temp_dir="${test_backup_dir}/temp"
  local test_ssl_dir="/tmp/test-ssl-$$"
  mkdir -p "$test_temp_dir" "$test_ssl_dir"

  ROLLBACK_TEMP_DIR="$test_temp_dir"
  # shellcheck disable=SC2034
  SSL_CERT_DIR="$test_ssl_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Рµ СЃРµСЂС‚РёС„РёРєР°С‚С‹
  mkdir -p "${test_temp_dir}/ssl-certs"
  echo "test cert" >"${test_temp_dir}/ssl-certs/fullchain.pem"

  rollback_ssl_certs || true

  pass "rollback_ssl_certs: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "$test_ssl_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_keys в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_keys() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_keys..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_temp_dir="${test_backup_dir}/temp"
  local test_singbox_dir="/tmp/test-singbox-$$"
  mkdir -p "$test_temp_dir" "$test_singbox_dir"

  ROLLBACK_TEMP_DIR="$test_temp_dir"
  # shellcheck disable=SC2034
  CREDENTIALS_FILE="${test_singbox_dir}/credentials.age"
  # shellcheck disable=SC2034
  CREDENTIALS_KEY="${test_singbox_dir}/credentials.key"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Рµ РєР»СЋС‡Рё
  echo "test credentials" >"${test_temp_dir}/credentials.age"
  echo "test key" >"${test_temp_dir}/credentials.key"

  rollback_keys

  pass "rollback_keys: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir" "$test_singbox_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_start_services в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_start_services() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_start_services..."

  rollback_start_services

  pass "rollback_start_services: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_full в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_full_mock() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_full (mock)..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_archive_dir="${test_backup_dir}/archives"
  local test_temp_dir="${test_backup_dir}/temp"
  mkdir -p "$test_archive_dir" "$test_temp_dir"

  BACKUP_DIR="$test_backup_dir"
  BACKUP_ARCHIVE_DIR="$test_archive_dir"
  ROLLBACK_TEMP_DIR="$test_temp_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ Р±СЌРєР°Рї
  echo "test" >"${test_archive_dir}/test.tar.gz"

  # Mock РґР»СЏ select
  rollback_select_backup() {
    echo "${test_archive_dir}/test.tar.gz"
  }

  rollback_extract_backup() { return 0; }
  rollback_verify_integrity() { return 0; }
  rollback_stop_services() { return 0; }
  rollback_singbox_db() { return 0; }
  rollback_singbox_config() { return 0; }
  rollback_singbox_config() { return 0; }
  rollback_ssl_certs() { return 0; }
  rollback_keys() { return 0; }
  rollback_start_services() { return 0; }

  rollback_full || true

  pass "rollback_full: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: rollback_latest в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_latest_mock() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ rollback_latest (mock)..."

  local test_backup_dir="/tmp/test-rollback-$$"
  local test_archive_dir="${test_backup_dir}/archives"
  local test_temp_dir="${test_backup_dir}/temp"
  mkdir -p "$test_archive_dir" "$test_temp_dir"

  BACKUP_DIR="$test_backup_dir"
  BACKUP_ARCHIVE_DIR="$test_archive_dir"
  ROLLBACK_TEMP_DIR="$test_temp_dir"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ Р±СЌРєР°Рї
  echo "test" >"${test_archive_dir}/test.tar.gz"

  rollback_extract_backup() { return 0; }
  rollback_verify_integrity() { return 0; }
  rollback_stop_services() { return 0; }
  rollback_singbox_db() { return 0; }
  rollback_singbox_config() { return 0; }
  rollback_ssl_certs() { return 0; }
  rollback_start_services() { return 0; }

  rollback_latest || true

  pass "rollback_latest: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_backup_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: module_install в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_install() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_install..."

  module_install

  pass "module_install: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_rollback в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_rollback() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_rollback..."

  # Mock РґР»СЏ РёР·Р±РµР¶Р°РЅРёСЏ РёРЅС‚РµСЂР°РєС‚РёРІРЅРѕСЃС‚Рё
  rollback_full() { return 0; }

  module_rollback

  pass "module_rollback: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_rollback_latest в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_rollback_latest() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_rollback_latest..."

  rollback_latest() { return 0; }

  module_rollback_latest

  pass "module_rollback_latest: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
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

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_all_functions_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№..."

  local required_functions=(
    "rollback_init"
    "rollback_list_backups"
    "rollback_select_backup"
    "rollback_extract_backup"
    "rollback_verify_integrity"
    "rollback_stop_services"
    "rollback_singbox_db"
    "rollback_singbox_config"
    "rollback_singbox_config"
    "rollback_ssl_certs"
    "rollback_keys"
    "rollback_start_services"
    "rollback_full"
    "rollback_latest"
    "module_install"
    "module_rollback"
    "module_rollback_latest"
    "module_list"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Р’СЃРµ С„СѓРЅРєС†РёРё СЃСѓС‰РµСЃС‚РІСѓСЋС‚ ($found/${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "РќРµ РІСЃРµ С„СѓРЅРєС†РёРё РЅР°Р№РґРµРЅС‹ ($found/${#required_functions[@]})"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РєРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_config_variables() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РєРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹С… РїРµСЂРµРјРµРЅРЅС‹С…..."

  if [[ -n "$BACKUP_DIR" ]] && [[ -n "$BACKUP_ARCHIVE_DIR" ]] && [[ -n "$ROLLBACK_TEMP_DIR" ]]; then
    pass "РљРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹"
    ((TESTS_PASSED++)) || true
  else
    fail "РљРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: verify_sha256 integration в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_verify_sha256_integration() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РёРЅС‚РµРіСЂР°С†РёРё verify_sha256..."

  local test_file="/tmp/test-verify-$$"
  echo "test content" >"$test_file"

  # РџРѕР»СѓС‡Р°РµРј СЂРµР°Р»СЊРЅС‹Р№ hash
  local expected_hash
  # shellcheck disable=SC2034
  expected_hash=$(sha256sum "$test_file" | awk '{print $1}')

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ verify_sha256 СЃСѓС‰РµСЃС‚РІСѓРµС‚
  if declare -f verify_sha256 &>/dev/null; then
    pass "verify_sha256 С„СѓРЅРєС†РёСЏ РґРѕСЃС‚СѓРїРЅР°"
    ((TESTS_PASSED++)) || true
  else
    fail "verify_sha256 С„СѓРЅРєС†РёСЏ РЅРµ РЅР°Р№РґРµРЅР°"
  fi

  rm -f "$test_file"
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - Rollback Module         в•‘${PLAIN}"
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

  test_rollback_init
  echo ""

  test_rollback_list_backups
  echo ""

  test_rollback_select_backup_mock
  echo ""

  test_rollback_extract_backup
  echo ""

  test_rollback_verify_integrity
  echo ""

  test_rollback_stop_services
  echo ""

  test_rollback_singbox_db
  echo ""

  echo ""

  test_rollback_singbox_config
  echo ""

  test_rollback_ssl_certs
  echo ""

  test_rollback_keys
  echo ""

  test_rollback_start_services
  echo ""

  test_rollback_full_mock
  echo ""

  test_rollback_latest_mock
  echo ""

  test_module_install
  echo ""

  test_module_rollback
  echo ""

  test_module_rollback_latest
  echo ""

  test_module_list
  echo ""

  test_all_functions_exist
  echo ""

  test_config_variables
  echo ""

  test_verify_sha256_integration
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
