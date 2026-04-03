#!/bin/bash
# shellcheck disable=SC1071
# shellcheck disable=SC2034,SC2154
# ╔═══════════════════════════════════════════════════════════╗
# ║         CubiVeil — Main Localization                      ║
# ║                   EN / RU strings                         ║
# ║                                                           ║
# ║  Основной файл локализации для install.sh и утилит        ║
# ╚═══════════════════════════════════════════════════════════╝

# Guard check - не подключать повторно
if [[ -n "${_CUBIVEIL_LANG_LOADED:-}" ]]; then
  return 0
fi
_CUBIVEIL_LANG_LOADED=1

set -euo pipefail

# ── Язык по умолчанию / Default language ─────────────────────
# Раскомментируй нужную строку / Uncomment the line you need:
# LANG_NAME="English"

# Устанавливаем язык только если ещё не определён (защита от сброса)
if [[ -z "${LANG_NAME:-}" ]]; then
  LANG_NAME="Русский"
fi

# ── Определение директории скрипта ───────────────────────────
LANG_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${LANG_SCRIPT_DIR}/.." && pwd)"

# ── Подключение унифицированного модуля локализации ───────
# ПРИМЕЧАНИЕ: i18n.sh уже должен быть загружен через init.sh
# Это подключение для обратной совместимости при прямом вызове
if [[ -f "${PROJECT_ROOT}/lib/i18n.sh" ]]; then
  source "${PROJECT_ROOT}/lib/i18n.sh"
fi

# ── Проверки / Checks ─────────────────────────────────────────
ERR_ROOT="Scripts must be run as root (sudo)"
ERR_ROOT_RU="Запускай от root"
ERR_UBUNTU="This script is only for Ubuntu"
ERR_UBUNTU_RU="Скрипт только для Ubuntu"
ERR_SUI_NOT_FOUND="S-UI not found. Run main installer first: bash install.sh"
ERR_SUI_NOT_FOUND_RU="S-UI не найдена. Сначала запусти основной установщик: bash install.sh"
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

STEP_SUI="Step 7/12 — S-UI Panel"
STEP_SUI_RU="Шаг 7/12 — Панель S-UI"

STEP_KEYS="Step 8/12 — Reality keypair and ports"
STEP_KEYS_RU="Шаг 8/12 — Ключи Reality и порты"

STEP_SSL="Step 9/12 — SSL certificate (Let's Encrypt)"
STEP_SSL_RU="Шаг 9/12 — SSL сертификат (Let's Encrypt)"

STEP_CONFIGURE="Step 10/12 — S-UI configuration"
STEP_CONFIGURE_RU="Шаг 10/12 — Конфигурация S-UI"

STEP_TELEGRAM="Step 11/12 — Telegram bot"
STEP_TELEGRAM_RU="Шаг 11/12 — Telegram-бот"

STEP_FINISH="Step 12/12 — Finish"
STEP_FINISH_RU="Шаг 12/12 — Завершение"

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

# ── S-UI ──────────────────────────────────────────────────────
INFO_INSTALLING_SUI="Installing S-UI panel..."
INFO_INSTALLING_SUI_RU="Устанавливаю панель S-UI..."

ERR_SUI_INSTALL="S-UI installation failed. Log: journalctl -u s-ui -n 50"
ERR_SUI_INSTALL_RU="Установка S-UI не удалась. Лог: journalctl -u s-ui -n 50"

ERR_SUI_SCRIPT_NOT_FOUND="S-UI installation script not found"
ERR_SUI_SCRIPT_NOT_FOUND_RU="Скрипт установки S-UI не найден"

OK_SUI_INSTALLED="S-UI installed"
OK_SUI_INSTALLED_RU="S-UI установлена"

# ── Keys and ports ────────────────────────────────────────────
OK_REALITY_GENERATED="Reality keypair generated, camouflage: [REALITY_SNI]"
OK_REALITY_GENERATED_RU="Reality keypair сгенерирован, camouflage: [REALITY_SNI]"

OK_PORTS_GENERATED="Ports → Panel:[PANEL_PORT] Subscription:[SUB_PORT]"
OK_PORTS_GENERATED_RU="Порты → Панель:[PANEL_PORT] Подписки:[SUB_PORT]"

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
OK_SUI_CONFIGURED="S-UI configured"
OK_SUI_CONFIGURED_RU="S-UI настроена"

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

MSG_WARN_SERVICE_NOT_STARTED="S-UI not started — check logs"
MSG_WARN_SERVICE_NOT_STARTED_RU="S-UI не запустилась — проверьте логи"

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

MSG_STEP_1_8_SYSTEM="System update and base configuration"
MSG_STEP_1_8_SYSTEM_RU="Обновление системы и базовые настройки"

MSG_STEP_2_8_FIREWALL="Firewall (UFW)"
MSG_STEP_2_8_FIREWALL_RU="Файрвол (UFW)"

MSG_STEP_3_8_FAIL2BAN="Fail2ban"
MSG_STEP_3_8_FAIL2BAN_RU="Fail2ban"

MSG_STEP_4_8_SSL="SSL certificate"
MSG_STEP_4_8_SSL_RU="SSL сертификат"

MSG_STEP_5_8_SUI="S-UI Panel"
MSG_STEP_5_8_SUI_RU="Панель S-UI"

MSG_STEP_PROFILES="VPN Profiles"
MSG_STEP_PROFILES_RU="VPN профили"

MSG_STEP_6_8_DECOY="Decoy site"
MSG_STEP_6_8_DECOY_RU="Сайт-прикрытие (decoy)"

MSG_STEP_7_8_TRAFFIC="Traffic shaping"
MSG_STEP_7_8_TRAFFIC_RU="Traffic shaping"

MSG_STEP_8_8_TELEGRAM="Telegram bot"
MSG_STEP_8_8_TELEGRAM_RU="Telegram-бот"

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

MSG_ADMIN_CREDENTIALS="S-UI Admin Credentials:"
MSG_ADMIN_CREDENTIALS_RU="Данные администратора S-UI:"

MSG_FAILED_DOWNLOAD="Failed to download: {FILE}"
MSG_FAILED_DOWNLOAD_RU="Не удалось загрузить: {FILE}"

MSG_CRITICAL_FILE_MISSING="Critical file missing: {FILE}"
MSG_CRITICAL_FILE_MISSING_RU="Критический файл отсутствует: {FILE}"

MSG_CLONE_AND_RUN="Clone the repo and run manually:"
MSG_CLONE_AND_RUN_RU="Склонируйте репозиторий и запустите вручную:"

MSG_FAILED_PREPARE="Failed to prepare installation files"
MSG_FAILED_PREPARE_RU="Не удалось подготовить файлы установки"

# ══════════════════════════════════════════════════════════════
# INSTALLER: ORCHESTRATOR
# ══════════════════════════════════════════════════════════════
MSG_MODULE_INSTALL_FAILED="module_install failed for {NAME}"
MSG_MODULE_INSTALL_FAILED_RU="module_install не удался для {NAME}"

MSG_MODULE_CONFIGURE_FAILED="module_configure failed for {NAME}"
MSG_MODULE_CONFIGURE_FAILED_RU="module_configure не удался для {NAME}"

MSG_MODULE_ENABLE_FAILED="module_enable failed for {NAME}"
MSG_MODULE_ENABLE_FAILED_RU="module_enable не удался для {NAME}"

MSG_MODULE_OK="Module {NAME}: ✓ OK"
MSG_MODULE_OK_RU="Модуль {NAME}: ✓ OK"

MSG_MODULE_SKIPPED_ISSUES="Module {NAME}: ⚠ Skipped with issues"
MSG_MODULE_SKIPPED_ISSUES_RU="Модуль {NAME}: ⚠ Пропущен с ошибками"

MSG_MODULE_SKIPPED="⚠ Skipped"
MSG_MODULE_SKIPPED_RU="⚠ Пропущен"

MSG_DRY_RUN_SKIPPED="✓ DRY-RUN: {NAME} skipped"
MSG_DRY_RUN_SKIPPED_RU="✓ DRY-RUN: {NAME} пропущен"

MSG_TELEGRAM_SETUP_NOT_FOUND="Telegram bot setup script not found: {SCRIPT}"
MSG_TELEGRAM_SETUP_NOT_FOUND_RU="Скрипт настройки Telegram-бота не найден: {SCRIPT}"

# ══════════════════════════════════════════════════════════════
# INSTALLER: UI
# ══════════════════════════════════════════════════════════════
MSG_DRY_RUN_SIMULATION_MODE="This is a Simulation mode - no changes will be made"
MSG_DRY_RUN_SIMULATION_MODE_RU="Это режим симуляции - изменения не будут внесены"

MSG_DRY_RUN_CHECKING_ENV="Checking environment..."
MSG_DRY_RUN_CHECKING_ENV_RU="Проверка окружения..."

MSG_DRY_RUN_ROOT_ACCESS_WOULD_CHECK="[DRY-RUN] Root access: would check EUID"
MSG_DRY_RUN_ROOT_ACCESS_WOULD_CHECK_RU="[DRY-RUN] Root access: проверил бы EUID"

MSG_DRY_RUN_ROOT_ACCESS_OK="[DRY-RUN] Root access: OK"
MSG_DRY_RUN_ROOT_ACCESS_OK_RU="[DRY-RUN] Root access: OK"

MSG_DRY_RUN_UBUNTU_DETECTED_OK="[DRY-RUN] Ubuntu detected: OK"
MSG_DRY_RUN_UBUNTU_DETECTED_OK_RU="[DRY-RUN] Ubuntu обнаружен: OK"

MSG_DRY_RUN_UBUNTU_WOULD_CHECK="[DRY-RUN] Ubuntu detected: would check"
MSG_DRY_RUN_UBUNTU_WOULD_CHECK_RU="[DRY-RUN] Ubuntu обнаружен: проверил бы"

MSG_DRY_RUN_ENV_CHECKS_OK="[DRY-RUN] Environment checks: OK"
MSG_DRY_RUN_ENV_CHECKS_OK_RU="[DRY-RUN] Проверка окружения: OK"

