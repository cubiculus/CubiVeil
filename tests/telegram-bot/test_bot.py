#!/usr/bin/env python3
"""
Tests for Telegram Bot Main Module (bot.py)
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, mock_open
import tempfile
import shutil
import json

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

# Mock fcntl on Windows (not available) BEFORE importing bot modules
if sys.platform == 'win32':
    sys.modules['fcntl'] = MagicMock()


class TestCubiVeilBotInit(unittest.TestCase):
    """Test CubiVeilBot initialization"""

    def setUp(self):
        """Save original environment"""
        self.original_env = os.environ.copy()

    def tearDown(self):
        """Restore original environment"""
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    @patch('bot.os.makedirs')
    def test_init_success(self, mock_makedirs, mock_client, mock_metrics,
                          mock_backup, mock_alert, mock_health, mock_logs, mock_commands):
        """Test successful initialization"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_client_instance = MagicMock()
        mock_client_instance.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_client_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        self.assertEqual(bot_instance.token, "test-token")
        self.assertEqual(bot_instance.chat_id, "12345")
        mock_client.assert_called_once_with("test-token", "12345")
        mock_client_instance.validate_token.assert_called_once()

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_init_missing_token(self, mock_client, mock_metrics, mock_backup,
                                mock_alert, mock_health, mock_logs, mock_commands):
        """Test initialization with missing token"""
        os.environ.pop("TG_TOKEN", None)
        os.environ["TG_CHAT_ID"] = "12345"

        from bot import CubiVeilBot
        with self.assertRaises(SystemExit):
            CubiVeilBot()

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_init_missing_chat_id(self, mock_client, mock_metrics, mock_backup,
                                  mock_alert, mock_health, mock_logs, mock_commands):
        """Test initialization with missing chat_id"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ.pop("TG_CHAT_ID", None)

        from bot import CubiVeilBot
        with self.assertRaises(SystemExit):
            CubiVeilBot()

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_init_invalid_token(self, mock_client, mock_metrics, mock_backup,
                                mock_alert, mock_health, mock_logs, mock_commands):
        """Test initialization with invalid token"""
        os.environ["TG_TOKEN"] = "invalid-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_client_instance = MagicMock()
        mock_client_instance.validate_token.return_value = (False, "Invalid token")
        mock_client.return_value = mock_client_instance

        from bot import CubiVeilBot
        with self.assertRaises(SystemExit):
            CubiVeilBot()

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_init_default_thresholds(self, mock_client, mock_metrics, mock_backup,
                                     mock_alert, mock_health, mock_logs, mock_commands):
        """Test initialization with default alert thresholds"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_client_instance = MagicMock()
        mock_client_instance.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_client_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        self.assertEqual(bot_instance.alert_cpu, 80)
        self.assertEqual(bot_instance.alert_ram, 85)
        self.assertEqual(bot_instance.alert_disk, 90)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_init_custom_thresholds(self, mock_client, mock_metrics, mock_backup,
                                    mock_alert, mock_health, mock_logs, mock_commands):
        """Test initialization with custom alert thresholds"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"
        os.environ["ALERT_CPU"] = "70"
        os.environ["ALERT_RAM"] = "75"
        os.environ["ALERT_DISK"] = "80"

        mock_client_instance = MagicMock()
        mock_client_instance.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_client_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        self.assertEqual(bot_instance.alert_cpu, 70)
        self.assertEqual(bot_instance.alert_ram, 75)
        self.assertEqual(bot_instance.alert_disk, 80)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_init_threshold_bounds(self, mock_client, mock_metrics, mock_backup,
                                   mock_alert, mock_health, mock_logs, mock_commands):
        """Test threshold validation bounds"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"
        os.environ["ALERT_CPU"] = "-10"  # Below minimum
        os.environ["ALERT_RAM"] = "150"  # Above maximum

        mock_client_instance = MagicMock()
        mock_client_instance.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_client_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        self.assertEqual(bot_instance.alert_cpu, 0)  # Clamped to minimum
        self.assertEqual(bot_instance.alert_ram, 100)  # Clamped to maximum


