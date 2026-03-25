#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: SSL Certificate                  ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Получение SSL сертификата (Let's Encrypt)                  ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# Подключаем utils
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# Подключаем ssl модуль
if [[ -f "${SCRIPT_DIR}/lib/modules/ssl/install.sh" ]]; then
  source "${SCRIPT_DIR}/lib/modules/ssl/install.sh"
fi

# ── Функции / Functions ──────────────────────────────────────

# Установка acme.sh
ssl_install_acme() {
  log_step "ssl_install_acme" "Installing acme.sh"

  if [[ ! -f "$HOME/.acme.sh/acme.sh" ]]; then
    info "Устанавливаю acme.sh..."
    local ACME_SCRIPT="/tmp/acme-install.sh"

    # Скачиваем скрипт с проверкой
    curl -fsSL "https://get.acme.sh" -o "$ACME_SCRIPT" || err "Не удалось скачать acme.sh"

    # Проверка что файл не пустой (минимум 500 байт)
    if [[ ! -s "$ACME_SCRIPT" ]] || [[ $(stat -c%s "$ACME_SCRIPT") -lt 500 ]]; then
      rm -f "$ACME_SCRIPT"
      err "Скачанный файл acme.sh пуст или повреждён"
    fi

    # Проверка на корректность bash скрипта
    if ! bash -n "$ACME_SCRIPT" 2>/dev/null; then
      rm -f "$ACME_SCRIPT"
      err "Скачанный файл acme.sh содержит синтаксические ошибки"
    fi

    bash "$ACME_SCRIPT" -s email="$LE_EMAIL" >/dev/null 2>&1
    rm -f "$ACME_SCRIPT"

    log_debug "acme.sh installed"
  else
    log_debug "acme.sh already installed"
  fi
}

# Подготовка к валидации (открытие порта 80)
ssl_prepare_validation() {
  log_step "ssl_prepare_validation" "Preparing for SSL validation"

  open_port 80 tcp "Let's Encrypt validation"
  svc_stop "marzban" 2>/dev/null || true
}

# Запрос сертификата
ssl_request_certificate() {
  log_step "ssl_request_certificate" "Requesting SSL certificate"

  info "Запрашиваю сертификат для ${DOMAIN}..."

  "$HOME/.acme.sh/acme.sh" --set-default-ca --server letsencrypt >/dev/null 2>&1

  if ! "$HOME/.acme.sh/acme.sh" --issue \
    -d "$DOMAIN" --standalone --httpport 80 --force >/dev/null 2>&1; then
    err "Не удалось получить сертификат. Проверь A-запись: ${DOMAIN} → ${SERVER_IP}"
  fi

  log_debug "SSL certificate obtained"
}

# Установка сертификата для Marzban
ssl_install_for_marzban() {
  log_step "ssl_install_for_marzban" "Installing SSL certificate for Marzban"

  mkdir -p /var/lib/marzban/certs

  "$HOME/.acme.sh/acme.sh" --installcert -d "$DOMAIN" \
    --cert-file /var/lib/marzban/certs/cert.pem \
    --key-file /var/lib/marzban/certs/key.pem \
    --fullchain-file /var/lib/marzban/certs/fullchain.pem \
    --reloadcmd "systemctl restart marzban" >/dev/null 2>&1

  "$HOME/.acme.sh/acme.sh" --upgrade --auto-upgrade >/dev/null 2>&1

  # Установка прав
  chmod 600 /var/lib/marzban/certs/key.pem
  chmod 640 /var/lib/marzban/certs/cert.pem
  chmod 640 /var/lib/marzban/certs/fullchain.pem

  log_debug "SSL certificate installed for Marzban"
}

# Очистка после валидации
ssl_cleanup_validation() {
  log_step "ssl_cleanup_validation" "Cleaning up after validation"

  close_port 80 tcp
}

# Основная функция шага (вызывается из install-steps.sh)
step_ssl() {
  step_title "10" "SSL сертификат (Let's Encrypt)" "SSL certificate (Let's Encrypt)"

  ssl_install_acme
  ssl_prepare_validation
  ssl_request_certificate
  ssl_install_for_marzban
  ssl_cleanup_validation

  ok "SSL сертификат получен, автопродление настроено"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { ssl_install; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }
