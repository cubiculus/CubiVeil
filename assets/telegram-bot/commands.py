#!/usr/bin/env python3
"""
Command Handler Module
Handles Telegram bot commands and inline keyboard callbacks
"""

import subprocess  # nosec B404
import json
import time
import re
import os
import logging
from typing import Optional, Dict, Any
from collections import defaultdict

logger = logging.getLogger(__name__)

# Local modules
from keyboards import (
    build_main_menu,
    build_backup_menu,
    build_logs_menu,
    build_profiles_menu,
    build_settings_menu,
    build_alerts_submenu,
    build_back_button,
    build_confirm_keyboard,
    build_pagination_keyboard,
    build_profile_actions_keyboard,
    build_backup_actions_keyboard,
    build_logs_lines_keyboard,
    build_decoy_menu,
    build_decoy_settings_menu,
    build_decoy_weights_menu,
    build_decoy_weight_edit_keyboard,
    build_decoy_advanced_menu,
    # Callback constants
    CALLBACK_MAIN_STATUS,
    CALLBACK_MAIN_MONITOR,
    CALLBACK_MAIN_BACKUP,
    CALLBACK_MAIN_USERS,
    CALLBACK_MAIN_LOGS,
    CALLBACK_MAIN_HEALTH,
    CALLBACK_MAIN_PROFILES,
    CALLBACK_MAIN_SETTINGS,
    CALLBACK_BACKUP_LIST,
    CALLBACK_BACKUP_CREATE,
    CALLBACK_BACKUP_RESTORE,
    CALLBACK_BACKUP_DELETE,
    CALLBACK_BACKUP_DOWNLOAD,
    CALLBACK_LOGS_MARZBAN,
    CALLBACK_LOGS_SINGBOX,
    CALLBACK_LOGS_BOT,
    CALLBACK_LOGS_NGINX,
    CALLBACK_LOGS_SYSTEM,
    CALLBACK_PROFILES_LIST,
    CALLBACK_PROFILES_ACTIVE,
    CALLBACK_PROFILES_DISABLED,
    CALLBACK_PROFILES_EXPIRED,
    CALLBACK_SETTINGS_ALERTS,
    CALLBACK_SETTINGS_REPORT,
    CALLBACK_SETTINGS_CPU,
    CALLBACK_SETTINGS_RAM,
    CALLBACK_SETTINGS_DISK,
    CALLBACK_NAV_BACK,
)

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# Command names / Имена команд
COMMAND_START = "/start"
COMMAND_STATUS = "/status"
COMMAND_MONITOR = "/monitor"
COMMAND_BACKUP = "/backup"
COMMAND_BACKUPS = "/backups"
COMMAND_RESTORE = "/restore"
COMMAND_BACKUP_DELETE = "/backup_delete"
COMMAND_USERS = "/users"
COMMAND_RESTART = "/restart"
COMMAND_HEALTH = "/health"
COMMAND_SPEEDTEST = "/speedtest"
COMMAND_PROFILES = "/profiles"
COMMAND_HELP = "/help"
COMMAND_LOGS = "/logs"
COMMAND_SETTINGS = "/settings"
COMMAND_SET_CPU = "/set_cpu"
COMMAND_SET_RAM = "/set_ram"
COMMAND_SET_DISK = "/set_disk"
# Profile commands / Команды профилей
COMMAND_ENABLE = "/enable"
COMMAND_DISABLE = "/disable"
COMMAND_EXTEND = "/extend"
COMMAND_RESET = "/reset"
COMMAND_QR = "/qr"
COMMAND_TRAFFIC = "/traffic"
COMMAND_SUBSCRIPTION = "/subscription"
COMMAND_CREATE = "/create"
COMMAND_DIAGNOSE = "/diagnose"
COMMAND_UPDATE = "/update"
COMMAND_ROLLBACK = "/rollback"
COMMAND_EXPORT_CONFIG = "/export"
COMMAND_IMPORT_CONFIG = "/import"
COMMAND_INSTALL_ALIASES = "/install_aliases"

# Decoy Site commands / Команды сайта-прикрытия
COMMAND_DECOY = "/decoy"
COMMAND_DECOY_STATUS = "/decoy_status"
COMMAND_DECOY_ROTATE = "/decoy_rotate"
COMMAND_DECOY_FILES = "/decoy_files"
COMMAND_DECOY_CONFIG = "/decoy_config"

# Progress bar settings / Настройки прогресс-бара
PROGRESS_BAR_WIDTH = 10
PROGRESS_BAR_FILLED = "█"
PROGRESS_BAR_EMPTY = "░"

# Rate limiting / Ограничение частоты команд
RATE_LIMIT_SECONDS = 3  # Минимальный интервал между командами
MAX_COMMANDS_PER_MINUTE = 10  # Максимум команд в минуту

# Timeouts in seconds / Таймауты в секундах
SERVICE_RESTART_TIMEOUT = 30
ERROR_MESSAGE_MAX_LENGTH = 500

# Profile display limit / Лимит отображения профилей
PROFILE_DISPLAY_LIMIT = 10

# Profile status icons / Иконки статусов профилей
PROFILE_STATUS_ICONS = {
    "active": "🟢",
    "disabled": "🔴",
    "limited": "🟡",
    "expired": "⚫",
}

# Default connection test targets / Цели для проверки соединения по умолчанию
SPEEDTEST_TARGETS = [
    ("Google", "https://www.google.com"),
    ("Cloudflare", "https://www.cloudflare.com"),
    ("GitHub", "https://www.github.com"),
    ("Telegram", "https://api.telegram.org"),
]

# Service mapping for logs / Маппинг сервисов для логов
SERVICE_LOG_MAP = {
    CALLBACK_LOGS_MARZBAN: "marzban",
    CALLBACK_LOGS_SINGBOX: "sing-box",
    CALLBACK_LOGS_BOT: "cubiveil-bot",
    CALLBACK_LOGS_NGINX: "nginx",
    CALLBACK_LOGS_SYSTEM: "systemd",
}

# Service display names / Отображаемые имена сервисов
SERVICE_NAMES = {
    "marzban": "🅼 Marzban",
    "sing-box": "🆂 Sing-Box",
    "cubiveil-bot": "🤖 Bot",
    "nginx": "🌐 Nginx",
}

# Local modules - profiles
from profiles import MarzbanClient

# Local modules - decoy
from decoy import DecoyManager


