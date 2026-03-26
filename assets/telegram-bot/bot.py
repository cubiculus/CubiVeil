#!/usr/bin/env python3
"""
CubiVeil Telegram Bot - Main Module
- Daily reports: CPU, RAM, disk, uptime, active users + DB backup
- Alerts when thresholds are exceeded
- Interactive commands only for authorized chat_id
- Health checks: connection speed, profile status, auto-heal
- Inline keyboards and menus
"""

import os
import json
import time
import subprocess  # nosec B404
import sqlite3
import shutil
from datetime import datetime

# Local modules
from telegram_client import TelegramClient
from metrics import MetricsCollector
from backup import BackupManager
from alert_state import AlertStateManager
from commands import CommandHandler
from health_check import HealthChecker
from logs import LogsManager

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# File paths / Пути к файлам
DB_PATH = "/var/lib/marzban/db.sqlite3"
BACKUP_DIR = "/opt/cubiveil-bot/backups"

# Environment variables / Переменные окружения
ENV_TG_TOKEN = "TG_TOKEN"
ENV_TG_CHAT_ID = "TG_CHAT_ID"
ENV_ALERT_CPU = "ALERT_CPU"
ENV_ALERT_RAM = "ALERT_RAM"
ENV_ALERT_DISK = "ALERT_DISK"

# Alert thresholds defaults / Пороги уведомлений по умолчанию
DEFAULT_ALERT_CPU = 80
DEFAULT_ALERT_RAM = 85
DEFAULT_ALERT_DISK = 90

# Threshold validation bounds / Границы проверки порогов
THRESHOLD_MIN = 0
THRESHOLD_MAX = 100

# Time intervals in seconds / Временные интервалы в секундах
HEALTH_CHECK_INTERVAL = 300  # 5 minutes
POLL_ERROR_DELAY = 5
REQUEST_TIMEOUT = 30

# Progress bar settings / Настройки прогресс-бара
PROGRESS_BAR_WIDTH = 10
PROGRESS_BAR_FILLED = "█"
PROGRESS_BAR_EMPTY = "░"

# Status icons / Иконки статусов
STATUS_ICON_ALERT = "🔴"
STATUS_ICON_OK = "🟢"


