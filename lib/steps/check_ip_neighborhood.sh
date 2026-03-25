#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Check IP Neighborhood          ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Проверка IP-соседей на предмет VPN/хостинга            ║
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

# ── Функции / Functions ──────────────────────────────────────

# Проверка соседних IP адресов на VPN/хостинг
# Параметры: IP адрес сервера
check_ip_neighborhood_scan() {
  local SERVER_IP="$1"

  log_info "Scanning IP neighborhood for VPN/hosting servers..."

  # Определяем подсеть (первые 3 октета)
  local SUBNET
  SUBNET=$(echo "$SERVER_IP" | cut -d. -f1-3)

  # Параметры сканирования
  local CHECK_START=1
  local CHECK_END=10
  local STEP=1
  local MAX_CONCURRENT=5

  local VPN_COUNT=0
  local CHECKED=0

  # Время ожидания для curl (в секундах)
  local CURL_TIMEOUT=5

  # Задержка между запусками пакетов (сек)
  local RATE_DELAY=0.2

  # Параллельная проверка IP с rate limiting
  local temp_dir
  temp_dir=$(create_temp_dir "ip-check")
  local pids=()
  local batch_count=0

  for i in $(seq "$CHECK_START" "$STEP" "$CHECK_END"); do
    local CHECK_IP="${SUBNET}.${i}"
    [[ "$CHECK_IP" == "$SERVER_IP" ]] && continue

    # Rate limiting: ограничиваем количество одновременных запросов
    if [[ $batch_count -ge $MAX_CONCURRENT ]]; then
      # Ждём завершения oldest процесса в пакете
      wait "${pids[0]}" 2>/dev/null || true
      pids=("${pids[@]:1}")  # сдвигаем массив
      batch_count=0
      # Небольшая задержка между пакетами запросов
      sleep "$RATE_DELAY"
    fi

    # Запуск фонового процесса с улучшенными timeout
    {
      local RESULT ORG
      RESULT=$(curl -s $CURL_TIMEOUT "https://ipinfo.io/${CHECK_IP}/json" 2>/dev/null || echo "")
      if echo "$RESULT" | grep -qi '"org"'; then
        ORG=$(echo "$RESULT" | grep '"org"' | sed 's/.*"org": *"\(.*\)".*/\1/' | tr '[:upper:]' '[:lower:]')
        if echo "$ORG" | grep -qiE 'vpn|proxy|tunnel|hosting|datacenter|vps|server|cloud'; then
          echo "VPN" >"${temp_dir}/${i}.txt"
        fi
      fi
    } &
    pids+=($!)
    ((batch_count++)) || true
  done

  # Ожидание завершения всех оставшихся фоновых процессов
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  # Подсчет результатов
  for i in $(seq "$CHECK_START" "$STEP" "$CHECK_END"); do
    local CHECK_IP="${SUBNET}.${i}"
    [[ "$CHECK_IP" == "$SERVER_IP" ]] && continue
    if [[ -f "${temp_dir}/${i}.txt" ]]; then
      ((VPN_COUNT++)) || true
    fi
    ((CHECKED++)) || true
  done

  # Очистка временных файлов
  cleanup_temp_dir "$temp_dir"

  echo "$VPN_COUNT:$CHECKED"
}

# Форматирование результата проверки
check_ip_neighborhood_format() {
  local result="$1"
  local VPN_COUNT CHECKED

  VPN_COUNT=$(echo "$result" | cut -d: -f1)
  CHECKED=$(echo "$result" | cut -d: -f2)

  echo ""

  if [[ $VPN_COUNT -eq 0 ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      ok "В ${CHECKED} проверенных соседних IP — 0 VPN/хостинг серверов. Подсеть чистая ✓"
    else
      ok "$OK_SUBNET_CLEAN"
    fi
  elif [[ $VPN_COUNT -le 3 ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Обнаружено ${VPN_COUNT} VPN/хостинг серверов в ${CHECKED} проверенных IP — риск умеренный"
      warn "Совет: следи за стабильностью, при проблемах смени провайдера"
    else
      warn "$WARN_SUBNET_MODERATE"
      warn "$WARN_SUBNET_ADVICE"
    fi
  else
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Обнаружено ${VPN_COUNT} VPN/хостинг серверов в ${CHECKED} проверенных IP — риск ВЫСОКИЙ"
      warn "Подсеть скорее всего хорошо известна системам блокировок."
      warn "Рекомендуется сменить провайдера или запросить IP из другого диапазона."
    else
      warn "$WARN_SUBNET_HIGH"
      warn "$WARN_SUBNET_LIKELY_BLOCKED"
      warn "$WARN_SUBNET_RECOMMEND"
    fi
    echo ""

    local prompt_continue
    if [[ "$LANG_NAME" == "Русский" ]]; then
      prompt_continue="  Продолжить установку несмотря на предупреждение? (y/n): "
    else
      prompt_continue="  $WARN_CONTINUE_ANYWAY "
    fi

    read -rp "$prompt_continue" CONTINUE_ANYWAY
    [[ "$CONTINUE_ANYWAY" != "y" && "$CONTINUE_ANYWAY" != "Y" ]] &&
      { if [[ "$LANG_NAME" == "Русский" ]]; then err "$ERR_USER_ABORTED_RU"; else err "$ERR_USER_ABORTED"; fi; }
  fi
  echo ""
}

# Основная функция шага (вызывается из install-steps.sh)
step_check_ip_neighborhood() {
  step_title "1" "Проверка IP-соседей" "Check IP neighborhood"

  local result
  result=$(check_ip_neighborhood_scan "$SERVER_IP")

  check_ip_neighborhood_format "$result"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { :; }
module_configure() { step_check_ip_neighborhood; }
module_enable() { :; }
module_disable() { :; }
