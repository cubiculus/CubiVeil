#!/usr/bin/env python3
"""
Decoy Manager Module
Manages Decoy Site rotation and configuration for Telegram bot
"""

import os
import json
import subprocess  # nosec B404
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
import logging

from constants import (
    DECOY_CONFIG,
    DECOY_WEBROOT,
    DECOY_TIMER,
    DECOY_ROTATE_SCRIPT,
)

logger = logging.getLogger(__name__)

# File type display names / Отображаемые имена типов файлов
FILE_TYPE_NAMES = {
    "jpg": "🖼️ JPG",
    "pdf": "📄 PDF",
    "mp4": "🎬 MP4",
    "mp3": "🎵 MP3",
}

# Command timeout / Таймаут команд
DECOY_COMMAND_TIMEOUT = 60


class DecoyManager:
    """Manager for Decoy Site rotation and configuration"""

    def __init__(self):
        self.config_path = DECOY_CONFIG
        self.webroot = DECOY_WEBROOT
        self.timer_name = DECOY_TIMER
        self.rotate_script = DECOY_ROTATE_SCRIPT

    def _run_command(self, cmd: list[str], timeout: int = DECOY_COMMAND_TIMEOUT) -> tuple[bool, str]:
        """
        Run shell command with timeout
        Args:
            cmd: Command and arguments
            timeout: Timeout in seconds
        Returns:
            (success, output) tuple
        """
        try:
            result = subprocess.run(  # nosec B603
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            output = result.stdout + result.stderr
            return result.returncode == 0, output.strip()
        except subprocess.TimeoutExpired:
            return False, f"Command timed out after {timeout}s"
        except Exception as e:
            return False, str(e)

    def _load_config(self) -> Optional[Dict[str, Any]]:
        """Load decoy configuration"""
        try:
            if not os.path.exists(self.config_path):
                return None
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError) as e:
            logger.error(f"Failed to load config: {e}")
            return None

    def _save_config(self, config: Dict[str, Any]) -> bool:
        """Save decoy configuration"""
        try:
            with open(self.config_path, 'w') as f:
                json.dump(config, f, indent=2)
            # Set secure permissions
            os.chmod(self.config_path, 0o600)
            return True
        except IOError as e:
            logger.error(f"Failed to save config: {e}")
            return False

    def is_configured(self) -> bool:
        """Check if decoy site is configured"""
        return os.path.exists(self.config_path)

    def get_status(self) -> Dict[str, Any]:
        """
        Get decoy site status
        Returns:
            dict with status information
        """
        status = {
            "configured": False,
            "enabled": False,
            "timer_active": False,
            "file_count": 0,
            "total_size_mb": 0.0,
            "last_rotation": None,
            "next_rotation": None,
            "interval_hours": 3,
            "max_size_mb": 5000,
            "files_by_type": {},
        }

        if not self.is_configured():
            return status

        config = self._load_config()
        if not config:
            return status

        status["configured"] = True
        status["enabled"] = config.get("rotation", {}).get("enabled", False)
        status["interval_hours"] = config.get("rotation", {}).get("interval_hours", 3)
        status["max_size_mb"] = config.get("max_total_files_mb", 5000)

        # Last rotation
        last_rotated = config.get("rotation", {}).get("last_rotated_at")
        if last_rotated:
            status["last_rotation"] = last_rotated
            # Calculate next rotation
            try:
                last_dt = datetime.fromisoformat(last_rotated.replace('Z', '+00:00'))
                next_dt = last_dt + timedelta(hours=status["interval_hours"])
                status["next_rotation"] = next_dt.isoformat()
            except (ValueError, TypeError) as e:
                logger.debug(f"Failed to parse last rotation time: {e}")
                pass

        # Timer status
        success, _ = self._run_command(
            ["systemctl", "is-active", f"{self.timer_name}.timer"]
        )
        status["timer_active"] = success

        # File statistics
        if os.path.exists(self.webroot):
            files_dir = os.path.join(self.webroot, "files")
            if os.path.isdir(files_dir):
                total_size = 0
                file_count = 0
                by_type = {}

                for root, dirs, files in os.walk(files_dir):
                    for f in files:
                        filepath = os.path.join(root, f)
                        try:
                            size = os.path.getsize(filepath)
                            total_size += size
                            file_count += 1

                            # Count by type
                            ext = f.rsplit('.', 1)[-1].lower() if '.' in f else "other"
                            by_type[ext] = by_type.get(ext, 0) + 1
                        except OSError as e:
                            logger.debug(f"Failed to get file size for {filepath}: {e}")
                            pass

                status["file_count"] = file_count
                status["total_size_mb"] = round(total_size / (1024 * 1024), 2)
                status["files_by_type"] = by_type

        return status

    def get_files_list(self, limit: int = 50) -> List[Dict[str, Any]]:
        """
        Get list of files in decoy webroot
        Args:
            limit: Maximum files to return
        Returns:
            List of file info dicts
        """
        files = []
        files_dir = os.path.join(self.webroot, "files")

        if not os.path.isdir(files_dir):
            return files

        for root, dirs, filenames in os.walk(files_dir):
            for filename in filenames:
                filepath = os.path.join(root, filename)
                try:
                    stat = os.stat(filepath)
                    ext = filename.rsplit('.', 1)[-1].lower() if '.' in filename else "other"
                    files.append({
                        "name": filename,
                        "path": filepath,
                        "type": ext,
                        "type_display": FILE_TYPE_NAMES.get(ext, ext.upper()),
                        "size_bytes": stat.st_size,
                        "size_mb": round(stat.st_size / (1024 * 1024), 2),
                        "modified": datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    })
                except OSError as e:
                    logger.debug(f"Failed to get file info for {filepath}: {e}")
                    pass

                if len(files) >= limit:
                    break

        # Sort by modification time (newest first)
        files.sort(key=lambda x: x["modified"], reverse=True)
        return files[:limit]

    def rotate_now(self) -> tuple[bool, str]:
        """
        Trigger immediate rotation
        Returns:
            (success, message) tuple
        """
        if not self.is_configured():
            return False, "Decoy site not configured"

        if not os.path.exists(self.rotate_script):
            return False, f"Rotate script not found: {self.rotate_script}"

        success, output = self._run_command(["bash", self.rotate_script])
        if success:
            return True, "Rotation completed successfully"
        return False, f"Rotation failed: {output}"

    def set_interval(self, hours: int) -> tuple[bool, str]:
        """
        Set rotation interval
        Args:
            hours: Interval in hours (1-168)
        Returns:
            (success, message) tuple
        """
        if hours < 1 or hours > 168:
            return False, "Interval must be between 1 and 168 hours"

        config = self._load_config()
        if not config:
            return False, "Failed to load configuration"

        config.setdefault("rotation", {})["interval_hours"] = hours

        if self._save_config(config):
            # Reload systemd timer
            self._run_command(["systemctl", "daemon-reload"])
            return True, f"Interval set to {hours} hours"
        return False, "Failed to save configuration"

    def set_size_limit(self, limit_mb: int) -> tuple[bool, str]:
        """
        Set maximum total size limit
        Args:
            limit_mb: Limit in megabytes (minimum 100)
        Returns:
            (success, message) tuple
        """
        if limit_mb < 100:
            return False, "Minimum size limit is 100 MB"

        config = self._load_config()
        if not config:
            return False, "Failed to load configuration"

        config["max_total_files_mb"] = limit_mb

        if self._save_config(config):
            return True, f"Size limit set to {limit_mb} MB"
        return False, "Failed to save configuration"

    def set_type_weight(self, file_type: str, weight: int) -> tuple[bool, str]:
        """
        Set weight for file type
        Args:
            file_type: Type (jpg, pdf, mp4, mp3)
            weight: Weight (0-10, 0 = disabled)
        Returns:
            (success, message) tuple
        """
        valid_types = ["jpg", "pdf", "mp4", "mp3"]
        if file_type not in valid_types:
            return False, f"Invalid type. Must be one of: {valid_types}"

        if weight < 0 or weight > 10:
            return False, "Weight must be between 0 and 10"

        config = self._load_config()
        if not config:
            return False, "Failed to load configuration"

        config.setdefault("rotation", {}).setdefault("types", {})
        config["rotation"]["types"][file_type] = {
            "enabled": weight > 0,
            "weight": weight,
        }

        if self._save_config(config):
            status = "enabled" if weight > 0 else "disabled"
            return True, f"{file_type.upper()} rotation {status} with weight {weight}"
        return False, "Failed to save configuration"

    def get_type_weights(self) -> Dict[str, Dict[str, Any]]:
        """
        Get current file type weights
        Returns:
            Dict with type configurations
        """
        config = self._load_config()
        if not config:
            return {}

        return config.get("rotation", {}).get("types", {})

    def toggle_rotation(self, enable: bool) -> tuple[bool, str]:
        """
        Enable or disable rotation
        Args:
            enable: True to enable, False to disable
        Returns:
            (success, message) tuple
        """
        config = self._load_config()
        if not config:
            return False, "Failed to load configuration"

        config.setdefault("rotation", {})["enabled"] = enable

        if self._save_config(config):
            action = "enable" if enable else "disable"
            success, _ = self._run_command(
                ["systemctl", f"{action}", f"{self.timer_name}.timer"]
            )
            if enable:
                self._run_command(["systemctl", "start", f"{self.timer_name}.timer"])

            status = "enabled" if enable else "disabled"
            return True, f"Rotation {status}"
        return False, "Failed to save configuration"

    def cleanup_old_files(self) -> tuple[bool, str, Dict[str, Any]]:
        """
        Clean up old files exceeding size limit
        Returns:
            (success, message, stats) tuple
        """
        if not self.is_configured():
            return False, "Decoy site not configured", {}

        # Source the rotate.sh and call the cleanup function
        # We'll use the CLI utility for this
        success, output = self._run_command(
            ["bash", "/opt/cubiveil/utils/decoy-rotate.sh", "cleanup"]
        )

        stats = {"deleted": 0, "freed_mb": 0}
        # Parse output for stats
        if "удалено файлов" in output:
            try:
                parts = output.split("удалено файлов")[1].split(",")[0].strip()
                stats["deleted"] = int(parts)
            except (ValueError, IndexError) as e:
                logger.debug(f"Failed to parse deleted files count: {e}")
                pass
        if "освобождено" in output:
            try:
                parts = output.split("освобождено ~")[1].split("MB")[0].strip()
                stats["freed_mb"] = int(parts)
            except (ValueError, IndexError) as e:
                logger.debug(f"Failed to parse freed space: {e}")
                pass

        if success:
            return True, "Cleanup completed", stats
        return False, f"Cleanup failed: {output}", stats

    def regenerate_all(self) -> tuple[bool, str]:
        """
        Regenerate all decoy files
        Returns:
            (success, message) tuple
        """
        if not self.is_configured():
            return False, "Decoy site not configured"

        # Stop timer
        self._run_command(["systemctl", "stop", f"{self.timer_name}.timer"])

        # Run regeneration via CLI utility
        success, output = self._run_command(
            ["bash", "/opt/cubiveil/utils/decoy-rotate.sh", "regenerate"],
            timeout=300  # 5 minutes for regeneration
        )

        # Restart timer
        self._run_command(["systemctl", "start", f"{self.timer_name}.timer"])

        if success:
            return True, "All files regenerated successfully"
        return False, f"Regeneration failed: {output}"
