#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Telegram Bot Setup                    ║
# ║          github.com/cubiculus/cubiveil                    ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Определение директории скрипта ───────────────────────────
# Используем _TG_DIR чтобы избежать коллизий с SCRIPT_DIR из lib/*.sh
# Когда вызван из install.sh, INSTALL_SCRIPT_DIR уже указывает на корень репо.
# Когда запущен напрямую, используем BASH_SOURCE.
if [[ -n "${INSTALL_SCRIPT_DIR:-}" && -d "${INSTALL_SCRIPT_DIR}/lib" ]]; then
  _TG_DIR="$INSTALL_SCRIPT_DIR"
else
  _TG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# ── Подключение локализации ──────────────────────────────────
if [[ -f "${_TG_DIR}/lang/telegram.sh" ]]; then
  source "${_TG_DIR}/lang/telegram.sh"
elif [[ -f "${_TG_DIR}/lang/main.sh" ]]; then
  source "${_TG_DIR}/lang/main.sh"
else
  source "${_TG_DIR}/lib/fallback.sh"
fi

# ── Подключение общих модулей ────────────────────────────────
export TELEGRAM_BOT_lib_SCRIPT_DIR="${_TG_DIR}/lib"

source "${_TG_DIR}/lib/output.sh" || {
  echo -e "\033[0;31m[✗] Не удалось загрузить lib/output.sh\033[0m"
  exit 1
}
source "${_TG_DIR}/lib/security.sh" || {
  echo -e "\033[0;31m[✗] Не удалось загрузить lib/security.sh\033[0m"
  exit 1
}
source "${_TG_DIR}/lib/common.sh" || {
  echo -e "\033[0;31m[✗] Не удалось загрузить lib/common.sh\033[0m"
  exit 1
}
source "${_TG_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}
source "${_TG_DIR}/lib/i18n.sh" || {
  warn "Не удалось загрузить lib/i18n.sh — локализация может не работать"
}
source "${_TG_DIR}/lib/validation.sh" || {
  warn "Не удалось загрузить lib/validation.sh — валидация может не работать"
}

# ══════════════════════════════════════════════════════════════
# Вспомогательные функции
# ══════════════════════════════════════════════════════════════

# Печать заголовка Telegram
print_banner_telegram() {
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
  echo -e "${GREEN}║     CubiVeil — Telegram Bot Setup                   ║${PLAIN}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
  echo ""
}

# Шаг установки с локализацией
tg_step() {
  local step_num="$1"
  local total_steps="$2"
  local ru="$3"
  local en="$4"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_module "$step_num" "$total_steps" "$ru"
  else
    step_module "$step_num" "$total_steps" "$en"
  fi
}

# Ожидание запуска systemd-сервиса с таймером
wait_for_service() {
  local svc="$1"
  local max_wait="${2:-30}"
  local start_ts
  start_ts=$(date +%s)

  while true; do
    if systemctl is-active --quiet "$svc"; then
      success "$(get_tg_str OK_SERVICE_ACTIVE | sed "s/{SERVICE}/${svc}/g")"
      return 0
    fi
    local now_ts
    now_ts=$(date +%s)
    local elapsed=$((now_ts - start_ts))
    if [[ $elapsed -ge $max_wait ]]; then
      warning "$(get_tg_str WARN_SERVICE_TIMEOUT | sed "s/{SERVICE}/${svc}/g" | sed "s/{SECONDS}/${max_wait}/g")"
      return 1
    fi
    echo -ne "\rWaiting for $svc... ${elapsed}s"
    sleep 1
  done
}

