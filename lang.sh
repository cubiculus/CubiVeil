#!/bin/bash
# shellcheck disable=SC2034
# ╔═══════════════════════════════════════════════════════════╗
# ║              CubiVeil — Localization                      ║
# ║                   EN / RU strings                         ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Язык по умолчанию / Default language ─────────────────────
# Раскомментируй нужную строку / Uncomment the line you need:
# LANG_NAME="English"
LANG_NAME="Русский"

# ── Подключение fallback функций ─────────────────────────────
LANG_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${LANG_SCRIPT_DIR}/lib/fallback.sh" ]]; then
  source "${LANG_SCRIPT_DIR}/lib/fallback.sh"
fi

# ── Подключение унифицированного модуля локализации ───────
if [[ -f "${LANG_SCRIPT_DIR}/lib/i18n.sh" ]]; then
  source "${LANG_SCRIPT_DIR}/lib/i18n.sh"
fi

# ── Проверки / Checks ─────────────────────────────────────────
ERR_ROOT="Scripts must be run as root (sudo)"
ERR_ROOT_RU="Запускай от root"
ERR_UBUNTU="This script is only for Ubuntu"
ERR_UBUNTU_RU="Скрипт только для Ubuntu"
ERR_MARZBAN_NOT_FOUND="Marzban not found. Run main installer first: bash install.sh"
ERR_MARZBAN_NOT_FOUND_RU="Marzban не найден. Сначала запусти основной установщик: bash install.sh"
ERR_PYTHON3_NOT_FOUND="Python3 not found. Install: apt-get install python3"
ERR_PYTHON3_NOT_FOUND_RU="Python3 не установлен. Установи: apt-get install python3"
ERR_CURL_NOT_FOUND="curl not found. Install: apt-get install curl"
ERR_CURL_NOT_FOUND_RU="curl не установлен. Установи: apt-get install curl"

# ── Dev mode / Dev режим ──────────────────────────────────────
INFO_DEV_MODE="DEV mode: using self-signed SSL certificate"
INFO_DEV_MODE_RU="DEV-режим: использование самоподписного SSL сертификата"

INFO_DEV_DOMAIN="Domain not required, will use: {DOMAIN}"
INFO_DEV_DOMAIN_RU="Домен не требуется, будет использован: {DOMAIN}"

WARN_DEV_MODE="WARNING: Browsers will show security warning"
WARN_DEV_MODE_RU="ВНИМАНИЕ: Браузеры будут показывать предупреждение о безопасности"

WARN_DEV_NOT_FOR_PRODUCTION="Do not use in production!"
WARN_DEV_NOT_FOR_PRODUCTION_RU="Не используйте в production!"

OK_DEV_DOMAIN="Domain: {DOMAIN} (dev mode)"
OK_DEV_DOMAIN_RU="Домен: {DOMAIN} (dev-режим)"

# ── Строки ввода данных / Input prompts ───────────────────────
PROMPT_DOMAIN="Domain for panel and subscriptions (e.g. panel.example.com):"
PROMPT_DOMAIN_RU="Домен для панели и подписок (например panel.example.com):"

PROMPT_EMAIL="Email for Let's Encrypt [admin@DOMAIN]:"
PROMPT_EMAIL_RU="Email для Let's Encrypt [admin@DOMAIN]:"

PROMPT_TG_TOKEN="Telegram Bot Token (Enter to skip):"
PROMPT_TG_TOKEN_RU="Telegram Bot Token (Enter — пропустить):"

PROMPT_TG_CHAT_ID="Telegram Chat ID:"
PROMPT_TG_CHAT_ID_RU="Telegram Chat ID:"

PROMPT_REPORT_TIME="Daily report time UTC [09:00]:"
PROMPT_REPORT_TIME_RU="Время ежедневного отчёта UTC [09:00]:"

PROMPT_ALERT_CPU="CPU  > ? % [80]:"
PROMPT_ALERT_CPU_RU="CPU  > ? % [80]:"

PROMPT_ALERT_RAM="RAM  > ? % [85]:"
PROMPT_ALERT_RAM_RU="RAM  > ? % [85]:"

PROMPT_ALERT_DISK="Disk > ? % [90]:"
PROMPT_ALERT_DISK_RU="Диск > ? % [90]:"

# ── Предупреждения / Warnings ─────────────────────────────────
WARN_DNS_RECORD="Make sure the domain's A record already points to this server."
WARN_DNS_RECORD_RU="Убедись что A-запись домена уже указывает на этот сервер."

WARN_LETS_ENCRYPT="Let's Encrypt will check DNS — installation will fail if record is not set."
WARN_LETS_ENCRYPT_RU="Let's Encrypt проверит DNS — установка упадёт если запись не прописана."

WARN_DOMAIN_EMPTY="Domain cannot be empty"
WARN_DOMAIN_EMPTY_RU="Домен не может быть пустым"

