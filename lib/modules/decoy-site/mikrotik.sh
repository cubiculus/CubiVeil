#!/bin/bash
# shellcheck disable=SC1071
# ╔══════════════════════════════════════════════════════╗
# ║  CubiVeil — Decoy Site: MikroTik Script              ║
# ║  Генерация скрипта для MikroTik RouterOS             ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC2034
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# ── Константы / Constants ────────────────────────────────────────
# shellcheck disable=SC2034
DECOY_WEBROOT="/var/www/decoy"
DECOY_CONFIG="/etc/cubiveil/decoy.json"

# ── Генерация MikroTik скрипта ────────────────────────────────────

decoy_print_mikrotik_script() {
  local config_file="${1:-$DECOY_CONFIG}"

  if [[ ! -f "$config_file" ]]; then
    log_error "Конфигурация не найдена: $config_file"
    return 1
  fi

  # Читаем конфигурацию
  local site_name domain interval_hours
  site_name=$(jq -r '.site_name // "Decoy Site"' "$config_file" 2>/dev/null || echo "Decoy Site")
  domain=$(jq -r '.domain // "example.com"' "$config_file" 2>/dev/null || echo "example.com")
  interval_hours=$(jq -r '.rotation.interval_hours // 3' "$config_file" 2>/dev/null || echo "3")

  # Очищаем имя для использования в комментариях
  local clean_name
  clean_name=$(echo "$site_name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '_')

  cat <<EOF
# ═══════════════════════════════════════════════════════════════
# MikroTik RouterOS Script — Decoy Site Configuration
# Site: ${site_name}
# Domain: ${domain}
# Rotation Interval: ${interval_hours} hours
# Generated: $(date -Iseconds)
# ═══════════════════════════════════════════════════════════════

# Add this script to RouterOS:
# 1. Upload to Files: /files/upload decoy-config.rsc
# 2. Import: /import decoy-config.rsc
# 3. Or copy-paste commands manually

# ═══════════════════════════════════════════════════════════════
# 1. Address List — Decoy Domain
# ═══════════════════════════════════════════════════════════════

# Add decoy domain to address list (if using DNS)
# /ip dns static add name="${domain}" address="0.0.0.0"

# ═══════════════════════════════════════════════════════════════
# 2. Firewall Rules — Log Decoy Access
# ═══════════════════════════════════════════════════════════════

# Log connections to decoy site (port 443)
/ip firewall filter add chain=input dst-port=443 protocol=tcp \
    action=log log-prefix="DECOY_ACCESS:" \
    comment="Log decoy site access"

# Optionally drop after logging
# /ip firewall filter add chain=input dst-port=443 protocol=tcp \
#     action=drop comment="Drop decoy access"

# ═══════════════════════════════════════════════════════════════
# 3. Scheduled Task — Periodic Check
# ═══════════════════════════════════════════════════════════════

# Create scheduled task to check decoy status
/system scheduler add name="decoy-check" interval="${interval_hours}h:0m:0s" \
    on-event="/log info message=\\\"Decoy site check: ${clean_name}\\\"" \
    comment="Check decoy site status"

# ═══════════════════════════════════════════════════════════════
# 4. Email Alert (if SMTP configured)
# ═══════════════════════════════════════════════════════════════

# Send email alert on decoy access (requires SMTP setup)
# /tool e-mail send to="admin@example.com" \
#     subject="Decoy Site Access Alert" \
#     body="Decoy site \${site_name} was accessed at [/system clock get time]"

# ═══════════════════════════════════════════════════════════════
# 5. Netwatch — Monitor Decoy Site
# ═══════════════════════════════════════════════════════════════

# Monitor decoy site availability
/tool netwatch add host="${domain}" interval=60s timeout=3s \
    comment="Monitor decoy site" \
    on-down="/log warning message=\\\"Decoy site ${clean_name} is DOWN\\\""

# ═══════════════════════════════════════════════════════════════
# End of MikroTik Script
# ═══════════════════════════════════════════════════════════════
EOF
}

decoy_save_mikrotik_script() {
  local output_file="${1:-/etc/cubiveil/mikrotik-decoy.rsc}"
  local config_file="${2:-$DECOY_CONFIG}"

  log_step "decoy_mikrotik" "Генерация MikroTik скрипта"

  # Создаём директорию если не существует
  mkdir -p "$(dirname "$output_file")"

  # Генерируем скрипт
  if decoy_print_mikrotik_script "$config_file" >"$output_file"; then
    chmod 644 "$output_file"
    log_success "MikroTik скрипт сохранён: $output_file"
    return 0
  else
    log_error "Не удалось создать MikroTik скрипт"
    return 1
  fi
}

# Если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-print}" in
  print)
    decoy_print_mikrotik_script "${2:-}"
    ;;
  save)
    decoy_save_mikrotik_script "${2:-}" "${3:-}"
    ;;
  *)
    echo "Usage: $0 [print|save] [config_file] [output_file]"
    exit 1
    ;;
  esac
fi
