#!/usr/bin/env python3
"""
Tests for Telegram Bot Health Check Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, mock_open
import tempfile
import shutil
import subprocess
import json

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from health_check import HealthChecker, HealthCheckError
from constants import (
    MONITORED_SERVICES,
    DEFAULT_CONNECTION_TARGETS,
    DEFAULT_HEALTH_CHECK_PORT,
    RESTART_COOLDOWN,
)


class TestHealthCheckerInit(unittest.TestCase):
    """Test HealthChecker initialization"""

    @patch('health_check.HealthChecker._get_health_check_port')
    def test_initialization_default_port(self, mock_get_port):
        """Test initialization with default port"""
        mock_get_port.return_value = 2095
        checker = HealthChecker()
        self.assertEqual(checker.health_check_port, 2095)
        self.assertEqual(checker.restart_cooldown, RESTART_COOLDOWN)
        self.assertEqual(checker.last_restart_time, {})

    def test_initialization_custom_port(self):
        """Test initialization with custom port"""
        checker = HealthChecker(health_check_port=3000)
        self.assertEqual(checker.health_check_port, 3000)


class TestGetHealthCheckPort(unittest.TestCase):
    """Test _get_health_check_port method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.env_file = os.path.join(self.test_dir, "s-ui.credentials")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch('health_check.SUI_ENV_FILE')
    def test_get_port_from_env(self, mock_env_file):
        """Test getting port from environment file"""
        mock_env_file.return_value = self.env_file
        with open(self.env_file, 'w') as f:
            f.write("SUI_PANEL_PORT=3095\n")

        checker = HealthChecker.__new__(HealthChecker)
        port = checker._get_health_check_port()
        self.assertEqual(port, 3095)

    @patch('health_check.SUI_ENV_FILE')
    def test_get_port_default_fallback(self, mock_env_file):
        """Test default port when env file missing"""
        mock_env_file.return_value = "/nonexistent/file"

        checker = HealthChecker.__new__(HealthChecker)
        port = checker._get_health_check_port()
        self.assertEqual(port, DEFAULT_HEALTH_CHECK_PORT)


