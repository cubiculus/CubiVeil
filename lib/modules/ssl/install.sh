#!/bin/bash
# shellcheck disable=SC1071
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — SSL Module                            ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль управления SSL сертификатами                      ║
# ║  - Dev-режим: самоподписные сертификаты                   ║
# ║  - Production: s-ui ACME (встроенный в панель)            ║
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

# ── Глобальные переменные / Global Variables ────────────────

# Пути для самоподписных сертификатов (dev-режим)
SSL_SELFIGNED_DIR="/usr/local/s-ui/cert"

# ── Генерация самоподписного сертификата (dev-режим) ────────
ssl_generate_self_signed() {
  local domain="${DOMAIN:-localhost}"

  log_step "ssl_generate_self_signed" "Generating self-signed certificate for ${domain}"

  # Создаём директорию
  mkdir -p "$SSL_SELFIGNED_DIR"

  # Генерируем приватный ключ и сертификат
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${SSL_SELFIGNED_DIR}/key.pem" \
    -out "${SSL_SELFIGNED_DIR}/cert.pem" \
    -subj "/CN=${domain}/O=CubiVeil Dev/C=US" \
    -addext "subjectAltName=DNS:${domain},DNS:localhost,IP:127.0.0.1" \
    >/dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    log_error "Failed to generate self-signed certificate"
    return 1
  fi

  # Создаём fullchain (копия cert.pem для совместимости)
  cp "${SSL_SELFIGNED_DIR}/cert.pem" "${SSL_SELFIGNED_DIR}/fullchain.pem"

  # Устанавливаем правильные права
  chmod 600 "${SSL_SELFIGNED_DIR}/key.pem"
  chmod 644 "${SSL_SELFIGNED_DIR}/cert.pem"
  chmod 644 "${SSL_SELFIGNED_DIR}/fullchain.pem"

  log_success "Self-signed certificate generated at ${SSL_SELFIGNED_DIR}"
  log_info "Certificate valid for 365 days"
  log_warn "Browsers will show security warning — this is expected in dev mode"
}

# ── Включение SSL (для тестов и ручного использования) ──────
ssl_enable() {
  log_step "ssl_enable" "Enabling SSL module"

  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    if [[ -f "${SSL_SELFIGNED_DIR}/cert.pem" ]]; then
      log_info "Self-signed certificate found at ${SSL_SELFIGNED_DIR}"
      svc_restart_if_active "s-ui" 2>/dev/null || true
      svc_restart_if_active "sing-box" 2>/dev/null || true
      log_success "SSL module enabled (dev mode)"
    else
      log_warn "No self-signed certificate found"
      return 1
    fi
  else
    log_info "s-ui manages SSL certificates via ACME"
    log_success "SSL module enabled (production mode)"
  fi
}

# ── Модульный интерфейс / Module Interface ─────────────────

module_install() {
  # Dry-run mode: skip actual installation
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install SSL module"
    if [[ "${DEV_MODE:-false}" == "true" ]]; then
      log_info "[DRY-RUN] Would generate self-signed certificate for ${DOMAIN:-dev.cubiveil.local}"
    else
      log_info "[DRY-RUN] s-ui will handle Let's Encrypt certificates via ACME"
    fi
    return 0
  fi

  # В dev-режиме генерируем самоподписной сертификат
  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    ssl_generate_self_signed
  else
    # В production-режиме s-ui сам управляет SSL через встроенный ACME
    log_info "s-ui will handle SSL certificates via ACME"
    log_info "Use s-ui web panel to obtain Let's Encrypt certificates"
  fi
}

module_configure() {
  log_step "ssl_configure" "Configuring SSL module"

  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    ssl_generate_self_signed
  fi

  log_success "SSL module configured"
}

module_enable() {
  log_step "ssl_enable" "Enabling SSL module"

  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    if [[ -f "${SSL_SELFIGNED_DIR}/cert.pem" ]]; then
      log_info "Self-signed certificate found at ${SSL_SELFIGNED_DIR}"
      log_success "SSL module enabled (dev mode)"
    else
      log_warn "No self-signed certificate found"
    fi
  else
    log_info "s-ui manages SSL certificates via ACME"
    log_success "SSL module enabled (production mode)"
  fi
}

module_disable() {
  log_step "ssl_disable" "Disabling SSL module"
  log_info "SSL module disabled (certificates remain installed)"
}

module_update() {
  log_step "module_update" "Updating SSL module"
  log_info "s-ui handles certificate renewal automatically via ACME"
}

module_remove() {
  log_step "module_remove" "Removing SSL module"
  log_success "SSL module removed (certificates remain installed)"
}
