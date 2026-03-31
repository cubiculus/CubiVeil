#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — Prompt                                        ║
# ║  Пользовательский ввод и интерактивные prompts            ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Функции ─────────────────────────────────────────────────

_select_language() {
  echo ""
  echo "$(get_str MSG_SELECT_LANGUAGE)"
  echo "  1) $(get_str MSG_OPTION_RU)"
  echo "  2) $(get_str MSG_OPTION_EN)"
  echo ""
  while true; do
    read -rp "  Enter choice [1-2]: " _lc
    case "$_lc" in
    1)
      LANG_NAME="Русский"
      return
      ;;
    2)
      LANG_NAME="English"
      return
      ;;
    *) echo "  $(get_str MSG_INVALID_CHOICE)" ;;
    esac
  done
}

_print_banner() {
  echo ""
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║        CubiVeil Installer                ║"
  echo "  ║   github.com/cubiculus/cubiveil          ║"
  echo "  ╚══════════════════════════════════════════╝"
  echo ""
}

prompt_inputs() {
  local _step_label
  _step_label="$(get_str MSG_PRE_INSTALL_SETUP)"
  step "$_step_label"

  # ── DEV MODE ──────────────────────────────────────────────
  # DEV mode: skip interactive prompts, use self-signed SSL
  if [[ "$DEV_MODE" == "true" ]]; then
    [[ -z "$DOMAIN" ]] && DOMAIN="$DEV_DOMAIN"
    LE_EMAIL="admin@${DOMAIN}"
    # DEV-режим: Self-signed SSL, no domain required
    echo ""
    echo -e "\033[0;33m  [DEV mode] Self-signed SSL, no domain required\033[0m"
    echo ""
    info "$(get_str INFO_DEV_MODE)"
    warn "$(get_str MSG_BROWSERS_SECURITY_WARNING)"
    warn "$(get_str MSG_DO_NOT_USE_PRODUCTION)"
    echo ""
    ok "Domain:  $DOMAIN"
    ok "Email:   $LE_EMAIL"
    echo ""
    return 0
  fi

  # ── PRODUCTION MODE ───────────────────────────────────────
  warn "$(get_str MSG_DNS_A_RECORD_HINT)"
  warn "$(get_str MSG_LE_DNS_CHECK)"
  echo ""

  # Получаем внешний IP сервера
  SERVER_IP=$(get_external_ip 2>/dev/null || hostname -I | awk '{print $1}')

  # Домен
  while true; do
    local _pdomain
    _pdomain="$(get_str MSG_PROMPT_DOMAIN)"
    read -rp "$_pdomain" DOMAIN
    DOMAIN="${DOMAIN// /}"

    if [[ -z "$DOMAIN" ]]; then
      warn "$(get_str WARN_DOMAIN_EMPTY)"
      continue
    fi
    if ! validate_domain "$DOMAIN"; then
      warn "$(get_str WARN_DOMAIN_FORMAT)"
      continue
    fi

    # DNS check
    if ! command -v dig &>/dev/null; then
      apt-get install -y -qq dnsutils >/dev/null 2>&1
    fi
    local _resolved
    _resolved=$(dig +short "$DOMAIN" A 2>/dev/null | head -1)
    if [[ -z "$_resolved" ]]; then
      warn "$(get_str MSG_CANNOT_RESOLVE_DOMAIN | sed "s/{DOMAIN}/$DOMAIN/g")"
      read -rp "  $(get_str MSG_CONTINUE_DESPITE_ERROR) " _cont
      [[ "$_cont" =~ ^[yY]$ ]] || continue
    elif [[ -n "$SERVER_IP" && "$_resolved" != "$SERVER_IP" ]]; then
      local _mismatch_msg
      _mismatch_msg="$(get_str MSG_A_RECORD_MISMATCH)"
      _mismatch_msg="${_mismatch_msg//\{DOMAIN\}/$DOMAIN}"
      _mismatch_msg="${_mismatch_msg//\{RESOLVED\}/$_resolved}"
      _mismatch_msg="${_mismatch_msg//\{SERVER_IP\}/$SERVER_IP}"
      warn "$_mismatch_msg"
      read -rp "  $(get_str MSG_CONTINUE_DESPITE_MISMATCH) " _cont
      [[ "$_cont" =~ ^[yY]$ ]] || continue
    fi
    break
  done

  # Email
  local _pemail
  local _domain_placeholder="${DOMAIN}"
  _pemail="$(get_str MSG_PROMPT_EMAIL | sed "s/{DOMAIN}/$_domain_placeholder/g")"
  read -rp "$_pemail" LE_EMAIL
  LE_EMAIL="${LE_EMAIL// /}"
  [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"

  while ! validate_email "$LE_EMAIL"; do
    warn "$(get_str MSG_INVALID_EMAIL | sed "s/{DOMAIN}/$_domain_placeholder/g")"
    read -rp "$_pemail" LE_EMAIL
    LE_EMAIL="${LE_EMAIL// /}"
    [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"
  done

  echo ""
  ok "Domain:  $DOMAIN"
  ok "Email:   $LE_EMAIL"
  echo ""

  # ── Telegram bot ───────────────────────────────────────────
  if [[ -z "$INSTALL_TELEGRAM" ]]; then
    local _ptg
    _ptg="$(get_str MSG_PROMPT_TELEGRAM)"
    read -rp "$_ptg" _tg_choice
    if [[ "$_tg_choice" =~ ^[yY]$ ]]; then
      INSTALL_TELEGRAM="true"
      info "$(get_str MSG_TELEGRAM_WILL_BE_INSTALLED)"
    else
      INSTALL_TELEGRAM="false"
    fi
  fi

  echo ""
}

# ── Legacy API wrappers ─────────────────────────────────────
select_language() { _select_language; }
print_banner() { _print_banner; }