WARN_DOMAIN_FORMAT="Invalid domain format. Example: panel.example.com"
WARN_DOMAIN_FORMAT_RU="Некорректный формат домена. Пример: panel.example.com"

WARN_DOMAIN_INTERNAL="Domain must not be internal (localhost, .local, IP address)"
WARN_DOMAIN_INTERNAL_RU="Домен не должен быть внутренним (localhost, .local, IP-адрес)"

# shellcheck disable=SC2034
WARN_DNS_RESOLVE="Failed to resolve domain {DOMAIN}. Check A record."
WARN_DNS_RESOLVE_RU="Не удалось разрешить домен {DOMAIN}. Проверь A-запись."

WARN_CONTINUE_ERROR="Continue despite the error? (y/n):"
WARN_CONTINUE_ERROR_RU="Продолжить несмотря на ошибку? (y/n):"

WARN_DNS_MISMATCH="A record {DOMAIN} → {IP}, but server IP: {SERVER_IP}"
WARN_DNS_MISMATCH_RU="A-запись {DOMAIN} → {IP}, но IP сервера: {SERVER_IP}"

WARN_CONTINUE_MISMATCH="Continue despite the mismatch? (y/n):"
WARN_CONTINUE_MISMATCH_RU="Продолжить несмотря на несоответствие? (y/n):"

# ── Telegram validation ───────────────────────────────────────
ERR_TG_TOKEN_FORMAT="Invalid Telegram token format. Expected: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
ERR_TG_TOKEN_FORMAT_RU="Некорректный формат токена Telegram. Ожидается: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"

ERR_TG_TOKEN_INVALID="Telegram token is invalid. Check token from @BotFather"
ERR_TG_TOKEN_INVALID_RU="Токен Telegram недействителен. Проверь токен от @BotFather"

OK_TG_TOKEN_VERIFIED="Telegram token verified ✓"
OK_TG_TOKEN_VERIFIED_RU="Токен Telegram проверен ✓"

ERR_CHAT_ID_FORMAT="Invalid Chat ID. Expected a number (e.g.: 123456789)"
ERR_CHAT_ID_FORMAT_RU="Некорректный Chat ID. Ожидается число (например: 123456789)"

# ── Info messages ─────────────────────────────────────────────
INFO_TG_BOT="Telegram bot: need token from @BotFather and your chat_id (get it: @userinfobot)."
INFO_TG_BOT_RU="Telegram-бот: нужен токен от @BotFather и твой chat_id (узнать: @userinfobot)."

INFO_ALERT_THRESHOLDS="Alert thresholds (in %, Enter = default):"
INFO_ALERT_THRESHOLDS_RU="Пороги алертов (в %, Enter = по умолчанию):"

# ── Summary ───────────────────────────────────────────────────
OK_DOMAIN="Domain:"
OK_DOMAIN_RU="Домен:"

OK_EMAIL="Email:"
OK_EMAIL_RU="Email:"

OK_TG_CONFIGURED="Telegram: configured (report at [REPORT_TIME] UTC)"
OK_TG_CONFIGURED_RU="Telegram: настроен (отчёт в [REPORT_TIME] UTC)"

WARN_TG_SKIPPED="Telegram: skipped (can be added later)"
WARN_TG_SKIPPED_RU="Telegram: пропущен (можно добавить позже)"

# ── Step titles ───────────────────────────────────────────────
STEP_CHECK_SUBNET="Step 1/12 — Subnet reputation check"
STEP_CHECK_SUBNET_RU="Шаг 1/12 — Проверка репутации подсети"

STEP_UPDATE="Step 2/12 — System update"
STEP_UPDATE_RU="Шаг 2/12 — Обновление системы"

STEP_AUTO_UPDATES="Step 3/12 — Security auto-updates"
STEP_AUTO_UPDATES_RU="Шаг 3/12 — Автообновления безопасности"

STEP_BBR="Step 4/12 — BBR and network optimization"
STEP_BBR_RU="Шаг 4/12 — BBR и оптимизация сети"

STEP_FIREWALL="Step 5/12 — Firewall (ufw)"
STEP_FIREWALL_RU="Шаг 5/12 — Файрвол (ufw)"

STEP_FAIL2BAN="Step 6/12 — Fail2ban"
STEP_FAIL2BAN_RU="Шаг 6/12 — Fail2ban"

STEP_SINGBOX="Step 7/12 — Sing-box"
STEP_SINGBOX_RU="Шаг 7/12 — Sing-box"

STEP_KEYS="Step 8/12 — Reality keypair and ports"
STEP_KEYS_RU="Шаг 8/12 — Ключи Reality и порты"

STEP_MARZBAN="Step 9/12 — Marzban"
STEP_MARZBAN_RU="Шаг 9/12 — Marzban"

