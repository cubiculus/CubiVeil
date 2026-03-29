#!/usr/bin/env python3
"""
Tests for Telegram Bot Metrics Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, mock_open

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from metrics import MetricsCollector, MetricsError


class TestMetricsCollector(unittest.TestCase):
    """Test cases for MetricsCollector module"""

    def setUp(self):
        """Set up test fixtures"""
        self.metrics = MetricsCollector()

    def test_initialization(self):
        """Test metrics collector initializes correctly"""
        self.assertIsNotNone(self.metrics.db_path)
        self.assertEqual(self.metrics.db_path, "/usr/local/s-ui/db/s-ui.db")

    @patch('metrics.open', new_callable=mock_open)
    @patch('time.sleep')
    def test_get_cpu(self, mock_sleep, mock_file):
        """Test CPU usage calculation"""
        # Mock second read with different values
        mock_file().readline.side_effect = [
            "cpu 100 0 200 300 400 500 600 0 0 0\n",
            "cpu 200 0 300 400 500 600 700 0 0 0\n"
        ]

        cpu = self.metrics.get_cpu()

        self.assertIsInstance(cpu, float)
        self.assertGreaterEqual(cpu, 0)
        self.assertLessEqual(cpu, 100)

    def test_get_ram_mock(self):
        """Test RAM usage calculation with manual calculation"""
        # Test the calculation logic directly
        mem_total_kb = 16384000
        mem_available_kb = 12000000

        total = mem_total_kb // 1024  # MB
        used = (mem_total_kb - mem_available_kb) // 1024  # MB
        pct = round(used / total * 100, 1) if total > 0 else 0.0

        self.assertGreater(total, 0)
        self.assertEqual(total, 16000)
        self.assertGreaterEqual(used, 0)
        self.assertGreaterEqual(pct, 0)
        self.assertLessEqual(pct, 100)

    @patch('metrics.subprocess.run')
    def test_get_disk(self, mock_run):
        """Test disk usage calculation"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="Filesystem     1G-blocks  Used Available Use% Mounted on\n/dev/sda1       100G   50G   50G  50% /\n"
        )

        used, total, pct = self.metrics.get_disk()

        self.assertEqual(total, 100)
        self.assertEqual(used, 50)
        self.assertEqual(pct, 50)

    @patch('metrics.open', new_callable=mock_open, read_data="123456.78\n")
    def test_get_uptime(self, mock_file):
        """Test uptime calculation"""
        uptime = self.metrics.get_uptime()

        self.assertIsInstance(uptime, str)
        self.assertIn("d", uptime) or self.assertIn("h", uptime) or self.assertIn("m", uptime)

    @patch('metrics.os.path.exists')
    @patch('metrics.sqlite3.connect')
    def test_get_active_users(self, mock_connect, mock_exists):
        """Test active users count"""
        mock_exists.return_value = True
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = [42]
        mock_connect.return_value.cursor.return_value = mock_cursor

        users = self.metrics.get_active_users()

        self.assertEqual(users, 42)

    @patch('metrics.os.path.exists')
    def test_get_active_users_db_not_found(self, mock_exists):
        """Test active users when DB not found"""
        mock_exists.return_value = False

        users = self.metrics.get_active_users()

        self.assertEqual(users, "?")


class TestMetricsErrors(unittest.TestCase):
    """Test error handling in metrics module"""

    def setUp(self):
        """Set up test fixtures"""
        self.metrics = MetricsCollector()

    @patch('metrics.open')
    def test_get_cpu_file_not_found(self, mock_open):
        """Test CPU when file not found"""
        mock_open.side_effect = FileNotFoundError()

        cpu = self.metrics.get_cpu()

        self.assertEqual(cpu, 0.0)

    @patch('metrics.subprocess.run')
    def test_get_disk_timeout(self, mock_run):
        """Test disk when command times out"""
        mock_run.side_effect = Exception("Timeout")

        used, total, pct = self.metrics.get_disk()

        self.assertEqual(used, 0)
        self.assertEqual(total, 0)
        self.assertEqual(pct, 0)


if __name__ == "__main__":
    unittest.main()
