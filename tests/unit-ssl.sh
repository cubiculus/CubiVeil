#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - SSL Module                  в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ lib/modules/ssl/install.sh           в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

# Strict mode РѕС‚РєР»СЋС‡РµРЅ РґР»СЏ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё СЃ mock-С„СѓРЅРєС†РёСЏРјРё

# в”Ђв”Ђ РЎС‡С‘С‚С‡РёРєРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
TESTS_PASSED=0
TESTS_FAILED=0

# в”Ђв”Ђ Р¦РІРµС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# в”Ђв”Ђ Р¤СѓРЅРєС†РёРё РІС‹РІРѕРґР° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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

# в”Ђв”Ђ РџСѓС‚СЊ Рє РїСЂРѕРµРєС‚Сѓ Рё РјРѕРґСѓР»СЋ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_PATH="${PROJECT_ROOT}/lib/modules/ssl/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "РћС€РёР±РєР°: SSL module РЅРµ РЅР°Р№РґРµРЅ: $MODULE_PATH" >&2
  exit 1
fi

# в”Ђв”Ђ РњРѕРєРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_info() { echo "[INFO] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }

cmd_check() { return 1; }
pkg_install_packages() {
  echo "[MOCK] pkg_install_packages: $*" >&2
  return 0
}
svc_restart_if_active() {
  echo "[MOCK] svc_restart_if_active: $1" >&2
  return 0
}
systemctl() {
  echo "[MOCK] systemctl: $*" >&2
  return 0
}

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# shellcheck source=lib/modules/ssl/install.sh
source "$MODULE_PATH"

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° РјРѕРґСѓР»СЏ..."
  if [[ -f "$MODULE_PATH" ]]; then
    pass "SSL module: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
  else
    fail "SSL module: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР°..."
  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "SSL module: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
  else
    fail "SSL module: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: shebang в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang..."
  local shebang
  shebang=$(head -1 "$MODULE_PATH")
  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "SSL module: РєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang"
  else
    fail "SSL module: РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang: $shebang"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: ssl_generate_self_signed в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_ssl_generate_self_signed() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ ssl_generate_self_signed..."

  local tmp_dir
  tmp_dir="/tmp/ssl-selfsigned-test-$$"
  export SSL_SELFIGNED_DIR="$tmp_dir"
  export DOMAIN="test.local"

  rm -rf "$tmp_dir" && mkdir -p "$tmp_dir"
  if ! ssl_generate_self_signed; then
    fail "ssl_generate_self_signed РІРµСЂРЅСѓР» РѕС€РёР±РєСѓ"
    return
  fi

  local expected_files=("key.pem" "cert.pem" "fullchain.pem")
  for f in "${expected_files[@]}"; do
    if [[ ! -f "$tmp_dir/$f" ]]; then
      fail "ssl_generate_self_signed: РЅРµ СЃРѕР·РґР°Р» $f"
      return
    fi
  done

  pass "ssl_generate_self_signed СЃРѕР·РґР°Р» СЃР°РјРѕРїРѕРґРїРёСЃР°РЅРЅС‹Рµ СЃРµСЂС‚РёС„РёРєР°С‚С‹"
  rm -rf "$tmp_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: ssl_enable РІ dev СЂРµР¶РёРјРµ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_ssl_enable_dev_mode() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ ssl_enable РІ dev СЂРµР¶РёРјРµ..."

  local tmp_dir
  tmp_dir="/tmp/ssl-dev-mode-test-$$"
  export SSL_SELFIGNED_DIR="$tmp_dir"
  export DEV_MODE="true"

  rm -rf "$tmp_dir" && mkdir -p "$tmp_dir"
  touch "$tmp_dir/cert.pem"

  local called=0
  svc_restart_if_active() {
    called=1
    echo "[MOCK] svc_restart_if_active: $1" >&2
    return 0
  }

  if ! ssl_enable; then
    fail "ssl_enable РІРµСЂРЅСѓР» РѕС€РёР±РєСѓ РІ dev СЂРµР¶РёРјРµ"
    rm -rf "$tmp_dir"
    return
  fi

  if [[ "$called" -eq 1 ]]; then
    pass "ssl_enable РІ dev СЂРµР¶РёРјРµ РїРµСЂРµР·Р°РїСѓСЃРєР°РµС‚ СЃРµСЂРІРёСЃС‹"
  else
    fail "ssl_enable РІ dev СЂРµР¶РёРјРµ РЅРµ РІС‹Р·РІР°Р» svc_restart_if_active"
  fi

  rm -rf "$tmp_dir"
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅРѕР№ Р·Р°РїСѓСЃРє в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  test_file_exists
  test_syntax
  test_shebang
  test_ssl_generate_self_signed
  test_ssl_enable_dev_mode

  echo ""
  echo "в”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓ"
  echo "РџСЂРѕР№РґРµРЅРѕ: $TESTS_PASSED"
  echo "РџСЂРѕРІР°Р»РµРЅРѕ: $TESTS_FAILED"
  echo "в”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓ"

  if [[ "$TESTS_FAILED" -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

main "$@"
