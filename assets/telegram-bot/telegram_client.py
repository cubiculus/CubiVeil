#!/usr/bin/env python3
"""
Telegram Client Module
Handles communication with Telegram Bot API
"""

import urllib.request
import urllib.parse
import urllib.error
import http.client
import json
import os
import ssl

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# API endpoints / Конечные точки API
TELEGRAM_API_BASE = "https://api.telegram.org"
TELEGRAM_GET_ME_ENDPOINT = "/getMe"
TELEGRAM_SEND_MESSAGE_ENDPOINT = "/sendMessage"
TELEGRAM_SEND_DOCUMENT_ENDPOINT = "/sendDocument"

# Timeouts in seconds / Таймауты в секундах
DEFAULT_REQUEST_TIMEOUT = 10

# Multipart boundary / Граница multipart
MULTIPART_BOUNDARY = "CubiVeilBoundary"

# Content types / Типы контента
CONTENT_TYPE_HTML = "HTML"
CONTENT_TYPE_OCTET_STREAM = "application/octet-stream"
CONTENT_TYPE_MULTIPART_FORM_DATA = "multipart/form-data"


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
            with urllib.request.urlopen(url, timeout=DEFAULT_REQUEST_TIMEOUT) as response:
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
                with urllib.request.urlopen(url, data, timeout=timeout) as response:
                    return response.read().decode()
            else:
                with urllib.request.urlopen(url, timeout=timeout) as response:
                    return response.read().decode()
        except urllib.error.URLError as e:
            raise Exception(f"Telegram API request failed: {e}")

    def send(self, text, parse_mode=CONTENT_TYPE_HTML):
        """Send text message to chat"""
        url = f"{self.base_url}{TELEGRAM_SEND_MESSAGE_ENDPOINT}"
        data = urllib.parse.urlencode({
            "chat_id": self.chat_id,
            "text": text,
            "parse_mode": parse_mode
        }).encode()

        try:
            self._make_request(url, data)
        except Exception as e:
            print(f"[bot] Error sending message: {e}")

    def send_file(self, path, caption=""):
        """Send file/document to chat"""
        if not os.path.exists(path):
            self.send("⚠️ Backup file not found")
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
            print(f"[bot] Error sending file: {e}")
