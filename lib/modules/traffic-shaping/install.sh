#!/bin/bash
# shellcheck disable=SC1071
# ╔══════════════════════════════════════════════════════╗
# ║  CubiVeil — Traffic Shaping Module (tc/netem)        ║
# ║  Уникальный "почерк" сервера — фиксируется при       ║
# ║  установке, применяется после каждой перезагрузки    ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение зависимостей через init.sh ──────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Используем централизованный загрузчик для правильного порядка
if [[ -f "${SCRIPT_DIR}/lib/init.sh" ]]; then
  source "${SCRIPT_DIR}/lib/init.sh"
else
  # Fallback для обратной совместимости
  if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
    source "${SCRIPT_DIR}/lib/core/system.sh"
  fi
  if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
    source "${SCRIPT_DIR}/lib/core/log.sh"
  fi
  if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
    source "${SCRIPT_DIR}/lib/utils.sh"
  fi
fi

if [[ -f "${MODULE_DIR}/persist.sh" ]]; then
  source "${MODULE_DIR}/persist.sh"
else
  log_error "persist.sh not found — traffic-shaping module is incomplete"
  return 1 2>/dev/null || exit 1
fi

TS_CONFIG="/etc/cubiveil/traffic-shaping.json"
TS_SERVICE="cubiveil-tc"
TS_APPLY_SCRIPT="/usr/local/lib/cubiveil/tc-apply.sh"

module_install() {
  log_step "ts_install" "Проверка tc/netem"
  if ! command -v tc &>/dev/null; then
    pkg_install_packages "iproute2"
  fi
  log_success "tc/netem доступен (без дополнительных зависимостей)"
}

module_configure() {
  log_step "ts_configure" "Генерация профиля шейпинга"
  ts_generate_profile
  ts_write_apply_script
  ts_write_systemd_service
  log_success "Профиль шейпинга сохранён"
}

module_enable() {
  log_step "ts_enable" "Применение tc-правил"
  systemctl daemon-reload
  systemctl enable "${TS_SERVICE}" >/dev/null 2>&1
  bash "$TS_APPLY_SCRIPT"
  log_success "Шейпинг трафика активен"
}

module_disable() {
  systemctl stop "${TS_SERVICE}" 2>/dev/null || true
  systemctl disable "${TS_SERVICE}" 2>/dev/null || true
  local iface
  iface=$(jq -r '.interface' "$TS_CONFIG" 2>/dev/null ||
    ip route show default | awk '/default/ {print $5}' | head -1)
  tc qdisc del dev "$iface" root 2>/dev/null || true
  log_info "Шейпинг отключён, tc-правила сброшены"
}

module_status() {
  log_step "ts_status" "Статус шейпинга трафика"
  local iface
  iface=$(jq -r '.interface' "$TS_CONFIG" 2>/dev/null || echo "?")
  if systemctl is-active --quiet "${TS_SERVICE}"; then
    log_success "Сервис ${TS_SERVICE}: активен"
  else
    log_error "Сервис ${TS_SERVICE}: не запущен"
  fi
  log_info "Текущие правила tc (${iface}):"
  tc qdisc show dev "$iface" 2>/dev/null || true
}
