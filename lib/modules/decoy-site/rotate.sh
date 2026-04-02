#!/bin/bash
# shellcheck disable=SC1071
# CubiVeil — Decoy Site: ротация файлов
# В прототипе таймер создаётся, но rotation.enabled = false
# Для включения: изменить поле в decoy.json и запустить module_enable()

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
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# ── Константы / Constants ───────────────────────────────────
# Пути по умолчанию могут быть переопределены через переменные окружения
DECOY_WEBROOT="${DECOY_WEBROOT:-/var/www/decoy}"
DECOY_CONFIG="${DECOY_CONFIG:-/etc/cubiveil/decoy.json}"
DECOY_ROTATE_TIMER="cubiveil-decoy-rotate"

# В тестовом режиме используем временные директории
if [[ "${TEST_MODE:-false}" == "true" ]]; then
  if [[ -z "$TEST_DECOY_DIR" ]]; then
    TEST_DECOY_DIR="/tmp/test-decoy-$$"
  fi
  mkdir -p "$TEST_DECOY_DIR"
  DECOY_WEBROOT="${TEST_DECOY_DIR}/webroot"
  DECOY_CONFIG="${TEST_DECOY_DIR}/decoy.json"
fi

# ── Утилиты / Utilities ─────────────────────────────────────

# Генерация случайного числа в диапазоне [min, max]
gen_range() {
  local min="$1"
  local max="$2"
  echo $((min + RANDOM % (max - min + 1)))
}

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

# ── Управление размером директории ──────────────────────────

# Получить общий размер директории в MB
_decoy_get_total_size_mb() {
  local total_kb
  total_kb=$(du -sk "${DECOY_WEBROOT}/files" 2>/dev/null | cut -f1)
  echo $((${total_kb:-0} / 1024))
}

# Получить максимальный размер из конфигурации
_decoy_get_max_size_mb() {
  jq -r '.max_total_files_mb // 5000' "$DECOY_CONFIG" 2>/dev/null || echo "5000"
}

# Удалить старые файлы, если размер превышает лимит
_decoy_enforce_size_limit() {
  local max_size_mb current_size_mb
  max_size_mb=$(_decoy_get_max_size_mb)
  current_size_mb=$(_decoy_get_total_size_mb)

  if [[ "${current_size_mb}" -le "${max_size_mb}" ]]; then
    log_info "Размер директории: ${current_size_mb}MB / ${max_size_mb}MB (в норме)"
    return 0
  fi

  log_warn "Превышен лимит размера: ${current_size_mb}MB > ${max_size_mb}MB"
  log_info "Начинаю удаление старых файлов..."

  local deleted_count=0
  local freed_mb=0

  # Удаляем файлы по одному (самые старые по mtime), пока не войдём в лимит
  while [[ "${current_size_mb}" -gt "${max_size_mb}" ]]; do
    # Находим самый старый файл
    local oldest_file
    oldest_file=$(find "${DECOY_WEBROOT}/files" -type f -printf '%T+ %p\n' 2>/dev/null |
      sort | head -n1 | cut -d' ' -f2-)

    if [[ -z "$oldest_file" || ! -f "$oldest_file" ]]; then
      log_warn "Нет файлов для удаления, но лимит всё ещё превышен"
      break
    fi

    # Получаем размер файла перед удалением
    local file_size_mb
    file_size_mb=$(du -m "$oldest_file" 2>/dev/null | cut -f1)
    file_size_mb=${file_size_mb:-0}

    # Удаляем файл
    rm -f "$oldest_file"
    deleted_count=$((deleted_count + 1))
    freed_mb=$((freed_mb + file_size_mb))

    log_info "Удалён старый файл: $(basename "$oldest_file") (${file_size_mb}MB)"

    # Пересчитываем размер
    current_size_mb=$(_decoy_get_total_size_mb)
  done

  log_success "Очистка завершена: удалено файлов ${deleted_count}, освобождено ~${freed_mb}MB"
  log_info "Текущий размер: ${current_size_mb}MB / ${max_size_mb}MB"
}

# ── Одна итерация ротации ────────────────────────────────────

# Сгенерировать новый файл указанного типа
_generate_rotated_file() {
  local file_type="$1"
  local target_dir="${DECOY_WEBROOT}/files"
  local accent_color
  accent_color=$(jq -r '.accent_color' "$DECOY_CONFIG" 2>/dev/null || echo "#4a90d9")

  local fname new_file seed
  fname="$(gen_hex 8).${file_type}"
  new_file="${target_dir}/${fname}"

  case "$file_type" in
  jpg)
    seed=$(gen_hex 6)
    if command -v convert &>/dev/null; then
      convert -size 4000x3000 \
        "plasma:#${seed}-${accent_color:1}" \
        -quality 88 "$new_file" 2>/dev/null && echo "$new_file" && return 0
    fi
    # Fallback
    local size
    size=$(gen_range 5 15)
    dd if=/dev/urandom of="$new_file" bs=1M count="$size" status=none 2>/dev/null && echo "$new_file"
    ;;
  pdf)
    # Минимальный PDF + случайные данные
    local target_size
    target_size=$(jq -r ".rotation.types.pdf.size_min_mb // 50" "$DECOY_CONFIG" 2>/dev/null || echo "50")
    {
      printf '%%PDF-1.4\n'
      printf '1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
      printf '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
      printf '3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R>>endobj\n'
      printf 'xref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n193\n%%%%EOF\n'
    } >"$new_file"
    dd if=/dev/urandom bs=1M count="$target_size" status=none >>"$new_file" 2>/dev/null && echo "$new_file"
    ;;
  mp4)
    # Заглушка MP4 + случайные данные
    local target_size
    target_size=$(jq -r ".rotation.types.mp4.size_min_mb // 100" "$DECOY_CONFIG" 2>/dev/null || echo "100")
    printf '\x00\x00\x00\x1cftypisom\x00\x00\x02\x00isomiso2mp41' >"$new_file"
    dd if=/dev/urandom bs=1M count="$target_size" status=none >>"$new_file" 2>/dev/null && echo "$new_file"
    ;;
  mp3)
    # Заглушка MP3 + случайные данные
    local target_size
    target_size=$(jq -r ".rotation.types.mp3.size_min_mb // 10" "$DECOY_CONFIG" 2>/dev/null || echo "10")
    printf 'ID3\x03\x00\x00\x00\x00\x00\x00' >"$new_file"
    dd if=/dev/urandom bs=1M count="$target_size" status=none >>"$new_file" 2>/dev/null && echo "$new_file"
    ;;
  *)
    return 1
    ;;
  esac
}

