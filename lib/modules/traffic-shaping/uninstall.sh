#!/bin/bash
# CubiVeil — Traffic Shaping Uninstaller
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

TS_CONFIG="/etc/cubiveil/traffic-shaping.json"
TS_SERVICE="cubiveil-tc"
TS_APPLY_SCRIPT="/usr/local/lib/cubiveil/tc-apply.sh"

ts_uninstall() {
  log_step "ts_uninstall" "Удаление traffic-shaping"

  # Останавливаем и удаляем сервис
  systemctl stop    "${TS_SERVICE}" 2>/dev/null || true
  systemctl disable "${TS_SERVICE}" 2>/dev/null || true
  rm -f "/etc/systemd/system/${TS_SERVICE}.service"
  systemctl daemon-reload

  # Удаляем tc-правила
  local iface
  iface=$(jq -r '.interface' "$TS_CONFIG" 2>/dev/null || \
    ip route show default | awk '/default/ {print $5}' | head -1)
  if [[ -n "$iface" ]]; then
    tc qdisc del dev "$iface" root 2>/dev/null || true
  fi

  # Удаляем файлы
  rm -f "$TS_APPLY_SCRIPT"
  rm -f "$TS_CONFIG"

  log_success "Traffic-shaping удалён"
}

# Запуск при прямом вызове
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ts_uninstall
fi
