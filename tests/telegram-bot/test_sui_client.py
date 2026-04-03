#!/usr/bin/env python3
"""
Tests for Telegram Bot S-UI Client Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, mock_open
import tempfile
import shutil
import json
import urllib.error

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from sui_client import SuiClient, SuiClientError, DEFAULT_BASE_URL, DEFAULT_CREDENTIALS_PATH


class TestSuiClientInit(unittest.TestCase):
    """Test SuiClient initialization"""

    def test_initialization_defaults(self):
        """Test initialization with default values"""
        with patch('sui_client.os.path.exists', return_value=False):
            client = SuiClient()

        self.assertEqual(client.base_url, DEFAULT_BASE_URL)
        self.assertEqual(client.credentials_path, DEFAULT_CREDENTIALS_PATH)
        self.assertIsNone(client.token)
        self.assertIsNone(client.session_cookie)

    def test_initialization_custom(self):
        """Test initialization with custom values"""
        with patch('sui_client.os.path.exists', return_value=False):
            client = SuiClient(
                base_url="http://example.com:8080",
                credentials_path="/custom/path"
            )

        self.assertEqual(client.base_url, "http://example.com:8080")
        self.assertEqual(client.credentials_path, "/custom/path")

    def test_initialization_strips_trailing_slash(self):
        """Test that trailing slash is stripped from base URL"""
        with patch('sui_client.os.path.exists', return_value=False):
            client = SuiClient(base_url="http://example.com/")

        self.assertEqual(client.base_url, "http://example.com")


class TestLoadCredentials(unittest.TestCase):
    """Test _load_credentials method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_load_credentials_success(self):
        """Test successful credential load"""
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token-123\n")
            f.write("OTHER_VAR=value\n")

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient()

        self.assertEqual(client.token, "test-token-123")

    def test_load_credentials_file_not_found(self):
        """Test credentials file not found"""
        nonexistent = "/nonexistent/credentials"
        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', nonexistent):
            client = SuiClient()

        self.assertIsNone(client.token)

    def test_load_credentials_no_token(self):
        """Test credentials file without token"""
        with open(self.creds_file, 'w') as f:
            f.write("OTHER_VAR=value\n")

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient()

        self.assertIsNone(client.token)

    def test_load_credentials_exception(self):
        """Test exception during credential load"""
        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            with patch('builtins.open', side_effect=PermissionError("Access denied")):
                client = SuiClient()

        self.assertIsNone(client.token)


