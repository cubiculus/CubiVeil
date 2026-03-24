#!/usr/bin/env python3
"""
Health Check Module
- Connection speed tests
- Profile status checks
- Service health monitoring
- Automatic service restart
- Alert notifications
"""

import subprocess
import time
import json
import os
from datetime import datetime
from typing import Optional


class HealthChecker:
    """Health check functionality for CubiVeil"""

    def __init__(self, health_check_port: Optional[int] = None):
        self.health_check_port = health_check_port or self._get_health_check_port()
        self.marzban_dir = "/opt/marzban"
        self.last_restart_time: dict = {}
        self.restart_cooldown = 300  # 5 minutes between auto-restarts

    def _get_health_check_port(self) -> int:
        """Get health check port from Marzban config"""
        try:
            env_file = os.path.join(self.marzban_dir, ".env")
            if os.path.exists(env_file):
                with open(env_file) as f:
                    for line in f:
                        if line.startswith("HEALTH_CHECK_PORT="):
                            return int(line.split("=")[1].strip())
        except Exception:
            pass
        return 8080  # Default fallback

    def check_connection_speed(self, target: str = "https://www.google.com",
                                timeout: int = 10) -> dict:
        """
        Check connection speed to a target URL
        Returns dict with latency_ms, success, error
        """
        result = {
            "target": target,
            "success": False,
            "latency_ms": None,
            "error": None
        }

        try:
            start = time.time()
            subprocess.run(
                ["curl", "-sf", "--max-time", str(timeout), "-o", "/dev/null", target],
                capture_output=True,
                timeout=timeout + 5
            )
            elapsed = time.time() - start
            result["success"] = True
            result["latency_ms"] = round(elapsed * 1000, 2)
        except subprocess.TimeoutExpired:
            result["error"] = f"Timeout after {timeout}s"
        except Exception as e:
            result["error"] = str(e)

        return result

    def check_profile_status(self, username: str) -> dict:
        """
        Check status of a specific profile
        Returns dict with status, traffic used, expiry
        """
        result = {
            "username": username,
            "status": "unknown",
            "used_traffic": 0,
            "data_limit": 0,
            "expiry": None,
            "error": None
        }

        try:
            # Read Marzban database
            db_path = os.path.join(self.marzban_dir, "db.sqlite3")
            if not os.path.exists(db_path):
                result["error"] = "Database not found"
                return result

            import sqlite3
            conn = sqlite3.connect(db_path, timeout=5)
            cur = conn.cursor()

            cur.execute("""
                SELECT status, used_traffic, data_limit, expire
                FROM users
                WHERE username = ?
            """, (username,))

            row = cur.fetchone()
            conn.close()

            if row:
                result["status"] = row[0] or "unknown"
                result["used_traffic"] = row[1] or 0
                result["data_limit"] = row[2] or 0
                result["expiry"] = row[3]
            else:
                result["error"] = "User not found"

        except Exception as e:
            result["error"] = str(e)

        return result

    def check_all_profiles(self) -> list:
        """
        Check status of all profiles
        Returns list of profile statuses
        """
        profiles = []

        try:
            db_path = os.path.join(self.marzban_dir, "db.sqlite3")
            if not os.path.exists(db_path):
                return profiles

            import sqlite3
            conn = sqlite3.connect(db_path, timeout=5)
            cur = conn.cursor()

            cur.execute("""
                SELECT username, status, used_traffic, data_limit, expire
                FROM users
                ORDER BY username
            """)

            for row in cur.fetchall():
                profiles.append({
                    "username": row[0],
                    "status": row[1] or "unknown",
                    "used_traffic": row[2] or 0,
                    "data_limit": row[3] or 0,
                    "expiry": row[4]
                })

            conn.close()

        except Exception as e:
            print(f"[health] Error checking profiles: {e}")

        return profiles

    def check_service_health(self, service_name: str) -> dict:
        """
        Check health of a systemd service
        Returns dict with active, running, error
        """
        result = {
            "service": service_name,
            "active": False,
            "running": False,
            "error": None
        }

        try:
            # Check if service is active
            active_result = subprocess.run(
                ["systemctl", "is-active", service_name],
                capture_output=True,
                text=True,
                timeout=10
            )
            result["active"] = active_result.returncode == 0

            # Check if service is running
            running_result = subprocess.run(
                ["systemctl", "is-running", service_name],
                capture_output=True,
                text=True,
                timeout=10
            )
            result["running"] = running_result.returncode == 0

        except subprocess.TimeoutExpired:
            result["error"] = "Timeout checking service"
        except Exception as e:
            result["error"] = str(e)

        return result

    def check_health_endpoint(self) -> dict:
        """
        Check the health check endpoint
        Returns dict with status, services
        """
        result = {
            "status": "unknown",
            "marzban": "unknown",
            "singbox": "unknown",
            "error": None
        }

        try:
            response = subprocess.run(
                ["curl", "-sf", "--max-time", "10",
                 f"http://localhost:{self.health_check_port}/health"],
                capture_output=True,
                text=True,
                timeout=15
            )

            if response.returncode == 0:
                data = json.loads(response.stdout)
                result["status"] = data.get("status", "unknown")
                result["marzban"] = data.get("marzban", "unknown")
                result["singbox"] = data.get("singbox", "unknown")
            else:
                result["status"] = "unreachable"
                result["error"] = "Health endpoint not responding"

        except subprocess.TimeoutExpired:
            result["error"] = "Timeout connecting to health endpoint"
        except json.JSONDecodeError:
            result["error"] = "Invalid JSON from health endpoint"
        except Exception as e:
            result["error"] = str(e)

        return result

    def restart_service(self, service_name: str, force: bool = False) -> bool:
        """
        Restart a systemd service with cooldown protection
        Returns True if restart was successful
        """
        # Check cooldown
        now = time.time()
        last_restart = self.last_restart_time.get(service_name, 0)

        if not force and (now - last_restart) < self.restart_cooldown:
            remaining = int(self.restart_cooldown - (now - last_restart))
            print(f"[health] Restart cooldown active for {service_name}. "
                  f"Wait {remaining}s")
            return False

        try:
            print(f"[health] Restarting {service_name}...")
            subprocess.run(
                ["systemctl", "restart", service_name],
                capture_output=True,
                timeout=60
            )

            # Wait for service to start
            time.sleep(3)

            # Verify restart
            status = subprocess.run(
                ["systemctl", "is-active", service_name],
                capture_output=True,
                text=True,
                timeout=10
            )

            if status.returncode == 0:
                self.last_restart_time[service_name] = now
                print(f"[health] {service_name} restarted successfully")
                return True
            else:
                print(f"[health] {service_name} failed to restart")
                return False

        except Exception as e:
            print(f"[health] Error restarting {service_name}: {e}")
            return False

    def auto_heal(self) -> list:
        """
        Check all services and auto-restart failed ones
        Returns list of actions taken
        """
        actions = []
        services = ["marzban", "sing-box"]

        for service in services:
            health = self.check_service_health(service)

            if not health["active"]:
                print(f"[health] {service} is not active, attempting restart...")

                if self.restart_service(service):
                    actions.append({
                        "service": service,
                        "action": "restarted",
                        "timestamp": datetime.now().isoformat()
                    })
                else:
                    actions.append({
                        "service": service,
                        "action": "restart_failed",
                        "timestamp": datetime.now().isoformat()
                    })

        return actions

    def get_full_health_report(self) -> dict:
        """
        Get comprehensive health report
        Returns dict with all health metrics
        """
        report = {
            "timestamp": datetime.now().isoformat(),
            "health_endpoint": self.check_health_endpoint(),
            "services": {},
            "profiles_summary": {},
            "connection": {}
        }

        # Check services
        for service in ["marzban", "sing-box", "cubiveil-bot"]:
            report["services"][service] = self.check_service_health(service)

        # Profile summary
        profiles = self.check_all_profiles()
        report["profiles_summary"] = {
            "total": len(profiles),
            "active": sum(1 for p in profiles if p["status"] == "active"),
            "disabled": sum(1 for p in profiles if p["status"] == "disabled"),
            "limited": sum(1 for p in profiles if p["status"] == "limited"),
            "expired": sum(1 for p in profiles if p["status"] == "expired")
        }

        # Connection tests
        for target in [
            ("Google", "https://www.google.com"),
            ("Cloudflare", "https://www.cloudflare.com"),
            ("GitHub", "https://www.github.com")
        ]:
            name, url = target
            result = self.check_connection_speed(url)
            report["connection"][name] = result

        return report

    def format_health_message(self) -> str:
        """
        Format health report as HTML message for Telegram
        Returns formatted string
        """
        report = self.get_full_health_report()

        # Status icons
        def icon(healthy: bool) -> str:
            return "🟢" if healthy else "🔴"

        # Build message
        lines = ["<b>🏥 Health Check Report</b>", ""]

        # Health endpoint
        he = report["health_endpoint"]
        lines.append(f"Health Endpoint: {icon(he['status'] == 'healthy')} {he['status']}")
        if he.get("error"):
            lines.append(f"  └─ Error: {he['error']}")
        lines.append("")

        # Services
        lines.append("Services:")
        for service, health in report["services"].items():
            status_icon = icon(health["active"])
            lines.append(f"  {status_icon} {service}: {'running' if health['active'] else 'stopped'}")
        lines.append("")

        # Profiles
        ps = report["profiles_summary"]
        lines.append(f"Profiles: {ps['total']} total")
        lines.append(f"  🟢 Active: {ps['active']}")
        if ps["disabled"]:
            lines.append(f"  🔴 Disabled: {ps['disabled']}")
        if ps["limited"]:
            lines.append(f"  🟡 Limited: {ps['limited']}")
        if ps["expired"]:
            lines.append(f"  ⚫ Expired: {ps['expired']}")
        lines.append("")

        # Connection
        lines.append("Connection:")
        for name, result in report["connection"].items():
            if result["success"]:
                lines.append(f"  🟢 {name}: {result['latency_ms']}ms")
            else:
                lines.append(f"  🔴 {name}: {result.get('error', 'failed')}")

        return "\n".join(lines)
