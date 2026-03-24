#!/usr/bin/env python3
"""
Backup Management Module
Handles database backup creation and cleanup
"""

import os
import shutil
from datetime import datetime


class BackupManager:
    """Manages database backups"""

    def __init__(self, db_path="/var/lib/marzban/db.sqlite3", backup_dir="/opt/cubiveil-bot/backups"):
        self.db_path = db_path
        self.backup_dir = backup_dir

        # Create backup directory if it doesn't exist
        os.makedirs(self.backup_dir, exist_ok=True)

    def create(self):
        """
        Create database backup and delete old backups (>7 days)
        Returns path to created backup or None on failure
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M")
        dst = f"{self.backup_dir}/marzban_{timestamp}.sqlite3"

        try:
            # Create backup
            shutil.copy2(self.db_path, dst)

            # Delete old backups (>7 days)
            now = datetime.now().timestamp()
            for filename in os.listdir(self.backup_dir):
                filepath = os.path.join(self.backup_dir, filename)
                if os.path.isfile(filepath):
                    file_age = now - os.path.getmtime(filepath)
                    if file_age > 7 * 86400:  # 7 days in seconds
                        os.remove(filepath)
                        print(f"[bot] Deleted old backup: {filename}")

            return dst
        except Exception as e:
            print(f"[bot] Backup error: {e}")
            return None