class TestMakeRequest(unittest.TestCase):
    """Test _make_request method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch('sui_client.urllib.request.urlopen')
    def test_get_request_success(self, mock_urlopen):
        """Test successful GET request"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"success": True, "obj": {"id": 1}}).encode()
        mock_urlopen.return_value.__enter__ = MagicMock(return_value=mock_response)
        mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._make_request("/api/user/list")

        self.assertIsNotNone(result)
        self.assertTrue(result["success"])

    @patch('sui_client.urllib.request.urlopen')
    def test_post_request_success(self, mock_urlopen):
        """Test successful POST request"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"success": True}).encode()
        mock_urlopen.return_value.__enter__ = MagicMock(return_value=mock_response)
        mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._make_request("/api/user/create", method="POST", data={"name": "test"})

        self.assertIsNotNone(result)
        self.assertTrue(result["success"])

    @patch('sui_client.urllib.request.urlopen')
    def test_request_with_token_auth(self, mock_urlopen):
        """Test request with token authentication"""
        mock_response = MagicMock()
        mock_response.read.return_value = b'{}'
        mock_urlopen.return_value.__enter__ = MagicMock(return_value=mock_response)
        mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")
            # Ensure token is set (in case credentials file loading differs)
            client.token = "test-token"
            client._make_request("/api/test", needs_auth=True)

        # Verify the request had the token header
        self.assertTrue(mock_urlopen.called, "urlopen should have been called")
        call_args = mock_urlopen.call_args[0][0]
        # Headers are case-insensitive and normalized by urllib
        headers = {k.lower(): v for k, v in call_args.headers.items()}
        self.assertEqual(headers.get("x-api-token"), "test-token")

    @patch('sui_client.urllib.request.urlopen')
    def test_request_with_session_cookie(self, mock_urlopen):
        """Test request with session cookie"""
        mock_response = MagicMock()
        mock_response.read.return_value = b'{}'
        mock_urlopen.return_value.__enter__ = MagicMock(return_value=mock_response)
        mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")
            client.session_cookie = "session-abc"
            client._make_request("/api/test", needs_auth=True)

        call_args = mock_urlopen.call_args[0][0]
        self.assertIn("session=session-abc", call_args.headers["Cookie"])

    def test_request_http_error(self):
        """Test HTTP error response"""
        error_response = MagicMock()
        error_response.read.return_value = b'{"error": "not found"}'

        with patch('sui_client.urllib.request.urlopen') as mock_urlopen:
            mock_urlopen.side_effect = urllib.error.HTTPError(
                url="http://localhost", code=404, msg="Not Found",
                hdrs={}, fp=error_response
            )

            with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
                client = SuiClient(base_url="http://localhost:2095")

            result = client._make_request("/api/nonexistent")
            self.assertIsNone(result)

    def test_request_url_error(self):
        """Test URL/network error"""
        with patch('sui_client.urllib.request.urlopen') as mock_urlopen:
            mock_urlopen.side_effect = urllib.error.URLError("Connection refused")

            with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
                client = SuiClient(base_url="http://localhost:2095")

            result = client._make_request("/api/test")
            self.assertIsNone(result)

    @patch('sui_client.urllib.request.urlopen')
    def test_request_json_decode_error(self, mock_urlopen):
        """Test JSON decode error"""
        mock_response = MagicMock()
        mock_response.read.return_value = b'not json'
        mock_urlopen.return_value.__enter__ = MagicMock(return_value=mock_response)
        mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._make_request("/api/test")
        self.assertIsNone(result)

    def test_request_exception(self):
        """Test unexpected exception"""
        with patch('sui_client.urllib.request.urlopen') as mock_urlopen:
            mock_urlopen.side_effect = Exception("Unknown error")

            with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
                client = SuiClient(base_url="http://localhost:2095")

            result = client._make_request("/api/test")
            self.assertIsNone(result)

    @patch('sui_client.urllib.request.urlopen')
    def test_request_no_auth(self, mock_urlopen):
        """Test request without authentication"""
        mock_response = MagicMock()
        mock_response.read.return_value = b'{}'
        mock_urlopen.return_value.__enter__ = MagicMock(return_value=mock_response)
        mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._make_request("/api/status", needs_auth=False)
        self.assertIsNotNone(result)

    @patch('sui_client.urllib.request.urlopen')
    def test_request_empty_response(self, mock_urlopen):
        """Test request with empty response"""
        mock_response = MagicMock()
        mock_response.read.return_value = b''
        mock_urlopen.return_value.__enter__ = MagicMock(return_value=mock_response)
        mock_urlopen.return_value.__exit__ = MagicMock(return_value=False)

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._make_request("/api/test")
        self.assertIsNone(result)


class TestHelperMethods(unittest.TestCase):
    """Test _get, _post, _put, _delete helper methods"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch.object(SuiClient, '_make_request')
    def test_get(self, mock_request):
        """Test GET helper"""
        mock_request.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._get("/api/test")
        mock_request.assert_called_once_with("/api/test", method="GET")
        self.assertTrue(result["success"])

    @patch.object(SuiClient, '_make_request')
    def test_post(self, mock_request):
        """Test POST helper"""
        mock_request.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._post("/api/test", {"key": "value"})
        mock_request.assert_called_once_with("/api/test", method="POST", data={"key": "value"})

    @patch.object(SuiClient, '_make_request')
    def test_put(self, mock_request):
        """Test PUT helper"""
        mock_request.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._put("/api/test", {"key": "value"})
        mock_request.assert_called_once_with("/api/test", method="PUT", data={"key": "value"})

    @patch.object(SuiClient, '_make_request')
    def test_delete(self, mock_request):
        """Test DELETE helper"""
        mock_request.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client._delete("/api/test")
        mock_request.assert_called_once_with("/api/test", method="DELETE")