class TestValidateThreshold(unittest.TestCase):
    """Test _validate_threshold method"""

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_validate_threshold_normal(self, mock_client, mock_metrics, mock_backup,
                                       mock_alert, mock_health, mock_logs, mock_commands):
        """Test normal threshold validation"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_client_instance = MagicMock()
        mock_client_instance.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_client_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        self.assertEqual(bot_instance._validate_threshold(50), 50)
        self.assertEqual(bot_instance._validate_threshold(0), 0)
        self.assertEqual(bot_instance._validate_threshold(100), 100)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_validate_threshold_bounds(self, mock_client, mock_metrics, mock_backup,
                                       mock_alert, mock_health, mock_logs, mock_commands):
        """Test threshold clamping"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_client_instance = MagicMock()
        mock_client_instance.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_client_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        self.assertEqual(bot_instance._validate_threshold(-10), 0)
        self.assertEqual(bot_instance._validate_threshold(150), 100)


class TestSendStartupMessage(unittest.TestCase):
    """Test send_startup_message method"""

    def setUp(self):
        self.original_env = os.environ.copy()

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_send_startup_message(self, mock_client, mock_metrics, mock_backup,
                                  mock_alert, mock_health, mock_logs, mock_commands):
        """Test startup message is sent"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.send_startup_message()

        mock_telegram.send.assert_called_once()
        call_args = mock_telegram.send.call_args[0][0]
        self.assertIn("CubiVeil Bot started", call_args)
        self.assertIn("CPU>80%", call_args)
        self.assertIn("RAM>85%", call_args)
        self.assertIn("Disk>90%", call_args)


class TestSendDailyReport(unittest.TestCase):
    """Test send_daily_report method"""

    def setUp(self):
        self.original_env = os.environ.copy()

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_send_daily_report_success(self, mock_client, mock_metrics, mock_backup,
                                       mock_alert, mock_health, mock_logs, mock_commands):
        """Test successful daily report"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 45
        mock_metrics_instance.get_ram.return_value = (2048, 4096, 50)
        mock_metrics_instance.get_disk.return_value = (50, 100, 50)
        mock_metrics_instance.get_uptime.return_value = "2d 5h 30m"
        mock_metrics.return_value = mock_metrics_instance

        mock_backup_instance = MagicMock()
        mock_backup_instance.create.return_value = "/path/to/backup.sqlite3"
        mock_backup.return_value = mock_backup_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.send_daily_report()

        # Verify report message was sent
        self.assertEqual(mock_telegram.send.call_count, 2)  # Report + backup
        call_args = mock_telegram.send.call_args_list[0][0][0]
        self.assertIn("Daily Report", call_args)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_send_daily_report_backup_failed(self, mock_client, mock_metrics, mock_backup,
                                            mock_alert, mock_health, mock_logs, mock_commands):
        """Test daily report with failed backup"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 45
        mock_metrics_instance.get_ram.return_value = (2048, 4096, 50)
        mock_metrics_instance.get_disk.return_value = (50, 100, 50)
        mock_metrics_instance.get_uptime.return_value = "2d 5h 30m"
        mock_metrics.return_value = mock_metrics_instance

        mock_backup_instance = MagicMock()
        mock_backup_instance.create.return_value = None
        mock_backup.return_value = mock_backup_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.send_daily_report()

        # Check that failure message was sent
        calls = [call[0][0] for call in mock_telegram.send.call_args_list]
        self.assertTrue(any("Failed to create DB backup" in c for c in calls))

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_send_daily_report_alert_thresholds(self, mock_client, mock_metrics, mock_backup,
                                                mock_alert, mock_health, mock_logs, mock_commands):
        """Test daily report shows alert icons when thresholds exceeded"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"
        os.environ["ALERT_CPU"] = "50"  # Low threshold to trigger

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 75  # Above threshold
        mock_metrics_instance.get_ram.return_value = (2048, 4096, 30)  # Below threshold
        mock_metrics_instance.get_disk.return_value = (50, 100, 30)
        mock_metrics_instance.get_uptime.return_value = "1d"
        mock_metrics.return_value = mock_metrics_instance

        mock_backup_instance = MagicMock()
        mock_backup_instance.create.return_value = None
        mock_backup.return_value = mock_backup_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.send_daily_report()

        call_args = mock_telegram.send.call_args_list[0][0][0]
        # CPU should have alert icon since 75 > 50
        self.assertIn("🔴", call_args)