STEP_SSL="Step 10/12 — SSL certificate (Let's Encrypt)"
STEP_SSL_RU="Шаг 10/12 — SSL сертификат (Let's Encrypt)"

STEP_CONFIGURE="Step 11/12 — Marzban and 5-profile Sing-box configuration"
STEP_CONFIGURE_RU="Шаг 11/12 — Конфигурация Marzban и 5 профилей Sing-box"

STEP_TELEGRAM="Step 12/12 — Telegram bot"
STEP_TELEGRAM_RU="Шаг 12/12 — Telegram-бот"

# ── Subnet check ──────────────────────────────────────────────
# Примечание: SERVER_IP определяется динамически через get_server_ip()
get_server_ip_info() {
  local ip="${SERVER_IP:-[IP]}"
  echo "IP сервера: ${ip}"
}
get_server_ip_info_en() {
  local ip="${SERVER_IP:-[IP]}"
  echo "Server IP: ${ip}"
}

INFO_CHECKING_NEIGHBORS="Checking neighboring IPs in /24 range..."
INFO_CHECKING_NEIGHBORS_RU="Проверяю соседние адреса в диапазоне /24..."

OK_SUBNET_CLEAN="In [CHECKED] checked neighbor IPs — 0 VPN/hosting servers. Subnet is clean ✓"
OK_SUBNET_CLEAN_RU="В [CHECKED] проверенных соседних IP — 0 VPN/хостинг серверов. Подсеть чистая ✓"

WARN_SUBNET_MODERATE="Detected [VPN_COUNT] VPN/hosting servers in [CHECKED] checked IPs — moderate risk"
WARN_SUBNET_MODERATE_RU="Обнаружено [VPN_COUNT] VPN/хостинг серверов в [CHECKED] проверенных IP — риск умеренный"

WARN_SUBNET_ADVICE="Advice: monitor stability, change provider if problems occur"
WARN_SUBNET_ADVICE_RU="Совет: следи за стабильностью, при проблемах смени провайдера"

WARN_SUBNET_HIGH="Detected [VPN_COUNT] VPN/hosting servers in [CHECKED] checked IPs — HIGH risk"
WARN_SUBNET_HIGH_RU="Обнаружено [VPN_COUNT] VPN/хостинг серверов в [CHECKED] проверенных IP — риск ВЫСОКИЙ"

WARN_SUBNET_LIKELY_BLOCKED="Subnet is likely well-known to blocking systems."
WARN_SUBNET_LIKELY_BLOCKED_RU="Подсеть скорее всего хорошо известна системам блокировок."

WARN_SUBNET_RECOMMEND="Recommended to change provider or request IP from different range."
WARN_SUBNET_RECOMMEND_RU="Рекомендуется сменить провайдера или запросить IP из другого диапазона."

WARN_CONTINUE_ANYWAY="Continue installation despite the warning? (y/n):"
WARN_CONTINUE_ANYWAY_RU="Продолжить установку несмотря на предупреждение? (y/n):"

ERR_USER_ABORTED="Installation aborted by user"
ERR_USER_ABORTED_RU="Установка прервана пользователем"

# ── System update ─────────────────────────────────────────────
OK_SYSTEM_UPDATED="System updated, dependencies installed"
OK_SYSTEM_UPDATED_RU="Система обновлена, зависимости установлены"

# ── Auto updates ──────────────────────────────────────────────
OK_AUTO_UPDATES_CONFIGURED="Security auto-updates configured (no interactive dialogs)"
OK_AUTO_UPDATES_CONFIGURED_RU="Автообновления security-патчей настроены (без интерактивных диалогов)"

# ── BBR ───────────────────────────────────────────────────────
OK_BBR="TCP congestion control: [CURRENT]"
OK_BBR_RU="TCP congestion control: [CURRENT]"

# ── Firewall ──────────────────────────────────────────────────
OK_FIREWALL="Firewall enabled: 22/tcp, 443/tcp, 443/udp"
OK_FIREWALL_RU="Файрвол включён: 22/tcp, 443/tcp, 443/udp"

WARN_SSH_PORT="SSH: after checking new port, close 22 → ufw delete allow 22/tcp"
WARN_SSH_PORT_RU="SSH: после проверки нового порта закрой 22 → ufw delete allow 22/tcp"

# ── Fail2ban ──────────────────────────────────────────────────
OK_FAIL2BAN="Fail2ban: SSH protection on port [SSH_PORT] (3 attempts → 24h ban)"
OK_FAIL2BAN_RU="Fail2ban: SSH защита на порту [SSH_PORT] (3 попытки → бан 24ч)"

# ── Sing-box ──────────────────────────────────────────────────
INFO_GETTING_SINGBOX="Getting latest version from GitHub..."
INFO_GETTING_SINGBOX_RU="Получаю последнюю версию с GitHub..."

