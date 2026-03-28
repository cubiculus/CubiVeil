#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - lang/main.sh                 в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р»РѕРєР°Р»РёР·Р°С†РёРё (EN/RU)                  в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјРѕРіРѕ РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ ! -f "${SCRIPT_DIR}/lang/main.sh" ]]; then
  echo "РћС€РёР±РєР°: lang/main.sh РЅРµ РЅР°Р№РґРµРЅ"
  exit 1
fi

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° lang/main.sh..."

  if [[ -f "${SCRIPT_DIR}/lang/main.sh" ]]; then
    pass "lang/main.sh: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "lang/main.sh: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР° lang/main.sh..."

  if bash -n "${SCRIPT_DIR}/lang/main.sh" 2>/dev/null; then
    pass "lang/main.sh: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "lang/main.sh: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Р·Р°РіСЂСѓР·РєР° РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_loading() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р·Р°РіСЂСѓР·РєРё РјРѕРґСѓР»СЏ..."

  if bash -c "source ${SCRIPT_DIR}/lang/main.sh 2>&1" 2>/dev/null; then
    pass "lang/main.sh: Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ Р±РµР· РѕС€РёР±РѕРє"
    ((TESTS_PASSED++)) || true
  else
    fail "lang/main.sh: РѕС€РёР±РєР° РїСЂРё Р·Р°РіСЂСѓР·РєРµ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РІС‹Р±РѕСЂ СЏР·С‹РєР° РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_default_language() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЏР·С‹РєР° РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ..."

  # Р—Р°РіСЂСѓР¶Р°РµРј РјРѕРґСѓР»СЊ РІ РїРѕРґРїСЂРѕС†РµСЃСЃРµ С‡С‚РѕР±С‹ РЅРµ Р·Р°РіСЂСЏР·РЅСЏС‚СЊ СЃСЂРµРґСѓ
  local lang_name
  lang_name=$(bash -c "source ${SCRIPT_DIR}/lang.sh && echo \$LANG_NAME" 2>/dev/null)

  if [[ "$lang_name" == "Р СѓСЃСЃРєРёР№" || "$lang_name" == "English" ]]; then
    pass "РЇР·С‹Рє РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ СѓСЃС‚Р°РЅРѕРІР»РµРЅ: $lang_name"
    ((TESTS_PASSED++)) || true
  else
    fail "РЇР·С‹Рє РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РєРѕСЂСЂРµРєС‚РЅРѕ: '$lang_name'"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёСЏ select_language СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_select_language_function() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё select_language..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f select_language >/dev/null 2>&1" 2>/dev/null; then
    pass "Р¤СѓРЅРєС†РёСЏ select_language СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "Р¤СѓРЅРєС†РёСЏ select_language РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёСЏ step_title СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_step_title_function() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё step_title..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f step_title >/dev/null 2>&1" 2>/dev/null; then
    pass "Р¤СѓРЅРєС†РёСЏ step_title СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "Р¤СѓРЅРєС†РёСЏ step_title РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёСЏ get_str СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_get_str_function() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё get_str..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f get_str >/dev/null 2>&1" 2>/dev/null; then
    pass "Р¤СѓРЅРєС†РёСЏ get_str СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    warn "Р¤СѓРЅРєС†РёСЏ get_str РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚ (РјРѕР¶РµС‚ Р±С‹С‚СЊ РѕРїС†РёРѕРЅР°Р»СЊРЅРѕ)"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ С†РІРµС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_colors_defined() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕРїСЂРµРґРµР»РµРЅРёСЏ С†РІРµС‚РѕРІ..."

  local colors=("RED" "GREEN" "YELLOW" "BLUE" "CYAN" "PLAIN")
  local defined=0

  for color in "${colors[@]}"; do
    if bash -c "source ${SCRIPT_DIR}/lang.sh && [[ -n \"\$$color\" ]] && echo 'yes'" 2>/dev/null | grep -q "yes"; then
      ((defined++))
    fi
  done

  if [[ $defined -ge 5 ]]; then
    pass "Р¦РІРµС‚Р° РѕРїСЂРµРґРµР»РµРЅС‹: $defined РёР· ${#colors[@]}"
    ((TESTS_PASSED++)) || true
  else
    fail "РќРµ РІСЃРµ С†РІРµС‚Р° РѕРїСЂРµРґРµР»РµРЅС‹: $defined РёР· ${#colors[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: С„СѓРЅРєС†РёРё РІС‹РІРѕРґР° РѕРїСЂРµРґРµР»РµРЅС‹ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_output_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ РІС‹РІРѕРґР°..."

  local functions=("ok" "warn" "err" "info" "step")
  local defined=0

  for func in "${functions[@]}"; do
    if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f $func >/dev/null 2>&1" 2>/dev/null; then
      ((defined++))
    fi
  done

  if [[ $defined -eq ${#functions[@]} ]]; then
    pass "Р’СЃРµ С„СѓРЅРєС†РёРё РІС‹РІРѕРґР° РѕРїСЂРµРґРµР»РµРЅС‹: ${defined}"
    ((TESTS_PASSED++)) || true
  else
    fail "РќРµ РІСЃРµ С„СѓРЅРєС†РёРё РІС‹РІРѕРґР° РѕРїСЂРµРґРµР»РµРЅС‹: $defined РёР· ${#functions[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃС‚СЂРѕРєРё Р»РѕРєР°Р»РёР·Р°С†РёРё EN в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_en_strings() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃС‚СЂРѕРє Р»РѕРєР°Р»РёР·Р°С†РёРё EN..."

  local en_strings=(
    "ERR_ROOT"
    "ERR_UBUNTU"
    "PROMPT_DOMAIN"
    "PROMPT_EMAIL"
    "WARN_DNS_RECORD"
    "WARN_LETS_ENCRYPT"
  )

  local found=0
  for str in "${en_strings[@]}"; do
    if grep -q "^${str}=" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -eq ${#en_strings[@]} ]]; then
    pass "Р’СЃРµ EN СЃС‚СЂРѕРєРё РЅР°Р№РґРµРЅС‹: $found"
    ((TESTS_PASSED++)) || true
  else
    warn "РќРµ РІСЃРµ EN СЃС‚СЂРѕРєРё РЅР°Р№РґРµРЅС‹: $found РёР· ${#en_strings[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃС‚СЂРѕРєРё Р»РѕРєР°Р»РёР·Р°С†РёРё RU в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_ru_strings() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃС‚СЂРѕРє Р»РѕРєР°Р»РёР·Р°С†РёРё RU..."

  local ru_strings=(
    "ERR_ROOT_RU"
    "ERR_UBUNTU_RU"
    "PROMPT_DOMAIN_RU"
    "PROMPT_EMAIL_RU"
    "WARN_DNS_RECORD_RU"
    "WARN_LETS_ENCRYPT_RU"
  )

  local found=0
  for str in "${ru_strings[@]}"; do
    if grep -q "^${str}=" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -eq ${#ru_strings[@]} ]]; then
    pass "Р’СЃРµ RU СЃС‚СЂРѕРєРё РЅР°Р№РґРµРЅС‹: $found"
    ((TESTS_PASSED++)) || true
  else
    warn "РќРµ РІСЃРµ RU СЃС‚СЂРѕРєРё РЅР°Р№РґРµРЅС‹: $found РёР· ${#ru_strings[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Р·Р°РіРѕР»РѕРІРєРё С€Р°РіРѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_step_titles() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р·Р°РіРѕР»РѕРІРєРѕРІ С€Р°РіРѕРІ..."

  local step_strings=(
    "STEP_CHECK_SUBNET"
    "STEP_UPDATE"
    "STEP_AUTO_UPDATES"
    "STEP_BBR"
    "STEP_FIREWALL"
    "STEP_FAIL2BAN"
    "STEP_SINGBOX"
    "STEP_KEYS"
    "STEP_MARZBAN"
    "STEP_SSL"
    "STEP_CONFIGURE"
    "STEP_TELEGRAM"
  )

  local found=0
  for str in "${step_strings[@]}"; do
    if grep -q "^${str}=" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 10 ]]; then
    pass "Р—Р°РіРѕР»РѕРІРєРё С€Р°РіРѕРІ РЅР°Р№РґРµРЅС‹: $found"
    ((TESTS_PASSED++)) || true
  else
    fail "РќРµ РІСЃРµ Р·Р°РіРѕР»РѕРІРєРё С€Р°РіРѕРІ РЅР°Р№РґРµРЅС‹: $found РёР· ${#step_strings[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Р·Р°РіРѕР»РѕРІРєРё С€Р°РіРѕРІ RU в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_step_titles_ru() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р·Р°РіРѕР»РѕРІРєРѕРІ С€Р°РіРѕРІ RU..."

  local step_strings=(
    "STEP_CHECK_SUBNET_RU"
    "STEP_UPDATE_RU"
    "STEP_AUTO_UPDATES_RU"
    "STEP_BBR_RU"
    "STEP_FIREWALL_RU"
    "STEP_FAIL2BAN_RU"
    "STEP_SINGBOX_RU"
    "STEP_KEYS_RU"
    "STEP_MARZBAN_RU"
    "STEP_SSL_RU"
    "STEP_CONFIGURE_RU"
    "STEP_TELEGRAM_RU"
  )

  local found=0
  for str in "${step_strings[@]}"; do
    if grep -q "^${str}=" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 10 ]]; then
    pass "Р—Р°РіРѕР»РѕРІРєРё С€Р°РіРѕРІ RU РЅР°Р№РґРµРЅС‹: $found"
    ((TESTS_PASSED++)) || true
  else
    warn "РќРµ РІСЃРµ Р·Р°РіРѕР»РѕРІРєРё С€Р°РіРѕРІ RU РЅР°Р№РґРµРЅС‹: $found РёР· ${#step_strings[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Telegram СЃС‚СЂРѕРєРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_telegram_strings() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Telegram СЃС‚СЂРѕРє..."

  local tg_strings=(
    "PROMPT_TG_TOKEN"
    "PROMPT_TG_CHAT_ID"
    "ERR_TG_TOKEN_FORMAT"
    "ERR_TG_TOKEN_INVALID"
    "OK_TG_TOKEN_VERIFIED"
    "ERR_CHAT_ID_FORMAT"
  )

  local found=0
  for str in "${tg_strings[@]}"; do
    if grep -q "^${str}" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 4 ]]; then
    pass "Telegram СЃС‚СЂРѕРєРё РЅР°Р№РґРµРЅС‹: $found"
    ((TESTS_PASSED++)) || true
  else
    warn "РќРµ РІСЃРµ Telegram СЃС‚СЂРѕРєРё РЅР°Р№РґРµРЅС‹: $found РёР· ${#tg_strings[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: С„РёРЅР°Р»СЊРЅС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_final_messages() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„РёРЅР°Р»СЊРЅС‹С… СЃРѕРѕР±С‰РµРЅРёР№..."

  local final_strings=(
    "SUCCESS_TITLE"
    "SUCCESS_PANEL_URL"
    "SUCCESS_SUBSCRIPTION_URL"
    "SUCCESS_PROFILES"
    "SUCCESS_TELEGRAM"
    "NEXT_STEPS"
  )

  local found=0
  for str in "${final_strings[@]}"; do
    if grep -q "^${str}" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 4 ]]; then
    pass "Р¤РёРЅР°Р»СЊРЅС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ РЅР°Р№РґРµРЅС‹: $found"
    ((TESTS_PASSED++)) || true
  else
    warn "РќРµ РІСЃРµ С„РёРЅР°Р»СЊРЅС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ РЅР°Р№РґРµРЅС‹: $found РёР· ${#final_strings[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: С„РёРЅР°Р»СЊРЅС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ RU в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_final_messages_ru() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„РёРЅР°Р»СЊРЅС‹С… СЃРѕРѕР±С‰РµРЅРёР№ RU..."

  local final_strings=(
    "SUCCESS_TITLE_RU"
    "SUCCESS_PANEL_URL_RU"
    "SUCCESS_SUBSCRIPTION_URL_RU"
    "SUCCESS_PROFILES_RU"
    "SUCCESS_TELEGRAM_RU"
    "NEXT_STEPS_RU"
  )

  local found=0
  for str in "${final_strings[@]}"; do
    if grep -q "^${str}" "${SCRIPT_DIR}/lang.sh" 2>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -ge 4 ]]; then
    pass "Р¤РёРЅР°Р»СЊРЅС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ RU РЅР°Р№РґРµРЅС‹: $found"
    ((TESTS_PASSED++)) || true
  else
    warn "РќРµ РІСЃРµ С„РёРЅР°Р»СЊРЅС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ RU РЅР°Р№РґРµРЅС‹: $found РёР· ${#final_strings[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° С„СѓРЅРєС†РёРё step_title в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_step_title_functionality() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРѕРЅР°Р»СЊРЅРѕСЃС‚Рё step_title..."

  # Р—Р°РіСЂСѓР¶Р°РµРј РјРѕРґСѓР»СЊ Рё С‚РµСЃС‚РёСЂСѓРµРј С„СѓРЅРєС†РёСЋ
  local output
  output=$(bash -c "
    source ${SCRIPT_DIR}/lang.sh
    LANG_NAME='English'
    step_title '1' 'РўРµСЃС‚ RU' 'Test EN'
  " 2>&1)

  if echo "$output" | grep -q "Step 1/12"; then
    pass "step_title: English С„РѕСЂРјР°С‚ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    warn "step_title: English С„РѕСЂРјР°С‚ РЅРµ РЅР°Р№РґРµРЅ РІ РІС‹РІРѕРґРµ"
  fi

  # РўРµСЃС‚ РґР»СЏ СЂСѓСЃСЃРєРѕРіРѕ СЏР·С‹РєР°
  output=$(bash -c "
    source ${SCRIPT_DIR}/lang.sh
    LANG_NAME='Р СѓСЃСЃРєРёР№'
    step_title '1' 'РўРµСЃС‚ RU' 'Test EN'
  " 2>&1)

  if echo "$output" | grep -q "РЁР°Рі 1/12"; then
    pass "step_title: Р СѓСЃСЃРєРёР№ С„РѕСЂРјР°С‚ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    warn "step_title: Р СѓСЃСЃРєРёР№ С„РѕСЂРјР°С‚ РЅРµ РЅР°Р№РґРµРЅ РІ РІС‹РІРѕРґРµ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїРѕР»РЅРѕС‚Р° Р»РѕРєР°Р»РёР·Р°С†РёРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_localization_completeness() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїРѕР»РЅРѕС‚С‹ Р»РѕРєР°Р»РёР·Р°С†РёРё..."

  # РџРѕРґСЃС‡РёС‚С‹РІР°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ EN Рё RU СЃС‚СЂРѕРє
  local en_count ru_count
  en_count=$(grep -cE '^[A-Z_]+="[A-Za-z ]+"$' "${SCRIPT_DIR}/lang.sh" 2>/dev/null || echo "0")
  ru_count=$(grep -cE '^[A-Z_]+_RU=' "${SCRIPT_DIR}/lang.sh" 2>/dev/null || echo "0")

  info "РќР°Р№РґРµРЅРѕ EN СЃС‚СЂРѕРє: $en_count, RU СЃС‚СЂРѕРє: $ru_count"

  # РћР¶РёРґР°РµРј С‡С‚Рѕ RU СЃС‚СЂРѕРє С…РѕС‚СЏ Р±С‹ 80% РѕС‚ EN
  if [[ $en_count -gt 0 ]]; then
    local threshold=$((en_count * 80 / 100))
    if [[ $ru_count -ge $threshold ]]; then
      pass "РџРѕР»РЅРѕС‚Р° Р»РѕРєР°Р»РёР·Р°С†РёРё: RU СЃС‚СЂРѕРєРё РїРѕРєСЂС‹РІР°СЋС‚ $((ru_count * 100 / en_count))% EN СЃС‚СЂРѕРє"
      ((TESTS_PASSED++)) || true
    else
      warn "РџРѕР»РЅРѕС‚Р° Р»РѕРєР°Р»РёР·Р°С†РёРё: RU СЃС‚СЂРѕРєРё РїРѕРєСЂС‹РІР°СЋС‚ С‚РѕР»СЊРєРѕ $((ru_count * 100 / en_count))% EN СЃС‚СЂРѕРє"
    fi
  else
    warn "РќРµ СѓРґР°Р»РѕСЃСЊ РїРѕРґСЃС‡РёС‚Р°С‚СЊ EN СЃС‚СЂРѕРєРё"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РѕС‚СЃСѓС‚СЃС‚РІРёРµ РїСѓСЃС‚С‹С… СЃС‚СЂРѕРє Р»РѕРєР°Р»РёР·Р°С†РёРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_no_empty_strings() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕС‚СЃСѓС‚СЃС‚РІРёСЏ РїСѓСЃС‚С‹С… СЃС‚СЂРѕРє Р»РѕРєР°Р»РёР·Р°С†РёРё..."

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РЅРµС‚ СЃС‚СЂРѕРє РІРёРґР° KEY=""
  local empty_count
  empty_count=$(grep -cE '^[A-Z_]+=""$' "${SCRIPT_DIR}/lang.sh" 2>/dev/null || echo "0")

  if [[ $empty_count -eq 0 ]]; then
    pass "РџСѓСЃС‚С‹Рµ СЃС‚СЂРѕРєРё Р»РѕРєР°Р»РёР·Р°С†РёРё РѕС‚СЃСѓС‚СЃС‚РІСѓСЋС‚"
    ((TESTS_PASSED++)) || true
  else
    warn "РќР°Р№РґРµРЅРѕ РїСѓСЃС‚С‹С… СЃС‚СЂРѕРє Р»РѕРєР°Р»РёР·Р°С†РёРё: $empty_count"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РєРѕСЂСЂРµРєС‚РЅРѕСЃС‚СЊ СЌРєСЂР°РЅРёСЂРѕРІР°РЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_escaping_correctness() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РєРѕСЂСЂРµРєС‚РЅРѕСЃС‚Рё СЌРєСЂР°РЅРёСЂРѕРІР°РЅРёСЏ..."

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РЅРµС‚ РЅРµСЌРєСЂР°РЅРёСЂРѕРІР°РЅРЅС‹С… РєР°РІС‹С‡РµРє РІРЅСѓС‚СЂРё СЃС‚СЂРѕРє
  # (РїСЂРѕСЃС‚Р°СЏ СЌРІСЂРёСЃС‚РёС‡РµСЃРєР°СЏ РїСЂРѕРІРµСЂРєР°)
  local bad_lines
  bad_lines=$(grep -n '="[^"]*"[^"]*="' "${SCRIPT_DIR}/lang.sh" 2>/dev/null | head -5 || true)

  if [[ -z "$bad_lines" ]]; then
    pass "Р­РєСЂР°РЅРёСЂРѕРІР°РЅРёРµ РєР°РІС‹С‡РµРє РєРѕСЂСЂРµРєС‚РЅРѕ"
    ((TESTS_PASSED++)) || true
  else
    warn "Р’РѕР·РјРѕР¶РЅС‹Рµ РїСЂРѕР±Р»РµРјС‹ СЃ СЌРєСЂР°РЅРёСЂРѕРІР°РЅРёРµРј: $bad_lines"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° С„СѓРЅРєС†РёРё check_root в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_check_root_function() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё check_root..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f check_root >/dev/null 2>&1" 2>/dev/null; then
    pass "Р¤СѓРЅРєС†РёСЏ check_root СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    warn "Р¤СѓРЅРєС†РёСЏ check_root РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° С„СѓРЅРєС†РёРё check_ubuntu в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_check_ubuntu_function() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё check_ubuntu..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f check_ubuntu >/dev/null 2>&1" 2>/dev/null; then
    pass "Р¤СѓРЅРєС†РёСЏ check_ubuntu СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    warn "Р¤СѓРЅРєС†РёСЏ check_ubuntu РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° С„СѓРЅРєС†РёРё print_banner в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_print_banner_function() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё print_banner..."

  if bash -c "source ${SCRIPT_DIR}/lang.sh && declare -f print_banner >/dev/null 2>&1" 2>/dev/null; then
    pass "Р¤СѓРЅРєС†РёСЏ print_banner СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    warn "Р¤СѓРЅРєС†РёСЏ print_banner РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РёРЅС‚РµРіСЂР°С†РёСЏ СЃ РґСЂСѓРіРёРјРё РјРѕРґСѓР»СЏРјРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_integration_with_modules() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РёРЅС‚РµРіСЂР°С†РёРё СЃ РґСЂСѓРіРёРјРё РјРѕРґСѓР»СЏРјРё..."

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ lang.sh РјРѕР¶РµС‚ Р±С‹С‚СЊ Р·Р°РіСЂСѓР¶РµРЅ РїРµСЂРµРґ РґСЂСѓРіРёРјРё РјРѕРґСѓР»СЏРјРё
  local result
  result=$(bash -c "
    source ${SCRIPT_DIR}/lang.sh
    source ${SCRIPT_DIR}/lib/utils.sh 2>&1
    echo 'OK'
  " 2>&1)

  if echo "$result" | grep -q "OK"; then
    pass "РРЅС‚РµРіСЂР°С†РёСЏ СЃ lib/utils.sh СѓСЃРїРµС€РЅР°"
    ((TESTS_PASSED++)) || true
  else
    warn "РРЅС‚РµРіСЂР°С†РёСЏ СЃ lib/utils.shеЏЇиѓЅжњ‰ РїСЂРѕР±Р»РµРјС‹: $result"
  fi
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - lang.sh                 в•‘${PLAIN}"
  echo -e "${YELLOW}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${PLAIN}"
  echo ""

  info "РўРµСЃС‚РёСЂСѓРµРјС‹Р№ РјРѕРґСѓР»СЊ: ${SCRIPT_DIR}/lang.sh"
  echo ""

  # в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_module_loading
  echo ""

  test_default_language
  echo ""

  test_select_language_function
  echo ""

  test_step_title_function
  echo ""

  test_get_str_function
  echo ""

  test_colors_defined
  echo ""

  test_output_functions
  echo ""

  test_en_strings
  echo ""

  test_ru_strings
  echo ""

  test_step_titles
  echo ""

  test_step_titles_ru
  echo ""

  test_telegram_strings
  echo ""

  test_final_messages
  echo ""

  test_final_messages_ru
  echo ""

  test_step_title_functionality
  echo ""

  test_localization_completeness
  echo ""

  test_no_empty_strings
  echo ""

  test_escaping_correctness
  echo ""

  test_check_root_function
  echo ""

  test_check_ubuntu_function
  echo ""

  test_print_banner_function
  echo ""

  test_integration_with_modules
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