MSG_DRY_RUN_MODE_DEV="Mode: DEV (self-signed SSL, no DNS check)"
MSG_DRY_RUN_MODE_DEV_RU="Режим: DEV (самоподписный SSL, без проверки DNS)"

MSG_DRY_RUN_MODE_PROD="Mode: PRODUCTION (Let's Encrypt)"
MSG_DRY_RUN_MODE_PROD_RU="Режим: PRODUCTION (Let's Encrypt)"

MSG_DRY_RUN_DOMAIN="Domain:"
MSG_DRY_RUN_DOMAIN_RU="Домен:"

MSG_DRY_RUN_EMAIL="Email:"
MSG_DRY_RUN_EMAIL_RU="Email:"

MSG_DRY_RUN_WILL_BE_PROMPTED="will be prompted"
MSG_DRY_RUN_WILL_BE_PROMPTED_RU="будет запрошено"

MSG_WARNINGS_DURING_INSTALL="⚠ Warnings during install:"
MSG_WARNINGS_DURING_INSTALL_RU="⚠ Предупреждения при установке:"

MSG_MIKROTIK_SCRIPT_SAVED="MikroTik script saved to: {PATH}"
MSG_MIKROTIK_SCRIPT_SAVED_RU="MikroTik скрипт сохранён в: {PATH}"

MSG_MIKROTIK_IMPORT_INSTRUCTIONS_1="1. Copy file {PATH} to your computer"
MSG_MIKROTIK_IMPORT_INSTRUCTIONS_1_RU="1. Скопируйте файл {PATH} на компьютер"

MSG_MIKROTIK_IMPORT_INSTRUCTIONS_2="2. In WinBox: Files → drag mikrotik-decoy.rsc"
MSG_MIKROTIK_IMPORT_INSTRUCTIONS_2_RU="2. В WinBox: Files → перетащите mikrotik-decoy.rsc"

MSG_MIKROTIK_IMPORT_INSTRUCTIONS_3="3. In Terminal: /import file-name=mikrotik-decoy.rsc"
MSG_MIKROTIK_IMPORT_INSTRUCTIONS_3_RU="3. В Terminal: /import file-name=mikrotik-decoy.rsc"

# ══════════════════════════════════════════════════════════════
# MODULE: FIREWALL
# ══════════════════════════════════════════════════════════════
MSG_FW_INSTALLING="Installing UFW"
MSG_FW_INSTALLING_RU="Устанавливаю UFW"

MSG_FW_ALREADY_INSTALLED="UFW already installed"
MSG_FW_ALREADY_INSTALLED_RU="UFW уже установлен"

MSG_FW_RESET="Resetting firewall rules"
MSG_FW_RESET_RU="Сбрасываю правила файрвола"

MSG_FW_RULES_RESET="Firewall rules reset"
MSG_FW_RULES_RESET_RU="Правила файрвола сброшены"

MSG_FW_CONFIGURING="Configuring firewall"
MSG_FW_CONFIGURING_RU="Настраиваю файрвол"

MSG_FW_CONFIGURED="Firewall configured: 22/tcp, 443/tcp, 443/udp"
MSG_FW_CONFIGURED_RU="Файрвол настроен: 22/tcp, 443/tcp, 443/udp"

MSG_FW_SSH_WARNING_RU="⚠️  Не забудь изменить SSH порт и закрыть порт 22!"
MSG_FW_SSH_WARNING_EN="⚠️  Don't forget to change SSH port and close port 22!"

MSG_FW_ENABLING="Enabling firewall"
MSG_FW_ENABLING_RU="Включаю файрвол"

MSG_FW_ENABLED="Firewall enabled successfully"
MSG_FW_ENABLED_RU="Файрвол успешно включён"

MSG_FW_ENABLE_FAILED="Failed to enable firewall"
MSG_FW_ENABLE_FAILED_RU="Не удалось включить файрвол"

MSG_FW_DISABLING="Disabling firewall"
MSG_FW_DISABLING_RU="Отключаю файрвол"

MSG_FW_DISABLED="Firewall disabled"
MSG_FW_DISABLED_RU="Файрвол отключён"

MSG_FW_OPENING_PORT="Opening port \${port}/\${proto}"
MSG_FW_OPENING_PORT_RU="Открываю порт \${port}/\${proto}"

MSG_FW_INVALID_PORT="Invalid port: \${port}"
MSG_FW_INVALID_PORT_RU="Невалидный порт: \${port}"

MSG_FW_OPEN_FAILED="Failed to open port \${port}/\${proto} in firewall"
MSG_FW_OPEN_FAILED_RU="Не удалось открыть порт \${port}/\${proto} в файрволе"

MSG_FW_PORT_OPENED="Port \${port}/\${proto} opened: \${comment}"
MSG_FW_PORT_OPENED_RU="Порт \${port}/\${proto} открыт: \${comment}"

MSG_FW_CLOSING_PORT="Closing port \${port}/\${proto}"
MSG_FW_CLOSING_PORT_RU="Закрываю порт \${port}/\${proto}"

MSG_FW_PORT_CLOSED="Port \${port}/\${proto} closed"
MSG_FW_PORT_CLOSED_RU="Порт \${port}/\${proto} закрыт"

MSG_FW_UPDATING="Updating firewall configuration"
MSG_FW_UPDATING_RU="Обновление конфигурации файрвола"

MSG_FW_REMOVING="Removing firewall module"
MSG_FW_REMOVING_RU="Удаление модуля файрвола"

MSG_FW_MODULE_REMOVED="Firewall module removed"
MSG_FW_MODULE_REMOVED_RU="Модуль файрвола удалён"

# ══════════════════════════════════════════════════════════════
# MODULE: FAIL2BAN
# ══════════════════════════════════════════════════════════════
MSG_F2B_INSTALLING="Installing Fail2ban"
MSG_F2B_INSTALLING_RU="Устанавливаю Fail2ban"

MSG_F2B_ALREADY_INSTALLED="Fail2ban already installed"
MSG_F2B_ALREADY_INSTALLED_RU="Fail2ban уже установлен"

MSG_F2B_CONFIGURING="Configuring Fail2ban"
MSG_F2B_CONFIGURING_RU="Настраиваю Fail2ban"

MSG_F2B_SSH_PORT="Detected SSH port: \${ssh_port}"
MSG_F2B_SSH_PORT_RU="Определён порт SSH: \${ssh_port}"

MSG_F2B_CONFIGURED="Fail2ban configured: SSH protection on port \${ssh_port}"
MSG_F2B_CONFIGURED_RU="Fail2ban настроен: защита SSH на порту \${ssh_port}"

MSG_F2B_ENABLING="Enabling Fail2ban"
MSG_F2B_ENABLING_RU="Включаю Fail2ban"

MSG_F2B_ENABLED="Fail2ban enabled successfully"
MSG_F2B_ENABLED_RU="Fail2ban успешно включён"

MSG_F2B_DISABLING="Disabling Fail2ban"
MSG_F2B_DISABLING_RU="Отключаю Fail2ban"

MSG_F2B_DISABLED="Fail2ban disabled"
MSG_F2B_DISABLED_RU="Fail2ban отключён"

MSG_F2B_CHECK_CONFIG="Checking Fail2ban configuration"
MSG_F2B_CHECK_CONFIG_RU="Проверка конфигурации Fail2ban"

MSG_F2B_CONFIG_NOT_FOUND="Fail2ban configuration file not found: \${path}"
MSG_F2B_CONFIG_NOT_FOUND_RU="Файл конфигурации Fail2ban не найден: \${path}"

MSG_F2B_CONFIG_FOUND="Fail2ban configuration found at \${path}"
MSG_F2B_CONFIG_FOUND_RU="Конфигурация Fail2ban найдена в \${path}"

MSG_F2B_UNBANNING="Unbanning \${ip} from \${jail}"
MSG_F2B_UNBANNING_RU="Разбаниваю \${ip} из \${jail}"

MSG_F2B_UPDATING="Updating Fail2ban configuration"
MSG_F2B_UPDATING_RU="Обновление конфигурации Fail2ban"

MSG_F2B_REMOVING="Removing Fail2ban module"
MSG_F2B_REMOVING_RU="Удаление модуля Fail2ban"

MSG_F2B_MODULE_REMOVED="Fail2ban module removed"
MSG_F2B_MODULE_REMOVED_RU="Модуль Fail2ban удалён"

# ══════════════════════════════════════════════════════════════
# MODULE: SSL
# ══════════════════════════════════════════════════════════════
MSG_SSL_INSTALLING="Installing Certbot"
MSG_SSL_INSTALLING_RU="Устанавливаю Certbot"

MSG_SSL_ALREADY_INSTALLED="Certbot already installed"
MSG_SSL_ALREADY_INSTALLED_RU="Certbot уже установлен"

MSG_SSL_GENERATING_SELF_SIGNED="Generating self-signed certificate for \${domain}"
MSG_SSL_GENERATING_SELF_SIGNED_RU="Генерирую самоподписной сертификат для \${domain}"

MSG_SSL_SELF_SIGNED_FAILED="Failed to generate self-signed certificate"
MSG_SSL_SELF_SIGNED_FAILED_RU="Не удалось сгенерировать самоподписной сертификат"

MSG_SSL_SELF_SIGNED_CREATED="Self-signed certificate generated at \${SSL_SELFIGNED_DIR}"
MSG_SSL_SELF_SIGNED_CREATED_RU="Самоподписной сертификат сгенерирован в \${SSL_SELFIGNED_DIR}"

MSG_SSL_CERT_VALID_365="Certificate valid for 365 days"
MSG_SSL_CERT_VALID_365_RU="Сертификат действителен 365 дней"

MSG_SSL_BROWSER_WARNING="Browsers will show security warning — this is expected in dev mode"
MSG_SSL_BROWSER_WARNING_RU="Браузеры будут показывать предупреждение — это нормально для dev-режима"

MSG_SSL_GENERATING_CERT="Generating SSL certificate for \${domain}"
MSG_SSL_GENERATING_CERT_RU="Генерирую SSL сертификат для \${domain}"

