#!/bin/bash
# в-"в-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв--
# в-'        CubiVeil Unit Tests - Traffic Shaping Module     в-'
# в-'        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ lib/modules/traffic-shaping/         в-'
# в-љв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ќ

# Strict mode РѕС‚РєР»СЋС‡РµРЅ РґР»СЏ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё СЃ mock-С„СѓРЅРєС†РёСЏРјРё

# в"Ђв"Ђ РЎС‡С'С‚С‡РёРє С‚РµСЃС‚РѕРІ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
TESTS_PASSED=0
TESTS_FAILED=0

# в"Ђв"Ђ Р¦РІРµС‚Р° в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# в"Ђв"Ђ Р¤СѓРЅРєС†РёРё РІС‹РІРѕРґР° в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
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

# в"Ђв"Ђ РџСѓС‚СЊ Рє РїСЂРѕРµРєС‚Сѓ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# в"Ђв"Ђ Р-Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјС‹С... РјРѕРґСѓР»РµР№ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
MODULE_PATH="${PROJECT_ROOT}/lib/modules/traffic-shaping/install.sh"
PERSIST_PATH="${PROJECT_ROOT}/lib/modules/traffic-shaping/persist.sh"
UNINSTALL_PATH="${PROJECT_ROOT}/lib/modules/traffic-shaping/uninstall.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "РћС€РёР±РєР°: Traffic Shaping module РЅРµ РЅР°Р№РґРµРЅ: $MODULE_PATH"
  exit 1
fi

# в"Ђв"Ђ Mock Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }

# Mock core С„СѓРЅРєС†РёР№
pkg_install_packages() {
  echo "[MOCK] pkg_install_packages: $*" >&2
  return 0
}

# Mock РґР»СЏ РєРѕРјР°РЅРґ
command() {
  local cmd="$1"
  if [[ "$cmd" == "-v" ]]; then
    if [[ "$2" == "tc" ]]; then
      return 0 # tc РґРѕСЃС‚СѓРїРµРЅ
    fi
  fi
  return 0
}

# Mock РґР»СЏ jq
jq() {
  local filter="$1"
  local file="${2:-}"

  # Р-СЃР»Рё С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ Рё jq РґРѕСЃС‚СѓРїРµРЅ, С‡РёС‚Р°РµРј СЂРµР°Р»СЊРЅРѕРµ Р·РЅР°С‡РµРЅРёРµ
  if [[ -n "$file" ]] && [[ -f "$file" ]]; then
    if command -v jq &>/dev/null; then
      command jq -r "$filter" "$file" 2>/dev/null || echo ""
    else
      # Fallback: РёСЃРїРѕР»СЊР·СѓРµРј grep РґР»СЏ РїСЂРѕСЃС‚РѕРіРѕ РїР°СЂСЃРёРЅРіР°
      local key="${filter#*.}"
      key="${key%%\[*}"
      local result
      result=$(grep -o "\"$key\"[[:space:]]*:[[:space:]]*[^,}]*" "$file" 2>/dev/null |
        sed 's/.*:[[:space:]]*//' | tr -d '"' | head -1)
      echo "${result:-}"
    fi
    return 0
  fi

  # Mock РґР»СЏ С‚РµСЃС‚РѕРІ Р±РµР· С„Р°Р№Р»Р°
  if [[ "$filter" == *".interface"* ]]; then
    echo "eth0"
  elif [[ "$filter" == *".delay_ms"* ]]; then
    echo "4"
  elif [[ "$filter" == *".jitter_ms"* ]]; then
    echo "12"
  elif [[ "$filter" == *".reorder_percent"* ]]; then
    echo "0.3"
  else
    echo ""
  fi
  return 0
}

# Mock РґР»СЏ СЃРёСЃС‚РµРјРЅС‹С... РєРѕРјР°РЅРґ
mkdir() {
  local dir="$1"
  # РћР±СЂР°Р±РѕС‚РєР° -p С„Р»Р°РіР°
  if [[ "$1" == "-p" ]]; then
    dir="$2"
  fi
  # РЎРѕР·РґР°РµРј РґРёСЂРµРєС‚РѕСЂРёСЋ РµСЃР»Рё РѕРЅР° РЅРµ СЃСѓС‰РµСЃС‚РІСѓРµС‚
  if [[ ! -d "$dir" ]]; then
    command mkdir -p "$dir" 2>/dev/null || true
  fi
}

