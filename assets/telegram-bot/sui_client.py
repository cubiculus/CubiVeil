#!/usr/bin/env python3
"""
S-UI API Client Module
Real implementation of S-UI API v2 for user management
"""

import urllib.request
import urllib.parse
import urllib.error
import json
import os
import logging
from typing import Optional, Dict, Any, List

logger = logging.getLogger(__name__)

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

DEFAULT_BASE_URL = "http://localhost:2095"
DEFAULT_CREDENTIALS_PATH = "/etc/cubiveil/s-ui.credentials"
API_TIMEOUT = 30


class SuiClientError(Exception):
    """Custom exception for S-UI API errors"""
    pass


class SuiClient:
    """
    S-UI API v2 client for user management
    Authenticates via token from credentials file
    """

    def __init__(self, base_url: Optional[str] = None, credentials_path: Optional[str] = None):
        self.base_url = (base_url or DEFAULT_BASE_URL).rstrip('/')
        self.credentials_path = credentials_path or DEFAULT_CREDENTIALS_PATH
        self.token: Optional[str] = None
        self.session_cookie: Optional[str] = None

        # Load credentials
        self._load_credentials()

    def _load_credentials(self) -> None:
        """Load API token from credentials file"""
        try:
            if not os.path.exists(self.credentials_path):
                logger.warning(f"Credentials file not found: {self.credentials_path}")
                return

            with open(self.credentials_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith('SUI_API_TOKEN='):
                        self.token = line.split('=', 1)[1].strip()
                        break

            if not self.token:
                logger.warning("No API token found in credentials file")
        except Exception as e:
            logger.error(f"Failed to load credentials: {e}")

    def _make_request(
        self,
        endpoint: str,
        method: str = "GET",
        data: Optional[Dict[str, Any]] = None,
        needs_auth: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Make HTTP request to S-UI API
        Args:
            endpoint: API endpoint (e.g., "/api/user/list")
            method: HTTP method
            data: Request body for POST/PUT
            needs_auth: Whether authentication is required
        Returns:
            JSON response as dict or None on error
        """
        url = f"{self.base_url}{endpoint}"

        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        # Add authentication
        if needs_auth:
            if self.token:
                headers["X-API-Token"] = self.token
            if self.session_cookie:
                headers["Cookie"] = f"session={self.session_cookie}"

        try:
            request_data = None
            if data and method in ("POST", "PUT"):
                request_data = json.dumps(data).encode('utf-8')

            req = urllib.request.Request(
                url,
                data=request_data,
                headers=headers,
                method=method
            )

            with urllib.request.urlopen(req, timeout=API_TIMEOUT) as response:  # nosec B310
                response_data = response.read().decode('utf-8')
                if response_data:
                    return json.loads(response_data)
                return None

        except urllib.error.HTTPError as e:
            logger.error(f"HTTP error {e.code} for {endpoint}: {e.read().decode() if e.fp else 'unknown'}")
            return None
        except urllib.error.URLError as e:
            logger.error(f"Network error for {endpoint}: {e.reason}")
            return None
        except json.JSONDecodeError as e:
            logger.error(f"JSON decode error for {endpoint}: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error for {endpoint}: {e}")
            return None

    def _get(self, endpoint: str) -> Optional[Dict[str, Any]]:
        """Make GET request"""
        return self._make_request(endpoint, method="GET")

    def _post(self, endpoint: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Make POST request"""
        return self._make_request(endpoint, method="POST", data=data)

    def _put(self, endpoint: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """Make PUT request"""
        return self._make_request(endpoint, method="PUT", data=data)

    def _delete(self, endpoint: str) -> Optional[Dict[str, Any]]:
        """Make DELETE request"""
        return self._make_request(endpoint, method="DELETE")

    # ═══════════════════════════════════════════════════════════════════════════
    # User Management API / Управление пользователями
    # ═══════════════════════════════════════════════════════════════════════════

    def get_user(self, username: str) -> Optional[Dict[str, Any]]:
        """
        Get user by username
        Returns user dict or None if not found
        """
        # S-UI API v2: GET /api/user/{username}
        response = self._get(f"/api/user/{username}")

        if response and response.get("success"):
            return response.get("obj")
        return None

    def list_users(self) -> List[Dict[str, Any]]:
        """
        Get list of all users
        Returns list of user dicts
        """
        # S-UI API v2: GET /api/user/list
        response = self._get("/api/user/list")

        if response and response.get("success"):
            return response.get("obj", [])
        return []

    def enable_user(self, username: str) -> bool:
        """
        Enable a user
        Returns True on success
        """
        # S-UI API v2: PUT /api/user/{username}/enable
        response = self._put(f"/api/user/{username}/enable", {})

        if response and response.get("success"):
            logger.info(f"User {username} enabled")
            return True

        logger.warning(f"Failed to enable user {username}")
        return False

    def disable_user(self, username: str) -> bool:
        """
        Disable a user
        Returns True on success
        """
        # S-UI API v2: PUT /api/user/{username}/disable
        response = self._put(f"/api/user/{username}/disable", {})

        if response and response.get("success"):
            logger.info(f"User {username} disabled")
            return True

        logger.warning(f"Failed to disable user {username}")
        return False

    def extend_user(self, username: str, days: int) -> Optional[Dict[str, Any]]:
        """
        Extend user expiration by days
        Returns updated user dict on success
        """
        # S-UI API v2: PUT /api/user/{username}/extend
        response = self._put(f"/api/user/{username}/extend", {"days": days})

        if response and response.get("success"):
            logger.info(f"User {username} extended by {days} days")
            return response.get("obj")

        logger.warning(f"Failed to extend user {username}")
        return None

    def reset_user_traffic(self, username: str) -> bool:
        """
        Reset user traffic counters
        Returns True on success
        """
        # S-UI API v2: PUT /api/user/{username}/reset-traffic
        response = self._put(f"/api/user/{username}/reset-traffic", {})

        if response and response.get("success"):
            logger.info(f"Traffic reset for user {username}")
            return True

        logger.warning(f"Failed to reset traffic for user {username}")
        return False

    def create_user(
        self,
        username: str,
        days: int,
        data_limit: int,
        email: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Create a new user
        Args:
            username: Username
            days: Expiration in days
            data_limit: Data limit in bytes
            email: Optional email (defaults to username)
        Returns:
            Created user dict on success
        """
        # S-UI API v2: POST /api/user/create
        payload = {
            "username": username,
            "email": email or f"{username}@local",
            "enable": True,
            "expiry_time": days * 86400 * 1000,  # Convert to milliseconds
            "data_limit": data_limit,
            "down": 0,
            "up": 0,
        }

        response = self._post("/api/user/create", payload)

        if response and response.get("success"):
            logger.info(f"User {username} created")
            return response.get("obj")

        logger.warning(f"Failed to create user {username}: {response}")
        return None

    def delete_user(self, username: str) -> bool:
        """
        Delete a user
        Returns True on success
        """
        # S-UI API v2: DELETE /api/user/{username}
        response = self._delete(f"/api/user/{username}")

        if response and response.get("success"):
            logger.info(f"User {username} deleted")
            return True

        logger.warning(f"Failed to delete user {username}")
        return False

    def get_user_traffic(self, username: str) -> Dict[str, Any]:
        """
        Get user traffic usage
        Returns dict with traffic stats
        """
        user = self.get_user(username)

        if not user:
            return {"used_gb": 0, "limit_gb": 0, "remaining_gb": 0, "percentage": 0, "error": "User not found"}

        up = user.get("up", 0) or 0
        down = user.get("down", 0) or 0
        total = user.get("data_limit", 0) or 0
        used = up + down

        used_gb = used / (1024 ** 3)
        limit_gb = total / (1024 ** 3) if total > 0 else 0
        remaining_gb = max(0, limit_gb - used_gb) if total > 0 else float('inf')
        percentage = (used / total * 100) if total > 0 else 0

        return {
            "used_gb": round(used_gb, 2),
            "limit_gb": round(limit_gb, 2),
            "remaining_gb": round(remaining_gb, 2) if remaining_gb != float('inf') else -1,
            "percentage": round(percentage, 1),
            "up_gb": round(up / (1024 ** 3), 2),
            "down_gb": round(down / (1024 ** 3), 2),
        }

    def get_subscription_link(self, username: str) -> str:
        """
        Get user subscription link
        Returns subscription URL
        """
        # S-UI subscription format: http://host:port/sub/{username}
        # Extract host from base_url
        host = self.base_url.replace("http://", "").replace("https://", "")

        # Remove port from host for subscription URL
        if ":" in host:
            host = host.split(":")[0]

        return f"http://{host}/sub/{username}"

    def get_user_status(self, username: str) -> Dict[str, Any]:
        """
        Get comprehensive user status
        Returns dict with all user info
        """
        user = self.get_user(username)

        if not user:
            return {"error": "User not found"}

        traffic = self.get_user_traffic(username)

        return {
            "username": user.get("username", username),
            "email": user.get("email", ""),
            "enabled": user.get("enable", False),
            "status": "active" if user.get("enable", False) else "disabled",
            "used_traffic": traffic["used_gb"],
            "data_limit": traffic["limit_gb"],
            "remaining_traffic": traffic["remaining_gb"],
            "traffic_percentage": traffic["percentage"],
            "expiry_time": user.get("expiry_time", 0),
            "created_at": user.get("created_at", 0),
        }

    def search_users(self, query: str) -> List[Dict[str, Any]]:
        """
        Search users by query
        Returns list of matching users
        """
        # S-UI API v2: GET /api/user/search?q={query}
        encoded_query = urllib.parse.quote(query)
        response = self._get(f"/api/user/search?q={encoded_query}")

        if response and response.get("success"):
            return response.get("obj", [])
        return []

    def is_connected(self) -> bool:
        """
        Check if S-UI API is accessible
        Returns True if connection successful
        """
        # Try to get server status
        response = self._get("/api/server/status", needs_auth=False)
        return response is not None
