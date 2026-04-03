#!/usr/bin/env python3
"""
Telegram Client Module
Handles communication with Telegram Bot API
- Send messages with inline keyboards
- Send files/documents
- Typing status
- Callback query answering
"""

import urllib.request
import urllib.parse
import urllib.error
import http.client
import json
import os
import logging

logger = logging.getLogger(__name__)


def _safe_print(text: str) -> None:
    """Print that silently ignores OSError (e.g. stdout closed in CI)."""
    try:
        print(text)
    except OSError:
        pass


import ssl

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# API endpoints / Конечные точки API
TELEGRAM_API_BASE = "https://api.telegram.org"
TELEGRAM_GET_ME_ENDPOINT = "/getMe"
TELEGRAM_SEND_MESSAGE_ENDPOINT = "/sendMessage"
TELEGRAM_SEND_DOCUMENT_ENDPOINT = "/sendDocument"
TELEGRAM_SEND_CHAT_ACTION_ENDPOINT = "/sendChatAction"
TELEGRAM_ANSWER_CALLBACK_ENDPOINT = "/answerCallbackQuery"
TELEGRAM_EDIT_MESSAGE_ENDPOINT = "/editMessageText"
TELEGRAM_EDIT_MESSAGE_REPLY_MARKUP_ENDPOINT = "/editMessageReplyMarkup"

# Timeouts in seconds / Таймауты в секундах
DEFAULT_REQUEST_TIMEOUT = 10

# Maximum file size for sending to Telegram (50 MB limit for documents)
MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB

# Multipart boundary / Граница multipart
MULTIPART_BOUNDARY = "CubiVeilBoundary"

# Content types / Типы контента
CONTENT_TYPE_HTML = "HTML"
CONTENT_TYPE_OCTET_STREAM = "application/octet-stream"
CONTENT_TYPE_MULTIPART_FORM_DATA = "multipart/form-data"

# Chat actions / Действия чата
CHAT_ACTION_TYPING = "typing"


