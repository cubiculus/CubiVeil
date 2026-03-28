#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - System Module                в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ lib/modules/system/install.sh         в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјРѕРіРѕ РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
MODULE_PATH="${SCRIPT_DIR}/lib/modules/system/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "РћС€РёР±РєР°: System module РЅРµ РЅР°Р№РґРµРЅ: $MODULE_PATH"
  exit 1
fi

# в”Ђв”Ђ Mock Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }

# Mock core С„СѓРЅРєС†РёР№
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

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# shellcheck source=lib/modules/system/install.sh
source "$MODULE_PATH"

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° РјРѕРґСѓР»СЏ..."

  if [[ -f "$MODULE_PATH" ]]; then
    pass "System module: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "System module: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР°..."

  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "System module: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "System module: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: shebang в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang..."

  local shebang
  shebang=$(head -1 "$MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "System module: РєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "System module: РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang: $shebang"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: system_setup_update_env в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_setup_update_env() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_setup_update_env..."

  # Mock РґР»СЏ sed
  sed() {
    echo "[MOCK] sed: $*" >&2
    return 0
  }

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  system_setup_update_env

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РїРµСЂРµРјРµРЅРЅС‹Рµ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹
  if [[ "${DEBIAN_FRONTEND:-}" == "noninteractive" ]]; then
    pass "system_setup_update_env: DEBIAN_FRONTEND СѓСЃС‚Р°РЅРѕРІР»РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "system_setup_update_env: DEBIAN_FRONTEND РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅ"
  fi

  if [[ "${UCF_FORCE_CONFFOLD:-}" == "1" ]]; then
    pass "system_setup_update_env: UCF_FORCE_CONFFOLD СѓСЃС‚Р°РЅРѕРІР»РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "system_setup_update_env: UCF_FORCE_CONFFOLD РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: system_full_update в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_full_update() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_full_update..."

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  system_full_update

  pass "system_full_update: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_quick_update в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_quick_update() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_quick_update..."

  system_quick_update

  pass "system_quick_update: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_auto_updates_configure в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_auto_updates_configure() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_auto_updates_configure..."

  # Mock РґР»СЏ cat
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

  pass "system_auto_updates_configure: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_auto_updates_unattended_configure в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_auto_updates_unattended_configure() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_auto_updates_unattended_configure..."

  cat() {
    if [[ "$*" == *">"* ]]; then
      return 0
    fi
    command cat "$@" 2>/dev/null || echo ""
  }

  system_auto_updates_unattended_configure

  pass "system_auto_updates_unattended_configure: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_auto_updates_enable в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_auto_updates_enable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_auto_updates_enable..."

  system_auto_updates_enable

  pass "system_auto_updates_enable: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_auto_updates_setup в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_auto_updates_setup() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_auto_updates_setup..."

  cat() { return 0; }

  system_auto_updates_setup

  pass "system_auto_updates_setup: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_bbr_load_module в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_bbr_load_module() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_bbr_load_module..."

  # Mock РґР»СЏ РїСЂРѕРІРµСЂРєРё СЃРѕР·РґР°РЅРёСЏ С„Р°Р№Р»Р°
  # shellcheck disable=SC2034
  local test_file="/tmp/test-bbr-$$"

  # Р’СЂРµРјРµРЅРЅР°СЏ Р·Р°РјРµРЅР° /etc/modules-load.d
  mkdir -p /tmp/test-modules-load.d
  sed() { return 0; }

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ (РѕРЅР° СЃРѕР·РґР°СЃС‚ С„Р°Р№Р» РІ /etc/modules-load.d)
  # Р”Р»СЏ С‚РµСЃС‚Р° РїСЂРѕСЃС‚Рѕ РїСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ С„СѓРЅРєС†РёСЏ РІС‹Р·С‹РІР°РµС‚СЃСЏ
  system_bbr_load_module

  pass "system_bbr_load_module: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf /tmp/test-modules-load.d
}