class TestUserManagement(unittest.TestCase):
    """Test user management methods"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch.object(SuiClient, '_get')
    def test_get_user_success(self, mock_get):
        """Test successful get user"""
        mock_get.return_value = {"success": True, "obj": {"username": "testuser"}}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user("testuser")
        self.assertEqual(result["username"], "testuser")

    @patch.object(SuiClient, '_get')
    def test_get_user_not_found(self, mock_get):
        """Test user not found"""
        mock_get.return_value = {"success": False}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user("nonexistent")
        self.assertIsNone(result)

    @patch.object(SuiClient, '_get')
    def test_get_user_none_response(self, mock_get):
        """Test get user with None response"""
        mock_get.return_value = None

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user("testuser")
        self.assertIsNone(result)

    @patch.object(SuiClient, '_get')
    def test_list_users_success(self, mock_get):
        """Test successful list users"""
        mock_get.return_value = {
            "success": True,
            "obj": [
                {"username": "user1"},
                {"username": "user2"},
            ]
        }

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.list_users()
        self.assertEqual(len(result), 2)
        self.assertEqual(result[0]["username"], "user1")

    @patch.object(SuiClient, '_get')
    def test_list_users_empty(self, mock_get):
        """Test list users empty"""
        mock_get.return_value = {"success": True, "obj": []}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.list_users()
        self.assertEqual(result, [])

    @patch.object(SuiClient, '_get')
    def test_list_users_failed(self, mock_get):
        """Test list users failed"""
        mock_get.return_value = {"success": False}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.list_users()
        self.assertEqual(result, [])

    @patch.object(SuiClient, '_put')
    def test_enable_user_success(self, mock_put):
        """Test successful enable user"""
        mock_put.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.enable_user("testuser")
        self.assertTrue(result)

    @patch.object(SuiClient, '_put')
    def test_enable_user_failed(self, mock_put):
        """Test failed enable user"""
        mock_put.return_value = {"success": False}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.enable_user("testuser")
        self.assertFalse(result)

    @patch.object(SuiClient, '_put')
    def test_disable_user_success(self, mock_put):
        """Test successful disable user"""
        mock_put.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.disable_user("testuser")
        self.assertTrue(result)

    @patch.object(SuiClient, '_put')
    def test_extend_user_success(self, mock_put):
        """Test successful extend user"""
        mock_put.return_value = {"success": True, "obj": {"username": "testuser"}}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.extend_user("testuser", 30)
        self.assertIsNotNone(result)

    @patch.object(SuiClient, '_put')
    def test_extend_user_failed(self, mock_put):
        """Test failed extend user"""
        mock_put.return_value = {"success": False}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.extend_user("testuser", 30)
        self.assertIsNone(result)

    @patch.object(SuiClient, '_put')
    def test_reset_traffic_success(self, mock_put):
        """Test successful reset traffic"""
        mock_put.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.reset_user_traffic("testuser")
        self.assertTrue(result)

    @patch.object(SuiClient, '_put')
    def test_reset_traffic_failed(self, mock_put):
        """Test failed reset traffic"""
        mock_put.return_value = {"success": False}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.reset_user_traffic("testuser")
        self.assertFalse(result)

    @patch.object(SuiClient, '_post')
    def test_create_user_success(self, mock_post):
        """Test successful create user"""
        mock_post.return_value = {"success": True, "obj": {"username": "newuser"}}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.create_user("newuser", days=30, data_limit=1073741824)
        self.assertIsNotNone(result)
        self.assertEqual(result["username"], "newuser")

    @patch.object(SuiClient, '_post')
    def test_create_user_with_email(self, mock_post):
        """Test create user with custom email"""
        mock_post.return_value = {"success": True, "obj": {"username": "newuser"}}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.create_user("newuser", days=30, data_limit=1073741824, email="test@example.com")
        self.assertIsNotNone(result)

        # Verify the payload included the email
        call_args = mock_post.call_args[0][1]
        self.assertEqual(call_args["email"], "test@example.com")

    @patch.object(SuiClient, '_post')
    def test_create_user_default_email(self, mock_post):
        """Test create user with default email"""
        mock_post.return_value = {"success": True, "obj": {}}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        client.create_user("newuser", days=30, data_limit=1073741824)

        call_args = mock_post.call_args[0][1]
        self.assertEqual(call_args["email"], "newuser@local")

    @patch.object(SuiClient, '_post')
    def test_create_user_failed(self, mock_post):
        """Test failed create user"""
        mock_post.return_value = {"success": False}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.create_user("newuser", days=30, data_limit=1073741824)
        self.assertIsNone(result)

    @patch.object(SuiClient, '_delete')
    def test_delete_user_success(self, mock_delete):
        """Test successful delete user"""
        mock_delete.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.delete_user("testuser")
        self.assertTrue(result)

    @patch.object(SuiClient, '_delete')
    def test_delete_user_failed(self, mock_delete):
        """Test failed delete user"""
        mock_delete.return_value = {"success": False}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.delete_user("testuser")
        self.assertFalse(result)


class TestUserTraffic(unittest.TestCase):
    """Test get_user_traffic method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch.object(SuiClient, 'get_user')
    def test_get_user_traffic_success(self, mock_get_user):
        """Test successful get user traffic"""
        mock_get_user.return_value = {
            "username": "testuser",
            "up": 1073741824,  # 1 GB
            "down": 2147483648,  # 2 GB
            "data_limit": 10737418240,  # 10 GB
        }

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user_traffic("testuser")

        self.assertEqual(result["used_gb"], 3.0)
        self.assertEqual(result["limit_gb"], 10.0)
        self.assertEqual(result["remaining_gb"], 7.0)
        self.assertEqual(result["percentage"], 30.0)

    @patch.object(SuiClient, 'get_user')
    def test_get_user_traffic_not_found(self, mock_get_user):
        """Test user not found for traffic"""
        mock_get_user.return_value = None

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user_traffic("nonexistent")

        self.assertEqual(result["error"], "User not found")
        self.assertEqual(result["used_gb"], 0)

    @patch.object(SuiClient, 'get_user')
    def test_get_user_traffic_no_limit(self, mock_get_user):
        """Test traffic with no data limit"""
        mock_get_user.return_value = {
            "username": "testuser",
            "up": 1073741824,
            "down": 0,
            "data_limit": 0,
        }

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user_traffic("testuser")

        self.assertEqual(result["limit_gb"], 0)
        self.assertEqual(result["remaining_gb"], -1)
        self.assertEqual(result["percentage"], 0)

    @patch.object(SuiClient, 'get_user')
    def test_get_user_traffic_null_values(self, mock_get_user):
        """Test traffic with null values"""
        mock_get_user.return_value = {
            "username": "testuser",
            "up": None,
            "down": None,
            "data_limit": None,
        }

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user_traffic("testuser")

        self.assertEqual(result["used_gb"], 0)
        self.assertEqual(result["limit_gb"], 0)