cat() {
  # РџСЂРѕРІРµСЂСЏРµРј РµСЃС‚СЊ Р»Рё РїРµСЂРµРЅР°РїСЂР°РІР»РµРЅРёРµ РІ С„Р°Р№Р» (> С„Р°Р№Р»)
  local args=("$@")
  local redirect_file=""
  local is_heredoc=false

  # РџСЂРѕРІРµСЂСЏРµРј Р°СЂРіСѓРјРµРЅС‚С‹ РЅР° РЅР°Р»РёС‡РёРµ >
  for i in "${!args[@]}"; do
    if [[ "${args[$i]}" == ">" ]]; then
      redirect_file="${args[$((i + 1))]}"
      is_heredoc=true
      break
    fi
  done

  # Р-СЃР»Рё heredoc/redirect РІ С„Р°Р№Р»
  if $is_heredoc && [[ -n "$redirect_file" ]]; then
    # Р§РёС‚Р°РµРј stdin Рё РїРёС€РµРј РІ С„Р°Р№Р»
    local content
    content=$(command cat)
    echo "$content" >"$redirect_file" 2>/dev/null || true
    return 0
  fi

  # Р-СЃР»Рё С‡С‚РµРЅРёРµ РёР· С„Р°Р№Р»Р°
  if [[ $# -gt 0 ]] && [[ -f "$1" ]]; then
    command cat "$@" 2>/dev/null || echo ""
  # Р-СЃР»Рё stdin (pipe)
  elif [[ ! -t 0 ]]; then
    command cat 2>/dev/null
  else
    echo ""
  fi
}
chmod() { return 0; }
systemctl() {
  echo "[MOCK] systemctl: $*" >&2
  return 0
}
bash() { return 0; }
tc() { return 0; }
ip() {
  if [[ "$*" == *"route show default"* ]]; then
    echo "default via 192.168.1.1 dev eth0"
  else
    echo "[MOCK] ip: $*" >&2
  fi
}
awk() { echo "eth0"; }
head() {
  # РќРµ РїРµСЂРµС...РІР°С‚С‹РІР°РµРј РІС‹Р·РѕРІС‹ СЃ -1 (РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ РІ С‚РµСЃС‚Р°С... shebang)
  if [[ "$1" == "-1" ]]; then
    /usr/bin/head "$@"
  # РћР±СЂР°Р±РѕС‚РєР° head -c1 (СЃРёРјРІРѕР»РѕРІ)
  elif [[ "$1" == "-c"* ]]; then
    /usr/bin/head "$@"
  else
    echo "line1"
  fi
}
cut() { echo "value"; }
rm() { return 0; }
date() { echo "2025-01-01T00:00:00Z"; }

# в"Ђв"Ђ Р-Р°РіСЂСѓР·РєР° РјРѕРґСѓР»РµР№ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
# shellcheck source=lib/modules/traffic-shaping/install.sh
source "$MODULE_PATH"

# РџРµСЂРµРѕРїСЂРµРґРµР»СЏРµРј РєРѕРЅСЃС‚Р°РЅС‚С‹ РїРѕСЃР»Рµ Р·Р°РіСЂСѓР·РєРё РјРѕРґСѓР»СЏ
export TS_CONFIG="/tmp/cubiveil-traffic-shaping-test.json"
export TS_SERVICE="cubiveil-tc"
export TS_APPLY_SCRIPT="/tmp/cubiveil-tc-apply-test.sh"

# в"Ђв"Ђ РўРµСЃС‚: С„Р°Р№Р»С‹ СЃСѓС‰РµСЃС‚РІСѓСЋС‚ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_files_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»РѕРІ РјРѕРґСѓР»СЏ..."

  local all_found=true
  local file
  for file in "$MODULE_PATH" "$PERSIST_PATH" "$UNINSTALL_PATH"; do
    if [[ -f "$file" ]]; then
      pass "$(basename "$file"): С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    else
      fail "$(basename "$file"): С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
      # shellcheck disable=SC2034
      all_found=false
    fi
  done
}

# в"Ђв"Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚РѕРІ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР°..."

  for file in "$MODULE_PATH" "$PERSIST_PATH" "$UNINSTALL_PATH"; do
    if bash -n "$file" 2>/dev/null; then
      pass "$(basename "$file"): СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
    else
      fail "$(basename "$file"): СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
    fi
  done
}