INFO_DOWNLOADING_SINGBOX="Downloading Sing-box [SB_TAG]..."
INFO_DOWNLOADING_SINGBOX_RU="Скачиваю Sing-box [SB_TAG]..."

OK_SINGBOX_INSTALLED="Sing-box [SB_TAG] ($(arch)) installed"
OK_SINGBOX_INSTALLED_RU="Sing-box [SB_TAG] ($(arch)) установлен"

# ── Keys and ports ────────────────────────────────────────────
OK_REALITY_GENERATED="Reality keypair generated, camouflage: [REALITY_SNI]"
OK_REALITY_GENERATED_RU="Reality keypair сгенерирован, camouflage: [REALITY_SNI]"

OK_PORTS_GENERATED="Ports → Trojan:[TROJAN_PORT] SS:[SS_PORT] Panel:[PANEL_PORT] Subscription:[SUB_PORT]"
OK_PORTS_GENERATED_RU="Порты → Trojan:[TROJAN_PORT] SS:[SS_PORT] Панель:[PANEL_PORT] Подписки:[SUB_PORT]"

# ── Marzban ───────────────────────────────────────────────────
INFO_INSTALLING_MARZBAN="Installing Marzban..."
INFO_INSTALLING_MARZBAN_RU="Устанавливаю Marzban..."

ERR_MARZBAN_INSTALL="Marzban installation failed. Log: journalctl -u marzban -n 50"
ERR_MARZBAN_INSTALL_RU="Установка Marzban не удалась. Лог: journalctl -u marzban -n 50"

ERR_MARZBAN_SCRIPT_NOT_FOUND="Marzban installation script not found"
ERR_MARZBAN_SCRIPT_NOT_FOUND_RU="Скрипт установки Marzban не найден"

OK_MARZBAN_INSTALLED="Marzban installed"
OK_MARZBAN_INSTALLED_RU="Marzban установлен"

# ── SSL ───────────────────────────────────────────────────────
INFO_INSTALLING_ACME="Installing acme.sh..."
INFO_INSTALLING_ACME_RU="Устанавливаю acme.sh..."

INFO_REQUESTING_CERT="Requesting certificate for [DOMAIN]..."
INFO_REQUESTING_CERT_RU="Запрашиваю сертификат для [DOMAIN]..."

ERR_CERT_FAILED="Failed to obtain certificate. Check A record: [DOMAIN] → [SERVER_IP]"
ERR_CERT_FAILED_RU="Не удалось получить сертификат. Проверь A-запись: [DOMAIN] → [SERVER_IP]"

OK_SSL_CONFIGURED="SSL certificate obtained, auto-renewal configured"
OK_SSL_CONFIGURED_RU="SSL сертификат получен, автопродление настроено"

# ── Configuration ─────────────────────────────────────────────
OK_MARZBAN_ENV_CONFIGURED="Marzban .env configured"
OK_MARZBAN_ENV_CONFIGURED_RU="Marzban .env настроен"

OK_SINGBOX_TEMPLATE="Sing-box template with 5 profiles created"
OK_SINGBOX_TEMPLATE_RU="Sing-box шаблон с 5 профилями создан"

# ── Final messages ────────────────────────────────────────────
SUCCESS_TITLE="CubiVeil installed successfully! 🎉"
SUCCESS_TITLE_RU="CubiVeil установлен успешно! 🎉"

SUCCESS_PANEL_URL="Panel URL:"
SUCCESS_PANEL_URL_RU="URL панели:"

SUCCESS_SUBSCRIPTION_URL="Subscription URL:"
SUCCESS_SUBSCRIPTION_URL_RU="URL подписки:"

SUCCESS_PROFILES="Profiles:"
SUCCESS_PROFILES_RU="Профили:"

SUCCESS_TELEGRAM="Telegram:"
SUCCESS_TELEGRAM_RU="Telegram:"

SUCCESS_HEALTH_CHECK="Health Check:"
SUCCESS_HEALTH_CHECK_RU="Health Check:"

SUCCESS_CREDENTIALS="Credentials:"
SUCCESS_CREDENTIALS_RU="Учётные данные:"

SUCCESS_KEY="Key:"
SUCCESS_KEY_RU="Ключ:"

SUCCESS_INSTRUCTIONS="Instructions:"
SUCCESS_INSTRUCTIONS_RU="Инструкция:"

WARN_CHANGE_SSH="⚠  Change SSH port and close 22 (see README)"
WARN_CHANGE_SSH_RU="⚠  Смени порт SSH и закрой 22 (инструкция в README)"

NEXT_STEPS="Next steps:"
NEXT_STEPS_RU="Следующие шаги:"

STEP_CREATE_USERS="1. Log in to panel → create users"
STEP_CREATE_USERS_RU="1. Зайди в панель → создай пользователей"

