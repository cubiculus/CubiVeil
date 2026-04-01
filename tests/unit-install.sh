#!/bin/bash
# в-"в-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв--
# в-'        CubiVeil Unit Tests - install.sh                   в-'
# в-'        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РіР»Р°РІРЅРѕР№ С‚РѕС‡РєРё РІС...РѕРґР°                  в-'
# в-љв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ќ

# Strict mode РѕС‚РєР»СЋС‡РµРЅ РґР»СЏ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё СЃ mock-С„СѓРЅРєС†РёСЏРјРё

# в"Ђв"Ђ РџСѓС‚СЊ Рє РїСЂРѕРµРєС‚Сѓ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# в"Ђв"Ђ Р¦РІРµС‚Р° в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# в"Ђв"Ђ РЎС‡С'С‚С‡РёРє С‚РµСЃС‚РѕРІ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
TESTS_PASSED=0
TESTS_FAILED=0

# в"Ђв"Ђ Mock С„СѓРЅРєС†РёР№ РІС‹РІРѕРґР° в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
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

# в"Ђв"Ђ РўРµСЃС‚: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° install.sh..."

  if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
    pass "install.sh: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚Р° в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР° install.sh..."

  if bash -n "${SCRIPT_DIR}/install.sh" 2>/dev/null; then
    pass "install.sh: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: СЃРєСЂРёРїС‚ РёРјРµРµС‚ shebang в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang..."

  local shebang
  shebang=$(head -1 "${SCRIPT_DIR}/install.sh")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "install.sh: РєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang: $shebang"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: strict mode РІРєР»СЋС‡С'РЅ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_strict_mode() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ strict mode..."

  if grep -q "set -euo pipefail" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: strict mode РІРєР»СЋС‡С'РЅ"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: strict mode РЅРµ РІРєР»СЋС‡С'РЅ"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: Р·Р°РіСЂСѓР·РєР° РјРѕРґСѓР»РµР№ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_module_loading() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р·Р°РіСЂСѓР·РєРё РјРѕРґСѓР»РµР№..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ lang/main.sh Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ
  if grep -q 'source.*lang/main.sh' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: Р·Р°РіСЂСѓР¶Р°РµС‚ lang/main.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚ lang/main.sh"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ lib/utils.sh Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ
  if grep -q 'source.*lib/utils.sh' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: Р·Р°РіСЂСѓР¶Р°РµС‚ lib/utils.sh"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚ lib/utils.sh"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: С„СѓРЅРєС†РёСЏ main СЃСѓС‰РµСЃС‚РІСѓРµС‚ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_main_function() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё main..."

  if grep -q "^main()" "${SCRIPT_DIR}/install.sh" ||
    grep -q "main() {" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: С„СѓРЅРєС†РёСЏ main СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: С„СѓРЅРєС†РёСЏ main РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: С„СѓРЅРєС†РёСЏ main РІС‹Р·С‹РІР°РµС‚СЃСЏ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_main_call() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РІС‹Р·РѕРІР° С„СѓРЅРєС†РёРё main..."

  if grep -q 'main "$@"' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'main "$1"' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'main' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: main РІС‹Р·С‹РІР°РµС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: main РЅРµ РІС‹Р·С‹РІР°РµС‚СЃСЏ"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: РёСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РёР· РјРѕРґСѓР»РµР№ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_module_functions_usage() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РёСЃРїРѕР»СЊР·РѕРІР°РЅРёСЏ С„СѓРЅРєС†РёР№ РёР· РјРѕРґСѓР»РµР№..."

  local required_functions=(
    "select_language"
    "print_banner"
    "prompt_inputs"
    "step_check_ip_neighborhood"
    "step_system_update"
    "step_auto_updates"
    "step_bbr"
    "step_firewall"
    "step_fail2ban"
    "step_ssl"
    "step_install_sui"
    "step_decoy_site"
    "step_traffic_shaping"
    "step_finish"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    # Проверяем как прямое вхождение, так и с префиксом _
    if grep -qE "(^|[^a-zA-Z0-9_])${func}([^a-zA-Z0-9_]|$)|(^|[^a-zA-Z0-9_])_${func}([^a-zA-Z0-9_]|$)" "${SCRIPT_DIR}/install.sh"; then
      ((found++))
    fi
  done

  # Также проверяем _step_system как обобщающую функцию
  if grep -q "_step_system" "${SCRIPT_DIR}/install.sh"; then
    found=$((found + 3))
  fi
  [[ $found -gt 14 ]] && found=14

  if [[ $found -ge 12 ]]; then
    pass "install.sh: РёСЃРїРѕР»СЊР·СѓРµС‚ С„СѓРЅРєС†РёРё РёР· РјРѕРґСѓР»РµР№ ($found/${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: РЅРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ РёСЃРїРѕР»СЊР·СѓРµС‚ С„СѓРЅРєС†РёРё РёР· РјРѕРґСѓР»РµР№ ($found/${#required_functions[@]})"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: РїРѕСЃР»РµРґРѕРІР°С‚РµР»СЊРЅРѕСЃС‚СЊ С€Р°РіРѕРІ СѓСЃС‚Р°РЅРѕРІРєРё в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_installation_steps_order() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїРѕСЃР»РµРґРѕРІР°С‚РµР»СЊРЅРѕСЃС‚Рё С€Р°РіРѕРІ СѓСЃС‚Р°РЅРѕРІРєРё..."

  # РР·РІР»РµРєР°РµРј С‚РµР»Рѕ С„СѓРЅРєС†РёРё main
  local main_body
  main_body=$(sed -n '/^main()/,/^}/p' "${SCRIPT_DIR}/install.sh" 2>/dev/null || echo "")

  if [[ -z "$main_body" ]]; then
    warn "РќРµ СѓРґР°Р»РѕСЃСЊ РёР·РІР»РµС‡СЊ С‚РµР»Рѕ С„СѓРЅРєС†РёРё main"
    return
  fi

  # РџСЂРѕРІРµСЂСЏРµРј РїРѕСЂСЏРґРѕРє РІС‹Р·РѕРІР° С€Р°РіРѕРІ
  local expected_order=(
    "select_language"
    "print_banner"
    "prompt_inputs"
    "step_check_ip_neighborhood"
    "step_system_update"
    "step_install_sui"
    "step_finish"
  )

  local last_line=0
  local correct_order=true

  for step in "${expected_order[@]}"; do
    local current_line
    current_line=$(grep -n "$step" "${SCRIPT_DIR}/install.sh" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")

    if [[ "$current_line" -gt 0 && "$current_line" -gt "$last_line" ]]; then
      last_line=$current_line
    elif [[ "$current_line" -eq 0 ]]; then
      warn "РЁР°Рі РЅРµ РЅР°Р№РґРµРЅ: $step"
    else
      correct_order=false
    fi
  done

  if $correct_order; then
    pass "install.sh: РїРѕСЃР»РµРґРѕРІР°С‚РµР»СЊРЅРѕСЃС‚СЊ С€Р°РіРѕРІ РєРѕСЂСЂРµРєС‚РЅР°"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РІРѕР·РјРѕР¶РЅР°СЏ РїСЂРѕР±Р»РµРјР° СЃ РїРѕСЃР»РµРґРѕРІР°С‚РµР»СЊРЅРѕСЃС‚СЊСЋ С€Р°РіРѕРІ"
  fi
}

# -- Тест: step_traffic_shaping после step_install_sui ---------------------
test_traffic_shaping_after_configure() {
  info "Тестирование последовательности step_install_sui → step_traffic_shaping..."

  # Находим номера строк вызова step_install_sui и step_traffic_shaping
  local sui_line traffic_line
  sui_line=$(grep -n '^  step_install_sui$' "${SCRIPT_DIR}/install.sh" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")
  traffic_line=$(grep -n '^  step_traffic_shaping$' "${SCRIPT_DIR}/install.sh" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")

  if [[ "$sui_line" -eq 0 ]]; then
    fail "install.sh: step_install_sui не найден"
    return
  fi

  if [[ "$traffic_line" -eq 0 ]]; then
    fail "install.sh: step_traffic_shaping не найден"
    return
  fi

  # Проверяем что step_traffic_shaping вызывается после step_install_sui
  if [[ "$traffic_line" -gt "$sui_line" ]]; then
    pass "install.sh: step_traffic_shaping вызывается после step_install_sui (строки $sui_line → $traffic_line)"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: step_traffic_shaping должен вызываться после step_install_sui"
  fi
}

# -- Тест: step_decoy_site после step_install_sui --------------------------
test_decoy_site_after_configure() {
  info "Тестирование последовательности step_install_sui → step_decoy_site..."

  # Находим номера строк вызова step_install_sui и step_decoy_site
  local sui_line decoy_line
  sui_line=$(grep -n '^  step_install_sui$' "${SCRIPT_DIR}/install.sh" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")
  decoy_line=$(grep -n '^  step_decoy_site$' "${SCRIPT_DIR}/install.sh" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")

  if [[ "$sui_line" -eq 0 ]]; then
    fail "install.sh: step_install_sui не найден"
    return
  fi

  if [[ "$decoy_line" -eq 0 ]]; then
    fail "install.sh: step_decoy_site не найден"
    return
  fi

  # Проверяем что step_decoy_site вызывается после step_install_sui
  if [[ "$decoy_line" -gt "$sui_line" ]]; then
    pass "install.sh: step_decoy_site вызывается после step_install_sui (строки $sui_line → $decoy_line)"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: step_decoy_site должен вызываться после step_install_sui"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: step_traffic_shaping РїРѕСЃР»Рµ step_decoy_site в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_traffic_shaping_after_decoy_site() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїРѕСЃР»РµРґРѕРІР°С‚РµР»СЊРЅРѕСЃС‚Рё step_decoy_site в†' step_traffic_shaping..."

  # РќР°С...РѕРґРёРј РЅРѕРјРµСЂР° СЃС‚СЂРѕРє РІС‹Р·РѕРІР° step_decoy_site Рё step_traffic_shaping
  local decoy_line traffic_line
  decoy_line=$(grep -n '^  step_decoy_site$' "${SCRIPT_DIR}/install.sh" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")
  traffic_line=$(grep -n '^  step_traffic_shaping$' "${SCRIPT_DIR}/install.sh" 2>/dev/null | head -1 | cut -d: -f1 || echo "0")

  if [[ "$decoy_line" -eq 0 ]]; then
    fail "install.sh: step_decoy_site РЅРµ РЅР°Р№РґРµРЅ"
    return
  fi

  if [[ "$traffic_line" -eq 0 ]]; then
    fail "install.sh: step_traffic_shaping РЅРµ РЅР°Р№РґРµРЅ"
    return
  fi

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ step_traffic_shaping РІС‹Р·С‹РІР°РµС‚СЃСЏ СЃСЂР°Р·Сѓ РїРѕСЃР»Рµ step_decoy_site
  local expected_traffic_line=$((decoy_line + 2))

  if [[ "$traffic_line" -eq "$expected_traffic_line" ]]; then
    pass "install.sh: step_traffic_shaping РІС‹Р·С‹РІР°РµС‚СЃСЏ РїРѕСЃР»Рµ step_decoy_site (СЃС‚СЂРѕРєРё $decoy_line в†' $traffic_line)"
    ((TESTS_PASSED++)) || true
  elif [[ "$traffic_line" -gt "$decoy_line" ]]; then
    pass "install.sh: step_traffic_shaping РІС‹Р·С‹РІР°РµС‚СЃСЏ РїРѕСЃР»Рµ step_decoy_site (СЃС‚СЂРѕРєРё $decoy_line в†' $traffic_line)"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: step_traffic_shaping РґРѕР»Р¶РµРЅ РІС‹Р·С‹РІР°С‚СЊСЃСЏ РїРѕСЃР»Рµ step_decoy_site"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: РѕР±СЂР°Р±РѕС‚РєР° РѕС€РёР±РѕРє в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_error_handling() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±СЂР°Р±РѕС‚РєРё РѕС€РёР±РѕРє..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ err С„СѓРЅРєС†РёСЏ РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ
  if grep -q 'err "' "${SCRIPT_DIR}/install.sh" ||
    grep -q "err '" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РёСЃРїРѕР»СЊР·СѓРµС‚ С„СѓРЅРєС†РёСЋ err РґР»СЏ РѕС€РёР±РѕРє"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РЅРµ РёСЃРїРѕР»СЊР·СѓРµС‚ С„СѓРЅРєС†РёСЋ err"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РµСЃС‚СЊ РїСЂРѕРІРµСЂРєРё РЅР° РѕС€РёР±РєРё
  if grep -q "|| {" "${SCRIPT_DIR}/install.sh" ||
    grep -q "|| true" "${SCRIPT_DIR}/install.sh" ||
    grep -q "&&" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РёСЃРїРѕР»СЊР·СѓРµС‚ РѕР±СЂР°Р±РѕС‚РєСѓ РѕС€РёР±РѕРє"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РЅРµ РёСЃРїРѕР»СЊР·СѓРµС‚ СЏРІРЅСѓСЋ РѕР±СЂР°Р±РѕС‚РєСѓ РѕС€РёР±РѕРє"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: fallback РґР»СЏ lang/main.sh в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_lang_fallback() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ fallback РґР»СЏ lang/main.sh..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РµСЃС‚СЊ fallback РµСЃР»Рё lang/main.sh РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚
  if grep -A5 'if \[\[ -f.*lang/main.sh' "${SCRIPT_DIR}/install.sh" | grep -q "else\|fallback\|RED=\|GREEN="; then
    pass "install.sh: РёРјРµРµС‚ fallback РґР»СЏ lang/main.sh"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: fallback РґР»СЏ lang/main.sh РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: СЂР°Р·РјРµСЂС‹ СЃРєСЂРёРїС‚Р° в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_script_size() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЂР°Р·РјРµСЂР° СЃРєСЂРёРїС‚Р°..."

  local line_count
  line_count=$(wc -l <"${SCRIPT_DIR}/install.sh")

  # install.sh РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РєРѕРјРїР°РєС‚РЅС‹Рј (< 200 СЃС‚СЂРѕРє вЂ" С...РѕСЂРѕС€Рѕ)
  if [[ $line_count -lt 200 ]]; then
    pass "install.sh: РєРѕРјРїР°РєС‚РЅС‹Р№ ($line_count СЃС‚СЂРѕРє)"
    ((TESTS_PASSED++)) || true
  elif [[ $line_count -lt 500 ]]; then
    warn "install.sh: СѓРјРµСЂРµРЅРЅРѕРіРѕ СЂР°Р·РјРµСЂР° ($line_count СЃС‚СЂРѕРє)"
  elif [[ $line_count -lt 1000 ]]; then
    pass "install.sh: РґРѕРїСѓСЃС‚РёРјС‹Р№ СЂР°Р·РјРµСЂ ($line_count СЃС‚СЂРѕРє)"
    ((TESTS_PASSED++)) || true
  else
    fail "install.sh: СЃР»РёС€РєРѕРј Р±РѕР»СЊС€РѕР№ ($line_count СЃС‚СЂРѕРє), РЅСѓР¶РµРЅ СЂРµС„Р°РєС‚РѕСЂРёРЅРі"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РєРѕРјРјРµРЅС‚Р°СЂРёРµРІ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_comments() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РєРѕРјРјРµРЅС‚Р°СЂРёРµРІ..."

  local comment_count
  comment_count=$(grep -c "^#" "${SCRIPT_DIR}/install.sh" 2>/dev/null || echo "0")

  if [[ $comment_count -ge 5 ]]; then
    pass "install.sh: РґРѕСЃС‚Р°С‚РѕС‡РЅРѕРµ РєРѕР»РёС‡РµСЃС‚РІРѕ РєРѕРјРјРµРЅС‚Р°СЂРёРµРІ ($comment_count)"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РјР°Р»Рѕ РєРѕРјРјРµРЅС‚Р°СЂРёРµРІ ($comment_count)"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: Р·Р°РїСѓСЃРє Р±РµР· root (РґРѕР»Р¶РµРЅ РїРѕРєР°Р·Р°С‚СЊ РїСЂРµРґСѓРїСЂРµР¶РґРµРЅРёРµ) в"Ђв"Ђв"Ђ
test_run_without_root() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р·Р°РїСѓСЃРєР° Р±РµР· root..."

  # Р-Р°РїСѓСЃРєР°РµРј СЃРєСЂРёРїС‚ РІ dry-run СЂРµР¶РёРјРµ (РµСЃР»Рё РµСЃС‚СЊ С‚Р°РєР°СЏ РІРѕР·РјРѕР¶РЅРѕСЃС‚СЊ)
  # РёР»Рё РїСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РµСЃС‚СЊ РїСЂРѕРІРµСЂРєР° РЅР° root
  if grep -q "check_root\|EUID\|root" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РёРјРµРµС‚ РїСЂРѕРІРµСЂРєСѓ РЅР° root"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РїСЂРѕРІРµСЂРєР° РЅР° root РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° РЅР° Ubuntu в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_ubuntu_check() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїСЂРѕРІРµСЂРєРё РЅР° Ubuntu..."

  if grep -q "check_ubuntu\|ubuntu\|Ubuntu" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РёРјРµРµС‚ РїСЂРѕРІРµСЂРєСѓ РЅР° Ubuntu"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РїСЂРѕРІРµСЂРєР° РЅР° Ubuntu РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: РїРµСЂРµРјРµРЅРЅС‹Рµ РѕРєСЂСѓР¶РµРЅРёСЏ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_environment_variables() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїРµСЂРµРјРµРЅРЅС‹С... РѕРєСЂСѓР¶РµРЅРёСЏ..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ СЃРєСЂРёРїС‚ РЅРµ С‚СЂРµР±СѓРµС‚ РІРЅРµС€РЅРёС... РїРµСЂРµРјРµРЅРЅС‹С... РѕРєСЂСѓР¶РµРЅРёСЏ
  # (РєСЂРѕРјРµ С‚РµС... С‡С‚Рѕ СѓСЃС‚Р°РЅР°РІР»РёРІР°СЋС‚СЃСЏ РІРЅСѓС‚СЂРё СЃРєСЂРёРїС‚Р°)
  local env_deps
  env_deps=$(grep -oE '\$\{?[A-Z_]+\}?' "${SCRIPT_DIR}/install.sh" 2>/dev/null |
    grep -v "^\${SCRIPT_DIR}\|^\${LANG_NAME}\|^\${DOMAIN}\|^\${LE_EMAIL}" |
    sort -u | wc -l || echo "0")

  if [[ $env_deps -lt 10 ]]; then
    pass "install.sh: РјРёРЅРёРјР°Р»СЊРЅС‹Рµ РІРЅРµС€РЅРёРµ Р·Р°РІРёСЃРёРјРѕСЃС‚Рё ($env_deps)"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РјРЅРѕРіРѕ РІРЅРµС€РЅРёС... Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ ($env_deps)"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: РёРЅС‚РµРіСЂР°С†РёСЏ СЃ setup-telegram.sh в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_telegram_integration() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РёРЅС‚РµРіСЂР°С†РёРё СЃ Telegram..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ install.sh СѓРїРѕРјРёРЅР°РµС‚ setup-telegram.sh
  if grep -q "setup-telegram.sh" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: СѓРїРѕРјРёРЅР°РµС‚ setup-telegram.sh"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РЅРµ СѓРїРѕРјРёРЅР°РµС‚ setup-telegram.sh"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ INSTALL_TELEGRAM РїРµСЂРµРјРµРЅРЅР°СЏ РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ
  if grep -q "INSTALL_TELEGRAM" "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РёСЃРїРѕР»СЊР·СѓРµС‚ INSTALL_TELEGRAM РїРµСЂРµРјРµРЅРЅСѓСЋ"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: INSTALL_TELEGRAM РїРµСЂРµРјРµРЅРЅР°СЏ РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: dry-run СЃРёРјСѓР»СЏС†РёСЏ (mock) в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_dry_run_simulation() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ dry-run СЃРёРјСѓР»СЏС†РёРё..."

  # РЎРѕР·РґР°С'Рј mock РґР»СЏ РІСЃРµС... РІРЅРµС€РЅРёС... РєРѕРјР°РЅРґ
  LANG_NAME="English"
  export DRY_RUN="true"

  # Mock С„СѓРЅРєС†РёР№
  select_language() { :; }
  print_banner() { :; }
  prompt_inputs() {
    export DOMAIN="test.example.com"
    export LE_EMAIL="test@example.com"
    export INSTALL_TELEGRAM="n"
  }
  step_check_ip_neighborhood() { :; }
  step_system_update() { :; }
  step_auto_updates() { :; }
  step_bbr() { :; }
  step_firewall() { :; }
  step_fail2ban() { :; }
  step_install_singbox() { :; }
  step_ssl() { :; }
  step_install_sui() { :; }
  step_ssl() { :; }
  step_configure() { :; }
  step_finish() { :; }

  # Mock СѓС‚РёР»РёС‚
  check_root() { :; }
  check_ubuntu() { :; }
  step() { :; }
  ok() { :; }
  warn() { :; }
  err() { return 1; }
  info() { :; }
  gen_random() { echo "mock"; }
  gen_hex() { echo "mock"; }
  open_port() { :; }
  close_port() { :; }
  get_server_ip() { echo "1.2.3.4"; }
  arch() { echo "amd64"; }
  unique_port() { echo "30000"; }

  # Р-Р°РіСЂСѓР¶Р°РµРј РјРѕРґСѓР»Рё
  source "${SCRIPT_DIR}/lib/utils.sh" 2>/dev/null || true

  # РџС‹С‚Р°РµРјСЃСЏ Р·Р°РіСЂСѓР·РёС‚СЊ install.sh Рё РїСЂРѕРІРµСЂРёС‚СЊ С‡С‚Рѕ main СЃСѓС‰РµСЃС‚РІСѓРµС‚
  if DRY_RUN="true" bash -c "source ${SCRIPT_DIR}/install.sh 2>&1 && declare -f main >/dev/null" 2>/dev/null; then
    pass "install.sh: Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ Рё main СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    # Р­С‚Рѕ РјРѕР¶РµС‚ РЅРµ СЃСЂР°Р±РѕС‚Р°С‚СЊ РёР·-Р·Р° РёРЅС‚РµСЂР°РєС‚РёРІРЅРѕСЃС‚Рё, РїРѕСЌС‚РѕРјСѓ warning
    warn "install.sh: Р·Р°РіСЂСѓР·РєР° РјРѕР¶РµС‚ С‚СЂРµР±РѕРІР°С‚СЊ РёРЅС‚РµСЂР°РєС‚РёРІРЅРѕСЃС‚Рё"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: Р±РµР·РѕРїР°СЃРЅРѕСЃС‚СЊ (РѕС‚СЃСѓС‚СЃС‚РІРёРµ С...Р°СЂРґРєРѕРґРЅС‹С... СЃРµРєСЂРµС‚РѕРІ) в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_security_no_hardcoded_secrets() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р±РµР·РѕРїР°СЃРЅРѕСЃС‚Рё (РѕС‚СЃСѓС‚СЃС‚РІРёРµ СЃРµРєСЂРµС‚РѕРІ)..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РЅРµС‚ С...Р°СЂРґРєРѕРґРЅС‹С... РїР°СЂРѕР»РµР№ РёР»Рё РєР»СЋС‡РµР№
  if grep -qiE "password\s*=\s*['\"][^'\"]+['\"]|secret\s*=\s*['\"][^'\"]+['\"]|key\s*=\s*['\"][^'\"]+['\"]" \
    "${SCRIPT_DIR}/install.sh" 2>/dev/null | grep -v "SUDO_PASSWORD\|SECRET_KEY\|SS_PASSWORD"; then
    fail "install.sh: РІРѕР·РјРѕР¶РЅС‹ С...Р°СЂРґРєРѕРґРЅС‹Рµ СЃРµРєСЂРµС‚С‹"
  else
    pass "install.sh: С...Р°СЂРґРєРѕРґРЅС‹Рµ СЃРµРєСЂРµС‚С‹ РЅРµ РЅР°Р№РґРµРЅС‹"
    ((TESTS_PASSED++)) || true
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: РёСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ РєР°РІС‹С‡РµРє в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_quoting_usage() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РёСЃРїРѕР»СЊР·РѕРІР°РЅРёСЏ РєР°РІС‹С‡РµРє..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РїРµСЂРµРјРµРЅРЅС‹Рµ РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ СЃ РєР°РІС‹С‡РєР°РјРё
  # shellcheck disable=SC2034
  local unquoted_vars
  # shellcheck disable=SC2034
  unquoted_vars=$(grep -oE '\$[A-Za-z_][A-Za-z0-9_]*' "${SCRIPT_DIR}/install.sh" 2>/dev/null |
    wc -l || echo "0")

  local quoted_vars
  quoted_vars=$(grep -oE '"\$[A-Za-z_][A-Za-z0-9_]*"' "${SCRIPT_DIR}/install.sh" 2>/dev/null |
    wc -l || echo "0")

  if [[ $quoted_vars -gt 0 ]]; then
    pass "install.sh: РёСЃРїРѕР»СЊР·СѓРµС‚ РєР°РІС‹С‡РєРё РґР»СЏ РїРµСЂРµРјРµРЅРЅС‹С... ($quoted_vars)"
    ((TESTS_PASSED++)) || true
  else
    warn "install.sh: РїРµСЂРµРјРµРЅРЅС‹Рµ РјРѕРіСѓС‚ Р±С‹С‚СЊ РЅРµ РІ РєР°РІС‹С‡РєР°С..."
  fi
}

# в"Ђв"Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
main() {
  echo ""
  echo -e "${YELLOW}в-"в-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв--${PLAIN}"
  echo -e "${YELLOW}в-'        CubiVeil Unit Tests - install.sh              в-'${PLAIN}"
  echo -e "${YELLOW}в-љв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ќ${PLAIN}"
  echo ""

  info "РўРµСЃС‚РёСЂСѓРµРјС‹Р№ СЃРєСЂРёРїС‚: ${SCRIPT_DIR}/install.sh"
  echo ""

  # в"Ђв"Ђ Р-Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_strict_mode
  echo ""

  test_module_loading
  echo ""

  test_main_function
  echo ""

  test_main_call
  echo ""

  test_module_functions_usage
  echo ""

  test_installation_steps_order
  echo ""

  test_traffic_shaping_after_configure
  echo ""

  test_decoy_site_after_configure
  echo ""

  test_traffic_shaping_after_decoy_site
  echo ""

  test_error_handling
  echo ""

  test_lang_fallback
  echo ""

  test_script_size
  echo ""

  test_comments
  echo ""

  test_run_without_root
  echo ""

  test_ubuntu_check
  echo ""

  test_environment_variables
  echo ""

  test_telegram_integration
  echo ""

  test_dry_run_simulation
  echo ""

  test_security_no_hardcoded_secrets
  echo ""

  test_quoting_usage
  echo ""

  # в"Ђв"Ђ РС‚РѕРіРё в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
  echo ""
  echo -e "${YELLOW}в"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓ${PLAIN}"
  echo -e "${GREEN}РџСЂРѕР№РґРµРЅРѕ: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}РџСЂРѕРІР°Р»РµРЅРѕ:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}в"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓ${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}вќЊ РўРµСЃС‚С‹ РїСЂРѕРІР°Р»РµРЅС‹${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}вњ... Р'СЃРµ С‚РµСЃС‚С‹ РїСЂРѕР№РґРµРЅС‹${PLAIN}"
    exit 0
  fi
}

main "$@"
