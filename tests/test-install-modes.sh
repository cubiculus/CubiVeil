#!/bin/bash
# shellcheck disable=SC1071,SC1111,SC2140
# ╔═════════════════════════════════════════════════════════════
# ╓      CubiVeil Unit Tests - install.sh modes               ╓
# ╓      РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЂРµР¶РёРјРѕРІ --dev Рё --dry-run              ╓
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── РџСѓС‚СЊ Рє РїСЂРѕРµРєС‚Сѓ ───────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── РЎС‡С'С‚С‡РёРє С‚РµСЃС‚РѕРІ ───────────────────────────────────────────
TESTS_PASSED=0
TESTS_FAILED=0

# ── Р¦РІРµС‚Р° ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# ── Р¤СѓРЅРєС†РёРё РІС‹РІРѕРґР° ───────────────────────────────────────────
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

# ── Р-Р°РіСЂСѓР·РєР° РјРѕРґСѓР»РµР№ ─────────────────────────────────────────
source "${SCRIPT_DIR}/lib/output.sh" 2>/dev/null || true

# ── РўРµСЃС‚: С„Р°Р№Р» install.sh СЃСѓС‰РµСЃС‚РІСѓРµС‚ ─────────────────────────
test_install_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° install.sh..."

  if [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
    pass "install.sh: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
  else
    fail "install.sh: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# ── РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ install.sh ───────────────────────────────
test_install_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР° install.sh..."

  if bash -n "${SCRIPT_DIR}/install.sh" 2>/dev/null; then
    pass "install.sh: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
  else
    fail "install.sh: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# -- Тест: переменная DEV_MODE определена ---------------------------------
test_dev_mode_variable() {
  info "Тестирование переменной DEV_MODE..."

  if grep -q 'DEV_MODE=' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE=' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: переменная DEV_MODE определена"
  else
    fail "install.sh: переменная DEV_MODE не найдена"
  fi
}

# -- Тест: переменная DRY_RUN определена ----------------------------------
test_dry_run_variable() {
  info "Тестирование переменной DRY_RUN..."

  if grep -q 'DRY_RUN=' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DRY_RUN=' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: переменная DRY_RUN определена"
  else
    fail "install.sh: переменная DRY_RUN не найдена"
  fi
}

# -- Тест: аргумент --dev обрабатывается -----------------------------------
test_dev_argument() {
  info "Тестирование обработки аргумента --dev..."

  if grep -q '\-\-dev)' "${SCRIPT_DIR}/install.sh" ||
    grep -q '\-\-dev)' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: аргумент --dev обрабатывается"
  else
    fail "install.sh: аргумент --dev не обрабатывается"
  fi
}

# -- Тест: аргумент --dry-run обрабатывается -------------------------------
test_dry_run_argument() {
  info "Тестирование обработки аргумента --dry-run..."

  if grep -q '\-\-dry-run)' "${SCRIPT_DIR}/install.sh" ||
    grep -q '\-\-dry-run)' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: аргумент --dry-run обрабатывается"
  else
    fail "install.sh: аргумент --dry-run не обрабатывается"
  fi
}

# ── РўРµСЃС‚: usage СЃРѕРґРµСЂР¶РёС‚ --dev ───────────────────────────────
test_usage_has_dev() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ usage: РЅР°Р»РёС‡РёРµ --dev..."

  if grep -q '\-\-dev' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: usage СЃРѕРґРµСЂР¶РёС‚ --dev"
  else
    fail "install.sh: usage РЅРµ СЃРѕРґРµСЂР¶РёС‚ --dev"
  fi
}

# ── РўРµСЃС‚: usage СЃРѕРґРµСЂР¶РёС‚ --dry-run ───────────────────────────
test_usage_has_dry_run() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ usage: РЅР°Р»РёС‡РёРµ --dry-run..."

  if grep -q '\-\-dry-run' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: usage СЃРѕРґРµСЂР¶РёС‚ --dry-run"
  else
    fail "install.sh: usage РЅРµ СЃРѕРґРµСЂР¶РёС‚ --dry-run"
  fi
}

