#!/usr/bin/env python3
"""
Tests for Telegram Bot Telegram Client Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, mock_open
import json

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from telegram_client import TelegramClient, TELEGRAM_API_BASE


class TestTelegramClient(unittest.TestCase):
    """Test cases for TelegramClient module"""

    def setUp(self):
        """Set up test fixtures"""
        self.token = "123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
        self.chat_id = "123456789"
        self.client = TelegramClient(self.token, self.chat_id)

    def test_initialization(self):
        """Test client initializes correctly"""
        self.assertEqual(self.client.token, self.token)
        self.assertEqual(self.client.chat_id, self.chat_id)
        self.assertEqual(self.client.base_url, f"{TELEGRAM_API_BASE}/bot{self.token}")

    @patch('telegram_client.urllib.request.urlopen')
    def test_validate_token_success(self, mock_urlopen):
        """Test successful token validation"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "ok": True,
            "result": {
                "username": "testbot",
                "first_name": "Test Bot"
            }
        }).encode()
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = lambda s, *args: None
        mock_urlopen.return_value = mock_response

        is_valid, message = self.client.validate_token()

        self.assertTrue(is_valid)
        self.assertIn("Bot:", message)

    @patch('telegram_client.urllib.request.urlopen')
    def test_validate_token_invalid(self, mock_urlopen):
        """Test invalid token"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "ok": False,
            "error_code": 401,
            "description": "Unauthorized"
        }).encode()
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = lambda s, *args: None
        mock_urlopen.return_value = mock_response

        is_valid, message = self.client.validate_token()

        self.assertFalse(is_valid)
        self.assertIn("401", message)

    @patch('telegram_client.urllib.request.urlopen')
    def test_validate_token_network_error(self, mock_urlopen):
        """Test network error during validation"""
        mock_urlopen.side_effect = Exception("Network error")

        is_valid, message = self.client.validate_token()

        self.assertFalse(is_valid)

    @patch('telegram_client.urllib.request.urlopen')
    def test_send_message(self, mock_urlopen):
        """Test sending message"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"ok": True}).encode()
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = lambda s, *args: None
        mock_urlopen.return_value = mock_response

        # Should not raise
        self.client.send("Test message")

        mock_urlopen.assert_called_once()

    @patch('telegram_client.urllib.request.urlopen')
    def test_send_message_error(self, mock_urlopen):
        """Test sending message with error"""
        mock_urlopen.side_effect = Exception("API error")

        # Should not raise, just print error
        self.client.send("Test message")

    @patch('telegram_client.http.client.HTTPSConnection')
    def test_send_file(self, mock_https):
        """Test sending file"""
        # Create temp file
        import tempfile
        with tempfile.NamedTemporaryFile(delete=False) as f:
            f.write(b"test content")
            temp_path = f.name

        try:
            mock_conn = MagicMock()
            mock_https.return_value = mock_conn

            self.client.send_file(temp_path, "Test caption")

            mock_conn.request.assert_called_once()
        finally:
            os.unlink(temp_path)

    def test_send_file_not_exists(self):
        """Test sending non-existent file"""
        self.client.send_file("/nonexistent/file.txt")

        # Should send error message instead
        # (we can't easily test this without mocking send())

    @patch('telegram_client.urllib.request.urlopen')
    def test_send_chat_action(self, mock_urlopen):
        """Test sending chat action"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"ok": True}).encode()
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = lambda s, *args: None
        mock_urlopen.return_value = mock_response

        self.client.send_chat_action("typing")

        mock_urlopen.assert_called_once()

    @patch('telegram_client.urllib.request.urlopen')
    def test_answer_callback(self, mock_urlopen):
        """Test answering callback query"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"ok": True}).encode()
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = lambda s, *args: None
        mock_urlopen.return_value = mock_response

        self.client.answer_callback("callback_id_123")

        mock_urlopen.assert_called_once()

    @patch('telegram_client.urllib.request.urlopen')
    def test_edit_message_text(self, mock_urlopen):
        """Test editing message text"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"ok": True}).encode()
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = lambda s, *args: None
        mock_urlopen.return_value = mock_response

        self.client.edit_message_text(
            self.chat_id,
            123,
            "Updated message"
        )

        mock_urlopen.assert_called_once()

    @patch('telegram_client.urllib.request.urlopen')
    def test_edit_message_reply_markup(self, mock_urlopen):
        """Test editing message reply markup"""
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({"ok": True}).encode()
        mock_response.__enter__ = lambda s: s
        mock_response.__exit__ = lambda s, *args: None
        mock_urlopen.return_value = mock_response

        keyboard = {"inline_keyboard": [[{"text": "Button", "callback_data": "test"}]]}

        self.client.edit_message_reply_markup(
            self.chat_id,
            123,
            keyboard
        )

        mock_urlopen.assert_called_once()


class TestTelegramClientConstants(unittest.TestCase):
    """Test telegram client constants"""

    def test_api_base_url(self):
        """Test API base URL is correct"""
        self.assertEqual(TELEGRAM_API_BASE, "https://api.telegram.org")

    def test_content_types(self):
        """Test content type constants"""
        from telegram_client import CONTENT_TYPE_HTML, CONTENT_TYPE_OCTET_STREAM
        self.assertEqual(CONTENT_TYPE_HTML, "HTML")
        self.assertEqual(CONTENT_TYPE_OCTET_STREAM, "application/octet-stream")

    def test_chat_actions(self):
        """Test chat action constants"""
        from telegram_client import CHAT_ACTION_TYPING
        self.assertEqual(CHAT_ACTION_TYPING, "typing")


if __name__ == "__main__":
    unittest.main()
