#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  CubiVeil — Decoy Site Module                        ║
# ║  Модуль сайта-прикрытия                              ║
# ╚══════════════════════════════════════════════════════╝
# Этот файл содержит только контракт модуля и sourcing.
# Вся логика — в generate.sh, rotate.sh, mikrotik.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi
if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

source "${MODULE_DIR}/generate.sh"
source "${MODULE_DIR}/rotate.sh"
source "${MODULE_DIR}/mikrotik.sh"

# ── Константы / Constants ────────────────────────────────────────
DECOY_WEBROOT="/var/www/decoy"
DECOY_CONFIG="/etc/cubiveil/decoy.json"
NGINX_CONF="/etc/nginx/sites-available/cubiveil-decoy"
NGINX_ENABLED="/etc/nginx/sites-enabled/cubiveil-decoy"
DECOY_ROTATE_TIMER="cubiveil-decoy-rotate"

# ── Контракт модуля / Module Contract ──────────────────────────────

module_install() {
  log_step "decoy_install" "Установка зависимостей сайта-прикрытия"
  pkg_install_packages "nginx" "imagemagick"
  # Модуль подмены Server: заголовка — устанавливаем если есть в репо
  pkg_install "libnginx-mod-http-headers-more-filter" 2>/dev/null || true
  # Зависимости для генерации контента
  pkg_install "enscript" "ghostscript" 2>/dev/null || true
  pkg_install "ffmpeg" 2>/dev/null || true
  log_success "Зависимости decoy-site установлены"
}

module_configure() {
  log_step "decoy_configure" "Настройка сайта-прикрытия"
  decoy_generate_profile
  decoy_build_webroot
  decoy_write_nginx_conf
  decoy_write_rotate_timer
  log_success "Сайт-прикрытие настроен"
}

module_enable() {
  log_step "decoy_enable" "Запуск сайта-прикрытия"
  rm -f /etc/nginx/sites-enabled/default
  ln -sf "$NGINX_CONF" "$NGINX_ENABLED"
  nginx -t >/dev/null 2>&1 || { log_error "Ошибка конфигурации nginx"; return 1; }
  systemctl enable nginx >/dev/null 2>&1
  systemctl reload nginx

  # Таймер ротации — включаем если enabled: true в decoy.json
  local rotation_enabled
  rotation_enabled=$(jq -r '.rotation.enabled' "$DECOY_CONFIG" 2>/dev/null || echo "true")
  if [[ "$rotation_enabled" == "true" ]]; then
    systemctl enable "${DECOY_ROTATE_TIMER}.timer" >/dev/null 2>&1
    systemctl start  "${DECOY_ROTATE_TIMER}.timer"
    log_success "Ротация файлов активирована (~3 часа)"
  else
    log_info "Ротация файлов отключена (rotation.enabled = false)"
  fi

  log_success "Сайт-прикрытие запущен на порту 443"
}

module_disable() {
  rm -f "$NGINX_ENABLED"
  systemctl reload nginx 2>/dev/null || true
  systemctl stop    "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null || true
  systemctl disable "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null || true
  log_info "Сайт-прикрытие отключён"
}

module_status() {
  log_step "decoy_status" "Статус сайта-прикрытия"

  # nginx
  if systemctl is-active --quiet nginx; then
    log_success "nginx: активен"
  else
    log_error "nginx: не запущен"
  fi

  # Сертификат
  local cert_file
  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    cert_file="/var/lib/marzban/certs/cert.pem"
  else
    cert_file="/etc/letsencrypt/live/${DOMAIN:-_}/fullchain.pem"
  fi
  if [[ -f "$cert_file" ]]; then
    local expiry
    expiry=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
    log_success "Сертификат: действует до ${expiry}"
  else
    log_error "Сертификат не найден: ${cert_file}"
  fi

  # Файлы в webroot
  local file_count total_size
  file_count=$(find "${DECOY_WEBROOT}/files" -type f 2>/dev/null | wc -l)
  total_size=$(du -sh "${DECOY_WEBROOT}/files" 2>/dev/null | cut -f1)
  log_info "Файлов в /files/: ${file_count} (${total_size:-0})"

  # Таймер ротации
  if systemctl is-active --quiet "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null; then
    log_success "Ротация: активна"
  else
    log_info "Ротация: отключена (rotation.enabled = false)"
  fi
}
