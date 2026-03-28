#!/bin/bash
# в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘      CubiVeil Unit Tests - install.sh modes               в•‘
# в•‘      РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЂРµР¶РёРјРѕРІ --dev Рё --dry-run              в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџСѓС‚СЊ Рє РїСЂРѕРµРєС‚Сѓ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# в”Ђв”Ђ РЎС‡С‘С‚С‡РёРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
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

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° РјРѕРґСѓР»РµР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
source "${SCRIPT_DIR}/lib/output.sh" 2>/dev/null || true

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р» install.sh СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_install_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° install.sh..."

  if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
    pass "install.sh: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
  else
    fail "install.sh: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ install.sh в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_install_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР° install.sh..."

  if bash -n "${SCRIPT_DIR}/install.sh" 2>/dev/null; then
    pass "install.sh: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
  else
    fail "install.sh: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїРµСЂРµРјРµРЅРЅР°СЏ DEV_MODE РѕРїСЂРµРґРµР»РµРЅР° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dev_mode_variable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїРµСЂРµРјРµРЅРЅРѕР№ DEV_MODE..."

  if grep -q 'DEV_MODE=' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РїРµСЂРµРјРµРЅРЅР°СЏ DEV_MODE РѕРїСЂРµРґРµР»РµРЅР°"
  else
    fail "install.sh: РїРµСЂРµРјРµРЅРЅР°СЏ DEV_MODE РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїРµСЂРµРјРµРЅРЅР°СЏ DRY_RUN РѕРїСЂРµРґРµР»РµРЅР° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dry_run_variable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїРµСЂРµРјРµРЅРЅРѕР№ DRY_RUN..."

  if grep -q 'DRY_RUN=' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РїРµСЂРµРјРµРЅРЅР°СЏ DRY_RUN РѕРїСЂРµРґРµР»РµРЅР°"
  else
    fail "install.sh: РїРµСЂРµРјРµРЅРЅР°СЏ DRY_RUN РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Р°СЂРіСѓРјРµРЅС‚ --dev РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dev_argument() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±СЂР°Р±РѕС‚РєРё Р°СЂРіСѓРјРµРЅС‚Р° --dev..."

  if grep -q '\-\-dev)' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: Р°СЂРіСѓРјРµРЅС‚ --dev РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  else
    fail "install.sh: Р°СЂРіСѓРјРµРЅС‚ --dev РЅРµ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: Р°СЂРіСѓРјРµРЅС‚ --dry-run РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dry_run_argument() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±СЂР°Р±РѕС‚РєРё Р°СЂРіСѓРјРµРЅС‚Р° --dry-run..."

  if grep -q '\-\-dry-run)' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: Р°СЂРіСѓРјРµРЅС‚ --dry-run РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  else
    fail "install.sh: Р°СЂРіСѓРјРµРЅС‚ --dry-run РЅРµ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: usage СЃРѕРґРµСЂР¶РёС‚ --dev в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_usage_has_dev() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ usage: РЅР°Р»РёС‡РёРµ --dev..."

  if grep -q '\-\-dev' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: usage СЃРѕРґРµСЂР¶РёС‚ --dev"
  else
    fail "install.sh: usage РЅРµ СЃРѕРґРµСЂР¶РёС‚ --dev"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: usage СЃРѕРґРµСЂР¶РёС‚ --dry-run в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_usage_has_dry_run() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ usage: РЅР°Р»РёС‡РёРµ --dry-run..."

  if grep -q '\-\-dry-run' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: usage СЃРѕРґРµСЂР¶РёС‚ --dry-run"
  else
    fail "install.sh: usage РЅРµ СЃРѕРґРµСЂР¶РёС‚ --dry-run"
  fi
}