MSG_SSL_INVALID_DOMAIN="Invalid domain: \${domain}"
MSG_SSL_INVALID_DOMAIN_RU="Некорректный домен: \${domain}"

MSG_SSL_INVALID_EMAIL="Invalid email: \${email}"
MSG_SSL_INVALID_EMAIL_RU="Некорректный email: \${email}"

MSG_SSL_GENERATE_FAILED="Failed to generate SSL certificate for \${domain}"
MSG_SSL_GENERATE_FAILED_RU="Не удалось сгенерировать SSL сертификат для \${domain}"

MSG_SSL_CERT_GENERATED="SSL certificate generated for \${domain}"
MSG_SSL_CERT_GENERATED_RU="SSL сертификат сгенерирован для \${domain}"

MSG_SSL_CONFIG_WEBROOT="Configuring webroot directory"
MSG_SSL_CONFIG_WEBROOT_RU="Настраиваю директорию webroot"

MSG_SSL_WEBROOT_CONFIGURED="Webroot configured at \${webroot_dir}"
MSG_SSL_WEBROOT_CONFIGURED_RU="Webroot настроен в \${webroot_dir}"

MSG_SSL_CONFIG_RENEWAL="Configuring automatic certificate renewal"
MSG_SSL_CONFIG_RENEWAL_RU="Настраиваю автоматическое продление сертификата"

MSG_SSL_TIMER_CONFIGURED="Certbot renewal timer already configured"
MSG_SSL_TIMER_CONFIGURED_RU="Таймер продления Certbot уже настроен"

MSG_SSL_TIMER_ENABLED="Certbot renewal timer enabled"
MSG_SSL_TIMER_ENABLED_RU="Таймер продления Certbot включён"

MSG_SSL_TIMER_NOT_FOUND="Certbot renewal timer not found, manual renewal required"
MSG_SSL_TIMER_NOT_FOUND_RU="Таймер продления Certbot не найден, требуется ручное продление"

MSG_SSL_CONFIG_MODULE="Configuring SSL module"
MSG_SSL_CONFIG_MODULE_RU="Настраиваю SSL модуль"

MSG_SSL_MODULE_CONFIGURED="SSL module configured"
MSG_SSL_MODULE_CONFIGURED_RU="SSL модуль настроен"

MSG_SSL_CERT_NOT_FOUND="Certificate not found: \${cert_path}"
MSG_SSL_CERT_NOT_FOUND_RU="Сертификат не найден: \${cert_path}"

MSG_SSL_CERT_EXPIRES="Certificate for \${domain} expires in \${days_left} days"
MSG_SSL_CERT_EXPIRES_RU="Сертификат для \${domain} истекает через \${days_left} дней"

MSG_SSL_CERT_EXPIRE_SOON="Certificate will expire soon (\${days_left} days)"
MSG_SSL_CERT_EXPIRE_SOON_RU="Сертификат скоро истечёт (\${days_left} дней)"

MSG_SSL_RENEWING="Renewing SSL certificate"
MSG_SSL_RENEWING_RU="Продлеваю SSL сертификат"

MSG_SSL_CERT_RENEWED="Certificate renewed for \${domain}"
MSG_SSL_CERT_RENEWED_RU="Сертификат продлён для \${domain}"

MSG_SSL_RENEW_FAILED="Failed to renew certificate for \${domain}"
MSG_SSL_RENEW_FAILED_RU="Не удалось продлить сертификат для \${domain}"

MSG_SSL_RENEW_PARTIAL="Some certificates may have failed to renew"
MSG_SSL_RENEW_PARTIAL_RU="Некоторые сертификаты могли не продлиться"

MSG_SSL_REMOVING_CERT="Removing SSL certificate for \${domain}"
MSG_SSL_REMOVING_CERT_RU="Удаляю SSL сертификат для \${domain}"

MSG_SSL_CERT_NOT_FOUND_DOMAIN="Certificate not found for \${domain}"
MSG_SSL_CERT_NOT_FOUND_DOMAIN_RU="Сертификат не найден для \${domain}"

MSG_SSL_CERT_REMOVED="Certificate removed for \${domain}"
MSG_SSL_CERT_REMOVED_RU="Сертификат удалён для \${domain}"

MSG_SSL_ENABLING="Enabling SSL module"
MSG_SSL_ENABLING_RU="Включаю SSL модуль"

MSG_SSL_SELF_SIGNED_FOUND="Self-signed certificate found at \${SSL_SELFIGNED_DIR}"
MSG_SSL_SELF_SIGNED_FOUND_RU="Самоподписной сертификат найден в \${SSL_SELFIGNED_DIR}"

MSG_SSL_CERTS_FOUND="Found \${cert_count} SSL certificate(s)"
MSG_SSL_CERTS_FOUND_RU="Найдено \${cert_count} SSL сертификат(ов)"

MSG_SSL_NO_CERTS="No SSL certificates found"
MSG_SSL_NO_CERTS_RU="SSL сертификаты не найдены"

MSG_SSL_MODULE_ENABLED="SSL module enabled"
MSG_SSL_MODULE_ENABLED_RU="SSL модуль включён"

MSG_SSL_DISABLING="Disabling SSL module"
MSG_SSL_DISABLING_RU="Отключаю SSL модуль"

MSG_SSL_MODULE_DISABLED="SSL module disabled (certificates remain installed)"
MSG_SSL_MODULE_DISABLED_RU="SSL модуль отключён (сертификаты остаются установленными)"

MSG_SSL_LISTING="Listing SSL certificates"
MSG_SSL_LISTING_RU="Список SSL сертификатов"

MSG_SSL_NO_CERTS_DIR="No SSL certificates directory found"
MSG_SSL_NO_CERTS_DIR_RU="Директория SSL сертификатов не найдена"

MSG_SSL_UPDATING_MODULE="Updating SSL module"
MSG_SSL_UPDATING_MODULE_RU="Обновление SSL модуля"

MSG_SSL_REMOVING_MODULE="Removing SSL module"
MSG_SSL_REMOVING_MODULE_RU="Удаление SSL модуля"

MSG_SSL_MODULE_REMOVED="SSL module removed (certificates remain installed)"
MSG_SSL_MODULE_REMOVED_RU="SSL модуль удалён (сертификаты остаются установленными)"

# ══════════════════════════════════════════════════════════════
# MODULE: SINGBOX
# ══════════════════════════════════════════════════════════════
MSG_SINGBOX_CACHED="Using cached Sing-box version: \${sb_tag}"
MSG_SINGBOX_CACHED_RU="Использую кэшированную версию Sing-box: \${sb_tag}"

MSG_SINGBOX_GETTING_VERSION="Getting latest Sing-box version from GitHub..."
MSG_SINGBOX_GETTING_VERSION_RU="Получаю последнюю версию Sing-box с GitHub..."

MSG_SINGBOX_GIT_FALLBACK="GitHub API failed, trying git ls-remote..."
MSG_SINGBOX_GIT_FALLBACK_RU="GitHub API не ответил, пробую git ls-remote..."

MSG_SINGBOX_VERSION_FAILED="Cannot get Sing-box version from GitHub"
MSG_SINGBOX_VERSION_FAILED_RU="Не удалось получить версию Sing-box с GitHub"

MSG_SINGBOX_LATEST="Sing-box latest: \${SB_TAG} (\${_arch})"
MSG_SINGBOX_LATEST_RU="Sing-box последняя: \${SB_TAG} (\${_arch})"

MSG_SINGBOX_SHA_FETCH_FAILED="Could not fetch SHA256 checksum, will skip verification"
MSG_SINGBOX_SHA_FETCH_FAILED_RU="Не удалось получить SHA256 checksum, пропускаю проверку"

MSG_SINGBOX_DOWNLOADING="Downloading Sing-box \${sb_tag}"
MSG_SINGBOX_DOWNLOADING_RU="Загружаю Sing-box \${sb_tag}"

MSG_SINGBOX_URL_EMPTY="Sing-box download URL is empty"
MSG_SINGBOX_URL_EMPTY_RU="URL загрузки Sing-box пуст"

MSG_SINGBOX_DOWNLOAD_FAILED="Failed to download Sing-box from: \${url}"
MSG_SINGBOX_DOWNLOAD_FAILED_RU="Не удалось загрузить Sing-box из: \${url}"

MSG_SINGBOX_DOWNLOADED="Downloaded: /tmp/sing-box.tar.gz"
MSG_SINGBOX_DOWNLOADED_RU="Загружено: /tmp/sing-box.tar.gz"

MSG_SINGBOX_GPG_VERIFIED="GPG signature verified"
MSG_SINGBOX_GPG_VERIFIED_RU="GPG подпись проверена"

MSG_SINGBOX_GPG_FAILED="GPG verification failed — falling back to SHA256"
MSG_SINGBOX_GPG_FAILED_RU="GPG проверка не удалась — использую SHA256"

MSG_SINGBOX_NO_SHA="No SHA256 checksum available, skipping verification"
MSG_SINGBOX_NO_SHA_RU="SHA256 checksum недоступен, пропускаю проверку"

MSG_SINGBOX_VERIFY_SHA="Verifying SHA256..."
MSG_SINGBOX_VERIFY_SHA_RU="Проверяю SHA256..."

MSG_SINGBOX_SHA_FAILED="SHA256 verification failed"
MSG_SINGBOX_SHA_FAILED_RU="Проверка SHA256 не удалась"

MSG_SINGBOX_SHA_VERIFIED="SHA256 verified"
MSG_SINGBOX_SHA_VERIFIED_RU="SHA256 проверен"

MSG_SINGBOX_INSTALL_BINARY="Installing Sing-box binary"
MSG_SINGBOX_INSTALL_BINARY_RU="Устанавливаю бинарник Sing-box"

MSG_SINGBOX_BINARY_NOT_FOUND="sing-box binary not found in archive"
MSG_SINGBOX_BINARY_NOT_FOUND_RU="Бинарник sing-box не найден в архиве"

MSG_SINGBOX_INSTALLED="Installed: \${sb_tag}"
MSG_SINGBOX_INSTALLED_RU="Установлено: \${sb_tag}"