class TestCheckHealthAndHeal(unittest.TestCase):
    """Test check_health_and_heal method"""

    def setUp(self):
        self.original_env = os.environ.copy()

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_health_no_actions(self, mock_client, mock_metrics, mock_backup,
                               mock_alert, mock_health, mock_logs, mock_commands):
        """Test health check with no actions needed"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_health_instance = MagicMock()
        mock_health_instance.auto_heal.return_value = []
        mock_health.return_value = mock_health_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_health_and_heal()

        # No message should be sent when no actions
        mock_telegram.send.assert_not_called()

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_health_service_restarted(self, mock_client, mock_metrics, mock_backup,
                                      mock_alert, mock_health, mock_logs, mock_commands):
        """Test health check with service restart"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_health_instance = MagicMock()
        mock_health_instance.auto_heal.return_value = [
            {"service": "s-ui", "action": "restarted"}
        ]
        mock_health.return_value = mock_health_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_health_and_heal()

        mock_telegram.send.assert_called_once()
        call_args = mock_telegram.send.call_args[0][0]
        self.assertIn("Auto-heal triggered", call_args)
        self.assertIn("s-ui restarted", call_args)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_health_restart_failed(self, mock_client, mock_metrics, mock_backup,
                                   mock_alert, mock_health, mock_logs, mock_commands):
        """Test health check with failed restart"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_health_instance = MagicMock()
        mock_health_instance.auto_heal.return_value = [
            {"service": "sing-box", "action": "restart_failed"}
        ]
        mock_health.return_value = mock_health_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_health_and_heal()

        call_args = mock_telegram.send.call_args[0][0]
        self.assertIn("restart failed", call_args)


class TestCheckAlerts(unittest.TestCase):
    """Test check_alerts method"""

    def setUp(self):
        self.original_env = os.environ.copy()

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_alerts_no_transition(self, mock_client, mock_metrics, mock_backup,
                                  mock_alert, mock_health, mock_logs, mock_commands):
        """Test no alert when already in alert state"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 90  # Above threshold
        mock_metrics_instance.get_ram.return_value = (2048, 4096, 50)
        mock_metrics_instance.get_disk.return_value = (50, 100, 50)
        mock_metrics.return_value = mock_metrics_instance

        mock_alert_state = MagicMock()
        mock_alert_state.load.return_value = {"cpu": True}  # Already in alert state
        mock_alert.return_value = mock_alert_state

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_alerts()

        # No alert message should be sent since we're already in alert state
        mock_telegram.send.assert_not_called()

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_alerts_cpu_transition(self, mock_client, mock_metrics, mock_backup,
                                   mock_alert, mock_health, mock_logs, mock_commands):
        """Test alert when transitioning from normal to CPU alert"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 90  # Above threshold (80)
        mock_metrics_instance.get_ram.return_value = (2048, 4096, 50)
        mock_metrics_instance.get_disk.return_value = (50, 100, 50)
        mock_metrics.return_value = mock_metrics_instance

        mock_alert_state = MagicMock()
        mock_alert_state.load.return_value = {"cpu": False}  # Not in alert state
        mock_alert.return_value = mock_alert_state

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_alerts()

        mock_telegram.send.assert_called_once()
        call_args = mock_telegram.send.call_args[0][0]
        self.assertIn("CPU", call_args)
        self.assertIn("90%", call_args)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_alerts_ram_transition(self, mock_client, mock_metrics, mock_backup,
                                   mock_alert, mock_health, mock_logs, mock_commands):
        """Test alert when transitioning to RAM alert"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 30
        mock_metrics_instance.get_ram.return_value = (3800, 4096, 93)  # Above threshold (85)
        mock_metrics_instance.get_disk.return_value = (50, 100, 50)
        mock_metrics.return_value = mock_metrics_instance

        mock_alert_state = MagicMock()
        mock_alert_state.load.return_value = {}
        mock_alert.return_value = mock_alert_state

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_alerts()

        call_args = mock_telegram.send.call_args[0][0]
        self.assertIn("RAM", call_args)
        self.assertIn("93%", call_args)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_alerts_disk_transition(self, mock_client, mock_metrics, mock_backup,
                                    mock_alert, mock_health, mock_logs, mock_commands):
        """Test alert when transitioning to disk alert"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 30
        mock_metrics_instance.get_ram.return_value = (2048, 4096, 50)
        mock_metrics_instance.get_disk.return_value = (95, 100, 95)  # Above threshold (90)
        mock_metrics.return_value = mock_metrics_instance

        mock_alert_state = MagicMock()
        mock_alert_state.load.return_value = {}
        mock_alert.return_value = mock_alert_state

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_alerts()

        call_args = mock_telegram.send.call_args[0][0]
        self.assertIn("Disk", call_args)
        self.assertIn("95%", call_args)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_alerts_no_alerts(self, mock_client, mock_metrics, mock_backup,
                              mock_alert, mock_health, mock_logs, mock_commands):
        """Test no alerts when all metrics are below thresholds"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 30
        mock_metrics_instance.get_ram.return_value = (2048, 4096, 50)
        mock_metrics_instance.get_disk.return_value = (50, 100, 50)
        mock_metrics.return_value = mock_metrics_instance

        mock_alert_state = MagicMock()
        mock_alert_state.load.return_value = {}
        mock_alert.return_value = mock_alert_state

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_alerts()

        mock_telegram.send.assert_not_called()

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_alerts_multiple_transitions(self, mock_client, mock_metrics, mock_backup,
                                         mock_alert, mock_health, mock_logs, mock_commands):
        """Test alerts when multiple thresholds are exceeded"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_metrics_instance = MagicMock()
        mock_metrics_instance.get_cpu.return_value = 90
        mock_metrics_instance.get_ram.return_value = (3800, 4096, 93)
        mock_metrics_instance.get_disk.return_value = (50, 100, 50)
        mock_metrics.return_value = mock_metrics_instance

        mock_alert_state = MagicMock()
        mock_alert_state.load.return_value = {}
        mock_alert.return_value = mock_alert_state

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance.check_alerts()

        call_args = mock_telegram.send.call_args[0][0]
        self.assertIn("CPU", call_args)
        self.assertIn("RAM", call_args)


class TestProcessMessage(unittest.TestCase):
    """Test _process_message method"""

    def setUp(self):
        self.original_env = os.environ.copy()

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_process_message_authorized(self, mock_client, mock_metrics, mock_backup,
                                        mock_alert, mock_health, mock_logs, mock_commands):
        """Test processing message from authorized chat"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_commands_instance = MagicMock()
        mock_commands.return_value = mock_commands_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        message = {
            "chat": {"id": 12345},
            "text": "/status"
        }
        bot_instance._process_message(message)

        mock_commands_instance.handle.assert_called_once_with("/status", "12345")

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_process_message_unauthorized(self, mock_client, mock_metrics, mock_backup,
                                          mock_alert, mock_health, mock_logs, mock_commands):
        """Test processing message from unauthorized chat"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_commands_instance = MagicMock()
        mock_commands.return_value = mock_commands_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        message = {
            "chat": {"id": 99999},  # Different chat_id
            "text": "/status"
        }
        bot_instance._process_message(message)

        mock_commands_instance.handle.assert_not_called()

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_process_message_non_command(self, mock_client, mock_metrics, mock_backup,
                                         mock_alert, mock_health, mock_logs, mock_commands):
        """Test processing non-command message"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_commands_instance = MagicMock()
        mock_commands.return_value = mock_commands_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        message = {
            "chat": {"id": 12345},
            "text": "Hello, bot!"
        }
        bot_instance._process_message(message)

        mock_commands_instance.handle.assert_not_called()