class CommandHandler:
    """Handles Telegram bot commands and callbacks"""

    def __init__(self, telegram, metrics, backup, alert_state, alert_cpu, alert_ram, alert_disk, health_checker=None, logs_manager=None):
        self.telegram = telegram
        self.metrics = metrics
        self.backup = backup
        self.alert_state = alert_state
        self.alert_cpu = alert_cpu
        self.alert_ram = alert_ram
        self.alert_disk = alert_disk
        self.health = health_checker
        self.logs = logs_manager
        self.marzban = MarzbanClient()
        self.decoy = DecoyManager()

        # Pending actions (for confirmations)
        self.pending_actions: Dict[str, dict] = {}

        # Rate limiting
        self._command_times: Dict[str, list] = defaultdict(list)
        self._last_command_time: Dict[str, float] = {}

    def _check_rate_limit(self, chat_id: str, command: str) -> bool:
        """
        Check rate limiting for commands
        Returns True if command is allowed, False if rate limited
        """
        current_time = time.time()
        key = f"{chat_id}:{command}"

        # Check minimum interval between commands
        last_time = self._last_command_time.get(chat_id, 0)
        if current_time - last_time < RATE_LIMIT_SECONDS:
            return False

        # Clean old entries (older than 1 minute)
        self._command_times[key] = [
            t for t in self._command_times[key]
            if current_time - t < 60
        ]

        # Check commands per minute limit
        if len(self._command_times[key]) >= MAX_COMMANDS_PER_MINUTE:
            return False

        # Record this command
        self._command_times[key].append(current_time)
        self._last_command_time[chat_id] = current_time
        return True

    def _progress_bar(self, pct, width=PROGRESS_BAR_WIDTH):
        """Generate progress bar"""
        filled = int(min(pct, 100) / 100 * width)
        return PROGRESS_BAR_FILLED * filled + PROGRESS_BAR_EMPTY * (width - filled)

    def _run_shell_utility(self, args, description):
        """Run utils/*.sh script and send brief output to Telegram"""
        self.telegram.send(f"⏳ {description}...")

        try:
            result = subprocess.run(  # nosec B603: args are hardcoded script paths
                args,
                capture_output=True,
                text=True,
                timeout=900,
                check=False
            )

            output = (result.stdout or result.stderr or "(no output)").strip()
            if len(output) > 3000:
                output = output[:2900] + "\n... (output truncated)"

            if result.returncode == 0:
                self.telegram.send(f"✅ {description} completed.\n<code>{output}</code>")
            else:
                self.telegram.send(
                    f"❌ {description} failed (exit code {result.returncode}).\n<code>{output}</code>"
                )

        except subprocess.TimeoutExpired:
            self.telegram.send(f"❌ {description} timed out (15m)")
        except Exception as e:
            self.telegram.send(f"❌ {description} error: {str(e)}")

    def _diagnose(self):
        """Run diagnose utility and send report path"""
        script = "/usr/local/bin/cubiveil/utils/diagnose.sh"
        # Fallback to repo path
        if not os.path.exists(script):
            script = "/opt/cubiveil/utils/diagnose.sh"

        if not os.path.exists(script):
            script = "./utils/diagnose.sh"

        # Start diagnose and keep last report location known
        self._run_shell_utility(["bash", script], "Diagnostics")

    def _update(self):
        """Run update utility"""
        script = "/usr/local/bin/cubiveil/utils/update.sh"
        if not os.path.exists(script):
            script = "/opt/cubiveil/utils/update.sh"
        if not os.path.exists(script):
            script = "./utils/update.sh"

        self._run_shell_utility(["bash", script], "Update")

    def _rollback(self, command):
        """Run rollback utility with optional target"""
        script = "/usr/local/bin/cubiveil/utils/rollback.sh"
        if not os.path.exists(script):
            script = "/opt/cubiveil/utils/rollback.sh"
        if not os.path.exists(script):
            script = "./utils/rollback.sh"

        args = ["bash", script]
        params = command.strip().split()[1:]
        if params:
            args += params

        self._run_shell_utility(args, "Rollback")

    def _export_config(self):
        """Run export-config utility"""
        script = "/usr/local/bin/cubiveil/utils/export-config.sh"
        if not os.path.exists(script):
            script = "/opt/cubiveil/utils/export-config.sh"
        if not os.path.exists(script):
            script = "./utils/export-config.sh"

        self._run_shell_utility(["bash", script], "Export config")

    def _import_config(self, command):
        """Run import-config utility with path"""
        script = "/usr/local/bin/cubiveil/utils/import-config.sh"
        if not os.path.exists(script):
            script = "/opt/cubiveil/utils/import-config.sh"
        if not os.path.exists(script):
            script = "./utils/import-config.sh"

        params = command.strip().split()[1:]
        if not params:
            self.telegram.send("⚠️ Usage: /import <path_to_exported_config>")
            return

        args = ["bash", script] + params
        self._run_shell_utility(args, "Import config")

    def _install_aliases(self):
        """Run install-aliases utility"""
        script = "/usr/local/bin/cubiveil/utils/install-aliases.sh"
        if not os.path.exists(script):
            script = "/opt/cubiveil/utils/install-aliases.sh"
        if not os.path.exists(script):
            script = "./utils/install-aliases.sh"

        self._run_shell_utility(["bash", script], "Install aliases")

    # ═══════════════════════════════════════════════════════════════════════════
    # Command Handlers / Обработчики команд
    # ═══════════════════════════════════════════════════════════════════════════

    def handle(self, command: str, chat_id: str = None):
        """
        Handle incoming command with rate limiting
        Args:
            command: Command text
            chat_id: Chat ID for rate limiting
        """
        cmd = command.strip().split()[0].lower()

        # Rate limiting check
        if chat_id and not self._check_rate_limit(chat_id, cmd):
            self.telegram.send("⏳ Please wait a moment before sending another command")
            return

        # Show typing status for long operations
        if cmd in (COMMAND_HEALTH, COMMAND_SPEEDTEST, COMMAND_LOGS, COMMAND_MONITOR, COMMAND_QR, COMMAND_TRAFFIC):
            self.telegram.send_chat_action("typing")

        # Route commands
        if cmd in (COMMAND_START, COMMAND_STATUS):
            self._status()
        elif cmd == COMMAND_MONITOR:
            self._monitor()
        elif cmd in (COMMAND_BACKUP, COMMAND_BACKUPS):
            self._backup_menu()
        elif cmd == COMMAND_RESTORE:
            self._restore_command(command)
        elif cmd == COMMAND_BACKUP_DELETE:
            self._backup_delete_command(command)
        elif cmd == COMMAND_USERS:
            self._users()
        elif cmd == COMMAND_RESTART:
            self._restart()
        elif cmd == COMMAND_HEALTH:
            self._health()
        elif cmd == COMMAND_SPEEDTEST:
            self._speedtest()
        elif cmd == COMMAND_PROFILES:
            self._profiles()
        elif cmd == COMMAND_LOGS:
            self._logs_command(command)
        elif cmd == COMMAND_SETTINGS:
            self._settings_menu()
        elif cmd == COMMAND_SET_CPU:
            self._set_cpu(command)
        elif cmd == COMMAND_SET_RAM:
            self._set_ram(command)
        elif cmd == COMMAND_SET_DISK:
            self._set_disk(command)
        elif cmd == COMMAND_DIAGNOSE:
            self._diagnose()
        elif cmd == COMMAND_UPDATE:
            self._update()
        elif cmd == COMMAND_ROLLBACK:
            self._rollback(command)
        elif cmd == COMMAND_EXPORT_CONFIG:
            self._export_config()
        elif cmd == COMMAND_IMPORT_CONFIG:
            self._import_config(command)
        elif cmd == COMMAND_INSTALL_ALIASES:
            self._install_aliases()
        # Decoy Site commands
        elif cmd in (COMMAND_DECOY, COMMAND_DECOY_STATUS):
            self._decoy_menu(chat_id)
        elif cmd == COMMAND_DECOY_ROTATE:
            self._decoy_rotate(chat_id)
        elif cmd == COMMAND_DECOY_FILES:
            self._decoy_files(chat_id)
        elif cmd == COMMAND_DECOY_CONFIG:
            self._decoy_config(chat_id)
        # Profile commands
        elif cmd == COMMAND_ENABLE:
            self._enable_command(command)
        elif cmd == COMMAND_DISABLE:
            self._disable_command(command)
        elif cmd == COMMAND_EXTEND:
            self._extend_command(command)
        elif cmd == COMMAND_RESET:
            self._reset_command(command)
        elif cmd == COMMAND_QR:
            self._qr_command(command)
        elif cmd == COMMAND_TRAFFIC:
            self._traffic_command(command)
        elif cmd == COMMAND_SUBSCRIPTION:
            self._subscription_command(command)
        elif cmd == COMMAND_CREATE:
            self._create_command(command)
        elif cmd == COMMAND_HELP:
            self._help()
        else:
            self.telegram.send("❓ Unknown command. Send /help for command list")

    def handle_callback(self, callback_query: dict):
        """
        Handle inline keyboard callback
        Args:
            callback_query: Telegram callback_query object
        """
        chat_id = callback_query.get("message", {}).get("chat", {}).get("id")
        message_id = callback_query.get("message", {}).get("message_id")
        data = callback_query.get("data", "")

        # Answer callback (remove loading state)
        self.telegram.answer_callback(callback_query.get("id", ""))

        # Route to handler
        if data.startswith("main_"):
            self._handle_main_menu(chat_id, message_id, data)
        elif data.startswith("backup_"):
            self._handle_backup_menu(chat_id, message_id, data)
        elif data.startswith("logs_"):
            self._handle_logs_menu(chat_id, message_id, data)
        elif data.startswith("profile_"):
            self._handle_profile_menu(chat_id, message_id, data)
        elif data.startswith("profiles_"):
            self._handle_profiles_list(chat_id, message_id, data)
        elif data.startswith("settings_"):
            self._handle_settings_menu(chat_id, message_id, data)
        elif data.startswith("nav_"):
            self._handle_navigation(chat_id, message_id, data)

    # ═══════════════════════════════════════════════════════════════════════════
    # Navigation Handlers / Навигация
    # ═══════════════════════════════════════════════════════════════════════════

    def _handle_navigation(self, chat_id, message_id, data: str):
        """Handle navigation buttons"""
        if data == CALLBACK_NAV_BACK:
            # Show main menu
            self.telegram.edit_message_text(
                chat_id, message_id,
                "<b>🤖 CubiVeil Bot — Main Menu</b>\n\nSelect an option:",
                reply_markup=json.dumps(build_main_menu())
            )

    # ═══════════════════════════════════════════════════════════════════════════
    # Main Menu Handlers / Главное меню
    # ═══════════════════════════════════════════════════════════════════════════

    def _handle_main_menu(self, chat_id, message_id, data: str):
        """Handle main menu callbacks"""
        if data == CALLBACK_MAIN_STATUS:
            self._status()
        elif data == CALLBACK_MAIN_MONITOR:
            self._monitor()
        elif data == CALLBACK_MAIN_BACKUP:
            self._backup_menu()
        elif data == CALLBACK_MAIN_USERS:
            self._users()
        elif data == CALLBACK_MAIN_LOGS:
            self._logs_menu()
        elif data == CALLBACK_MAIN_HEALTH:
            self._health()
        elif data == CALLBACK_MAIN_PROFILES:
            self._profiles()
        elif data == CALLBACK_MAIN_SETTINGS:
            self._settings_menu()
        elif data == CALLBACK_DECOY_MAIN:
            self._decoy_menu(chat_id, message_id)
        elif data == CALLBACK_DECOY_STATUS:
            self._decoy_status(chat_id, message_id)
        elif data == CALLBACK_DECOY_ROTATE:
            self._decoy_rotate(chat_id, message_id)
        elif data == CALLBACK_DECOY_FILES:
            self._decoy_files(chat_id, message_id)
        elif data == CALLBACK_DECOY_CONFIG:
            self._decoy_config(chat_id, message_id)
        elif data == CALLBACK_DECOY_SETTINGS:
            self._decoy_settings_menu(chat_id, message_id)

    # ═══════════════════════════════════════════════════════════════════════════
    # Backup Menu Handlers / Меню бэкапов
    # ═══════════════════════════════════════════════════════════════════════════

    def _handle_backup_menu(self, chat_id, message_id, data: str):
        """Handle backup menu callbacks"""
        if data == CALLBACK_BACKUP_LIST:
            self._list_backups()
        elif data == CALLBACK_BACKUP_CREATE:
            self._create_backup()
        elif data == CALLBACK_BACKUP_RESTORE:
            self.telegram.send("⚠️ Restore feature: Use /restore <filename> command")
        elif data == CALLBACK_BACKUP_DELETE:
            self._cleanup_backups()
        elif data.startswith("backup_download:"):
            filename = data.split(":", 1)[1].replace("_", "/")
            self._download_backup(filename)
        elif data.startswith("backup_restore:"):
            filename = data.split(":", 1)[1].replace("_", "/")
            self._confirm_restore(filename)
        elif data.startswith("backup_delete:"):
            filename = data.split(":", 1)[1].replace("_", "/")
            self._confirm_delete_backup(filename)
        elif data.startswith("backup_confirm:"):
            filename = data.split(":", 1)[1].replace("_", "/")
            self._restore_backup(filename)
        elif data.startswith("backup_cancel:"):
            self.telegram.send(chat_id, "✅ Cancelled")

    # ═══════════════════════════════════════════════════════════════════════════
    # Logs Menu Handlers / Меню логов
    # ═══════════════════════════════════════════════════════════════════════════

    def _handle_logs_menu(self, chat_id, message_id, data: str):
        """Handle logs menu callbacks"""
        if data.startswith("logs_lines:"):
            # Parse: logs_lines:service:lines
            parts = data.split(":")
            if len(parts) >= 3:
                service = parts[1]
                lines = int(parts[2])
                self._show_logs(service, lines)
        elif data in SERVICE_LOG_MAP:
            service = SERVICE_LOG_MAP[data]
            self._show_logs(service, 50)

    # ═══════════════════════════════════════════════════════════════════════════
    # Profiles Handlers / Профили
    # ═══════════════════════════════════════════════════════════════════════════

    def _handle_profiles_list(self, chat_id, message_id, data: str):
        """Handle profiles list callbacks"""
        if data == CALLBACK_PROFILES_LIST:
            self._show_all_profiles()
        elif data == CALLBACK_PROFILES_ACTIVE:
            self._show_profiles_by_status("active")
        elif data == CALLBACK_PROFILES_DISABLED:
            self._show_profiles_by_status("disabled")
        elif data == CALLBACK_PROFILES_EXPIRED:
            self._show_profiles_by_status("expired")
        elif data.startswith("profile_info:"):
            username = data.split(":", 1)[1]
            self._show_profile_info(username)
        elif data.startswith("profile_extend:"):
            username = data.split(":", 1)[1]
            self.telegram.send("⚠️ Extend: Use /extend <username> <days> command")
        elif data.startswith("profile_disable:"):
            username = data.split(":", 1)[1]
            self._confirm_disable_profile(username)
        elif data.startswith("profile_enable:"):
            username = data.split(":", 1)[1]
            self._enable_profile(username)
        elif data.startswith("profile_reset:"):
            username = data.split(":", 1)[1]
            self.telegram.send("⚠️ Reset traffic: Use /reset <username> command")
        elif data.startswith("profile_qr:"):
            username = data.split(":", 1)[1]
            self._show_qr(username)

    # ═══════════════════════════════════════════════════════════════════════════
    # Settings Handlers / Настройки
    # ═══════════════════════════════════════════════════════════════════════════

    def _handle_settings_menu(self, chat_id, message_id, data: str):
        """Handle settings menu callbacks"""
        if data == CALLBACK_SETTINGS_ALERTS:
            self._show_alerts_settings()
        elif data == CALLBACK_SETTINGS_REPORT:
            self.telegram.send("⚠️ Change report time: Use /set_report <HH:MM> command")
        elif data == CALLBACK_SETTINGS_CPU:
            self.telegram.send("⚠️ Change CPU threshold: Use /set_cpu <percent> command")
        elif data == CALLBACK_SETTINGS_RAM:
            self.telegram.send("⚠️ Change RAM threshold: Use /set_ram <percent> command")
        elif data == CALLBACK_SETTINGS_DISK:
            self.telegram.send("⚠️ Change Disk threshold: Use /set_disk <percent> command")

    # ═══════════════════════════════════════════════════════════════════════════
    # Command Implementations / Реализация команд
    # ═══════════════════════════════════════════════════════════════════════════

    def _status(self):
        """Send server status with main menu"""
        cpu = self.metrics.get_cpu()
        ram_u, ram_t, ram_p = self.metrics.get_ram()
        dsk_u, dsk_t, dsk_p = self.metrics.get_disk()
        uptime = self.metrics.get_uptime()
        users = self.metrics.get_active_users()

        self.telegram.send(
            f"<b>📊 Server Status</b>\n"
            f"━━━━━━━━━━━━━━━\n"
            f"CPU:    {cpu}%  {self._progress_bar(cpu)}\n"
            f"RAM:    {ram_u}/{ram_t} MB ({ram_p}%)\n"
            f"Disk:   {dsk_u}/{dsk_t} GB ({dsk_p}%)\n"
            f"Uptime: {uptime}\n"
            f"━━━━━━━━━━━━━━━\n"
            f"👥 Active: {users}",
            reply_markup=json.dumps(build_main_menu())
        )

    def _monitor(self):
        """Send detailed monitor info"""
        cpu = self.metrics.get_cpu()
        ram_u, ram_t, ram_p = self.metrics.get_ram()
        dsk_u, dsk_t, dsk_p = self.metrics.get_disk()
        uptime = self.metrics.get_uptime()
        users = self.metrics.get_active_users()

        # Status icons
        cpu_icon = "🔴" if cpu > self.alert_cpu else "🟢"
        ram_icon = "🔴" if ram_p > self.alert_ram else "🟢"
        disk_icon = "🔴" if dsk_p > self.alert_disk else "🟢"

        self.telegram.send(
            f"<b>📈 System Monitor</b>\n"
            f"━━━━━━━━━━━━━━━━━━━━━\n"
            f"{cpu_icon} <b>CPU:</b> {cpu}% (threshold: {self.alert_cpu}%)\n"
            f"   {self._progress_bar(cpu)}\n\n"
            f"{ram_icon} <b>RAM:</b> {ram_u}/{ram_t} MB ({ram_p}%)\n"
            f"   (threshold: {self.alert_ram}%)\n"
            f"   {self._progress_bar(ram_p)}\n\n"
            f"{disk_icon} <b>Disk:</b> {dsk_u}/{dsk_t} GB ({dsk_p}%)\n"
            f"   (threshold: {self.alert_disk}%)\n"
            f"   {self._progress_bar(dsk_p)}\n\n"
            f"⏱ <b>Uptime:</b> {uptime}\n"
            f"━━━━━━━━━━━━━━━━━━━━━\n"
            f"👥 <b>Active Users:</b> {users}",
            reply_markup=json.dumps(build_back_button())
        )

    def _backup_menu(self):
        """Show backup management menu"""
        self.telegram.send(
            "<b>💾 Backup Management</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            "Select an action:",
            reply_markup=json.dumps(build_backup_menu())
        )

    def _create_backup(self):
        """Create backup now"""
        self.telegram.send("⏳ Creating backup...")
        bak = self.backup.create()
        if bak:
            self.telegram.send_file(bak, f"Marzban DB Backup • {bak.split('/')[-1]}")
        else:
            self.telegram.send("❌ Backup creation failed")

    def _list_backups(self):
        """List available backups"""
        backups = self.backup.list_backups()

        if not backups:
            self.telegram.send(
                "📭 No backups found",
                reply_markup=json.dumps(build_back_button())
            )
            return

        message = "<b>📋 Available Backups</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n\n"

        # Show last 10 backups
        for bak in backups[-10:][::-1]:
            size_mb = bak["size"] / (1024 * 1024)
            message += f"📦 <code>{bak['filename']}</code>\n"
            message += f"   Size: {size_mb:.1f} MB • Age: {bak['age_days']} days\n\n"

        self.telegram.send(message, reply_markup=json.dumps(build_back_button()))

    def _cleanup_backups(self):
        """Cleanup old backups"""
        deleted = self.backup.cleanup_old_backups()
        self.telegram.send(f"🗑️ Deleted {deleted} old backup(s)")

    def _download_backup(self, filename: str):
        """Send backup file to user"""
        backups = self.backup.list_backups()
        for bak in backups:
            if bak["filename"] == filename:
                self.telegram.send_file(bak["path"], f"Backup: {filename}")
                return
        self.telegram.send(f"❌ Backup not found: {filename}")

    def _confirm_restore(self, filename: str):
        """Confirm backup restore"""
        self.telegram.send(
            f"⚠️ <b>Confirm Restore</b>\n\n"
            f"Restore from: <code>{filename}</code>\n"
            f"This will overwrite current database!",
            reply_markup=json.dumps(build_confirm_keyboard("backup_restore", filename))
        )

    def _restore_backup(self, filename: str):
        """Restore backup"""
        backups = self.backup.list_backups()
        for bak in backups:
            if bak["filename"] == filename:
                success = self.backup.restore(bak["path"])
                if success:
                    self.telegram.send("✅ Backup restored successfully!")
                else:
                    self.telegram.send("❌ Restore failed")
                return
        self.telegram.send(f"❌ Backup not found: {filename}")

    def _confirm_delete_backup(self, filename: str):
        """Confirm backup deletion"""
        self.telegram.send(
            f"⚠️ <b>Confirm Delete</b>\n\n"
            f"Delete: <code>{filename}</code>\n"
            f"This action cannot be undone!",
            reply_markup=json.dumps(build_confirm_keyboard("backup_delete", filename))
        )

    def _users(self):
        """Send active user count"""
        users = self.metrics.get_active_users()
        self.telegram.send(
            f"👥 <b>Active Users</b>\n"
            f"━━━━━━━━━━━━━━━\n"
            f"Current active: <b>{users}</b>",
            reply_markup=json.dumps(build_main_menu())
        )

    def _restart(self):
        """Restart Marzban service"""
        self.telegram.send("🔄 Restarting Marzban...")
        try:
            result = subprocess.run(  # nosec B607, B603
                ["systemctl", "restart", "marzban"],
                capture_output=True,
                timeout=SERVICE_RESTART_TIMEOUT
            )
            if result.returncode == 0:
                self.telegram.send("✅ Marzban restarted successfully")
            else:
                stderr = result.stderr.decode()[:ERROR_MESSAGE_MAX_LENGTH] if result.stderr else "Unknown error"
                self.telegram.send(f"❌ Error:\n<code>{stderr}</code>")
        except subprocess.TimeoutExpired:
            self.telegram.send("❌ Timeout: Marzban restart took too long")
        except Exception as e:
            self.telegram.send(f"❌ Error: {str(e)}")

    def _help(self):
        """Send help message with main menu"""
        self.telegram.send(
            "<b>🤖 CubiVeil Bot — Commands</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            "<b>Main Commands:</b>\n"
            "/status  — CPU, RAM, disk, uptime\n"
            "/monitor — Detailed system monitor\n"
            "/backup  — Backup menu\n"
            "/users   — Active users count\n"
            "/restart — Restart Marzban\n"
            "/logs    — Logs menu\n"
            "/health  — Full health check\n"
            "/speedtest — Connection test\n"
            "/profiles — Profiles management\n"
            "/settings — Bot settings\n"
            "/diagnose — Full diagnostics report\n"
            "/update — Update CubiVeil\n"
            "/rollback <backup> — Roll back CubiVeil\n"
            "/export — Export configuration\n"
            "/import <path> — Import configuration\n"
            "\n"
            "<b>Direct Commands:</b>\n"            "<b>Direct Commands:</b>\n"
            "/logs &lt;service&gt; [lines] — Service logs\n"
            "/set_cpu &lt;percent&gt; — CPU threshold\n"
            "/set_ram &lt;percent&gt; — RAM threshold\n"
            "/set_disk &lt;percent&gt; — Disk threshold",
            reply_markup=json.dumps(build_main_menu())
        )

    def _health(self):
        """Send full health check report"""
        if not self.health:
            self.telegram.send("❌ Health checker not available")
            return

        self.telegram.send("⏳ Running health check...")
        try:
            message = self.health.format_health_message()
            self.telegram.send(message, reply_markup=json.dumps(build_back_button()))
        except Exception as e:
            self.telegram.send(f"❌ Health check failed: {str(e)}")

    def _speedtest(self):
        """Run connection speed test"""
        if not self.health:
            self.telegram.send("❌ Health checker not available")
            return

        self.telegram.send("⏳ Running speed test...")

        results = []
        for name, url in SPEEDTEST_TARGETS:
            result = self.health.check_connection_speed(url)
            if result["success"]:
                results.append(f"🟢 {name}: {result['latency_ms']}ms")
            else:
                results.append(f"🔴 {name}: {result.get('error', 'failed')}")

        self.telegram.send(
            "<b>📊 Speed Test Results</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n" +
            "\n".join(results),
            reply_markup=json.dumps(build_back_button())
        )

    def _profiles(self):
        """Show profiles management menu"""
        self.telegram.send(
            "<b>👤 Profiles Management</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            "Select filter:",
            reply_markup=json.dumps(build_profiles_menu())
        )

    def _show_all_profiles(self):
        """Show all profiles"""
        if not self.health:
            self.telegram.send("❌ Health checker not available")
            return

        profiles = self.health.check_all_profiles()
        self._format_profiles_message(profiles)

    def _show_profiles_by_status(self, status: str):
        """Show profiles filtered by status"""
        if not self.health:
            self.telegram.send("❌ Health checker not available")
            return

        all_profiles = self.health.check_all_profiles()
        filtered = [p for p in all_profiles if p["status"] == status]
        self._format_profiles_message(filtered, status)

    def _format_profiles_message(self, profiles: list, filter_status: str = None):
        """Format and send profiles message"""
        if not profiles:
            status_text = f" for {filter_status}" if filter_status else ""
            self.telegram.send(
                f"📭 No profiles found{status_text}",
                reply_markup=json.dumps(build_back_button())
            )
            return

        # Group by status
        by_status = {}
        for p in profiles:
            status = p["status"]
            if status not in by_status:
                by_status[status] = []
            by_status[status].append(p)

        message = "<b>👥 Profiles</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n\n"

        for status in PROFILE_STATUS_ICONS.keys():
            if status in by_status:
                icon = PROFILE_STATUS_ICONS.get(status, "⚪")
                count = len(by_status[status])
                message += f"{icon} <b>{status.title()}</b>: {count}\n"

                # Show first N profiles
                for p in by_status[status][:PROFILE_DISPLAY_LIMIT]:
                    username = p["username"]
                    used = p.get("used_traffic", 0) / (1024 * 1024 * 1024)  # GB
                    message += f"   ├─ <code>{username}</code> ({used:.1f} GB)\n"

                if len(by_status[status]) > PROFILE_DISPLAY_LIMIT:
                    more = len(by_status[status]) - PROFILE_DISPLAY_LIMIT
                    message += f"   └─ ... and {more} more\n"
                message += "\n"

        self.telegram.send(message, reply_markup=json.dumps(build_profiles_menu()))

    def _show_profile_info(self, username: str):
        """Show detailed profile info"""
        if not self.health:
            self.telegram.send("❌ Health checker not available")
            return

        profile = self.health.check_profile_status(username)

        if profile.get("error"):
            self.telegram.send(f"❌ {profile['error']}")
            return

        used_gb = profile.get("used_traffic", 0) / (1024 * 1024 * 1024)
        limit_gb = profile.get("data_limit", 0) / (1024 * 1024 * 1024)

        message = f"<b>👤 Profile: {username}</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n"
        message += f"Status: {PROFILE_STATUS_ICONS.get(profile['status'], '⚪')} {profile['status']}\n"
        message += f"Used: {used_gb:.2f} GB"
        if limit_gb > 0:
            message += f" / {limit_gb:.2f} GB\n"
            pct = (used_gb / limit_gb) * 100
            message += f"   {self._progress_bar(pct)}\n"
        message += "\n"

        if profile.get("expiry"):
            from datetime import datetime
            try:
                expiry = datetime.fromtimestamp(profile["expiry"])
                message += f"Expires: {expiry.strftime('%Y-%m-%d %H:%M')}\n"
            except (ValueError, TypeError):
                message += "Expires: N/A\n"

        self.telegram.send(
            message,
            reply_markup=json.dumps(build_profile_actions_keyboard(username))
        )

    def _confirm_disable_profile(self, username: str):
        """Confirm profile disable"""
        self.telegram.send(
            f"⚠️ <b>Confirm Disable</b>\n\n"
            f"Disable profile: <code>{username}</code>\n"
            f"User will lose access!",
            reply_markup=json.dumps(build_confirm_keyboard("profile_disable", username))
        )

    def _enable_profile(self, username: str):
        """Enable profile"""
        # TODO: Implement enable via Marzban API
        self.telegram.send(f"⚠️ Enable: Use Marzban panel or /enable {username} command")

    def _show_qr(self, username: str):
        """Show QR code for profile"""
        # TODO: Generate QR code
        self.telegram.send(f"⚠️ QR Code: Use /qr {username} command")

    # ═══════════════════════════════════════════════════════════════════════════
    # Logs Commands / Команды логов
    # ═══════════════════════════════════════════════════════════════════════════

    def _logs_menu(self):
        """Show logs selection menu"""
        self.telegram.send(
            "<b>📋 Logs Menu</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            "Select a service:",
            reply_markup=json.dumps(build_logs_menu())
        )

    def _show_logs(self, service: str, lines: int):
        """Show logs for a service"""
        if not self.logs:
            self.telegram.send("❌ Logs manager not available")
            return

        success, logs = self.logs.get_service_logs(service, lines)

        if success:
            # Add lines selection keyboard
            keyboard = build_logs_lines_keyboard(service, lines)
            self.telegram.send(logs, reply_markup=json.dumps(keyboard))
        else:
            self.telegram.send(logs, reply_markup=json.dumps(build_logs_menu()))

    def _settings_menu(self):
        """Show settings menu"""
        message = "<b>⚙️ Bot Settings</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n\n"
        message += f"🔹 CPU Threshold: {self.alert_cpu}%\n"
        message += f"🔸 RAM Threshold: {self.alert_ram}%\n"
        message += f"💿 Disk Threshold: {self.alert_disk}%\n\n"
        message += "Use commands to change:\n"
        message += "<code>/set_cpu &lt;percent&gt;</code>\n"
        message += "<code>/set_ram &lt;percent&gt;</code>\n"
        message += "<code>/set_disk &lt;percent&gt;</code>"

        self.telegram.send(
            message,
            reply_markup=json.dumps(build_settings_menu())
        )

    def _show_alerts_settings(self):
        """Show alerts settings"""
        message = "<b>🔔 Alert Thresholds</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n\n"
        message += f"🔹 CPU: {self.alert_cpu}%\n"
        message += f"🔸 RAM: {self.alert_ram}%\n"
        message += f"💿 Disk: {self.alert_disk}%\n\n"
        message += "Use commands to change:\n"
        message += "<code>/set_cpu &lt;percent&gt;</code>\n"
        message += "<code>/set_ram &lt;percent&gt;</code>\n"
        message += "<code>/set_disk &lt;percent&gt;</code>"

        self.telegram.send(
            message,
            reply_markup=json.dumps(build_alerts_submenu())
        )

    # ═══════════════════════════════════════════════════════════════════════════
    # New Commands / Новые команды
    # ═══════════════════════════════════════════════════════════════════════════

    def _logs_command(self, command: str):
        """
        Handle /logs command with optional arguments
        Usage: /logs [service] [lines]
        """
        args = command.split()[1:]  # Skip command

        if len(args) >= 1:
            service = args[0].lower()
            lines = int(args[1]) if len(args) >= 2 else 50

            # Map service names
            service_map = {
                "marzban": "marzban",
                "singbox": "sing-box",
                "sing-box": "sing-box",
                "bot": "cubiveil-bot",
                "cubiveil-bot": "cubiveil-bot",
                "nginx": "nginx",
                "systemd": "systemd",
                "system": "systemd",
            }

            if service in service_map:
                self._show_logs(service_map[service], min(lines, 200))
            else:
                self.telegram.send(
                    f"❓ Unknown service: {service}\n"
                    f"Available: marzban, sing-box, bot, nginx, systemd",
                    reply_markup=json.dumps(build_logs_menu())
                )
        else:
            # No arguments — show menu
            self._logs_menu()

    def _restore_command(self, command: str):
        """
        Handle /restore command
        Usage: /restore <filename>
        """
        args = command.split()[1:]  # Skip command

        if len(args) < 1:
            self.telegram.send(
                "⚠️ Usage: <code>/restore &lt;filename&gt;</code>\n\n"
                "Example: <code>/restore marzban_20250101_1200.sqlite3</code>"
            )
            return

        filename = args[0]
        backups = self.backup.list_backups()

        # Find backup by filename
        for bak in backups:
            if bak["filename"] == filename:
                self.telegram.send(
                    f"⚠️ <b>Confirm Restore</b>\n\n"
                    f"Restore from: <code>{filename}</code>\n"
                    f"Size: {bak['size'] / (1024*1024):.1f} MB\n"
                    f"This will overwrite current database!",
                    reply_markup=json.dumps(build_confirm_keyboard("backup_restore", filename))
                )
                return

        self.telegram.send(f"❌ Backup not found: <code>{filename}</code>\nUse /backups to list available backups")

    def _restore_backup(self, filename: str):
        """Restore backup (called from callback)"""
        backups = self.backup.list_backups()
        for bak in backups:
            if bak["filename"] == filename:
                self.telegram.send_chat_action("typing")
                success = self.backup.restore(bak["path"])
                if success:
                    self.telegram.send("✅ Backup restored successfully!\nMarzban will be restarted automatically.")
                    # Restart marzban after restore
                    try:
                        subprocess.run(["systemctl", "restart", "marzban"], timeout=30)  # nosec B607, B603
                    except Exception as e:  # nosec B110
                        logger.warning(f"Failed to restart marzban after restore: {e}")
                else:
                    self.telegram.send("❌ Restore failed")
                return
        self.telegram.send(f"❌ Backup not found: {filename}")

    def _backup_delete_command(self, command: str):
        """
        Handle /backup_delete command
        Usage: /backup_delete <filename>
        """
        args = command.split()[1:]  # Skip command

        if len(args) < 1:
            self.telegram.send(
                "⚠️ Usage: <code>/backup_delete &lt;filename&gt;</code>\n\n"
                "Example: <code>/backup_delete marzban_20250101_1200.sqlite3</code>"
            )
            return

        filename = args[0]
        backups = self.backup.list_backups()

        # Find backup by filename
        for bak in backups:
            if bak["filename"] == filename:
                self.telegram.send(
                    f"⚠️ <b>Confirm Delete</b>\n\n"
                    f"Delete: <code>{filename}</code>\n"
                    f"Size: {bak['size'] / (1024*1024):.1f} MB\n"
                    f"This action cannot be undone!",
                    reply_markup=json.dumps(build_confirm_keyboard("backup_delete", filename))
                )
                return

        self.telegram.send(f"❌ Backup not found: <code>{filename}</code>")

    def _set_cpu(self, command: str):
        """
        Handle /set_cpu command
        Usage: /set_cpu <percent>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send(f"⚠️ Current CPU threshold: {self.alert_cpu}%\nUsage: <code>/set_cpu &lt;percent&gt;</code>")
            return

        try:
            new_value = int(args[0])
            if new_value < 0 or new_value > 100:
                self.telegram.send("⚠️ Value must be between 0 and 100")
                return

            self.alert_cpu = new_value
            self.telegram.send(f"✅ CPU threshold set to {new_value}%")
        except ValueError:
            self.telegram.send("⚠️ Invalid value. Use a number between 0 and 100")

    def _set_ram(self, command: str):
        """
        Handle /set_ram command
        Usage: /set_ram <percent>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send(f"⚠️ Current RAM threshold: {self.alert_ram}%\nUsage: <code>/set_ram &lt;percent&gt;</code>")
            return

        try:
            new_value = int(args[0])
            if new_value < 0 or new_value > 100:
                self.telegram.send("⚠️ Value must be between 0 and 100")
                return

            self.alert_ram = new_value
            self.telegram.send(f"✅ RAM threshold set to {new_value}%")
        except ValueError:
            self.telegram.send("⚠️ Invalid value. Use a number between 0 and 100")

    def _set_disk(self, command: str):
        """
        Handle /set_disk command
        Usage: /set_disk <percent>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send(f"⚠️ Current Disk threshold: {self.alert_disk}%\nUsage: <code>/set_disk &lt;percent&gt;</code>")
            return

        try:
            new_value = int(args[0])
            if new_value < 0 or new_value > 100:
                self.telegram.send("⚠️ Value must be between 0 and 100")
                return

            self.alert_disk = new_value
            self.telegram.send(f"✅ Disk threshold set to {new_value}%")
        except ValueError:
            self.telegram.send("⚠️ Invalid value. Use a number between 0 and 100")

    # ═══════════════════════════════════════════════════════════════════════════
    # Profile Commands / Команды профилей
    # ═══════════════════════════════════════════════════════════════════════════

    def _enable_command(self, command: str):
        """
        Handle /enable command
        Usage: /enable <username>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send("⚠️ Usage: <code>/enable &lt;username&gt;</code>")
            return

        username = args[0]
        success = self.marzban.enable_user(username)

        if success:
            self.telegram.send(f"✅ Profile <code>{username}</code> enabled")
        else:
            self.telegram.send(f"❌ Failed to enable profile <code>{username}</code>\nCheck username and try again")

    def _disable_command(self, command: str):
        """
        Handle /disable command
        Usage: /disable <username>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send("⚠️ Usage: <code>/disable &lt;username&gt;</code>")
            return

        username = args[0]
        success = self.marzban.disable_user(username)

        if success:
            self.telegram.send(f"✅ Profile <code>{username}</code> disabled")
        else:
            self.telegram.send(f"❌ Failed to disable profile <code>{username}</code>\nCheck username and try again")

    def _extend_command(self, command: str):
        """
        Handle /extend command
        Usage: /extend <username> <days>
        """
        args = command.split()[1:]

        if len(args) < 2:
            self.telegram.send("⚠️ Usage: <code>/extend &lt;username&gt; &lt;days&gt;</code>\nExample: <code>/extend user123 30</code>")
            return

        username = args[0]
        try:
            days = int(args[1])
            if days <= 0:
                self.telegram.send("⚠️ Days must be positive")
                return

            result = self.marzban.extend_user(username, days)

            if result:
                new_expiry = result.get("expire")
                if new_expiry:
                    expiry_date = datetime.fromtimestamp(new_expiry).strftime("%Y-%m-%d")
                    self.telegram.send(f"✅ Profile <code>{username}</code> extended by {days} days\nNew expiry: {expiry_date}")
                else:
                    self.telegram.send(f"✅ Profile <code>{username}</code> extended by {days} days")
            else:
                self.telegram.send(f"❌ Failed to extend profile <code>{username}</code>\nCheck username and try again")
        except ValueError:
            self.telegram.send("⚠️ Invalid days value. Use a number")
        except Exception as e:
            self.telegram.send(f"❌ Error: {str(e)}")

    def _reset_command(self, command: str):
        """
        Handle /reset command
        Usage: /reset <username>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send("⚠️ Usage: <code>/reset &lt;username&gt;</code>")
            return

        username = args[0]
        success = self.marzban.reset_user_traffic(username)

        if success:
            self.telegram.send(f"✅ Traffic reset for <code>{username}</code>")
        else:
            self.telegram.send(f"❌ Failed to reset traffic for <code>{username}</code>\nCheck username and try again")

    def _qr_command(self, command: str):
        """
        Handle /qr command
        Usage: /qr <username>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send("⚠️ Usage: <code>/qr &lt;username&gt;</code>")
            return

        username = args[0]
        sub_link = self.marzban.get_subscription_link(username)

        if not sub_link:
            self.telegram.send(f"❌ Profile <code>{username}</code> not found")
            return

        qr_url = self.marzban.generate_qr_code_url(sub_link)

        # Download and send QR code
        try:
            import urllib.request
            temp_file = f"/tmp/qr_{username}.png"
            urllib.request.urlretrieve(qr_url, temp_file)  # nosec B310
            self.telegram.send_file(temp_file, f"QR Code for {username}")
            import os
            os.remove(temp_file)
        except Exception as e:
            self.telegram.send(f"❌ Error generating QR: {str(e)}\n\nSubscription link:\n<code>{sub_link}</code>")

    def _traffic_command(self, command: str):
        """
        Handle /traffic command
        Usage: /traffic <username>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send("⚠️ Usage: <code>/traffic &lt;username&gt;</code>")
            return

        username = args[0]
        traffic = self.marzban.get_user_traffic(username)

        if not traffic:
            self.telegram.send(f"❌ Profile <code>{username}</code> not found")
            return

        message = f"<b>📊 Traffic for {username}</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n"

        used_gb = traffic["used_gb"]
        limit_gb = traffic["limit_gb"]
        remaining_gb = traffic["remaining_gb"]
        pct = traffic["percentage"]

        message += f"Used: {used_gb:.2f} GB\n"

        if limit_gb:
            message += f"Limit: {limit_gb:.2f} GB\n"
            message += f"Remaining: {remaining_gb:.2f} GB\n"
            message += f"{self._progress_bar(pct)} {pct:.1f}%\n"
        else:
            message += "Limit: ∞ (unlimited)\n"

        self.telegram.send(message)

    def _subscription_command(self, command: str):
        """
        Handle /subscription command
        Usage: /subscription <username>
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send("⚠️ Usage: <code>/subscription &lt;username&gt;</code>")
            return

        username = args[0]
        sub_link = self.marzban.get_subscription_link(username)

        if not sub_link:
            self.telegram.send(f"❌ Profile <code>{username}</code> not found")
            return

        message = f"<b>🔗 Subscription for {username}</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n"
        message += f"<code>{sub_link}</code>\n\n"
        message += "Click to copy or scan QR with /qr"

        self.telegram.send(message)

    def _create_command(self, command: str):
        """
        Handle /create command
        Usage: /create <username> [days] [limit_gb]
        """
        args = command.split()[1:]

        if len(args) < 1:
            self.telegram.send(
                "⚠️ Usage: <code>/create &lt;username&gt; [days] [limit_gb]</code>\n"
                "Example: <code>/create user123 30 50</code>\n"
                "Defaults: 30 days, unlimited data"
            )
            return

        username = args[0]
        days = int(args[1]) if len(args) >= 2 else 30
        limit_gb = float(args[2]) if len(args) >= 3 else 0.0

        # Validate username
        if not username.isalnum() or len(username) < 3:
            self.telegram.send("⚠️ Username must be at least 3 characters and alphanumeric")
            return

        result = self.marzban.create_user(username, days, limit_gb)

        if result:
            message = f"✅ Profile created: <code>{username}</code>\n"
            message += "━━━━━━━━━━━━━━━━━━━━━\n"
            message += f"Days: {days}\n"
            if limit_gb > 0:
                message += f"Data limit: {limit_gb} GB\n"
            else:
                message += "Data limit: ∞ (unlimited)\n"
            message += "\nUse /qr or /subscription to get connection details"
            self.telegram.send(message)
        else:
            self.telegram.send(f"❌ Failed to create profile <code>{username}</code>\nUsername may already exist")

    # ═══════════════════════════════════════════════════════════════════════════
    # Decoy Site Handlers / Обработка Decoy Site
    # ═══════════════════════════════════════════════════════════════════════════

    def _decoy_menu(self, chat_id, message_id=None):
        """Show Decoy Site main menu"""
        if not self.decoy.is_configured():
            self.telegram.send(
                chat_id,
                "❌ Decoy Site not configured\n"
                "Run: install.sh --decoy",
                reply_markup=build_back_button()
            )
            return

        self.telegram.send(
            chat_id,
            "🎭 <b>Decoy Site Management</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            "Manage rotation and files",
            reply_markup=build_decoy_menu()
        )

    def _decoy_status(self, chat_id, message_id=None):
        """Show Decoy Site status"""
        status = self.decoy.get_status()

        if not status["configured"]:
            self.telegram.send(
                chat_id,
                "❌ Decoy Site not configured\n"
                "Run: install.sh --decoy"
            )
            return

        message = "🎭 <b>Decoy Site Status</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n"
        message += f"Rotation: {'✅ Enabled' if status['enabled'] else '❌ Disabled'}\n"
        message += f"Timer: {'🟢 Active' if status['timer_active'] else '🔴 Inactive'}\n"
        message += f"Interval: {status['interval_hours']} hours\n"
        message += f"Files: {status['file_count']} ({status['total_size_mb']} MB)\n"
        message += f"Limit: {status['max_size_mb']} MB\n"

        if status["last_rotation"]:
            message += f"Last rotation: {status['last_rotation']}\n"

        if status["files_by_type"]:
            message += "\n📁 By type:\n"
            for ftype, count in status["files_by_type"].items():
                message += f"  {ftype.upper()}: {count}\n"

        self.telegram.send(chat_id, message, reply_markup=build_decoy_menu())

    def _decoy_rotate(self, chat_id, message_id=None):
        """Trigger immediate rotation"""
        self.telegram.answer_callback(chat_id, "🔄 Starting rotation...")

        success, message = self.decoy.rotate_now()

        if success:
            self.telegram.send(chat_id, f"✅ {message}\n\nUse /decoy_status to see results")
        else:
            self.telegram.send(chat_id, f"❌ {message}")

    def _decoy_files(self, chat_id, message_id=None):
        """Show list of decoy files"""
        files = self.decoy.get_files_list(limit=20)

        if not files:
            self.telegram.send(
                chat_id,
                "📁 No files found\n"
                "Run rotation or regenerate files",
                reply_markup=build_decoy_menu()
            )
            return

        message = "📁 <b>Decoy Files</b>\n"
        message += "━━━━━━━━━━━━━━━━━━━━━\n"

        for f in files[:15]:
            message += f"{f['type_display']} {f['name']}\n"
            message += f"   Size: {f['size_mb']} MB | Modified: {f['modified'][:10]}\n"

        if len(files) > 15:
            message += f"\n... and {len(files) - 15} more files"

        self.telegram.send(chat_id, message, reply_markup=build_decoy_menu())

    def _decoy_config(self, chat_id, message_id=None):
        """Show decoy configuration"""
        config = self.decoy._load_config()

        if not config:
            self.telegram.send(chat_id, "❌ Failed to load configuration")
            return

        # Format config as code block
        config_text = json.dumps(config, indent=2)

        # Truncate if too long
        if len(config_text) > 4000:
            config_text = config_text[:4000] + "\n... (truncated)"

        message = f"⚙️ <b>Decoy Configuration</b>\n\n"
        message += f"<pre>{config_text}</pre>"

        self.telegram.send(chat_id, message, reply_markup=build_decoy_menu())

    def _decoy_settings_menu(self, chat_id, message_id=None):
        """Show Decoy Settings menu"""
        self.telegram.send(
            chat_id,
            "⚙️ <b>Decoy Settings</b>\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            "Configure rotation parameters",
            reply_markup=build_decoy_settings_menu()
        )
