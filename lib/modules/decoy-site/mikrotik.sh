#!/bin/bash
# CubiVeil — Decoy Site: генерация скрипта для MikroTik RouterOS
# Читает параметры из decoy.json
# Вызывается из step_finish()

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
DECOY_WEBROOT="/var/www/decoy"
DECOY_CONFIG="/etc/cubiveil/decoy.json"

# ── Генерация блока сессий для одного scheduler ─────────────

_generate_session_block() {
  local window_name="$1"
  local session_count="$2"
  local speed_bps="$3"
  local files=("$4") # массив файлов

  for i in $(seq 1 "$session_count"); do
    local action_type=$((RANDOM % 100))
    local delay=$((RANDOM % 40 + 5)) # 5-45 секунд между запросами

    # HEAD запрос (15% шанс)
    if [[ $action_type -lt 15 ]]; then
      echo "  :delay ${delay}s"
      echo "  /tool fetch url=\"https://${DOMAIN}/\" mode=keep-result=no"

    # Намеренный 404 (8% шанс)
    elif [[ $action_type -lt 23 ]]; then
      local fake_path
      fake_path="$(gen_hex 8)"
      echo "  :delay ${delay}s"
      echo "  /tool fetch url=\"https://${DOMAIN}/files/${fake_path}\" \
        dst-path=\"/cv-tmp-${window_name}-${i}.bin\" \
        limit-bytes-per-second=${speed_bps} \
        keep-result=no"

    # GET файл (77% шанс)
    else
      local file
      file="${files[$((RANDOM % ${#files[@]}))]}"
      echo "  :delay ${delay}s"
      echo "  /tool fetch url=\"https://${DOMAIN}/files/${file}\" \
        dst-path=\"/cv-tmp-${window_name}-${i}.bin\" \
        limit-bytes-per-second=${speed_bps} \
        keep-result=no"
    fi
  done
}

# ── Генерация скрипта MikroTik ─────────────────────────────────

decoy_print_mikrotik_script() {
  # Читаем параметры поведения из decoy.json
  local speed_min session_files
  speed_min=$(jq -r '.behavior.speed_kbps_min' "$DECOY_CONFIG" 2>/dev/null || echo "200")
  session_files=$(jq -r '.behavior.session_files' "$DECOY_CONFIG" 2>/dev/null || echo "3")

  # Получаем список файлов из webroot
  local files=()
  mapfile -t files < <(ls "${DECOY_WEBROOT}/files/" 2>/dev/null)
  local fcount="${#files[@]}"

  if [[ "$fcount" -eq 0 ]]; then
    log_error "Нет файлов в ${DECOY_WEBROOT}/files/ — сначала запусти module_configure"
    return 1
  fi

  # Временны́е окна из decoy.json
  # morning: 07–09, day: 12–15, evening: 18–23
  # Случайные минуты внутри окна для непредсказуемости
  local m_morning=$((RANDOM % 59))
  local m_day=$((RANDOM % 59))
  local m_evening=$((RANDOM % 59))
  local h_morning=$((RANDOM % 3 + 7))  # 7, 8 или 9
  local h_day=$((RANDOM % 4 + 12))     # 12–15
  local h_evening=$((RANDOM % 6 + 18)) # 18–23

  # Форматируем время для RouterOS: HH:MM:00
  local t_morning t_day t_evening
  printf -v t_morning "%02d:%02d:00" "$h_morning" "$m_morning"
  printf -v t_day "%02d:%02d:00" "$h_day" "$m_day"
  printf -v t_evening "%02d:%02d:00" "$h_evening" "$m_evening"

  # limit-bytes-per-second для RouterOS (переводим KB/s → bytes/s)
  local speed_bps=$((speed_min * 1024))

  # Генерируем блоки сессий для каждого окна
  local session_block_morning session_block_day session_block_evening
  session_block_morning=$(_generate_session_block "morning" "$session_files" "$speed_bps" "${files[*]}")
  session_block_day=$(_generate_session_block "day" "$session_files" "$speed_bps" "${files[*]}")
  session_block_evening=$(_generate_session_block "evening" "$session_files" "$speed_bps" "${files[*]}")

  cat <<MIKROTIK
# ══════════════════════════════════════════════════════════════
# CubiVeil — MikroTik RouterOS скрипт имитации трафика
# Вставить в Terminal роутера целиком (Ctrl+V или New Terminal)
# Домен: ${DOMAIN}
# Окна активности: утро(${t_morning}), день(${t_day}), вечер(${t_evening})
# Сессий за запуск: ${session_files} (3-7 fetch/HEAD/404)
# ══════════════════════════════════════════════════════════════

/system scheduler

# Утреннее окно (${t_morning})
add name="cv-morning" \
  start-time=${t_morning} \
  interval=24:00:00 \
  on-event="{
${session_block_morning}
  }" \
  comment="CubiVeil decoy morning" \
  disabled=no

# Дневное окно (${t_day})
add name="cv-day" \
  start-time=${t_day} \
  interval=24:00:00 \
  on-event="{
${session_block_day}
  }" \
  comment="CubiVeil decoy day" \
  disabled=no

# Вечернее окно (${t_evening})
add name="cv-evening" \
  start-time=${t_evening} \
  interval=24:00:00 \
  on-event="{
${session_block_evening}
  }" \
  comment="CubiVeil decoy evening" \
  disabled=no

# Ежедневная очистка временных файлов
add name="cv-cleanup" \
  start-time=03:00:00 \
  interval=24:00:00 \
  on-event="/file remove [/file find name~\"cv-tmp\"]" \
  comment="CubiVeil decoy cleanup" \
  disabled=no

# ══════════════════════════════════════════════════════════════
# Проверка: /system scheduler print
# Удаление:  /system scheduler remove [/system scheduler find comment~"CubiVeil"]
# ══════════════════════════════════════════════════════════════
MIKROTIK
}

# Сохранение MikroTik скрипта в файл
decoy_save_mikrotik_script() {
  local output_file="${1:-/etc/cubiveil/mikrotik-decoy.rsc}"

  # Генерируем скрипт и сохраняем в файл
  {
    echo "# ══════════════════════════════════════════════════════════════"
    echo "# CubiVeil — MikroTik RouterOS Traffic Imitation Script"
    echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Domain: ${DOMAIN}"
    echo "# ══════════════════════════════════════════════════════════════"
    echo ""
    decoy_print_mikrotik_script
  } >"$output_file"

  chmod 644 "$output_file" 2>/dev/null || true
  log_info "MikroTik script saved to: $output_file"
}