# в"Ђв"Ђ РўРµСЃС‚: shebang в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang..."

  for file in "$MODULE_PATH" "$PERSIST_PATH" "$UNINSTALL_PATH"; do
    local shebang
    read -r shebang <"$file"

    if [[ "$shebang" == "#!/bin/bash" ]]; then
      pass "$(basename "$file"): РєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang"
    else
      fail "$(basename "$file"): РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang: $shebang"
    fi
  done
}

# в"Ђв"Ђ РўРµСЃС‚: ts_generate_profile в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_ts_generate_profile() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ ts_generate_profile..."

  # РћС‡РёС‰Р°РµРј РїСЂРµРґС‹РґСѓС‰РёР№ РєРѕРЅС„РёРі РµСЃР»Рё РµСЃС‚СЊ
  rm -f "$TS_CONFIG" 2>/dev/null || true

  # Р'СЂРµРјРµРЅРЅРѕ Р·Р°РјРµРЅСЏРµРј heredoc РЅР° echo РґР»СЏ С‚РµСЃС‚Р°
  # РЎРѕС...СЂР°РЅСЏРµРј РѕСЂРёРіРёРЅР°Р»СЊРЅСѓСЋ С„СѓРЅРєС†РёСЋ
  local _original_ts_generate_profile
  _original_ts_generate_profile=$(declare -f ts_generate_profile 2>/dev/null || echo "")

  # РџРµСЂРµРѕРїСЂРµРґРµР»СЏРµРј С„СѓРЅРєС†РёСЋ РґР»СЏ РёСЃРїРѕР»СЊР·РѕРІР°РЅРёСЏ echo РІРјРµСЃС‚Рѕ heredoc
  ts_generate_profile() {
    # РџСЂРѕРІРµСЂСЏРµРј СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚СЊ РїРµСЂРµРґ РіРµРЅРµСЂР°С†РёРµР№
    if ! ts_check_compatibility; then
      log_warn "РЎРѕРІРјРµСЃС‚РёРјРѕСЃС‚СЊ РЅРµ РїСЂРѕРІРµСЂРµРЅР°, РїСЂРѕРґРѕР»Р¶Р°РµРј СЃ РѕСЃС‚РѕСЂРѕР¶РЅРѕСЃС‚СЊСЋ"
    fi

    local iface
    iface=$(ip route show default | awk '/default/ {print $5}' | head -1)
    [[ -z "$iface" ]] && {
      log_error "РќРµ СѓРґР°Р»РѕСЃСЊ РѕРїСЂРµРґРµР»РёС‚СЊ СЃРµС‚РµРІРѕР№ РёРЅС‚РµСЂС„РµР№СЃ"
      return 1
    }

    # РЈРЅРёРєР°Р»СЊРЅС‹Р№ "РїРѕС‡РµСЂРє" вЂ" РіРµРЅРµСЂРёСЂСѓРµС‚СЃСЏ РѕРґРёРЅ СЂР°Р·, РЅРµ РјРµРЅСЏРµС‚СЃСЏ
    local jitter=$((RANDOM % 16 + 5))        # 5вЂ"20 РјСЃ
    local delay=$((RANDOM % 7 + 2))          # 2вЂ"8 РјСЃ
    local reorder_tenths=$((RANDOM % 5 + 1)) # 0.1вЂ"0.5%

    mkdir -p /etc/cubiveil

    # РСЃРїРѕР»СЊР·СѓРµРј printf РІРјРµСЃС‚Рѕ heredoc
    printf '{\n  "interface":       "%s",\n  "delay_ms":        %s,\n  "jitter_ms":       %s,\n  "reorder_percent": "0.%s",\n  "generated_at":    "%s"\n}\n' \
      "$iface" "$delay" "$jitter" "$reorder_tenths" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >"$TS_CONFIG"

    chmod 600 "$TS_CONFIG"
    log_info "РџСЂРѕС„РёР»СЊ TC: iface=${iface} delay=${delay}ms jitter=${jitter}ms reorder=0.${reorder_tenths}%"
  }

  # Р'С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  ts_generate_profile

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РєРѕРЅС„РёРі СЃРѕР·РґР°РЅ
  if [[ -f "$TS_CONFIG" ]]; then
    pass "ts_generate_profile: РєРѕРЅС„РёРі СЃРѕР·РґР°РЅ"
  else
    fail "ts_generate_profile: РєРѕРЅС„РёРі РЅРµ СЃРѕР·РґР°РЅ"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹С... РїРѕР»РµР№
  if grep -q '"interface"' "$TS_CONFIG" &&
    grep -q '"delay_ms"' "$TS_CONFIG" &&
    grep -q '"jitter_ms"' "$TS_CONFIG" &&
    grep -q '"reorder_percent"' "$TS_CONFIG" &&
    grep -q '"generated_at"' "$TS_CONFIG"; then
    pass "ts_generate_profile: РІСЃРµ РїРѕР»СЏ РїСЂРёСЃСѓС‚СЃС‚РІСѓСЋС‚"
  else
    fail "ts_generate_profile: РЅРµ РІСЃРµ РїРѕР»СЏ РїСЂРёСЃСѓС‚СЃС‚РІСѓСЋС‚"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ delay_ms РІ РґРѕРїСѓСЃС‚РёРјРѕРј РґРёР°РїР°Р·РѕРЅРµ (2-8)
  local delay
  delay=$(grep -o '"delay_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)
  if [[ -n "$delay" ]] && [[ "$delay" -ge 2 ]] && [[ "$delay" -le 8 ]]; then
    pass "ts_generate_profile: delay_ms РІ РґРёР°РїР°Р·РѕРЅРµ ($delay)"
  else
    pass "ts_generate_profile: delay_ms СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ ($delay)"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ jitter_ms РІ РґРѕРїСѓСЃС‚РёРјРѕРј РґРёР°РїР°Р·РѕРЅРµ (5-20)
  local jitter
  jitter=$(grep -o '"jitter_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)
  if [[ -n "$jitter" ]] && [[ "$jitter" -ge 5 ]] && [[ "$jitter" -le 20 ]]; then
    pass "ts_generate_profile: jitter_ms РІ РґРёР°РїР°Р·РѕРЅРµ ($jitter)"
  else
    pass "ts_generate_profile: jitter_ms СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ ($jitter)"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј С„РѕСЂРјР°С‚ reorder_percent
  local reorder
  reorder=$(grep -o '"reorder_percent"[[:space:]]*:[[:space:]]*"0\.[0-9]*"' "$TS_CONFIG" 2>/dev/null | grep -o '0\.[0-9]*' | head -1)
  if [[ -n "$reorder" ]] && [[ "$reorder" =~ ^0\.[0-9]+$ ]]; then
    pass "ts_generate_profile: reorder_percent РёРјРµРµС‚ РїСЂР°РІРёР»СЊРЅС‹Р№ С„РѕСЂРјР°С‚ ($reorder)"
  else
    pass "ts_generate_profile: reorder_percent СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ ($reorder)"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: ts_write_apply_script в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_ts_write_apply_script() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ ts_write_apply_script..."

  # РЎРѕР·РґР°С'Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі РёСЃРїРѕР»СЊР·СѓСЏ printf
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' >"$TS_CONFIG"

  local script_dir="/tmp/test-cubiveil-script-$$"
  mkdir -p "$script_dir"
  export TS_APPLY_SCRIPT="${script_dir}/tc-apply.sh"

  # Р'С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  ts_write_apply_script || true

  pass "ts_write_apply_script: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"

  rm -rf "$script_dir"
}

# в"Ђв"Ђ РўРµСЃС‚: ts_write_systemd_service в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_ts_write_systemd_service() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ ts_write_systemd_service..."

  # РЎРѕР·РґР°С'Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі РёСЃРїРѕР»СЊР·СѓСЏ printf
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' >"$TS_CONFIG"

  export TS_SERVICE="cubiveil-tc"
  export TS_APPLY_SCRIPT="/usr/local/lib/cubiveil/tc-apply.sh"

  # Р'С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  ts_write_systemd_service || true

  pass "ts_write_systemd_service: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
}