class TestCheckConnectionSpeed(unittest.TestCase):
    """Test check_connection_speed method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)

    @patch('health_check.subprocess.run')
    def test_connection_success(self, mock_run):
        """Test successful connection"""
        mock_run.return_value = MagicMock(returncode=0)

        result = self.checker.check_connection_speed("https://example.com")

        self.assertTrue(result["success"])
        self.assertIsNotNone(result["latency_ms"])
        self.assertIsNone(result["error"])
        self.assertEqual(result["target"], "https://example.com")

    @patch('health_check.subprocess.run')
    def test_connection_timeout(self, mock_run):
        """Test connection timeout"""
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=["curl"], timeout=10)

        result = self.checker.check_connection_speed("https://example.com")

        self.assertFalse(result["success"])
        self.assertIsNone(result["latency_ms"])
        self.assertIsNotNone(result["error"])
        self.assertIn("Timeout", result["error"])

    @patch('health_check.subprocess.run')
    def test_connection_failed(self, mock_run):
        """Test failed connection"""
        mock_run.side_effect = subprocess.CalledProcessError(
            returncode=7, cmd=["curl"]
        )

        result = self.checker.check_connection_speed("https://example.com")

        self.assertFalse(result["success"])
        self.assertIsNone(result["latency_ms"])
        self.assertIn("Connection failed", result["error"])

    @patch('health_check.subprocess.run')
    def test_curl_not_found(self, mock_run):
        """Test curl not found"""
        mock_run.side_effect = FileNotFoundError()

        result = self.checker.check_connection_speed("https://example.com")

        self.assertFalse(result["success"])
        self.assertEqual(result["error"], "curl not installed")

    @patch('health_check.subprocess.run')
    def test_unexpected_error(self, mock_run):
        """Test unexpected error"""
        mock_run.side_effect = Exception("Unknown error")

        result = self.checker.check_connection_speed("https://example.com")

        self.assertFalse(result["success"])
        self.assertEqual(result["error"], "Unknown error")


class TestCheckProfileStatus(unittest.TestCase):
    """Test check_profile_status method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)
        self.test_dir = tempfile.mkdtemp()
        self.db_file = os.path.join(self.test_dir, "s-ui.db")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch('health_check.SUI_DB_FILE')
    def test_profile_not_found_db_missing(self, mock_db_file):
        """Test profile check when DB is missing"""
        mock_db_file.return_value = "/nonexistent/db.sqlite"

        result = self.checker.check_profile_status("testuser")

        self.assertEqual(result["status"], "unknown")
        self.assertEqual(result["error"], "Database not found")

    @patch('health_check.SUI_DB_FILE')
    def test_profile_active(self, mock_db_file):
        """Test active profile"""
        mock_db_file.return_value = self.db_file

        import sqlite3
        conn = sqlite3.connect(self.db_file)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE clients (
                email TEXT,
                enable INTEGER,
                up INTEGER,
                down INTEGER,
                total INTEGER,
                expiry_time INTEGER
            )
        """)
        cur.execute(
            "INSERT INTO clients VALUES (?, ?, ?, ?, ?, ?)",
            ("testuser", 1, 1000, 2000, 10000, 1234567890)
        )
        conn.commit()
        conn.close()

        result = self.checker.check_profile_status("testuser")

        self.assertEqual(result["status"], "active")
        self.assertEqual(result["used_traffic"], 3000)
        self.assertEqual(result["data_limit"], 10000)
        self.assertEqual(result["expiry"], 1234567890)

    @patch('health_check.SUI_DB_FILE')
    def test_profile_disabled(self, mock_db_file):
        """Test disabled profile"""
        mock_db_file.return_value = self.db_file

        import sqlite3
        conn = sqlite3.connect(self.db_file)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE clients (
                email TEXT,
                enable INTEGER,
                up INTEGER,
                down INTEGER,
                total INTEGER,
                expiry_time INTEGER
            )
        """)
        cur.execute(
            "INSERT INTO clients VALUES (?, ?, ?, ?, ?, ?)",
            ("testuser", 0, 0, 0, 5000, 1234567890)
        )
        conn.commit()
        conn.close()

        result = self.checker.check_profile_status("testuser")

        self.assertEqual(result["status"], "disabled")

    @patch('health_check.SUI_DB_FILE')
    def test_profile_user_not_found(self, mock_db_file):
        """Test user not found in DB"""
        mock_db_file.return_value = self.db_file

        import sqlite3
        conn = sqlite3.connect(self.db_file)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE clients (
                email TEXT,
                enable INTEGER,
                up INTEGER,
                down INTEGER,
                total INTEGER,
                expiry_time INTEGER
            )
        """)
        conn.commit()
        conn.close()

        result = self.checker.check_profile_status("nonexistent")

        self.assertEqual(result["error"], "User not found")

    @patch('health_check.SUI_DB_FILE')
    def test_profile_db_error(self, mock_db_file):
        """Test database error"""
        mock_db_file.return_value = self.db_file

        with patch('sqlite3.connect') as mock_connect:
            mock_connect.side_effect = sqlite3.Error("DB error")

            result = self.checker.check_profile_status("testuser")

            self.assertIn("Database error", result["error"])


class TestCheckAllProfiles(unittest.TestCase):
    """Test check_all_profiles method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)
        self.test_dir = tempfile.mkdtemp()
        self.db_file = os.path.join(self.test_dir, "s-ui.db")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch('health_check.SUI_DB_FILE')
    def test_all_profiles_empty_db(self, mock_db_file):
        """Test empty database"""
        mock_db_file.return_value = self.db_file

        import sqlite3
        conn = sqlite3.connect(self.db_file)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE clients (
                email TEXT,
                enable INTEGER,
                up INTEGER,
                down INTEGER,
                total INTEGER,
                expiry_time INTEGER
            )
        """)
        conn.commit()
        conn.close()

        profiles = self.checker.check_all_profiles()
        self.assertEqual(len(profiles), 0)

    @patch('health_check.SUI_DB_FILE')
    def test_all_profiles_multiple(self, mock_db_file):
        """Test multiple profiles"""
        mock_db_file.return_value = self.db_file

        import sqlite3
        conn = sqlite3.connect(self.db_file)
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE clients (
                email TEXT,
                enable INTEGER,
                up INTEGER,
                down INTEGER,
                total INTEGER,
                expiry_time INTEGER
            )
        """)
        cur.execute(
            "INSERT INTO clients VALUES (?, ?, ?, ?, ?, ?)",
            ("user1", 1, 100, 200, 1000, 1234567890)
        )
        cur.execute(
            "INSERT INTO clients VALUES (?, ?, ?, ?, ?, ?)",
            ("user2", 0, 0, 0, 500, 1234567891)
        )
        conn.commit()
        conn.close()

        profiles = self.checker.check_all_profiles()

        self.assertEqual(len(profiles), 2)
        self.assertEqual(profiles[0]["username"], "user1")
        self.assertEqual(profiles[0]["status"], "active")
        self.assertEqual(profiles[1]["username"], "user2")
        self.assertEqual(profiles[1]["status"], "disabled")

    @patch('health_check.SUI_DB_FILE')
    def test_all_profiles_db_missing(self, mock_db_file):
        """Test missing DB"""
        mock_db_file.return_value = "/nonexistent/db.sqlite"

        profiles = self.checker.check_all_profiles()
        self.assertEqual(profiles, [])