# -- Тест: usage содержит примеры -----------------------------------------------
test_usage_has_examples() {
  info "Тестирование usage: наличие примеров..."

  local examples_count
  examples_count=$(grep -c 'Examples:' "${SCRIPT_DIR}/install.sh" 2>/dev/null || echo "0")
  examples_count="${examples_count%%[^0-9]*}" # Удаляем все нецифровые символы

  if [[ "$examples_count" -ge 1 ]]; then
    pass "install.sh: usage содержит примеры"
  else
    fail "install.sh: usage не содержит примеры"
  fi
}

# -- Тест: dry-run режим показывает план установки -------------------------
test_dry_run_shows_plan() {
  info "Тестирование dry-run: план установки..."

  if grep -q 'Installation Plan' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'Installation Plan' "${SCRIPT_DIR}/lib/core/installer/ui.sh" ||
    grep -q 'План установки' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'План установки' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run показывает план установки"
  else
    fail "install.sh: dry-run не показывает план установки"
  fi
}

# -- Тест: dry-run проверяет root ------------------------------------------
test_dry_run_checks_root() {
  info "Тестирование dry-run: проверка root..."

  if grep -q 'EUID' "${SCRIPT_DIR}/lib/core/installer/ui.sh" &&
    grep -q 'Root access' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run проверяет root доступ"
  else
    fail "install.sh: dry-run не проверяет root доступ"
  fi
}

# -- Тест: dry-run проверяет Ubuntu ----------------------------------------
test_dry_run_checks_ubuntu() {
  info "Тестирование dry-run: проверка Ubuntu..."

  if grep -q 'ubuntu' "${SCRIPT_DIR}/lib/core/installer/ui.sh" &&
    grep -q 'Ubuntu' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run проверяет Ubuntu"
  else
    fail "install.sh: dry-run не проверяет Ubuntu"
  fi
}

# -- Тест: dev режим показывает предупреждение -----------------------------
test_dev_mode_warning() {
  info "Тестирование dev-режим: предупреждение..."

  if grep -q 'DEV MODE' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV-режим' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE' "${SCRIPT_DIR}/lib/core/installer/cli.sh" ||
    grep -q 'DEV_MODE' "${SCRIPT_DIR}/lib/core/installer/prompt.sh"; then
    pass "install.sh: dev-режим показывает предупреждение"
  else
    fail "install.sh: dev-режим не показывает предупреждение"
  fi
}

# -- Тест: dry-run показывает сообщение о симуляции ------------------------
test_dry_run_simulation_message() {
  info "Тестирование dry-run: сообщение о симуляции..."

  if grep -q 'Simulation' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'Simulation' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run показывает сообщение о симуляции"
  else
    fail "install.sh: dry-run не показывает сообщение о симуляции"
  fi
}

# -- Тест: dry-run не вносит изменения -------------------------------------
test_dry_run_no_changes() {
  info "Тестирование dry-run: отсутствие изменений..."

  if grep -q 'No changes' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'No changes' "${SCRIPT_DIR}/lib/core/installer/ui.sh" ||
    grep -q 'изменения не будут' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'изменения не будут' "${SCRIPT_DIR}/lib/core/installer/ui.sh"; then
    pass "install.sh: dry-run указывает на отсутствие изменений"
  else
    fail "install.sh: dry-run не указывает на отсутствие изменений"
  fi
}

# -- Тест: parse_args функция существует -----------------------------------
test_parse_args_exists() {
  info "Тестирование функции parse_args..."

  if grep -q 'parse_args()' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'parse_args()' "${SCRIPT_DIR}/lib/core/installer/cli.sh" ||
    grep -q 'parse_args() {' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: функция parse_args существует"
  else
    fail "install.sh: функция parse_args не найдена"
  fi
}

# ── РўРµСЃС‚: usage С„СѓРЅРєС†РёСЏ СЃСѓС‰РµСЃС‚РІСѓРµС‚ ───────────────────────────
test_usage_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ С„СѓРЅРєС†РёРё usage..."

  if grep -q 'usage()' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: С„СѓРЅРєС†РёСЏ usage СЃСѓС‰РµСЃС‚РІСѓРµС‚"
  else
    fail "install.sh: С„СѓРЅРєС†РёСЏ usage РЅРµ РЅР°Р№РґРµРЅР°"
  fi
}

