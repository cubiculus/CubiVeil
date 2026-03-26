#!/usr/bin/env python3
"""
Profiles Module
Marzban API client for profile management
"""

import urllib.request
import urllib.parse
import urllib.error
import json
import logging
import os
from typing import Optional, Dict, List, Any
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# Marzban API endpoints / Конечные точки API
MARZBAN_API_BASE = "http://localhost:8000"
MARZBAN_TOKEN_FILE = "/opt/marzban/.marzban_token"

# API endpoints
API_LOGIN = "/api/admin/token"
API_USER = "/api/user/{username}"
API_USERS = "/api/users"
API_USER_RESET = "/api/user/{username}/reset"
API_USER_REVOKE = "/api/user/{username}/revoke_sub"

# Timeouts in seconds / Таймауты в секундах
API_TIMEOUT = 10

# QR Code settings / Настройки QR-кода
QR_API_URL = "https://api.qrserver.com/v1/create-qr-code/"
QR_SIZE = "300x300"


class ProfilesError(Exception):
    """Custom exception for profiles errors"""
    pass


class MarzbanClient:
    """Client for Marzban API"""

    def __init__(self):
        self.base_url = MARZBAN_API_BASE
        self.token = self._load_token()
        self.headers = {
            "Content-Type": "application/x-www-form-urlencoded"
        }
        if self.token:
            self.headers["Authorization"] = f"Bearer {self.token}"

    def _load_token(self) -> Optional[str]:
        """Load Marzban API token from file"""
        try:
            if os.path.exists(MARZBAN_TOKEN_FILE):
                with open(MARZBAN_TOKEN_FILE, 'r') as f:
                    return f.read().strip()
        except Exception as e:
            logger.error(f"Error loading token: {e}")
        return None

    def _make_request(self, method: str, endpoint: str, data: dict = None) -> Optional[dict]:
        """
        Make HTTP request to Marzban API
        Args:
            method: HTTP method (GET, POST, PUT, DELETE)
            endpoint: API endpoint
            data: Request data
        Returns:
            dict: Response data or None
        """
        url = f"{self.base_url}{endpoint}"

        try:
            if data:
                encoded_data = urllib.parse.urlencode(data).encode()
            else:
                encoded_data = None

            req = urllib.request.Request(
                url,
                data=encoded_data,
                headers=self.headers,
                method=method
            )

            with urllib.request.urlopen(req, timeout=API_TIMEOUT) as response:  # nosec B310
                if response.status == 204:  # No content
                    return {}
                return json.loads(response.read().decode())

        except urllib.error.HTTPError as e:
            error_body = e.read().decode() if e.fp else ""
            logger.error(f"HTTP error {e.code}: {error_body}")
            return None
        except urllib.error.URLError as e:
            logger.error(f"Network error: {e.reason}")
            return None
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            return None

    def get_user(self, username: str) -> Optional[dict]:
        """
        Get user profile
        Args:
            username: Username
        Returns:
            dict: User data or None
        """
        return self._make_request("GET", API_USER.format(username=username))

    def get_all_users(self) -> List[dict]:
        """
        Get all users
        Returns:
            list: List of users
        """
        result = self._make_request("GET", API_USERS)
        return result if result else []

    def modify_user(self, username: str, data: dict) -> Optional[dict]:
        """
        Modify user (enable/disable/extend)
        Args:
            username: Username
            data: Modification data
        Returns:
            dict: Updated user data or None
        """
        return self._make_request("PUT", API_USER.format(username=username), data)

    def disable_user(self, username: str) -> bool:
        """
        Disable user by setting status to disabled
        Args:
            username: Username
        Returns:
            bool: Success status
        """
        data = {"status": "disabled"}
        result = self.modify_user(username, data)
        return result is not None

    def enable_user(self, username: str) -> bool:
        """
        Enable user by setting status to active
        Args:
            username: Username
        Returns:
            bool: Success status
        """
        data = {"status": "active"}
        result = self.modify_user(username, data)
        return result is not None

    def extend_user(self, username: str, days: int) -> Optional[dict]:
        """
        Extend user expiry date
        Args:
            username: Username
            days: Days to extend
        Returns:
            dict: Updated user data or None
        """
        user = self.get_user(username)
        if not user:
            return None

        current_expiry = user.get("expire")
        if current_expiry:
            # Add days to current expiry
            new_expiry = current_expiry + (days * 86400)
        else:
            # Set new expiry from now
            new_expiry = int((datetime.now() + timedelta(days=days)).timestamp())

        data = {"expire": new_expiry}
        return self.modify_user(username, data)

    def reset_user_traffic(self, username: str) -> bool:
        """
        Reset user traffic
        Args:
            username: Username
        Returns:
            bool: Success status
        """
        result = self._make_request("POST", API_USER_RESET.format(username=username))
        return result is not None

    def revoke_subscription(self, username: str) -> Optional[str]:
        """
        Revoke user subscription and get new link
        Args:
            username: Username
        Returns:
            str: New subscription link or None
        """
        result = self._make_request("POST", API_USER_REVOKE.format(username=username))
        if result:
            return result.get("subscription_url")
        return None

    def create_user(self, username: str, days: int = 30,
                    data_limit_gb: float = 0.0) -> Optional[dict]:
        """
        Create new user
        Args:
            username: Username
            days: Validity days
            data_limit_gb: Data limit in GB
        Returns:
            dict: Created user data or None
        """
        data = {
            "username": username,
            "status": "active",
            "expire": int((datetime.now() + timedelta(days=days)).timestamp()),
            "data_limit": int(data_limit_gb * 1024 * 1024 * 1024) if data_limit_gb > 0 else None,
        }

        # Remove None values
        data = {k: v for k, v in data.items() if v is not None}

        result = self._make_request("POST", API_USERS, data)
        return result

    def get_subscription_link(self, username: str) -> Optional[str]:
        """
        Get user subscription link
        Args:
            username: Username
        Returns:
            str: Subscription link or None
        """
        user = self.get_user(username)
        if user:
            return user.get("subscription_url")
        return None

    def generate_qr_code_url(self, subscription_link: str) -> str:
        """
        Generate QR code URL for subscription
        Args:
            subscription_link: Subscription URL
        Returns:
            str: QR code image URL
        """
        params = urllib.parse.urlencode({
            "size": QR_SIZE,
            "data": subscription_link
        })
        return f"{QR_API_URL}?{params}"

    def get_user_traffic(self, username: str) -> Optional[dict]:
        """
        Get user traffic statistics
        Args:
            username: Username
        Returns:
            dict: Traffic data {used, limit, remaining}
        """
        user = self.get_user(username)
        if not user:
            return None

        used = user.get("used_traffic", 0)
        limit = user.get("data_limit", 0)

        return {
            "used_bytes": used,
            "used_gb": used / (1024 * 1024 * 1024),
            "limit_bytes": limit,
            "limit_gb": limit / (1024 * 1024 * 1024) if limit > 0 else None,
            "remaining_bytes": max(0, limit - used) if limit > 0 else None,
            "remaining_gb": max(0, (limit - used) / (1024 * 1024 * 1024)) if limit > 0 else None,
            "percentage": (used / limit * 100) if limit > 0 else 0
        }
