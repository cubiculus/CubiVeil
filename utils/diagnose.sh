#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Diagnose Utility                     ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                          ║
# ║  Диагностика проблем и сбор информации для поддержки     ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
if [[ -f "${PROJECT_DIR}/lang.sh" ]]; then
  source "${PROJECT_DIR}/lang.sh"
else
  source "${PROJECT_DIR}/lib/fallback.sh"
fi

# ── Подключение унифицированных функций вывода ───────────────
source "${PROJECT_DIR}/lib/output.sh" || {
  echo "❌ Не удалось загрузить lib/output.sh" >&2
  exit 1
}

# ── Подключение общих утилит ───────────────────────────────────
source "${PROJECT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}

# ── Константы ─────────────────────────────────────────────────
MARZBAN_DIR="/opt/marzban"
SINGBOX_DIR="/etc/sing-box"
DIAGNOSE_DIR="/root/cubiveil-diagnose"
HEALTH_CHECK_PORT=""

# ── Локализация сообщений ─────────────────────────────────────
declare -A MSG=(
  [TITLE_DIAGNOSE]="CubiVeil — Diagnostics"
  [TITLE_DNS]="Проверка DNS"
  [TITLE_SSL]="Проверка SSL сертификата"
  [TITLE_CONNECTION]="Проверка соединений"
  [TITLE_SERVICES]="Проверка сервисов"
  [TITLE_PORTS]="Проверка портов"
  [TITLE_LOGS]="Анализ логов"
  [TITLE_REPORT]="Сбор отчёта"
  [TITLE_FIX]="Рекомендации"

  [MSG_DIAGNOSING]="Диагностика..."
  [MSG_CHECKING]="Проверка..."
  [MSG_OK]="OK"
  [MSG_FAIL]="FAIL"
  [MSG_WARNING]="WARNING"
  [MSG_SKIPPED]="SKIPPED"

  [MSG_DNS_RESOLVE]="Разрешение имён"
  [MSG_DNS_SERVER]="DNS сервер"
  [MSG_SSL_VALID]="Сертификат валиден"
  [MSG_SSL_EXPIRED]="Сертификат истёк"
  [MSG_SSL_DAYS]="Дней до истечения"
  [MSG_PORT_OPEN]="Порт открыт"
  [MSG_PORT_CLOSED]="Порт закрыт"
  [MSG_SERVICE_ACTIVE]="Сервис активен"
  [MSG_SERVICE_INACTIVE]="Сервис неактивен"
  [MSG_CONNECTION_OK]="Соединение установлено"
  [MSG_CONNECTION_FAIL]="Соединение не установлено"

  [ERR_NOT_ROOT]="Требуется запуск от root"
  [ERR_DIAGNOSE_FAILED]="Диагностика завершена с ошибками"

  [FIX_RESTART_SERVICE]="Перезапустить сервис"
  [FIX_CHECK_FIREWALL]="Проверить файрвол"
  [FIX_RENEW_SSL]="Обновить SSL сертификат"
  [FIX_CHECK_DNS]="Проверить DNS настройки"
  [FIX_CHECK_DISK]="Очистить место на диске"
  [FIX_CHECK_RAM]="Освободить память"
)

msg() {
  local key="$1"
  local default="${2:-}"
  echo "${MSG[$key]:-$default}"
}

step_title() {
  local step="$1"
  local ru="$2"
  local en="$3"
  echo ""
  echo "══════════════════════════════════════════════════════════"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "  ${step}. ${ru}"
  else
    echo "  ${step}. ${en}"
  fi
  echo "══════════════════════════════════════════════════════════"
}

# ══════════════════════════════════════════════════════════════
# Переменные для сбора статистики
# ══════════════════════════════════════════════════════════════

declare -A DIAGNOSE_RESULTS
DIAGNOSE_ISSUES=()

# ══════════════════════════════════════════════════════════════
# ШАГ 1: Проверка окружения
# ══════════════════════════════════════════════════════════════

