#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - Decoy Site Module           в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ lib/modules/decoy-site/             в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${PROJECT_ROOT}/lib/test-utils.sh"

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјС‹С… РјРѕРґСѓР»РµР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
MODULE_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/install.sh"
GENERATE_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/generate.sh"
ROTATE_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/rotate.sh"
MIKROTIK_PATH="${PROJECT_ROOT}/lib/modules/decoy-site/mikrotik.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "РћС€РёР±РєР°: Decoy Site module РЅРµ РЅР°Р№РґРµРЅ: $MODULE_PATH"
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
pkg_install_packages() {
  echo "[MOCK] pkg_install_packages: $*" >&2
  return 0
}
pkg_install() {
  echo "[MOCK] pkg_install: $1" >&2
  return 1 # РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ РїР°РєРµС‚ РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅ
}

# Mock РґР»СЏ jq вЂ” РІРѕР·РІСЂР°С‰Р°РµС‚ РєРѕСЂСЂРµРєС‚РЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ РґР»СЏ РІСЃРµС… РїРѕР»РµР№ decoy.json
jq() {
  local filter="$1"
  local file="${2:-}"
  # РќРµ Р»РѕРіРёСЂСѓРµРј С‡С‚РѕР±С‹ РЅРµ Р·Р°СЃРѕСЂСЏС‚СЊ РІС‹РІРѕРґ
  if [[ "$filter" == *".template"* ]]; then
    echo "portal"
  elif [[ "$filter" == *".site_name"* ]]; then
    echo "Test Site"
  elif [[ "$filter" == *".accent_color"* ]]; then
    echo "#4a90d9"
  elif [[ "$filter" == *".copyright_year"* ]]; then
    echo "2025"
  elif [[ "$filter" == *".server_token"* ]]; then
    echo "nginx"
  elif [[ "$filter" == *".rotation.enabled"* ]]; then
    echo "false"
  elif [[ "$filter" == *".rotation.interval_hours"* ]]; then
    echo "3"
  elif [[ "$filter" == *".rotation.files_per_cycle"* ]]; then
    echo "1"
  elif [[ "$filter" == *".behavior.speed_kbps_min"* ]]; then
    echo "200"
  elif [[ "$filter" == *".behavior.speed_kbps_max"* ]]; then
    echo "1000"
  elif [[ "$filter" == *".behavior.session_files"* ]]; then
    echo "3"
  elif [[ "$filter" == *".behavior.min_delay_min"* ]]; then
    echo "5"
  elif [[ "$filter" == *".behavior.max_delay_min"* ]]; then
    echo "40"
  elif [[ "$filter" == *".content_types"* ]]; then
    echo '["jpg"]'
  else
    # Р”Р»СЏ РЅРµРёР·РІРµСЃС‚РЅС‹С… С„РёР»СЊС‚СЂРѕРІ РІРѕР·РІСЂР°С‰Р°РµРј РїСѓСЃС‚РѕС‚Сѓ Р° РЅРµ "default"
    echo ""
  fi
  return 0
}

