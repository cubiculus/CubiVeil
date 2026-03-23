#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║              CubiVeil — Localization                      ║
# ║                   EN / RU strings                         ║
# ╚═══════════════════════════════════════════════════════════╝

# Выбери язык / Select language:
# LANG_NAME="English"
LANG_NAME="Русский"

# ── Цвета / Colors ────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# ── Функции вывода / Output functions ─────────────────────────
ok()   { echo -e "${GREEN}[✓]${PLAIN} $1"; }
warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
err()  { echo -e "${RED}[✗]${PLAIN} $1"; exit 1; }
info() { echo -e "${CYAN}[→]${PLAIN} $1"; }

step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e "${BLUE}  $1${PLAIN}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
}

# ── Проверки / Checks ─────────────────────────────────────────
ERR_ROOT="Scripts must be run as root (sudo)"
ERR_ROOT_RU="Запускай от root"
ERR_UBUNTU="This script is only for Ubuntu"
ERR_UBUNTU_RU="Скрипт только для Ubuntu"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        if [[ "$LANG_NAME" == "Русский" ]]; then
            err "$ERR_ROOT_RU"
        else
            err "$ERR_ROOT"
        fi
    fi
}

check_ubuntu() {
    if ! grep -qi "ubuntu" /etc/os-release; then
        if [[ "$LANG_NAME" == "Русский" ]]; then
            err "$ERR_UBUNTU_RU"
        else
            err "$ERR_UBUNTU"
        fi
    fi
}

# ── Баннер / Banner ───────────────────────────────────────────
print_banner() {
    clear
    echo ""
    echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
    echo -e "${CYAN}  ║            CubiVeil Installer            ║${PLAIN}"
    echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
    if [[ "$LANG_NAME" == "Русский" ]]; then
        echo -e "${CYAN}  ║    Marzban + Sing-box + Telegram бот     ║${PLAIN}"
    else
        echo -e "${CYAN}  ║    Marzban + Sing-box + Telegram Bot     ║${PLAIN}"
    fi
    echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
    echo ""
}

# ── Выбор языка / Language selection ──────────────────────────
select_language() {
    echo ""
    echo "  Select language / Выберите язык:"
    echo ""
    echo "  1) Русский (Russian)"
    echo "  2) English"
    echo ""
    
    while true; do
        read -rp "  Enter choice [1-2]: " lang_choice
        case "$lang_choice" in
            1)
                LANG_NAME="Русский"
                return
                ;;
            2)
                LANG_NAME="English"
                return
                ;;
            *)
                warn "Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
}

# ── Строки ввода данных / Input prompts ───────────────────────
PROMPT_DOMAIN="Domain for panel and subscriptions (e.g. panel.example.com):"
PROMPT_DOMAIN_RU="Домен для панели и подписок (например panel.example.com):"

PROMPT_EMAIL="Email for Let's Encrypt [admin@${DOMAIN}]:"
PROMPT_EMAIL_RU="Email для Let's Encrypt [admin@${DOMAIN}]:"

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

WARN_DNS_RESOLVE="Failed to resolve domain $DOMAIN. Check A record."
WARN_DNS_RESOLVE_RU="Не удалось разрешить домен $DOMAIN. Проверь A-запись."

WARN_CONTINUE_ERROR="Continue despite the error? (y/n):"
WARN_CONTINUE_ERROR_RU="Продолжить несмотря на ошибку? (y/n):"

WARN_DNS_MISMATCH="A record $DOMAIN → $resolved_ip, but server IP: $SERVER_IP"
WARN_DNS_MISMATCH_RU="A-запись $DOMAIN → $resolved_ip, но IP сервера: $SERVER_IP"

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

OK_TG_CONFIGURED="Telegram: configured (report at ${REPORT_TIME} UTC)"
OK_TG_CONFIGURED_RU="Telegram: настроен (отчёт в ${REPORT_TIME} UTC)"

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
INFO_SERVER_IP="Server IP: ${SERVER_IP}"
INFO_SERVER_IP_RU="IP сервера: ${SERVER_IP}"

INFO_CHECKING_NEIGHBORS="Checking neighboring IPs in /24 range..."
INFO_CHECKING_NEIGHBORS_RU="Проверяю соседние адреса в диапазоне /24..."

OK_SUBNET_CLEAN="In ${CHECKED} checked neighbor IPs — 0 VPN/hosting servers. Subnet is clean ✓"
OK_SUBNET_CLEAN_RU="В ${CHECKED} проверенных соседних IP — 0 VPN/хостинг серверов. Подсеть чистая ✓"