step_check_environment() {
  step_title "1" "Проверка окружения" "Environment check"

  if [[ $EUID -ne 0 ]]; then
    err "${MSG[ERR_NOT_ROOT]}"
  fi

  mkdir -p "${DIAGNOSE_DIR}"

  success "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Проверка DNS
# ══════════════════════════════════════════════════════════════

step_check_dns() {
  step_title "2" "${MSG[TITLE_DNS]}" "DNS check"

  local issues=0

  # Проверка разрешения имён
  info "${MSG[MSG_DNS_RESOLVE]}..."

  local test_domains=("google.com" "github.com" "api4.ipify.org")
  for domain in "${test_domains[@]}"; do
    if dig +short "$domain" &>/dev/null || nslookup "$domain" &>/dev/null || host "$domain" &>/dev/null; then
      success "  ✓ ${domain}"
    else
      # Пробуем альтернативу
      if curl -sf --max-time 5 "https://${domain}" &>/dev/null; then
        success "  ✓ ${domain} (через curl)"
      else
        warning "  ✗ ${domain}"
        ((issues++))
      fi
    fi
  done

  # Проверка DNS серверов
  info "${MSG[MSG_DNS_SERVER]}..."
  local dns_servers
  dns_servers=$(grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ' || echo "N/A")
  info "  DNS: ${dns_servers}"

  # Проверка на DNS leak (если есть утечка через IPv6)
  local ipv6_enabled
  if [[ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]]; then
    ipv6_enabled=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
    if [[ "$ipv6_enabled" == "0" ]]; then
      info "  IPv6: включён"
    else
      info "  IPv6: отключён"
    fi
  fi

  DIAGNOSE_RESULTS[dns]=$([[ $issues -eq 0 ]] && echo "OK" || echo "ISSUES")

  if [[ $issues -gt 0 ]]; then
    DIAGNOSE_ISSUES+=("${MSG[FIX_CHECK_DNS]}")
    warning "${MSG[TITLE_DNS]}: ${issues} проблем"
  else
    success "${MSG[TITLE_DNS]}: OK"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Проверка SSL сертификата
# ══════════════════════════════════════════════════════════════

step_check_ssl() {
  step_title "3" "${MSG[TITLE_SSL]}" "SSL certificate check"

  local domain=""
  local cert_path=""
  local days_until_expiry=0
  local is_valid=false

  # Ищем домен в конфиге Marzban
  if [[ -f "${MARZBAN_DIR}/.env" ]]; then
    domain=$(grep -E "^XRAY_SUBSCRIPTION_URL_PREFIX=" "${MARZBAN_DIR}/.env" 2>/dev/null | \
      sed 's/.*https:\/\/\([^/]*\).*/\1/' | head -1 || echo "")

    if [[ -z "$domain" ]]; then
      domain=$(grep -E "^MARZBAN_HOST=" "${MARZBAN_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "")
    fi
  fi

  # Ищем сертификат
  if [[ -n "$domain" ]] && [[ -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ]]; then
    cert_path="/etc/letsencrypt/live/${domain}/fullchain.pem"
  elif [[ -f "${SINGBOX_DIR}/cert.pem" ]]; then
    cert_path="${SINGBOX_DIR}/cert.pem"
  elif [[ -f "${MARZBAN_DIR}/cert.pem" ]]; then
    cert_path="${MARZBAN_DIR}/cert.pem"
  fi

  if [[ -n "$cert_path" ]] && [[ -f "$cert_path" ]]; then
    info "Сертификат: ${cert_path}"

    # Проверяем срок действия
    local expiry_date
    expiry_date=$(openssl x509 -in "$cert_path" -noout -enddate 2>/dev/null | cut -d= -f2 || echo "")

    if [[ -n "$expiry_date" ]]; then
      local expiry_epoch current_epoch
      expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
      current_epoch=$(date +%s)
      days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))

      info "${MSG[MSG_SSL_DAYS]}: ${days_until_expiry}"

      if [[ $days_until_expiry -gt 30 ]]; then
        success "${MSG[MSG_SSL_VALID]}"
        is_valid=true
      elif [[ $days_until_expiry -gt 0 ]]; then
        warning "${MSG[MSG_SSL_VALID]} (истекает скоро)"
        is_valid=true
        DIAGNOSE_ISSUES+=("${MSG[FIX_RENEW_SSL]}")
      else
        warning "${MSG[MSG_SSL_EXPIRED]}"
        DIAGNOSE_ISSUES+=("${MSG[FIX_RENEW_SSL]}")
      fi
    fi
  else
    info "SSL сертификат не найден (возможно используется Let's Encrypt)"

    # Проверяем через curl с доменом
    if [[ -n "$domain" ]]; then
      if curl -sfk --max-time 10 "https://${domain}" &>/dev/null; then
        success "HTTPS соединение с ${domain} работает"
        is_valid=true
      else
        warning "HTTPS соединение с ${domain} не установлено"
      fi
    fi
  fi

  DIAGNOSE_RESULTS[ssl]=$([[ "$is_valid" == "true" ]] && echo "OK" || echo "ISSUES")
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Проверка соединений
# ══════════════════════════════════════════════════════════════

step_check_connections() {
  step_title "4" "${MSG[TITLE_CONNECTION]}" "Connection check"

  local issues=0

  # Проверка внешнего соединения
  info "Проверка интернет-соединения..."

  if curl -sf --max-time 10 https://www.google.com &>/dev/null; then
    success "  ✓ Интернет-соединение"
  elif curl -sf --max-time 10 https://8.8.8.8 &>/dev/null; then
    success "  ✓ Интернет-соединение (через IP)"
  else
    warning "  ✗ Интернет-соединение"
    ((issues++))
    DIAGNOSE_ISSUES+=("Проверить сетевое подключение")
  fi

  # Проверка доступности API Telegram (если установлен бот)
  if systemctl is-active --quiet cubiveil-bot 2>/dev/null; then
    info "Проверка соединения с Telegram..."
    if curl -sf --max-time 10 https://api.telegram.org &>/dev/null; then
      success "  ✓ Telegram API"
    else
      warning "  ✗ Telegram API"
      ((issues++))
      DIAGNOSE_ISSUES+=("Проверить доступность Telegram")
    fi
  fi

  # Проверка health check endpoint
  info "Проверка health check..."

  # Находим порт health check
  if [[ -f "${MARZBAN_DIR}/.env" ]]; then
    HEALTH_CHECK_PORT=$(grep -E "^HEALTH_CHECK_PORT=" "${MARZBAN_DIR}/.env" 2>/dev/null | cut -d'=' -f2 || echo "")
  fi

  if [[ -n "$HEALTH_CHECK_PORT" ]]; then
    if curl -sf --max-time 5 "http://localhost:${HEALTH_CHECK_PORT}/health" &>/dev/null; then
      success "  ✓ Health check (порт ${HEALTH_CHECK_PORT})"
    else
      warning "  ✗ Health check не отвечает"
      ((issues++))
    fi
  else
    info "  Health check порт не найден"
  fi

  DIAGNOSE_RESULTS[connections]=$([[ $issues -eq 0 ]] && echo "OK" || echo "ISSUES")
}

# ══════════════════════════════════════════════════════════════
# ШАГ 5: Проверка сервисов
# ══════════════════════════════════════════════════════════════

step_check_services() {
  step_title "5" "${MSG[TITLE_SERVICES]}" "Services check"

  local services=("marzban" "sing-box" "cubiveil-bot" "ufw" "fail2ban")
  local issues=0

  for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
      success "  ✓ ${service} — ${MSG[MSG_SERVICE_ACTIVE]}"
    elif systemctl list-unit-files "$service" &>/dev/null; then
      warning "  ✗ ${service} — ${MSG[MSG_SERVICE_INACTIVE]}"
      ((issues++))
      DIAGNOSE_ISSUES+=("${MSG[FIX_RESTART_SERVICE]}: ${service}")
    else
      info "  ○ ${service} — не установлен"
    fi
  done

  # Проверка логов на ошибки
  info "Проверка логов на ошибки..."
  for service in "marzban" "sing-box"; do
    local error_count
    error_count=$(journalctl -u "$service" --since "1 hour ago" 2>/dev/null | \
      grep -ciE "(error|fail|critical)" || echo "0")

    if [[ "$error_count" -gt 10 ]]; then
      warning "  ⚠️  ${service}: ${error_count} ошибок за последний час"
    else
      info "  ✓ ${service}: ${error_count} ошибок за последний час"
    fi
  done

  DIAGNOSE_RESULTS[services]=$([[ $issues -eq 0 ]] && echo "OK" || echo "ISSUES")
}

# ══════════════════════════════════════════════════════════════
# ШАГ 6: Проверка портов
# ══════════════════════════════════════════════════════════════

step_check_ports() {
  step_title "6" "${MSG[TITLE_PORTS]}" "Ports check"

  local issues=0

  # Ожидаемые порты
  local expected_ports=(443)

  # Добавляем порты из конфига
  if [[ -f "${MARZBAN_DIR}/.env" ]]; then
    local config_ports
    config_ports=$(grep -oE "PORT=[0-9]+" "${MARZBAN_DIR}/.env" 2>/dev/null | cut -d= -f2 || echo "")
    for port in $config_ports; do
      expected_ports+=("$port")
    done
  fi

  info "Проверка ожидаемых портов..."

  for port in "${expected_ports[@]}"; do
    if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
      success "  ✓ Порт ${port} открыт"
    else
      warning "  ✗ Порт ${port} закрыт"
      ((issues++))
    fi
  done

  # Проверка на неожиданные открытые порты
  info "Сканирование открытых портов..."
  local open_ports
  open_ports=$(ss -tlnp 2>/dev/null | awk 'NR>1 {print $4}' | grep -oE ':[0-9]+' | cut -d: -f2 | sort -u | tr '\n' ' ' || echo "N/A")
  info "  Открытые порты: ${open_ports}"

  DIAGNOSE_RESULTS[ports]=$([[ $issues -eq 0 ]] && echo "OK" || echo "ISSUES")

  if [[ $issues -gt 0 ]]; then
    DIAGNOSE_ISSUES+=("${MSG[FIX_CHECK_FIREWALL]}")
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 7: Анализ логов
# ══════════════════════════════════════════════════════════════

step_analyze_logs() {
  step_title "7" "${MSG[TITLE_LOGS]}" "Log analysis"

  # Собираем последние ошибки
  info "Сбор последних ошибок..."

  local log_file="${DIAGNOSE_DIR}/recent_errors.log"

  {
    echo "=== Recent Errors ==="
    echo "Generated: $(date -Iseconds)"
    echo ""

    for service in "marzban" "sing-box" "cubiveil-bot"; do
      echo "=== ${service} ==="
      journalctl -u "$service" --since "24 hours ago" --priority=err --no-pager 2>/dev/null | tail -20 || echo "No errors"
      echo ""
    done
  } > "$log_file"

  local error_count
  error_count=$(wc -l < "$log_file" || echo "0")
  info "Собрано строк логов: ${error_count}"

  # Проверка места под логи
  local journal_size
  journal_size=$(journalctl --disk-usage 2>/dev/null | awk '{print $2, $3}' || echo "N/A")
  info "Размер логов journalctl: ${journal_size}"

  DIAGNOSE_RESULTS[logs]="OK"
  success "Логи сохранены в: ${log_file}"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 8: Проверка ресурсов
# ══════════════════════════════════════════════════════════════

step_check_resources() {
  step_title "8" "Проверка ресурсов" "Resource check"

  local issues=0

  # Проверка диска
  local disk_usage
  disk_usage=$(df / 2>/dev/null | tail -1 | awk '{print $5}' | tr -d '%')

  if [[ "$disk_usage" -gt 90 ]]; then
    warning "  ✗ Диск заполнен на ${disk_usage}%"
    ((issues++))
    DIAGNOSE_ISSUES+=("${MSG[FIX_CHECK_DISK]}")
  elif [[ "$disk_usage" -gt 80 ]]; then
    warning "  ⚠️  Диск заполнен на ${disk_usage}%"
  else
    success "  ✓ Диск: ${disk_usage}%"
  fi

  # Проверка RAM
  local ram_usage
  ram_usage=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

  if [[ "$ram_usage" -gt 90 ]]; then
    warning "  ✗ RAM использовано ${ram_usage}%"
    ((issues++))
    DIAGNOSE_ISSUES+=("${MSG[FIX_CHECK_RAM]}")
  elif [[ "$ram_usage" -gt 80 ]]; then
    warning "  ⚠️  RAM использовано ${ram_usage}%"
  else
    success "  ✓ RAM: ${ram_usage}%"
  fi

  DIAGNOSE_RESULTS[resources]=$([[ $issues -eq 0 ]] && echo "OK" || echo "ISSUES")
}

# ══════════════════════════════════════════════════════════════
# ШАГ 9: Генерация отчёта
# ══════════════════════════════════════════════════════════════

step_generate_report() {
  step_title "9" "${MSG[TITLE_REPORT]}" "Generate report"

  local report_file
  report_file="${DIAGNOSE_DIR}/diagnose_report_$(date +%Y%m%d_%H%M%S).txt"

  {
    echo "══════════════════════════════════════════════════════════"
    echo "  CubiVeil — Diagnose Report"
    echo "  Generated: $(date -Iseconds)"
    echo "  Hostname: $(hostname)"
    echo "══════════════════════════════════════════════════════════"
    echo ""

    echo "## Результаты проверки"
    echo ""
    for key in "${!DIAGNOSE_RESULTS[@]}"; do
      printf "  %-15s %s\n" "${key}:" "${DIAGNOSE_RESULTS[$key]}"
    done
    echo ""

    echo "## Проблемы"
    echo ""
    if [[ ${#DIAGNOSE_ISSUES[@]} -eq 0 ]]; then
      echo "  Проблем не обнаружено"
    else
      for issue in "${DIAGNOSE_ISSUES[@]}"; do
        echo "  ⚠️  ${issue}"
      done
    fi
    echo ""

    echo "## Системная информация"
    echo ""
    echo "  OS: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo 'N/A')"
    echo "  Kernel: $(uname -r)"
    echo "  CPU: $(nproc) cores"
    echo "  RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "  Disk: $(df -h / | tail -1 | awk '{print $2}')"
    echo ""

    echo "## Сетевая информация"
    echo ""
    echo "  External IP: $(curl -sf --max-time 5 https://api4.ipify.org || echo 'N/A')"
    echo "  Internal IP: $(hostname -I 2>/dev/null | awk '{print $1}' || echo 'N/A')"
    echo ""

  } > "$report_file"

  success "Отчёт сохранён: ${report_file}"

  # Вывод краткого резюме
  echo ""
  info "══════════════════════════════════════════════════════════"
  info "  Краткое резюме"
  info "══════════════════════════════════════════════════════════"

  local total_issues=${#DIAGNOSE_ISSUES[@]}
  if [[ $total_issues -eq 0 ]]; then
    success "  Проблем не обнаружено"
  else
    warning "  Обнаружено проблем: ${total_issues}"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 10: Рекомендации
# ══════════════════════════════════════════════════════════════

step_recommendations() {
  step_title "10" "${MSG[TITLE_FIX]}" "Recommendations"

  if [[ ${#DIAGNOSE_ISSUES[@]} -eq 0 ]]; then
    success "  Все системы работают нормально"
    return 0
  fi

  info "Рекомендации:"
  echo ""

  local i=1
  declare -A shown_recommendations
  for issue in "${DIAGNOSE_ISSUES[@]}"; do
    # Убираем дубликаты
    if [[ -z "${shown_recommendations[$issue]:-}" ]]; then
      printf "  %d. %s\n" "$i" "$issue"
      shown_recommendations[$issue]=1
      ((i++))
    fi
  done

  echo ""
  info "Для сбора полного лога выполните:"
  echo "  tar -czf /root/cubiveil-diagnose.tar.gz -C /root cubiveil-diagnose"
  echo "  и отправьте файл в поддержку"
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════

main() {
  select_language

  step_check_environment
  step_check_dns
  step_check_ssl
  step_check_connections
  step_check_services
  step_check_ports
  step_analyze_logs
  step_check_resources
  step_generate_report
  step_recommendations

  # Итоговый статус
  echo ""
  if [[ ${#DIAGNOSE_ISSUES[@]} -gt 0 ]]; then
    warning "${MSG[ERR_DIAGNOSE_FAILED]}"
    exit 1
  else
    success "Диагностика завершена успешно"
    exit 0
  fi
}

main "$@"