# в”Ђв”Ђ РўРµСЃС‚: system_bbr_create_sysctl_config в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_bbr_create_sysctl_config() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_bbr_create_sysctl_config..."

  # Mock cat РґР»СЏ Р·Р°РїРёСЃРё РІ С„Р°Р№Р»
  # shellcheck disable=SC2120
  cat() {
    if [[ "$*" == *">"* ]] || [[ $# -eq 0 ]]; then
      return 0
    fi
    command cat "$@" 2>/dev/null || echo ""
  }

  system_bbr_create_sysctl_config

  pass "system_bbr_create_sysctl_config: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_bbr_apply_sysctl в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_bbr_apply_sysctl() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_bbr_apply_sysctl..."

  system_bbr_apply_sysctl

  pass "system_bbr_apply_sysctl: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_bbr_setup в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_bbr_setup() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_bbr_setup..."

  system_bbr_setup

  pass "system_bbr_setup: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_bbr_check_status в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_bbr_check_status() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_bbr_check_status..."

  if system_bbr_check_status; then
    pass "system_bbr_check_status: BBR Р°РєС‚РёРІРµРЅ"
    ((TESTS_PASSED++)) || true
  else
    warn "system_bbr_check_status: BBR РЅРµ Р°РєС‚РёРІРµРЅ (РјРѕР¶РµС‚ Р±С‹С‚СЊ РЅРѕСЂРјР°Р»СЊРЅРѕ)"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: system_check_services в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_check_services() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_check_services..."

  # Р¤СѓРЅРєС†РёСЏ РІРµСЂРЅС‘С‚ false С‚.Рє. СЃРµСЂРІРёСЃС‹ РЅРµ Р°РєС‚РёРІРЅС‹ РІ С‚РµСЃС‚Рµ
  system_check_services || true

  pass "system_check_services: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_restart_services в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_restart_services() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_restart_services..."

  system_restart_services

  pass "system_restart_services: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: system_install_base_dependencies в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_system_install_base_dependencies() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ system_install_base_dependencies..."

  system_install_base_dependencies

  pass "system_install_base_dependencies: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: pkg_update в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_pkg_update() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ pkg_update..."

  apt_args=()
  apt-get() {
    apt_args=("$@")
    return 0
  }

  pkg_update

  if [[ "${DEBIAN_FRONTEND:-}" == "noninteractive" ]] && [[ "${UCF_FORCE_CONFFOLD:-}" == "1" ]] && [[ "${apt_args[0]}" == "update" ]]; then
    pass "pkg_update РІС‹РїРѕР»РЅСЏРµС‚ apt-get update Рё СѓСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ РѕРєСЂСѓР¶РµРЅРёРµ"
    ((TESTS_PASSED++)) || true
  else
    fail "pkg_update РЅРµ РІС‹РїРѕР»РЅСЏРµС‚ РѕР¶РёРґР°РµРјС‹Рµ РґРµР№СЃС‚РІРёСЏ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: pkg_upgrade в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_pkg_upgrade() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ pkg_upgrade..."

  apt_args=()
  apt-get() {
    apt_args=("$@")
    return 0
  }
  sed() { return 0; }

  pkg_upgrade

  if [[ "${DEBIAN_FRONTEND:-}" == "noninteractive" ]] && [[ "${UCF_FORCE_CONFFOLD:-}" == "1" ]] && [[ "${UCFF_FORCE_CONFFNEW:-}" == "1" ]] && [[ "${apt_args[0]}" == "upgrade" ]]; then
    pass "pkg_upgrade РІС‹РїРѕР»РЅСЏРµС‚ apt-get upgrade Рё СѓСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ РѕРєСЂСѓР¶РµРЅРёРµ"
    ((TESTS_PASSED++)) || true
  else
    fail "pkg_upgrade РЅРµ РІС‹РїРѕР»РЅСЏРµС‚ РѕР¶РёРґР°РµРјС‹Рµ РґРµР№СЃС‚РІРёСЏ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: pkg_full_upgrade в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_pkg_full_upgrade() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ pkg_full_upgrade..."

  apt_args=()
  apt-get() {
    apt_args=("$@")
    return 0
  }
  sed() { return 0; }

  pkg_full_upgrade

  if [[ "${DEBIAN_FRONTEND:-}" == "noninteractive" ]] && [[ "${UCF_FORCE_CONFFOLD:-}" == "1" ]] && [[ "${UCFF_FORCE_CONFFNEW:-}" == "1" ]] && [[ "${apt_args[0]}" == "dist-upgrade" ]]; then
    pass "pkg_full_upgrade РІС‹РїРѕР»РЅСЏРµС‚ apt-get dist-upgrade Рё СѓСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ РѕРєСЂСѓР¶РµРЅРёРµ"
    ((TESTS_PASSED++)) || true
  else
    fail "pkg_full_upgrade РЅРµ РІС‹РїРѕР»РЅСЏРµС‚ РѕР¶РёРґР°РµРјС‹Рµ РґРµР№СЃС‚РІРёСЏ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: module_install в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_install() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_install..."

  cat() { return 0; }

  module_install

  pass "module_install: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_configure в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_configure() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_configure..."

  cat() { return 0; }

  module_configure

  pass "module_configure: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_enable в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_enable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_enable..."

  module_enable

  pass "module_enable: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_disable в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_disable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_disable..."

  module_disable

  pass "module_disable: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_update в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_update() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_update..."

  module_update

  pass "module_update: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_status в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_status() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_status..."

  module_status || true

  pass "module_status: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_quick_update в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_quick_update() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_quick_update..."

  module_quick_update

  pass "module_quick_update: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_all_functions_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№..."

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
    pass "Р’СЃРµ С„СѓРЅРєС†РёРё СЃСѓС‰РµСЃС‚РІСѓСЋС‚ ($found/${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "РќРµ РІСЃРµ С„СѓРЅРєС†РёРё РЅР°Р№РґРµРЅС‹ ($found/${#required_functions[@]})"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° СЌРєСЃРїРѕСЂС‚Р° С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_functions_exported() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЌРєСЃРїРѕСЂС‚Р° С„СѓРЅРєС†РёР№..."

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ module_* С„СѓРЅРєС†РёРё РґРѕСЃС‚СѓРїРЅС‹
  if declare -f module_install &>/dev/null &&
    declare -f module_configure &>/dev/null &&
    declare -f module_enable &>/dev/null &&
    declare -f module_disable &>/dev/null; then
    pass "Module interface С„СѓРЅРєС†РёРё СЌРєСЃРїРѕСЂС‚РёСЂРѕРІР°РЅС‹"
    ((TESTS_PASSED++)) || true
  else
    fail "Module interface С„СѓРЅРєС†РёРё РЅРµ РЅР°Р№РґРµРЅС‹"
  fi
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - System Module           в•‘${PLAIN}"
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