class TestSubscriptionLink(unittest.TestCase):
    """Test get_subscription_link method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_get_subscription_link_with_port(self):
        """Test subscription link with port in URL"""
        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        link = client.get_subscription_link("testuser")
        self.assertEqual(link, "http://localhost/sub/testuser")

    def test_get_subscription_link_without_port(self):
        """Test subscription link without port"""
        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://example.com")

        link = client.get_subscription_link("testuser")
        self.assertEqual(link, "http://example.com/sub/testuser")

    def test_get_subscription_link_https(self):
        """Test subscription link with HTTPS base URL"""
        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="https://example.com:443")

        link = client.get_subscription_link("testuser")
        self.assertEqual(link, "http://example.com/sub/testuser")


class TestGetUserStatus(unittest.TestCase):
    """Test get_user_status method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch.object(SuiClient, 'get_user')
    @patch.object(SuiClient, 'get_user_traffic')
    def test_get_user_status_success(self, mock_traffic, mock_user):
        """Test successful get user status"""
        mock_user.return_value = {
            "username": "testuser",
            "email": "test@local",
            "enable": True,
            "expiry_time": 1234567890,
            "created_at": 1234567800,
        }
        mock_traffic.return_value = {
            "used_gb": 3.0,
            "limit_gb": 10.0,
            "remaining_gb": 7.0,
            "percentage": 30.0,
        }

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user_status("testuser")

        self.assertEqual(result["username"], "testuser")
        self.assertEqual(result["status"], "active")
        self.assertTrue(result["enabled"])
        self.assertEqual(result["used_traffic"], 3.0)

    @patch.object(SuiClient, 'get_user')
    def test_get_user_status_disabled(self, mock_user):
        """Test disabled user status"""
        mock_user.return_value = {
            "username": "testuser",
            "enable": False,
        }

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file), \
             patch.object(SuiClient, 'get_user_traffic', return_value={
                 "used_gb": 0, "limit_gb": 0, "remaining_gb": -1, "percentage": 0
             }):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user_status("testuser")
        self.assertEqual(result["status"], "disabled")
        self.assertFalse(result["enabled"])

    @patch.object(SuiClient, 'get_user')
    def test_get_user_status_not_found(self, mock_user):
        """Test user not found status"""
        mock_user.return_value = None

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.get_user_status("nonexistent")
        self.assertEqual(result["error"], "User not found")


class TestSearchUsers(unittest.TestCase):
    """Test search_users method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch.object(SuiClient, '_get')
    def test_search_users_success(self, mock_get):
        """Test successful search"""
        mock_get.return_value = {
            "success": True,
            "obj": [{"username": "testuser"}]
        }

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.search_users("test")
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["username"], "testuser")

    @patch.object(SuiClient, '_get')
    def test_search_users_no_results(self, mock_get):
        """Test search with no results"""
        mock_get.return_value = {
            "success": True,
            "obj": []
        }

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.search_users("nonexistent")
        self.assertEqual(result, [])

    @patch.object(SuiClient, '_get')
    def test_search_users_failed(self, mock_get):
        """Test failed search"""
        mock_get.return_value = {"success": False}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.search_users("test")
        self.assertEqual(result, [])


class TestIsConnected(unittest.TestCase):
    """Test is_connected method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.creds_file = os.path.join(self.test_dir, "s-ui.credentials")
        with open(self.creds_file, 'w') as f:
            f.write("SUI_API_TOKEN=test-token\n")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch.object(SuiClient, '_get')
    def test_is_connected_success(self, mock_get):
        """Test successful connection"""
        mock_get.return_value = {"success": True}

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.is_connected()
        self.assertTrue(result)

    @patch.object(SuiClient, '_get')
    def test_is_connected_failed(self, mock_get):
        """Test failed connection"""
        mock_get.return_value = None

        with patch('sui_client.DEFAULT_CREDENTIALS_PATH', self.creds_file):
            client = SuiClient(base_url="http://localhost:2095")

        result = client.is_connected()
        self.assertFalse(result)


if __name__ == "__main__":
    unittest.main()