class TelegramClient:
    """Client for Telegram Bot API communication"""

    def __init__(self, token, chat_id):
        self.token = token
        self.chat_id = chat_id
        self.base_url = f"{TELEGRAM_API_BASE}/bot{token}"

    def validate_token(self):
        """
        Validate bot token via Telegram API getMe method
        Returns tuple: (is_valid: bool, error_message: str or None)
        """
        try:
            url = f"{self.base_url}{TELEGRAM_GET_ME_ENDPOINT}"
            with urllib.request.urlopen(url, timeout=DEFAULT_REQUEST_TIMEOUT) as response:  # nosec B310
                data = json.loads(response.read().decode())
                if data.get("ok"):
                    result = data.get("result", {})
                    bot_username = result.get("username", "unknown")
                    bot_name = result.get("first_name", "unknown")
                    return True, f"Bot: @{bot_username} ({bot_name})"
                else:
                    error_code = data.get("error_code", "unknown")
                    description = data.get("description", "Unknown error")
                    return False, f"API error {error_code}: {description}"
        except urllib.error.HTTPError as e:
            try:
                error_body = json.loads(e.read().decode())
                description = error_body.get("description", str(e))
            except Exception:
                description = str(e)
            return False, f"HTTP error {e.code}: {description}"
        except urllib.error.URLError as e:
            return False, f"Network error: {e.reason}"
        except json.JSONDecodeError:
            return False, "Invalid JSON response from Telegram API"
        except Exception as e:
            return False, f"Unexpected error: {str(e)}"

    def _make_request(self, url, data=None, timeout=DEFAULT_REQUEST_TIMEOUT):
        """Make HTTP request to Telegram API"""
        try:
            if data:
                with urllib.request.urlopen(url, data, timeout=timeout) as response:  # nosec B310
                    return response.read().decode()
            else:
                with urllib.request.urlopen(url, timeout=timeout) as response:  # nosec B310
                    return response.read().decode()
        except urllib.error.URLError as e:
            raise Exception(f"Telegram API request failed: {e}")

    def send(self, text, parse_mode=CONTENT_TYPE_HTML, reply_markup=None):
        """
        Send text message to chat
        Args:
            text: Message text (HTML supported)
            parse_mode: Parse mode (HTML or Markdown)
            reply_markup: Inline keyboard JSON dict (optional)
        """
        url = f"{self.base_url}{TELEGRAM_SEND_MESSAGE_ENDPOINT}"

        params = {
            "chat_id": self.chat_id,
            "text": text,
            "parse_mode": parse_mode
        }

        # Add reply markup if provided
        if reply_markup:
            params["reply_markup"] = json.dumps(reply_markup)

        data = urllib.parse.urlencode(params).encode()

        try:
            self._make_request(url, data)
        except Exception as e:
            _safe_print(f"[bot] Error sending message: {e}")

    def send_file(self, path, caption=""):
        """Send file/document to chat"""
        if not os.path.exists(path):
            self.send("⚠️ Backup file not found")
            return

        # Check file size before loading into memory (prevent OOM)
        file_size = os.path.getsize(path)
        if file_size > MAX_FILE_SIZE:
            self.send(
                f"⚠️ File too large: {file_size / (1024*1024):.1f} MB\n"
                f"Maximum size: {MAX_FILE_SIZE / (1024*1024):.0f} MB"
            )
            return

        filename = os.path.basename(path)

        with open(path, "rb") as f:
            file_data = f.read()

        def field(name, value):
            return (f"--{MULTIPART_BOUNDARY}\r\nContent-Disposition: form-data; "
                    f'name="{name}"\r\n\r\n{value}\r\n').encode()

        body = (
            field("chat_id", self.chat_id) +
            field("caption", caption) +
            f"--{MULTIPART_BOUNDARY}\r\nContent-Disposition: form-data; "
            f'name="document"; filename="{filename}"\r\n'
            f"Content-Type: {CONTENT_TYPE_OCTET_STREAM}\r\n\r\n".encode() +
            file_data +
            f"\r\n--{MULTIPART_BOUNDARY}--\r\n".encode()
        )

        try:
            conn = http.client.HTTPSConnection(TELEGRAM_API_BASE)
            conn.request(
                "POST",
                f"/bot{self.token}{TELEGRAM_SEND_DOCUMENT_ENDPOINT}",
                body,
                {"Content-Type": f"{CONTENT_TYPE_MULTIPART_FORM_DATA}; boundary={MULTIPART_BOUNDARY}"}
            )
            conn.getresponse()
        except Exception as e:
            _safe_print(f"[bot] Error sending file: {e}")

    def send_chat_action(self, action=CHAT_ACTION_TYPING):
        """
        Send chat action (typing, etc.)
        Args:
            action: Chat action (typing, upload_photo, etc.)
        """
        url = f"{self.base_url}{TELEGRAM_SEND_CHAT_ACTION_ENDPOINT}"
        data = urllib.parse.urlencode({
            "chat_id": self.chat_id,
            "action": action
        }).encode()

        try:
            self._make_request(url, data)
        except Exception as e:
            _safe_print(f"[bot] Error sending chat action: {e}")

    def answer_callback(self, callback_query_id, text=None, show_alert=False):
        """
        Answer callback query (remove loading state)
        Args:
            callback_query_id: ID of callback query
            text: Notification text (optional)
            show_alert: Show as alert (True) or notification (False)
        """
        url = f"{self.base_url}{TELEGRAM_ANSWER_CALLBACK_ENDPOINT}"
        data = urllib.parse.urlencode({
            "callback_query_id": callback_query_id,
            "text": text or "",
            "show_alert": str(show_alert).lower()
        }).encode()

        try:
            self._make_request(url, data)
        except Exception as e:
            _safe_print(f"[bot] Error answering callback: {e}")

    def edit_message_text(self, chat_id, message_id, text, parse_mode=CONTENT_TYPE_HTML, reply_markup=None):
        """
        Edit message text
        Args:
            chat_id: Chat ID
            message_id: Message ID to edit
            text: New text
            parse_mode: Parse mode
            reply_markup: New inline keyboard (optional)
        """
        url = f"{self.base_url}{TELEGRAM_EDIT_MESSAGE_ENDPOINT}"

        params = {
            "chat_id": chat_id,
            "message_id": message_id,
            "text": text,
            "parse_mode": parse_mode
        }

        # Add reply markup if provided
        if reply_markup:
            params["reply_markup"] = json.dumps(reply_markup)

        data = urllib.parse.urlencode(params).encode()

        try:
            self._make_request(url, data)
        except Exception as e:
            _safe_print(f"[bot] Error editing message: {e}")

    def edit_message_reply_markup(self, chat_id, message_id, reply_markup):
        """
        Edit message reply markup (inline keyboard) only
        Args:
            chat_id: Chat ID
            message_id: Message ID to edit
            reply_markup: New inline keyboard
        """
        url = f"{self.base_url}{TELEGRAM_EDIT_MESSAGE_REPLY_MARKUP_ENDPOINT}"

        params = {
            "chat_id": chat_id,
            "message_id": message_id,
            "reply_markup": json.dumps(reply_markup)
        }

        data = urllib.parse.urlencode(params).encode()

        try:
            self._make_request(url, data)
        except Exception as e:
            _safe_print(f"[bot] Error editing reply markup: {e}")
