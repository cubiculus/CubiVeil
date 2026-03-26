#!/bin/bash
# CubiVeil — Decoy Site: ротация файлов
# В прототипе таймер создаётся, но rotation.enabled = false
# Для включения: изменить поле в decoy.json и запустить module_enable()

# ── Подключение зависимостей / Dependencies ─────────────────
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

# ── Константы / Constants ───────────────────────────────────
DECOY_WEBROOT="/var/www/decoy"
DECOY_CONFIG="/etc/cubiveil/decoy.json"
DECOY_ROTATE_TIMER="cubiveil-decoy-rotate"

# ── Проверка условий для ротации ────────────────────────────

_decoy_can_rotate() {
  # Проверка load average — не ротировать под нагрузкой
  local load
  load=$(awk '{print $1}' /proc/loadavg 2>/dev/null | cut -d. -f1)
  if [[ "${load:-99}" -ge 2 ]]; then
    log_info "Ротация пропущена: load average ${load} >= 2"
    return 1
  fi

  # Проверка свободного места (минимум 200MB)
  local free_mb
  free_mb=$(df -m "${DECOY_WEBROOT}" 2>/dev/null | awk 'NR==2 {print $4}')
  if [[ "${free_mb:-0}" -lt 200 ]]; then
    log_info "Ротация пропущена: мало места (${free_mb}MB < 200MB)"
    return 1
  fi

  return 0
}

# ── Одна итерация ротации ────────────────────────────────────

decoy_rotate_once() {
  if ! _decoy_can_rotate; then
    return 0
  fi

  local files_per_cycle
  files_per_cycle=$(jq -r '.rotation.files_per_cycle' "$DECOY_CONFIG" 2>/dev/null || echo "1")
  local accent_color
  accent_color=$(jq -r '.accent_color' "$DECOY_CONFIG" 2>/dev/null || echo "#4a90d9")

  local replaced=0
  for _ in $(seq 1 "$files_per_cycle"); do
    # Выбираем случайный jpg для замены
    local old_file
    old_file=$(find "${DECOY_WEBROOT}/files" -name "*.jpg" 2>/dev/null | shuf -n1)
    if [[ -z "$old_file" ]]; then
      break
    fi

    # Генерируем новый файл
    local new_file seed
    new_file="${DECOY_WEBROOT}/files/$(gen_hex 8).jpg"
    seed=$(gen_hex 6)
    if convert -size 4000x3000 \
        "plasma:#${seed}-${accent_color:1}" \
        -quality 88 "$new_file" 2>/dev/null; then
      rm -f "$old_file"
      chown www-data:www-data "$new_file"
      chmod 644 "$new_file"
      replaced=$(( replaced + 1 ))
      log_info "Ротация: заменён $(basename "$old_file") → $(basename "$new_file")"
    fi
  done

  # Обновляем timestamp последней ротации
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local tmp_file="${DECOY_CONFIG}.tmp"
  if jq ".rotation.last_rotated_at = \"${timestamp}\"" "$DECOY_CONFIG" > "$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$DECOY_CONFIG"
    chmod 600 "$DECOY_CONFIG"
    log_info "Timestamp ротации обновлён: ${timestamp}"
  else
    rm -f "$tmp_file"
    log_warn "Не удалось обновить timestamp в decoy.json"
  fi

  log_success "Ротация завершена: заменено файлов ${replaced}"
}

# ── Systemd таймер ───────────────────────────────────────────

# Скрипт для systemd — обёртка для ротации
decoy_write_rotate_service() {
  cat > "/etc/systemd/system/${DECOY_ROTATE_TIMER}.service" <<EOF
[Unit]
Description=CubiVeil Decoy Site File Rotation
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/lib/cubiveil/decoy-rotate.sh
StandardOutput=journal
EOF
  chmod 644 "/etc/systemd/system/${DECOY_ROTATE_TIMER}.service"
}

# Скрипт применения ротации
decoy_write_rotate_script() {
  mkdir -p /usr/local/lib/cubiveil
  cat > "/usr/local/lib/cubiveil/decoy-rotate.sh" <<'SCRIPT'
#!/bin/bash
# CubiVeil decoy-rotate — вызывается systemd для ротации файлов
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_DIR="${SCRIPT_DIR}/lib/modules/decoy-site"

# Подключаем зависимости
if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi
if [[ -f "${MODULE_DIR}/rotate.sh" ]]; then
  source "${MODULE_DIR}/rotate.sh"
fi

# Запускаем ротацию
decoy_rotate_once
SCRIPT
  chmod 750 "/usr/local/lib/cubiveil/decoy-rotate.sh"
}

decoy_write_rotate_timer() {
  local interval_hours
  interval_hours=$(jq -r '.rotation.interval_hours' "$DECOY_CONFIG" 2>/dev/null || echo "3")

  # Создаём service и скрипт
  decoy_write_rotate_service
  decoy_write_rotate_script

  # Timer с рандомизацией ±30 мин для непредсказуемости
  cat > "/etc/systemd/system/${DECOY_ROTATE_TIMER}.timer" <<EOF
[Unit]
Description=CubiVeil Decoy Rotation Timer (~${interval_hours}h)

[Timer]
OnBootSec=10min
OnUnitActiveSec=${interval_hours}h
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
EOF

  chmod 644 "/etc/systemd/system/${DECOY_ROTATE_TIMER}.service"
  chmod 644 "/etc/systemd/system/${DECOY_ROTATE_TIMER}.timer"
  systemctl daemon-reload
  log_info "Таймер ротации создан (включён по умолчанию)"
}