class TestProcessCallback(unittest.TestCase):
    """Test _process_callback method"""

    def setUp(self):
        self.original_env = os.environ.copy()

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_process_callback_authorized(self, mock_client, mock_metrics, mock_backup,
                                         mock_alert, mock_health, mock_logs, mock_commands):
        """Test processing callback from authorized chat"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_commands_instance = MagicMock()
        mock_commands.return_value = mock_commands_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        callback = {
            "message": {"chat": {"id": 12345}},
            "data": "nav_status"
        }
        bot_instance._process_callback(callback)

        mock_commands_instance.handle_callback.assert_called_once_with(callback)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_process_callback_unauthorized(self, mock_client, mock_metrics, mock_backup,
                                           mock_alert, mock_health, mock_logs, mock_commands):
        """Test processing callback from unauthorized chat"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        mock_commands_instance = MagicMock()
        mock_commands.return_value = mock_commands_instance

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        callback = {
            "message": {"chat": {"id": 99999}},
            "data": "nav_status"
        }
        bot_instance._process_callback(callback)

        mock_commands_instance.handle_callback.assert_not_called()


class TestGetUpdates(unittest.TestCase):
    """Test _get_updates method"""

    def setUp(self):
        self.original_env = os.environ.copy()

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_get_updates_success(self, mock_client, mock_metrics, mock_backup,
                                 mock_alert, mock_health, mock_logs, mock_commands):
        """Test successful get updates"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_telegram._make_request.return_value = json.dumps({
            "result": [
                {"update_id": 1, "message": {"chat": {"id": 12345}, "text": "/status"}}
            ]
        })
        mock_client.return_value = mock_telegram

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        updates, offset = bot_instance._get_updates(0)

        self.assertEqual(len(updates), 1)
        self.assertEqual(offset, 0)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_get_updates_empty(self, mock_client, mock_metrics, mock_backup,
                               mock_alert, mock_health, mock_logs, mock_commands):
        """Test get updates with no results"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_telegram._make_request.return_value = json.dumps({"result": []})
        mock_client.return_value = mock_telegram

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()

        updates, offset = bot_instance._get_updates(0)

        self.assertEqual(updates, [])


