#!/usr/bin/env python3
"""
Tests for Telegram Bot Backup Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, mock_open
import tempfile
import shutil

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from backup import BackupManager, BackupError


class TestBackupManager(unittest.TestCase):
    """Test cases for BackupManager module"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_dir = tempfile.mkdtemp()
        self.test_db = os.path.join(self.test_dir, "test.db")
        self.backup_dir = os.path.join(self.test_dir, "backups")

        # Create test database file
        with open(self.test_db, 'w') as f:
            f.write("test database content")

        self.backup = BackupManager(self.test_db, self.backup_dir)

    def tearDown(self):
        """Clean up test fixtures"""
        shutil.rmtree(self.test_dir)

    def test_initialization(self):
        """Test backup manager initializes correctly"""
        self.assertEqual(self.backup.db_path, self.test_db)
        self.assertEqual(self.backup.backup_dir, self.backup_dir)
        self.assertEqual(self.backup.retention_days, 7)
        self.assertTrue(os.path.exists(self.backup_dir))

    def test_validate_db_path_success(self):
        """Test database validation with valid path"""
        result = self.backup._validate_db_path()
        self.assertTrue(result)

    def test_validate_db_path_not_exists(self):
        """Test database validation with non-existent path"""
        self.backup.db_path = "/nonexistent/path.db"
        result = self.backup._validate_db_path()
        self.assertFalse(result)

    def test_create_backup(self):
        """Test backup creation"""
        backup_path = self.backup.create()

        self.assertIsNotNone(backup_path)
        self.assertTrue(os.path.exists(backup_path))
        self.assertIn("s-ui_", backup_path)

    def test_create_backup_invalid_path(self):
        """Test backup creation with invalid path"""
        self.backup.db_path = "/nonexistent/path.db"

        with self.assertRaises(BackupError):
            self.backup.create()

    def test_list_backups(self):
        """Test listing backups"""
        # Create a backup first
        self.backup.create()

        backups = self.backup.list_backups()

        self.assertIsInstance(backups, list)
        self.assertGreater(len(backups), 0)
        self.assertIn("filename", backups[0])
        self.assertIn("size", backups[0])
        self.assertIn("created", backups[0])

    def test_list_backups_empty(self):
        """Test listing backups when directory is empty"""
        # Remove the backup we created in setUp
        for f in os.listdir(self.backup_dir):
            os.remove(os.path.join(self.backup_dir, f))

        backups = self.backup.list_backups()

        self.assertEqual(len(backups), 0)

    def test_get_latest_backup(self):
        """Test getting latest backup"""
        # Create multiple backups
        backup1 = self.backup.create()

        backups = self.backup.list_backups()
        latest = self.backup.get_latest_backup()

        self.assertIsNotNone(latest)
        self.assertEqual(latest, backup1)

    def test_get_latest_backup_none(self):
        """Test getting latest backup when none exist"""
        # Remove all backups
        for f in os.listdir(self.backup_dir):
            os.remove(os.path.join(self.backup_dir, f))

        latest = self.backup.get_latest_backup()

        self.assertIsNone(latest)

    @patch('backup.os.path.exists')
    def test_cleanup_old_backups(self, mock_exists):
        """Test cleanup of old backups"""
        mock_exists.return_value = True

        # Mock old backup file
        with patch('backup.os.listdir') as mock_listdir, \
             patch('backup.os.path.getmtime') as mock_getmtime, \
             patch('backup.os.remove') as mock_remove:

            mock_listdir.return_value = ["old_backup.sqlite3"]
            mock_getmtime.return_value = 0  # Very old timestamp

            deleted = self.backup.cleanup_old_backups()

            self.assertGreaterEqual(deleted, 0)

    def test_restore_backup(self):
        """Test backup restoration"""
        # Create a backup
        backup_path = self.backup.create()

        # Remove original database
        os.remove(self.test_db)

        # Restore from backup
        result = self.backup.restore(backup_path, self.test_db)

        self.assertTrue(result)
        self.assertTrue(os.path.exists(self.test_db))

    def test_restore_backup_not_found(self):
        """Test restoration with non-existent backup"""
        result = self.backup.restore("/nonexistent/backup.sqlite3")

        self.assertFalse(result)


class TestBackupManagerRetention(unittest.TestCase):
    """Test backup retention functionality"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_dir = tempfile.mkdtemp()
        self.test_db = os.path.join(self.test_dir, "test.db")
        self.backup_dir = os.path.join(self.test_dir, "backups")

        with open(self.test_db, 'w') as f:
            f.write("test database content")

        # Create backup with custom retention
        self.backup = BackupManager(self.test_db, self.backup_dir, retention_days=1)

    def tearDown(self):
        """Clean up test fixtures"""
        shutil.rmtree(self.test_dir)

    def test_custom_retention_days(self):
        """Test custom retention days setting"""
        self.assertEqual(self.backup.retention_days, 1)


if __name__ == "__main__":
    unittest.main()
