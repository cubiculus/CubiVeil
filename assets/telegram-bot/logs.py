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

# Service display names / Отображаемые имена сервисов
SERVICE_NAMES = {
    "s-ui": "🆂 S-UI",
    "sing-box": "🆂 Sing-Box",
    "cubiveil-bot": "🤖 Bot",
    "nginx": "🌐 Nginx",
    "systemd": "💻 Systemd"
}


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

    def get_recent_logs(self, service: str, lines: int = 10) -> str:
        """
        Get recent logs for a service (simplified version for inline display)
        Args:
            service: Service name
            lines: Number of lines
        Returns:
            str: Formatted logs
        """
        success, logs = self.get_service_logs(service, lines)

        if not success:
            return logs

        return logs

    def search_logs(self, service: str, pattern: str, lines: int = 100) -> Tuple[bool, str]:
        """
        Search logs for a specific pattern
        Args:
            service: Service name
            pattern: Search pattern (grep)
            lines: Number of lines to search
        Returns:
            tuple: (success: bool, logs: str)
        """
        if service not in self.services:
            return False, f"Unknown service: {service}"

        try:
            # Get logs first
            journal_result = subprocess.run(  # nosec B607, B603
                ["journalctl", "-u", service, "--no-pager", "-n", str(lines)],
                capture_output=True,
                text=True,
                timeout=LOG_COMMAND_TIMEOUT,
                check=False
            )

            if journal_result.returncode != 0:
                stderr = journal_result.stderr.strip()[:500] if journal_result.stderr else "Unknown error"
                return False, f"❌ Error reading logs:\n<code>{stderr}</code>"

            # Search with grep
            grep_result = subprocess.run(  # nosec B607, B603
                ["grep", "-i", pattern],
                input=journal_result.stdout,
                capture_output=True,
                text=True,
                timeout=LOG_COMMAND_TIMEOUT,
                check=False
            )

            if grep_result.returncode == 0 and grep_result.stdout.strip():
                matches = grep_result.stdout.strip()
                if len(matches) > LOG_CHUNK_SIZE:
                    matches = matches[:LOG_CHUNK_SIZE] + "\n... (truncated)"

                return True, f"<b>🔍 Search results for '{pattern}':</b>\n\n<code>{matches}</code>"
            elif grep_result.returncode == 1:
                return True, f"📭 No matches found for '{pattern}'"
            else:
                stderr = grep_result.stderr.strip()[:500] if grep_result.stderr else "Unknown error"
                return False, f"❌ Error searching logs:\n<code>{stderr}</code>"

        except subprocess.TimeoutExpired:
            return False, "⚠️ Timeout: Search took too long"
        except Exception as e:
            return False, f"❌ Error: {str(e)}"

    def get_log_stats(self, service: str) -> dict:
        """
        Get statistics about logs for a service
        Args:
            service: Service name
        Returns:
            dict: Log statistics
        """
        stats = {
            "service": service,
            "total_lines": 0,
            "errors": 0,
            "warnings": 0,
            "size_kb": 0
        }

        try:
            # Count total lines (last 1000)
            lines_result = subprocess.run(  # nosec B607, B603
                ["journalctl", "-u", service, "--no-pager", "-n", "1000"],
                capture_output=True,
                text=True,
                timeout=LOG_COMMAND_TIMEOUT,
                check=False
            )

            if lines_result.returncode == 0:
                all_lines = lines_result.stdout.strip().split("\n")
                stats["total_lines"] = len(all_lines)

                # Count errors and warnings
                for line in all_lines:
                    line_lower = line.lower()
                    if "error" in line_lower or "failed" in line_lower:
                        stats["errors"] += 1
                    elif "warning" in line_lower or "warn" in line_lower:
                        stats["warnings"] += 1

            # Get disk usage for journal
            size_result = subprocess.run(  # nosec B607, B603
                ["journalctl", "--disk-usage"],
                capture_output=True,
                text=True,
                timeout=LOG_COMMAND_TIMEOUT,
                check=False
            )

            if size_result.returncode == 0:
                # Parse "Archived and active journals take up 88.0M in total."
                output = size_result.stdout.strip()
                if "take up" in output:
                    size_part = output.split("take up")[1].split("in total")[0].strip()
                    stats["size_kb"] = size_part

        except Exception as e:
            logger.error(f"Error getting log stats: {e}")

        return stats

    def clear_service_logs(self, service: str) -> bool:
        """
        Clear logs for a specific service (rotate)
        Args:
            service: Service name
        Returns:
            bool: Success status
        """
        try:
            subprocess.run(  # nosec B607, B603
                ["journalctl", "-u", service, "--rotate"],
                capture_output=True,
                text=True,
                timeout=LOG_COMMAND_TIMEOUT,
                check=True
            )
            logger.info(f"Logs rotated for {service}")
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to rotate logs for {service}: {e}")
            return False
        except Exception as e:
            logger.error(f"Error rotating logs for {service}: {e}")
            return False