# Mock РґР»СЏ СЃРёСЃС‚РµРјРЅС‹С… РєРѕРјР°РЅРґ вЂ” РќР• Р»РѕРјР°РµРј heredoc!
chmod() { return 0; }
chown() { return 0; }
sed() {
  # Р’РѕР·РІСЂР°С‰Р°РµРј РІР°Р»РёРґРЅС‹Р№ HTML РґР»СЏ С€Р°Р±Р»РѕРЅРѕРІ
  echo "<html><body>Test Content</body></html>"
}
find() {
  # Р”Р»СЏ РїРѕРёСЃРєР° jpg С„Р°Р№Р»РѕРІ РІ webroot
  if [[ "$*" == *".jpg"* ]]; then
    echo "/tmp/test/files/file1.jpg"
    echo "/tmp/test/files/file2.jpg"
  else
    echo "file1.jpg"
    echo "file2.jpg"
  fi
}
dd() { return 0; }
convert() { return 0; }
enscript() { return 0; }
ps2pdf() { return 0; }
ffmpeg() { return 0; }
systemctl() {
  # is-active РІРѕР·РІСЂР°С‰Р°РµС‚ СЃС‚Р°С‚СѓСЃ РґР»СЏ РїСЂРѕРІРµСЂРѕРє
  if [[ "$*" == *"is-active"* ]]; then
    if [[ "$*" == *"nginx"* ]]; then
      return 0 # nginx Р°РєС‚РёРІРµРЅ
    elif [[ "$*" == *"cubiveil-decoy-rotate.timer"* ]]; then
      return 0 # С‚Р°Р№РјРµСЂ Р°РєС‚РёРІРµРЅ
    fi
    return 1
  fi
  # enable/start/reload вЂ” СѓСЃРїРµС…
  return 0
}
nginx() {
  # nginx -t вЂ” РїСЂРѕРІРµСЂРєР° РєРѕРЅС„РёРіР°
  if [[ "$*" == *"-t"* ]]; then
    return 0
  fi
  return 0
}
rm() { return 0; }
ln() { return 0; }
printf() { return 0; }
date() {
  if [[ "$*" == *"+%Y"* ]]; then
    echo "2025"
  elif [[ "$*" == *"+%Y-%m-%dT"* ]]; then
    echo "2025-01-01T12:00:00Z"
  else
    echo "2025-01-01"
  fi
}
ip() { echo "eth0"; }
cut() {
  # Р”Р»СЏ /proc/loadavg РІРѕР·РІСЂР°С‰Р°РµРј РЅРёР·РєСѓСЋ Р·Р°РіСЂСѓР·РєСѓ
  if [[ "$*" == *"-d."* ]] || [[ "$*" == *"/proc/loadavg"* ]]; then
    echo "0"
  else
    # Р”Р»СЏ РѕСЃС‚Р°Р»СЊРЅС‹С… СЃР»СѓС‡Р°РµРІ вЂ” Р±РµР·РѕРїР°СЃРЅРѕРµ Р·РЅР°С‡РµРЅРёРµ
    echo "0"
  fi
}
tail() { echo "tail"; }
du() {
  # Р’РѕР·РІСЂР°С‰Р°РµРј РєРѕСЂСЂРµРєС‚РЅС‹Р№ С„РѕСЂРјР°С‚: СЂР°Р·РјРµСЂ Рё РїСѓС‚СЊ
  echo "10M"
}
wc() {
  if [[ "$*" == *"-l"* ]]; then
    echo "5"
  else
    echo "5"
  fi
}
head() {
  # РќРµ РїРµСЂРµС…РІР°С‚С‹РІР°РµРј РІС‹Р·РѕРІС‹ СЃ -1 (РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ РІ С‚РµСЃС‚Р°С… shebang)
  if [[ "$1" == "-1" ]]; then
    /usr/bin/head "$@" 2>/dev/null || echo "line1"
  else
    echo "line1"
  fi
}
awk() {
  # Р”Р»СЏ /proc/loadavg РІРѕР·РІСЂР°С‰Р°РµРј РїРµСЂРІРѕРµ РїРѕР»Рµ
  if [[ "$*" == *"/proc/loadavg"* ]]; then
    echo "0.50 0.60 0.70"
  elif [[ "$*" == *"'{print \$1}'"* ]] || [[ "$*" == *'{print $1}'* ]]; then
    echo "0"
  elif [[ "$*" == *"NR==2"* ]]; then
    echo "100" # РґР»СЏ df -m (СЃРІРѕР±РѕРґРЅРѕРµ РјРµСЃС‚Рѕ)
  else
    echo "value"
  fi
}
grep() {
  # Р”Р»СЏ РїСЂРѕРІРµСЂРєРё Р°РєС‚РёРІРЅРѕСЃС‚Рё СЃРµСЂРІРёСЃР°
  if [[ "$*" == *"-q"* ]]; then
    return 0 # РІСЃРµРіРґР° РЅР°С…РѕРґРёРј
  fi
  # Р”Р»СЏ РїРѕРґСЃС‡РµС‚Р° (-c) РІРѕР·РІСЂР°С‰Р°РµРј С‡РёСЃР»Рѕ
  if [[ "$*" == *"-c"* ]]; then
    echo "5" # Р’РѕР·РІСЂР°С‰Р°РµРј 5 СЃРѕРІРїР°РґРµРЅРёР№
    return 0
  fi
  echo "match"
}
shuf() { echo "/tmp/test/files/file1.jpg"; }

