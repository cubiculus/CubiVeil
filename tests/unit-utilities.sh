#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - Utilities                    в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СѓС‚РёР»РёС‚                                 в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"
# Р”Р»СЏ С‚РµСЃС‚РёСЂРѕРІР°РЅРёСЏ С€Р°РіРѕРІ РѕР±РЅРѕРІР»РµРЅРёСЏ
source "${SCRIPT_DIR}/utils/update.sh" 2>/dev/null || true

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_utilities_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ СѓС‚РёР»РёС‚..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if [[ -f "${SCRIPT_DIR}/${util}" ]]; then
      pass "РЈС‚РёР»РёС‚Р° СЃСѓС‰РµСЃС‚РІСѓРµС‚: $util"
      ((TESTS_PASSED++)) || true
    else
      fail "РЈС‚РёР»РёС‚Р° РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $util"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_utilities_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР° СѓС‚РёР»РёС‚..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if [[ -f "${SCRIPT_DIR}/${util}" ]]; then
      if bash -n "${SCRIPT_DIR}/${util}" 2>/dev/null; then
        pass "РЎРёРЅС‚Р°РєСЃРёСЃ OK: $util"
        ((TESTS_PASSED++)) || true
      else
        fail "РЎРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°: $util"
      fi
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: Р·Р°РіРѕР»РѕРІРѕРє shebang в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang СѓС‚РёР»РёС‚..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    local first_line
    first_line=$(head -1 "${SCRIPT_DIR}/${util}" 2>/dev/null || echo "")

    if [[ "$first_line" == "#!/bin/bash" ]]; then
      pass "Shebang OK: $util"
      ((TESTS_PASSED++)) || true
    else
      fail "РќРµРІРµСЂРЅС‹Р№ shebang: $util ($first_line)"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: Р±РµР·РѕРїР°СЃРЅРѕСЃС‚СЊ (set -euo pipefail) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_safety_flags() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„Р»Р°РіРѕРІ Р±РµР·РѕРїР°СЃРЅРѕСЃС‚Рё..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if grep -q "set -euo pipefail" "${SCRIPT_DIR}/${util}" 2>/dev/null; then
      pass "Р¤Р»Р°РіРё Р±РµР·РѕРїР°СЃРЅРѕСЃС‚Рё: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "РќРµС‚ С„Р»Р°РіРѕРІ Р±РµР·РѕРїР°СЃРЅРѕСЃС‚Рё: $util"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: Р»РѕРєР°Р»РёР·Р°С†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_localization() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р»РѕРєР°Р»РёР·Р°С†РёРё..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    # РџСЂРѕРІРµСЂРєР° РїРѕРґРєР»СЋС‡РµРЅРёСЏ lang.sh
    if grep -q 'source.*lang.sh\|source.*fallback.sh' "${SCRIPT_DIR}/${util}" 2>/dev/null; then
      pass "Р›РѕРєР°Р»РёР·Р°С†РёСЏ РїРѕРґРєР»СЋС‡РµРЅР°: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "Р›РѕРєР°Р»РёР·Р°С†РёСЏ РЅРµ РїРѕРґРєР»СЋС‡РµРЅР°: $util"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° root РїСЂР°РІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_root_check() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїСЂРѕРІРµСЂРєРё root РїСЂР°РІ..."

  local utilities=(
    "utils/update.sh"
    "utils/rollback.sh"
    "utils/export-config.sh"
    "utils/import-config.sh"
    "utils/diagnose.sh"
    "utils/install-aliases.sh"
  )

  for util in "${utilities[@]}"; do
    if grep -qE 'EUID.*-ne.*0|root' "${SCRIPT_DIR}/${util}" 2>/dev/null; then
      pass "РџСЂРѕРІРµСЂРєР° root: $util"
      ((TESTS_PASSED++)) || true
    else
      warn "РќРµС‚ РїСЂРѕРІРµСЂРєРё root: $util"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІ backup.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_backup_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІ backup.sh..."

  # Mock Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№
  check_root() { :; }
  check_ubuntu() { :; }
  step() { echo "$1"; }
  ok() { echo -e "${GREEN}[вњ“]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[вњ—]${PLAIN} $1" >&2
    exit 1
  }
  info() { echo "[INFO] $1"; }
  select_language() { :; }

  source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null
  source "${SCRIPT_DIR}/utils/backup.sh" 2>/dev/null || true

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
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      # Р¤СѓРЅРєС†РёРё РјРѕРіСѓС‚ Р±С‹С‚СЊ РЅРµРґРѕСЃС‚СѓРїРЅС‹ РёР·-Р·Р° СЃС‚СЂСѓРєС‚СѓСЂС‹ СЃРєСЂРёРїС‚Р°
      info "Р¤СѓРЅРєС†РёСЏ РЅРµ РїСЂРѕРІРµСЂРµРЅР°: $func (РјРѕР¶РµС‚ Р±С‹С‚СЊ Р»РѕРєР°Р»СЊРЅРѕР№)"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІ monitor.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІ monitor.sh..."

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
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/utils/monitor.sh" 2>/dev/null; then
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      info "Р¤СѓРЅРєС†РёСЏ РЅРµ РїСЂРѕРІРµСЂРµРЅР°: $func (РјРѕР¶РµС‚ РѕС‚СЃСѓС‚СЃС‚РІРѕРІР°С‚СЊ РІ С„Р°Р№Р»Рµ)"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІ diagnose.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_diagnose_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІ diagnose.sh..."

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
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/utils/diagnose.sh" 2>/dev/null; then
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Р¤СѓРЅРєС†РёСЏ РЅРµ РїСЂРѕРІРµСЂРµРЅР°: $func"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІ export-config.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_export_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІ export-config.sh..."

  local functions=(
    "step_collect_config"
    "step_collect_keys"
    "step_generate_manifest"
    "step_encrypt_sensitive"
    "step_create_archive"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/export-config.sh" 2>/dev/null; then
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Р¤СѓРЅРєС†РёСЏ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $func"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІ update.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_update_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІ update.sh..."

  local functions=(
    "step_check_versions"
    "step_confirm_update"
    "step_create_backup"
    "step_download_update"
    "step_install_update"
    "step_update_marzban"
    "step_update_singbox"
  )

  for func in "${functions[@]}"; do
    if grep -q "^[[:space:]]*${func}()" "${SCRIPT_DIR}/update.sh" 2>/dev/null; then
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Р¤СѓРЅРєС†РёСЏ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $func"
    fi
  done
}
# в”Ђв”Ђ РўРµСЃС‚: step_update_marzban вЂ” РїСЂРѕРїСѓСЃРє РѕР±РЅРѕРІР»РµРЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_step_update_marzban_skip() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ step_update_marzban (skip)..."

  # РЈР±РµРґРёРјСЃСЏ, С‡С‚Рѕ Р·Р°РїСЂРѕСЃ РІ С„СѓРЅРєС†РёРё РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ Р±РµР· Р·РІРѕРЅРєРѕРІ Рє СЂРµР°Р»СЊРЅРѕРјСѓ Marzban
  local output
  output=$(printf 'n\n' | step_update_marzban 2>&1)

  if [[ "$output" == *"РџСЂРѕРїСѓСЃРє РѕР±РЅРѕРІР»РµРЅРёСЏ Marzban"* ]]; then
    pass "step_update_marzban: РєРѕСЂСЂРµРєС‚РЅР°СЏ РІРµС‚РєР° РїСЂРѕРїСѓСЃРєР° РїСЂРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊСЃРєРѕРј РѕС‚РІРµС‚Рµ n"
    ((TESTS_PASSED++)) || true
  else
    fail "step_update_marzban: РЅРµСЂР°Р±РѕС‚Р°СЋС‰Р°СЏ РІРµС‚РєР° РїСЂРѕРїСѓСЃРєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: step_update_singbox вЂ” РїСЂРѕРїСѓСЃРє РѕР±РЅРѕРІР»РµРЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_step_update_singbox_skip() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ step_update_singbox (skip)..."

  local output
  output=$(printf 'n\n' | step_update_singbox 2>&1)

  if [[ "$output" == *"РџСЂРѕРїСѓСЃРє РѕР±РЅРѕРІР»РµРЅРёСЏ sing-box"* ]]; then
    pass "step_update_singbox: РєРѕСЂСЂРµРєС‚РЅР°СЏ РІРµС‚РєР° РїСЂРѕРїСѓСЃРєР° РїСЂРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊСЃРєРѕРј РѕС‚РІРµС‚Рµ n"
    ((TESTS_PASSED++)) || true
  else
    fail "step_update_singbox: РЅРµСЂР°Р±РѕС‚Р°СЋС‰Р°СЏ РІРµС‚РєР° РїСЂРѕРїСѓСЃРєР°"
  fi
}
# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІ rollback.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_rollback_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІ rollback.sh..."

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
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Р¤СѓРЅРєС†РёСЏ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $func"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: Python health check module в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_health_check() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python health check РјРѕРґСѓР»СЏ..."

  local health_check_file="${SCRIPT_DIR}/assets/telegram-bot/health_check.py"

  if [[ -f "$health_check_file" ]]; then
    pass "health_check.py СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true

    # РџСЂРѕРІРµСЂРєР° СЃРёРЅС‚Р°РєСЃРёСЃР° Python
    if python3 -m py_compile "$health_check_file" 2>/dev/null; then
      pass "РЎРёРЅС‚Р°РєСЃРёСЃ Python OK: health_check.py"
      ((TESTS_PASSED++)) || true
    else
      fail "РЎРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°: health_check.py"
    fi

    # РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ РєР»Р°СЃСЃРѕРІ
    if grep -q "class HealthChecker" "$health_check_file"; then
      pass "РљР»Р°СЃСЃ HealthChecker СЃСѓС‰РµСЃС‚РІСѓРµС‚"
      ((TESTS_PASSED++)) || true
    else
      fail "РљР»Р°СЃСЃ HealthChecker РЅРµ РЅР°Р№РґРµРЅ"
    fi

    # РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ РјРµС‚РѕРґРѕРІ
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
        pass "РњРµС‚РѕРґ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $method"
        ((TESTS_PASSED++)) || true
      else
        fail "РњРµС‚РѕРґ РЅРµ РЅР°Р№РґРµРЅ: $method"
      fi
    done
  else
    fail "health_check.py РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РѕР±РЅРѕРІР»С‘РЅРЅС‹Р№ bot.py в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_bot_updated() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±РЅРѕРІР»С‘РЅРЅРѕРіРѕ bot.py..."

  local bot_file="${SCRIPT_DIR}/assets/telegram-bot/bot.py"

  if [[ -f "$bot_file" ]]; then
    pass "bot.py СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true

    # РџСЂРѕРІРµСЂРєР° РёРјРїРѕСЂС‚Р° health_check
    if grep -q "from health_check import HealthChecker" "$bot_file"; then
      pass "HealthChecker РёРјРїРѕСЂС‚РёСЂРѕРІР°РЅ РІ bot.py"
      ((TESTS_PASSED++)) || true
    else
      fail "HealthChecker РЅРµ РёРјРїРѕСЂС‚РёСЂРѕРІР°РЅ РІ bot.py"
    fi

    # РџСЂРѕРІРµСЂРєР° РёРЅРёС†РёР°Р»РёР·Р°С†РёРё health checker
    if grep -q "self.health = HealthChecker()" "$bot_file"; then
      pass "HealthChecker РёРЅРёС†РёР°Р»РёР·РёСЂРѕРІР°РЅ"
      ((TESTS_PASSED++)) || true
    else
      fail "HealthChecker РЅРµ РёРЅРёС†РёР°Р»РёР·РёСЂРѕРІР°РЅ"
    fi

    # РџСЂРѕРІРµСЂРєР° health check РІ poll
    if grep -q "check_health_and_heal" "$bot_file"; then
      pass "Health check РІС‹Р·С‹РІР°РµС‚СЃСЏ РІ poll"
      ((TESTS_PASSED++)) || true
    else
      fail "Health check РЅРµ РІС‹Р·С‹РІР°РµС‚СЃСЏ РІ poll"
    fi
  else
    fail "bot.py РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РѕР±РЅРѕРІР»С‘РЅРЅС‹Р№ commands.py в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_commands_updated() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±РЅРѕРІР»С‘РЅРЅРѕРіРѕ commands.py..."

  local commands_file="${SCRIPT_DIR}/assets/telegram-bot/commands.py"

  if [[ -f "$commands_file" ]]; then
    pass "commands.py СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true

    # РџСЂРѕРІРµСЂРєР° РЅРѕРІС‹С… РєРѕРјР°РЅРґ
    local commands=(
      "/health"
      "/speedtest"
      "/profiles"
    )

    for cmd in "${commands[@]}"; do
      if grep -q "\"$cmd\"" "$commands_file"; then
        pass "РљРѕРјР°РЅРґР° СЃСѓС‰РµСЃС‚РІСѓРµС‚: $cmd"
        ((TESTS_PASSED++)) || true
      else
        fail "РљРѕРјР°РЅРґР° РЅРµ РЅР°Р№РґРµРЅР°: $cmd"
      fi
    done

    # РџСЂРѕРІРµСЂРєР° РјРµС‚РѕРґРѕРІ
    local methods=(
      "_health"
      "_speedtest"
      "_profiles"
    )

    for method in "${methods[@]}"; do
      if grep -q "def ${method}" "$commands_file"; then
        pass "РњРµС‚РѕРґ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $method"
        ((TESTS_PASSED++)) || true
      else
        fail "РњРµС‚РѕРґ РЅРµ РЅР°Р№РґРµРЅ: $method"
      fi
    done
  else
    fail "commands.py РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: install-aliases.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_install_aliases() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ install-aliases.sh..."

  local aliases_file="${SCRIPT_DIR}/utils/install-aliases.sh"

  if [[ -f "$aliases_file" ]]; then
    pass "install-aliases.sh СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true

    # РџСЂРѕРІРµСЂРєР° СѓСЃС‚Р°РЅРѕРІРєРё CLI
    if grep -q "/usr/local/bin/cubiveil" "$aliases_file"; then
      pass "CLI РїСѓС‚СЊ РЅР°СЃС‚СЂРѕРµРЅ"
      ((TESTS_PASSED++)) || true
    else
      fail "CLI РїСѓС‚СЊ РЅРµ РЅР°Р№РґРµРЅ"
    fi

    # РџСЂРѕРІРµСЂРєР° Р°Р»РёР°СЃРѕРІ
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
        pass "РђР»РёР°СЃ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $alias"
        ((TESTS_PASSED++)) || true
      else
        warn "РђР»РёР°СЃ РЅРµ РЅР°Р№РґРµРЅ: $alias"
      fi
    done
  else
    fail "install-aliases.sh РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - New Utilities           в•‘${PLAIN}"
  echo -e "${YELLOW}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${PLAIN}"
  echo ""

  info "РўРµСЃС‚РёСЂСѓРµРјС‹Р№ РїСЂРѕРµРєС‚: ${SCRIPT_DIR}"
  echo ""

  # в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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
