#!/usr/bin/env python3
"""
Alert State Management Module
Manages alert state to avoid spamming alerts
"""

import json
import os
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)


class AlertStateError(Exception):
    """Custom exception for alert state errors"""
    pass


class AlertStateManager:
    """Manages alert state persistence"""

    def __init__(self, state_file: str = "/opt/cubiveil-bot/alert_state.json"):
        self.state_file = state_file
        self._ensure_directory_exists()

    def _ensure_directory_exists(self) -> None:
        """Ensure the directory for state file exists"""
        try:
            dir_name = os.path.dirname(self.state_file)
            if dir_name and not os.path.exists(dir_name):
                os.makedirs(dir_name, mode=0o755, exist_ok=True)
        except OSError as e:
            logger.warning(f"Failed to create state directory: {e}")

    def load(self) -> Dict[str, Any]:
        """
        Load alert state from file
        Returns:
            dict: Alert state dictionary
        Raises:
            AlertStateError: If file cannot be read or parsed
        """
        try:
            if not os.path.exists(self.state_file):
                logger.debug(f"State file {self.state_file} does not exist, returning empty state")
                return {}

            with open(self.state_file, 'r') as f:
                state = json.load(f)
                if not isinstance(state, dict):
                    logger.warning(f"Invalid state format, expected dict, got {type(state)}")
                    return {}
                return state
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse state file: {e}")
            return {}
        except IOError as e:
            logger.error(f"Failed to read state file: {e}")
            return {}
        except Exception as e:
            logger.error(f"Unexpected error loading state: {e}")
            return {}

    def save(self, state: Dict[str, Any]) -> bool:
        """
        Save alert state to file
        Args:
            state: State dictionary to save
        Returns:
            bool: True if saved successfully, False otherwise
        Raises:
            AlertStateError: If state cannot be saved
        """
        if not isinstance(state, dict):
            logger.error(f"Invalid state type: expected dict, got {type(state)}")
            return False

        try:
            self._ensure_directory_exists()
            with open(self.state_file, 'w') as f:
                json.dump(state, f, indent=2)
            logger.debug(f"State saved to {self.state_file}")
            return True
        except IOError as e:
            logger.error(f"Failed to write state file: {e}")
            return False
        except Exception as e:
            logger.error(f"Unexpected error saving state: {e}")
            return False

    def clear(self) -> bool:
        """
        Clear all alert states
        Returns:
            bool: True if cleared successfully, False otherwise
        """
        return self.save({})

    def get(self, key: str, default: Any = None) -> Any:
        """
        Get specific state value
        Args:
            key: State key
            default: Default value if key not found
        Returns:
            State value or default
        """
        state = self.load()
        return state.get(key, default)

    def set(self, key: str, value: Any) -> bool:
        """
        Set specific state value
        Args:
            key: State key
            value: State value
        Returns:
            bool: True if set successfully, False otherwise
        """
        state = self.load()
        state[key] = value
        return self.save(state)