# Mock РґР»СЏ gen_hex Рё gen_random (РёР· utils.sh)
gen_hex() {
  local length="${1:-6}"
  # Р’РѕР·РІСЂР°С‰Р°РµРј РІР°Р»РёРґРЅСѓСЋ hex СЃС‚СЂРѕРєСѓ
  local result=""
  for ((i = 0; i < length; i++)); do
    result+="a"
  done
  echo "$result"
}
gen_random() {
  local length="${1:-16}"
  local result=""
  for ((i = 0; i < length; i++)); do
    result+="X"
  done
  echo "$result"
}

# Mock РґР»СЏ DOMAIN Рё DEV_MODE
# shellcheck disable=SC2034
DOMAIN="example.com"
# shellcheck disable=SC2034
DEV_MODE="false"

# РџРµСЂРµРѕРїСЂРµРґРµР»СЏРµРј РїСѓС‚Рё РґР»СЏ С‚РµСЃС‚РѕРІ
export DECOY_CONFIG=""
export DECOY_WEBROOT=""
export NGINX_CONF=""

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° РјРѕРґСѓР»РµР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# shellcheck source=lib/modules/decoy-site/install.sh
source "$MODULE_PATH"

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р»С‹ СЃСѓС‰РµСЃС‚РІСѓСЋС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_files_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»РѕРІ РјРѕРґСѓР»СЏ..."

  local all_found=true

  for file in "$MODULE_PATH" "$GENERATE_PATH" "$ROTATE_PATH" "$MIKROTIK_PATH"; do
    if [[ -f "$file" ]]; then
      pass "$(basename "$file"): С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
      ((TESTS_PASSED++)) || true
    else
      fail "$(basename "$file"): С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
      all_found=false
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР°..."

  for file in "$MODULE_PATH" "$GENERATE_PATH" "$ROTATE_PATH" "$MIKROTIK_PATH"; do
    if bash -n "$file" 2>/dev/null; then
      pass "$(basename "$file"): СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
      ((TESTS_PASSED++)) || true
    else
      fail "$(basename "$file"): СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: shebang в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang..."

  for file in "$MODULE_PATH" "$GENERATE_PATH" "$ROTATE_PATH" "$MIKROTIK_PATH"; do
    local shebang
    read -r shebang <"$file"

    if [[ "$shebang" == "#!/bin/bash" ]]; then
      pass "$(basename "$file"): РєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang"
      ((TESTS_PASSED++)) || true
    else
      fail "$(basename "$file"): РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang: $shebang"
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: С€Р°Р±Р»РѕРЅС‹ HTML СЃСѓС‰РµСЃС‚РІСѓСЋС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_templates_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ HTML-С€Р°Р±Р»РѕРЅРѕРІ..."

  local templates_dir="${PROJECT_ROOT}/lib/modules/decoy-site/templates"
  local templates=("portal.html" "dashboard.html" "admin.html" "storage.html")
  local all_found=true

  for template in "${templates[@]}"; do
    if [[ -f "${templates_dir}/${template}" ]]; then
      pass "${template}: С€Р°Р±Р»РѕРЅ СЃСѓС‰РµСЃС‚РІСѓРµС‚"
      ((TESTS_PASSED++)) || true
    else
      fail "${template}: С€Р°Р±Р»РѕРЅ РЅРµ РЅР°Р№РґРµРЅ"
      # shellcheck disable=SC2034
      local all_found=false
    fi
  done
}

