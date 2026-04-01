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
        self.assertIn("s-ui", self.logs.services)
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

        success, logs = self.logs.get_service_logs("s-ui", 50)

        self.assertTrue(success)
        self.assertIn("<b>", logs)  # HTML formatting
        self.assertIn("S-UI", logs)
        mock_run.assert_called_once()

    @patch('logs.subprocess.run')
    def test_get_service_logs_empty(self, mock_run):
        """Test log retrieval with empty logs"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="",
            stderr=""
        )

        success, logs = self.logs.get_service_logs("s-ui", 50)

        self.assertTrue(success)
        self.assertIn("No logs found", logs)

    @patch('logs.subprocess.run')
    def test_get_service_logs_timeout(self, mock_run):
        """Test log retrieval timeout"""
        mock_run.side_effect = Exception("Timeout")

        success, logs = self.logs.get_service_logs("s-ui", 50)

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


class TestLogsConstants(unittest.TestCase):
    """Test logs module constants"""

    def test_service_log_map(self):
        """Test service log mapping in commands module"""
        # Import here to avoid circular imports
        sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))
        from commands import SERVICE_LOG_MAP

        self.assertIn("logs_sui", SERVICE_LOG_MAP)
        self.assertEqual(SERVICE_LOG_MAP["logs_sui"], "s-ui")
        self.assertEqual(SERVICE_LOG_MAP["logs_singbox"], "sing-box")
        self.assertEqual(SERVICE_LOG_MAP["logs_bot"], "cubiveil-bot")
        self.assertEqual(SERVICE_LOG_MAP["logs_nginx"], "nginx")
        self.assertEqual(SERVICE_LOG_MAP["logs_system"], "systemd")


if __name__ == "__main__":
    unittest.main()