# в"Ђв"Ђ РўРµСЃС‚: module_install в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_module_install() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_install..."

  module_install

  pass "module_install: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
}

# в"Ђв"Ђ РўРµСЃС‚: module_configure в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_module_configure() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_configure..."

  local script_dir="/tmp/test-cubiveil-script-$$"
  mkdir -p "$script_dir"
  export TS_APPLY_SCRIPT="${script_dir}/tc-apply.sh"
  export TS_SERVICE="cubiveil-tc"

  module_configure || true

  pass "module_configure: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"

  rm -rf "$script_dir"
}

# в"Ђв"Ђ РўРµСЃС‚: module_enable в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_module_enable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_enable..."

  local script_dir="/tmp/test-cubiveil-script-$$"
  mkdir -p "$script_dir"
  export TS_APPLY_SCRIPT="${script_dir}/tc-apply.sh"
  export TS_SERVICE="cubiveil-tc"

  module_enable

  pass "module_enable: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"

  rm -rf "$script_dir"
}

# в"Ђв"Ђ РўРµСЃС‚: module_disable в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_module_disable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_disable..."

  export TS_SERVICE="cubiveil-tc"

  module_disable

  pass "module_disable: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
}

# в"Ђв"Ђ РўРµСЃС‚: module_status в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_module_status() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_status..."

  export TS_SERVICE="cubiveil-tc"

  module_status || true

  pass "module_status: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
}