STEP_SUBSCRIPTION="2. Copy Subscription URL to Mihomo on router"
STEP_SUBSCRIPTION_RU="2. Subscription URL скопируй в Mihomo на роутере"

STEP_SSH_SECURITY="3. Change SSH port, close 22 in ufw"
STEP_SSH_SECURITY_RU="3. Смени порт SSH, закрой 22 в ufw"

STEP_SAVE_KEY="4. Save age key in a secure location!"
STEP_SAVE_KEY_RU="4. Сохрани ключ age в безопасном месте!"

# ── Update messages ──────────────────────────────────────────────
MSG_TITLE_UPDATE="CubiVeil — Update Utility"
MSG_TITLE_CHECK="Check version"
MSG_TITLE_DOWNLOAD="Download new version"
MSG_TITLE_BACKUP="Backup current version"
MSG_TITLE_INSTALL="Install update"
MSG_TITLE_FINISH="Update complete"

MSG_MSG_CURRENT_VERSION="Current version"
MSG_MSG_LATEST_VERSION="Latest version"
MSG_MSG_UP_TO_DATE="Latest version installed"
MSG_MSG_NEW_VERSION_AVAILABLE="New version available"
MSG_MSG_UPDATE_AVAILABLE="Update available"
MSG_MSG_DOWNLOADING="Downloading files..."
MSG_MSG_BACKING_UP="Creating backup..."
MSG_MSG_INSTALLING="Installing update..."
MSG_MSG_SUCCESS="Update completed successfully"
MSG_MSG_NO_UPDATE="No updates required"

MSG_ERR_NOT_INSTALLED="CubiVeil not installed in [CUBIVEIL_DIR]"
MSG_ERR_DOWNLOAD_FAILED="Failed to download update files"
MSG_ERR_BACKUP_FAILED="Failed to create backup"
MSG_ERR_INSTALL_FAILED="Failed to install update"
MSG_ERR_GIT_FAILED="Failed to get version info"

MSG_TITLE_UPDATE_RU="CubiVeil — Утилита обновления"
MSG_TITLE_CHECK_RU="Проверка версии"
MSG_TITLE_DOWNLOAD_RU="Загрузка новой версии"
MSG_TITLE_BACKUP_RU="Бэкап текущей версии"
MSG_TITLE_INSTALL_RU="Установка обновления"
MSG_TITLE_FINISH_RU="Обновление завершено"

MSG_MSG_CURRENT_VERSION_RU="Текущая версия"
MSG_MSG_LATEST_VERSION_RU="Последняя версия"
MSG_MSG_UP_TO_DATE_RU="Установлена последняя версия"
MSG_MSG_NEW_VERSION_AVAILABLE_RU="Доступна новая версия"
MSG_MSG_UPDATE_AVAILABLE_RU="Доступно обновление"
MSG_MSG_DOWNLOADING_RU="Загрузка файлов..."
MSG_MSG_BACKING_UP_RU="Создание бэкапа..."
MSG_MSG_INSTALLING_RU="Установка обновления..."
MSG_MSG_SUCCESS_RU="Обновление успешно завершено"
MSG_MSG_NO_UPDATE_RU="Обновлений не требуется"

MSG_ERR_NOT_INSTALLED_RU="CubiVeil не установлен в [CUBIVEIL_DIR]"
MSG_ERR_DOWNLOAD_FAILED_RU="Не удалось загрузить файлы обновления"
MSG_ERR_BACKUP_FAILED_RU="Не удалось создать бэкап"
MSG_ERR_INSTALL_FAILED_RU="Не удалось установить обновление"
MSG_ERR_GIT_FAILED_RU="Не удалось получить информацию о версии"

# ── Rollback messages ──────────────────────────────────────────────
MSG_TITLE_ROLLBACK="CubiVeil — Rollback Utility"
MSG_TITLE_ROLLBACK_CHECK="Check backup"
MSG_TITLE_STOP="Stop services"
MSG_TITLE_RESTORE="Restore files"
MSG_TITLE_CONFIG="Restore configuration"
MSG_TITLE_START="Start services"
MSG_TITLE_ROLLBACK_FINISH="Rollback complete"

MSG_MSG_AVAILABLE_BACKUPS="Available backups"
MSG_MSG_SELECTED_BACKUP="Selected backup"
MSG_MSG_RESTORING="Restoring from backup..."
MSG_MSG_RESTORED="Restored from backup"
MSG_MSG_ROLLBACK_SUCCESS="Rollback completed successfully"

MSG_ERR_NO_BACKUPS="No backups found in [BACKUP_DIR]"
MSG_ERR_BACKUP_INVALID="Invalid backup: missing structure"
MSG_ERR_RESTORE_FAILED="Failed to restore files"
MSG_ERR_STOP_FAILED="Failed to stop services"
MSG_ERR_START_FAILED="Failed to start services"

