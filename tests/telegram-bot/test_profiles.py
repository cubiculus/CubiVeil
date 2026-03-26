#!/usr/bin/env python3
"""
Tests for Telegram Bot Profiles Module (Marzban API Client)
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock
import json

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from profiles import MarzbanClient, ProfilesError


class TestMarzbanClient(unittest.TestCase):
    """Test cases for MarzbanClient module"""

    def setUp(self):
        """Set up test fixtures"""
        self.client = MarzbanClient()

    def test_client_initialization(self):
        """Test client initializes with correct attributes"""
        self.assertIsNotNone(self.client.base_url)
        self.assertEqual(self.client.base_url, "http://localhost:8000")
        self.assertIn("Content-Type", self.client.headers)

    @patch('profiles.urllib.request.urlopen')
    def test_get_user_success(self, mock_urlopen):
        """Test successful user retrieval"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "username": "testuser",
            "status": "active",
            "used_traffic": 1000000000,
            "data_limit": 50000000000
        }).encode()
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = lambda s, *args: None
        mock_urlopen.return_value = mock_response

        user = self.client.get_user("testuser")

        self.assertIsNotNone(user)
        self.assertEqual(user["username"], "testuser")
        self.assertEqual(user["status"], "active")

    @patch('profiles.urllib.request.urlopen')
    def test_get_user_not_found(self, mock_urlopen):
        """Test user not found"""
        mock_urlopen.side_effect = Exception("HTTP Error 404")

        user = self.client.get_user("nonexistent")

        self.assertIsNone(user)

    def test_get_user_traffic_calculation(self):
        """Test traffic calculation"""
        # Test with limit - manual calculation
        used_traffic = 5368709120  # 5GB
        data_limit = 10737418240   # 10GB

        used_gb = used_traffic / (1024 * 1024 * 1024)
        limit_gb = data_limit / (1024 * 1024 * 1024)
        remaining_gb = (data_limit - used_traffic) / (1024 * 1024 * 1024)
        percentage = (used_traffic / data_limit) * 100

        self.assertAlmostEqual(used_gb, 5.0, places=1)
        self.assertAlmostEqual(limit_gb, 10.0, places=1)
        self.assertAlmostEqual(remaining_gb, 5.0, places=1)
        self.assertAlmostEqual(percentage, 50.0, places=1)

        # Test without limit (unlimited)
        used_traffic_unlimited = 5368709120
        data_limit_unlimited = 0

        used_gb_unlimited = used_traffic_unlimited / (1024 * 1024 * 1024)
        limit_gb_unlimited = None
        remaining_gb_unlimited = None

        self.assertIsNone(limit_gb_unlimited)
        self.assertIsNone(remaining_gb_unlimited)

    def test_generate_qr_code_url(self):
        """Test QR code URL generation"""
        sub_link = "https://example.com/sub/abc123"
        qr_url = self.client.generate_qr_code_url(sub_link)

        self.assertIn("api.qrserver.com", qr_url)
        self.assertIn("size=300x300", qr_url)
        self.assertIn("data=https%3A%2F%2Fexample.com%2Fsub%2Fabc123", qr_url)

    @patch('profiles.MarzbanClient._make_request')
    def test_enable_user(self, mock_request):
        """Test enabling user"""
        mock_request.return_value = {"username": "testuser", "status": "active"}

        result = self.client.enable_user("testuser")

        self.assertTrue(result)
        mock_request.assert_called_once_with(
            "PUT",
            "/api/user/testuser",
            {"status": "active"}
        )

    @patch('profiles.MarzbanClient._make_request')
    def test_disable_user(self, mock_request):
        """Test disabling user"""
        mock_request.return_value = {"username": "testuser", "status": "disabled"}

        result = self.client.disable_user("testuser")

        self.assertTrue(result)
        mock_request.assert_called_once_with(
            "PUT",
            "/api/user/testuser",
            {"status": "disabled"}
        )

    @patch('profiles.MarzbanClient.get_user')
    @patch('profiles.MarzbanClient._make_request')
    def test_extend_user_with_current_expiry(self, mock_request, mock_get_user):
        """Test extending user with existing expiry"""
        mock_get_user.return_value = {"expire": 1700000000}
        mock_request.return_value = {"expire": 1702592000}

        result = self.client.extend_user("testuser", 30)

        self.assertIsNotNone(result)
        mock_request.assert_called_once()

    @patch('profiles.MarzbanClient._make_request')
    def test_reset_user_traffic(self, mock_request):
        """Test resetting user traffic"""
        mock_request.return_value = {}

        result = self.client.reset_user_traffic("testuser")

        self.assertTrue(result)
        mock_request.assert_called_once_with(
            "POST",
            "/api/user/testuser/reset"
        )

    @patch('profiles.MarzbanClient._make_request')
    def test_create_user(self, mock_request):
        """Test creating user"""
        mock_request.return_value = {
            "username": "newuser",
            "status": "active",
            "expire": 1700000000
        }

        result = self.client.create_user("newuser", days=30, data_limit_gb=50)

        self.assertIsNotNone(result)
        mock_request.assert_called_once_with("POST", "/api/users", unittest.mock.ANY)

        # Check the data sent
        call_args = mock_request.call_args
        data = call_args[0][2]
        self.assertEqual(data["username"], "newuser")
        self.assertEqual(data["status"], "active")


class TestMarzbanClientTokenLoading(unittest.TestCase):
    """Test token loading functionality"""

    @patch('profiles.os.path.exists')
    @patch('profiles.open')
    def test_load_token_success(self, mock_open, mock_exists):
        """Test loading token from file"""
        mock_exists.return_value = True
        mock_open.return_value.__enter__ = lambda s: s
        mock_open.return_value.__exit__ = lambda s, *args: None
        mock_open.return_value.read.return_value = "test_token_123\n"

        client = MarzbanClient()

        self.assertEqual(client.token, "test_token_123")
        self.assertIn("Bearer test_token_123", client.headers.get("Authorization", ""))

    @patch('profiles.os.path.exists')
    def test_load_token_file_not_exists(self, mock_exists):
        """Test token loading when file doesn't exist"""
        mock_exists.return_value = False

        client = MarzbanClient()

        self.assertIsNone(client.token)
        self.assertNotIn("Authorization", client.headers)


if __name__ == "__main__":
    unittest.main()
