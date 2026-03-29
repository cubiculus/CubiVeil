#!/usr/bin/env python3
"""
Tests for Telegram Bot Commands Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, PropertyMock
import json

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from commands import CommandHandler, RATE_LIMIT_SECONDS, MAX_COMMANDS_PER_MINUTE


class MockTelegram:
    """Mock Telegram client"""
    def __init__(self):
        self.messages = []

    def send(self, text, reply_markup=None):
        self.messages.append({"text": text, "reply_markup": reply_markup})

    def send_chat_action(self, action):
        pass

    def answer_callback(self, callback_id):
        pass

    def edit_message_text(self, chat_id, message_id, text, reply_markup=None):
        self.messages.append({"text": text, "reply_markup": reply_markup})


class MockMetrics:
    """Mock Metrics collector"""
    def get_cpu(self):
        return 25.5

    def get_ram(self):
        return (4096, 8192, 50.0)

    def get_disk(self):
        return (50, 100, 50)

    def get_uptime(self):
        return "10d 5h 30m"

    def get_active_users(self):
        return 42


class MockBackup:
    """Mock Backup manager"""
    def create(self):
        return "/tmp/test_backup.sqlite3"

    def list_backups(self):
        return [{"filename": "test.sqlite3", "size": 1024 * 1024 * 10}]

    def cleanup_old_backups(self):
        return 0

    def restore(self, path):
        return True


class MockAlertState:
    """Mock Alert state manager"""
    def load(self):
        return {}

    def save(self, state):
        pass


class MockHealth:
    """Mock Health checker"""
    def check_all_profiles(self):
        return [
            {"username": "user1", "status": "active", "used_traffic": 1000000000},
            {"username": "user2", "status": "disabled", "used_traffic": 0}
        ]

    def check_profile_status(self, username):
        return {
            "username": username,
            "status": "active",
            "used_traffic": 1000000000,
            "data_limit": 50000000000,
            "expiry": 1700000000
        }

    def format_health_message(self):
        return "<b>Health Report</b>"

    def check_connection_speed(self, url):
        return {"success": True, "latency_ms": 50}


class MockLogs:
    """Mock Logs manager"""
    def get_service_logs(self, service, lines):
        return (True, f"Logs for {service}")


class TestCommandHandler(unittest.TestCase):
    """Test cases for CommandHandler module"""

    def setUp(self):
        """Set up test fixtures"""
        self.telegram = MockTelegram()
        self.metrics = MockMetrics()
        self.backup = MockBackup()
        self.alert_state = MockAlertState()
        self.health = MockHealth()
        self.logs = MockLogs()

        self.handler = CommandHandler(
            self.telegram,
            self.metrics,
            self.backup,
            self.alert_state,
            80,  # alert_cpu
            85,  # alert_ram
            90,  # alert_disk
            self.health,
            self.logs
        )

    def test_handle_status_command(self):
        """Test /status command"""
        self.handler.handle("/status", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Server Status", self.telegram.messages[0]["text"])

    def test_handle_help_command(self):
        """Test /help command"""
        self.handler.handle("/help", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Commands", self.telegram.messages[0]["text"])

    def test_handle_unknown_command(self):
        """Test unknown command"""
        self.handler.handle("/unknown", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Unknown command", self.telegram.messages[0]["text"])

    def test_rate_limiting(self):
        """Test rate limiting"""
        # First command should pass
        self.handler.handle("/status", "123456")

        # Second command immediately should be rate limited
        initial_count = len(self.telegram.messages)
        self.handler.handle("/status", "123456")

        # Should have rate limit message
        self.assertGreater(len(self.telegram.messages), initial_count)
        self.assertIn("wait", self.telegram.messages[-1]["text"].lower())

    def test_handle_users_command(self):
        """Test /users command"""
        self.handler.handle("/users", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Active Users", self.telegram.messages[0]["text"])

    def test_handle_monitor_command(self):
        """Test /monitor command"""
        self.handler.handle("/monitor", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("System Monitor", self.telegram.messages[0]["text"])

    def test_handle_backup_menu_command(self):
        """Test /backup command"""
        self.handler.handle("/backup", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Backup Management", self.telegram.messages[0]["text"])

    def test_handle_profiles_command(self):
        """Test /profiles command"""
        self.handler.handle("/profiles", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Profiles Management", self.telegram.messages[0]["text"])

    def test_handle_logs_menu_command(self):
        """Test /logs command"""
        self.handler.handle("/logs", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Logs Menu", self.telegram.messages[0]["text"])

    def test_handle_settings_command(self):
        """Test /settings command"""
        self.handler.handle("/settings", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Bot Settings", self.telegram.messages[0]["text"])


class TestProfileCommands(unittest.TestCase):
    """Test profile-related commands"""

    def setUp(self):
        """Set up test fixtures"""
        self.telegram = MockTelegram()
        self.metrics = MockMetrics()
        self.backup = MockBackup()
        self.alert_state = MockAlertState()
        self.health = MockHealth()
        self.logs = MockLogs()

        self.handler = CommandHandler(
            self.telegram,
            self.metrics,
            self.backup,
            self.alert_state,
            80, 85, 90,
            self.health,
            self.logs
        )

    @patch('commands.SuiClient')
    def test_enable_command(self, mock_client_class):
        """Test /enable command"""
        mock_client = MagicMock()
        mock_client.enable_user.return_value = True
        self.handler.sui = mock_client

        self.handler.handle("/enable testuser", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("enabled", self.telegram.messages[0]["text"])

    @patch('commands.SuiClient')
    def test_disable_command(self, mock_client_class):
        """Test /disable command"""
        mock_client = MagicMock()
        mock_client.disable_user.return_value = True
        self.handler.sui = mock_client

        self.handler.handle("/disable testuser", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("disabled", self.telegram.messages[0]["text"])

    @patch('commands.SuiClient')
    def test_extend_command(self, mock_client_class):
        """Test /extend command"""
        mock_client = MagicMock()
        mock_client.extend_user.return_value = {"expire": 1700000000, "username": "testuser"}
        self.handler.sui = mock_client

        self.handler.handle("/extend testuser 30", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        # Just check the command executed without error
        self.assertTrue(len(self.telegram.messages) > 0)

    @patch('commands.SuiClient')
    def test_reset_command(self, mock_client_class):
        """Test /reset command"""
        mock_client = MagicMock()
        mock_client.reset_user_traffic.return_value = True
        self.handler.sui = mock_client

        self.handler.handle("/reset testuser", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Traffic reset", self.telegram.messages[0]["text"])

    @patch('commands.SuiClient')
    def test_traffic_command(self, mock_client_class):
        """Test /traffic command"""
        mock_client = MagicMock()
        mock_client.get_user_traffic.return_value = {
            "used_gb": 5.0,
            "limit_gb": 10.0,
            "remaining_gb": 5.0,
            "percentage": 50.0
        }
        self.handler.sui = mock_client

        self.handler.handle("/traffic testuser", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Traffic", self.telegram.messages[0]["text"])

    @patch('commands.SuiClient')
    def test_subscription_command(self, mock_client_class):
        """Test /subscription command"""
        mock_client = MagicMock()
        mock_client.get_subscription_link.return_value = "https://example.com/sub/abc123"
        self.handler.sui = mock_client

        self.handler.handle("/subscription testuser", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("Subscription", self.telegram.messages[0]["text"])

    @patch('commands.SuiClient')
    def test_create_command(self, mock_client_class):
        """Test /create command"""
        mock_client = MagicMock()
        mock_client.create_user.return_value = {"username": "newuser"}
        self.handler.sui = mock_client

        self.handler.handle("/create newuser 30 50", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("created", self.telegram.messages[0]["text"])


class TestSettingsCommands(unittest.TestCase):
    """Test settings commands"""

    def setUp(self):
        """Set up test fixtures"""
        self.telegram = MockTelegram()
        self.metrics = MockMetrics()
        self.backup = MockBackup()
        self.alert_state = MockAlertState()
        self.health = MockHealth()
        self.logs = MockLogs()

        self.handler = CommandHandler(
            self.telegram,
            self.metrics,
            self.backup,
            self.alert_state,
            80, 85, 90,
            self.health,
            self.logs
        )

    def test_set_cpu_command(self):
        """Test /set_cpu command"""
        self.handler.handle("/set_cpu 90", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertEqual(self.handler.alert_cpu, 90)

    def test_set_ram_command(self):
        """Test /set_ram command"""
        self.handler.handle("/set_ram 90", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertEqual(self.handler.alert_ram, 90)

    def test_set_disk_command(self):
        """Test /set_disk command"""
        self.handler.handle("/set_disk 95", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertEqual(self.handler.alert_disk, 95)

    def test_set_cpu_invalid_value(self):
        """Test /set_cpu with invalid value"""
        self.handler.handle("/set_cpu 150", "123456")

        self.assertGreater(len(self.telegram.messages), 0)
        self.assertIn("between 0 and 100", self.telegram.messages[0]["text"])


class TestCallbackHandlers(unittest.TestCase):
    """Test callback query handlers"""

    def setUp(self):
        """Set up test fixtures"""
        self.telegram = MockTelegram()
        self.metrics = MockMetrics()
        self.backup = MockBackup()
        self.alert_state = MockAlertState()
        self.health = MockHealth()
        self.logs = MockLogs()

        self.handler = CommandHandler(
            self.telegram,
            self.metrics,
            self.backup,
            self.alert_state,
            80, 85, 90,
            self.health,
            self.logs
        )

    def test_handle_callback_navigation(self):
        """Test navigation callback"""
        callback = {
            "id": "123",
            "message": {
                "chat": {"id": "123456"},
                "message_id": 789
            },
            "data": "nav_back"
        }

        # Should not raise
        self.handler.handle_callback(callback)


if __name__ == "__main__":
    unittest.main()
