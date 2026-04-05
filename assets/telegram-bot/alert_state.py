#!/usr/bin/env python3
"""
Alert State Management Module
Manages alert state to avoid spamming alerts
Uses file locking to prevent race conditions between cron and polling
"""

import json
import os
import sys
import tempfile
import logging
from typing import Dict, Any

# Cross-platform file locking
if sys.platform == 'win32':
    import msvcrt
else:
    import fcntl

logger = logging.getLogger(__name__)


def _lock_file_shared(fd):
    """Acquire shared (read) lock on file descriptor"""
    if sys.platform == 'win32':
        msvcrt.locking(fd, msvcrt.LK_NBLCK, 1)
    else:
        fcntl.flock(fd, fcntl.LOCK_SH)


def _lock_file_exclusive(fd):
    """Acquire exclusive (write) lock on file descriptor"""
    if sys.platform == 'win32':
        msvcrt.locking(fd, msvcrt.LK_NBLCK, 1)
    else:
        fcntl.flock(fd, fcntl.LOCK_EX)


def _unlock_file(fd):
    """Release lock on file descriptor"""
    if sys.platform == 'win32':
        try:
            msvcrt.locking(fd, msvcrt.LK_UNLCK, 1)
        except OSError:
            # Ignore unlock errors on Windows
            pass
    else:
        fcntl.flock(fd, fcntl.LOCK_UN)


class AlertStateError(Exception):
    """Custom exception for alert state errors"""
    pass


class AlertStateManager:
    """Manages alert state persistence with file locking"""

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
        Load alert state from file with shared lock
        Returns:
            dict: Alert state dictionary
        """
        try:
            if not os.path.exists(self.state_file):
                logger.debug(f"State file {self.state_file} does not exist, returning empty state")
                return {}

            with open(self.state_file, 'r') as f:
                # Acquire shared lock for reading
                try:
                    _lock_file_shared(f.fileno())
                except OSError:
                    # Locking may fail on some platforms, continue without lock
                    pass
                try:
                    state = json.load(f)
                    if not isinstance(state, dict):
                        logger.warning(f"Invalid state format, expected dict, got {type(state)}")
                        return {}
                    return state
                finally:
                    # Release lock
                    try:
                        _unlock_file(f.fileno())
                    except OSError:
                        pass
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
        Save alert state to file using atomic write with exclusive lock
        to prevent race conditions between concurrent processes.
        Args:
            state: State dictionary to save
        Returns:
            bool: True if saved successfully, False otherwise
        """
        if not isinstance(state, dict):
            logger.error(f"Invalid state type: expected dict, got {type(state)}")
            return False

        try:
            self._ensure_directory_exists()

            # Write to temporary file first
            dir_name = os.path.dirname(self.state_file)
            fd, temp_path = tempfile.mkstemp(suffix='.tmp', dir=dir_name)
            try:
                with os.fdopen(fd, 'w') as f:
                    json.dump(state, f, indent=2)
                    f.flush()
                    os.fsync(f.fileno())

                # Atomic replace with exclusive lock (cross-platform)
                if sys.platform == 'win32':
                    try:
                        os.replace(temp_path, self.state_file)
                    except OSError:
                        if os.path.exists(self.state_file):
                            os.remove(self.state_file)
                        os.rename(temp_path, self.state_file)
                else:
                    # On Linux/Unix, use file locking for concurrent safety
                    with open(self.state_file, 'a') as lock_file:
                        try:
                            _lock_file_exclusive(lock_file.fileno())
                        except OSError:
                            pass  # Locking may fail, continue
                        try:
                            os.replace(temp_path, self.state_file)
                        finally:
                            try:
                                _unlock_file(lock_file.fileno())
                            except OSError:
                                pass

                logger.debug(f"State saved atomically to {self.state_file}")
                return True
            except Exception:
                # Clean up temp file on error
                if os.path.exists(temp_path):
                    os.unlink(temp_path)
                raise

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
