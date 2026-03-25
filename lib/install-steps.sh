#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Installation Steps (Refactored)       ║
# ║          github.com/cubiculus/cubiveil                    ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение модуля валидации ─────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/validation.sh" ]]; then
  source "${SCRIPT_DIR}/validation.sh"
fi

# ── Автозагрузка всех step файлов ───────────────────────────
STEPS_DIR="${SCRIPT_DIR}/steps"

# Загружаем все step файлы автоматически
for step_file in "${STEPS_DIR}"/*.sh; do
  if [[ -f "$step_file" ]]; then
    source "$step_file"
  fi
done

# ── Загрузка основных шагов установки ───────────────────────
if [[ -f "${SCRIPT_DIR}/steps/install-steps-main.sh" ]]; then
  source "${SCRIPT_DIR}/steps/install-steps-main.sh"
fi

# ── ШАГ 0: Ввод данных / Input data ──────────────────────────
prompt_inputs() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="Настройка перед установкой"
  else
    step_title="Pre-installation setup"
  fi
  step "$step_title"

  # ── DEV MODE: Пропуск ввода домена ──────────────────────────
  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      info "DEV-режим: использование самоподписного SSL сертификата"
      info "Домен не требуется, будет использован: ${DOMAIN:-${DEV_DOMAIN:-dev.cubiveil.local}}"
    else
      info "DEV mode: using self-signed SSL certificate"
      info "Domain not required, will use: ${DOMAIN:-${DEV_DOMAIN:-dev.cubiveil.local}}"
    fi
    echo ""

    # Установка домена по умолчанию если не задан
    if [[ -z "${DOMAIN:-}" ]]; then
      DOMAIN="${DEV_DOMAIN:-dev.cubiveil.local}"
    fi

    # Email по умолчанию
    LE_EMAIL="${LE_EMAIL:-admin@${DOMAIN}}"

    if [[ "$LANG_NAME" == "Русский" ]]; then
      ok "Домен:   $DOMAIN (dev-режим)"
      ok "Email:   $LE_EMAIL"
      warn "ВНИМАНИЕ: Браузеры будут показывать предупреждение о безопасности"
    else
      ok "Domain:  $DOMAIN (dev mode)"
      ok "Email:   $LE_EMAIL"
      warn "WARNING: Browsers will show security warning"
    fi
    echo ""

    # Telegram - спрашиваем только要不要
    local prompt_telegram
    if [[ "$LANG_NAME" == "Русский" ]]; then
      info "Telegram-бот: ежедневные отчёты, алерты, управление через чат."
      prompt_telegram="  Установить Telegram-бот? (y/n): "
    else
      info "Telegram bot: daily reports, alerts, chat control."
      prompt_telegram="  Install Telegram bot? (y/n): "
    fi
    read -rp "$prompt_telegram" INSTALL_TG

    # Сбрасываем переменные Telegram
    # shellcheck disable=SC2034
    TG_TOKEN=""
    # shellcheck disable=SC2034
    TG_CHAT_ID=""

    if [[ "$INSTALL_TG" == "y" || "$INSTALL_TG" == "Y" ]]; then
      warn "Telegram-бот будет установлен через отдельный скрипт после завершения установки."
    fi

    echo ""
    return 0
  fi

  # ── PRODUCTION MODE: Запрос домена ─────────────────────────
  if [[ "$LANG_NAME" == "Русский" ]]; then
    warn "Убедись что A-запись домена уже указывает на этот сервер."
    warn "Let's Encrypt проверит DNS — установка упадёт если запись не прописана."
  else
    warn "$WARN_DNS_RECORD"
    warn "$WARN_LETS_ENCRYPT"
  fi
  echo ""

  while true; do
    local prompt_domain
    if [[ "$LANG_NAME" == "Русский" ]]; then
      prompt_domain="  Домен для панели и подписок (например panel.example.com): "
    else
      prompt_domain="  $PROMPT_DOMAIN "
    fi
    read -rp "$prompt_domain" DOMAIN
    DOMAIN="${DOMAIN// /}"

    # Валидация домена через модуль validation.sh
    if [[ -z "$DOMAIN" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Домен не может быть пустым"
      else
        warn "$WARN_DOMAIN_EMPTY"
      fi
      continue
    fi

    # Использование функции validate_domain из модуля validation.sh
    if ! validate_domain "$DOMAIN"; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Некорректный формат домена. Пример: panel.example.com"
      else
        warn "$WARN_DOMAIN_FORMAT"
      fi
      continue
    fi

    # Проверка DNS A-записи
    if ! command -v dig &>/dev/null; then
      apt-get install -y -qq dnsutils >/dev/null 2>&1
    fi
    local resolved_ip
    resolved_ip=$(dig +short "$DOMAIN" A 2>/dev/null | head -1)
    if [[ -z "$resolved_ip" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Не удалось разрешить домен $DOMAIN. Проверь A-запись."
        read -rp "  Продолжить несмотря на ошибку? (y/n): " cont
      else
        warn "$WARN_DNS_RESOLVE"
        read -rp "  $WARN_CONTINUE_ERROR " cont
      fi
      [[ "$cont" == "y" || "$cont" == "Y" ]] || continue
    elif [[ "$resolved_ip" != "$SERVER_IP" ]] && [[ -n "$SERVER_IP" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "A-запись $DOMAIN → $resolved_ip, но IP сервера: $SERVER_IP"
        read -rp "  Продолжить несмотря на несоответствие? (y/n): " cont
      else
        warn "$WARN_DNS_MISMATCH"
        read -rp "  $WARN_CONTINUE_MISMATCH " cont
      fi
      [[ "$cont" == "y" || "$cont" == "Y" ]] || continue
    fi

    break
  done

  local prompt_email
  if [[ "$LANG_NAME" == "Русский" ]]; then
    prompt_email="  Email для Let's Encrypt [admin@${DOMAIN}]: "
  else
    prompt_email="  $PROMPT_EMAIL "
  fi
  read -rp "$prompt_email" LE_EMAIL
  LE_EMAIL="${LE_EMAIL// /}"
  [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"

  # Валидация email через модуль validation.sh
  while ! validate_email "$LE_EMAIL"; do
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Некорректный формат email. Пример: admin@${DOMAIN}"
    else
      warn "Invalid email format. Example: admin@${DOMAIN}"
    fi
    read -rp "$prompt_email" LE_EMAIL
    LE_EMAIL="${LE_EMAIL// /}"
    [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"
  done

  echo ""

  # Telegram - теперь спрашиваем только要不要, без деталей
  local prompt_telegram
  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Telegram-бот: ежедневные отчёты, алерты, управление через чат."
    prompt_telegram="  Установить Telegram-бот? (y/n): "
  else
    info "Telegram bot: daily reports, alerts, chat control."
    prompt_telegram="  Install Telegram bot? (y/n): "
  fi
  read -rp "$prompt_telegram" INSTALL_TG

  # Сбрасываем переменные Telegram (используются в setup-telegram.sh)
  # shellcheck disable=SC2034
  TG_TOKEN=""
  # shellcheck disable=SC2034
  TG_CHAT_ID=""

  if [[ "$INSTALL_TG" == "y" || "$INSTALL_TG" == "Y" ]]; then
    warn "Telegram-бот будет установлен через отдельный скрипт после завершения установки."
  fi

  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Домен:   $DOMAIN"
    ok "Email:   $LE_EMAIL"
    if [[ "$INSTALL_TG" == "y" || "$INSTALL_TG" == "Y" ]]; then
      warn "Telegram: будет установлен через setup-telegram.sh"
    else
      warn "Telegram: пропущен (можно добавить позже)"
    fi
  else
    ok "$OK_DOMAIN   $DOMAIN"
    ok "$OK_EMAIL   $LE_EMAIL"
    if [[ "$INSTALL_TG" == "y" || "$INSTALL_TG" == "Y" ]]; then
      warn "Telegram: will be installed via setup-telegram.sh"
    else
      warn "Telegram: skipped (can add later)"
    fi
  fi
  echo ""
}