# ── РўРµСЃС‚: --help РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ ──────────────────────────────
test_help_argument() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±СЂР°Р±РѕС‚РєРё --help..."

  if grep -q '\-\-help' "${SCRIPT_DIR}/install.sh" &&
    grep -q 'usage' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: --help РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  else
    fail "install.sh: --help РЅРµ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  fi
}

# -- Тест: DEV_DOMAIN переменная определена --------------------------------
test_dev_domain_variable() {
  info "Тестирование переменной DEV_DOMAIN..."

  if grep -q 'DEV_DOMAIN=' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_DOMAIN=' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: переменная DEV_DOMAIN определена"
  else
    fail "install.sh: переменная DEV_DOMAIN не найдена"
  fi
}

# -- Тест: dev.cubiveil.local используется по умолчанию --------------------
test_default_dev_domain() {
  info "Тестирование домена по умолчанию для dev..."

  if grep -q 'dev.cubiveil.local' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'dev.cubiveil.local' "${SCRIPT_DIR}/lib/core/installer/cli.sh"; then
    pass "install.sh: dev.cubiveil.local используется по умолчанию"
  else
    fail "install.sh: dev.cubiveil.local не найдено"
  fi
}

# ── РўРµСЃС‚: --domain Р°СЂРіСѓРјРµРЅС‚ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ ───────────────────
test_domain_argument() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РѕР±СЂР°Р±РѕС‚РєРё --domain..."

  if grep -q '\-\-domain=' "${SCRIPT_DIR}/install.sh"; then
    pass "install.sh: --domain РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  else
    fail "install.sh: --domain РЅРµ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚СЃСЏ"
  fi
}

# -- Тест: prompt_inputs проверяет DEV_MODE ---------------------------------
test_prompt_inputs_checks_dev_mode() {
  info "Тестирование prompt_inputs: проверка DEV_MODE..."

  if grep -q 'DEV_MODE.*true' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE:-false' "${SCRIPT_DIR}/install.sh" ||
    grep -q 'DEV_MODE' "${SCRIPT_DIR}/lib/core/installer/prompt.sh"; then
    pass "prompt_inputs: проверяет DEV_MODE"
  else
    fail "prompt_inputs: не проверяет DEV_MODE"
  fi
}

# -- Тест: prompt_inputs пропускает ввод в dev-режиме -------------------------
test_prompt_inputs_skips_in_dev_mode() {
  info "Тестирование prompt_inputs: пропуск ввода в dev-режиме..."

  if grep -q 'return 0' "${SCRIPT_DIR}/lib/core/installer/prompt.sh" &&
    grep -q 'DEV-режим\|DEV mode\|DEV_MODE' "${SCRIPT_DIR}/lib/core/installer/prompt.sh"; then
    pass "prompt_inputs: пропускает ввод в dev-режиме"
  else
    fail "prompt_inputs: не пропускает ввод в dev-режиме"
  fi
}

# ── Р-Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ ────────────────────────────────────────────
main() {
  echo "══════════════════════════════════════════════════════════"
  echo "  CubiVeil Unit Tests - install.sh modes"
  echo "  РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЂРµР¶РёРјРѕРІ --dev Рё --dry-run"
  echo "══════════════════════════════════════════════════════════"
  echo ""

  # Р'Р°Р·РѕРІС‹Рµ С‚РµСЃС‚С‹
  test_install_file_exists
  test_install_syntax

  # РўРµСЃС‚С‹ РїРµСЂРµРјРµРЅРЅС‹С...
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

  # -- Итоги ------------------------------------------------------------------
  echo ""
  echo "══════════════════════════════════════════════════════════"
  echo "  Р РµР·СѓР»СЊС‚Р°С‚С‹ / Results"
  echo "══════════════════════════════════════════════════════════"
  echo ""
  echo -e "  РџСЂРѕР№РґРµРЅРѕ ${GREEN}(${TESTS_PASSED})${PLAIN}"
  echo -e "  РџСЂРѕРІР°Р»РµРЅРѕ ${RED}(${TESTS_FAILED})${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}  РўРµСЃС‚С‹ РЅРµ РїСЂРѕР№РґРµРЅС‹${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}Р'СЃРµ С‚РµС‚С‹ РїСЂРѕР№РґРµРЅС‹ вњ${PLAIN}"
    exit 0
  fi
}

main "$@"
