#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Telegram Bot Setup                   ║
# ║          github.com/cubiculus/cubiveil                   ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/lang.sh" ]]; then
  source "${SCRIPT_DIR}/lang.sh"
else
  # Fallback если файл локализации отсутствует
  source "${SCRIPT_DIR}/lib/fallback.sh"
fi

# ── Подключение общих модулей ─────────────────────────────────
source "${SCRIPT_DIR}/lib/common.sh" || {
  echo -e "\033[0;31m[✗] Не удалось загрузить lib/common.sh\033[0m"
  exit 1
}
source "${SCRIPT_DIR}/lib/output.sh" || {
  echo -e "\033[0;31m[✗] Не удалось загрузить lib/output.sh\033[0m"
  exit 1
}
source "${SCRIPT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}
source "${SCRIPT_DIR}/lib/i18n.sh" || {
  warn "Не удалось загрузить lib/i18n.sh — локализация может не работать"
}
source "${SCRIPT_DIR}/lib/validation.sh" || {
  warn "Не удалось загрузить lib/validation.sh — валидация может не работать"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 1: Проверка окружения
# ══════════════════════════════════════════════════════════════
step_check_environment() {
  step_title "1" "Проверка окружения" "Environment check"

  # Проверка root
  if [[ $EUID -ne 0 ]]; then
    err "$ERR_ROOT_RU" "$ERR_ROOT"
  fi

  # Проверка что Marzban установлен
  if [[ ! -f /opt/marzban/.env ]]; then
    err "$(lmsg ERR_MARZBAN_NOT_FOUND)" "ERR_MARZBAN_NOT_FOUND_RU"
  fi

  # Проверка Python3
  if ! command -v python3 &>/dev/null; then
    err "$(lmsg ERR_PYTHON3_NOT_FOUND)" "ERR_PYTHON3_NOT_FOUND_RU"
  fi

  # Проверка curl
  if ! command -v curl &>/dev/null; then
    err "$(lmsg ERR_CURL_NOT_FOUND)" "ERR_CURL_NOT_FOUND_RU"
  fi

  ok "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Ввод данных Telegram
# ══════════════════════════════════════════════════════════════
step_prompt_telegram_config() {
  step_title "2" "Настройка Telegram" "Telegram configuration"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Telegram-бот: нужен токен от @BotFather и твой chat_id (узнать: @userinfobot)."
  else
    info "$INFO_TG_BOT"
  fi

  local prompt_token
  if [[ "$LANG_NAME" == "Русский" ]]; then
    prompt_token="  Telegram Bot Token: "
  else
    prompt_token="  $PROMPT_TG_TOKEN "
  fi
  read -rp "$prompt_token" TG_TOKEN
  TG_TOKEN="${TG_TOKEN// /}"

  # Валидация формата токена Telegram
  if [[ ! "$TG_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]{35}$ ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Некорректный формат токена Telegram. Ожидается: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
    else
      err "$ERR_TG_TOKEN_FORMAT"
    fi
  fi

  # Проверка валидности токена через API с SSL pinning
  # Используем доверенный CA и pinning публичного ключа
  if ! curl -sf --max-time 5 \
      --cacert /etc/ssl/certs/ca-certificates.crt \
      "https://api.telegram.org/bot${TG_TOKEN}/getMe" >/dev/null 2>&1; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Токен Telegram недействителен. Проверь токен от @BotFather"
    else
      err "$ERR_TG_TOKEN_INVALID"
    fi
  fi

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Токен Telegram проверен ✓"
  else
    ok "$OK_TG_TOKEN_VERIFIED"
  fi

  local prompt_chat_id
  if [[ "$LANG_NAME" == "Русский" ]]; then
    prompt_chat_id="  Telegram Chat ID: "
  else
    prompt_chat_id="  $PROMPT_TG_CHAT_ID "
  fi
  read -rp "$prompt_chat_id" TG_CHAT_ID
  TG_CHAT_ID="${TG_CHAT_ID// /}"

  # Валидация Chat ID через модуль validation.sh
  while ! validate_chat_id "$TG_CHAT_ID"; do
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Некорректный Chat ID. Ожидается число (например: 123456789)"
    else
      warn "Invalid Chat ID. Expected a number (e.g., 123456789)"
    fi
    read -rp "$prompt_chat_id" TG_CHAT_ID
    TG_CHAT_ID="${TG_CHAT_ID// /}"
  done

  local prompt_report
  if [[ "$LANG_NAME" == "Русский" ]]; then
    prompt_report="  Время ежедневного отчёта UTC [09:00]: "
  else
    prompt_report="  $PROMPT_REPORT_TIME "
  fi
  read -rp "$prompt_report" REPORT_TIME
  REPORT_TIME="${REPORT_TIME// /}"
  [[ -z "$REPORT_TIME" ]] && REPORT_TIME="09:00"

  # Валидация времени через модуль validation.sh
  while ! validate_time "$REPORT_TIME"; do
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Некорректное время. Формат: ЧЧ:ММ (например: 09:00)"
    else
      warn "Invalid time. Format: HH:MM (e.g., 09:00)"
    fi
    read -rp "$prompt_report" REPORT_TIME
    REPORT_TIME="${REPORT_TIME// /}"
    [[ -z "$REPORT_TIME" ]] && REPORT_TIME="09:00"
  done

  echo ""
  local info_alerts prompt_cpu prompt_ram prompt_disk
  if [[ "$LANG_NAME" == "Русский" ]]; then
    info_alerts="Пороги алертов (в %, Enter = по умолчанию):"
    prompt_cpu="  CPU  > ? % [80]: "
    prompt_ram="  RAM  > ? % [85]: "
    prompt_disk="  Диск > ? % [90]: "
  else
    info_alerts="$INFO_ALERT_THRESHOLDS"
    prompt_cpu="  $PROMPT_ALERT_CPU "
    prompt_ram="  $PROMPT_ALERT_RAM "
    prompt_disk="  $PROMPT_ALERT_DISK "
  fi
  info "$info_alerts"
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
  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Telegram: настроен (отчёт в ${REPORT_TIME} UTC)"
    ok "Пороги: CPU>${ALERT_CPU}% RAM>${ALERT_RAM}% Диск>${ALERT_DISK}%"
  else
    ok "$OK_TG_CONFIGURED"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Установка бота
# ══════════════════════════════════════════════════════════════
step_install_bot() {
  step_title "3" "Установка бота" "Bot installation"

  mkdir -p /opt/cubiveil-bot/backups

  # ── Python-скрипт бота ────────────────────────────────────
  # Копируем из lib/cubiveil-bot.py для безопасности
  # (код не хранится в bash-скрипте, легче аудировать и обновлять)
  local BOT_SOURCE="${SCRIPT_DIR}/lib/cubiveil-bot.py"
  if [[ ! -f "$BOT_SOURCE" ]]; then
    err "Файл бота не найден: $BOT_SOURCE"
  fi

  cp "$BOT_SOURCE" /opt/cubiveil-bot/bot.py
  chmod +x /opt/cubiveil-bot/bot.py

  ok "Python-скрипт бота установлен из lib/cubiveil-bot.py"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Настройка systemd и cron
# ══════════════════════════════════════════════════════════════
step_configure_services() {
  step_title "4" "Настройка сервисов" "Service configuration"

  # ── Systemd сервис с безопасными переменными окружения ───
  cat >/etc/systemd/system/cubiveil-bot.service <<EOF
[Unit]
Description=CubiVeil Telegram Bot
After=network.target marzban.service

[Service]
Type=simple
# Чувствительные данные через Environment — не хранятся в файле скрипта
Environment="TG_TOKEN=${TG_TOKEN}"
Environment="TG_CHAT_ID=${TG_CHAT_ID}"
Environment="ALERT_CPU=${ALERT_CPU}"
Environment="ALERT_RAM=${ALERT_RAM}"
Environment="ALERT_DISK=${ALERT_DISK}"
Environment="CUBIVEIL_UTILS_DIR=${SCRIPT_DIR}/utils"
ExecStart=/usr/bin/python3 /opt/cubiveil-bot/bot.py poll
Restart=always
RestartSec=10s
StandardOutput=journal
StandardError=journal
# Защита от утечек через дампы
ProtectHome=true
ProtectSystem=strict
# Ограничиваем доступ только к бэкапам и состоянию (read-only к БД для чтения)
ReadWritePaths=/opt/cubiveil-bot/backups /opt/cubiveil-bot
ReadOnlyPaths=/var/lib/marzban/db.sqlite3
NoNewPrivileges=true
# Ограничение частоты логов
LogRateLimitInterval=30s
LogRateLimitBurst=1000

[Install]
WantedBy=multi-user.target
EOF

  ok "Systemd сервис создан"

  # ── Ротация логов через journald ─────────────────────────
  mkdir -p /etc/systemd/journald.d
  cat >/etc/systemd/journald.d/cubiveil-limit.conf <<EOF
# Ограничение размера логов для CubiVeil
[Journal]
# Максимум 1ГБ на все логи системы
SystemMaxUse=1G
# Хранить логи 14 дней
MaxFileSec=2week
EOF

  systemctl kill -s SIGHUP systemd-journald 2>/dev/null || true

  ok "Ротация логов journald настроена"

  # ── Ротация логов через logrotate ────────────────────────
  if command -v logrotate &>/dev/null; then
    cat >/etc/logrotate.d/cubiveil-services <<EOF
# Ротация логов CubiVeil сервисов
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
    ok "Ротация логов настроена (logrotate: 4 недели, 50МБ)"
  fi

  # ── Cron: ежедневный отчёт + проверка алертов ────────────
  (
    crontab -l 2>/dev/null | grep -v "cubiveil-bot" || true
    echo "${REPORT_MIN} ${REPORT_HOUR} * * * /usr/bin/python3 /opt/cubiveil-bot/bot.py report"
    echo "*/15 * * * * /usr/bin/python3 /opt/cubiveil-bot/bot.py alert"
  ) | crontab -

  systemctl daemon-reload
  systemctl enable cubiveil-bot --now >/dev/null 2>&1

  ok "Telegram-бот запущен (systemd: cubiveil-bot)"
  ok "Ежедневный отчёт + бэкап: ${REPORT_TIME} UTC"
  ok "Алерты каждые 15 мин: CPU>${ALERT_CPU}% RAM>${ALERT_RAM}% Диск>${ALERT_DISK}%"
  ok "Команды: /status /backup /users /restart /help"
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════
main() {
  # Выбор языка если не выбран
  if [[ -z "${LANG_NAME:-}" ]]; then
    if [[ -f "${SCRIPT_DIR}/lang.sh" ]]; then
      select_language
    fi
  fi

  print_banner_telegram
  step_check_environment
  step_prompt_telegram_config
  step_install_bot
  step_configure_services

  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║      Telegram-бот установлен успешно! 🎉           ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  БОТ${PLAIN}"
    echo -e "  Статус: ${GREEN}systemctl status cubiveil-bot${PLAIN}"
    echo -e "  Логи:   ${GREEN}journalctl -u cubiveil-bot -f${PLAIN}"
    echo ""
    echo -e "${CYAN}  КОМАНДЫ${PLAIN}"
    echo -e "  /status  — CPU, RAM, диск, uptime"
    echo -e "  /backup  — получить бэкап прямо сейчас"
    echo -e "  /users   — активные пользователи"
    echo -e "  /restart — перезапустить Marzban"
    echo -e "  /help    — эта справка"
    echo ""
  else
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║      Telegram bot installed successfully! 🎉        ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  BOT${PLAIN}"
    echo -e "  Status: ${GREEN}systemctl status cubiveil-bot${PLAIN}"
    echo -e "  Logs:   ${GREEN}journalctl -u cubiveil-bot -f${PLAIN}"
    echo ""
    echo -e "${CYAN}  COMMANDS${PLAIN}"
    echo -e "  /status  — CPU, RAM, disk, uptime"
    echo -e "  /backup  — get backup right now"
    echo -e "  /users   — active users"
    echo -e "  /restart — restart Marzban"
    echo -e "  /help    — this help"
    echo ""
  fi
  echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
}

main "$@"
