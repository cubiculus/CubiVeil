#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - setup-telegram.sh            в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРєСЂРёРїС‚Р° СѓСЃС‚Р°РЅРѕРІРєРё Telegram Р±РѕС‚Р°       в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјРѕРіРѕ СЃРєСЂРёРїС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
if [[ ! -f "${SCRIPT_DIR}/setup-telegram.sh" ]]; then
  echo "РћС€РёР±РєР°: setup-telegram.sh РЅРµ РЅР°Р№РґРµРЅ"
  exit 1
fi

# в”Ђв”Ђ Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅР°СЏ С„СѓРЅРєС†РёСЏ РґР»СЏ РїСЂРѕРІРµСЂРєРё Python С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# Usage: check_python_functions "category" "func1" "func2" ...
check_python_functions() {
  local category="$1"
  shift
  local functions=("$@")
  local found=0

  for func in "${functions[@]}"; do
    if grep -q "def ${func}" "${SCRIPT_DIR}/setup-telegram.sh"; then
      pass "Python $category: $func"
      ((TESTS_PASSED++)) || true
      ((found++))
    else
      warn "Python $category: $func РЅРµ РЅР°Р№РґРµРЅР°"
    fi
  done

  if [[ $found -eq ${#functions[@]} ]]; then
    pass "Python $category: РІСЃРµ С„СѓРЅРєС†РёРё РЅР°Р№РґРµРЅС‹ ($found/${#functions[@]})"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅР°СЏ С„СѓРЅРєС†РёСЏ РґР»СЏ РїСЂРѕРІРµСЂРєРё systemd РґРёСЂРµРєС‚РёРІ в”Ђв”Ђв”Ђв”Ђв”Ђ
# Usage: check_systemd_directives "directive1" "directive2" ...
check_systemd_directives() {
  local directives=("$@")
  local found=0

  for directive in "${directives[@]}"; do
    if grep -q "$directive" "${SCRIPT_DIR}/setup-telegram.sh"; then
      pass "Systemd: $directive"
      ((TESTS_PASSED++)) || true
      ((found++))
    else
      warn "Systemd: $directive РЅРµ РЅР°Р№РґРµРЅР°"
    fi
  done

  if [[ $found -eq ${#directives[@]} ]]; then
    pass "Systemd: РІСЃРµ РґРёСЂРµРєС‚РёРІС‹ РЅР°Р№РґРµРЅС‹ ($found/${#directives[@]})"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° setup-telegram.sh..."

  if [[ -f "${SCRIPT_DIR}/setup-telegram.sh" ]]; then
    pass "setup-telegram.sh: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "setup-telegram.sh: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР° setup-telegram.sh..."

  if bash -n "${SCRIPT_DIR}/setup-telegram.sh" 2>/dev/null; then
    pass "setup-telegram.sh: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "setup-telegram.sh: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РЅРµРѕР±С…РѕРґРёРјС‹С… С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_functions_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РЅРµРѕР±С…РѕРґРёРјС‹С… С„СѓРЅРєС†РёР№..."

  # РР·РІР»РµРєР°РµРј РёРјРµРЅР° С„СѓРЅРєС†РёР№ РёР· СЃРєСЂРёРїС‚Р°
  local functions
  functions=$(grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)' "${SCRIPT_DIR}/setup-telegram.sh" | awk '{print $1}' | sed 's/()$//' | sort -u)

  local required_functions=(
    "step_check_environment"
    "step_prompt_telegram_config"
    "step_install_bot"
    "step_configure_services"
    "main"
  )

  local missing=0
  for func in "${required_functions[@]}"; do
    if echo "$functions" | grep -q "^${func}$"; then
      pass "Р¤СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Р¤СѓРЅРєС†РёСЏ РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚: $func"
      ((missing++))
    fi
  done

  if [[ $missing -eq 0 ]]; then
    pass "Р’СЃРµ РЅРµРѕР±С…РѕРґРёРјС‹Рµ С„СѓРЅРєС†РёРё РїСЂРёСЃСѓС‚СЃС‚РІСѓСЋС‚"
    ((TESTS_PASSED++)) || true
  else
    warn "РћС‚СЃСѓС‚СЃС‚РІСѓРµС‚ $missing РЅРµРѕР±С…РѕРґРёРјС‹С… С„СѓРЅРєС†РёР№"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dependencies() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ СЃРєСЂРёРїС‚Р°..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ СЃРєСЂРёРїС‚ Р·Р°РіСЂСѓР¶Р°РµС‚ РЅРµРѕР±С…РѕРґРёРјС‹Рµ РјРѕРґСѓР»Рё
  if grep -q 'source.*lang/main.sh' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р—Р°РІРёСЃРёРјРѕСЃС‚СЊ: lang/main.sh Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    fail "Р—Р°РІРёСЃРёРјРѕСЃС‚СЊ: lang/main.sh РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ"
  fi

  if grep -q 'source.*lib/utils.sh' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р—Р°РІРёСЃРёРјРѕСЃС‚СЊ: lib/utils.sh Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    fail "Р—Р°РІРёСЃРёРјРѕСЃС‚СЊ: lib/utils.sh РЅРµ Р·Р°РіСЂСѓР¶Р°РµС‚СЃСЏ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° Р±РµР·РѕРїР°СЃРЅРѕСЃС‚Рё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_security() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РјРµСЂ Р±РµР·РѕРїР°СЃРЅРѕСЃС‚Рё..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ С‚РѕРєРµРЅ Р±РµСЂС‘С‚СЃСЏ РёР· РїРµСЂРµРјРµРЅРЅРѕР№ РѕРєСЂСѓР¶РµРЅРёСЏ
  if grep -q 'os.environ.get("TG_TOKEN")' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р‘РµР·РѕРїР°СЃРЅРѕСЃС‚СЊ: С‚РѕРєРµРЅ РІ РїРµСЂРµРјРµРЅРЅРѕР№ РѕРєСЂСѓР¶РµРЅРёСЏ"
    ((TESTS_PASSED++)) || true
  else
    fail "Р‘РµР·РѕРїР°СЃРЅРѕСЃС‚СЊ: С‚РѕРєРµРЅ РЅРµ РІ РїРµСЂРµРјРµРЅРЅРѕР№ РѕРєСЂСѓР¶РµРЅРёСЏ"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ systemd СЃРµСЂРІРёСЃ РёРјРµРµС‚ Р·Р°С‰РёС‚РЅС‹Рµ РґРёСЂРµРєС‚РёРІС‹
  if grep -q 'ProtectHome' "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q 'ProtectSystem' "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q 'NoNewPrivileges' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р‘РµР·РѕРїР°СЃРЅРѕСЃС‚СЊ: systemd Р·Р°С‰РёС‚РЅС‹Рµ РґРёСЂРµРєС‚РёРІС‹"
    ((TESTS_PASSED++)) || true
  else
    warn "Р‘РµР·РѕРїР°СЃРЅРѕСЃС‚СЊ: РЅРµ РІСЃРµ systemd Р·Р°С‰РёС‚РЅС‹Рµ РґРёСЂРµРєС‚РёРІС‹"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° СЃС‚СЂСѓРєС‚СѓСЂС‹ Python Р±РѕС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_structure() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃС‚СЂСѓРєС‚СѓСЂС‹ Python Р±РѕС‚Р°..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ Python СЃРєСЂРёРїС‚ СЃРѕР·РґР°С‘С‚СЃСЏ РІ СЃРєСЂРёРїС‚Рµ
  if grep -q '/opt/cubiveil-bot/bot.py' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "РЎС‚СЂСѓРєС‚СѓСЂР°: Python Р±РѕС‚ СЃРѕР·РґР°С‘С‚СЃСЏ РІ /opt/cubiveil-bot/bot.py"
    ((TESTS_PASSED++)) || true
  else
    fail "РЎС‚СЂСѓРєС‚СѓСЂР°: РїСѓС‚СЊ Рє Р±РѕС‚Сѓ РЅРµРєРѕСЂСЂРµРєС‚РµРЅ"
  fi

  # РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ РєР»СЋС‡РµРІС‹С… С„СѓРЅРєС†РёР№ РІ Python РєРѕРґРµ
  local bot_functions=(
    "tg_send"
    "get_cpu"
    "get_ram"
    "get_disk"
    "check_alerts"
    "poll"
    "send_daily_report"
  )

  for func in "${bot_functions[@]}"; do
    if grep -q "def ${func}" "${SCRIPT_DIR}/setup-telegram.sh"; then
      pass "Python С„СѓРЅРєС†РёСЏ: $func"
      ((TESTS_PASSED++)) || true
    else
      warn "Python С„СѓРЅРєС†РёСЏ: $func РЅРµ РЅР°Р№РґРµРЅР°"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° systemd СЃРµСЂРІРёСЃР° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_systemd_service() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РєРѕРЅС„РёРіСѓСЂР°С†РёРё systemd СЃРµСЂРІРёСЃР°..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ СЃРѕР·РґР°С‘С‚СЃСЏ С„Р°Р№Р» СЃРµСЂРІРёСЃР°
  if grep -q '/etc/systemd/system/cubiveil-bot.service' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Systemd: РїСѓС‚СЊ Рє СЃРµСЂРІРёСЃСѓ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "Systemd: РїСѓС‚СЊ Рє СЃРµСЂРІРёСЃСѓ РЅРµРєРѕСЂСЂРµРєС‚РµРЅ"
  fi

  # РџСЂРѕРІРµСЂРєР° РєР»СЋС‡РµРІС‹С… РґРёСЂРµРєС‚РёРІ
  local systemd_directives=(
    "Description="
    "Type=simple"
    "ExecStart="
    "Restart=always"
    "WantedBy=multi-user.target"
  )

  for directive in "${systemd_directives[@]}"; do
    if grep -q "$directive" "${SCRIPT_DIR}/setup-telegram.sh"; then
      pass "Systemd РґРёСЂРµРєС‚РёРІР°: $directive"
      ((TESTS_PASSED++)) || true
    else
      warn "Systemd РґРёСЂРµРєС‚РёРІР°: $directive РЅРµ РЅР°Р№РґРµРЅР°"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° cron Р·Р°РґР°РЅРёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_cron_jobs() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ cron Р·Р°РґР°РЅРёР№..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ cron РЅР°СЃС‚СЂР°РёРІР°РµС‚СЃСЏ
  if grep -q 'crontab' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: РЅР°СЃС‚СЂРѕРµРЅС‹ cron Р·Р°РґР°РЅРёСЏ"
    ((TESTS_PASSED++)) || true
  else
    fail "Cron: cron Р·Р°РґР°РЅРёСЏ РЅРµ РЅР°СЃС‚СЂРѕРµРЅС‹"
  fi

  # РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ Р·Р°РґР°РЅРёСЏ РґР»СЏ РѕС‚С‡С‘С‚Р°
  if grep -q 'bot.py report' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: Р·Р°РґР°РЅРёРµ РґР»СЏ РµР¶РµРґРЅРµРІРЅРѕРіРѕ РѕС‚С‡С‘С‚Р°"
    ((TESTS_PASSED++)) || true
  else
    fail "Cron: Р·Р°РґР°РЅРёРµ РґР»СЏ РѕС‚С‡С‘С‚Р° РЅРµ РЅР°Р№РґРµРЅРѕ"
  fi

  # РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ Р·Р°РґР°РЅРёСЏ РґР»СЏ Р°Р»РµСЂС‚РѕРІ
  if grep -q 'bot.py alert' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Cron: Р·Р°РґР°РЅРёРµ РґР»СЏ Р°Р»РµСЂС‚РѕРІ"
    ((TESTS_PASSED++)) || true
  else
    fail "Cron: Р·Р°РґР°РЅРёРµ РґР»СЏ Р°Р»РµСЂС‚РѕРІ РЅРµ РЅР°Р№РґРµРЅРѕ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° Р»РѕРіРёСЂРѕРІР°РЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_logging() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р»РѕРіРёСЂРѕРІР°РЅРёСЏ..."

  # РџСЂРѕРІРµСЂРєР° journald РєРѕРЅС„РёРіР°
  if grep -q '/etc/systemd/journald.d/cubiveil-limit.conf' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р›РѕРіРёСЂРѕРІР°РЅРёРµ: journald РєРѕРЅС„РёРі СЃРѕР·РґР°РµС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    warn "Р›РѕРіРёСЂРѕРІР°РЅРёРµ: journald РєРѕРЅС„РёРі РЅРµ РЅР°Р№РґРµРЅ"
  fi

  # РџСЂРѕРІРµСЂРєР° logrotate РєРѕРЅС„РёРіР°
  if grep -q '/etc/logrotate.d/cubiveil-services' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р›РѕРіРёСЂРѕРІР°РЅРёРµ: logrotate РєРѕРЅС„РёРі СЃРѕР·РґР°РµС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    warn "Р›РѕРіРёСЂРѕРІР°РЅРёРµ: logrotate РєРѕРЅС„РёРі РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° СЃС‚СЂСѓРєС‚СѓСЂС‹ СѓСЃС‚Р°РЅРѕРІРєРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_installation_structure() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃС‚СЂСѓРєС‚СѓСЂС‹ СѓСЃС‚Р°РЅРѕРІРєРё..."

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ СЃРѕР·РґР°С‘С‚СЃСЏ РґРёСЂРµРєС‚РѕСЂРёСЏ РґР»СЏ Р±СЌРєР°РїРѕРІ
  if grep -q '/opt/cubiveil-bot/backups' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "РЎС‚СЂСѓРєС‚СѓСЂР°: РґРёСЂРµРєС‚РѕСЂРёСЏ РґР»СЏ Р±СЌРєР°РїРѕРІ СЃРѕР·РґР°РµС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    fail "РЎС‚СЂСѓРєС‚СѓСЂР°: РґРёСЂРµРєС‚РѕСЂРёСЏ РґР»СЏ Р±СЌРєР°РїРѕРІ РЅРµ РЅР°Р№РґРµРЅР°"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ Р±РѕС‚ Р·Р°РІРёСЃРёС‚ РѕС‚ Marzban
  if grep -q 'After=marzban' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р—Р°РІРёСЃРёРјРѕСЃС‚Рё: Р±РѕС‚ Р·Р°РїСѓСЃРєР°РµС‚СЃСЏ РїРѕСЃР»Рµ Marzban"
    ((TESTS_PASSED++)) || true
  else
    warn "Р—Р°РІРёСЃРёРјРѕСЃС‚Рё: Р·Р°РІРёСЃРёРјРѕСЃС‚СЊ РѕС‚ Marzban РЅРµ СѓРєР°Р·Р°РЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° РІР°Р»РёРґР°С†РёРё С‚РѕРєРµРЅР° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_token_validation() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РІР°Р»РёРґР°С†РёРё С‚РѕРєРµРЅР° Telegram..."

  # РџСЂРѕРІРµСЂРєР° С„РѕСЂРјР°С‚Р° С‚РѕРєРµРЅР°
  if grep -q '^[0-9]+:[A-Za-z0-9_-]{35}$' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р’Р°Р»РёРґР°С†РёСЏ: РїСЂРѕРІРµСЂРєР° С„РѕСЂРјР°С‚Р° С‚РѕРєРµРЅР°"
    ((TESTS_PASSED++)) || true
  else
    warn "Р’Р°Р»РёРґР°С†РёСЏ: РїСЂРѕРІРµСЂРєР° С„РѕСЂРјР°С‚Р° С‚РѕРєРµРЅР° РЅРµ РЅР°Р№РґРµРЅР°"
  fi

  # РџСЂРѕРІРµСЂРєР° РІР°Р»РёРґР°С†РёРё С‡РµСЂРµР· API
  if grep -q 'api.telegram.org.*getMe' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р’Р°Р»РёРґР°С†РёСЏ: РїСЂРѕРІРµСЂРєР° С‚РѕРєРµРЅР° С‡РµСЂРµР· API Telegram"
    ((TESTS_PASSED++)) || true
  else
    warn "Р’Р°Р»РёРґР°С†РёСЏ: РїСЂРѕРІРµСЂРєР° С‡РµСЂРµР· API РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїСЂРѕРІРµСЂРєР° РІР°Р»РёРґР°С†РёРё Chat ID в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_chat_id_validation() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РІР°Р»РёРґР°С†РёРё Chat ID..."

  # РџСЂРѕРІРµСЂРєР° С„РѕСЂРјР°С‚Р° Chat ID
  if grep -q '^-?\[0-9\]+$' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Р’Р°Р»РёРґР°С†РёСЏ: РїСЂРѕРІРµСЂРєР° С„РѕСЂРјР°С‚Р° Chat ID"
    ((TESTS_PASSED++)) || true
  else
    warn "Р’Р°Р»РёРґР°С†РёСЏ: РїСЂРѕРІРµСЂРєР° С„РѕСЂРјР°С‚Р° Chat ID РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” С„СѓРЅРєС†РёРё РјРµС‚СЂРёРє в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_metrics() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python С„СѓРЅРєС†РёР№ РјРµС‚СЂРёРє..."
  check_python_functions "РјРµС‚СЂРёРєР°" "get_cpu" "get_ram" "get_disk" "get_uptime" "get_active_users"
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” С„СѓРЅРєС†РёРё РѕС‚РїСЂР°РІРєРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_send_functions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python С„СѓРЅРєС†РёР№ РѕС‚РїСЂР°РІРєРё..."
  check_python_functions "РѕС‚РїСЂР°РІРєРё" "tg_send" "tg_send_file"
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” РєРѕРјР°РЅРґС‹ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_commands() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python РєРѕРјР°РЅРґ Р±РѕС‚Р°..."

  check_python_functions "РєРѕРјР°РЅРґ" "handle_command"

  # РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ РєРѕРјР°РЅРґ
  local commands=("/start" "/status" "/backup" "/users" "/restart" "/help")
  local found=0
  for cmd in "${commands[@]}"; do
    if grep -q "\"${cmd}\"" "${SCRIPT_DIR}/setup-telegram.sh" ||
      grep -q "'${cmd}'" "${SCRIPT_DIR}/setup-telegram.sh"; then
      ((found++))
    fi
  done
  if [[ $found -eq ${#commands[@]} ]]; then
    pass "Python РєРѕРјР°РЅРґС‹: РІСЃРµ РЅР°Р№РґРµРЅС‹ ($found/${#commands[@]})"
    ((TESTS_PASSED++)) || true
  else
    warn "Python РєРѕРјР°РЅРґС‹: РЅР°Р№РґРµРЅРѕ $found/${#commands[@]}"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” polling в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_polling() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python polling..."

  check_python_functions "" "poll"

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ getUpdates API
  if grep -q "getUpdates" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ getUpdates API"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: getUpdates API РЅРµ РЅР°Р№РґРµРЅ"
  fi

  # РџСЂРѕРІРµСЂРєР° Р°РІС‚РѕСЂРёР·Р°С†РёРё РїРѕ chat_id (РєРѕРјРїР»РµРєСЃРЅР°СЏ)
  if grep -q "CHAT_ID" "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q "msg.get.*chat.*id" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: Р°РІС‚РѕСЂРёР·Р°С†РёСЏ РїРѕ chat_id"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: Р°РІС‚РѕСЂРёР·Р°С†РёСЏ РїРѕ chat_id РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” Р°Р»РµСЂС‚С‹ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_alerts() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python СЃРёСЃС‚РµРјС‹ Р°Р»РµСЂС‚РѕРІ..."

  check_python_functions "Р°Р»РµСЂС‚РѕРІ" "check_alerts"

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ state С„Р°Р№Р» РґР»СЏ РїСЂРµРґРѕС‚РІСЂР°С‰РµРЅРёСЏ СЃРїР°РјР°
  if grep -q "load_state\|save_state" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: СЃРѕСЃС‚РѕСЏРЅРёРµ Р°Р»РµСЂС‚РѕРІ СЃРѕС…СЂР°РЅСЏРµС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: СЃРѕСЃС‚РѕСЏРЅРёРµ Р°Р»РµСЂС‚РѕРІ РЅРµ СЃРѕС…СЂР°РЅСЏРµС‚СЃСЏ"
  fi

  # РџСЂРѕРІРµСЂРєР° РїРѕСЂРѕРіРѕРІС‹С… Р·РЅР°С‡РµРЅРёР№ (РІСЃРµ СЃСЂР°Р·Сѓ)
  if grep -q "ALERT_CPU" "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q "ALERT_RAM" "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q "ALERT_DISK" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: РІСЃРµ РїРѕСЂРѕРіРѕРІС‹Рµ Р·РЅР°С‡РµРЅРёСЏ РЅР°Р№РґРµРЅС‹"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: РЅРµ РІСЃРµ РїРѕСЂРѕРіРѕРІС‹Рµ Р·РЅР°С‡РµРЅРёСЏ РЅР°Р№РґРµРЅС‹"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” Р±СЌРєР°РїС‹ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_backups() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python СЃРёСЃС‚РµРјС‹ Р±СЌРєР°РїРѕРІ..."

  check_python_functions "Р±СЌРєР°РїРѕРІ" "make_backup"

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РїСЂР°РІРёР»СЊРЅС‹Р№ РїСѓС‚СЊ Рє Р‘Р”
  if grep -q "/var/lib/marzban/db.sqlite3" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: РїСѓС‚СЊ Рє Р‘Р” Marzban"
    ((TESTS_PASSED++)) || true
  else
    fail "Python: РїСѓС‚СЊ Рє Р‘Р” РЅРµ РЅР°Р№РґРµРЅ"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ СЃС‚Р°СЂС‹Рµ Р±СЌРєР°РїС‹ СѓРґР°Р»СЏСЋС‚СЃСЏ
  if grep -q "7.*86400\|7.*days\|old.*backup" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: СЃС‚Р°СЂС‹Рµ Р±СЌРєР°РїС‹ СѓРґР°Р»СЏСЋС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: СѓРґР°Р»РµРЅРёРµ СЃС‚Р°СЂС‹С… Р±СЌРєР°РїРѕРІ РЅРµ РЅР°Р№РґРµРЅРѕ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” С‚РѕС‡РєР° РІС…РѕРґР° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_entry_point() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python С‚РѕС‡РєРё РІС…РѕРґР°..."

  # РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ if __name__ == "__main__"
  if grep -q 'if __name__ == "__main__":' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: С‚РѕС‡РєР° РІС…РѕРґР° СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "Python: С‚РѕС‡РєР° РІС…РѕРґР° РЅРµ РЅР°Р№РґРµРЅР°"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РїРѕРґРґРµСЂР¶РёРІР°СЋС‚СЃСЏ СЂРµР¶РёРјС‹ report, alert, poll
  local modes=("report" "alert" "poll")
  for mode in "${modes[@]}"; do
    if grep -q "cmd == \"$mode\"\|cmd == '$mode'" "${SCRIPT_DIR}/setup-telegram.sh"; then
      pass "Python: СЂРµР¶РёРј $mode"
      ((TESTS_PASSED++)) || true
    else
      warn "Python: СЂРµР¶РёРј $mode РЅРµ РЅР°Р№РґРµРЅ"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” РѕР±СЂР°Р±РѕС‚РєР° РѕС€РёР±РѕРє в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_error_handling() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python РѕР±СЂР°Р±РѕС‚РєРё РѕС€РёР±РѕРє..."

  # РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ try/except Р±Р»РѕРєРѕРІ
  if grep -q "try:\|except" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: РѕР±СЂР°Р±РѕС‚РєР° РѕС€РёР±РѕРє СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "Python: РѕР±СЂР°Р±РѕС‚РєР° РѕС€РёР±РѕРє РЅРµ РЅР°Р№РґРµРЅР°"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ URLError РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ
  if grep -q "URLError\|urllib.error" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: РѕР±СЂР°Р±РѕС‚РєР° СЃРµС‚РµРІС‹С… РѕС€РёР±РѕРє"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: РѕР±СЂР°Р±РѕС‚РєР° СЃРµС‚РµРІС‹С… РѕС€РёР±РѕРє РЅРµ РЅР°Р№РґРµРЅР°"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ Exception РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ
  if grep -q "except Exception" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: РѕР±СЂР°Р±РѕС‚РєР° РѕР±С‰РёС… РёСЃРєР»СЋС‡РµРЅРёР№"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: РѕР±СЂР°Р±РѕС‚РєР° РѕР±С‰РёС… РёСЃРєР»СЋС‡РµРЅРёР№ РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Python Р±РѕС‚ вЂ” РІРёР·СѓР°Р»РёР·Р°С†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_python_bot_visualization() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Python РІРёР·СѓР°Р»РёР·Р°С†РёРё..."
  check_python_functions "РІРёР·СѓР°Р»РёР·Р°С†РёРё" "bar"

  # РџСЂРѕРІРµСЂРєР° РёСЃРїРѕР»СЊР·РѕРІР°РЅРёСЏ emoji (РІСЃРµ СЃСЂР°Р·Сѓ)
  if grep -q "рџ”ґ" "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q "рџџў" "${SCRIPT_DIR}/setup-telegram.sh" &&
    grep -q "вљ пёЏ" "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Python: emoji РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ"
    ((TESTS_PASSED++)) || true
  else
    warn "Python: emoji РЅРµ РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: systemd СЃРµСЂРІРёСЃ вЂ” Р±РµР·РѕРїР°СЃРЅРѕСЃС‚СЊ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_systemd_security() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ Р±РµР·РѕРїР°СЃРЅРѕСЃС‚Рё systemd СЃРµСЂРІРёСЃР°..."

  check_systemd_directives "ProtectHome=true" "ProtectSystem=strict" "NoNewPrivileges=true"

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РїРµСЂРµРјРµРЅРЅС‹Рµ РѕРєСЂСѓР¶РµРЅРёСЏ РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ РґР»СЏ С‚РѕРєРµРЅРѕРІ
  if grep -q 'Environment="TG_TOKEN=' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Systemd: С‚РѕРєРµРЅ РІ Environment"
    ((TESTS_PASSED++)) || true
  else
    fail "Systemd: С‚РѕРєРµРЅ РЅРµ РІ Environment"
  fi

  if grep -q 'Environment="TG_CHAT_ID=' "${SCRIPT_DIR}/setup-telegram.sh"; then
    pass "Systemd: chat_id РІ Environment"
    ((TESTS_PASSED++)) || true
  else
    warn "Systemd: chat_id РЅРµ РІ Environment"
  fi
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - setup-telegram.sh       в•‘${PLAIN}"
  echo -e "${YELLOW}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${PLAIN}"
  echo ""

  info "РўРµСЃС‚РёСЂСѓРµРјС‹Р№ СЃРєСЂРёРїС‚: ${SCRIPT_DIR}/setup-telegram.sh"
  echo ""

  # в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_functions_exist
  echo ""

  test_dependencies
  echo ""

  test_security
  echo ""

  test_python_bot_structure
  echo ""

  test_systemd_service
  echo ""

  test_cron_jobs
  echo ""

  test_logging
  echo ""

  test_installation_structure
  echo ""

  test_token_validation
  echo ""

  test_chat_id_validation
  echo ""

  test_python_bot_metrics
  echo ""

  test_python_bot_send_functions
  echo ""

  test_python_bot_commands
  echo ""

  test_python_bot_polling
  echo ""

  test_python_bot_alerts
  echo ""

  test_python_bot_backups
  echo ""

  test_python_bot_entry_point
  echo ""

  test_python_bot_error_handling
  echo ""

  test_python_bot_visualization
  echo ""

  test_systemd_security
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
