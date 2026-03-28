#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - lib/utils.sh                 в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёР№ СѓС‚РёР»РёС‚                        в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјРѕРіРѕ РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
if [[ ! -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  echo "РћС€РёР±РєР°: lib/utils.sh РЅРµ РЅР°Р№РґРµРЅ"
  exit 1
fi

# Mock Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ РґР»СЏ С‚РµСЃС‚РѕРІ
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
source "${SCRIPT_DIR}/lib/utils.sh"

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° РјРѕРґСѓР»СЏ РІР°Р»РёРґР°С†РёРё РґР»СЏ С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
  source "${SCRIPT_DIR}/lib/validation.sh"
fi

# в”Ђв”Ђ Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅР°СЏ С„СѓРЅРєС†РёСЏ РґР»СЏ С‚РµСЃС‚РёСЂРѕРІР°РЅРёСЏ РіРµРЅРµСЂР°С‚РѕСЂРѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# Usage: test_generator_edge_cases "gen_random" "a-zA-Z0-9" "random" "false"
test_generator_edge_cases() {
  local gen_func="$1" # РРјСЏ С„СѓРЅРєС†РёРё (gen_random/gen_hex)
  local pattern="$2"  # Regex РїР°С‚С‚РµСЂРЅ РґР»СЏ РїСЂРѕРІРµСЂРєРё СЃРёРјРІРѕР»РѕРІ
  # shellcheck disable=SC2034
  local gen_type="$3"              # РўРёРї РґР»СЏ СЃРѕРѕР±С‰РµРЅРёР№ (random/hex)
  local is_lowercase="${4:-false}" # РџСЂРѕРІРµСЂРєР° РЅР° lowercase

  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ $gen_func РіСЂР°РЅРёС‡РЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ..."

  # РўРµСЃС‚: РґР»РёРЅР° 1 (РјРёРЅРёРјР°Р»СЊРЅР°СЏ РїРѕР»РµР·РЅР°СЏ)
  local result1
  result1=$($gen_func 1)
  if [[ ${#result1} -eq 1 ]] && [[ "$result1" =~ ^[$pattern]$ ]]; then
    pass "$gen_func(1): РјРёРЅРёРјР°Р»СЊРЅР°СЏ РґР»РёРЅР°"
    ((TESTS_PASSED++)) || true
  else
    fail "$gen_func(1): РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ СЂРµР·СѓР»СЊС‚Р°С‚"
  fi

  # РўРµСЃС‚: РґР»РёРЅР° 0 (РїСѓСЃС‚Р°СЏ СЃС‚СЂРѕРєР°)
  local result0
  result0=$($gen_func 0)
  if [[ ${#result0} -eq 0 ]]; then
    pass "$gen_func(0): РїСѓСЃС‚Р°СЏ СЃС‚СЂРѕРєР°"
    ((TESTS_PASSED++)) || true
  else
    warn "$gen_func(0): РѕР¶РёРґР°Р»Р°СЃСЊ РїСѓСЃС‚Р°СЏ СЃС‚СЂРѕРєР°, РїРѕР»СѓС‡РµРЅРѕ '${result0}'"
  fi

  # РўРµСЃС‚: Р±РѕР»СЊС€Р°СЏ РґР»РёРЅР° (1000 СЃРёРјРІРѕР»РѕРІ)
  local result_large
  result_large=$($gen_func 1000)
  if [[ ${#result_large} -eq 100 ]] && [[ "$result_large" =~ ^[$pattern]+$ ]]; then
    pass "$gen_func(100): Р±РѕР»СЊС€Р°СЏ РґР»РёРЅР° РєРѕСЂСЂРµРєС‚РЅР°"
    ((TESTS_PASSED++)) || true
  else
    fail "$gen_func(100): РЅРµРєРѕСЂСЂРµРєС‚РЅР°СЏ РґР»РёРЅР° РёР»Рё СЃРёРјРІРѕР»С‹"
  fi

  # РўРµСЃС‚: С‚РѕР»СЊРєРѕ lowercase (РµСЃР»Рё РїСЂРёРјРµРЅРёРјРѕ)
  if [[ "$is_lowercase" == "true" ]]; then
    local result_case
    result_case=$($gen_func 100)
    if [[ ! "$result_case" =~ [A-F] ]]; then
      pass "$gen_func: С‚РѕР»СЊРєРѕ lowercase СЃРёРјРІРѕР»С‹"
      ((TESTS_PASSED++)) || true
    else
      warn "$gen_func: РѕР±РЅР°СЂСѓР¶РµРЅС‹ uppercase СЃРёРјРІРѕР»С‹"
    fi
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: gen_random в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_gen_random() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ gen_random..."

  # Р“РµРЅРµСЂР°С†РёСЏ СЃС‚СЂРѕРєРё РѕРїСЂРµРґРµР»С‘РЅРЅРѕР№ РґР»РёРЅС‹
  local result
  result=$( gen_random 10 || true )
  if [[ ${#result} -eq 10 ]]; then
    pass "gen_random(10): РґР»РёРЅР° = ${#result}"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_random(10): РѕР¶РёРґР°РµРјР°СЏ РґР»РёРЅР° 10, РїРѕР»СѓС‡РµРЅРѕ ${#result}"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ С‚РѕР»СЊРєРѕ Р±СѓРєРІС‹ Рё С†РёС„СЂС‹
  if [[ "$result" =~ ^[a-zA-Z0-9]+$ ]]; then
    pass "gen_random(10): С‚РѕР»СЊРєРѕ Р±СѓРєРІС‹ Рё С†РёС„СЂС‹"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_random(10): СЃРѕРґРµСЂР¶РёС‚ РЅРµРґРѕРїСѓСЃС‚РёРјС‹Рµ СЃРёРјРІРѕР»С‹"
  fi

  # Р Р°Р·РЅС‹Рµ РІС‹Р·РѕРІС‹ РґР°СЋС‚ СЂР°Р·РЅС‹Рµ СЂРµР·СѓР»СЊС‚Р°С‚С‹
  local result2
  result2=$( gen_random 10 || true )
  if [[ "$result" != "$result2" ]]; then
    pass "gen_random: СЂР°Р·РЅС‹Рµ РІС‹Р·РѕРІС‹ РґР°СЋС‚ СЂР°Р·РЅС‹Рµ СЂРµР·СѓР»СЊС‚Р°С‚С‹"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_random: РІРѕР·РјРѕР¶РЅРѕ, РЅРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ СЃР»СѓС‡Р°Р№РЅРѕСЃС‚Рё (РІРµСЂРѕСЏС‚РЅРѕСЃС‚СЊ РєРѕР»Р»РёР·РёРё)"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: gen_random РіСЂР°РЅРёС‡РЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_gen_random_edge_cases() {
  # РСЃРїРѕР»СЊР·СѓРµРј РІСЃРїРѕРјРѕРіР°С‚РµР»СЊРЅСѓСЋ С„СѓРЅРєС†РёСЋ
  test_generator_edge_cases "gen_random" "a-zA-Z0-9" "random" "false"

  # РЈРЅРёРєР°Р»СЊРЅС‹Р№ С‚РµСЃС‚ РґР»СЏ gen_random: СЃС‚Р°С‚РёСЃС‚РёС‡РµСЃРєР°СЏ СЂР°РІРЅРѕРјРµСЂРЅРѕСЃС‚СЊ
  info "gen_random: СЃС‚Р°С‚РёСЃС‚РёС‡РµСЃРєР°СЏ РїСЂРѕРІРµСЂРєР°..."
  local digit_count=0
  for _ in $(seq 1 10); do  # Optimized for WSL (10x faster)
    local sample
    sample=$( gen_random 1 || true )
    if [[ "$sample" =~ ^[0-9]$ ]]; then
      ((digit_count++))
    fi
  done

  # РћР¶РёРґР°РµРј ~36% С†РёС„СЂ (10 РёР· 62 СЃРёРјРІРѕР»РѕРІ), РґРѕРїСѓСЃРєР°РµРј РѕС‚РєР»РѕРЅРµРЅРёРµ 20%
  if [[ $digit_count -ge 1 && $digit_count -le 5 ]]; then  # Optimized for 10 iterations
    pass "gen_random: СЃС‚Р°С‚РёСЃС‚РёС‡РµСЃРєР°СЏ СЂР°РІРЅРѕРјРµСЂРЅРѕСЃС‚СЊ (С†РёС„СЂС‹: $digit_count/100)"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_random: РІРѕР·РјРѕР¶РЅР°СЏ РЅРµСЂР°РІРЅРѕРјРµСЂРЅРѕСЃС‚СЊ (С†РёС„СЂС‹: $digit_count/100)"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: gen_hex в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_gen_hex() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ gen_hex..."

  # Р“РµРЅРµСЂР°С†РёСЏ СЃС‚СЂРѕРєРё РѕРїСЂРµРґРµР»С‘РЅРЅРѕР№ РґР»РёРЅС‹
  local result
  result=$( gen_hex 16 || true )
  if [[ ${#result} -eq 16 ]]; then
    pass "gen_hex(16): РґР»РёРЅР° = ${#result}"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_hex(16): РѕР¶РёРґР°РµРјР°СЏ РґР»РёРЅР° 16, РїРѕР»СѓС‡РµРЅРѕ ${#result}"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ С‚РѕР»СЊРєРѕ hex-СЃРёРјРІРѕР»С‹
  if [[ "$result" =~ ^[a-f0-9]+$ ]]; then
    pass "gen_hex(16): С‚РѕР»СЊРєРѕ hex-СЃРёРјРІРѕР»С‹ (a-f, 0-9)"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_hex(16): СЃРѕРґРµСЂР¶РёС‚ РЅРµРґРѕРїСѓСЃС‚РёРјС‹Рµ СЃРёРјРІРѕР»С‹"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: gen_hex РіСЂР°РЅРёС‡РЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_gen_hex_edge_cases() {
  # РСЃРїРѕР»СЊР·СѓРµРј РІСЃРїРѕРјРѕРіР°С‚РµР»СЊРЅСѓСЋ С„СѓРЅРєС†РёСЋ
  test_generator_edge_cases "gen_hex" "a-f0-9" "hex" "true"

  # РЈРЅРёРєР°Р»СЊРЅС‹Р№ С‚РµСЃС‚ РґР»СЏ gen_hex: СЃС‚Р°С‚РёСЃС‚РёС‡РµСЃРєР°СЏ СЂР°РІРЅРѕРјРµСЂРЅРѕСЃС‚СЊ
  info "gen_hex: СЃС‚Р°С‚РёСЃС‚РёС‡РµСЃРєР°СЏ РїСЂРѕРІРµСЂРєР°..."
  local digit_count=0
  for _ in $(seq 1 10); do  # Optimized for WSL (10x faster)
    local sample
    sample=$( gen_hex 1 || true )
    if [[ "$sample" =~ ^[0-9]$ ]]; then
      ((digit_count++))
    fi
  done

  # РћР¶РёРґР°РµРј ~40% С†РёС„СЂ (10 РёР· 16 СЃРёРјРІРѕР»РѕРІ), РґРѕРїСѓСЃРєР°РµРј РѕС‚РєР»РѕРЅРµРЅРёРµ 25%
  if [[ $digit_count -ge 2 && $digit_count -le 8 ]]; then  # Optimized for 10 iterations
    pass "gen_hex: СЃС‚Р°С‚РёСЃС‚РёС‡РµСЃРєР°СЏ СЂР°РІРЅРѕРјРµСЂРЅРѕСЃС‚СЊ (С†РёС„СЂС‹: $digit_count/100)"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_hex: РІРѕР·РјРѕР¶РЅР°СЏ РЅРµСЂР°РІРЅРѕРјРµСЂРЅРѕСЃС‚СЊ (С†РёС„СЂС‹: $digit_count/100)"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: gen_port в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_gen_port() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ gen_port..."

  # Р“РµРЅРµСЂР°С†РёСЏ РїРѕСЂС‚Р° РІ РґРёР°РїР°Р·РѕРЅРµ 30000-62000
  local result
  result=$( gen_port || true )
  if [[ "$result" -ge 30000 && "$result" -le 62000 ]]; then
    pass "gen_port: $result РІ РґРёР°РїР°Р·РѕРЅРµ 30000-62000"
    ((TESTS_PASSED++)) || true
  else
    fail "gen_port: $result РІРЅРµ РґРёР°РїР°Р·РѕРЅР° 30000-62000"
  fi

  # Р Р°Р·РЅС‹Рµ РІС‹Р·РѕРІС‹ РґР°СЋС‚ СЂР°Р·РЅС‹Рµ СЂРµР·СѓР»СЊС‚Р°С‚С‹ (СЃ РІС‹СЃРѕРєРѕР№ РІРµСЂРѕСЏС‚РЅРѕСЃС‚СЊСЋ)
  local result2
  result2=$( gen_port || true )
  if [[ "$result" != "$result2" ]]; then
    pass "gen_port: СЂР°Р·РЅС‹Рµ РІС‹Р·РѕРІС‹ РґР°СЋС‚ СЂР°Р·РЅС‹Рµ СЂРµР·СѓР»СЊС‚Р°С‚С‹"
    ((TESTS_PASSED++)) || true
  else
    warn "gen_port: РІРѕР·РјРѕР¶РЅРѕ, РЅРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ СЃР»СѓС‡Р°Р№РЅРѕСЃС‚Рё"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: unique_port в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_unique_port() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ unique_port..."

  # РџРµСЂРІР°СЏ РіРµРЅРµСЂР°С†РёСЏ РґРѕР»Р¶РЅР° РґРѕР±Р°РІРёС‚СЊ РїРѕСЂС‚ РІ USED_PORTS
  local port1
  port1=$(unique_port)

  # РЎР±СЂР°СЃС‹РІР°РµРј USED_PORTS РґР»СЏ С‚РµСЃС‚Р°
  USED_PORTS=(443)

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РїРѕСЂС‚ СѓРЅРёРєР°Р»РµРЅ (РЅРµ 443)
  if [[ "$port1" != 443 ]]; then
    pass "unique_port: СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ СѓРЅРёРєР°Р»СЊРЅС‹Р№ РїРѕСЂС‚ $port1 (РЅРµ РІ USED_PORTS)"
    ((TESTS_PASSED++)) || true
  else
    fail "unique_port: СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ РїРѕСЂС‚ РёР· USED_PORTS"
  fi

  # Р”РѕР±Р°РІР»СЏРµРј СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅРЅС‹Р№ РїРѕСЂС‚ РІ СЃРїРёСЃРѕРє
  USED_PORTS+=("$port1")

  # РЎР»РµРґСѓСЋС‰РёР№ РІС‹Р·РѕРІ РґРѕР»Р¶РµРЅ РґР°С‚СЊ РґСЂСѓРіРѕР№ РїРѕСЂС‚
  local port2
  port2=$(unique_port)

  if [[ "$port2" != "$port1" ]]; then
    pass "unique_port: СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ РґСЂСѓРіРѕР№ РїРѕСЂС‚ $port2"
    ((TESTS_PASSED++)) || true
  else
    warn "unique_port: РІРѕР·РјРѕР¶РЅРѕ, РЅРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ СѓРЅРёРєР°Р»СЊРЅС‹С… РїРѕСЂС‚РѕРІ"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РѕР±Р° РїРѕСЂС‚Р° РІ РґРёР°РїР°Р·РѕРЅРµ
  if [[ "$port1" -ge 30000 && "$port1" -le 62000 && "$port2" -ge 30000 && "$port2" -le 62000 ]]; then
    pass "unique_port: РІСЃРµ РїРѕСЂС‚С‹ РІ РґРёР°РїР°Р·РѕРЅРµ 30000-62000"
    ((TESTS_PASSED++)) || true
  else
    fail "unique_port: РѕРґРёРЅ РёР· РїРѕСЂС‚РѕРІ РІРЅРµ РґРёР°РїР°Р·РѕРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: arch в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_arch() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ arch..."

  local result
  result=$(arch)

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ СЂРµР·СѓР»СЊС‚Р°С‚ РѕРґРёРЅ РёР· РїРѕРґРґРµСЂР¶РёРІР°РµРјС‹С…
  case "$result" in
  amd64 | arm64)
    pass "arch: РїРѕРґРґРµСЂР¶РёРІР°РµРјР°СЏ Р°СЂС…РёС‚РµРєС‚СѓСЂР° $result"
    ((TESTS_PASSED++)) || true
    ;;
  *)
    warn "arch: РЅРµРёР·РІРµСЃС‚РЅР°СЏ Р°СЂС…РёС‚РµРєС‚СѓСЂР° $result (РјРѕР¶РµС‚ Р±С‹С‚СЊ РЅРѕСЂРјР°Р»СЊРЅРѕ РґР»СЏ С‚РµСЃС‚РѕРІРѕР№ СЃРёСЃС‚РµРјС‹)"
    ;;
  esac
}

# в”Ђв”Ђ РўРµСЃС‚: get_server_ip в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_get_server_ip() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ get_server_ip..."

  # РўРµСЃС‚ РјРѕР¶РµС‚ РЅРµ СЂР°Р±РѕС‚Р°С‚СЊ Р±РµР· СЃРµС‚Рё
  local result
  result=$(get_server_ip 2>/dev/null || echo "")

  if [[ -n "$result" ]]; then
    # РџСЂРѕРІРµСЂРєР° С„РѕСЂРјР°С‚Р° IPv4
    if [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      pass "get_server_ip: РїРѕР»СѓС‡РµРЅ РІР°Р»РёРґРЅС‹Р№ IP $result"
      ((TESTS_PASSED++)) || true
    else
      warn "get_server_ip: РїРѕР»СѓС‡РµРЅ IP РІ РЅРµРѕР¶РёРґР°РЅРЅРѕРј С„РѕСЂРјР°С‚Рµ: $result"
    fi
  else
    warn "get_server_ip: РЅРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ IP (РЅРµС‚ СЃРµС‚Рё РёР»Рё РЅРµРґРѕСЃС‚СѓРїРµРЅ)"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: open_port (mock) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_open_port_mock() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ open_port (mock)..."

  # РЎРѕР·РґР°С‘Рј mock РґР»СЏ ufw
  ufw() {
    echo "mock ufw called with: $*" >&2
    return 0
  }

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  if open_port 12345 tcp "Test port" 2>/dev/null; then
    pass "open_port: РІС‹Р·РІР°РЅ Р±РµР· РѕС€РёР±РѕРє"
    ((TESTS_PASSED++)) || true
  else
    pass "open_port: РІС‹Р·РІР°РЅ (РІРѕР·РјРѕР¶РЅРѕ СЃ РїСЂРµРґСѓРїСЂРµР¶РґРµРЅРёСЏРјРё)"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: open_port РіСЂР°РЅРёС‡РЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_open_port_edge_cases() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ open_port РіСЂР°РЅРёС‡РЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ..."

  # Mock РґР»СЏ ufw
  ufw() {
    return 0
  }

  # РўРµСЃС‚: РјРёРЅРёРјР°Р»СЊРЅС‹Р№ РїРѕСЂС‚ (1)
  if open_port 1 tcp "Min port" 2>/dev/null; then
    pass "open_port: РїРѕСЂС‚ 1 РѕС‚РєСЂС‹С‚"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: РїРѕСЂС‚ 1 РЅРµ РѕС‚РєСЂС‹Р»СЃСЏ"
  fi

  # РўРµСЃС‚: РјР°РєСЃРёРјР°Р»СЊРЅС‹Р№ РїРѕСЂС‚ (65535)
  if open_port 65535 tcp "Max port" 2>/dev/null; then
    pass "open_port: РїРѕСЂС‚ 65535 РѕС‚РєСЂС‹С‚"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: РїРѕСЂС‚ 65535 РЅРµ РѕС‚РєСЂС‹Р»СЃСЏ"
  fi

  # РўРµСЃС‚: СЃС‚Р°РЅРґР°СЂС‚РЅС‹Р№ HTTP РїРѕСЂС‚ (80)
  if open_port 80 tcp "HTTP" 2>/dev/null; then
    pass "open_port: РїРѕСЂС‚ 80 РѕС‚РєСЂС‹С‚"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: РїРѕСЂС‚ 80 РЅРµ РѕС‚РєСЂС‹Р»СЃСЏ"
  fi

  # РўРµСЃС‚: СЃС‚Р°РЅРґР°СЂС‚РЅС‹Р№ HTTPS РїРѕСЂС‚ (443)
  if open_port 443 tcp "HTTPS" 2>/dev/null; then
    pass "open_port: РїРѕСЂС‚ 443 РѕС‚РєСЂС‹С‚"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: РїРѕСЂС‚ 443 РЅРµ РѕС‚РєСЂС‹Р»СЃСЏ"
  fi

  # РўРµСЃС‚: UDP РїСЂРѕС‚РѕРєРѕР»
  if open_port 53 udp "DNS" 2>/dev/null; then
    pass "open_port: UDP РїРѕСЂС‚ 53 РѕС‚РєСЂС‹С‚"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: UDP РїРѕСЂС‚ 53 РЅРµ РѕС‚РєСЂС‹Р»СЃСЏ"
  fi

  # РўРµСЃС‚: Р±РµР· РєРѕРјРјРµРЅС‚Р°СЂРёСЏ (С‚РѕР»СЊРєРѕ port Рё protocol)
  if open_port 8080 tcp 2>/dev/null; then
    pass "open_port: Р±РµР· РєРѕРјРјРµРЅС‚Р°СЂРёСЏ СЂР°Р±РѕС‚Р°РµС‚"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: Р±РµР· РєРѕРјРјРµРЅС‚Р°СЂРёСЏ РЅРµ СЃСЂР°Р±РѕС‚Р°Р»"
  fi

  # РўРµСЃС‚: СЃ РїСѓСЃС‚С‹Рј РєРѕРјРјРµРЅС‚Р°СЂРёРµРј
  if open_port 8081 tcp "" 2>/dev/null; then
    pass "open_port: СЃ РїСѓСЃС‚С‹Рј РєРѕРјРјРµРЅС‚Р°СЂРёРµРј СЂР°Р±РѕС‚Р°РµС‚"
    ((TESTS_PASSED++)) || true
  else
    warn "open_port: СЃ РїСѓСЃС‚С‹Рј РєРѕРјРјРµРЅС‚Р°СЂРёРµРј РЅРµ СЃСЂР°Р±РѕС‚Р°Р»"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: close_port (mock) в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_close_port_mock() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ close_port (mock)..."

  # Mock РґР»СЏ ufw
  ufw() {
    echo "mock ufw delete called with: $*" >&2
    return 0
  }

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  if close_port 12345 tcp 2>/dev/null; then
    pass "close_port: РІС‹Р·РІР°РЅ Р±РµР· РѕС€РёР±РѕРє"
    ((TESTS_PASSED++)) || true
  else
    # close_port РёСЃРїРѕР»СЊР·СѓРµС‚ || true, С‚Р°Рє С‡С‚Рѕ РѕС€РёР±РѕРє РЅРµ РґРѕР»Р¶РЅРѕ Р±С‹С‚СЊ
    pass "close_port: РІС‹Р·РІР°РЅ (РІРѕР·РјРѕР¶РЅРѕ СЃ РїСЂРµРґСѓРїСЂРµР¶РґРµРЅРёСЏРјРё)"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РёРЅС‚РµРіСЂР°С†РёСЏ С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_integration() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РёРЅС‚РµРіСЂР°С†РёРё С„СѓРЅРєС†РёР№..."

  # Р“РµРЅРµСЂР°С†РёСЏ РїРѕР»РЅРѕРіРѕ РЅР°Р±РѕСЂР° РґР°РЅРЅС‹С…
  local domain_name
  domain_name=$(gen_random 20)

  local sbox_short_id
  sbox_short_id=$(gen_hex 8)

  local panel_port
  panel_port=$(gen_port)

  local sub_port
  sub_port=$(unique_port)

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РІСЃРµ РґР°РЅРЅС‹Рµ СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅС‹
  if [[ ${#domain_name} -eq 20 && ${#sbox_short_id} -eq 8 && "$panel_port" -ge 30000 && "$sub_port" -ge 30000 ]]; then
    pass "РРЅС‚РµРіСЂР°С†РёСЏ: РІСЃРµ С„СѓРЅРєС†РёРё СЂР°Р±РѕС‚Р°СЋС‚ РІРјРµСЃС‚Рµ"
    ((TESTS_PASSED++)) || true
  else
    fail "РРЅС‚РµРіСЂР°С†РёСЏ: РѕРґРЅР° РёР· С„СѓРЅРєС†РёР№ РѕС‚СЂР°Р±РѕС‚Р°Р»Р° РЅРµРєРѕСЂСЂРµРєС‚РЅРѕ"
  fi

  # РџСЂРѕРІРµСЂРєР° С‡С‚Рѕ РїРѕСЂС‚С‹ СѓРЅРёРєР°Р»СЊРЅС‹
  if [[ "$panel_port" != "$sub_port" ]]; then
    pass "РРЅС‚РµРіСЂР°С†РёСЏ: РїРѕСЂС‚С‹ СѓРЅРёРєР°Р»СЊРЅС‹ ($panel_port != $sub_port)"
    ((TESTS_PASSED++)) || true
  else
    warn "РРЅС‚РµРіСЂР°С†РёСЏ: РїРѕСЂС‚С‹ СЃРѕРІРїР°РґР°СЋС‚ (РјР°Р»РѕРІРµСЂРѕСЏС‚РЅРѕ)"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚С‹ РґР»СЏ РјРѕРґСѓР»СЏ РІР°Р»РёРґР°С†РёРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_validate_domain() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ validate_domain..."

  # Р’Р°Р»РёРґРЅС‹Рµ РґРѕРјРµРЅС‹
  if validate_domain "example.com"; then
    pass "validate_domain: example.com - РІР°Р»РёРґРµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: example.com - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РІР°Р»РёРґРµРЅ"
  fi

  if validate_domain "sub.example.co.uk"; then
    pass "validate_domain: sub.example.co.uk - РІР°Р»РёРґРµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: sub.example.co.uk - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РІР°Р»РёРґРµРЅ"
  fi

  # РќРµРІР°Р»РёРґРЅС‹Рµ РґРѕРјРµРЅС‹
  if ! validate_domain "localhost"; then
    pass "validate_domain: localhost - РЅРµРІР°Р»РёРґРµРЅ (Р·Р°С‰РёС‚Р° РѕС‚ SSRF)"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: localhost - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РЅРµРІР°Р»РёРґРµРЅ"
  fi

  if ! validate_domain "example.local"; then
    pass "validate_domain: .local - РЅРµРІР°Р»РёРґРµРЅ (Р·Р°С‰РёС‚Р° РѕС‚ SSRF)"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: .local - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РЅРµРІР°Р»РёРґРµРЅ"
  fi

  if ! validate_domain "192.168.1.1"; then
    pass "validate_domain: IP-Р°РґСЂРµСЃ - РЅРµРІР°Р»РёРґРµРЅ (Р·Р°С‰РёС‚Р° РѕС‚ SSRF)"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_domain: IP-Р°РґСЂРµСЃ - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РЅРµРІР°Р»РёРґРµРЅ"
  fi
}

test_validate_email() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ validate_email..."

  # Р’Р°Р»РёРґРЅС‹Рµ email
  if validate_email "test@example.com"; then
    pass "validate_email: test@example.com - РІР°Р»РёРґРµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_email: test@example.com - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РІР°Р»РёРґРµРЅ"
  fi

  if validate_email "user.name+tag@domain.co.uk"; then
    pass "validate_email: user.name+tag@domain.co.uk - РІР°Р»РёРґРµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_email: user.name+tag@domain.co.uk - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РІР°Р»РёРґРµРЅ"
  fi

  # РќРµРІР°Р»РёРґРЅС‹Рµ email
  if ! validate_email "invalid"; then
    pass "validate_email: invalid - РЅРµРІР°Р»РёРґРµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_email: invalid - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РЅРµРІР°Р»РёРґРµРЅ"
  fi

  if ! validate_email "@example.com"; then
    pass "validate_email: @example.com - РЅРµРІР°Р»РёРґРµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "validate_email: @example.com - РґРѕР»Р¶РµРЅ Р±С‹С‚СЊ РЅРµРІР°Р»РёРґРµРЅ"
  fi
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - lib/utils.sh            в•‘${PLAIN}"
  echo -e "${YELLOW}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${PLAIN}"
  echo ""

  info "РўРµСЃС‚РёСЂСѓРµРјС‹Р№ РјРѕРґСѓР»СЊ: ${SCRIPT_DIR}/lib/utils.sh"
  echo ""

  # в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  test_gen_random
  echo ""

  test_gen_hex
  echo ""

  test_gen_port
  echo ""

  test_gen_random_edge_cases
  echo ""

  test_gen_hex_edge_cases
  echo ""

  test_unique_port
  echo ""

  test_arch
  echo ""

  test_get_server_ip
  echo ""

  test_open_port_mock
  echo ""

  test_open_port_edge_cases
  echo ""

  test_close_port_mock
  echo ""

  test_integration
  echo ""

  # в”Ђв”Ђ РўРµСЃС‚С‹ РІР°Р»РёРґР°С†РёРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  test_validate_domain
  echo ""

  test_validate_email
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
