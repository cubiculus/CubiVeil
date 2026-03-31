#!/usr/bin/env python3
"""
Logs Module
Handles system and service logs retrieval
"""

import subprocess  # nosec B404
import logging
from typing import Optional, List, Tuple
from datetime import datetime

logger = logging.getLogger(__name__)

# Local modules - constants
from constants import SERVICE_NAMES

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# Services that can be monitored / Сервисы для мониторинга
AVAILABLE_SERVICES = {
    "s-ui": "s-ui",
    "sing-box": "sing-box",
    "cubiveil-bot": "cubiveil-bot",
    "nginx": "nginx",
    "systemd": "systemd"
}

# Default log lines / Количество строк по умолчанию
DEFAULT_LOG_LINES = 50

# Max log lines for Telegram / Максимум строк для Telegram
MAX_LOG_LINES_TELEGRAM = 200

# Log command timeout / Таймаут команды логов
LOG_COMMAND_TIMEOUT = 10

# Chunk size for long logs / Размер чанка для длинных логов
LOG_CHUNK_SIZE = 4000


class LogsError(Exception):
    """Custom exception for logs errors"""
    pass


class LogsManager:
    """Manages system and service logs"""

    def __init__(self):
        self.services = AVAILABLE_SERVICES

    def get_service_logs(self, service: str, lines: int = DEFAULT_LOG_LINES) -> Tuple[bool, str]:
        """
        Get logs for a specific service
        Args:
            service: Service name (sing-box, etc.)
            lines: Number of lines to retrieve
        Returns:
            tuple: (success: bool, logs: str)
        """
        if service not in self.services:
            return False, f"Unknown service: {service}"

        # Limit lines for Telegram
        lines = min(lines, MAX_LOG_LINES_TELEGRAM)

        try:
            if service == "systemd":
                return self._get_systemd_logs(lines)
            else:
                return self._get_service_logs(service, lines)
        except subprocess.TimeoutExpired:
            logger.error(f"Timeout getting logs for {service}")
            return False, f"⚠️ Timeout: Logs retrieval took too long"
        except Exception as e:
            logger.error(f"Error getting logs for {service}: {e}")
            return False, f"❌ Error: {str(e)}"

    def _get_service_logs(self, service: str, lines: int) -> Tuple[bool, str]:
        """Get logs for a specific systemd service"""
        try:
            result = subprocess.run(  # nosec B607, B603
                ["journalctl", "-u", service, "--no-pager", "-n", str(lines)],
                capture_output=True,
                text=True,
                timeout=LOG_COMMAND_TIMEOUT,
                check=False
            )

            if result.returncode == 0:
                logs = result.stdout.strip()
                if not logs:
                    return True, f"📭 No logs found for {SERVICE_NAMES.get(service, service)}"

                # Format logs with header
                header = f"<b>{SERVICE_NAMES.get(service, service)} — Last {lines} lines</b>\n"
                header += "━━━━━━━━━━━━━━━━━━━━━\n"
                header += "<code>"

                footer = "</code>"

                # Truncate if too long
                full_logs = header + logs + footer
                if len(full_logs) > LOG_CHUNK_SIZE:
                    # Split into chunks
                    logs = logs[:LOG_CHUNK_SIZE - len(header) - len(footer) - 100]
                    full_logs = header + logs + "\n... (truncated)</code>"

                return True, full_logs
            else:
                stderr = result.stderr.strip()[:500] if result.stderr else "Unknown error"
                return False, f"❌ Error reading logs:\n<code>{stderr}</code>"

        except FileNotFoundError:
            return False, "❌ journalctl command not found"
        except Exception as e:
            return False, f"❌ Error: {str(e)}"

    def _get_systemd_logs(self, lines: int) -> Tuple[bool, str]:
        """Get general systemd logs (errors and warnings)"""
        try:
            # Get failed services
            failed_result = subprocess.run(  # nosec B607, B603
                ["systemctl", "--failed", "--no-pager"],
                capture_output=True,
                text=True,
                timeout=LOG_COMMAND_TIMEOUT,
                check=False
            )

            # Get recent system errors
            errors_result = subprocess.run(  # nosec B607, B603
                ["journalctl", "--priority", "err", "--no-pager", "-n", str(lines)],
                capture_output=True,
                text=True,
                timeout=LOG_COMMAND_TIMEOUT,
                check=False
            )

            message = "<b>💻 Systemd Status</b>\n"
            message += "━━━━━━━━━━━━━━━━━━━━━\n\n"

            # Failed services
            if failed_result.returncode == 0 and failed_result.stdout.strip():
                failed_services = failed_result.stdout.strip()
                # Parse failed services
                failed_list = []
                for line in failed_result.stdout.strip().split("\n")[2:]:  # Skip header
                    parts = line.split()
                    if len(parts) >= 1:
                        failed_list.append(parts[0])

                if failed_list:
                    message += "<b>⚠️ Failed Services:</b>\n"
                    for svc in failed_list[:10]:  # Limit to 10
                        message += f"  • {svc}\n"
                    message += "\n"
                else:
                    message += "<b>🟢 No failed services</b>\n\n"
            else:
                message += "<b>🟢 No failed services</b>\n\n"

            # Recent errors
            if errors_result.returncode == 0 and errors_result.stdout.strip():
                errors = errors_result.stdout.strip()
                message += "<b>📋 Recent Errors (last {}):</b>\n".format(lines)
                message += "<code>"

                # Truncate if too long
                if len(errors) > 2000:
                    errors = errors[:2000] + "\n... (truncated)"

                message += errors + "</code>"
            else:
                message += "<b>🟢 No recent errors</b>"

            return True, message

        except FileNotFoundError:
            return False, "❌ systemctl or journalctl command not found"
        except Exception as e:
            return False, f"❌ Error: {str(e)}"
