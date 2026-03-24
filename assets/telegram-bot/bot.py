#!/usr/bin/env python3
"""
CubiVeil Telegram Bot - Main Module
- Daily reports: CPU, RAM, disk, uptime, active users + DB backup
- Alerts when thresholds are exceeded
- Interactive commands only for authorized chat_id
- Health checks: connection speed, profile status, auto-heal
"""

import os
import json
import time
import subprocess
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


class CubiVeilBot:
    """Main bot class coordinating all components"""

    def __init__(self):
        # Load sensitive data from environment variables (systemd Environment)
        self.token = os.environ.get("TG_TOKEN")
        self.chat_id = os.environ.get("TG_CHAT_ID")
        self.db_path = "/var/lib/marzban/db.sqlite3"
        self.backup_dir = "/opt/cubiveil-bot/backups"

        # Alert thresholds - validated and read from environment variables
        # with protection against SQL injection and XSS
        self.alert_cpu = self._validate_threshold(int(os.environ.get("ALERT_CPU", "80")))
        self.alert_ram = self._validate_threshold(int(os.environ.get("ALERT_RAM", "85")))
        self.alert_disk = self._validate_threshold(int(os.environ.get("ALERT_DISK", "90")))

        # Validate required environment variables
        if not self.token or not self.chat_id:
            print("[bot] ERROR: TG_TOKEN and TG_CHAT_ID must be set in environment variables")
            exit(1)

        # Create necessary directories
        os.makedirs(self.backup_dir, exist_ok=True)

        # Initialize components
        self.telegram = TelegramClient(self.token, self.chat_id)
        self.metrics = MetricsCollector(self.db_path)
        self.backup = BackupManager(self.db_path, self.backup_dir)
        self.alert_state = AlertStateManager()
        self.health = HealthChecker()
        self.commands = CommandHandler(
            self.telegram,
            self.metrics,
            self.backup,
            self.alert_state,
            self.alert_cpu,
            self.alert_ram,
            self.alert_disk,
            self.health
        )

    def _validate_threshold(self, value):
        """Validate threshold value is between 0 and 100"""
        return min(100, max(0, value))

    def send_startup_message(self):
        """Send startup message with alert thresholds"""
        self.telegram.send(
            "🟢 <b>CubiVeil Bot started</b>\n"
            f"Alerts: CPU>{self.alert_cpu}% RAM>{self.alert_ram}% Disk>{self.alert_disk}%\n"
            "Send /help"
        )

    def send_daily_report(self):
        """Send daily report with metrics and backup"""
        cpu = self.metrics.get_cpu()
        ram_u, ram_t, ram_p = self.metrics.get_ram()
        dsk_u, dsk_t, dsk_p = self.metrics.get_disk()
        uptime = self.metrics.get_uptime()
        users = self.metrics.get_active_users()
        now = datetime.now().strftime("%d.%m.%Y %H:%M UTC")

        # Determine status icons
        ci = "🔴" if cpu > self.alert_cpu else "🟢"
        ri = "🔴" if ram_p > self.alert_ram else "🟢"
        di = "🔴" if dsk_p > self.alert_disk else "🟢"

        # Build progress bars
        def bar(pct, width=10):
            filled = int(min(pct, 100) / 100 * width)
            return "█" * filled + "░" * (width - filled)

        # Send report
        self.telegram.send(
            f"<b>🛡 CubiVeil — Daily Report</b>\n"
            f"<code>{now}</code>\n"
            f"━━━━━━━━━━━━━━━━━━━━━\n"
            f"{ci} CPU:   {cpu}%  {bar(cpu)}\n"
            f"{ri} RAM:   {ram_u}/{ram_t} MB ({ram_p}%)  {bar(ram_p)}\n"
            f"{di} Disk:  {dsk_u}/{dsk_t} GB ({dsk_p}%)  {bar(dsk_p)}\n"
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

    def poll(self):
        """Poll Telegram API for messages"""
        self.send_startup_message()
        offset = 0
        last_health_check = 0
        health_check_interval = 300  # Check health every 5 minutes

        while True:
            try:
                # Periodic health check
                current_time = time.time()
                if current_time - last_health_check > health_check_interval:
                    self.check_health_and_heal()
                    last_health_check = current_time

                url = (f"https://api.telegram.org/bot{self.token}/getUpdates"
                       f"?offset={offset}&timeout=30&allowed_updates=[\"message\"]")

                response = self.telegram._make_request(url)
                data = json.loads(response)

                for update in data.get("result", []):
                    offset = update["update_id"] + 1
                    message = update.get("message", {})

                    # Strict authorization - only own chat_id
                    if str(message.get("chat", {}).get("id", "")) != str(self.chat_id):
                        continue

                    text = message.get("text", "")
                    if text.startswith("/"):
                        self.commands.handle(text)

            except Exception as e:
                print(f"[bot] poll error: {e}")
                time.sleep(5)


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