# ══════════════════════════════════════════════════════════════
# ШАГ 1: Проверка окружения
# ══════════════════════════════════════════════════════════════
step_check_environment() {
  local _ru _en
  _ru="$(get_tg_str STEP_TITLE_ENV_CHECK_RU)"
  _en="$(get_tg_str STEP_TITLE_ENV_CHECK)"
  tg_step 1 4 "$_ru" "$_en"

  # Проверка root
  if [[ $EUID -ne 0 ]]; then
    err "$(get_tg_str ERR_ROOT_TG_RU)"
  fi

  # Проверка что Marzban установлен (Docker-контейнер или .env файл)
  # .env находится в /var/lib/marzban/, а не в /opt/marzban/
  local _marzban_ok=false
  if [[ -f /var/lib/marzban/.env ]]; then
    _marzban_ok=true
  elif [[ -f /opt/marzban/.env ]]; then
    _marzban_ok=true
  fi
  # Дополнительная проверка Docker-контейнера
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qE '^marzban'; then
    _marzban_ok=true
  fi

  if [[ "$_marzban_ok" != "true" ]]; then
    err "$(get_tg_str ERR_MARZBAN_NOT_FOUND_TG_RU)"
  fi

  # Проверка Python3
  if ! command -v python3 &>/dev/null; then
    err "$(get_tg_str ERR_PYTHON3_NOT_FOUND_TG_RU)"
  fi

  # Проверка curl
  if ! command -v curl &>/dev/null; then
    err "$(get_tg_str ERR_CURL_NOT_FOUND_TG_RU)"
  fi

  success "$(get_tg_str OK_ENV_CHECKED_RU)"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Ввод данных Telegram
# ══════════════════════════════════════════════════════════════
step_prompt_telegram_config() {
  local _ru _en
  _ru="$(get_tg_str STEP_TITLE_TG_CONFIG_RU)"
  _en="$(get_tg_str STEP_TITLE_TG_CONFIG)"
  tg_step 2 4 "$_ru" "$_en"

  info "$(get_tg_str INFO_TG_BOT_RU)"

  local prompt_token
  prompt_token="$(get_tg_str PROMPT_TG_TOKEN_RU)"
  read -rp "$prompt_token" TG_TOKEN
  TG_TOKEN="${TG_TOKEN// /}"

  # Валидация формата токена Telegram
  if [[ ! "$TG_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]{35}$ ]]; then
    err "$(get_tg_str ERR_TG_TOKEN_FORMAT_RU)"
  fi

  # Проверка валидности токена через API
  # Используем || true чтобы set -e не прерывал скрипт при сетевых ошибках
  local _tg_response="" _curl_exit=0

  # Пробуем с системным CA bundle
  _tg_response=$(curl -sf --max-time 10 \
    --cacert /etc/ssl/certs/ca-certificates.crt \
    "https://api.telegram.org/bot${TG_TOKEN}/getMe" 2>/dev/null) || true

  # Fallback без CA bundle
  if [[ -z "$_tg_response" ]]; then
    _tg_response=$(curl -sf --max-time 10 \
      "https://api.telegram.org/bot${TG_TOKEN}/getMe" 2>/dev/null) || true
  fi

  if [[ -z "$_tg_response" ]]; then
    # Сервер не достигает api.telegram.org
    warn "Не удалось подключиться к api.telegram.org."
    warn "Возможно, Telegram заблокирован на этом сервере."
    warn "Токен будет сохранён без проверки."
    # Не выходим — продолжаем установку
  elif echo "$_tg_response" | grep -q '"ok":false'; then
    err "$(get_tg_str ERR_TG_TOKEN_INVALID_RU)"
  else
    success "$(get_tg_str OK_TG_TOKEN_VERIFIED_RU)"
  fi

  local prompt_chat_id
  prompt_chat_id="$(get_tg_str PROMPT_TG_CHAT_ID_RU)"
  read -rp "$prompt_chat_id" TG_CHAT_ID
  TG_CHAT_ID="${TG_CHAT_ID// /}"

  # Валидация Chat ID (пропускаем если пустой — пользователь нажал Enter)
  if [[ -n "$TG_CHAT_ID" ]]; then
    while ! validate_chat_id "$TG_CHAT_ID"; do
      warning "$(get_tg_str WARN_INVALID_CHAT_ID_RU)"
      read -rp "$prompt_chat_id" TG_CHAT_ID
      TG_CHAT_ID="${TG_CHAT_ID// /}"
      [[ -z "$TG_CHAT_ID" ]] && break
    done
  fi

  local prompt_report
  prompt_report="$(get_tg_str PROMPT_REPORT_TIME_RU)"
  read -rp "$prompt_report" REPORT_TIME
  REPORT_TIME="${REPORT_TIME// /}"
  [[ -z "$REPORT_TIME" ]] && REPORT_TIME="09:00"

  # Валидация времени
  while ! validate_time "$REPORT_TIME"; do
    warning "$(get_tg_str WARN_INVALID_TIME_RU)"
    read -rp "$prompt_report" REPORT_TIME
    REPORT_TIME="${REPORT_TIME// /}"
    [[ -z "$REPORT_TIME" ]] && REPORT_TIME="09:00"
  done

  # Парсинг REPORT_TIME для cron
  REPORT_HOUR=$(echo "$REPORT_TIME" | cut -d: -f1)
  REPORT_MIN=$(echo "$REPORT_TIME" | cut -d: -f2)

  echo ""
  info "$(get_tg_str INFO_ALERT_THRESHOLDS_RU)"
  local prompt_cpu prompt_ram prompt_disk
  prompt_cpu="$(get_tg_str PROMPT_ALERT_CPU_RU)"
  prompt_ram="$(get_tg_str PROMPT_ALERT_RAM_RU)"
  prompt_disk="$(get_tg_str PROMPT_ALERT_DISK_RU)"
  read -rp "$prompt_cpu" ALERT_CPU
  ALERT_CPU="${ALERT_CPU// /}"
  [[ -z "$ALERT_CPU" ]] && ALERT_CPU=80
  read -rp "$prompt_ram" ALERT_RAM
  ALERT_RAM="${ALERT_RAM// /}"
  [[ -z "$ALERT_RAM" ]] && ALERT_RAM=85
  read -rp "$prompt_disk" ALERT_DISK
  ALERT_DISK="${ALERT_DISK// /}"
  [[ -z "$ALERT_DISK" ]] && ALERT_DISK=90

  echo ""
  success "$(get_tg_str OK_TG_CONFIGURED_RU | sed "s/{REPORT_TIME}/${REPORT_TIME}/g")"
  success "$(get_tg_str OK_TG_CONFIGURED_SHORT_RU | sed "s/{ALERT_CPU}/${ALERT_CPU}/g" | sed "s/{ALERT_RAM}/${ALERT_RAM}/g" | sed "s/{ALERT_DISK}/${ALERT_DISK}/g")"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Установка бота
# ══════════════════════════════════════════════════════════════
step_install_bot() {
  local _ru _en
  _ru="$(get_tg_str STEP_TITLE_BOT_INSTALL_RU)"
  _en="$(get_tg_str STEP_TITLE_BOT_INSTALL)"
  tg_step 3 4 "$_ru" "$_en"

  mkdir -p /opt/cubiveil-bot/backups

  local BOT_SOURCE="${_TG_DIR}/assets/telegram-bot/bot.py"
  local BOT_MODULES_DIR="${_TG_DIR}/assets/telegram-bot"

  if [[ ! -f "$BOT_SOURCE" ]]; then
    err "$(get_tg_str ERR_BOT_FILE_NOT_FOUND_RU | sed "s/{PATH}/${BOT_SOURCE}/g")"
  fi

  cp "$BOT_SOURCE" /opt/cubiveil-bot/bot.py
  chmod +x /opt/cubiveil-bot/bot.py

  # Копируем модули
  for module in telegram_client.py metrics.py backup.py alert_state.py commands.py health_check.py logs.py keyboards.py profiles.py; do
    if [[ -f "${BOT_MODULES_DIR}/${module}" ]]; then
      cp "${BOT_MODULES_DIR}/${module}" /opt/cubiveil-bot/${module}
      chmod +x /opt/cubiveil-bot/${module}
    else
      warning "$(get_tg_str WARN_BOT_MODULE_NOT_FOUND_RU | sed "s/{MODULE}/${module}/g")"
    fi
  done

  success "$(get_tg_str OK_BOT_INSTALLED_RU)"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Настройка systemd и cron
# ══════════════════════════════════════════════════════════════
step_configure_services() {
  local _ru _en
  _ru="$(get_tg_str STEP_TITLE_SERVICE_CONFIG_RU)"
  _en="$(get_tg_str STEP_TITLE_SERVICE_CONFIG)"
  tg_step 4 4 "$_ru" "$_en"

  # ── Безопасный файл с чувствительными данными ───────────
  mkdir -p /etc/cubiveil
  cat >/etc/cubiveil/bot.env <<EOF
TG_TOKEN=${TG_TOKEN}
TG_CHAT_ID=${TG_CHAT_ID}
ALERT_CPU=${ALERT_CPU}
ALERT_RAM=${ALERT_RAM}
ALERT_DISK=${ALERT_DISK}
EOF
  chmod 600 /etc/cubiveil/bot.env
  chown root:root /etc/cubiveil/bot.env

  success "$(get_tg_str OK_SENSITIVE_FILE_CREATED_RU | sed "s/{PATH}\/etc\/cubiveil\/bot.env/\/etc\/cubiveil\/bot.env/g")"

  # ── Systemd сервис ───────────────────────────────────────
  cat >/etc/systemd/system/cubiveil-bot.service <<EOF
[Unit]
Description=CubiVeil Telegram Bot
After=network.target marzban.service

[Service]
Type=simple
EnvironmentFile=/etc/cubiveil/bot.env
Environment="CUBIVEIL_UTILS_DIR=${_TG_DIR}/utils"
ExecStart=/usr/bin/python3 /opt/cubiveil-bot/bot.py poll
Restart=always
RestartSec=10s
StandardOutput=journal
StandardError=journal
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/opt/cubiveil-bot/backups /opt/cubiveil-bot
ReadOnlyPaths=/var/lib/marzban/db.sqlite3
NoNewPrivileges=true
LogRateLimitInterval=30s
LogRateLimitBurst=1000

[Install]
WantedBy=multi-user.target
EOF

  success "$(get_tg_str OK_SYSTEMD_CREATED_RU)"

  # ── Ротация логов через journald ─────────────────────────
  mkdir -p /etc/systemd/journald.d
  cat >/etc/systemd/journald.d/cubiveil-limit.conf <<EOF
[Journal]
SystemMaxUse=1G
MaxFileSec=2week
EOF

  systemctl kill -s SIGHUP systemd-journald 2>/dev/null || true

  success "$(get_tg_str OK_JOURNALD_CONFIGURED_RU)"

  # ── Ротация логов через logrotate ────────────────────────
  if command -v logrotate &>/dev/null; then
    cat >/etc/logrotate.d/cubiveil-services <<EOF
/var/log/journal/*/cubiveil-bot.service.log {
  weekly
  rotate 4
  compress
  delaycompress
  missingok
  notifempty
  size=50M
  maxage 30
}
EOF
    success "$(get_tg_str OK_LOGROTATE_CONFIGURED_RU | sed "s/{WEEKS}/4/g" | sed "s/{SIZE}/50МБ/g")"
  fi

  # ── Cron: ежедневный отчёт + проверка алертов ────────────
  (
    crontab -l 2>/dev/null | grep -v "cubiveil-bot" || true
    echo "${REPORT_MIN} ${REPORT_HOUR} * * * /usr/bin/python3 /opt/cubiveil-bot/bot.py report"
    echo "*/15 * * * * /usr/bin/python3 /opt/cubiveil-bot/bot.py alert"
  ) | crontab -

  systemctl daemon-reload
  systemctl enable cubiveil-bot --now >/dev/null 2>&1

  success "$(get_tg_str OK_BOT_STARTED_RU | sed "s/{SERVICE}/cubiveil-bot/g")"
  success "$(get_tg_str OK_DAILY_REPORT_RU | sed "s/{TIME}/${REPORT_TIME}/g")"
  success "$(get_tg_str OK_ALERTS_CONFIGURED_RU | sed "s/{CPU}/${ALERT_CPU}/g" | sed "s/{RAM}/${ALERT_RAM}/g" | sed "s/{DISK}/${ALERT_DISK}/g")"
  success "$(get_tg_str OK_COMMANDS_RU)"
}

# ══════════════════════════════════════════════════════════════
# Финальный вывод
# ══════════════════════════════════════════════════════════════
print_finish() {
  echo ""

  # Итоговая сводка предупреждений
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}$(get_tg_str FINAL_WARNINGS_TITLE_RU)${PLAIN}"
    for _warn in "${WARNINGS[@]}"; do
      echo -e "  - ${_warn}"
    done
    echo ""
  fi

  echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    local _title_ru _padding
    _title_ru="$(get_tg_str FINAL_SUCCESS_TITLE_RU)"
    _padding=$((48 - ${#_title_ru}))
    echo -e "${GREEN}║  ${_title_ru}$(printf '%*s' "$_padding" '') ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  $(get_tg_str FINAL_BOT_SECTION_RU)${PLAIN}"
    echo -e "  $(get_tg_str FINAL_STATUS_RU): ${GREEN}systemctl status cubiveil-bot${PLAIN}"
    echo -e "  $(get_tg_str FINAL_LOGS_RU):   ${GREEN}journalctl -u cubiveil-bot -f${PLAIN}"
    echo ""
    echo -e "${CYAN}  $(get_tg_str FINAL_COMMANDS_SECTION_RU)${PLAIN}"
    echo -e "  /status  — CPU, RAM, диск, uptime"
    echo -e "  /monitor — детальный мониторинг"
    echo -e "  /backup  — меню бэкапов"
    echo -e "  /backups — список бэкапов"
    echo -e "  /restore — восстановить бэкап"
    echo -e "  /users   — активные пользователи"
    echo -e "  /restart — перезапустить Marzban"
    echo -e "  /logs    — логи сервисов"
    echo -e "  /health  — проверка здоровья"
    echo -e "  /profiles — управление профилями"
    echo -e "  /settings — настройки бота"
    echo -e "  /set_cpu — порог CPU alert"
    echo -e "  /set_ram — порог RAM alert"
    echo -e "  /set_disk — порог Disk alert"
    echo ""
    echo -e "${CYAN}  $(get_tg_str FINAL_PROFILES_SECTION_RU)${PLAIN}"
    echo -e "  /enable  — включить профиль"
    echo -e "  /disable — отключить профиль"
    echo -e "  /extend  — продлить профиль"
    echo -e "  /reset   — сбросить трафик"
    echo -e "  /qr      — QR-код для подключения"
    echo -e "  /traffic — расход трафика"
    echo -e "  /subscription — ссылка на подписку"
    echo -e "  /create  — создать новый профиль"
    echo ""
    echo -e "  /help    — эта справка"
    echo ""
    echo -e "${YELLOW}  $(get_tg_str FINAL_NAVIGATION_RU)${PLAIN}"
    echo ""
  else
    local _title_en _padding_en
    _title_en="$(get_tg_str FINAL_SUCCESS_TITLE)"
    _padding_en=$((48 - ${#_title_en}))
    echo -e "${GREEN}║  ${_title_en}$(printf '%*s' "$_padding_en" '') ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  $(get_tg_str FINAL_BOT_SECTION)${PLAIN}"
    echo -e "  $(get_tg_str FINAL_STATUS): ${GREEN}systemctl status cubiveil-bot${PLAIN}"
    echo -e "  $(get_tg_str FINAL_LOGS):   ${GREEN}journalctl -u cubiveil-bot -f${PLAIN}"
    echo ""
    echo -e "${CYAN}  $(get_tg_str FINAL_COMMANDS_SECTION)${PLAIN}"
    echo -e "  /status  — CPU, RAM, disk, uptime"
    echo -e "  /monitor — detailed monitoring"
    echo -e "  /backup  — backup menu"
    echo -e "  /backups — backups list"
    echo -e "  /restore — restore backup"
    echo -e "  /users   — active users"
    echo -e "  /restart — restart Marzban"
    echo -e "  /logs    — service logs"
    echo -e "  /health  — health check"
    echo -e "  /profiles — profiles management"
    echo -e "  /settings — bot settings"
    echo -e "  /set_cpu — CPU alert threshold"
    echo -e "  /set_ram — RAM alert threshold"
    echo -e "  /set_disk — Disk alert threshold"
    echo ""
    echo -e "${CYAN}  $(get_tg_str FINAL_PROFILES_SECTION)${PLAIN}"
    echo -e "  /enable  — enable profile"
    echo -e "  /disable — disable profile"
    echo -e "  /extend  — extend profile"
    echo -e "  /reset   — reset traffic"
    echo -e "  /qr      — QR code for connection"
    echo -e "  /traffic — traffic usage"
    echo -e "  /subscription — subscription link"
    echo -e "  /create  — create new profile"
    echo ""
    echo -e "  /help    — this help"
    echo ""
    echo -e "${YELLOW}  $(get_tg_str FINAL_NAVIGATION)${PLAIN}"
    echo ""
  fi
  echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════
telegram_main() {
  # Выбор языка если не выбран
  if [[ -z "${LANG_NAME:-}" ]]; then
    if [[ -f "${_TG_DIR}/lang/telegram.sh" ]]; then
      # Язык уже выбран в lang/telegram.sh
      :
    elif [[ -f "${_TG_DIR}/lang/main.sh" ]]; then
      source "${_TG_DIR}/lang/main.sh"
    fi
  fi

  print_banner_telegram
  step_check_environment
  step_prompt_telegram_config
  step_install_bot
  step_configure_services

  print_finish
}

main() {
  telegram_main "$@"
}

# Запускаем main только если скрипт запущен напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