MSG_SINGBOX_INSTALLING="Installing Sing-box"
MSG_SINGBOX_INSTALLING_RU="Устанавливаю Sing-box"

MSG_SINGBOX_ALREADY_INSTALLED="Sing-box already installed: \${sb_tag}"
MSG_SINGBOX_ALREADY_INSTALLED_RU="Sing-box уже установлен: \${sb_tag}"

MSG_SINGBOX_CONFIGURING="Configuring Sing-box"
MSG_SINGBOX_CONFIGURING_RU="Настраиваю Sing-box"

MSG_SINGBOX_CONFIGURED="Sing-box configured"
MSG_SINGBOX_CONFIGURED_RU="Sing-box настроен"

MSG_SINGBOX_CREATING_SERVICE="Creating systemd service"
MSG_SINGBOX_CREATING_SERVICE_RU="Создаю сервис systemd"

MSG_SINGBOX_ENABLING="Enabling Sing-box"
MSG_SINGBOX_ENABLING_RU="Включаю Sing-box"

MSG_SINGBOX_ENABLED_STARTED="Sing-box enabled and started"
MSG_SINGBOX_ENABLED_STARTED_RU="Sing-box включён и запущен"

MSG_SINGBOX_IS_ACTIVE="Sing-box is active"
MSG_SINGBOX_IS_ACTIVE_RU="Sing-box активен"

MSG_SINGBOX_NOT_ACTIVE="Sing-box is not active"
MSG_SINGBOX_NOT_ACTIVE_RU="Sing-box не активен"

MSG_SINGBOX_REMOVED="Sing-box removed"
MSG_SINGBOX_REMOVED_RU="Sing-box удалён"

MSG_SINGBOX_UP_TO_DATE="Sing-box already up to date: \${arg_1}"
MSG_SINGBOX_UP_TO_DATE_RU="Sing-box уже обновлён: \${arg_1}"

MSG_SINGBOX_UPDATED="Sing-box updated to \${arg_1}"
MSG_SINGBOX_UPDATED_RU="Sing-box обновлён до \${arg_1}"

# ══════════════════════════════════════════════════════════════
# MODULE: SYSTEM
# ══════════════════════════════════════════════════════════════
MSG_SYS_SETUP_ENV="Setting up non-interactive update environment"
MSG_SYS_SETUP_ENV_RU="Настраиваю неинтерактивное окружение для обновлений"

MSG_SYS_UPDATE_WAIT="Update and upgrade may take up to 5 minutes — please wait..."
MSG_SYS_UPDATE_WAIT_RU="Обновление может занять до 5 минут — пожалуйста, подождите..."

MSG_SYS_ENV_CONFIGURED="Non-interactive update environment configured"
MSG_SYS_ENV_CONFIGURED_RU="Неинтерактивное окружение для обновлений настроено"

MSG_SYS_FULL_UPDATE="Performing full system update"
MSG_SYS_FULL_UPDATE_RU="Выполняю полное обновление системы"

MSG_SYS_UPDATE_WAIT2="System update may take up to 5 minutes — please wait..."
MSG_SYS_UPDATE_WAIT2_RU="Обновление системы может занять до 5 минут — пожалуйста, подождите..."

MSG_SYS_UPDATED="System updated successfully"
MSG_SYS_UPDATED_RU="Система успешно обновлена"

MSG_SYS_QUICK_UPDATE="Performing quick package update"
MSG_SYS_QUICK_UPDATE_RU="Выполняю быстрое обновление пакетов"

MSG_SYS_PKG_UPDATED="Package index updated"
MSG_SYS_PKG_UPDATED_RU="Индекс пакетов обновлён"

MSG_SYS_CONFIG_AUTO="Configuring automatic updates"
MSG_SYS_CONFIG_AUTO_RU="Настраиваю автоматические обновления"

MSG_SYS_AUTO_ROOT_SKIP="system_auto_updates_configure: requires root privileges (skipped)"
MSG_SYS_AUTO_ROOT_SKIP_RU="system_auto_updates_configure: требуются права root (пропущено)"

MSG_SYS_AUTO_DIR_FAILED="Cannot create /etc/apt/apt.conf.d (no root?)"
MSG_SYS_AUTO_DIR_FAILED_RU="Не удалось создать /etc/apt/apt.conf.d (нет root?)"

MSG_SYS_AUTO_CREATED="Created /etc/apt/apt.conf.d/20auto-upgrades"
MSG_SYS_AUTO_CREATED_RU="Создан /etc/apt/apt.conf.d/20auto-upgrades"

MSG_SYS_CONFIG_UNATTENDED="Configuring unattended-upgrades"
MSG_SYS_CONFIG_UNATTENDED_RU="Настраиваю unattended-upgrades"

MSG_SYS_UNATTENDED_ROOT_SKIP="system_auto_updates_unattended_configure: requires root privileges (skipped)"
MSG_SYS_UNATTENDED_ROOT_SKIP_RU="system_auto_updates_unattended_configure: требуются права root (пропущено)"

MSG_SYS_UNATTENDED_CREATED="Created /etc/apt/apt.conf.d/50unattended-upgrades"
MSG_SYS_UNATTENDED_CREATED_RU="Создан /etc/apt/apt.conf.d/50unattended-upgrades"

MSG_SYS_ENABLING_AUTO="Enabling unattended-upgrades service"
MSG_SYS_ENABLING_AUTO_RU="Включаю сервис unattended-upgrades"

MSG_SYS_AUTO_ENABLED="Unattended-upgrades service enabled"
MSG_SYS_AUTO_ENABLED_RU="Сервис unattended-upgrades включён"

MSG_SYS_SETUP_AUTO="Setting up automatic security updates"
MSG_SYS_SETUP_AUTO_RU="Настраиваю автоматические security-обновления"

MSG_SYS_AUTO_CONFIGURED="Auto-updates configured"
MSG_SYS_AUTO_CONFIGURED_RU="Автообновления настроены"

MSG_SYS_LOAD_BBR="Loading BBR kernel module"
MSG_SYS_LOAD_BBR_RU="Загружаю модуль ядра BBR"

MSG_SYS_BBR_ROOT_SKIP="system_bbr_load_module: requires root privileges (skipped)"
MSG_SYS_BBR_ROOT_SKIP_RU="system_bbr_load_module: требуются права root (пропущено)"

MSG_SYS_BBR_LOADED="BBR module loaded"
MSG_SYS_BBR_LOADED_RU="Модуль BBR загружен"

MSG_SYS_CREATE_SYSCTL="Creating sysctl configuration for BBR"
MSG_SYS_CREATE_SYSCTL_RU="Создаю конфигурацию sysctl для BBR"

MSG_SYS_SYSCTL_ROOT_SKIP="system_bbr_create_sysctl_config: requires root privileges (skipped)"
MSG_SYS_SYSCTL_ROOT_SKIP_RU="system_bbr_create_sysctl_config: требуются права root (пропущено)"

MSG_SYS_SYSCTL_CREATED="Created /etc/sysctl.d/99-cubiveil.conf"
MSG_SYS_SYSCTL_CREATED_RU="Создан /etc/sysctl.d/99-cubiveil.conf"

MSG_SYS_APPLY_SYSCTL="Applying sysctl settings"
MSG_SYS_APPLY_SYSCTL_RU="Применяю настройки sysctl"

MSG_SYS_SETUP_BBR="Setting up BBR optimization"
MSG_SYS_SETUP_BBR_RU="Настраиваю оптимизацию BBR"

MSG_SYS_BBR_ENABLED="BBR optimization enabled (current: \${current})"
MSG_SYS_BBR_ENABLED_RU="Оптимизация BBR включена (текущий: \${current})"

MSG_SYS_BBR_STATUS="Current TCP congestion control: \${CURRENT}"
MSG_SYS_BBR_STATUS_RU="Текущий контроль перегрузки TCP: \${CURRENT}"

MSG_SYS_BBR_ACTIVE="BBR is active"
MSG_SYS_BBR_ACTIVE_RU="BBR активен"

MSG_SYS_BBR_NOT_ACTIVE="BBR is not active (current: \${CURRENT})"
MSG_SYS_BBR_NOT_ACTIVE_RU="BBR не активен (текущий: \${CURRENT})"

MSG_SYS_CHECK_IP="Checking IP neighborhood for VPN/hosting servers"
MSG_SYS_CHECK_IP_RU="Проверяю соседние IP на VPN/хостинг серверы"

MSG_SYS_IFACE_NOT_FOUND="Failed to determine network interface"
MSG_SYS_IFACE_NOT_FOUND_RU="Не удалось определить сетевой интерфейс"

MSG_SYS_CHECK_SERVICES="Checking critical services status"
MSG_SYS_CHECK_SERVICES_RU="Проверяю статус критических сервисов"

MSG_SYS_SERVICE_ACTIVE="\${service}: active"
MSG_SYS_SERVICE_ACTIVE_RU="\${service}: активен"

MSG_SYS_SERVICE_INACTIVE="\${service}: inactive"
MSG_SYS_SERVICE_INACTIVE_RU="\${service}: не активен"

MSG_SYS_SERVICES_RESTARTED="Services restarted"
MSG_SYS_SERVICES_RESTARTED_RU="Сервисы перезапущены"

MSG_SYS_INSTALL_BASE="Installing base dependencies"
MSG_SYS_INSTALL_BASE_RU="Устанавливаю базовые зависимости"

MSG_SYS_BASE_INSTALLED="Base dependencies installed"
MSG_SYS_BASE_INSTALLED_RU="Базовые зависимости установлены"

MSG_SYS_INSTALLING_MODULE="Installing system module"
MSG_SYS_INSTALLING_MODULE_RU="Устанавливаю системный модуль"

MSG_SYS_MODULE_INSTALLED="System module installed successfully"
MSG_SYS_MODULE_INSTALLED_RU="Системный модуль успешно установлен"

MSG_SYS_CONFIGURING_MODULE="Configuring system module"
MSG_SYS_CONFIGURING_MODULE_RU="Настраиваю системный модуль"

