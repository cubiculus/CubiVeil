#!/usr/bin/env python3
"""
Backup Management Module
Handles database backup creation and cleanup
"""

import os
import shutil
import logging
from datetime import datetime
from typing import Optional, List

logger = logging.getLogger(__name__)


class BackupError(Exception):
    """Custom exception for backup errors"""
    pass


class BackupManager:
    """Manages database backups"""

    def __init__(self, db_path: str = "/var/lib/marzban/db.sqlite3",
                 backup_dir: str = "/opt/cubiveil-bot/backups",
                 retention_days: int = 7):
        self.db_path = db_path
        self.backup_dir = backup_dir
        self.retention_days = retention_days

        # Create backup directory if it doesn't exist
        self._ensure_backup_directory()

    def _ensure_backup_directory(self) -> None:
        """Ensure backup directory exists with proper permissions"""
        try:
            if not os.path.exists(self.backup_dir):
                os.makedirs(self.backup_dir, mode=0o750, exist_ok=True)
                logger.info(f"Created backup directory: {self.backup_dir}")
        except OSError as e:
            logger.error(f"Failed to create backup directory: {e}")
            raise BackupError(f"Cannot create backup directory: {e}")

    def _validate_db_path(self) -> bool:
        """Validate database file exists and is readable"""
        if not os.path.exists(self.db_path):
            logger.error(f"Database file not found: {self.db_path}")
            return False
        if not os.path.isfile(self.db_path):
            logger.error(f"Database path is not a file: {self.db_path}")
            return False
        if not os.access(self.db_path, os.R_OK):
            logger.error(f"Database file is not readable: {self.db_path}")
            return False
        return True

    def create(self) -> Optional[str]:
        """
        Create database backup and delete old backups (>7 days)
        Returns:
            str: Path to created backup or None on failure
        Raises:
            BackupError: If backup creation fails
        """
        if not self._validate_db_path():
            raise BackupError(f"Invalid database path: {self.db_path}")

        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        dst = f"{self.backup_dir}/marzban_{timestamp}.sqlite3"

        try:
            # Create backup with metadata preservation
            shutil.copy2(self.db_path, dst)
            logger.info(f"Backup created: {dst}")

            # Delete old backups
            deleted = self.cleanup_old_backups()
            if deleted:
                logger.info(f"Deleted {deleted} old backup(s)")

            return dst
        except shutil.Error as e:
            logger.error(f"Failed to copy database: {e}")
            raise BackupError(f"Backup copy failed: {e}")
        except IOError as e:
            logger.error(f"IO error during backup: {e}")
            raise BackupError(f"Backup IO error: {e}")
        except Exception as e:
            logger.error(f"Unexpected error during backup: {e}")
            raise BackupError(f"Unexpected backup error: {e}")

    def cleanup_old_backups(self) -> int:
        """
        Delete backups older than retention period
        Returns:
            int: Number of deleted backups
        """
        if not os.path.exists(self.backup_dir):
            return 0

        deleted_count = 0
        now = datetime.now().timestamp()
        retention_seconds = self.retention_days * 86400

        try:
            for filename in os.listdir(self.backup_dir):
                filepath = os.path.join(self.backup_dir, filename)
                if not os.path.isfile(filepath):
                    continue

                file_age = now - os.path.getmtime(filepath)
                if file_age > retention_seconds:
                    os.remove(filepath)
                    logger.info(f"Deleted old backup: {filename}")
                    deleted_count += 1
        except OSError as e:
            logger.error(f"Error during backup cleanup: {e}")

        return deleted_count

    def list_backups(self) -> List[dict]:
        """
        List all available backups with metadata
        Returns:
            list: List of backup info dictionaries
        """
        backups = []

        if not os.path.exists(self.backup_dir):
            return backups

        try:
            for filename in sorted(os.listdir(self.backup_dir)):
                filepath = os.path.join(self.backup_dir, filename)
                if not os.path.isfile(filepath):
                    continue

                stat = os.stat(filepath)
                backups.append({
                    "filename": filename,
                    "path": filepath,
                    "size": stat.st_size,
                    "created": datetime.fromtimestamp(stat.st_mtime),
                    "age_days": (datetime.now() - datetime.fromtimestamp(stat.st_mtime)).days
                })
        except OSError as e:
            logger.error(f"Error listing backups: {e}")

        return backups

    def get_latest_backup(self) -> Optional[str]:
        """
        Get path to the most recent backup
        Returns:
            str: Path to latest backup or None if no backups exist
        """
        backups = self.list_backups()
        if not backups:
            return None
        return backups[-1]["path"]

    def restore(self, backup_path: str, target_path: Optional[str] = None) -> bool:
        """
        Restore database from backup
        Args:
            backup_path: Path to backup file
            target_path: Optional target path (defaults to original db_path)
        Returns:
            bool: True if restore successful, False otherwise
        """
        if not os.path.exists(backup_path):
            logger.error(f"Backup file not found: {backup_path}")
            return False

        target = target_path or self.db_path

        try:
            # Create backup of current database before restore
            if os.path.exists(target):
                pre_restore_backup = f"{target}.pre_restore_{datetime.now().strftime('%Y%m%d_%H%M')}"
                shutil.copy2(target, pre_restore_backup)
                logger.info(f"Created pre-restore backup: {pre_restore_backup}")

            shutil.copy2(backup_path, target)
            logger.info(f"Restored database from {backup_path}")
            return True
        except shutil.Error as e:
            logger.error(f"Failed to restore backup: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error during restore: {e}")
            return False