MSG_PROMPT_SELECT_BACKUP="Select backup"
MSG_PROMPT_CONFIRM="Confirm rollback"

MSG_TITLE_ROLLBACK_RU="CubiVeil — Утилита отката"
MSG_TITLE_ROLLBACK_CHECK_RU="Проверка бэкапа"
MSG_TITLE_STOP_RU="Остановка сервисов"
MSG_TITLE_RESTORE_RU="Восстановление файлов"
MSG_TITLE_CONFIG_RU="Восстановление конфигурации"
MSG_TITLE_START_RU="Запуск сервисов"
MSG_TITLE_ROLLBACK_FINISH_RU="Откат завершён"

MSG_MSG_AVAILABLE_BACKUPS_RU="Доступные бэкапы"
MSG_MSG_SELECTED_BACKUP_RU="Выбранный бэкап"
MSG_MSG_RESTORING_RU="Восстановление из бэкапа..."
MSG_MSG_RESTORED_RU="Восстановлено из бэкапа"
MSG_MSG_ROLLBACK_SUCCESS_RU="Откат успешно завершён"

MSG_ERR_NO_BACKUPS_RU="Бэкапы не найдены в [BACKUP_DIR]"
MSG_ERR_BACKUP_INVALID_RU="Некорректный бэкап: отсутствует структура"
MSG_ERR_RESTORE_FAILED_RU="Не удалось восстановить файлы"
MSG_ERR_STOP_FAILED_RU="Не удалось остановить сервисы"
MSG_ERR_START_FAILED_RU="Не удалось запустить сервисы"

MSG_PROMPT_SELECT_BACKUP_RU="Выберите бэкап"
MSG_PROMPT_CONFIRM_RU="Подтвердить откат"

# ── Общие сообщения ───────────────────────────────────────────────
MSG_INFO_ENV_CHECKED="Environment checked"
MSG_INFO_ENV_CHECKED_RU="Окружение проверено"

MSG_INFO_INSTALLING="Installing..."
MSG_INFO_INSTALLING_RU="Устанавливаю..."

MSG_INFO_DOWNLOADING="Downloading..."
MSG_INFO_DOWNLOADING_RU="Загружаю..."

MSG_INFO_FILES_LOADED="Files loaded"
MSG_INFO_FILES_LOADED_RU="Файлы загружены"

MSG_INFO_UPDATE_INSTALLED="Update installed"
MSG_INFO_UPDATE_INSTALLED_RU="Обновление установлено"

MSG_INFO_SERVICES_STOPPED="Services stopped"
MSG_INFO_SERVICES_STOPPED_RU="Сервисы остановлены"

MSG_INFO_SERVICES_STARTED="Services started"
MSG_INFO_SERVICES_STARTED_RU="Сервисы запущены"

MSG_PROMPT_UPDATE="Perform update?"
MSG_PROMPT_UPDATE_RU="Выполнить обновление?"

MSG_PROMPT_CONTINUE="Continue?"
MSG_PROMPT_CONTINUE_RU="Продолжить?"

MSG_INFO_UPDATE_CANCELLED="Update cancelled"
MSG_INFO_UPDATE_CANCELLED_RU="Обновление отменено"

MSG_INFO_ROLLBACK_CANCELLED="Rollback cancelled"
MSG_INFO_ROLLBACK_CANCELLED_RU="Откат отменён"

MSG_WARNING_RESTART_SERVICES="Restart services?"
MSG_WARNING_RESTART_SERVICES_RU="Перезапустить сервисы?"

MSG_INFO_RESTARTING="Restarting services..."
MSG_INFO_RESTARTING_RU="Перезапуск сервисов..."

MSG_INFO_SERVICES_RESTARTED="Services restarted"
MSG_INFO_SERVICES_RESTARTED_RU="Сервисы перезапущены"

MSG_WARN_CURRENT_DATA_REPLACED="Current data will be replaced with backup data!"
MSG_WARN_CURRENT_DATA_REPLACED_RU="Текущие данные будут заменены данными из бэкапа!"

MSG_WARN_CONTINUE_ROLLBACK="Perform rollback?"
MSG_WARN_CONTINUE_ROLLBACK_RU="Продолжить откат?"

MSG_INFO_BACKUP_CREATED="Backup created:"
MSG_INFO_BACKUP_CREATED_RU="Бэкап создан:"

MSG_INFO_ROLLBACK_FROM="Rollback performed from:"
MSG_INFO_ROLLBACK_FROM_RU="Откат выполнен из:"

MSG_WARN_SERVICE_NOT_STARTED="Marzban not started — check logs"
MSG_WARN_SERVICE_NOT_STARTED_RU="Marzban не запустился — проверьте логи"

MSG_WARN_SINGBOX_NOT_STARTED="Sing-box not started — check logs"
MSG_WARN_SINGBOX_NOT_STARTED_RU="Sing-box не запустился — проверьте логи"