MSG_SYS_MODULE_CONFIGURED="System module configured"
MSG_SYS_MODULE_CONFIGURED_RU="Системный модуль настроен"

MSG_SYS_ENABLING_MODULE="Enabling system module"
MSG_SYS_ENABLING_MODULE_RU="Включаю системный модуль"

MSG_SYS_MODULE_ENABLED="System module enabled"
MSG_SYS_MODULE_ENABLED_RU="Системный модуль включён"

MSG_SYS_DISABLING_MODULE="Disabling system module"
MSG_SYS_DISABLING_MODULE_RU="Отключаю системный модуль"

MSG_SYS_MODULE_DISABLED="System module disabled"
MSG_SYS_MODULE_DISABLED_RU="Системный модуль отключён"

MSG_SYS_UPDATING_MODULE="Updating system module"
MSG_SYS_UPDATING_MODULE_RU="Обновляю системный модуль"

MSG_SYS_MODULE_UPDATED="System module updated"
MSG_SYS_MODULE_UPDATED_RU="Системный модуль обновлён"

MSG_SYS_CHECKING_STATUS="Checking system module status"
MSG_SYS_CHECKING_STATUS_RU="Проверяю статус системного модуля"

MSG_SYS_AUTO_INACTIVE="Auto-updates: inactive"
MSG_SYS_AUTO_INACTIVE_RU="Автообновления: не активны"

# ══════════════════════════════════════════════════════════════
# MODULE: BACKUP
# ══════════════════════════════════════════════════════════════
MSG_BACKUP_INIT="Initializing backup module"
MSG_BACKUP_INIT_RU="Инициализация модуля резервного копирования"

MSG_BACKUP_DIRS_CREATED="Backup directories created"
MSG_BACKUP_DIRS_CREATED_RU="Директории для бэкапов созданы"

MSG_BACKUP_GEN_KEY="Generating encryption key"
MSG_BACKUP_GEN_KEY_RU="Генерирую ключ шифрования"

MSG_BACKUP_KEY_GENERATED="Encryption key generated"
MSG_BACKUP_KEY_GENERATED_RU="Ключ шифрования сгенерирован"

MSG_BACKUP_KEY_NOT_FOUND="Encryption key not found, generating new key..."
MSG_BACKUP_KEY_NOT_FOUND_RU="Ключ шифрования не найден, генерирую новый..."

MSG_BACKUP_CHECK_ENV="Checking backup environment"
MSG_BACKUP_CHECK_ENV_RU="Проверяю окружение для бэкапа"

MSG_BACKUP_SINGBOX_NOT_FOUND="Sing-box binary not found"
MSG_BACKUP_SINGBOX_NOT_FOUND_RU="Бинарник Sing-box не найден"

MSG_BACKUP_SSL_DIR_NOT_FOUND="SSL certificates directory not found: \${arg_1}"
MSG_BACKUP_SSL_DIR_NOT_FOUND_RU="Директория SSL сертификатов не найдена: \${arg_1}"

MSG_BACKUP_AGE_NOT_FOUND="age encryption tool not found, backups will not be encrypted"
MSG_BACKUP_AGE_NOT_FOUND_RU="Инструмент шифрования age не найден, бэкапы не будут зашифрованы"

MSG_BACKUP_ENV_ISSUES="Found \${arg_1} environment issues, backup may be incomplete"
MSG_BACKUP_ENV_ISSUES_RU="Найдено проблем окружения: \${arg_1}, бэкап может быть неполным"

MSG_BACKUP_ENV_OK="Environment check passed"
MSG_BACKUP_ENV_OK_RU="Проверка окружения пройдена"

MSG_BACKUP_STOP_SERVICES="Stopping services for backup"
MSG_BACKUP_STOP_SERVICES_RU="Останавливаю сервисы для бэкапа"

MSG_BACKUP_SINGBOX_STOPPED="Sing-box stopped"
MSG_BACKUP_SINGBOX_STOPPED_RU="Sing-box остановлен"

MSG_BACKUP_SINGBOX_CONFIG="Backing up Sing-box configuration"
MSG_BACKUP_SINGBOX_CONFIG_RU="Резервирую конфигурацию Sing-box"

MSG_BACKUP_SINGBOX_CONFIG_NOT_FOUND="Sing-box configuration not found"
MSG_BACKUP_SINGBOX_CONFIG_NOT_FOUND_RU="Конфигурация Sing-box не найдена"

MSG_BACKUP_SINGBOX_CONFIG_BACKED="Sing-box configuration backed up (SHA256: \${hash:0:8}...)"
MSG_BACKUP_SINGBOX_CONFIG_BACKED_RU="Конфигурация Sing-box зарезервирована (SHA256: \${hash:0:8}...)"

MSG_BACKUP_SSL_CERTS="Backing up SSL certificates"
MSG_BACKUP_SSL_CERTS_RU="Резервирую SSL сертификаты"

MSG_BACKUP_SSL_DIR_NOT_FOUND2="SSL certificates directory not found"
MSG_BACKUP_SSL_DIR_NOT_FOUND2_RU="Директория SSL сертификатов не найдена"

MSG_BACKUP_SSL_CHECKING="Checking SSL certificate for: \${arg_1}"
MSG_BACKUP_SSL_CHECKING_RU="Проверяю SSL сертификат для: \${arg_1}"

MSG_BACKUP_SSL_VALID="SSL certificate is valid: \${arg_1}"
MSG_BACKUP_SSL_VALID_RU="SSL сертификат действителен: \${arg_1}"

MSG_BACKUP_SSL_INVALID="SSL certificate validation failed: \${arg_1}"
MSG_BACKUP_SSL_INVALID_RU="Проверка SSL сертификата не удалась: \${arg_1}"

MSG_BACKUP_SSL_BACKED="SSL certificates backed up"
MSG_BACKUP_SSL_BACKED_RU="SSL сертификаты зарезервированы"

MSG_BACKUP_KEYS="Backing up keys and credentials"
MSG_BACKUP_KEYS_RU="Резервирую ключи и учётные данные"

MSG_BACKUP_AGE_UNAVAILABLE="age not available, credentials will not be encrypted"
MSG_BACKUP_AGE_UNAVAILABLE_RU="age недоступен, учётные данные не будут зашифрованы"

MSG_BACKUP_KEYS_BACKED="Keys and credentials backed up"
MSG_BACKUP_KEYS_BACKED_RU="Ключи и учётные данные зарезервированы"

MSG_BACKUP_ENCRYPT="Encrypting backup archive"
MSG_BACKUP_ENCRYPT_RU="Шифрую архив бэкапа"

MSG_BACKUP_AGE_UNAVAILABLE2="age not available, skipping encryption"
MSG_BACKUP_AGE_UNAVAILABLE2_RU="age недоступен, пропускаю шифрование"

MSG_BACKUP_ENCRYPTED="Backup encrypted: \${arg_1}"
MSG_BACKUP_ENCRYPTED_RU="Бэкап зашифрован: \${arg_1}"

MSG_BACKUP_ENCRYPTION_KEY="Encryption key: \${encrypted_file}.key"
MSG_BACKUP_ENCRYPTION_KEY_RU="Ключ шифрования: \${encrypted_file}.key"

MSG_BACKUP_ENCRYPT_FAILED="Failed to encrypt backup archive"
MSG_BACKUP_ENCRYPT_FAILED_RU="Не удалось зашифровать архив бэкапа"

MSG_BACKUP_SYS_INFO="Backing up system information"
MSG_BACKUP_SYS_INFO_RU="Резервирую системную информацию"

MSG_BACKUP_SYS_INFO_BACKED="System information backed up (SHA256: \${hash:0:8}...)"
MSG_BACKUP_SYS_INFO_BACKED_RU="Системная информация зарезервирована (SHA256: \${hash:0:8}...)"

MSG_BACKUP_CREATE_ARCHIVE="Creating backup archive"
MSG_BACKUP_CREATE_ARCHIVE_RU="Создаю архив бэкапа"

MSG_BACKUP_ARCHIVE_CREATED="Backup archive created: \${arg_1} (\${arg_1})"
MSG_BACKUP_ARCHIVE_CREATED_RU="Архив бэкапа создан: \${arg_1} (\${arg_1})"

MSG_BACKUP_ARCHIVE_FAILED="Failed to create backup archive"
MSG_BACKUP_ARCHIVE_FAILED_RU="Не удалось создать архив бэкапа"

MSG_BACKUP_START_SERVICES="Starting services after backup"
MSG_BACKUP_START_SERVICES_RU="Запускаю сервисы после бэкапа"

MSG_BACKUP_SINGBOX_STARTED="Sing-box started"
MSG_BACKUP_SINGBOX_STARTED_RU="Sing-box запущен"

MSG_BACKUP_CLEANUP="Cleaning up old backups"
MSG_BACKUP_CLEANUP_RU="Очищаю старые бэкапы"

MSG_BACKUP_KEPT="Kept \${arg_1} backups (retention: \${BACKUP_RETENTION_DAYS} days)"
MSG_BACKUP_KEPT_RU="Сохранено бэкапов: \${arg_1} (хранение: \${BACKUP_RETENTION_DAYS} дней)"

MSG_BACKUP_FULL="Performing full backup"
MSG_BACKUP_FULL_RU="Выполняю полный бэкап"

MSG_BACKUP_FULL_COMPLETE="Full backup completed"
MSG_BACKUP_FULL_COMPLETE_RU="Полный бэкап завершён"

MSG_BACKUP_CONFIG_MODULE="Configuring backup module"
MSG_BACKUP_CONFIG_MODULE_RU="Настраиваю модуль резервного копирования"

MSG_BACKUP_ENV_CHECK_FAILED="Backup environment check failed"
MSG_BACKUP_ENV_CHECK_FAILED_RU="Проверка окружения для бэкапа не удалась"

MSG_BACKUP_GEN_KEY2="Generating encryption key..."
MSG_BACKUP_GEN_KEY2_RU="Генерирую ключ шифрования..."

MSG_BACKUP_KEY_GENERATED2="Encryption key generated: \${key_file}"
MSG_BACKUP_KEY_GENERATED2_RU="Ключ шифрования сгенерирован: \${key_file}"

