#!/bin/bash
# shellcheck disable=SC1071
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Fallback Functions                    ║
# ║          Базовые функции и цвета при отсутствии lang.sh   ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение унифицированных функций вывода ───────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/output.sh" ]]; then
  source "${SCRIPT_DIR}/output.sh"
  # Функции уже определены в output.sh: ok, warn, err, info, step_title, step
else
  # Если output.sh отсутствует — определяем базовые функции
  # ── Цвета / Colors ────────────────────────────────────────────
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  PLAIN='\033[0m'

  # ── Функции вывода / Output functions ─────────────────────────
  ok() { echo -e "${GREEN}[✓]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[✗]${PLAIN} $1"
    exit 1
  }
  info() { echo -e "ℹ️  $*"; }

  step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e "${BLUE}  $1${PLAIN}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  }

  step_title() {
    local num="$1"
    local ru="$2"
    local en="$3"
    if [[ "${LANG_NAME:-}" == "Русский" ]]; then
      step "Шаг ${num}/12 — ${ru}"
    else
      step "Step ${num}/12 — ${en}"
    fi
  }
fi

# ── Баннер / Banner ───────────────────────────────────────────
print_banner() {
  clear
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
  echo -e "${CYAN}  ║            CubiVeil Installer            ║${PLAIN}"
  echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
  echo -e "${CYAN}  ║    S-UI Panel (Sing-box)                 ║${PLAIN}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
  echo ""
}

print_banner_telegram() {
  clear
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
  echo -e "${CYAN}  ║       CubiVeil Telegram Bot Setup        ║${PLAIN}"
  echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
  echo ""
}