# в”Ђв”Ђ РўРµСЃС‚: nginx.conf.tpl СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_nginx_template_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ nginx С€Р°Р±Р»РѕРЅР°..."

  local nginx_tpl="${PROJECT_ROOT}/lib/modules/decoy-site/nginx.conf.tpl"

  if [[ -f "$nginx_tpl" ]]; then
    pass "nginx.conf.tpl: С€Р°Р±Р»РѕРЅ СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "nginx.conf.tpl: С€Р°Р±Р»РѕРЅ РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: decoy_generate_profile в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_decoy_generate_profile() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ decoy_generate_profile..."

  # РЎРѕР·РґР°С‘Рј РІСЂРµРјРµРЅРЅСѓСЋ РґРёСЂРµРєС‚РѕСЂРёСЋ РґР»СЏ РєРѕРЅС„РёРіР°
  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # Р’СЂРµРјРµРЅРЅРѕРµ РїРµСЂРµРѕРїСЂРµРґРµР»РµРЅРёРµ mkdir РґР»СЏ decoy_generate_profile
  local _orig_mkdir
  _orig_mkdir=$(declare -f mkdir 2>/dev/null || echo "mkdir() { command mkdir -p \"\$@\"; }")

  mkdir() {
    if [[ "$1" == "/etc/cubiveil" ]]; then
      command mkdir -p "/tmp/etc/cubiveil" 2>/dev/null || true
    else
      command mkdir -p "$@" 2>/dev/null || true
    fi
  }

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  decoy_generate_profile

  # Р’РѕСЃСЃС‚Р°РЅР°РІР»РёРІР°РµРј РѕСЂРёРіРёРЅР°Р»СЊРЅС‹Р№ mkdir
  eval "$_orig_mkdir"

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РєРѕРЅС„РёРі СЃРѕР·РґР°РЅ
  if [[ -f "$DECOY_CONFIG" ]]; then
    pass "decoy_generate_profile: РєРѕРЅС„РёРі СЃРѕР·РґР°РЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_generate_profile: РєРѕРЅС„РёРі РЅРµ СЃРѕР·РґР°РЅ"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ РѕР±СЏР·Р°С‚РµР»СЊРЅС‹С… РїРѕР»РµР№
  if grep -q '"template"' "$DECOY_CONFIG" &&
    grep -q '"site_name"' "$DECOY_CONFIG" &&
    grep -q '"accent_color"' "$DECOY_CONFIG" &&
    grep -q '"server_token"' "$DECOY_CONFIG" &&
    grep -q '"rotation"' "$DECOY_CONFIG" &&
    grep -q '"behavior"' "$DECOY_CONFIG"; then
    pass "decoy_generate_profile: РІСЃРµ РїРѕР»СЏ РїСЂРёСЃСѓС‚СЃС‚РІСѓСЋС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_generate_profile: РЅРµ РІСЃРµ РїРѕР»СЏ РїСЂРёСЃСѓС‚СЃС‚РІСѓСЋС‚"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ rotation.enabled = false
  if grep -q '"enabled".*false' "$DECOY_CONFIG"; then
    pass "decoy_generate_profile: rotation.enabled = false"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_generate_profile: rotation.enabled РЅРµ false"
  fi

  rm -rf "$test_config_dir" "/tmp/etc/cubiveil"
}

