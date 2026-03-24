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


class TelegramClient:
    """Client for Telegram Bot API communication"""

    def __init__(self, token, chat_id):
        self.token = token
        self.chat_id = chat_id
        self.base_url = f"https://api.telegram.org/bot{token}"

    def _make_request(self, url, data=None, timeout=10):
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

    def send(self, text, parse_mode="HTML"):
        """Send text message to chat"""
        url = f"{self.base_url}/sendMessage"
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

        boundary = "CubiVeilBoundary"
        filename = os.path.basename(path)

        with open(path, "rb") as f:
            file_data = f.read()

        def field(name, value):
            return (f"--{boundary}\r\nContent-Disposition: form-data; "
                    f'name="{name}"\r\n\r\n{value}\r\n').encode()

        body = (
            field("chat_id", self.chat_id) +
            field("caption", caption) +
            f"--{boundary}\r\nContent-Disposition: form-data; "
            f'name="document"; filename="{filename}"\r\n'
            f"Content-Type: application/octet-stream\r\n\r\n".encode() +
            file_data +
            f"\r\n--{boundary}--\r\n".encode()
        )

        try:
            conn = http.client.HTTPSConnection("api.telegram.org")
            conn.request(
                "POST",
                f"/bot{self.token}/sendDocument",
                body,
                {"Content-Type": f"multipart/form-data; boundary={boundary}"}
            )
            conn.getresponse()
        except Exception as e:
            print(f"[bot] Error sending file: {e}")