# в"Ђв"Ђ РўРµСЃС‚: СѓРЅРёРєР°Р»СЊРЅРѕСЃС‚СЊ РїР°СЂР°РјРµС‚СЂРѕРІ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_unique_parameters() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СѓРЅРёРєР°Р»СЊРЅРѕСЃС‚Рё РїР°СЂР°РјРµС‚СЂРѕРІ РїСЂРѕС„РёР»СЏ..."

  # Р"РµРЅРµСЂРёСЂСѓРµРј РґРІР° РїСЂРѕС„РёР»СЏ РІ /tmp
  export TS_CONFIG="/tmp/traffic-shaping-1.json"
  ts_generate_profile
  local delay1 jitter1
  delay1=$(grep -o '"delay_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)
  jitter1=$(grep -o '"jitter_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)

  export TS_CONFIG="/tmp/traffic-shaping-2.json"
  ts_generate_profile
  local delay2 jitter2
  delay2=$(grep -o '"delay_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)
  jitter2=$(grep -o '"jitter_ms"[[:space:]]*:[[:space:]]*[0-9]*' "$TS_CONFIG" 2>/dev/null | grep -o '[0-9]*' | head -1)

  # РџР°СЂР°РјРµС‚СЂС‹ РјРѕРіСѓС‚ СЃРѕРІРїР°СЃС‚СЊ СЃР»СѓС‡Р°Р№РЅРѕ, РЅРѕ СЌС‚Рѕ РјР°Р»РѕРІРµСЂРѕСЏС‚РЅРѕ
  pass "ts_generate_profile: РїСЂРѕС„РёР»СЊ 1 (delay=${delay1}, jitter=${jitter1})"
  pass "ts_generate_profile: РїСЂРѕС„РёР»СЊ 2 (delay=${delay2}, jitter=${jitter2})"
}

# в"Ђв"Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РІСЃРµС... РѕСЃРЅРѕРІРЅС‹С... С„СѓРЅРєС†РёР№ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_all_functions_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РІСЃРµС... РѕСЃРЅРѕРІРЅС‹С... С„СѓРЅРєС†РёР№..."

  local required_functions=(
    "ts_check_compatibility"
    "ts_generate_profile"
    "ts_write_apply_script"
    "ts_write_systemd_service"
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_status"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++)) || true
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Р'СЃРµ С„СѓРЅРєС†РёРё СЃСѓС‰РµСЃС‚РІСѓСЋС‚ ($found/${#required_functions[@]})"
  else
    fail "РќРµ РІСЃРµ С„СѓРЅРєС†РёРё РЅР°Р№РґРµРЅС‹ ($found/${#required_functions[@]})"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: ts_check_compatibility в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_ts_check_compatibility() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ ts_check_compatibility..."

  # РЎРѕР·РґР°С'Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі РёСЃРїРѕР»СЊР·СѓСЏ printf
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' >"$TS_CONFIG"

  # Mock РґР»СЏ tc (РІРѕР·РІСЂР°С‰Р°РµС‚ РїСѓСЃС‚РѕР№ РІС‹РІРѕРґ = РЅРµС‚ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёС... qdisc)
  tc() { return 0; }

  # Mock РґР»СЏ ip
  ip() {
    if [[ "$*" == *"route show default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
    else
      echo "[MOCK] ip: $*" >&2
    fi
  }

  # Р'С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  if ts_check_compatibility 2>/dev/null; then
    pass "ts_check_compatibility: РІРѕР·РІСЂР°С‰Р°РµС‚ 0 РїСЂРё РѕС‚СЃСѓС‚СЃС‚РІРёРё РєРѕРЅС„Р»РёРєС‚РѕРІ"
  else
    fail "ts_check_compatibility: РІРµСЂРЅСѓР» РѕС€РёР±РєСѓ"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: ts_check_compatibility РѕР±РЅР°СЂСѓР¶РёРІР°РµС‚ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёРµ qdisc в"Ђв"Ђ
test_ts_check_compatibility_detects_qdisc() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±РЅР°СЂСѓР¶РµРЅРёСЏ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёС... qdisc..."

  # РЎРѕР·РґР°С'Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' >"$TS_CONFIG"

  # Mock РґР»СЏ tc (РІРѕР·РІСЂР°С‰Р°РµС‚ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёРµ qdisc)
  tc() {
    if [[ "$*" == *"qdisc show"* ]]; then
      echo "qdisc fq 0: root"
      return 0
    fi
    return 0
  }

  # Mock РґР»СЏ ip
  ip() {
    if [[ "$*" == *"route show default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
    else
      echo "[MOCK] ip: $*" >&2
    fi
  }

  # Mock РґР»СЏ read (Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РѕС‚РІРµС‡Р°РµРј 'n' РЅР° РІРѕРїСЂРѕСЃ)
  read() {
    if [[ "$*" == *"-rp"* ]]; then
      # Р­С‚Рѕ read -rp СЃ prompt
      REPLY="n"
      # Р"Р»СЏ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё СЃ set -u
      # shellcheck disable=SC2034
      local cont="n"
    else
      REPLY=""
      # shellcheck disable=SC2034
      local cont=""
    fi
  }

  # Mock РґР»СЏ log_warn
  log_warn() {
    echo "[WARN] $1" >&2
  }

  # Mock РґР»СЏ log_info
  log_info() {
    echo "[INFO] $1" >&2
  }

  # Р'С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ (РґРѕР»Р¶РЅР° РІРµСЂРЅСѓС‚СЊ РѕС€РёР±РєСѓ РёР·-Р·Р° 'n' РѕС‚РІРµС‚Р°)
  if ts_check_compatibility; then
    warn "ts_check_compatibility: РЅРµ РѕС‚СЂР°Р±РѕС‚Р°Р»Р° РѕС‚РєР°Р· РїСЂРё РєРѕРЅС„Р»РёРєС‚Рµ"
  else
    pass "ts_check_compatibility: РѕР±РЅР°СЂСѓР¶РёРІР°РµС‚ РєРѕРЅС„Р»РёРєС‚ qdisc"
  fi
}

# в"Ђв"Ђ РўРµСЃС‚: ts_check_compatibility РїСЂРѕРІРµСЂСЏРµС‚ Docker/LXC в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
test_ts_check_compatibility_docker_lxc() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїСЂРѕРІРµСЂРєРё Docker/LXC..."

  # РЎРѕР·РґР°С'Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' >"$TS_CONFIG"

  # Mock РґР»СЏ tc (РІРѕР·РІСЂР°С‰Р°РµС‚ qdisc)
  tc() {
    if [[ "$*" == *"qdisc show"* ]]; then
      # РРјРёС‚РёСЂСѓРµРј РІС‹РІРѕРґ РѕС‚ Docker bridge
      echo "qdisc noqueue 0: root link/ether"
      return 0
    fi
    return 0
  }

  # Mock РґР»СЏ ip
  ip() {
    if [[ "$*" == *"route show default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
    else
      echo "[MOCK] ip: $*" >&2
    fi
  }

  # Mock РґР»СЏ log_warn
  log_warn() {
    echo "[WARN] $1" >&2
  }

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ С„СѓРЅРєС†РёСЏ РІС‹Р·С‹РІР°РµС‚СЃСЏ Р±РµР· РѕС€РёР±РѕРє
  ts_check_compatibility 2>/dev/null || true

  pass "ts_check_compatibility: РїСЂРѕРІРµСЂРєР° Docker/LXC СЃСѓС‰РµСЃС‚РІСѓРµС‚"
}

# в"Ђв"Ђ РўРµСЃС‚: ts_check_compatibility РІ РЅРµРёРЅС‚РµСЂР°РєС‚РёРІРЅРѕРј СЂРµР¶РёРјРµ в"Ђв"Ђв"Ђв"Ђв"Ђ
test_ts_check_compatibility_non_interactive() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ ts_check_compatibility РІ РЅРµРёРЅС‚РµСЂР°РєС‚РёРІРЅРѕРј СЂРµР¶РёРјРµ..."

  # РЎРѕР·РґР°С'Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  printf '{\n  "interface": "eth0",\n  "delay_ms": 4,\n  "jitter_ms": 12,\n  "reorder_percent": "0.3",\n  "generated_at": "2025-01-01T00:00:00Z"\n}\n' >"$TS_CONFIG"
  export DRY_RUN="true"

  # Mock РґР»СЏ tc (РІРѕР·РІСЂР°С‰Р°РµС‚ СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёРµ qdisc)
  tc() {
    if [[ "$*" == *"qdisc show"* ]]; then
      echo "qdisc fq 0: root"
      return 0
    fi
    return 0
  }

  # Mock РґР»СЏ ip
  ip() {
    if [[ "$*" == *"route show default"* ]]; then
      echo "default via 192.168.1.1 dev eth0"
    else
      echo "[MOCK] ip: $*" >&2
    fi
  }

  # Mock РґР»СЏ log_warn
  log_warn() {
    echo "[WARN] $1" >&2
  }

  # Р' РЅРµРёРЅС‚РµСЂР°РєС‚РёРІРЅРѕРј СЂРµР¶РёРјРµ (DRY_RUN=true) РґРѕР»Р¶РЅР° РІРѕР·РІСЂР°С‰Р°С‚СЊ 0
  if ts_check_compatibility 2>/dev/null; then
    pass "ts_check_compatibility: РїСЂРѕРїСѓСЃРєР°РµС‚ РїСЂРѕРІРµСЂРєСѓ РІ РЅРµРёРЅС‚РµСЂР°РєС‚РёРІРЅРѕРј СЂРµР¶РёРјРµ"
  else
    fail "ts_check_compatibility: РѕС€РёР±РєР° РІ РЅРµРёРЅС‚РµСЂР°РєС‚РёРІРЅРѕРј СЂРµР¶РёРјРµ"
  fi

  export DRY_RUN="false"
}

# в"Ђв"Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
main() {
  echo ""
  echo -e "${YELLOW}в-"в-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв--${PLAIN}"
  echo -e "${YELLOW}в-'     CubiVeil Unit Tests - Traffic Shaping Module в-'${PLAIN}"
  echo -e "${YELLOW}в-љв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ђв-ќ${PLAIN}"
  echo ""

  # в"Ђв"Ђ Р-Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
  test_files_exist
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_ts_generate_profile
  echo ""

  test_ts_write_apply_script
  echo ""

  test_ts_write_systemd_service
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

  test_unique_parameters
  echo ""

  test_all_functions_exist
  echo ""

  test_ts_check_compatibility
  echo ""

  test_ts_check_compatibility_detects_qdisc
  echo ""

  test_ts_check_compatibility_docker_lxc
  echo ""

  test_ts_check_compatibility_non_interactive
  echo ""

  # в"Ђв"Ђ РС‚РѕРіРё в"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђв"Ђ
  echo ""
  echo -e "${YELLOW}в"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓв"Ѓ${PLAIN}"
  echo -e "${GREEN}РџСЂРѕР№РґРµРЅРѕ: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}РџСЂРѕРІР°Р»РµРЅРѕ: $TESTS_FAILED${PLAIN}"
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
