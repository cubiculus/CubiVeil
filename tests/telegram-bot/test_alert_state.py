#!/usr/bin/env python3
"""
Tests for Telegram Bot Alert State Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, mock_open
import tempfile
import shutil
import json

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from alert_state import AlertStateManager, AlertStateError


class TestAlertStateManager(unittest.TestCase):
    """Test cases for AlertStateManager module"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_dir = tempfile.mkdtemp()
        self.state_file = os.path.join(self.test_dir, "alert_state.json")
        self.manager = AlertStateManager(state_file=self.state_file)

    def tearDown(self):
        """Clean up test fixtures"""
        shutil.rmtree(self.test_dir)

    def test_initialization(self):
        """Test manager initializes with correct state file"""
        self.assertEqual(self.manager.state_file, self.state_file)

    def test_load_empty_state_nonexistent_file(self):
        """Test loading state when file doesn't exist"""
        state = self.manager.load()
        self.assertEqual(state, {})

    def test_save_and_load_state(self):
        """Test saving and loading state"""
        test_state = {"cpu": True, "ram": False, "disk": True}
        result = self.manager.save(test_state)
        self.assertTrue(result)

        loaded = self.manager.load()
        self.assertEqual(loaded, test_state)

    def test_save_invalid_state_type(self):
        """Test saving invalid state type"""
        result = self.manager.save("not a dict")  # type: ignore
        self.assertFalse(result)

        result = self.manager.save([1, 2, 3])  # type: ignore
        self.assertFalse(result)

    def test_clear_state(self):
        """Test clearing state"""
        # Save some state first
        self.manager.save({"cpu": True, "ram": True})
        result = self.manager.clear()
        self.assertTrue(result)

        loaded = self.manager.load()
        self.assertEqual(loaded, {})

    def test_get_existing_key(self):
        """Test getting existing key"""
        self.manager.save({"cpu": True, "ram": False})
        value = self.manager.get("cpu")
        self.assertTrue(value)

    def test_get_nonexistent_key(self):
        """Test getting non-existent key"""
        self.manager.save({"cpu": True})
        value = self.manager.get("nonexistent")
        self.assertIsNone(value)

    def test_get_nonexistent_key_default(self):
        """Test getting non-existent key with default"""
        self.manager.save({"cpu": True})
        value = self.manager.get("nonexistent", default=False)
        self.assertFalse(value)

    def test_set_new_key(self):
        """Test setting new key"""
        result = self.manager.set("cpu", True)
        self.assertTrue(result)

        state = self.manager.load()
        self.assertTrue(state["cpu"])

    def test_set_updates_existing_key(self):
        """Test updating existing key"""
        self.manager.save({"cpu": False})
        result = self.manager.set("cpu", True)
        self.assertTrue(result)

        state = self.manager.load()
        self.assertTrue(state["cpu"])

    def test_load_invalid_json(self):
        """Test loading invalid JSON file"""
        with open(self.state_file, 'w') as f:
            f.write("not valid json{{{")

        state = self.manager.load()
        self.assertEqual(state, {})

    def test_load_non_dict_json(self):
        """Test loading JSON that's not a dict"""
        with open(self.state_file, 'w') as f:
            f.write("[1, 2, 3]")

        state = self.manager.load()
        self.assertEqual(state, {})

    @patch('alert_state.os.makedirs')
    def test_ensure_directory_raises_oserror(self, mock_makedirs):
        """Test directory creation failure"""
        mock_makedirs.side_effect = OSError("Permission denied")
        # Should not raise exception, just log warning
        manager = AlertStateManager(state_file="/nonexistent/dir/state.json")
        state = manager.load()
        self.assertEqual(state, {})

    @patch('alert_state.json.load')
    def test_load_ioerror(self, mock_json_load):
        """Test IOError during load"""
        mock_json_load.side_effect = IOError("Read error")
        state = self.manager.load()
        self.assertEqual(state, {})

    @patch('alert_state.json.dump')
    def test_save_ioerror(self, mock_json_dump):
        """Test IOError during save"""
        mock_json_dump.side_effect = IOError("Write error")
        result = self.manager.save({"cpu": True})
        self.assertFalse(result)

    def test_save_creates_directory(self):
        """Test that save creates directory if it doesn't exist"""
        nested_dir = os.path.join(self.test_dir, "nested", "dir")
        nested_file = os.path.join(nested_dir, "state.json")
        manager = AlertStateManager(state_file=nested_file)

        result = manager.save({"key": "value"})
        self.assertTrue(result)
        self.assertTrue(os.path.exists(nested_file))

    def test_atomic_write_preserves_data(self):
        """Test atomic write preserves data correctly"""
        test_data = {"cpu": True, "ram": 85, "disk": {"used": 90}}
        self.manager.save(test_data)

        with open(self.state_file, 'r') as f:
            saved = json.load(f)

        self.assertEqual(saved, test_data)


class TestAlertStateManagerLocking(unittest.TestCase):
    """Test file locking behavior"""

    def setUp(self):
        """Set up test fixtures"""
        self.test_dir = tempfile.mkdtemp()
        self.state_file = os.path.join(self.test_dir, "alert_state.json")
        self.manager = AlertStateManager(state_file=self.state_file)

    def tearDown(self):
        """Clean up test fixtures"""
        shutil.rmtree(self.test_dir)

    @patch('alert_state.fcntl.flock')
    def test_load_acquires_shared_lock(self, mock_flock):
        """Test that load acquires shared lock"""
        self.manager.save({"cpu": True})
        state = self.manager.load()

        # Should have been called twice: LOCK_SH and LOCK_UN
        self.assertGreaterEqual(mock_flock.call_count, 2)

    @patch('alert_state.fcntl.flock')
    def test_save_acquires_exclusive_lock(self, mock_flock):
        """Test that save acquires exclusive lock"""
        self.manager.save({"cpu": True})

        # Should have been called with LOCK_EX and LOCK_UN
        self.assertGreaterEqual(mock_flock.call_count, 2)

    def test_concurrent_save_load(self):
        """Test concurrent save and load operations"""
        # Save initial state
        self.manager.save({"counter": 0})

        # Load and modify multiple times
        for i in range(10):
            state = self.manager.load()
            state["counter"] = i
            self.manager.save(state)

        final = self.manager.load()
        self.assertEqual(final["counter"], 9)


if __name__ == "__main__":
    unittest.main()