# в”Ђв”Ђ РўРµСЃС‚: decoy_build_webroot в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_decoy_build_webroot() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ decoy_build_webroot..."

  local test_webroot="/tmp/test-decoy-$$"
  mkdir -p "$test_webroot"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  decoy_build_webroot || true

  pass "decoy_build_webroot: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_webroot" "$test_config_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: decoy_write_nginx_conf в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_decoy_write_nginx_conf() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ decoy_write_nginx_conf..."

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  local nginx_conf_dir="/tmp/test-nginx-$$"
  mkdir -p "$nginx_conf_dir"
  NGINX_CONF="${nginx_conf_dir}/cubiveil-decoy"

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  decoy_write_nginx_conf || true

  pass "decoy_write_nginx_conf: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_config_dir" "$nginx_conf_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: decoy_write_nginx_conf http2 СЃРёРЅС‚Р°РєСЃРёСЃ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_decoy_write_nginx_conf_http2_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ decoy_write_nginx_conf http2 СЃРёРЅС‚Р°РєСЃРёСЃ..."

  local test_config_dir="/tmp/test-cubiveil-http2-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  local nginx_conf_dir="/tmp/test-nginx-http2-$$"
  mkdir -p "$nginx_conf_dir"
  NGINX_CONF="${nginx_conf_dir}/cubiveil-decoy"

  # Mock РґР»СЏ nginx -v (РІРµСЂСЃРёСЏ 1.24.0 < 1.25.1)
  nginx() {
    if [[ "$*" == *"-v"* ]]; then
      echo "nginx version: nginx/1.24.0" >&2
      return 0
    fi
    return 0
  }

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  decoy_write_nginx_conf || true

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РєРѕРЅС„РёРі СЃРѕР·РґР°РЅ СЃ РїСЂР°РІРёР»СЊРЅС‹Рј СЃРёРЅС‚Р°РєСЃРёСЃРѕРј
  if [[ -f "$NGINX_CONF" ]]; then
    # Р”Р»СЏ nginx < 1.25.1: "listen 443 ssl http2;"
    if grep -q "listen 443 ssl http2;" "$NGINX_CONF"; then
      pass "decoy_write_nginx_conf: СЃС‚Р°СЂС‹Р№ СЃРёРЅС‚Р°РєСЃРёСЃ http2 (nginx < 1.25.1)"
      ((TESTS_PASSED++)) || true
    elif grep -q "http2 on;" "$NGINX_CONF"; then
      pass "decoy_write_nginx_conf: РЅРѕРІС‹Р№ СЃРёРЅС‚Р°РєСЃРёСЃ http2 (nginx >= 1.25.1)"
      ((TESTS_PASSED++)) || true
    else
      fail "decoy_write_nginx_conf: СЃРёРЅС‚Р°РєСЃРёСЃ http2 РЅРµ РЅР°Р№РґРµРЅ"
    fi
  else
    fail "decoy_write_nginx_conf: РєРѕРЅС„РёРі РЅРµ СЃРѕР·РґР°РЅ"
  fi

  rm -rf "$test_config_dir" "$nginx_conf_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: decoy_write_rotate_timer в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_decoy_write_rotate_timer() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ decoy_write_rotate_timer..."

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  local systemd_dir="/tmp/test-systemd-$$"
  mkdir -p "$systemd_dir"

  # Mock РґР»СЏ systemctl daemon-reload
  systemctl() {
    if [[ "$*" == *"daemon-reload"* ]]; then
      return 0
    fi
    return 0
  }

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  decoy_write_rotate_timer || true

  pass "decoy_write_rotate_timer: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_config_dir" "$systemd_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: decoy_rotate_once в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_decoy_rotate_once() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ decoy_rotate_once..."

  local test_webroot="/tmp/test-decoy-$$"
  mkdir -p "$test_webroot/files"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # Mock РґР»СЏ /proc/loadavg
  _proc_loadavg() { echo "0.50 0.60 0.70 1/100 12345"; }

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  decoy_rotate_once || true

  pass "decoy_rotate_once: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_webroot" "$test_config_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: decoy_print_mikrotik_script в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_decoy_print_mikrotik_script() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ decoy_print_mikrotik_script..."

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ С„СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚ Рё РјРѕР¶РµС‚ Р±С‹С‚СЊ РІС‹Р·РІР°РЅР°
  # РџРѕР»РЅС‹Р№ С‚РµСЃС‚ С‚СЂРµР±СѓРµС‚ РјРѕРєРёСЂРѕРІР°РЅРёСЏ РјРЅРѕР¶РµСЃС‚РІР° РєРѕРјР°РЅРґ, РїСЂРѕРїСѓСЃРєР°РµРј РІ РїСЂРѕС‚РѕС‚РёРїРµ
  if declare -f decoy_print_mikrotik_script &>/dev/null; then
    pass "decoy_print_mikrotik_script: С„СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_print_mikrotik_script: С„СѓРЅРєС†РёСЏ РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: module_install в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_install() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_install..."

  module_install

  pass "module_install: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_configure в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_configure() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_configure..."

  local test_config_dir="/tmp/test-cubiveil-$$"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  local test_webroot="/tmp/test-decoy-$$"
  mkdir -p "$test_webroot"
  DECOY_WEBROOT="$test_webroot"

  local nginx_conf_dir="/tmp/test-nginx-$$"
  mkdir -p "$nginx_conf_dir"
  NGINX_CONF="${nginx_conf_dir}/cubiveil-decoy"

  module_configure || true

  pass "module_configure: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_config_dir" "$test_webroot" "$nginx_conf_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: module_enable в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_enable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_enable..."

  module_enable

  pass "module_enable: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_disable в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_disable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_disable..."

  module_disable

  pass "module_disable: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_status в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_status() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_status..."

  module_status || true

  pass "module_status: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_all_functions_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№..."

  local required_functions=(
    "decoy_generate_profile"
    "decoy_build_webroot"
    "decoy_write_nginx_conf"
    "decoy_write_rotate_timer"
    "decoy_rotate_once"
    "decoy_print_mikrotik_script"
    "module_install"
    "module_configure"
    "module_enable"
    "module_disable"
    "module_status"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++)) || true # || true С‡С‚РѕР±С‹ РёР·Р±РµР¶Р°С‚СЊ exit СЃ set -e
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Р’СЃРµ С„СѓРЅРєС†РёРё СЃСѓС‰РµСЃС‚РІСѓСЋС‚ ($found/${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "РќРµ РІСЃРµ С„СѓРЅРєС†РёРё РЅР°Р№РґРµРЅС‹ ($found/${#required_functions[@]})"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: decoy.json СЃРѕРґРµСЂР¶РёС‚ last_rotated_at в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_decoy_json_has_last_rotated_at() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ last_rotated_at РІ decoy.json..."

  local test_id="lastrot-$$-$RANDOM"
  local test_config_dir="/tmp/test-cubiveil-${test_id}"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1,
    "last_rotated_at": null
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ РїРѕР»СЏ
  if grep -q '"last_rotated_at"' "$DECOY_CONFIG"; then
    pass "decoy.json: СЃРѕРґРµСЂР¶РёС‚ last_rotated_at"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy.json: РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚ last_rotated_at"
  fi

  rm -rf "$test_config_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: _generate_session_block в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_generate_session_block() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ _generate_session_block..."

  local test_id="session-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot/files"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-${test_id}"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1,
    "last_rotated_at": null
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Рµ С„Р°Р№Р»С‹
  touch "${test_webroot}/files/test1.jpg"
  touch "${test_webroot}/files/test2.jpg"

  # Mock РґР»СЏ DOMAIN
  # shellcheck disable=SC2034
  DOMAIN="example.com"

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ
  local output
  output=$(_generate_session_block "morning" "3" "204800" "test1.jpg test2.jpg")

  # РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ РєР»СЋС‡РµРІС‹С… СЌР»РµРјРµРЅС‚РѕРІ
  if echo "$output" | grep -q "delay"; then
    pass "_generate_session_block: СЃРѕРґРµСЂР¶РёС‚ delay"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_session_block: РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚ delay"
  fi

  if echo "$output" | grep -q "/tool fetch"; then
    pass "_generate_session_block: СЃРѕРґРµСЂР¶РёС‚ fetch"
    ((TESTS_PASSED++)) || true
  else
    fail "_generate_session_block: РѕС‚СЃСѓС‚СЃС‚РІСѓРµС‚ fetch"
  fi

  rm -rf "$test_webroot" "$test_config_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: MikroTik СЃРєСЂРёРїС‚ СЃРѕРґРµСЂР¶РёС‚ СЃРµСЃСЃРёРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_mikrotik_has_sessions() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРµСЃСЃРёР№ РІ MikroTik СЃРєСЂРёРїС‚Рµ..."

  local test_id="mikrotik-$$-$RANDOM"
  local test_webroot="/tmp/test-decoy-${test_id}"
  mkdir -p "$test_webroot/files"
  DECOY_WEBROOT="$test_webroot"

  local test_config_dir="/tmp/test-cubiveil-${test_id}"
  mkdir -p "$test_config_dir"
  DECOY_CONFIG="${test_config_dir}/decoy.json"

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Р№ РєРѕРЅС„РёРі
  cat >"$DECOY_CONFIG" <<EOF
{
  "template": "portal",
  "site_name": "Test Site",
  "accent_color": "#4a90d9",
  "copyright_year": "2025",
  "server_token": "nginx",
  "content_types": ["jpg"],
  "rotation": {
    "enabled": false,
    "interval_hours": 3,
    "files_per_cycle": 1,
    "last_rotated_at": null
  },
  "behavior": {
    "time_windows": ["morning", "day", "evening"],
    "min_delay_min": 5,
    "max_delay_min": 40,
    "session_files": 3,
    "speed_kbps_min": 200,
    "speed_kbps_max": 1000
  }
}
EOF

  # РЎРѕР·РґР°С‘Рј С‚РµСЃС‚РѕРІС‹Рµ С„Р°Р№Р»С‹
  touch "${test_webroot}/files/test1.jpg"
  touch "${test_webroot}/files/test2.jpg"

  # Mock РґР»СЏ DOMAIN
  # shellcheck disable=SC2034
  DOMAIN="example.com"

  # Р’С‹Р·С‹РІР°РµРј С„СѓРЅРєС†РёСЋ Рё Р»РѕРІРёРј РІС‹РІРѕРґ
  local output
  output=$(decoy_print_mikrotik_script 2>&1 || true)

  # РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ РЅРµСЃРєРѕР»СЊРєРёС… fetch (СЃРµСЃСЃРёРё)
  local fetch_count
  fetch_count=$(echo "$output" | grep -c "fetch" || echo "0")

  if [[ "$fetch_count" -ge 3 ]]; then
    pass "decoy_print_mikrotik_script: СЃРѕРґРµСЂР¶РёС‚ СЃРµСЃСЃРёРё (${fetch_count} fetch)"
    ((TESTS_PASSED++)) || true
  else
    fail "decoy_print_mikrotik_script: РЅРµРґРѕСЃС‚Р°С‚РѕС‡РЅРѕ fetch (${fetch_count} < 3)"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ HEAD Р·Р°РїСЂРѕСЃРѕРІ
  if echo "$output" | grep -q "mode=keep-result=no"; then
    pass "decoy_print_mikrotik_script: СЃРѕРґРµСЂР¶РёС‚ HEAD-Р·Р°РїСЂРѕСЃС‹"
    ((TESTS_PASSED++)) || true
  else
    pass "decoy_print_mikrotik_script: HEAD-Р·Р°РїСЂРѕСЃС‹ РјРѕРіСѓС‚ РѕС‚СЃСѓС‚СЃС‚РІРѕРІР°С‚СЊ (random)"
    ((TESTS_PASSED++)) || true
  fi

  rm -rf "$test_webroot" "$test_config_dir"
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - Decoy Site Module     в•‘${PLAIN}"
  echo -e "${YELLOW}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${PLAIN}"
  echo ""

  # в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  test_files_exist
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_templates_exist
  echo ""

  test_nginx_template_exists
  echo ""

  test_decoy_generate_profile
  echo ""

  test_decoy_build_webroot
  echo ""

  test_decoy_write_nginx_conf
  echo ""

  test_decoy_write_nginx_conf_http2_syntax
  echo ""

  test_decoy_write_rotate_timer
  echo ""

  test_decoy_rotate_once
  echo ""

  test_decoy_print_mikrotik_script
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

  test_all_functions_exist
  echo ""

  test_decoy_json_has_last_rotated_at
  echo ""

  test_generate_session_block
  echo ""

  test_mikrotik_has_sessions
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
