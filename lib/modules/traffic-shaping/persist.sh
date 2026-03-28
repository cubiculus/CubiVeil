#!/bin/bash
# CubiVeil — Traffic Shaping: генерация профиля и системных файлов

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC2034
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi
if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# ── Константы / Constants ───────────────────────────────────
TS_CONFIG="/etc/cubiveil/traffic-shaping.json"
TS_SERVICE="cubiveil-tc"
TS_APPLY_SCRIPT="/usr/local/lib/cubiveil/tc-apply.sh"

# ── Генерация профиля шейпинга ─────────────────────────────────

ts_check_compatibility() {
  local iface
  iface=$(ip route show default | awk '/default/ {print $5}' | head -1)

  if [[ -z "$iface" ]]; then
    log_error "Не удалось определить сетевой интерфейс"
    return 1
  fi

  # Проверка существующих qdisc
  if command -v tc &>/dev/null; then
    local existing_qdisc
    existing_qdisc=$(tc qdisc show dev "$iface" 2>/dev/null | grep -c "qdisc" 2>/dev/null || echo "0")
    existing_qdisc=$(echo "$existing_qdisc" | tr -d '[:space:]' | head -c1)
    if [[ "$existing_qdisc" -gt 0 ]]; then
      log_warn "Обнаружены существующие tc правила на $iface"
      log_warn "Это может конфликтовать с traffic-shaping"
      # В dry-run режиме спрашиваем, в автоматическом — пропускаем
      if [[ "${DRY_RUN:-false}" == "true" ]]; then
        # Проверяем интерактивный режим через переменную окружения
        if [[ "${INTERACTIVE_MODE:-false}" == "true" && -t 0 ]]; then
          read -rp "  Продолжить? (y/n): " cont
          if [[ "$cont" != "y" && "$cont" != "Y" ]]; then
            log_info "Отмена установки traffic-shaping"
            return 1
          fi
        else
          log_info "Автоматический режим: продолжаем без подтверждения"
        fi
      else
        # Не dry-run — просто продолжаем
        log_info "Продолжаем с существующими правилами tc"
      fi
    fi
  fi

  return 0
}

ts_generate_profile() {
  # Проверяем совместимость перед генерацией
  if ! ts_check_compatibility; then
    log_warn "Совместимость не проверена, продолжаем с осторожностью"
  fi

  local iface
  iface=$(ip route show default | awk '/default/ {print $5}' | head -1)
  [[ -z "$iface" ]] && {
    log_error "Не удалось определить сетевой интерфейс"
    return 1
  }

  # Уникальный "почерк" — генерируется один раз, не меняется
  local jitter=$((RANDOM % 16 + 5))        # 5–20 мс
  local delay=$((RANDOM % 7 + 2))          # 2–8 мс
  local reorder_tenths=$((RANDOM % 5 + 1)) # 0.1–0.5%

  mkdir -p /etc/cubiveil
  cat >"$TS_CONFIG" <<EOF
{
  "interface":       "${iface}",
  "delay_ms":        ${delay},
  "jitter_ms":       ${jitter},
  "reorder_percent": "0.${reorder_tenths}",
  "generated_at":    "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  chmod 600 "$TS_CONFIG"
  log_info "Профиль TC: iface=${iface} delay=${delay}ms jitter=${jitter}ms reorder=0.${reorder_tenths}%"
}

# ── Скрипт применения tc-правил ─────────────────────────────────

ts_write_apply_script() {
  mkdir -p /usr/local/lib/cubiveil
  cat >"$TS_APPLY_SCRIPT" <<'SCRIPT'
#!/bin/bash
# CubiVeil tc-apply — вызывается systemd при каждой загрузке
set -euo pipefail

CONFIG="/etc/cubiveil/traffic-shaping.json"
[[ -f "$CONFIG" ]] || { echo "Конфиг не найден, пропуск"; exit 0; }

IFACE=$(jq   -r '.interface'        "$CONFIG")
DELAY=$(jq   -r '.delay_ms'         "$CONFIG")
JITTER=$(jq  -r '.jitter_ms'        "$CONFIG")
REORDER=$(jq -r '.reorder_percent'  "$CONFIG")

# Сброс перед применением — идемпотентно
tc qdisc del dev "$IFACE" root 2>/dev/null || true

tc qdisc add dev "$IFACE" root netem \
  delay "${DELAY}ms" "${JITTER}ms" \
  reorder "${REORDER}%" 50%

echo "[cubiveil-tc] ${IFACE}: delay=${DELAY}ms jitter=${JITTER}ms reorder=${REORDER}%"
SCRIPT
  chmod 750 "$TS_APPLY_SCRIPT"
}

# ── Systemd сервис ─────────────────────────────────────────────────

ts_write_systemd_service() {
  cat >"/etc/systemd/system/${TS_SERVICE}.service" <<EOF
[Unit]
Description=CubiVeil Traffic Shaping (tc/netem)
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=${TS_APPLY_SCRIPT}
ExecStop=/bin/bash -c \
  'tc qdisc del dev \$(jq -r .interface ${TS_CONFIG}) root 2>/dev/null || true'
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF
  chmod 644 "/etc/systemd/system/${TS_SERVICE}.service"
}
