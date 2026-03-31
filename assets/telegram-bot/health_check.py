#!/usr/bin/env python3
"""
Health Check Module
- Connection speed tests
- Profile status checks
- Service health monitoring
- Automatic service restart
- Alert notifications
"""

import subprocess  # nosec B404
import time
import json
import os
import logging
from datetime import datetime
from typing import Optional, Dict, List, Any

from constants import (
    SUI_DIR,
    SUI_ENV_FILE,
    SUI_DB_FILE,
    DEFAULT_HEALTH_CHECK_PORT,
    RESTART_COOLDOWN,
    CONNECTION_TIMEOUT,
    SERVICE_CHECK_TIMEOUT,
    SERVICE_RESTART_TIMEOUT,
    HEALTH_ENDPOINT_TIMEOUT,
    DB_TIMEOUT,
    DEFAULT_CONNECTION_TARGETS,
    MONITORED_SERVICES,
    PROFILE_STATUSES,
    PROFILE_DISPLAY_LIMIT,
)

logger = logging.getLogger(__name__)


class HealthCheckError(Exception):
    """Custom exception for health check errors"""
    pass


class HealthChecker:
    """Health check functionality for CubiVeil"""

    def __init__(self, health_check_port: Optional[int] = None):
        self.health_check_port = health_check_port or self._get_health_check_port()
        self.sui_dir = SUI_DIR
        self.last_restart_time: dict = {}
        self.restart_cooldown = RESTART_COOLDOWN

    def _get_health_check_port(self) -> int:
        """Get health check port from S-UI config"""
        try:
            if os.path.exists(SUI_ENV_FILE):
                with open(SUI_ENV_FILE) as f:
                    for line in f:
                        if line.startswith("SUI_PANEL_PORT="):
                            return int(line.split("=")[1].strip())
        except Exception:  # nosec B110
            logger.debug("Failed to get health check port, using default")
        return DEFAULT_HEALTH_CHECK_PORT  # Default fallback

    def check_connection_speed(self, target: str = "https://www.google.com",
                                timeout: int = CONNECTION_TIMEOUT) -> dict:
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
            subprocess.run(  # nosec B607, B603
                ["curl", "-sf", "--max-time", str(timeout), "-o", "/dev/null", target],
                capture_output=True,
                timeout=timeout + 5,
                check=True
            )
            elapsed = time.time() - start
            result["success"] = True
            result["latency_ms"] = round(elapsed * 1000, 2)
        except subprocess.TimeoutExpired as e:
            logger.warning(f"Connection timeout to {target}: {e}")
            result["error"] = f"Timeout after {timeout}s"
        except subprocess.CalledProcessError as e:
            logger.warning(f"Connection failed to {target}: {e}")
            result["error"] = f"Connection failed (exit code {e.returncode})"
        except FileNotFoundError:
            logger.error("curl command not found")
            result["error"] = "curl not installed"
        except Exception as e:
            logger.error(f"Unexpected error checking connection to {target}: {e}")
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
            # Read S-UI database
            if not os.path.exists(SUI_DB_FILE):
                logger.warning(f"Database not found: {SUI_DB_FILE}")
                result["error"] = "Database not found"
                return result

            import sqlite3
            conn = sqlite3.connect(SUI_DB_FILE, timeout=DB_TIMEOUT)
            cur = conn.cursor()

            # s-ui schema: clients(email, enable, up, down, total, expiry_time)
            cur.execute("""
                SELECT enable, up, down, total, expiry_time
                FROM clients
                WHERE email = ?
            """, (username,))

            row = cur.fetchone()
            conn.close()

            if row:
                enable, up, down, total, expiry_time = row
                result["status"] = "active" if enable == 1 else "disabled"
                result["used_traffic"] = (up or 0) + (down or 0)
                result["data_limit"] = total or 0
                result["expiry"] = expiry_time
            else:
                logger.info(f"User not found: {username}")
                result["error"] = "User not found"

        except sqlite3.Error as e:
            logger.error(f"Database error checking profile {username}: {e}")
            result["error"] = f"Database error: {str(e)}"
        except Exception as e:
            logger.error(f"Unexpected error checking profile {username}: {e}")
            result["error"] = str(e)

        return result

    def check_all_profiles(self) -> list:
        """
        Check status of all profiles
        Returns list of profile statuses
        """
        profiles = []

        try:
            if not os.path.exists(SUI_DB_FILE):
                logger.warning(f"Database not found: {SUI_DB_FILE}")
                return profiles

            import sqlite3
            conn = sqlite3.connect(SUI_DB_FILE, timeout=DB_TIMEOUT)
            cur = conn.cursor()

            # s-ui schema: clients(email, enable, up, down, total, expiry_time)
            cur.execute("""
                SELECT email, enable, up, down, total, expiry_time
                FROM clients
                ORDER BY email
            """)

            for row in cur.fetchall():
                email, enable, up, down, total, expiry_time = row
                profiles.append({
                    "username": email,
                    "status": "active" if enable == 1 else "disabled",
                    "used_traffic": (up or 0) + (down or 0),
                    "data_limit": total or 0,
                    "expiry": expiry_time
                })

            conn.close()

        except sqlite3.Error as e:
            logger.error(f"Database error checking profiles: {e}")
        except Exception as e:
            logger.error(f"Unexpected error checking profiles: {e}")

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
            active_result = subprocess.run(  # nosec B607, B603
                ["systemctl", "is-active", service_name],
                capture_output=True,
                text=True,
                timeout=SERVICE_CHECK_TIMEOUT
            )
            result["active"] = active_result.returncode == 0

            # Check if service is running
            running_result = subprocess.run(  # nosec B607, B603
                ["systemctl", "is-running", service_name],
                capture_output=True,
                text=True,
                timeout=SERVICE_CHECK_TIMEOUT
            )
            result["running"] = running_result.returncode == 0

        except subprocess.TimeoutExpired as e:
            logger.error(f"Timeout checking service {service_name}: {e}")
            result["error"] = "Timeout checking service"
        except FileNotFoundError:
            logger.error("systemctl command not found")
            result["error"] = "systemctl not available"
        except Exception as e:
            logger.error(f"Unexpected error checking service {service_name}: {e}")
            result["error"] = str(e)

        return result

    def check_health_endpoint(self) -> dict:
        """
        Check the S-UI API status endpoint
        Returns dict with status, services
        """
        result = {
            "status": "unknown",
            "s-ui": "unknown",
            "singbox": "unknown",
            "error": None
        }

        try:
            response = subprocess.run(  # nosec B607, B603
                ["curl", "-sf", "--max-time", "10",
                 f"http://localhost:{self.health_check_port}/api/server/status"],
                capture_output=True,
                text=True,
                timeout=HEALTH_ENDPOINT_TIMEOUT,
                check=True
            )

            if response.returncode == 0:
                try:
                    data = json.loads(response.stdout)
                    # S-UI API v2 response format
                    if data.get("success"):
                        result["status"] = "healthy"
                        result["s-ui"] = "running"
                    else:
                        result["status"] = "unhealthy"
                except json.JSONDecodeError as e:
                    logger.error(f"Invalid JSON from status endpoint: {e}")
                    result["status"] = "invalid_response"
                    result["error"] = "Invalid JSON from status endpoint"
            else:
                result["status"] = "unreachable"
                result["error"] = "Status endpoint not responding"

        except subprocess.TimeoutExpired as e:
            logger.warning(f"Timeout connecting to status endpoint: {e}")
            result["error"] = "Timeout connecting to status endpoint"
        except subprocess.CalledProcessError as e:
            logger.info(f"Status endpoint not responding: {e}")
            result["status"] = "unreachable"
            result["error"] = "Status endpoint not responding"
        except FileNotFoundError:
            logger.error("curl command not found")
            result["error"] = "curl not installed"
        except Exception as e:
            logger.error(f"Unexpected error checking health endpoint: {e}")
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
            logger.info(f"Restart cooldown active for {service_name}. Wait {remaining}s")
            return False

        try:
            logger.info(f"Restarting {service_name}...")
            subprocess.run(  # nosec B607, B603
                ["systemctl", "restart", service_name],
                capture_output=True,
                timeout=SERVICE_RESTART_TIMEOUT,
                check=True
            )

            # Wait for service to start
            time.sleep(3)

            # Verify restart
            status = subprocess.run(  # nosec B607, B603
                ["systemctl", "is-active", service_name],
                capture_output=True,
                text=True,
                timeout=SERVICE_CHECK_TIMEOUT
            )

            if status.returncode == 0:
                self.last_restart_time[service_name] = now
                logger.info(f"{service_name} restarted successfully")
                return True
            else:
                logger.warning(f"{service_name} failed to restart")
                return False

        except subprocess.TimeoutExpired as e:
            logger.error(f"Timeout restarting {service_name}: {e}")
            return False
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to restart {service_name}: {e}")
            return False
        except FileNotFoundError:
            logger.error("systemctl command not found")
            return False
        except Exception as e:
            logger.error(f"Unexpected error restarting {service_name}: {e}")
            return False

    def auto_heal(self) -> list:
        """
        Check all services and auto-restart failed ones
        Returns list of actions taken
        """
        actions = []

        for service in MONITORED_SERVICES:
            health = self.check_service_health(service)

            if not health["active"]:
                logger.warning(f"{service} is not active, attempting restart...")

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
        for service in MONITORED_SERVICES + ["cubiveil-bot"]:
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
        for target in DEFAULT_CONNECTION_TARGETS[:3]:  # First 3 targets
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