# ── Тест: usage содержит примеры ───────────────────────────────────────────────
test_usage_has_examples() {
  info "Тестирование usage: наличие примеров..."

  local examples_count
  examples_count=$(grep -c 'Examples:' "${SCRIPT_DIR}/install.sh" 2>/dev/null || echo "0")
  examples_count="${examples_count%%[^0-9]*}"  # Удаляем все нецифровые символы

  if [[ "$examples_count" -ge 1 ]]; then
    pass "install.sh: usage содержит примеры"
  else
    fail "install.sh: usage не содержит примеры"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: dry-run СЂРµР¶РёРј РїРѕРєР°Р·С‹РІР°РµС‚ РїР»Р°РЅ СѓСЃС‚Р°РЅРѕРІРєРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dry_run_shows_plan() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ dry-run: РїР»Р°РЅ СѓСЃС‚Р°РЅРѕРІРєРё..."

  if grep -q 'Installation Plan' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'РџР»Р°РЅ СѓСЃС‚Р°РЅРѕРІРєРё' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: dry-run РїРѕРєР°Р·С‹РІР°РµС‚ РїР»Р°РЅ СѓСЃС‚Р°РЅРѕРІРєРё"
  else
    fail "install.sh: dry-run РЅРµ РїРѕРєР°Р·С‹РІР°РµС‚ РїР»Р°РЅ СѓСЃС‚Р°РЅРѕРІРєРё"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: dry-run РїСЂРѕРІРµСЂСЏРµС‚ root в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dry_run_checks_root() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ dry-run: РїСЂРѕРІРµСЂРєР° root..."

  if grep -q 'EUID' "${SCRIPT_DIR}/install.sh" &&
    grep -q 'Root access' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: dry-run РїСЂРѕРІРµСЂСЏРµС‚ root РґРѕСЃС‚СѓРї"
  else
    fail "install.sh: dry-run РЅРµ РїСЂРѕРІРµСЂСЏРµС‚ root РґРѕСЃС‚СѓРї"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: dry-run РїСЂРѕРІРµСЂСЏРµС‚ Ubuntu в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dry_run_checks_ubuntu() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ dry-run: РїСЂРѕРІРµСЂРєР° Ubuntu..."

  if grep -q 'ubuntu' "${SCRIPT_DIR}/install.sh" &&
    grep -q 'Ubuntu detected' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: dry-run РїСЂРѕРІРµСЂСЏРµС‚ Ubuntu"
  else
    fail "install.sh: dry-run РЅРµ РїСЂРѕРІРµСЂСЏРµС‚ Ubuntu"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: dev СЂРµР¶РёРј РїРѕРєР°Р·С‹РІР°РµС‚ РїСЂРµРґСѓРїСЂРµР¶РґРµРЅРёРµ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dev_mode_warning() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ dev-СЂРµР¶РёРј: РїСЂРµРґСѓРїСЂРµР¶РґРµРЅРёРµ..."

  if grep -q 'DEV MODE' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: dev-СЂРµР¶РёРј РїРѕРєР°Р·С‹РІР°РµС‚ РїСЂРµРґСѓРїСЂРµР¶РґРµРЅРёРµ"
  else
    fail "install.sh: dev-СЂРµР¶РёРј РЅРµ РїРѕРєР°Р·С‹РІР°РµС‚ РїСЂРµРґСѓРїСЂРµР¶РґРµРЅРёРµ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: dry-run РїРѕРєР°Р·С‹РІР°РµС‚ СЃРѕРѕР±С‰РµРЅРёРµ Рѕ СЃРёРјСѓР»СЏС†РёРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dry_run_simulation_message() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ dry-run: СЃРѕРѕР±С‰РµРЅРёРµ Рѕ СЃРёРјСѓР»СЏС†РёРё..."

  if grep -q 'Simulation mode' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'Р РµР¶РёРј СЃРёРјСѓР»СЏС†РёРё' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: dry-run РїРѕРєР°Р·С‹РІР°РµС‚ СЃРѕРѕР±С‰РµРЅРёРµ Рѕ СЃРёРјСѓР»СЏС†РёРё"
  else
    fail "install.sh: dry-run РЅРµ РїРѕРєР°Р·С‹РІР°РµС‚ СЃРѕРѕР±С‰РµРЅРёРµ Рѕ СЃРёРјСѓР»СЏС†РёРё"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: dry-run РЅРµ РІРЅРѕСЃРёС‚ РёР·РјРµРЅРµРЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dry_run_no_changes() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ dry-run: РѕС‚СЃСѓС‚СЃС‚РІРёРµ РёР·РјРµРЅРµРЅРёР№..."

  if grep -q 'No changes' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'РёР·РјРµРЅРµРЅРёСЏ РЅРµ Р±СѓРґСѓС‚' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: dry-run СѓРєР°Р·С‹РІР°РµС‚ РЅР° РѕС‚СЃСѓС‚СЃС‚РІРёРµ РёР·РјРµРЅРµРЅРёР№"
  else
    fail "install.sh: dry-run РЅРµ СѓРєР°Р·С‹РІР°РµС‚ РЅР° РѕС‚СЃСѓС‚СЃС‚РІРёРµ РёР·РјРµРЅРµРЅРёР№"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: parse_args С„СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_parse_args_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё parse_args..."

  if grep -q 'parse_args()' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: С„СѓРЅРєС†РёСЏ parse_args СЃСѓС‰РµСЃС‚РІСѓРµС‚"
  else
    fail "install.sh: С„СѓРЅРєС†РёСЏ parse_args РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: usage С„СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_usage_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё usage..."

  if grep -q 'usage()' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: С„СѓРЅРєС†РёСЏ usage СЃСѓС‰РµСЃС‚РІСѓРµС‚"
  else
    fail "install.sh: С„СѓРЅРєС†РёСЏ usage РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: --help РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_help_argument() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±СЂР°Р±РѕС‚РєРё --help..."

  if grep -q '\-\-help' "${SCRIPT_DIR}/install.sh" &&
    grep -q 'usage' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: --help РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  else
    fail "install.sh: --help РЅРµ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: DEV_DOMAIN РїРµСЂРµРјРµРЅРЅР°СЏ РѕРїСЂРµРґРµР»РµРЅР° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_dev_domain_variable() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїРµСЂРµРјРµРЅРЅРѕР№ DEV_DOMAIN..."

  if grep -q 'DEV_DOMAIN=' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: РїРµСЂРµРјРµРЅРЅР°СЏ DEV_DOMAIN РѕРїСЂРµРґРµР»РµРЅР°"
  else
    fail "install.sh: РїРµСЂРµРјРµРЅРЅР°СЏ DEV_DOMAIN РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: dev.cubiveil.local РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_default_dev_domain() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РґРѕРјРµРЅР° РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ РґР»СЏ dev..."

  if grep -q 'dev.cubiveil.local' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: dev.cubiveil.local РёСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ"
  else
    fail "install.sh: dev.cubiveil.local РЅРµ РЅР°Р№РґРµРЅРѕ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: --domain Р°СЂРіСѓРјРµРЅС‚ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_domain_argument() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±СЂР°Р±РѕС‚РєРё --domain..."

  if grep -q '\-\-domain=' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: --domain РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  else
    fail "install.sh: --domain РЅРµ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  fi
}