MSG_BACKUP_KEY_EXISTS="Encryption key already exists"
MSG_BACKUP_KEY_EXISTS_RU="Ключ шифрования уже существует"

MSG_BACKUP_MODULE_CONFIGURED="Backup module configured"
MSG_BACKUP_MODULE_CONFIGURED_RU="Модуль резервного копирования настроен"

MSG_BACKUP_ENABLING="Enabling backup module"
MSG_BACKUP_ENABLING_RU="Включаю модуль резервного копирования"

MSG_BACKUP_CRON_NOT_FOUND="Cron not installed, installing..."
MSG_BACKUP_CRON_NOT_FOUND_RU="Cron не установлен, устанавливаю..."

MSG_BACKUP_CRON_ADDED="Daily backup cron job added"
MSG_BACKUP_CRON_ADDED_RU="Ежедневный cron job для бэкапа добавлен"

MSG_BACKUP_CRON_EXISTS="Backup cron job already exists"
MSG_BACKUP_CRON_EXISTS_RU="Cron job для бэкапа уже существует"

MSG_BACKUP_MODULE_ENABLED="Backup module enabled"
MSG_BACKUP_MODULE_ENABLED_RU="Модуль резервного копирования включён"

MSG_BACKUP_DISABLING="Disabling backup module"
MSG_BACKUP_DISABLING_RU="Отключаю модуль резервного копирования"

MSG_BACKUP_CRON_REMOVED="Backup cron job removed"
MSG_BACKUP_CRON_REMOVED_RU="Cron job для бэкапа удалён"

MSG_BACKUP_CRON_NOT_FOUND2="Backup cron job not found"
MSG_BACKUP_CRON_NOT_FOUND2_RU="Cron job для бэкапа не найден"

MSG_BACKUP_MODULE_DISABLED="Backup module disabled"
MSG_BACKUP_MODULE_DISABLED_RU="Модуль резервного копирования отключён"

MSG_BACKUP_QUICK="Performing quick backup"
MSG_BACKUP_QUICK_RU="Выполняю быстрый бэкап"

MSG_BACKUP_QUICK_COMPLETE="Quick backup completed"
MSG_BACKUP_QUICK_COMPLETE_RU="Быстрый бэкап завершён"

MSG_BACKUP_LISTING="Listing available backups"
MSG_BACKUP_LISTING_RU="Список доступных бэкапов"

MSG_BACKUP_CLEANUP_OLD="Removing old backups"
MSG_BACKUP_CLEANUP_OLD_RU="Удаление старых бэкапов"

# ══════════════════════════════════════════════════════════════
# MODULE: MONITORING
# ══════════════════════════════════════════════════════════════
MSG_MONITOR_INIT="Initializing monitoring module"
MSG_MONITOR_INIT_RU="Инициализация модуля мониторинга"

MSG_MONITOR_DIRS_CREATED="Monitoring directories created"
MSG_MONITOR_DIRS_CREATED_RU="Директории для мониторинга созданы"

MSG_MONITOR_CHECK_SERVICES="Checking services status"
MSG_MONITOR_CHECK_SERVICES_RU="Проверка статуса сервисов"

MSG_MONITOR_ALL_ACTIVE="All services are active"
MSG_MONITOR_ALL_ACTIVE_RU="Все сервисы активны"

MSG_MONITOR_SOME_INACTIVE="Some services are inactive"
MSG_MONITOR_SOME_INACTIVE_RU="Некоторые сервисы не активны"

MSG_MONITOR_CHECK_RESOURCES="Checking system resources"
MSG_MONITOR_CHECK_RESOURCES_RU="Проверка системных ресурсов"

MSG_MONITOR_CPU_HIGH="CPU usage is high: \${cpu_usage}%"
MSG_MONITOR_CPU_HIGH_RU="Высокое использование CPU: \${cpu_usage}%"

MSG_MONITOR_RAM_HIGH="RAM usage is high: \${ram_usage}%"
MSG_MONITOR_RAM_HIGH_RU="Высокое использование RAM: \${ram_usage}%"

MSG_MONITOR_DISK_HIGH="Disk usage is high: \${disk_usage}%"
MSG_MONITOR_DISK_HIGH_RU="Высокое использование диска: \${disk_usage}%"

MSG_MONITOR_RESOURCE_ALERTS="Found \${arg_1} resource alerts"
MSG_MONITOR_RESOURCE_ALERTS_RU="Найдено предупреждений о ресурсах: \${arg_1}"

MSG_MONITOR_RESOURCES_OK="Resource usage is normal"
MSG_MONITOR_RESOURCES_OK_RU="Использование ресурсов в норме"

MSG_MONITOR_CHECK_NETWORK="Checking network connectivity"
MSG_MONITOR_CHECK_NETWORK_RU="Проверка сетевого соединения"

MSG_MONITOR_NETWORK_REACHABLE="Network: reachable to \${arg_1}"
MSG_MONITOR_NETWORK_REACHABLE_RU="Сеть: доступно соединение с \${arg_1}"

MSG_MONITOR_NETWORK_DOWN="Network: no connectivity"
MSG_MONITOR_NETWORK_DOWN_RU="Сеть: нет соединения"

MSG_MONITOR_CHECK_SSL="Checking SSL certificates"
MSG_MONITOR_CHECK_SSL_RU="Проверка SSL сертификатов"

MSG_MONITOR_SSL_CHECKING="Checking SSL certificate for: \${arg_1}"
MSG_MONITOR_SSL_CHECKING_RU="Проверка SSL сертификата для: \${arg_1}"

MSG_MONITOR_SSL_VALID="SSL certificate valid: \${arg_1}"
MSG_MONITOR_SSL_VALID_RU="SSL сертификат действителен: \${arg_1}"

MSG_MONITOR_SSL_FAILED="SSL certificate check failed: \${arg_1}"
MSG_MONITOR_SSL_FAILED_RU="Проверка SSL сертификата не удалась: \${arg_1}"

MSG_MONITOR_SSL_ALERT="\${arg_1} SSL certificate checks failed"
MSG_MONITOR_SSL_ALERT_RU="Проверок SSL сертификатов не удалось: \${arg_1}"

MSG_MONITOR_CHECK_SINGBOX_LOGS="Checking Sing-box logs for errors"
MSG_MONITOR_CHECK_SINGBOX_LOGS_RU="Проверка логов Sing-box на ошибки"

MSG_MONITOR_SINGBOX_ERRORS="Found \${arg_1} errors in Sing-box logs"
MSG_MONITOR_SINGBOX_ERRORS_RU="Найдено ошибок в логах Sing-box: \${arg_1}"

MSG_MONITOR_SINGBOX_NO_ERRORS="No errors in Sing-box logs"
MSG_MONITOR_SINGBOX_NO_ERRORS_RU="Нет ошибок в логах Sing-box"

MSG_MONITOR_CHECK_FAIL2BAN_LOGS="Checking Fail2ban logs"
MSG_MONITOR_CHECK_FAIL2BAN_LOGS_RU="Проверка логов Fail2ban"

MSG_MONITOR_FAIL2BAN_BANS="Fail2ban: currently banned \${arg_1} IPs"
MSG_MONITOR_FAIL2BAN_BANS_RU="Fail2ban: сейчас забанено IP: \${arg_1}"

MSG_MONITOR_HEALTH_CHECK="Performing system health check"
MSG_MONITOR_HEALTH_CHECK_RU="Выполняю проверку здоровья системы"

MSG_MONITOR_HEALTHY="System is healthy"
MSG_MONITOR_HEALTHY_RU="Система здорова"

MSG_MONITOR_DEGRADED="System health is degraded"
MSG_MONITOR_DEGRADED_RU="Здоровье системы ухудшено"

MSG_MONITOR_CRITICAL="System health is critical"
MSG_MONITOR_CRITICAL_RU="Критическое состояние системы"

MSG_MONITOR_GENERATE_REPORT="Generating system report"
MSG_MONITOR_GENERATE_REPORT_RU="Генерирую отчёт о системе"

MSG_MONITOR_REPORT_GENERATED="Report generated: \${arg_1}"
MSG_MONITOR_REPORT_GENERATED_RU="Отчёт сгенерирован: \${arg_1}"

MSG_MONITOR_CONFIG_MODULE="Configuring monitoring module"
MSG_MONITOR_CONFIG_MODULE_RU="Настраиваю модуль мониторинга"

MSG_MONITOR_CONFIG_CREATED="Configuration file created: \${config_file}"
MSG_MONITOR_CONFIG_CREATED_RU="Файл конфигурации создан: \${config_file}"

MSG_MONITOR_TOOL_NOT_FOUND="Required tool not found: \${arg_1}"
MSG_MONITOR_TOOL_NOT_FOUND_RU="Требуемый инструмент не найден: \${arg_1}"

MSG_MONITOR_MODULE_CONFIGURED="Monitoring module configured"
MSG_MONITOR_MODULE_CONFIGURED_RU="Модуль мониторинга настроен"

MSG_MONITOR_ENABLING="Enabling monitoring module"
MSG_MONITOR_ENABLING_RU="Включаю модуль мониторинга"

MSG_MONITOR_HOURLY_ADDED="Hourly health check cron job added"
MSG_MONITOR_HOURLY_ADDED_RU="Ежечасный cron job для проверки здоровья добавлен"

MSG_MONITOR_DAILY_ADDED="Daily report cron job added"
MSG_MONITOR_DAILY_ADDED_RU="Ежедневный cron job для отчётов добавлен"

MSG_MONITOR_CRON_ADDED="Monitoring cron jobs added"
MSG_MONITOR_CRON_ADDED_RU="Cron jobs для мониторинга добавлены"

MSG_MONITOR_CRON_EXISTS="Monitoring cron jobs already exist"
MSG_MONITOR_CRON_EXISTS_RU="Cron jobs для мониторинга уже существуют"

MSG_MONITOR_MODULE_ENABLED="Monitoring module enabled"
MSG_MONITOR_MODULE_ENABLED_RU="Модуль мониторинга включён"

