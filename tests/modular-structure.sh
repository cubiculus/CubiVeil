#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - Modular Structure            в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РјРѕРґСѓР»СЊРЅРѕР№ Р°СЂС…РёС‚РµРєС‚СѓСЂС‹                в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# РСЃРїРѕР»СЊР·СѓРµРј СѓРЅРёРєР°Р»СЊРЅРѕРµ РёРјСЏ РїРµСЂРµРјРµРЅРЅРѕР№ С‡С‚РѕР±С‹ РёР·Р±РµР¶Р°С‚СЊ РїРµСЂРµР·Р°РїРёСЃРё
MODULAR_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${MODULAR_SCRIPT_DIR}/lib/test-utils.sh"

# в”Ђв”Ђ РўРµСЃС‚: СЃС‚СЂСѓРєС‚СѓСЂР° РґРёСЂРµРєС‚РѕСЂРёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_directory_structure() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃС‚СЂСѓРєС‚СѓСЂС‹ РґРёСЂРµРєС‚РѕСЂРёР№..."

  # РџСЂРѕРІРµСЂРєР° РѕСЃРЅРѕРІРЅС‹С… РґРёСЂРµРєС‚РѕСЂРёР№
  local dirs=(
    "lib"
    "tests"
  )

  for dir in "${dirs[@]}"; do
    if [[ -d "${MODULAR_SCRIPT_DIR}/${dir}" ]]; then
      pass "Р”РёСЂРµРєС‚РѕСЂРёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $dir"
      ((TESTS_PASSED++)) || true
    else
      fail "Р”РёСЂРµРєС‚РѕСЂРёСЏ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $dir"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РѕСЃРЅРѕРІРЅС‹С… С„Р°Р№Р»РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_main_files() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РѕСЃРЅРѕРІРЅС‹С… С„Р°Р№Р»РѕРІ..."

  local files=(
    "install.sh"
    "setup-telegram.sh"
    "lang.sh"
    "README.md"
    "run-tests.sh"
  )

  for file in "${files[@]}"; do
    if [[ -f "${MODULAR_SCRIPT_DIR}/${file}" ]]; then
      pass "Р¤Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚: $file"
      ((TESTS_PASSED++)) || true
    else
      warn "Р¤Р°Р№Р» РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $file"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: РјРѕРґСѓР»Рё lib в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_lib_modules() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РјРѕРґСѓР»РµР№ РІ lib/..."

  local lib_files=(
    "lib/utils.sh"
    "lib/install-steps.sh"
  )

  for file in "${lib_files[@]}"; do
    if [[ -f "${MODULAR_SCRIPT_DIR}/${file}" ]]; then
      pass "РњРѕРґСѓР»СЊ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $file"
      ((TESTS_PASSED++)) || true
    else
      fail "РњРѕРґСѓР»СЊ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $file"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: С‚РµСЃС‚РѕРІС‹Рµ С„Р°Р№Р»С‹ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_test_files() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С‚РµСЃС‚РѕРІС‹С… С„Р°Р№Р»РѕРІ..."

  local test_files=(
    "tests/integration-test.sh"
    "tests/unit-utils.sh"
    "tests/unit-telegram.sh"
    "tests/modular-structure.sh"
  )

  for file in "${test_files[@]}"; do
    if [[ -f "${MODULAR_SCRIPT_DIR}/${file}" ]]; then
      pass "РўРµСЃС‚РѕРІС‹Р№ С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚: $file"
      ((TESTS_PASSED++)) || true
    else
      warn "РўРµСЃС‚РѕРІС‹Р№ С„Р°Р№Р» РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $file"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ РІСЃРµС… СЃРєСЂРёРїС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_all_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР° РІСЃРµС… СЃРєСЂРёРїС‚РѕРІ..."

  local scripts=(
    "install.sh"
    "setup-telegram.sh"
    "lib/utils.sh"
    "lib/install-steps.sh"
    "tests/integration-test.sh"
    "tests/unit-utils.sh"
    "tests/unit-telegram.sh"
    "tests/modular-structure.sh"
    "run-tests.sh"
  )

  for script in "${scripts[@]}"; do
    if [[ -f "${MODULAR_SCRIPT_DIR}/${script}" ]]; then
      if bash -n "${MODULAR_SCRIPT_DIR}/${script}" 2>/dev/null; then
        pass "РЎРёРЅС‚Р°РєСЃРёСЃ OK: $script"
        ((TESTS_PASSED++)) || true
      else
        fail "РЎРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°: $script"
      fi
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: РёСЃРїРѕР»РЅРёРјРѕСЃС‚СЊ СЃРєСЂРёРїС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_executable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РёСЃРїРѕР»РЅРёРјРѕСЃС‚Рё СЃРєСЂРёРїС‚РѕРІ..."

  local exec_scripts=(
    "install.sh"
    "setup-telegram.sh"
    "lib/utils.sh"
    "lib/install-steps.sh"
    "tests/integration-test.sh"
    "tests/unit-utils.sh"
    "tests/unit-telegram.sh"
    "tests/modular-structure.sh"
    "run-tests.sh"
  )

  for script in "${exec_scripts[@]}"; do
    local script_path="${MODULAR_SCRIPT_DIR}/${script}"
    if [[ -f "$script_path" ]]; then
      if [[ -x "$script_path" ]]; then
        pass "РСЃРїРѕР»РЅРёРјС‹Р№: $script"
        ((TESTS_PASSED++)) || true
      else
        warn "РќРµ РёСЃРїРѕР»РЅРёРјС‹Р№: $script (chmod +x РјРѕР¶РµС‚ РїРѕРЅР°РґРѕР±РёС‚СЊСЃСЏ)"
      fi
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: Р·Р°РіСЂСѓР·РєР° РјРѕРґСѓР»РµР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_loading() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р·Р°РіСЂСѓР·РєРё РјРѕРґСѓР»РµР№..."

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

  # РџСЂРѕРІРµСЂРєР° Р·Р°РіСЂСѓР·РєРё lib/utils.sh
  if bash -c "source ${MODULAR_SCRIPT_DIR}/lib/utils.sh 2>&1"; then
    pass "РњРѕРґСѓР»СЊ Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ: lib/utils.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "РњРѕРґСѓР»СЊ РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ: lib/utils.sh"
  fi

  # РџСЂРѕРІРµСЂРєР° Р·Р°РіСЂСѓР·РєРё lib/install-steps.sh (Р·Р°РІРёСЃРёС‚ РѕС‚ utils.sh)
  if bash -c "source ${MODULAR_SCRIPT_DIR}/lib/utils.sh && source ${MODULAR_SCRIPT_DIR}/lib/install-steps.sh 2>&1"; then
    pass "РњРѕРґСѓР»СЊ Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ: lib/install-steps.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "РњРѕРґСѓР»СЊ РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ: lib/install-steps.sh"
  fi

  # РџСЂРѕРІРµСЂРєР° Р·Р°РіСЂСѓР·РєРё lang.sh
  if [[ -f "${MODULAR_SCRIPT_DIR}/lang.sh" ]]; then
    if bash -c "source ${MODULAR_SCRIPT_DIR}/lang.sh 2>&1"; then
      pass "РњРѕРґСѓР»СЊ Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ: lang.sh"
      ((TESTS_PASSED++)) || true
    else
      warn "РњРѕРґСѓР»СЊ РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ: lang.sh"
    fi
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІ lib/utils.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_utils_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІ lib/utils.sh..."

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

  # Р—Р°РіСЂСѓР¶Р°РµРј РјРѕРґСѓР»СЊ
  source "${MODULAR_SCRIPT_DIR}/lib/utils.sh"

  local functions=(
    "gen_random"
    "gen_hex"
    "gen_port"
    "unique_port"
    "arch"
    "get_server_ip"
    "open_port"
  )

  for func in "${functions[@]}"; do
    if declare -f "$func" >/dev/null; then
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Р¤СѓРЅРєС†РёСЏ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $func"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІ lib/install-steps.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# shellcheck disable=SC2218
test_install_steps_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІ lib/install-steps.sh..."

  # Mock Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№
  check_root() { :; }
  check_ubuntu() { :; }
  step() { echo "$1"; }
  step_title() { echo "$1"; }
  ok() { echo -e "${GREEN}[вњ“]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[вњ—]${PLAIN} $1" >&2
    exit 1
  }
  info() { echo "[INFO] $1"; }

  # Р—Р°РіСЂСѓР¶Р°РµРј РјРѕРґСѓР»Рё
  source "${MODULAR_SCRIPT_DIR}/lib/utils.sh"
  source "${MODULAR_SCRIPT_DIR}/lib/install-steps.sh"

  local functions=(
    "prompt_inputs"
    "step_check_ip_neighborhood"
    "step_system_update"
    "step_auto_updates"
    "step_bbr"
    "step_firewall"
    "step_fail2ban"
    "step_install_singbox"
    "step_generate_keys_and_ports"
    "step_install_marzban"
    "step_ssl"
    "step_configure"
    "step_finish"
  )

  for func in "${functions[@]}"; do
    if declare -f "$func" >/dev/null; then
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      fail "Р¤СѓРЅРєС†РёСЏ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $func"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: РѕС‚СЃСѓС‚СЃС‚РІРёРµ РґСѓР±Р»РёСЂРѕРІР°РЅРёСЏ РєРѕРґР° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_code_duplication() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕС‚СЃСѓС‚СЃС‚РІРёСЏ РґСѓР±Р»РёСЂРѕРІР°РЅРёСЏ РєРѕРґР°..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ install.sh РЅРµ СЃРѕРґРµСЂР¶РёС‚ РєРѕРґ Telegram Р±РѕС‚Р°
  if ! grep -q 'cubiveil-bot' "${MODULAR_SCRIPT_DIR}/install.sh" 2>/dev/null; then
    pass "install.sh: РЅРµ СЃРѕРґРµСЂР¶РёС‚ РєРѕРґ Telegram Р±РѕС‚Р° (РїСЂР°РІРёР»СЊРЅРѕ)"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: СЃРѕРґРµСЂР¶РёС‚ РєРѕРґ Telegram Р±РѕС‚Р° (РґСѓР±Р»РёСЂРѕРІР°РЅРёРµ!)"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ lib/utils.sh РЅРµ СЃРѕРґРµСЂР¶РёС‚ СЃРїРµС†РёС„РёС‡РЅС‹Р№ РєРѕРґ СѓСЃС‚Р°РЅРѕРІРєРё
  if ! grep -q 'step_' "${MODULAR_SCRIPT_DIR}/lib/utils.sh" 2>/dev/null; then
    pass "lib/utils.sh: РЅРµ СЃРѕРґРµСЂР¶РёС‚ С„СѓРЅРєС†РёРё step_* (РїСЂР°РІРёР»СЊРЅРѕ)"
    ((TESTS_PASSED++)) || true
  else
    warn "lib/utils.sh: СЃРѕРґРµСЂР¶РёС‚ С„СѓРЅРєС†РёРё step_* (РІРѕР·РјРѕР¶РЅРѕРµ РґСѓР±Р»РёСЂРѕРІР°РЅРёРµ)"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ lib/install-steps.sh РЅРµ СЃРѕРґРµСЂР¶РёС‚ РѕР±С‰РёРµ СѓС‚РёР»РёС‚С‹
  if ! grep -q 'gen_random\|gen_hex\|gen_port' "${MODULAR_SCRIPT_DIR}/lib/install-steps.sh" 2>/dev/null; then
    pass "lib/install-steps.sh: РЅРµ СЃРѕРґРµСЂР¶РёС‚ РѕР±С‰РёРµ СѓС‚РёР»РёС‚С‹ (РїСЂР°РІРёР»СЊРЅРѕ)"
    ((TESTS_PASSED++)) || true
  else
    warn "lib/install-steps.sh: СЃРѕРґРµСЂР¶РёС‚ РѕР±С‰РёРµ СѓС‚РёР»РёС‚С‹ (РІРѕР·РјРѕР¶РЅРѕРµ РґСѓР±Р»РёСЂРѕРІР°РЅРёРµ)"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЂР°Р·РјРµСЂ С„Р°Р№Р»РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_file_sizes() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЂР°Р·РјРµСЂРѕРІ С„Р°Р№Р»РѕРІ..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ install.sh РЅРµ СЃР»РёС€РєРѕРј Р±РѕР»СЊС€РѕР№ (СЂРµС„Р°РєС‚РѕСЂРёРЅРі СѓРґР°Р»СЃСЏ)
  local install_size
  install_size=$(wc -l <"${MODULAR_SCRIPT_DIR}/install.sh" 2>/dev/null || echo "0")

  if [[ $install_size -lt 200 ]]; then
    pass "install.sh: РєРѕРјРїР°РєС‚РЅС‹Р№ (${install_size} СЃС‚СЂРѕРє)"
    ((TESTS_PASSED++)) || true
  elif [[ $install_size -lt 500 ]]; then
    warn "install.sh: СѓРјРµСЂРµРЅРЅРѕРіРѕ СЂР°Р·РјРµСЂР° (${install_size} СЃС‚СЂРѕРє)"
  else
    fail "install.sh: СЃР»РёС€РєРѕРј Р±РѕР»СЊС€РѕР№ (${install_size} СЃС‚СЂРѕРє), РЅСѓР¶РµРЅ СЂРµС„Р°РєС‚РѕСЂРёРЅРі"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ setup-telegram.sh РёРјРµРµС‚ СЂР°Р·СѓРјРЅС‹Р№ СЂР°Р·РјРµСЂ
  local telegram_size
  telegram_size=$(wc -l <"${MODULAR_SCRIPT_DIR}/setup-telegram.sh" 2>/dev/null || echo "0")

  if [[ $telegram_size -gt 0 ]]; then
    pass "setup-telegram.sh: СЃРѕРґРµСЂР¶РёС‚ РєРѕРґ (${telegram_size} СЃС‚СЂРѕРє)"
    ((TESTS_PASSED++)) || true
  else
    fail "setup-telegram.sh: РїСѓСЃС‚ РёР»Рё РЅРµ РЅР°Р№РґРµРЅ"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ lib/utils.sh РёРјРµРµС‚ СЂР°Р·СѓРјРЅС‹Р№ СЂР°Р·РјРµСЂ
  local utils_size
  utils_size=$(wc -l <"${MODULAR_SCRIPT_DIR}/lib/utils.sh" 2>/dev/null || echo "0")

  if [[ $utils_size -gt 0 ]]; then
    pass "lib/utils.sh: СЃРѕРґРµСЂР¶РёС‚ РєРѕРґ (${utils_size} СЃС‚СЂРѕРє)"
    ((TESTS_PASSED++)) || true
  else
    fail "lib/utils.sh: РїСѓСЃС‚ РёР»Рё РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РёРЅС‚РµРіСЂР°С†РёСЏ РјРѕРґСѓР»РµР№ РІ install.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_install_sh_integration() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РёРЅС‚РµРіСЂР°С†РёРё РјРѕРґСѓР»РµР№ РІ install.sh..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ install.sh Р·Р°РіСЂСѓР¶Р°РµС‚ РјРѕРґСѓР»Рё
  if grep -q 'source.*lib/utils.sh' "${MODULAR_SCRIPT_DIR}/install.sh"; then
    pass "install.sh: Р·Р°РіСЂСѓР¶Р°РµС‚ lib/utils.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚ lib/utils.sh"
  fi

  if grep -q 'source.*lib/install-steps.sh' "${MODULAR_SCRIPT_DIR}/install.sh"; then
    pass "install.sh: Р·Р°РіСЂСѓР¶Р°РµС‚ lib/install-steps.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚ lib/install-steps.sh"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ install.sh РёСЃРїРѕР»СЊР·СѓРµС‚ С„СѓРЅРєС†РёРё РёР· РјРѕРґСѓР»РµР№
  if grep -q 'prompt_inputs\|step_check_ip_neighborhood\|step_finish' "${MODULAR_SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РёСЃРїРѕР»СЊР·СѓРµС‚ С„СѓРЅРєС†РёРё РёР· РјРѕРґСѓР»РµР№"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: РЅРµ РёСЃРїРѕР»СЊР·СѓРµС‚ С„СѓРЅРєС†РёРё РёР· РјРѕРґСѓР»РµР№"
  fi
}

# shellcheck disable=SC2218
# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - Modular Structure       в•‘${PLAIN}"
  echo -e "${YELLOW}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${PLAIN}"
  echo ""

  info "РўРµСЃС‚РёСЂСѓРµРјС‹Р№ РїСЂРѕРµРєС‚: ${MODULAR_SCRIPT_DIR}"
  echo ""

  # в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  test_directory_structure
  echo ""

  test_main_files
  echo ""

  test_lib_modules
  echo ""

  test_test_files
  echo ""

  test_all_syntax
  echo ""

  test_executable
  echo ""

  test_module_loading
  echo ""

  test_utils_functions
  echo ""

  test_install_steps_functions
  echo ""

  test_code_duplication
  echo ""

  test_file_sizes
  echo ""

  test_install_sh_integration
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
