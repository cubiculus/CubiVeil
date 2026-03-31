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
# shellcheck disable=SC2034
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

  # Проверяем что nginx установлен
  if ! command -v nginx &>/dev/null; then
    log_warn "nginx not installed — skipping decoy-site"
    return 0
  fi

  # Проверяем что конфиг существует
  if [[ ! -f "$NGINX_CONF" ]]; then
    log_warn "Decoy nginx config not found: $NGINX_CONF"
    log_warn "Skipping decoy-site — you can configure manually later"
    return 0
  fi

  rm -f /etc/nginx/sites-enabled/default
  ln -sf "$NGINX_CONF" "$NGINX_ENABLED"

  # Проверяем конфиг nginx
  local nginx_test_output
  if ! nginx_test_output=$(nginx -t 2>&1); then
    log_error "Ошибка конфигурации nginx: $nginx_test_output"
    log_warn "Decoy-site disabled due to nginx config error"
    return 0 # Не ошибка — продолжаем
  fi

  systemctl enable nginx >/dev/null 2>&1
  systemctl reload nginx

  # Таймер ротации — включаем если enabled: true в decoy.json
  local rotation_enabled
  rotation_enabled=$(jq -r '.rotation.enabled' "$DECOY_CONFIG" 2>/dev/null || echo "true")
  if [[ "$rotation_enabled" == "true" ]]; then
    systemctl enable "${DECOY_ROTATE_TIMER}.timer" >/dev/null 2>&1
    systemctl start "${DECOY_ROTATE_TIMER}.timer"
    log_success "Ротация файлов активирована (~3 часа)"
  else
    log_info "Ротация файлов отключена (rotation.enabled = false)"
  fi

  log_success "Сайт-прикрытие запущен на порту 443"
}

module_disable() {
  log_step "decoy_disable" "Выключение сайта-прикрытия"
  systemctl stop nginx 2>/dev/null || true
  systemctl disable nginx 2>/dev/null || true
  rm -f "$NGINX_ENABLED"
  log_success "Сайт-прикрытие выключен"
}

module_status() {
  echo "║         Decoy Site — Статус                         ║"
  echo "╠═════════════════════════════════════════════════════╣"

  # nginx статус
  if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "║  nginx: Active                                        ║"
  else
    echo "║  nginx: Inactive                                      ║"
  fi

  # Timer статус
  if systemctl is-active --quiet "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null; then
    echo "║  Rotation Timer: Active                               ║"
  else
    echo "║  Rotation Timer: Inactive                             ║"
  fi

  # Конфиг
  if [[ -f "$DECOY_CONFIG" ]]; then
    local template site_name
    template=$(jq -r '.template // "unknown"' "$DECOY_CONFIG" 2>/dev/null || echo "unknown")
    site_name=$(jq -r '.site_name // "unknown"' "$DECOY_CONFIG" 2>/dev/null || echo "unknown")
    echo "║  Template: ${template}"
    echo "║  Site Name: ${site_name}"
  fi

  echo "╚═════════════════════════════════════════════════════╝"
}
