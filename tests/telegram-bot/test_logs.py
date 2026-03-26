#!/usr/bin/env python3
"""
Tests for Telegram Bot Logs Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from logs import LogsManager, LogsError


class TestLogsManager(unittest.TestCase):
    """Test cases for LogsManager module"""

    def setUp(self):
        """Set up test fixtures"""
        self.logs = LogsManager()

    def test_initialization(self):
        """Test logs manager initializes correctly"""
        self.assertIsNotNone(self.logs.services)
        self.assertIn("marzban", self.logs.services)
        self.assertIn("sing-box", self.logs.services)
        self.assertIn("cubiveil-bot", self.logs.services)
        self.assertIn("nginx", self.logs.services)
        self.assertIn("systemd", self.logs.services)

    def test_get_service_logs_unknown_service(self):
        """Test getting logs for unknown service"""
        success, logs = self.logs.get_service_logs("unknown_service", 50)

        self.assertFalse(success)
        self.assertIn("Unknown service", logs)

    @patch('logs.subprocess.run')
    def test_get_service_logs_success(self, mock_run):
        """Test successful log retrieval"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="Line 1\nLine 2\nLine 3\n",
            stderr=""
        )

        success, logs = self.logs.get_service_logs("marzban", 50)

        self.assertTrue(success)
        self.assertIn("<b>", logs)  # HTML formatting
        self.assertIn("Marzban", logs)
        mock_run.assert_called_once()

    @patch('logs.subprocess.run')
    def test_get_service_logs_empty(self, mock_run):
        """Test log retrieval with empty logs"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="",
            stderr=""
        )

        success, logs = self.logs.get_service_logs("marzban", 50)

        self.assertTrue(success)
        self.assertIn("No logs found", logs)

    @patch('logs.subprocess.run')
    def test_get_service_logs_timeout(self, mock_run):
        """Test log retrieval timeout"""
        mock_run.side_effect = Exception("Timeout")

        success, logs = self.logs.get_service_logs("marzban", 50)

        self.assertFalse(success)
        self.assertIn("Error", logs)

    @patch('logs.subprocess.run')
    def test_get_systemd_logs_success(self, mock_run):
        """Test systemd logs retrieval"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="UNIT LOAD ACTIVE SUB DESCRIPTION\nunit.service loaded active running Description\n",
            stderr=""
        )

        success, logs = self.logs._get_systemd_logs(50)

        self.assertTrue(success)
        self.assertIn("Systemd", logs)

    def test_get_recent_logs(self):
        """Test getting recent logs"""
        # This will fail without actual journalctl, but tests the method exists
        result = self.logs.get_recent_logs("marzban", 10)
        self.assertIsInstance(result, str)

    @patch('logs.subprocess.run')
    def test_search_logs_success(self, mock_run):
        """Test searching logs"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="Match line 1\nMatch line 2\n",
            stderr=""
        )

        success, logs = self.logs.search_logs("marzban", "error", 100)

        self.assertTrue(success)
        self.assertIn("Search results", logs)

    @patch('logs.subprocess.run')
    def test_search_logs_no_matches(self, mock_run):
        """Test searching logs with no matches"""
        mock_run.return_value = MagicMock(
            returncode=1,
            stdout="",
            stderr=""
        )

        success, logs = self.logs.search_logs("marzban", "xyz123notfound", 100)

        self.assertTrue(success)  # Not an error, just no matches
        self.assertIn("No matches", logs)

    @patch('logs.subprocess.run')
    def test_get_log_stats(self, mock_run):
        """Test getting log statistics"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="Line with error\nLine with warning\nNormal line\n",
            stderr=""
        )

        stats = self.logs.get_log_stats("marzban")

        self.assertEqual(stats["service"], "marzban")
        self.assertGreater(stats["total_lines"], 0)

    @patch('logs.subprocess.run')
    def test_clear_service_logs(self, mock_run):
        """Test clearing service logs"""
        mock_run.return_value = MagicMock(returncode=0)

        result = self.logs.clear_service_logs("marzban")

        self.assertTrue(result)
        mock_run.assert_called_once()


class TestLogsConstants(unittest.TestCase):
    """Test logs module constants"""

    def test_service_log_map(self):
        """Test service log mapping in commands module"""
        # Import here to avoid circular imports
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))
        from commands import SERVICE_LOG_MAP

        self.assertIn("logs_marzban", SERVICE_LOG_MAP)
        self.assertEqual(SERVICE_LOG_MAP["logs_marzban"], "marzban")
        self.assertEqual(SERVICE_LOG_MAP["logs_singbox"], "sing-box")
        self.assertEqual(SERVICE_LOG_MAP["logs_bot"], "cubiveil-bot")
        self.assertEqual(SERVICE_LOG_MAP["logs_nginx"], "nginx")
        self.assertEqual(SERVICE_LOG_MAP["logs_system"], "systemd")


if __name__ == "__main__":
    unittest.main()
