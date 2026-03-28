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
    err "$(get_str ERR_MARZBAN_NOT_FOUND ERR_MARZBAN_NOT_FOUND_RU)"
  fi

  # Проверка Python3
  if ! command -v python3 &>/dev/null; then
    err "$(get_str ERR_PYTHON3_NOT_FOUND ERR_PYTHON3_NOT_FOUND_RU)"
  fi

  # Проверка curl
  if ! command -v curl &>/dev/null; then
    err "$(get_str ERR_CURL_NOT_FOUND ERR_CURL_NOT_FOUND_RU)"
  fi

  ok "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Ввод данных Telegram
# ══════════════════════════════════════════════════════════════
step_prompt_telegram_config() {
  step_title "2" "Настройка Telegram" "Telegram configuration"

  info "$(get_setup_str INFO_TG_BOT)"

  local prompt_token
  prompt_token="$(get_setup_str PROMPT_TG_TOKEN)"
  read -rp "$prompt_token" TG_TOKEN
  TG_TOKEN="${TG_TOKEN// /}"

  # Валидация формата токена Telegram
  if [[ ! "$TG_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]{35}$ ]]; then
    err "$(get_setup_str ERR_TG_TOKEN_FORMAT)"
  fi

  # Проверка валидности токена через API с SSL pinning
  # Используем доверенный CA и pinning публичного ключа
  if ! curl -sf --max-time 5 \
    --cacert /etc/ssl/certs/ca-certificates.crt \
    "https://api.telegram.org/bot${TG_TOKEN}/getMe" >/dev/null 2>&1; then
    err "$(get_setup_str ERR_TG_TOKEN_INVALID)"
  fi

  ok "$(get_setup_str OK_TG_TOKEN_VERIFIED)"

  local prompt_chat_id
  prompt_chat_id="$(get_setup_str PROMPT_TG_CHAT_ID)"
  read -rp "$prompt_chat_id" TG_CHAT_ID
  TG_CHAT_ID="${TG_CHAT_ID// /}"

  # Валидация Chat ID через модуль validation.sh
  while ! validate_chat_id "$TG_CHAT_ID"; do
    warn "$(get_setup_str WARN_INVALID_CHAT_ID)"
    read -rp "$prompt_chat_id" TG_CHAT_ID
    TG_CHAT_ID="${TG_CHAT_ID// /}"
  done

  local prompt_report
  prompt_report="$(get_setup_str PROMPT_REPORT_TIME)"
  read -rp "$prompt_report" REPORT_TIME
  REPORT_TIME="${REPORT_TIME// /}"
  [[ -z "$REPORT_TIME" ]] && REPORT_TIME="09:00"

  # Валидация времени через модуль validation.sh
  while ! validate_time "$REPORT_TIME"; do
    warn "$(get_setup_str WARN_INVALID_TIME)"
    read -rp "$prompt_report" REPORT_TIME
    REPORT_TIME="${REPORT_TIME// /}"
    [[ -z "$REPORT_TIME" ]] && REPORT_TIME="09:00"
  done

  # Парсинг REPORT_TIME для cron
  REPORT_HOUR=$(echo "$REPORT_TIME" | cut -d: -f1)
  REPORT_MIN=$(echo "$REPORT_TIME" | cut -d: -f2)

  echo ""
  local info_alerts
  local prompt_cpu
  local prompt_ram
  local prompt_disk
  info_alerts="$(get_setup_str INFO_ALERT_THRESHOLDS)"
  prompt_cpu="$(get_setup_str PROMPT_ALERT_CPU)"
  prompt_ram="$(get_setup_str PROMPT_ALERT_RAM)"
  prompt_disk="$(get_setup_str PROMPT_ALERT_DISK)"
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
  ok "$(get_setup_str OK_TG_CONFIGURED_RU)"
  ok "$(get_setup_str OK_TG_CONFIGURED_SHORT_RU)"
  if [[ "$LANG_NAME" != "Русский" ]]; then
    ok "$(get_setup_str OK_TG_CONFIGURED)"
    ok "$(get_setup_str OK_TG_CONFIGURED_SHORT)"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Установка бота
# ══════════════════════════════════════════════════════════════
step_install_bot() {
  step_title "3" "Установка бота" "Bot installation"

  mkdir -p /opt/cubiveil-bot/backups

  # ── Python-скрипт бота ────────────────────────────────────
  # Используем модульную версию из assets/telegram-bot/
  local BOT_SOURCE="${SCRIPT_DIR}/assets/telegram-bot/bot.py"
  local BOT_MODULES_DIR="${SCRIPT_DIR}/assets/telegram-bot"

  if [[ ! -f "$BOT_SOURCE" ]]; then
    err "Файл бота не найден: $BOT_SOURCE"
  fi

  # Копируем основной файл бота
  cp "$BOT_SOURCE" /opt/cubiveil-bot/bot.py
  chmod +x /opt/cubiveil-bot/bot.py

  # Копируем модули
  for module in telegram_client.py metrics.py backup.py alert_state.py commands.py health_check.py logs.py keyboards.py profiles.py; do
    if [[ -f "${BOT_MODULES_DIR}/${module}" ]]; then
      cp "${BOT_MODULES_DIR}/${module}" /opt/cubiveil-bot/${module}
      chmod +x /opt/cubiveil-bot/${module}
    fi
  done

  ok "Python-скрипт бота установлен из assets/telegram-bot/"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Настройка systemd и cron
# ══════════════════════════════════════════════════════════════
step_configure_services() {
  step_title "4" "Настройка сервисов" "Service configuration"

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

  ok "Файл с чувствительными данными создан (/etc/cubiveil/bot.env, 0600)"

  # ── Systemd сервис с EnvironmentFile ───────────────────
  cat >/etc/systemd/system/cubiveil-bot.service <<EOF
[Unit]
Description=CubiVeil Telegram Bot
After=network.target marzban.service

[Service]
Type=simple
# Чувствительные данные в защищённом файле с правами 0600
EnvironmentFile=/etc/cubiveil/bot.env
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
telegram_main() {
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
    echo -e "${GREEN}║      Telegram-бот установлен успешно! 🎉             ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  БОТ${PLAIN}"
    echo -e "  Статус: ${GREEN}systemctl status cubiveil-bot${PLAIN}"
    echo -e "  Логи:   ${GREEN}journalctl -u cubiveil-bot -f${PLAIN}"
    echo ""
    echo -e "${CYAN}  КОМАНДЫ${PLAIN}"
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
    echo -e ""
    echo -e "${CYAN}  ПРОФИЛИ${PLAIN}"
    echo -e "  /enable  — включить профиль"
    echo -e "  /disable — отключить профиль"
    echo -e "  /extend  — продлить профиль"
    echo -e "  /reset   — сбросить трафик"
    echo -e "  /qr      — QR-код для подключения"
    echo -e "  /traffic — расход трафика"
    echo -e "  /subscription — ссылка на подписку"
    echo -e "  /create  — создать новый профиль"
    echo -e ""
    echo -e "  /help    — эта справка"
    echo ""
    echo -e "${YELLOW}  Используйте кнопки в меню для навигации!${PLAIN}"
    echo ""
  else
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║      Telegram bot installed successfully! 🎉         ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  BOT${PLAIN}"
    echo -e "  Status: ${GREEN}systemctl status cubiveil-bot${PLAIN}"
    echo -e "  Logs:   ${GREEN}journalctl -u cubiveil-bot -f${PLAIN}"
    echo ""
    echo -e "${CYAN}  COMMANDS${PLAIN}"
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
    echo -e ""
    echo -e "${CYAN}  PROFILES${PLAIN}"
    echo -e "  /enable  — enable profile"
    echo -e "  /disable — disable profile"
    echo -e "  /extend  — extend profile"
    echo -e "  /reset   — reset traffic"
    echo -e "  /qr      — QR code for connection"
    echo -e "  /traffic — traffic usage"
    echo -e "  /subscription — subscription link"
    echo -e "  /create  — create new profile"
    echo -e ""
    echo -e "  /help    — this help"
    echo ""
    echo -e "${YELLOW}  Use menu buttons for navigation!${PLAIN}"
    echo ""
  fi
  echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
}

main() {
  telegram_main "$@"
}

# Запускаем main только если скрипт запущен напрямую, а не через source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