class TestCheckServiceHealth(unittest.TestCase):
    """Test check_service_health method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)

    @patch('health_check.subprocess.run')
    def test_service_active_and_running(self, mock_run):
        """Test service is active and running"""
        mock_run.side_effect = [
            MagicMock(returncode=0, stdout="active"),
            MagicMock(returncode=0, stdout="running"),
        ]

        result = self.checker.check_service_health("s-ui")

        self.assertTrue(result["active"])
        self.assertTrue(result["running"])
        self.assertIsNone(result["error"])

    @patch('health_check.subprocess.run')
    def test_service_inactive(self, mock_run):
        """Test service is inactive"""
        mock_run.side_effect = [
            MagicMock(returncode=3, stdout="inactive"),
            MagicMock(returncode=3, stdout="inactive"),
        ]

        result = self.checker.check_service_health("s-ui")

        self.assertFalse(result["active"])
        self.assertFalse(result["running"])

    @patch('health_check.subprocess.run')
    def test_service_check_timeout(self, mock_run):
        """Test service check timeout"""
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=["systemctl"], timeout=10)

        result = self.checker.check_service_health("s-ui")

        self.assertFalse(result["active"])
        self.assertEqual(result["error"], "Timeout checking service")

    @patch('health_check.subprocess.run')
    def test_systemctl_not_found(self, mock_run):
        """Test systemctl not found"""
        mock_run.side_effect = FileNotFoundError()

        result = self.checker.check_service_health("s-ui")

        self.assertFalse(result["active"])
        self.assertEqual(result["error"], "systemctl not available")


class TestCheckHealthEndpoint(unittest.TestCase):
    """Test check_health_endpoint method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)

    @patch('health_check.subprocess.run')
    def test_health_endpoint_healthy(self, mock_run):
        """Test healthy endpoint"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({"success": True, "data": {}})
        )

        result = self.checker.check_health_endpoint()

        self.assertEqual(result["status"], "healthy")
        self.assertEqual(result["s-ui"], "running")
        self.assertIsNone(result["error"])

    @patch('health_check.subprocess.run')
    def test_health_endpoint_unhealthy(self, mock_run):
        """Test unhealthy endpoint"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({"success": False})
        )

        result = self.checker.check_health_endpoint()

        self.assertEqual(result["status"], "unhealthy")

    @patch('health_check.subprocess.run')
    def test_health_endpoint_invalid_json(self, mock_run):
        """Test invalid JSON response"""
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="not json"
        )

        result = self.checker.check_health_endpoint()

        self.assertEqual(result["status"], "invalid_response")
        self.assertIn("Invalid JSON", result["error"])

    @patch('health_check.subprocess.run')
    def test_health_endpoint_unreachable(self, mock_run):
        """Test unreachable endpoint"""
        mock_run.side_effect = subprocess.CalledProcessError(
            returncode=7, cmd=["curl"]
        )

        result = self.checker.check_health_endpoint()

        self.assertEqual(result["status"], "unreachable")

    @patch('health_check.subprocess.run')
    def test_health_endpoint_timeout(self, mock_run):
        """Test endpoint timeout"""
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=["curl"], timeout=10)

        result = self.checker.check_health_endpoint()

        self.assertIn("Timeout", result["error"])

    @patch('health_check.subprocess.run')
    def test_health_endpoint_curl_not_found(self, mock_run):
        """Test curl not found"""
        mock_run.side_effect = FileNotFoundError()

        result = self.checker.check_health_endpoint()

        self.assertEqual(result["error"], "curl not installed")