MSG_MONITOR_DISABLING="Disabling monitoring module"
MSG_MONITOR_DISABLING_RU="Отключаю модуль мониторинга"

MSG_MONITOR_HEALTH_CRON_REMOVED="Health check cron job removed"
MSG_MONITOR_HEALTH_CRON_REMOVED_RU="Cron job для проверки здоровья удалён"

MSG_MONITOR_REPORT_CRON_REMOVED="Report cron job removed"
MSG_MONITOR_REPORT_CRON_REMOVED_RU="Cron job для отчётов удалён"

MSG_MONITOR_CRON_NOT_FOUND="Health check cron job not found"
MSG_MONITOR_CRON_NOT_FOUND_RU="Cron job для проверки здоровья не найден"

MSG_MONITOR_CRON_NOT_FOUND2="Report cron job not found"
MSG_MONITOR_CRON_NOT_FOUND2_RU="Cron job для отчётов не найден"

MSG_MONITOR_MODULE_DISABLED="Monitoring module disabled"
MSG_MONITOR_MODULE_DISABLED_RU="Модуль мониторинга отключён"

# ══════════════════════════════════════════════════════════════
# MODULE: DECOY-SITE
# ══════════════════════════════════════════════════════════════
MSG_DECOY_INSTALL_DEPS="Installing decoy site dependencies"
MSG_DECOY_INSTALL_DEPS_RU="Установка зависимостей сайта-прикрытия"

MSG_DECOY_DEPS_INSTALLED="Decoy site dependencies installed"
MSG_DECOY_DEPS_INSTALLED_RU="Зависимости decoy-site установлены"

MSG_DECOY_CONFIGURING="Configuring decoy site"
MSG_DECOY_CONFIGURING_RU="Настройка сайта-прикрытия"

MSG_DECOY_CONFIGURED="Decoy site configured"
MSG_DECOY_CONFIGURED_RU="Сайт-прикрытие настроен"

MSG_DECOY_ENABLING="Starting decoy site"
MSG_DECOY_ENABLING_RU="Запуск сайта-прикрытия"

MSG_DECOY_NGINX_NOT_INSTALLED="nginx not installed — skipping decoy-site"
MSG_DECOY_NGINX_NOT_INSTALLED_RU="nginx не установлен — пропускаю decoy-site"

MSG_DECOY_CONFIG_NOT_FOUND="Decoy nginx config not found: \${arg_1}"
MSG_DECOY_CONFIG_NOT_FOUND_RU="Конфиг nginx для decoy не найден: \${arg_1}"

MSG_DECOY_SKIP_MANUAL="Skipping decoy-site — you can configure manually later"
MSG_DECOY_SKIP_MANUAL_RU="Пропускаю decoy-site — сможете настроить вручную позже"

MSG_DECOY_NGINX_CONFIG_ERROR="Nginx configuration error: \${arg_1}"
MSG_DECOY_NGINX_CONFIG_ERROR_RU="Ошибка конфигурации nginx: \${arg_1}"

MSG_DECOY_DISABLED_CONFIG_ERROR="Decoy-site disabled due to nginx config error"
MSG_DECOY_DISABLED_CONFIG_ERROR_RU="Decoy-site отключён из-за ошибки конфигурации nginx"

MSG_DECOY_ROTATION_ENABLED="File rotation enabled (~3 hours)"
MSG_DECOY_ROTATION_ENABLED_RU="Ротация файлов активирована (~3 часа)"

MSG_DECOY_ROTATION_DISABLED="File rotation disabled (rotation.enabled = false)"
MSG_DECOY_ROTATION_DISABLED_RU="Ротация файлов отключена (rotation.enabled = false)"

MSG_DECOY_STARTED="Decoy site started on port 443"
MSG_DECOY_STARTED_RU="Сайт-прикрытие запущен на порту 443"

MSG_DECOY_DISABLED="Decoy site disabled"
MSG_DECOY_DISABLED_RU="Сайт-прикрытие отключён"

MSG_DECOY_STATUS="Decoy site status"
MSG_DECOY_STATUS_RU="Статус сайта-прикрытия"

MSG_DECOY_NGINX_ACTIVE="nginx: active"
MSG_DECOY_NGINX_ACTIVE_RU="nginx: активен"

MSG_DECOY_NGINX_NOT_RUNNING="nginx: not running"
MSG_DECOY_NGINX_NOT_RUNNING_RU="nginx: не запущен"

MSG_DECOY_CERT_VALID="Certificate: valid until \${expiry}"
MSG_DECOY_CERT_VALID_RU="Сертификат: действует до \${expiry}"

MSG_DECOY_CERT_NOT_FOUND="Certificate not found: \${cert_file}"
MSG_DECOY_CERT_NOT_FOUND_RU="Сертификат не найден: \${cert_file}"

MSG_DECOY_FILES_COUNT="Files in /files/: \${file_count} (\${total_size:-0})"
MSG_DECOY_FILES_COUNT_RU="Файлов в /files/: \${file_count} (\${total_size:-0})"

MSG_DECOY_ROTATION_ACTIVE="Rotation: active"
MSG_DECOY_ROTATION_ACTIVE_RU="Ротация: активна"

MSG_DECOY_ROTATION_INACTIVE="Rotation: disabled (rotation.enabled = false)"
MSG_DECOY_ROTATION_INACTIVE_RU="Ротация: отключена (rotation.enabled = false)"

MSG_DECOY_PROFILE="Profile: template=\${template} name='\${site_name}' color=\${accent_color}"
MSG_DECOY_PROFILE_RU="Профиль: шаблон=\${template} имя='\${site_name}' цвет=\${accent_color}"

MSG_DECOY_WEBROOT_BUILT="Webroot built: \${fcount} files, ~\${total_size} in \${DECOY_WEBROOT}"
MSG_DECOY_WEBROOT_BUILT_RU="Webroot собран: \${fcount} файлов, ~\${total_size} в \${DECOY_WEBROOT}"

MSG_DECOY_NGINX_CONF_WRITTEN="Nginx config written: \${NGINX_CONF} (nginx \${_nginx_ver:-unknown})"
MSG_DECOY_NGINX_CONF_WRITTEN_RU="Nginx конфиг записан: \${NGINX_CONF} (nginx \${_nginx_ver:-unknown})"

MSG_DECOY_ROTATION_SKIPPED_LOAD="Rotation skipped: load average \${load} >= 2"
MSG_DECOY_ROTATION_SKIPPED_LOAD_RU="Ротация пропущена: load average \${load} >= 2"

MSG_DECOY_ROTATION_SKIPPED_SPACE="Rotation skipped: low space (\${free_mb}MB < 200MB)"
MSG_DECOY_ROTATION_SKIPPED_SPACE_RU="Ротация пропущена: мало места (\${free_mb}MB < 200MB)"

MSG_DECOY_ROTATION_REPLACED="Rotation: replaced $(basename "\${arg_1}") → $(basename "\${arg_1}")"
MSG_DECOY_ROTATION_REPLACED_RU="Ротация: заменён $(basename "\${arg_1}") → $(basename "\${arg_1}")"

MSG_DECOY_ROTATION_TIMESTAMP="Rotation timestamp updated: \${timestamp}"
MSG_DECOY_ROTATION_TIMESTAMP_RU="Timestamp ротации обновлён: \${timestamp}"

MSG_DECOY_ROTATION_TS_FAILED="Failed to update timestamp in decoy.json"
MSG_DECOY_ROTATION_TS_FAILED_RU="Не удалось обновить timestamp в decoy.json"

MSG_DECOY_ROTATION_COMPLETE="Rotation complete: \${replaced} files replaced"
MSG_DECOY_ROTATION_COMPLETE_RU="Ротация завершена: заменено файлов \${replaced}"

MSG_DECOY_TIMER_CREATED="Rotation timer created (enabled by default)"
MSG_DECOY_TIMER_CREATED_RU="Таймер ротации создан (включён по умолчанию)"

MSG_DECOY_NO_FILES="No files in \${DECOY_WEBROOT}/files/ — run module_configure first"
MSG_DECOY_NO_FILES_RU="Нет файлов в \${DECOY_WEBROOT}/files/ — сначала запусти module_configure"

MSG_DECOY_MIKROTIK_SAVED="MikroTik script saved to: \${arg_1}"
MSG_DECOY_MIKROTIK_SAVED_RU="MikroTik скрипт сохранён в: \${arg_1}"

# ══════════════════════════════════════════════════════════════
# MODULE: ROLLBACK
# ══════════════════════════════════════════════════════════════
MSG_RB_INIT="Initializing rollback module"
MSG_RB_INIT_RU="Инициализация модуля отката"

MSG_RB_TEMP_CREATED="Rollback temp directory created"
MSG_RB_TEMP_CREATED_RU="Временная директория для отката создана"

MSG_RB_LISTING="Listing available backups"
MSG_RB_LISTING_RU="Список доступных бэкапов"

MSG_RB_NO_BACKUPS="No backups found"
MSG_RB_NO_BACKUPS_RU="Бэкапы не найдены"

MSG_RB_SELECTING="Selecting backup for restore"
MSG_RB_SELECTING_RU="Выбор бэкапа для восстановления"

MSG_RB_CANCELLED="Rollback cancelled"
MSG_RB_CANCELLED_RU="Откат отменён"

MSG_RB_INVALID_SELECTION="Invalid selection"
MSG_RB_INVALID_SELECTION_RU="Некорректный выбор"

MSG_RB_EXTRACTING="Extracting backup archive"
MSG_RB_EXTRACTING_RU="Распаковка архива бэкапа"

MSG_RB_ENCRYPTED_DETECTED="Encrypted archive detected, decrypting..."
MSG_RB_ENCRYPTED_DETECTED_RU="Обнаружен зашифрованный архив, расшифровываю..."

MSG_RB_KEY_NOT_FOUND="Encryption key not found: \${arg_1}"
MSG_RB_KEY_NOT_FOUND_RU="Ключ шифрования не найден: \${arg_1}"