MSG_ERR_ROOT_REQUIRED="Root access required"
MSG_ERR_ROOT_REQUIRED_RU="Требуется запуск от root"

# shellcheck disable=SC2154
MSG_ERR_COMMAND_REQUIRED="[cmd] required but not installed"
MSG_ERR_COMMAND_REQUIRED_RU="Требуется [cmd], но он не установлен"

# ── Utils messages ─────────────────────────────────────────────────
MSG_ERR_NO_FREE_PORT="Failed to find free port after {MAX} attempts"
MSG_ERR_NO_FREE_PORT_RU="Не удалось найти свободный порт после {MAX} попыток"

MSG_ERR_OPEN_PORT="Failed to open port {PORT}/{PROTO} in firewall"
MSG_ERR_OPEN_PORT_RU="Не удалось открыть порт {PORT}/{PROTO} в файрволе"

MSG_ERR_INVALID_PORT="Invalid port: {PORT}"
MSG_ERR_INVALID_PORT_RU="Невалидный порт: {PORT}"

MSG_ERR_UNKNOWN_ARCH="Unknown architecture: {ARCH}"
MSG_ERR_UNKNOWN_ARCH_RU="Неизвестная архитектура: {ARCH}"

# ── Install script messages ─────────────────────────────────────────
MSG_SELECT_LANGUAGE="Select language / Выберите язык:"
MSG_SELECT_LANGUAGE_RU="Выберите язык:"

MSG_OPTION_RU="Русский"
MSG_OPTION_EN="English"

MSG_INVALID_CHOICE="Invalid choice"
MSG_INVALID_CHOICE_RU="Неверный выбор"

MSG_PRE_INSTALL_SETUP="Pre-installation setup"
MSG_PRE_INSTALL_SETUP_RU="Настройка перед установкой"

MSG_BROWSERS_SECURITY_WARNING="Browsers will show a security warning"
MSG_BROWSERS_SECURITY_WARNING_RU="Браузеры покажут предупреждение о безопасности"

MSG_DO_NOT_USE_PRODUCTION="Do not use in production!"
MSG_DO_NOT_USE_PRODUCTION_RU="Не используйте в production!"

MSG_DNS_A_RECORD_HINT="Make sure the domain A record already points to this server."
MSG_DNS_A_RECORD_HINT_RU="Убедитесь, что A-запись домена уже указывает на этот сервер."

MSG_LE_DNS_CHECK="Let's Encrypt will check DNS — install will fail without a valid A record."
MSG_LE_DNS_CHECK_RU="Let's Encrypt проверит DNS — установка упадёт без правильной A-записи."

MSG_PROMPT_DOMAIN="Domain for panel (e.g. panel.example.com):"
MSG_PROMPT_DOMAIN_RU="Домен для панели (например panel.example.com):"

MSG_CANNOT_RESOLVE_DOMAIN="Cannot resolve {DOMAIN}. Check your A record."
MSG_CANNOT_RESOLVE_DOMAIN_RU="Не удалось разрешить {DOMAIN}. Проверьте A-запись."

MSG_CONTINUE_DESPITE_ERROR="Continue despite the error? (y/n):"
MSG_CONTINUE_DESPITE_ERROR_RU="Продолжить несмотря на ошибку? (y/n):"

MSG_A_RECORD_MISMATCH="A record {DOMAIN} → {RESOLVED}, but server IP: {SERVER_IP}"
MSG_A_RECORD_MISMATCH_RU="A-запись {DOMAIN} → {RESOLVED}, но IP сервера: {SERVER_IP}"

MSG_CONTINUE_DESPITE_MISMATCH="Continue despite the mismatch? (y/n):"
MSG_CONTINUE_DESPITE_MISMATCH_RU="Продолжить несмотря на несоответствие? (y/n):"

MSG_PROMPT_EMAIL="Email for Let's Encrypt [admin@{DOMAIN}]:"
MSG_PROMPT_EMAIL_RU="Email для Let's Encrypt [admin@{DOMAIN}]:"

MSG_INVALID_EMAIL="Invalid email. Example: admin@{DOMAIN}"
MSG_INVALID_EMAIL_RU="Некорректный email. Пример: admin@{DOMAIN}"

MSG_PROMPT_TELEGRAM="Install Telegram bot for monitoring and control? (y/n):"
MSG_PROMPT_TELEGRAM_RU="Установить Telegram-бот для мониторинга и управления? (y/n):"

MSG_TELEGRAM_WILL_BE_INSTALLED="Telegram bot will be installed after main components"
MSG_TELEGRAM_WILL_BE_INSTALLED_RU="Telegram-бот будет установлен после основных компонентов"

MSG_STEP_1_8_SYSTEM="Step 1/8 — System update and base configuration"
MSG_STEP_1_8_SYSTEM_RU="Шаг 1/8 — Обновление системы и базовые настройки"