class TestRestartService(unittest.TestCase):
    """Test restart_service method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)

    @patch('health_check.subprocess.run')
    def test_restart_success(self, mock_run):
        """Test successful service restart"""
        mock_run.side_effect = [
            None,  # systemctl restart - success
            MagicMock(returncode=0, stdout="active"),  # systemctl is-active
        ]

        with patch('health_check.time.sleep'):
            result = self.checker.restart_service("s-ui", force=True)

        self.assertTrue(result)

    @patch('health_check.subprocess.run')
    def test_restart_failed(self, mock_run):
        """Test failed service restart"""
        mock_run.side_effect = [
            None,  # systemctl restart - success
            MagicMock(returncode=3, stdout="inactive"),  # systemctl is-active - failed
        ]

        with patch('health_check.time.sleep'):
            result = self.checker.restart_service("s-ui", force=True)

        self.assertFalse(result)

    @patch('health_check.time.time')
    def test_restart_cooldown(self, mock_time):
        """Test restart cooldown"""
        mock_time.return_value = 100
        self.checker.last_restart_time["s-ui"] = 90
        self.checker.restart_cooldown = 300

        result = self.checker.restart_service("s-ui")
        self.assertFalse(result)

    @patch('health_check.subprocess.run')
    def test_restart_timeout(self, mock_run):
        """Test restart timeout"""
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=["systemctl"], timeout=60)

        result = self.checker.restart_service("s-ui", force=True)
        self.assertFalse(result)

    @patch('health_check.subprocess.run')
    def test_restart_called_process_error(self, mock_run):
        """Test restart CalledProcessError"""
        mock_run.side_effect = subprocess.CalledProcessError(
            returncode=1, cmd=["systemctl"]
        )

        result = self.checker.restart_service("s-ui", force=True)
        self.assertFalse(result)

    @patch('health_check.subprocess.run')
    def test_restart_file_not_found(self, mock_run):
        """Test systemctl not found during restart"""
        mock_run.side_effect = FileNotFoundError()

        result = self.checker.restart_service("s-ui", force=True)
        self.assertFalse(result)

    @patch('health_check.subprocess.run')
    def test_restart_unexpected_error(self, mock_run):
        """Test unexpected error during restart"""
        mock_run.side_effect = Exception("Unknown error")

        result = self.checker.restart_service("s-ui", force=True)
        self.assertFalse(result)


class TestAutoHeal(unittest.TestCase):
    """Test auto_heal method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)

    @patch.object(HealthChecker, 'restart_service')
    @patch.object(HealthChecker, 'check_service_health')
    def test_auto_heal_all_services_healthy(self, mock_health, mock_restart):
        """Test auto-heal when all services are healthy"""
        mock_health.return_value = {"active": True, "running": True}

        actions = self.checker.auto_heal()

        self.assertEqual(actions, [])
        mock_restart.assert_not_called()

    @patch.object(HealthChecker, 'restart_service')
    @patch.object(HealthChecker, 'check_service_health')
    def test_auto_heal_service_down_restart_success(self, mock_health, mock_restart):
        """Test auto-heal with successful restart"""
        mock_health.return_value = {"active": False, "running": False}
        mock_restart.return_value = True

        with patch('health_check.MONITORED_SERVICES', ["test-service"]):
            actions = self.checker.auto_heal()

        self.assertEqual(len(actions), 1)
        self.assertEqual(actions[0]["service"], "test-service")
        self.assertEqual(actions[0]["action"], "restarted")

    @patch.object(HealthChecker, 'restart_service')
    @patch.object(HealthChecker, 'check_service_health')
    def test_auto_heal_service_down_restart_failed(self, mock_health, mock_restart):
        """Test auto-heal with failed restart"""
        mock_health.return_value = {"active": False, "running": False}
        mock_restart.return_value = False

        with patch('health_check.MONITORED_SERVICES', ["test-service"]):
            actions = self.checker.auto_heal()

        self.assertEqual(len(actions), 1)
        self.assertEqual(actions[0]["action"], "restart_failed")