# ── Тест: prompt_inputs проверяет DEV_MODE ─────────────────────────────────
test_prompt_inputs_checks_dev_mode() {
  info "Тестирование prompt_inputs: проверка DEV_MODE..."

  if grep -q 'DEV_MODE.*true' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE:-false' "${SCRIPT_DIR}/install.sh"; then
    pass "prompt_inputs: проверяет DEV_MODE"
  else
    fail "prompt_inputs: не проверяет DEV_MODE"
  fi
}

# ── Тест: prompt_inputs пропускает ввод в dev-режиме ─────────────────────────
test_prompt_inputs_skips_in_dev_mode() {
  info "Тестирование prompt_inputs: пропуск ввода в dev-режиме..."

  if grep -q 'return 0' "${SCRIPT_DIR}/install.sh" &&
    grep -q 'DEV-режим\|DEV mode' "${SCRIPT_DIR}/install.sh"; then
    pass "prompt_inputs: пропускает ввод в dev-режиме"
  else
    fail "prompt_inputs: не пропускает ввод в dev-режиме"
  fi
}

# в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo "  CubiVeil Unit Tests - install.sh modes"
  echo "  РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЂРµР¶РёРјРѕРІ --dev Рё --dry-run"
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo ""

  # Р‘Р°Р·РѕРІС‹Рµ С‚РµСЃС‚С‹
  test_install_file_exists
  test_install_syntax

  # РўРµСЃС‚С‹ РїРµСЂРµРјРµРЅРЅС‹С…
  test_dev_mode_variable
  test_dry_run_variable
  test_dev_domain_variable

  # РўРµСЃС‚С‹ Р°СЂРіСѓРјРµРЅС‚РѕРІ
  test_dev_argument
  test_dry_run_argument
  test_domain_argument
  test_help_argument

  # РўРµСЃС‚С‹ usage
  test_usage_exists
  test_usage_has_dev
  test_usage_has_dry_run
  test_usage_has_examples

  # РўРµСЃС‚С‹ dry-run
  test_dry_run_shows_plan
  test_dry_run_checks_root
  test_dry_run_checks_ubuntu
  test_dry_run_simulation_message
  test_dry_run_no_changes

  # РўРµСЃС‚С‹ dev-СЂРµР¶РёРјР°
  test_dev_mode_warning
  test_default_dev_domain

  # Тесты функций
  test_parse_args_exists
  test_prompt_inputs_checks_dev_mode
  test_prompt_inputs_skips_in_dev_mode

  # ── Итоги ──────────────────────────────────────────────────────────────────
  echo ""
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo "  Р РµР·СѓР»СЊС‚Р°С‚С‹ / Results"
  echo "в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ"
  echo ""
  echo -e "  РџСЂРѕР№РґРµРЅРѕ ${GREEN}(${TESTS_PASSED})${PLAIN}"
  echo -e "  РџСЂРѕРІР°Р»РµРЅРѕ ${RED}(${TESTS_FAILED})${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}  РўРµСЃС‚С‹ РЅРµ РїСЂРѕР№РґРµРЅС‹${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}  Р’СЃРµ С‚РµСЃС‚С‹ РїСЂРѕР№РґРµРЅС‹ вњ“${PLAIN}"
    exit 0
  fi
}

main "$@"