class CubiVeilBot:
    """Main bot class coordinating all components"""

    def __init__(self):
        # Load sensitive data from environment variables (systemd Environment)
        self.token = os.environ.get(ENV_TG_TOKEN)
        self.chat_id = os.environ.get(ENV_TG_CHAT_ID)
        self.db_path = DB_PATH
        self.backup_dir = BACKUP_DIR

        # Alert thresholds - validated and read from environment variables
        # with protection against SQL injection and XSS
        self.alert_cpu = self._validate_threshold(
            int(os.environ.get(ENV_ALERT_CPU, str(DEFAULT_ALERT_CPU)))
        )
        self.alert_ram = self._validate_threshold(
            int(os.environ.get(ENV_ALERT_RAM, str(DEFAULT_ALERT_RAM)))
        )
        self.alert_disk = self._validate_threshold(
            int(os.environ.get(ENV_ALERT_DISK, str(DEFAULT_ALERT_DISK)))
        )

        # Validate required environment variables
        if not self.token or not self.chat_id:
            print("[bot] ERROR: TG_TOKEN and TG_CHAT_ID must be set in environment variables")
            exit(1)

        # Initialize Telegram client and validate token
        self.telegram = TelegramClient(self.token, self.chat_id)

        print("[bot] Validating Telegram bot token...")
        is_valid, message = self.telegram.validate_token()
        if not is_valid:
            print(f"[bot] ERROR: Invalid Telegram token - {message}")
            exit(1)
        print(f"[bot] Token validated successfully - {message}")

        # Create necessary directories
        os.makedirs(self.backup_dir, exist_ok=True)

        # Initialize components
        self.metrics = MetricsCollector(self.db_path)
        self.backup = BackupManager(self.db_path, self.backup_dir)
        self.alert_state = AlertStateManager()
        self.health = HealthChecker()
        self.logs = LogsManager()
        self.commands = CommandHandler(
            self.telegram,
            self.metrics,
            self.backup,
            self.alert_state,
            self.alert_cpu,
            self.alert_ram,
            self.alert_disk,
            self.health,
            self.logs
        )

    def _validate_threshold(self, value):
        """Validate threshold value is between 0 and 100"""
        return min(THRESHOLD_MAX, max(THRESHOLD_MIN, value))

    def send_startup_message(self):
        """Send startup message with alert thresholds"""
        self.telegram.send(
            f"{STATUS_ICON_OK} <b>CubiVeil Bot started</b>\n"
            f"Alerts: CPU>{self.alert_cpu}% RAM>{self.alert_ram}% Disk>{self.alert_disk}%\n"
            "Send /help or use menu below",
            reply_markup=self._build_main_menu_json()
        )

    def _build_main_menu_json(self):
        """Build main menu inline keyboard JSON"""
        return {
            "inline_keyboard": [
                [
                    {"text": "📊 Status", "callback_data": "main_status"},
                    {"text": "📈 Monitor", "callback_data": "main_monitor"}
                ],
                [
                    {"text": "💾 Backup", "callback_data": "main_backup"},
                    {"text": "👥 Users", "callback_data": "main_users"}
                ],
                [
                    {"text": "📋 Logs", "callback_data": "main_logs"},
                    {"text": "🏥 Health", "callback_data": "main_health"}
                ],
                [
                    {"text": "👤 Profiles", "callback_data": "main_profiles"},
                    {"text": "⚙️ Settings", "callback_data": "main_settings"}
                ]
            ]
        }

    def send_daily_report(self):
        """Send daily report with metrics and backup"""
        cpu = self.metrics.get_cpu()
        ram_u, ram_t, ram_p = self.metrics.get_ram()
        dsk_u, dsk_t, dsk_p = self.metrics.get_disk()
        uptime = self.metrics.get_uptime()
        users = self.metrics.get_active_users()
        now = datetime.now().strftime("%d.%m.%Y %H:%M UTC")

        # Determine status icons
        cpu_icon = STATUS_ICON_ALERT if cpu > self.alert_cpu else STATUS_ICON_OK
        ram_icon = STATUS_ICON_ALERT if ram_p > self.alert_ram else STATUS_ICON_OK
        disk_icon = STATUS_ICON_ALERT if dsk_p > self.alert_disk else STATUS_ICON_OK

        # Build progress bar
        def bar(pct, width=PROGRESS_BAR_WIDTH):
            filled = int(min(pct, THRESHOLD_MAX) / THRESHOLD_MAX * width)
            return PROGRESS_BAR_FILLED * filled + PROGRESS_BAR_EMPTY * (width - filled)

        # Send report
        self.telegram.send(
            f"<b>🛡 CubiVeil — Daily Report</b>\n"
            f"<code>{now}</code>\n"
            f"━━━━━━━━━━━━━━━━━━━━━\n"
            f"{cpu_icon} CPU:   {cpu}%  {bar(cpu)}\n"
            f"{ram_icon} RAM:   {ram_u}/{ram_t} MB ({ram_p}%)  {bar(ram_p)}\n"
            f"{disk_icon} Disk:  {dsk_u}/{dsk_t} GB ({dsk_p}%)  {bar(dsk_p)}\n"
            f"⏱ Uptime:  {uptime}\n"
            f"━━━━━━━━━━━━━━━━━━━━━\n"
            f"👥 Active users: <b>{users}</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━\n"
            f"📦 DB backup attached below"
        )

        # Create and send backup
        bak = self.backup.create()
        if bak:
            self.telegram.send_file(bak, f"Marzban DB Backup • {datetime.now().strftime('%d.%m.%Y')}")
        else:
            self.telegram.send("⚠️ Failed to create DB backup")

    def check_health_and_heal(self):
        """
        Check health of all services and auto-restart if needed.
        Send alert if services were restarted.
        """
        actions = self.health.auto_heal()

        if actions:
            message = "⚠️ <b>Auto-heal triggered!</b>\n\n"
            for action in actions:
                if action["action"] == "restarted":
                    message += f"✅ {action['service']} restarted\n"
                else:
                    message += f"❌ {action['service']} restart failed\n"
            self.telegram.send(message)

    def check_alerts(self):
        """
        Send alert only when transitioning from normal to exceeded threshold,
        don't spam every 15 minutes if threshold already exceeded.
        """
        state = self.alert_state.load()
        alerts = []
        new_state = {}

        # CPU alert
        cpu = self.metrics.get_cpu()
        cpu_alert = cpu > self.alert_cpu
        if cpu_alert and not state.get("cpu"):
            alerts.append(f"🔴 <b>CPU</b>: {cpu}% (threshold {self.alert_cpu}%)")
        new_state["cpu"] = cpu_alert

        # RAM alert
        _, _, ram_p = self.metrics.get_ram()
        ram_alert = ram_p > self.alert_ram
        if ram_alert and not state.get("ram"):
            alerts.append(f"🔴 <b>RAM</b>: {ram_p}% (threshold {self.alert_ram}%)")
        new_state["ram"] = ram_alert

        # Disk alert
        _, _, dsk_p = self.metrics.get_disk()
        dsk_alert = dsk_p > self.alert_disk
        if dsk_alert and not state.get("disk"):
            alerts.append(f"🔴 <b>Disk</b>: {dsk_p}% (threshold {self.alert_disk}%)")
        new_state["disk"] = dsk_alert

        # Save new state
        self.alert_state.save(new_state)

        # Send alerts if any
        if alerts:
            self.telegram.send(
                "⚠️ <b>CubiVeil — Alert!</b>\n"
                "━━━━━━━━━━━━━━━\n" + "\n".join(alerts)
            )

    def _get_updates(self, offset: int) -> tuple:
        """
        Get updates from Telegram API
        Returns tuple: (updates_list, new_offset)
        """
        url = (f"https://api.telegram.org/bot{self.token}/getUpdates"
               f"?offset={offset}&timeout={REQUEST_TIMEOUT}&allowed_updates=[\"message\",\"callback_query\"]")

        response = self.telegram._make_request(url)
        data = json.loads(response)

        updates = data.get("result", [])
        return updates, offset

    def _process_message(self, message: dict):
        """Process incoming message"""
        # Strict authorization - only own chat_id
        if str(message.get("chat", {}).get("id", "")) != str(self.chat_id):
            return

        text = message.get("text", "")
        chat_id = message.get("chat", {}).get("id")
        if text.startswith("/"):
            self.commands.handle(text, str(chat_id))

    def _process_callback(self, callback_query: dict):
        """Process callback query (inline button press)"""
        # Strict authorization
        chat = callback_query.get("message", {}).get("chat", {})
        if str(chat.get("id", "")) != str(self.chat_id):
            return

        self.commands.handle_callback(callback_query)

    def poll(self):
        """Poll Telegram API for messages and callbacks"""
        self.send_startup_message()
        offset = 0
        last_health_check = 0
        health_check_interval = HEALTH_CHECK_INTERVAL

        while True:
            try:
                # Periodic health check
                current_time = time.time()
                if current_time - last_health_check > health_check_interval:
                    self.check_health_and_heal()
                    last_health_check = current_time

                # Get updates
                updates, offset = self._get_updates(offset)

                for update in updates:
                    # Update offset
                    update_id = update.get("update_id", 0)
                    if update_id >= offset:
                        offset = update_id + 1

                    # Process message
                    message = update.get("message")
                    if message:
                        self._process_message(message)

                    # Process callback query
                    callback_query = update.get("callback_query")
                    if callback_query:
                        self._process_callback(callback_query)

            except Exception as e:
                print(f"[bot] poll error: {e}")
                time.sleep(POLL_ERROR_DELAY)


if __name__ == "__main__":
    import sys

    bot = CubiVeilBot()
    cmd = sys.argv[1] if len(sys.argv) > 1 else "poll"

    if cmd == "report":
        bot.send_daily_report()
    elif cmd == "alert":
        bot.check_alerts()
    elif cmd == "poll":
        bot.poll()
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