MSG_STEP_2_8_FIREWALL="Step 2/8 — Firewall (UFW)"
MSG_STEP_2_8_FIREWALL_RU="Шаг 2/8 — Файрвол (UFW)"

MSG_STEP_3_8_FAIL2BAN="Step 3/8 — Fail2ban"
MSG_STEP_3_8_FAIL2BAN_RU="Шаг 3/8 — Fail2ban"

MSG_STEP_4_8_SINGBOX="Step 4/8 — Sing-box"
MSG_STEP_4_8_SINGBOX_RU="Шаг 4/8 — Sing-box"

MSG_STEP_5_8_SSL="Step 5/8 — SSL certificate"
MSG_STEP_5_8_SSL_RU="Шаг 5/8 — SSL сертификат"

MSG_STEP_6_8_MARZBAN="Step 6/8 — Marzban"
MSG_STEP_6_8_MARZBAN_RU="Шаг 6/8 — Marzban"

MSG_STEP_7_8_DECOY="Step 7/8 — Decoy site"
MSG_STEP_7_8_DECOY_RU="Шаг 7/8 — Сайт-прикрытие (decoy)"

MSG_STEP_8_8_TRAFFIC="Step 8/8 — Traffic shaping"
MSG_STEP_8_8_TRAFFIC_RU="Шаг 8/8 — Traffic shaping"

MSG_STEP_9_9_TELEGRAM="Step 9/9 — Telegram bot"
MSG_STEP_9_9_TELEGRAM_RU="Шаг 9/9 — Telegram-бот"

MSG_MODULE_NOT_FOUND="Module not found, skipping: {NAME}"
MSG_MODULE_NOT_FOUND_RU="Модуль не найден, пропускаем: {NAME}"

MSG_DRY_RUN_WOULD_RUN="[DRY-RUN] Would run: {NAME}"
MSG_DRY_RUN_WOULD_RUN_RU="[DRY-RUN] Запустил бы: {NAME}"

MSG_PORTS_GENERATED="Ports → Trojan:{TROJAN} SS:{SS} Panel:{PANEL} Subscription:{SUB}"
MSG_PORTS_GENERATED_RU="Порты → Trojan:{TROJAN} SS:{SS} Панель:{PANEL} Подписки:{SUB}"

MSG_DRY_RUN_TITLE="[DRY-RUN] Installation plan / План установки"
MSG_DRY_RUN_TITLE_RU="[DRY-RUN] План установки"

MSG_DRY_RUN_NO_CHANGES="[DRY-RUN] No changes were made to the system."
MSG_DRY_RUN_NO_CHANGES_RU="[DRY-RUN] Никаких изменений в систему не внесено."

MSG_INSTALLED_SUCCESSFULLY="installed successfully! 🎉"
MSG_INSTALLED_SUCCESSFULLY_RU="установлен успешно! 🎉"

MSG_NEXT_STEP_CREATE_USERS="1. Log in to panel → create users"
MSG_NEXT_STEP_CREATE_USERS_RU="1. Зайдите в панель → создайте пользователей"

MSG_NEXT_STEP_SUBSCRIPTION="2. Copy Subscription URL to your client"
MSG_NEXT_STEP_SUBSCRIPTION_RU="2. Subscription URL скопируйте в Mihomo/клиент"

MSG_NEXT_STEP_SSH="3. Change SSH port, close 22 in UFW"
MSG_NEXT_STEP_SSH_RU="3. Смените SSH порт, закройте 22 в UFW"

MSG_NEXT_STEP_TELEGRAM="4. Setup Telegram bot: bash setup-telegram.sh"
MSG_NEXT_STEP_TELEGRAM_RU="4. Установите Telegram-бот: bash setup-telegram.sh"

MSG_MIKROTIK_SCRIPT="MikroTik RouterOS script (decoy-site):"
MSG_MIKROTIK_SCRIPT_RU="MikroTik RouterOS скрипт (decoy-site):"

MSG_ADMIN_CREDENTIALS="Marzban Admin Credentials:"
MSG_ADMIN_CREDENTIALS_RU="Данные администратора Marzban:"

MSG_FAILED_DOWNLOAD="Failed to download: {FILE}"
MSG_FAILED_DOWNLOAD_RU="Не удалось загрузить: {FILE}"

MSG_CRITICAL_FILE_MISSING="Critical file missing: {FILE}"
MSG_CRITICAL_FILE_MISSING_RU="Критический файл отсутствует: {FILE}"

MSG_CLONE_AND_RUN="Clone the repo and run manually:"
MSG_CLONE_AND_RUN_RU="Склонируйте репозиторий и запустите вручную:"

MSG_FAILED_PREPARE="Failed to prepare installation files"
MSG_FAILED_PREPARE_RU="Не удалось подготовить файлы установки"
