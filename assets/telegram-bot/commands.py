#!/usr/bin/env python3
"""
Command Handler Module
Handles Telegram bot commands
"""

import subprocess


class CommandHandler:
    """Handles bot commands"""

    def __init__(self, telegram, metrics, backup, alert_state, alert_cpu, alert_ram, alert_disk, health_checker=None):
        self.telegram = telegram
        self.metrics = metrics
        self.backup = backup
        self.alert_state = alert_state
        self.alert_cpu = alert_cpu
        self.alert_ram = alert_ram
        self.alert_disk = alert_disk
        self.health = health_checker

    def _progress_bar(self, pct, width=10):
        """Generate progress bar"""
        filled = int(min(pct, 100) / 100 * width)
        return "█" * filled + "░" * (width - filled)

    def handle(self, command):
        """Handle incoming command"""
        cmd = command.strip().split()[0].lower()

        if cmd in ("/start", "/status"):
            self._status()
        elif cmd == "/backup":
            self._backup()
        elif cmd == "/users":
            self._users()
        elif cmd == "/restart":
            self._restart()
        elif cmd == "/health":
            self._health()
        elif cmd == "/speedtest":
            self._speedtest()
        elif cmd == "/profiles":
            self._profiles()
        elif cmd == "/help":
            self._help()
        else:
            self.telegram.send("Unknown command. /help — command list")

    def _status(self):
        """Send server status"""
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
            f"👥 Active: {users}"
        )

    def _backup(self):
        """Create and send backup"""
        self.telegram.send("⏳ Creating backup...")
        bak = self.backup.create()
        if bak:
            self.telegram.send_file(bak, "Marzban DB Backup")
        else:
            self.telegram.send("❌ Backup creation failed")

    def _users(self):
        """Send active user count"""
        self.telegram.send(f"👥 Active users: <b>{self.metrics.get_active_users()}</b>")

    def _restart(self):
        """Restart Marzban service"""
        self.telegram.send("🔄 Restarting Marzban...")
        try:
            result = subprocess.run(
                ["systemctl", "restart", "marzban"],
                capture_output=True,
                timeout=30
            )
            if result.returncode == 0:
                self.telegram.send("✅ Marzban restarted")
            else:
                stderr = result.stderr.decode()[:500] if result.stderr else "Unknown error"
                self.telegram.send(f"❌ Error:\n<code>{stderr}</code>")
        except subprocess.TimeoutExpired:
            self.telegram.send("❌ Timeout: Marzban restart took too long")
        except Exception as e:
            self.telegram.send(f"❌ Error: {str(e)}")

    def _help(self):
        """Send help message"""
        self.telegram.send(
            "<b>CubiVeil Bot — Commands</b>\n"
            "━━━━━━━━━━━━━━━\n"
            "/status  — CPU, RAM, disk, uptime\n"
            "/backup  — get backup right now\n"
            "/users   — active users\n"
            "/restart — restart Marzban\n"
            "/health  — full health check report\n"
            "/speedtest — connection speed test\n"
            "/profiles — profile status summary\n"
            "/help    — this help"
        )

    def _health(self):
        """Send full health check report"""
        if not self.health:
            self.telegram.send("❌ Health checker not available")
            return

        self.telegram.send("⏳ Running health check...")
        try:
            message = self.health.format_health_message()
            self.telegram.send(message)
        except Exception as e:
            self.telegram.send(f"❌ Health check failed: {str(e)}")

    def _speedtest(self):
        """Run connection speed test"""
        if not self.health:
            self.telegram.send("❌ Health checker not available")
            return

        self.telegram.send("⏳ Running speed test...")

        targets = [
            ("Google", "https://www.google.com"),
            ("Cloudflare", "https://www.cloudflare.com"),
            ("GitHub", "https://www.github.com"),
            ("Telegram", "https://api.telegram.org")
        ]

        results = []
        for name, url in targets:
            result = self.health.check_connection_speed(url)
            if result["success"]:
                results.append(f"🟢 {name}: {result['latency_ms']}ms")
            else:
                results.append(f"🔴 {name}: {result.get('error', 'failed')}")

        self.telegram.send(
            "<b>📊 Speed Test Results</b>\n"
            "━━━━━━━━━━━━━━━\n" +
            "\n".join(results)
        )

    def _profiles(self):
        """Send profiles status summary"""
        if not self.health:
            self.telegram.send("❌ Health checker not available")
            return

        profiles = self.health.check_all_profiles()

        if not profiles:
            self.telegram.send("ℹ️ No profiles found")
            return

        # Group by status
        by_status = {}
        for p in profiles:
            status = p["status"]
            if status not in by_status:
                by_status[status] = []
            by_status[status].append(p["username"])

        message = "<b>👥 Profiles Status</b>\n"

        for status in ["active", "disabled", "limited", "expired"]:
            if status in by_status:
                icon = {"active": "🟢", "disabled": "🔴", "limited": "🟡", "expired": "⚫"}.get(status, "⚪")
                usernames = ", ".join(by_status[status][:10])  # Limit to 10
                more = f" +{len(by_status[status]) - 10}" if len(by_status[status]) > 10 else ""
                message += f"\n{icon} <b>{status.title()}</b> ({len(by_status[status])}): {usernames}{more}"

        self.telegram.send(message)