# Выбрать тип файла для ротации на основе весов
_select_file_type() {
  local types_json
  types_json=$(jq -r '.rotation.types // {}' "$DECOY_CONFIG" 2>/dev/null)

  # Собрать включённые типы с их весами
  local enabled_types=()
  local total_weight=0

  for type in jpg pdf mp4 mp3; do
    local enabled weight
    enabled=$(echo "$types_json" | jq -r ".${type}.enabled // false" 2>/dev/null)
    weight=$(echo "$types_json" | jq -r ".${type}.weight // 1" 2>/dev/null)

    if [[ "$enabled" == "true" && "$weight" -gt 0 ]]; then
      enabled_types+=("$type")
      # Добавляем тип в массив weight раз
      for ((i = 0; i < weight; i++)); do
        total_weight=$((total_weight + 1))
      done
    fi
  done

  if [[ ${#enabled_types[@]} -eq 0 ]]; then
    echo "jpg" # Fallback
    return
  fi

  # Выбрать случайный тип на основе весов
  local rand_idx
  rand_idx=$((RANDOM % total_weight))

  local current_weight=0
  for type in "${enabled_types[@]}"; do
    local weight
    weight=$(echo "$types_json" | jq -r ".${type}.weight // 1" 2>/dev/null)
    current_weight=$((current_weight + weight))
    if [[ $rand_idx -lt $current_weight ]]; then
      echo "$type"
      return
    fi
  done

  echo "${enabled_types[0]}"
}

# Ротировать файл одного типа
_rotate_files_by_type() {
  local file_type="$1"
  local files_per_cycle="$2"
  local accent_color
  accent_color=$(jq -r '.accent_color' "$DECOY_CONFIG" 2>/dev/null || echo "#4a90d9")

  local replaced=0
  for _ in $(seq 1 "$files_per_cycle"); do
    # Выбираем случайный файл указанного типа для замены
    local old_file
    old_file=$(find "${DECOY_WEBROOT}/files" -name "*.${file_type}" 2>/dev/null | shuf -n1)
    if [[ -z "$old_file" ]]; then
      log_warn "Нет файлов типа .${file_type} для ротации"
      break
    fi

    # Генерируем новый файл
    local new_file
    new_file=$(_generate_rotated_file "$file_type")
    if [[ -n "$new_file" && -f "$new_file" ]]; then
      rm -f "$old_file"
      chown www-data:www-data "$new_file"
      chmod 644 "$new_file"
      replaced=$((replaced + 1))
      log_info "Ротация [${file_type}]: заменён $(basename "$old_file") → $(basename "$new_file")"
    fi
  done

  echo "$replaced"
}

# Основная функция ротации — ротирует все типы файлов
decoy_rotate_once() {
  if ! _decoy_can_rotate; then
    return 0
  fi

  local files_per_cycle
  files_per_cycle=$(jq -r '.rotation.files_per_cycle' "$DECOY_CONFIG" 2>/dev/null || echo "1")

  # Выбрать тип файла для этой итерации ротации
  local file_type
  file_type=$(_select_file_type)

  log_info "Начало ротации: тип=${file_type}, файлов=${files_per_cycle}"

  # Ротировать файлы выбранного типа
  local replaced
  replaced=$(_rotate_files_by_type "$file_type" "$files_per_cycle")

  # Обновляем timestamp последней ротации
  local timestamp
  timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local tmp_file="${DECOY_CONFIG}.tmp"
  if jq ".rotation.last_rotated_at = \"${timestamp}\"" "$DECOY_CONFIG" >"$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$DECOY_CONFIG"
    chmod 600 "$DECOY_CONFIG"
    log_info "Timestamp ротации обновлён: ${timestamp}"
  else
    rm -f "$tmp_file"
    log_warn "Не удалось обновить timestamp в decoy.json"
  fi

  log_success "Ротация завершена: заменено файлов ${replaced} (тип: ${file_type})"

  # Проверка и соблюдение лимита размера после ротации
  _decoy_enforce_size_limit
}

# ── Systemd таймер ───────────────────────────────────────────

# Скрипт для systemd — обёртка для ротации
decoy_write_rotate_service() {
  cat >"/etc/systemd/system/${DECOY_ROTATE_TIMER}.service" <<EOF
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
  cat >"/usr/local/lib/cubiveil/decoy-rotate.sh" <<'SCRIPT'
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
  cat >"/etc/systemd/system/${DECOY_ROTATE_TIMER}.timer" <<EOF
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