MSG_RB_DECRYPT_FAILED="Failed to decrypt archive"
MSG_RB_DECRYPT_FAILED_RU="Не удалось расшифровать архив"

MSG_RB_DECRYPTED="Archive decrypted successfully"
MSG_RB_DECRYPTED_RU="Архив успешно расшифрован"

MSG_RB_EXTRACTED="Backup extracted"
MSG_RB_EXTRACTED_RU="Бэкап распакован"

MSG_RB_VERIFY="Verifying backup integrity"
MSG_RB_VERIFY_RU="Проверка целостности бэкапа"

MSG_RB_SINGBOX_INTEGRITY_FAILED="Sing-box configuration integrity check FAILED"
MSG_RB_SINGBOX_INTEGRITY_FAILED_RU="Проверка целостности конфигурации Sing-box НЕ ПРОЙДЕНА"

MSG_RB_SINGBOX_INTEGRITY_OK="Sing-box configuration integrity verified"
MSG_RB_SINGBOX_INTEGRITY_OK_RU="Целостность конфигурации Sing-box проверена"

MSG_RB_INTEGRITY_FAILED="Integrity checks failed: \${arg_1} files corrupted"
MSG_RB_INTEGRITY_FAILED_RU="Проверки целостности не пройдены: файлов повреждено \${arg_1}"

MSG_RB_INTEGRITY_OK="All integrity checks passed"
MSG_RB_INTEGRITY_OK_RU="Все проверки целостности пройдены"

MSG_RB_STOPPING="Stopping services for rollback"
MSG_RB_STOPPING_RU="Остановка сервисов для отката"

MSG_RB_TEMPLATE_INTEGRITY_FAILED="Sing-box template integrity check failed, skipping restore"
MSG_RB_TEMPLATE_INTEGRITY_FAILED_RU="Проверка целостности шаблона Sing-box не удалась, пропускаю восстановление"

MSG_RB_TEMPLATE_RESTORED="Sing-box template restored"
MSG_RB_TEMPLATE_RESTORED_RU="Шаблон Sing-box восстановлен"

MSG_RB_TEMPLATE_BACKUP_NOT_FOUND="Sing-box template backup not found"
MSG_RB_TEMPLATE_BACKUP_NOT_FOUND_RU="Бэкап шаблона Sing-box не найден"

MSG_RB_RESTORE_SINGBOX="Restoring Sing-box configuration"
MSG_RB_RESTORE_SINGBOX_RU="Восстановление конфигурации Sing-box"

MSG_RB_SINGBOX_INTEGRITY_CHECK_FAILED="Sing-box configuration integrity check failed, skipping restore"
MSG_RB_SINGBOX_INTEGRITY_CHECK_FAILED_RU="Проверка целостности конфигурации Sing-box не удалась, пропускаю восстановление"

MSG_RB_SINGBOX_BACKUP_NOT_FOUND="Sing-box configuration backup not found"
MSG_RB_SINGBOX_BACKUP_NOT_FOUND_RU="Бэкап конфигурации Sing-box не найден"

MSG_RB_SINGBOX_RESTORED="Sing-box configuration restored"
MSG_RB_SINGBOX_RESTORED_RU="Конфигурация Sing-box восстановлена"

MSG_RB_RESTORE_SSL="Restoring SSL certificates"
MSG_RB_RESTORE_SSL_RU="Восстановление SSL сертификатов"

MSG_RB_SSL_BACKUP_NOT_FOUND="SSL certificates backup not found"
MSG_RB_SSL_BACKUP_NOT_FOUND_RU="Бэкап SSL сертификатов не найден"

MSG_RB_SSL_RESTORED="SSL certificates restored"
MSG_RB_SSL_RESTORED_RU="SSL сертификаты восстановлены"

MSG_RB_RESTORE_KEYS="Restoring keys and credentials"
MSG_RB_RESTORE_KEYS_RU="Восстановление ключей и учётных данных"

MSG_RB_CREDS_RESTORED="Credentials restored"
MSG_RB_CREDS_RESTORED_RU="Учётные данные восстановлены"

MSG_RB_CREDS_BACKUP_NOT_FOUND="Credentials backup not found"
MSG_RB_CREDS_BACKUP_NOT_FOUND_RU="Бэкап учётных данных не найден"

MSG_RB_KEY_RESTORED="Age key restored"
MSG_RB_KEY_RESTORED_RU="Ключ Age восстановлен"

MSG_RB_KEY_BACKUP_NOT_FOUND="Age key backup not found"
MSG_RB_KEY_BACKUP_NOT_FOUND_RU="Бэкап ключа Age не найден"

MSG_RB_STARTING="Starting services after rollback"
MSG_RB_STARTING_RU="Запуск сервисов после отката"

MSG_RB_FULL="Performing full rollback with integrity checks"
MSG_RB_FULL_RU="Выполняю полный откат с проверками целостности"

MSG_RB_FULL_COMPLETE="Full rollback completed"
MSG_RB_FULL_COMPLETE_RU="Полный откат завершён"

MSG_RB_LATEST="Performing rollback from latest backup"
MSG_RB_LATEST_RU="Выполняю откат из последнего бэкапа"

MSG_RB_USING_LATEST="Using latest backup: $(basename "\${arg_1}")"
MSG_RB_USING_LATEST_RU="Использую последний бэкап: $(basename "\${arg_1}")"

MSG_RB_LATEST_COMPLETE="Rollback from latest backup completed"
MSG_RB_LATEST_COMPLETE_RU="Откат из последнего бэкапа завершён"

MSG_RB_CONFIG_MODULE="Configuring rollback module"
MSG_RB_CONFIG_MODULE_RU="Настройка модуля отката"

MSG_RB_NO_BACKUPS_DIR="No backups found in \${BACKUP_ARCHIVE_DIR}"
MSG_RB_NO_BACKUPS_DIR_RU="Бэкапы не найдены в \${BACKUP_ARCHIVE_DIR}"

MSG_RB_RUN_BACKUP_FIRST="Run backup module first to create backups"
MSG_RB_RUN_BACKUP_FIRST_RU="Сначала запустите модуль резервного копирования для создания бэкапов"

MSG_RB_LATEST_BACKUP="Latest backup: $(basename "\${arg_1}")"
MSG_RB_LATEST_BACKUP_RU="Последний бэкап: $(basename "\${arg_1}")"

MSG_RB_BACKUP_VERIFIED="Backup integrity verified"
MSG_RB_BACKUP_VERIFIED_RU="Целостность бэкапа проверена"

MSG_RB_BACKUP_CHECK_FAILED="Backup integrity check failed"
MSG_RB_BACKUP_CHECK_FAILED_RU="Проверка целостности бэкапа не удалась"

MSG_RB_MODULE_CONFIGURED="Rollback module configured"
MSG_RB_MODULE_CONFIGURED_RU="Модуль отката настроен"

MSG_RB_ENABLING="Enabling rollback module"
MSG_RB_ENABLING_RU="Включение модуля отката"

MSG_RB_UTILITY="Rollback module is a utility module"
MSG_RB_UTILITY_RU="Модуль отката — утилитный модуль"

MSG_RB_NO_SERVICES_ENABLE="No services to enable"
MSG_RB_NO_SERVICES_ENABLE_RU="Нет сервисов для включения"

MSG_RB_USE_MODULE_ROLLBACK="Use 'module_rollback' to perform rollback"
MSG_RB_USE_MODULE_ROLLBACK_RU="Используйте 'module_rollback' для выполнения отката"

MSG_RB_MODULE_READY="Rollback module ready"
MSG_RB_MODULE_READY_RU="Модуль отката готов"

MSG_RB_DISABLING="Disabling rollback module"
MSG_RB_DISABLING_RU="Отключение модуля отката"

MSG_RB_NO_SERVICES_DISABLE="No services to disable"
MSG_RB_NO_SERVICES_DISABLE_RU="Нет сервисов для отключения"

MSG_RB_MODULE_DISABLED="Rollback module disabled"
MSG_RB_MODULE_DISABLED_RU="Модуль отката отключён"

# ══════════════════════════════════════════════════════════════
# MODULE: TRAFFIC-SHAPING
# ══════════════════════════════════════════════════════════════
MSG_TS_CHECK="Checking tc/netem"
MSG_TS_CHECK_RU="Проверка tc/netem"

MSG_TS_AVAILABLE="tc/netem available (no additional dependencies)"
MSG_TS_AVAILABLE_RU="tc/netem доступен (без дополнительных зависимостей)"

MSG_TS_GENERATE="Generating shaping profile"
MSG_TS_GENERATE_RU="Генерация профиля шейпинга"

MSG_TS_PROFILE_SAVED="Shaping profile saved"
MSG_TS_PROFILE_SAVED_RU="Профиль шейпинга сохранён"

MSG_TS_APPLY="Applying tc rules"
MSG_TS_APPLY_RU="Применение tc-правил"

MSG_TS_ACTIVE="Traffic shaping active"
MSG_TS_ACTIVE_RU="Шейпинг трафика активен"

MSG_TS_DISABLED="Shaping disabled, tc rules reset"
MSG_TS_DISABLED_RU="Шейпинг отключён, tc-правила сброшены"

MSG_TS_STATUS="Traffic shaping status"
MSG_TS_STATUS_RU="Статус шейпинга трафика"

MSG_TS_SERVICE_ACTIVE="Service \${TS_SERVICE}: active"
MSG_TS_SERVICE_ACTIVE_RU="Сервис \${TS_SERVICE}: активен"

MSG_TS_SERVICE_NOT_RUNNING="Service \${TS_SERVICE}: not running"
MSG_TS_SERVICE_NOT_RUNNING_RU="Сервис \${TS_SERVICE}: не запущен"

MSG_TS_CURRENT_RULES="Current tc rules (\${iface}):"
MSG_TS_CURRENT_RULES_RU="Текущие правила tc (\${iface}):"

MSG_TS_UNINSTALL="Uninstalling traffic-shaping"
MSG_TS_UNINSTALL_RU="Удаление traffic-shaping"

MSG_TS_REMOVED="Traffic-shaping removed"
MSG_TS_REMOVED_RU="Traffic-shaping удалён"