class TestFullHealthReport(unittest.TestCase):
    """Test get_full_health_report method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)

    @patch.object(HealthChecker, 'check_connection_speed')
    @patch.object(HealthChecker, 'check_all_profiles')
    @patch.object(HealthChecker, 'check_service_health')
    @patch.object(HealthChecker, 'check_health_endpoint')
    def test_get_full_health_report(
        self, mock_endpoint, mock_service, mock_profiles, mock_connection
    ):
        """Test full health report"""
        mock_endpoint.return_value = {"status": "healthy", "s-ui": "running", "error": None}
        mock_service.return_value = {"active": True, "running": True, "error": None}
        mock_profiles.return_value = [
            {"status": "active"},
            {"status": "disabled"},
        ]
        mock_connection.return_value = {"success": True, "latency_ms": 50, "error": None}

        with patch('health_check.MONITORED_SERVICES', ["s-ui"]):
            report = self.checker.get_full_health_report()

        self.assertIn("timestamp", report)
        self.assertIn("health_endpoint", report)
        self.assertIn("services", report)
        self.assertIn("profiles_summary", report)
        self.assertIn("connection", report)
        self.assertEqual(report["profiles_summary"]["total"], 2)
        self.assertEqual(report["profiles_summary"]["active"], 1)


class TestFormatHealthMessage(unittest.TestCase):
    """Test format_health_message method"""

    def setUp(self):
        self.checker = HealthChecker(health_check_port=2095)

    @patch.object(HealthChecker, 'get_full_health_report')
    def test_format_health_message_healthy(self, mock_report):
        """Test health message when everything is healthy"""
        mock_report.return_value = {
            "health_endpoint": {"status": "healthy", "error": None},
            "services": {
                "s-ui": {"active": True, "running": True},
                "cubiveil-bot": {"active": True, "running": True},
            },
            "profiles_summary": {
                "total": 2,
                "active": 2,
                "disabled": 0,
                "limited": 0,
                "expired": 0,
            },
            "connection": {
                "Google": {"success": True, "latency_ms": 50, "error": None},
            },
        }

        message = self.checker.format_health_message()

        self.assertIn("Health Check Report", message)
        self.assertIn("healthy", message)

    @patch.object(HealthChecker, 'get_full_health_report')
    def test_format_health_message_unhealthy(self, mock_report):
        """Test health message when services are unhealthy"""
        mock_report.return_value = {
            "health_endpoint": {"status": "unhealthy", "error": "Service down"},
            "services": {
                "s-ui": {"active": False, "running": False},
            },
            "profiles_summary": {
                "total": 1,
                "active": 0,
                "disabled": 1,
                "limited": 0,
                "expired": 0,
            },
            "connection": {
                "Google": {"success": False, "error": "Timeout"},
            },
        }

        message = self.checker.format_health_message()

        self.assertIn("unhealthy", message)
        self.assertIn("Service down", message)


if __name__ == "__main__":
    unittest.main()