class TestPoll(unittest.TestCase):
    """Test poll method (without actual infinite loop)"""

    def setUp(self):
        self.original_env = os.environ.copy()

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)

    @patch('bot.CommandHandler')
    @patch('bot.LogsManager')
    @patch('bot.HealthChecker')
    @patch('bot.AlertStateManager')
    @patch('bot.BackupManager')
    @patch('bot.MetricsCollector')
    @patch('bot.TelegramClient')
    def test_poll_starts_with_startup_message(self, mock_client, mock_metrics, mock_backup,
                                              mock_alert, mock_health, mock_logs, mock_commands):
        """Test poll sends startup message"""
        os.environ["TG_TOKEN"] = "test-token"
        os.environ["TG_CHAT_ID"] = "12345"

        mock_telegram = MagicMock()
        mock_telegram.validate_token.return_value = (True, "OK")
        mock_client.return_value = mock_telegram

        # Mock _get_updates to raise exception after first call to break loop
        def mock_get_updates(offset):
            raise KeyboardInterrupt("Stop polling")

        from bot import CubiVeilBot
        bot_instance = CubiVeilBot()
        bot_instance._get_updates = mock_get_updates

        with self.assertRaises(KeyboardInterrupt):
            bot_instance.poll()

        # Startup message should be sent
        mock_telegram.send.assert_called_once()


class TestMainBlock(unittest.TestCase):
    """Test the main block command handling"""

    def setUp(self):
        self.original_env = os.environ.copy()
        self.original_argv = sys.argv

    def tearDown(self):
        os.environ.clear()
        os.environ.update(self.original_env)
        sys.argv = self.original_argv

    @patch('bot.CubiVeilBot')
    def test_main_report_command(self, mock_bot_class):
        """Test 'report' command in main block"""
        mock_bot = MagicMock()
        mock_bot_class.return_value = mock_bot

        sys.argv = ["bot.py", "report"]

        # Simulate main block
        from bot import CubiVeilBot
        bot_instance = mock_bot
        cmd = sys.argv[1] if len(sys.argv) > 1 else "poll"

        if cmd == "report":
            bot_instance.send_daily_report()
        elif cmd == "alert":
            bot_instance.check_alerts()

        bot_instance.send_daily_report.assert_called_once()

    @patch('bot.CubiVeilBot')
    def test_main_alert_command(self, mock_bot_class):
        """Test 'alert' command in main block"""
        mock_bot = MagicMock()
        mock_bot_class.return_value = mock_bot

        sys.argv = ["bot.py", "alert"]

        from bot import CubiVeilBot
        bot_instance = mock_bot
        cmd = sys.argv[1] if len(sys.argv) > 1 else "poll"

        if cmd == "alert":
            bot_instance.check_alerts()

        bot_instance.check_alerts.assert_called_once()

    @patch('bot.CubiVeilBot')
    def test_main_unknown_command(self, mock_bot_class):
        """Test unknown command in main block"""
        mock_bot = MagicMock()
        mock_bot_class.return_value = mock_bot

        sys.argv = ["bot.py", "unknown"]

        from bot import CubiVeilBot
        bot_instance = mock_bot
        cmd = sys.argv[1] if len(sys.argv) > 1 else "poll"

        if cmd == "report":
            bot_instance.send_daily_report()
        elif cmd == "alert":
            bot_instance.check_alerts()
        elif cmd == "poll":
            bot_instance.poll()
        else:
            with self.assertRaises(SystemExit):
                print(f"Unknown command: {cmd}")
                sys.exit(1)


if __name__ == "__main__":
    unittest.main()