WARN_SUBNET_MODERATE="Detected ${VPN_COUNT} VPN/hosting servers in ${CHECKED} checked IPs — moderate risk"
WARN_SUBNET_MODERATE_RU="Обнаружено ${VPN_COUNT} VPN/хостинг серверов в ${CHECKED} проверенных IP — риск умеренный"

WARN_SUBNET_ADVICE="Advice: monitor stability, change provider if problems occur"
WARN_SUBNET_ADVICE_RU="Совет: следи за стабильностью, при проблемах смени провайдера"

WARN_SUBNET_HIGH="Detected ${VPN_COUNT} VPN/hosting servers in ${CHECKED} checked IPs — HIGH risk"
WARN_SUBNET_HIGH_RU="Обнаружено ${VPN_COUNT} VPN/хостинг серверов в ${CHECKED} проверенных IP — риск ВЫСОКИЙ"

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
OK_BBR="TCP congestion control: ${CURRENT}"
OK_BBR_RU="TCP congestion control: ${CURRENT}"

# ── Firewall ──────────────────────────────────────────────────
OK_FIREWALL="Firewall enabled: 22/tcp, 443/tcp, 443/udp"
OK_FIREWALL_RU="Файрвол включён: 22/tcp, 443/tcp, 443/udp"

WARN_SSH_PORT="SSH: after checking new port, close 22 → ufw delete allow 22/tcp"
WARN_SSH_PORT_RU="SSH: после проверки нового порта закрой 22 → ufw delete allow 22/tcp"

# ── Fail2ban ──────────────────────────────────────────────────
OK_FAIL2BAN="Fail2ban: SSH protection on port ${SSH_PORT} (3 attempts → 24h ban)"
OK_FAIL2BAN_RU="Fail2ban: SSH защита на порту ${SSH_PORT} (3 попытки → бан 24ч)"

# ── Sing-box ──────────────────────────────────────────────────
INFO_GETTING_SINGBOX="Getting latest version from GitHub..."
INFO_GETTING_SINGBOX_RU="Получаю последнюю версию с GitHub..."

INFO_DOWNLOADING_SINGBOX="Downloading Sing-box ${SB_TAG}..."
INFO_DOWNLOADING_SINGBOX_RU="Скачиваю Sing-box ${SB_TAG}..."

OK_SINGBOX_INSTALLED="Sing-box ${SB_TAG} ($(arch)) installed"
OK_SINGBOX_INSTALLED_RU="Sing-box ${SB_TAG} ($(arch)) установлен"

# ── Keys and ports ────────────────────────────────────────────
OK_REALITY_GENERATED="Reality keypair generated, camouflage: ${REALITY_SNI}"
OK_REALITY_GENERATED_RU="Reality keypair сгенерирован, camouflage: ${REALITY_SNI}"

OK_PORTS_GENERATED="Ports → Trojan:${TROJAN_PORT} SS:${SS_PORT} Panel:${PANEL_PORT} Subscription:${SUB_PORT}"
OK_PORTS_GENERATED_RU="Порты → Trojan:${TROJAN_PORT} SS:${SS_PORT} Панель:${PANEL_PORT} Подписки:${SUB_PORT}"

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

INFO_REQUESTING_CERT="Requesting certificate for ${DOMAIN}..."
INFO_REQUESTING_CERT_RU="Запрашиваю сертификат для ${DOMAIN}..."

ERR_CERT_FAILED="Failed to obtain certificate. Check A record: ${DOMAIN} → ${SERVER_IP}"
ERR_CERT_FAILED_RU="Не удалось получить сертификат. Проверь A-запись: ${DOMAIN} → ${SERVER_IP}"

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

# ── Helper function to get localized string ───────────────────
get_str() {
    local key="$1"
    local ru_key="${key}_RU"
    
    if [[ "$LANG_NAME" == "Русский" ]]; then
        echo "${!ru_key:-${!key}}"
    else
        echo "${!key}"
    fi
}

# ── Step title helper ─────────────────────────────────────────
step_title() {
    local step_num="$1"
    local title_ru="$2"
    local title_en="$3"
    
    if [[ "$LANG_NAME" == "Русский" ]]; then
        step "Шаг ${step_num}/12 — ${title_ru}"
    else
        step "Step ${step_num}/12 — ${title_en}"
    fi
}
