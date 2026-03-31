#!/usr/bin/env python3
"""
Common Constants Module
Shared constants for Telegram bot components
"""

# ══════════════════════════════════════════════════════════════════════════════
# File paths / Пути к файлам
# ══════════════════════════════════════════════════════════════════════════════

DB_PATH = "/usr/local/s-ui/db/s-ui.db"
DEFAULT_DB_PATH = DB_PATH  # Alias for compatibility
BACKUP_DIR = "/opt/cubiveil-bot/backups"

# System files / Системные файлы
PROC_STAT_PATH = "/proc/stat"
PROC_MEMINFO_PATH = "/proc/meminfo"
PROC_UPTIME_PATH = "/proc/uptime"

# ══════════════════════════════════════════════════════════════════════════════
# S-UI paths / Пути к S-UI
# ══════════════════════════════════════════════════════════════════════════════

SUI_DIR = "/usr/local/s-ui"
SUI_DB_DIR = "/usr/local/s-ui/db"
SUI_DB_FILE = DB_PATH
SUI_ENV_FILE = "/etc/cubiveil/s-ui.credentials"

# ══════════════════════════════════════════════════════════════════════════════
# Decoy Site paths / Пути к сайту-прикрытию
# ══════════════════════════════════════════════════════════════════════════════

DECOY_CONFIG = "/etc/cubiveil/decoy.json"
DECOY_WEBROOT = "/var/www/decoy"
DECOY_TIMER = "cubiveil-decoy-rotate"
DECOY_ROTATE_SCRIPT = "/usr/local/lib/cubiveil/decoy-rotate.sh"

# ══════════════════════════════════════════════════════════════════════════════
# Default ports / Порты по умолчанию
# ══════════════════════════════════════════════════════════════════════════════

DEFAULT_HEALTH_CHECK_PORT = 2095

# ══════════════════════════════════════════════════════════════════════════════
# Alert thresholds defaults / Пороги уведомлений по умолчанию
# ══════════════════════════════════════════════════════════════════════════════

DEFAULT_ALERT_CPU = 80
DEFAULT_ALERT_RAM = 85
DEFAULT_ALERT_DISK = 90

# Threshold validation bounds / Границы проверки порогов
THRESHOLD_MIN = 0
THRESHOLD_MAX = 100

# ══════════════════════════════════════════════════════════════════════════════
# Time intervals in seconds / Временные интервалы в секундах
# ══════════════════════════════════════════════════════════════════════════════

HEALTH_CHECK_INTERVAL = 300  # 5 minutes
POLL_ERROR_DELAY = 5
REQUEST_TIMEOUT = 35  # Long polling timeout + buffer (must be > getUpdates timeout)
RESTART_COOLDOWN = 300  # 5 minutes between auto-restarts
CONNECTION_TIMEOUT = 10  # Default connection timeout
SERVICE_CHECK_TIMEOUT = 10  # Service status check timeout
SERVICE_RESTART_TIMEOUT = 60  # Service restart timeout
HEALTH_ENDPOINT_TIMEOUT = 15  # Health endpoint check timeout
DB_TIMEOUT = 5  # Database connection timeout
CPU_READ_DELAY = 0.01  # Minimal delay between CPU readings
DISK_CHECK_TIMEOUT = 5  # Disk check command timeout

# ══════════════════════════════════════════════════════════════════════════════
# Progress bar settings / Настройки прогресс-бара
# ══════════════════════════════════════════════════════════════════════════════

PROGRESS_BAR_WIDTH = 10
PROGRESS_BAR_FILLED = "█"
PROGRESS_BAR_EMPTY = "░"

# ══════════════════════════════════════════════════════════════════════════════
# Status icons / Иконки статусов
# ══════════════════════════════════════════════════════════════════════════════

STATUS_ICON_ALERT = "🔴"
STATUS_ICON_OK = "🟢"

# ══════════════════════════════════════════════════════════════════════════════
# Unit conversion / Конвертация единиц
# ══════════════════════════════════════════════════════════════════════════════

KB_TO_MB_DIVISOR = 1024  # Convert kB to MB
SECONDS_PER_DAY = 86400
SECONDS_PER_HOUR = 3600
SECONDS_PER_MINUTE = 60

# ══════════════════════════════════════════════════════════════════════════════
# Environment variables / Переменные окружения
# ══════════════════════════════════════════════════════════════════════════════

ENV_TG_TOKEN = "TG_TOKEN"
ENV_TG_CHAT_ID = "TG_CHAT_ID"
ENV_ALERT_CPU = "ALERT_CPU"
ENV_ALERT_RAM = "ALERT_RAM"
ENV_ALERT_DISK = "ALERT_DISK"

# ══════════════════════════════════════════════════════════════════════════════
# Services to monitor / Сервисы для мониторинга
# ══════════════════════════════════════════════════════════════════════════════

MONITORED_SERVICES = ["s-ui", "sing-box"]

# ══════════════════════════════════════════════════════════════════════════════
# Service display names / Отображаемые имена сервисов
# ══════════════════════════════════════════════════════════════════════════════

SERVICE_NAMES = {
    "s-ui": "🆂 S-UI",
    "sing-box": "🆂 Sing-Box",
    "cubiveil-bot": "🤖 Bot",
    "nginx": "🌐 Nginx",
    "systemd": "💻 Systemd"
}

# ══════════════════════════════════════════════════════════════════════════════
# Profile constants / Константы профилей
# ══════════════════════════════════════════════════════════════════════════════

PROFILE_STATUSES = ["active", "disabled", "limited", "expired"]
PROFILE_DISPLAY_LIMIT = 10

# ══════════════════════════════════════════════════════════════════════════════
# Default connection test targets / Цели для проверки соединения по умолчанию
# ══════════════════════════════════════════════════════════════════════════════

DEFAULT_CONNECTION_TARGETS = [
    ("Google", "https://www.google.com"),
    ("Cloudflare", "https://www.cloudflare.com"),
    ("GitHub", "https://www.github.com"),
    ("Telegram", "https://api.telegram.org"),
]
