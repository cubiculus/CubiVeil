#!/usr/bin/env python3
"""
Tests for Telegram Bot Decoy Manager Module
"""

import sys
import os
import unittest
from unittest.mock import patch, MagicMock, mock_open
import tempfile
import shutil
import json
import subprocess

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from decoy import DecoyManager, FILE_TYPE_NAMES


class TestDecoyManagerInit(unittest.TestCase):
    """Test DecoyManager initialization"""

    def test_initialization(self):
        """Test initialization with default values"""
        decoy = DecoyManager()
        self.assertEqual(decoy.config_path, "/etc/cubiveil/decoy.json")
        self.assertEqual(decoy.webroot, "/var/www/decoy")
        self.assertEqual(decoy.timer_name, "cubiveil-decoy-rotate")
        self.assertEqual(decoy.rotate_script, "/usr/local/lib/cubiveil/decoy-rotate.sh")


class TestRunCommand(unittest.TestCase):
    """Test _run_command method"""

    def setUp(self):
        self.decoy = DecoyManager()

    @patch('decoy.subprocess.run')
    def test_command_success(self, mock_run):
        """Test successful command execution"""
        mock_run.return_value = MagicMock(
            returncode=0, stdout="success output", stderr=""
        )

        success, output = self.decoy._run_command(["echo", "test"])

        self.assertTrue(success)
        self.assertEqual(output, "success output")

    @patch('decoy.subprocess.run')
    def test_command_failed(self, mock_run):
        """Test failed command"""
        mock_run.return_value = MagicMock(
            returncode=1, stdout="", stderr="error message"
        )

        success, output = self.decoy._run_command(["false"])

        self.assertFalse(success)
        self.assertEqual(output, "error message")

    @patch('decoy.subprocess.run')
    def test_command_timeout(self, mock_run):
        """Test command timeout"""
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=["slow"], timeout=60)

        success, output = self.decoy._run_command(["slow"])

        self.assertFalse(success)
        self.assertIn("timed out", output)

    @patch('decoy.subprocess.run')
    def test_command_exception(self, mock_run):
        """Test command exception"""
        mock_run.side_effect = Exception("Unknown error")

        success, output = self.decoy._run_command(["test"])

        self.assertFalse(success)
        self.assertEqual(output, "Unknown error")


class TestConfigManagement(unittest.TestCase):
    """Test config load/save methods"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch('decoy.DECOY_CONFIG')
    def test_load_config_success(self, mock_config):
        """Test successful config load"""
        mock_config.__str__ = lambda self: self.config_file
        test_config = {"rotation": {"enabled": True, "interval_hours": 6}}

        with open(self.config_file, 'w') as f:
            json.dump(test_config, f)

        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            config = decoy._load_config()

            self.assertEqual(config, test_config)

    def test_load_config_not_exists(self):
        """Test config file not exists"""
        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            config = decoy._load_config()

            self.assertIsNone(config)

    def test_load_config_invalid_json(self):
        """Test invalid JSON config"""
        with open(self.config_file, 'w') as f:
            f.write("not valid json")

        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            config = decoy._load_config()

            self.assertIsNone(config)

    def test_save_config_success(self):
        """Test successful config save"""
        test_config = {"rotation": {"enabled": True}}

        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            result = decoy._save_config(test_config)

            self.assertTrue(result)
            self.assertTrue(os.path.exists(self.config_file))

            # Check file permissions (skip on Windows as chmod behaves differently)
            if os.name != 'nt':
                mode = oct(os.stat(self.config_file).st_mode)[-3:]
                self.assertEqual(mode, "600")

    def test_save_config_io_error(self):
        """Test config save IO error"""
        # Create instance without calling __init__ to avoid config loading
        decoy = DecoyManager.__new__(DecoyManager)
        decoy.config_path = '/nonexistent/path/config.json'
        result = decoy._save_config({"key": "value"})

        self.assertFalse(result)


class TestIsConfigured(unittest.TestCase):
    """Test is_configured method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch('decoy.DECOY_CONFIG')
    def test_configured(self, mock_config):
        """Test when config exists"""
        with patch('decoy.DECOY_CONFIG', self.config_file):
            with open(self.config_file, 'w') as f:
                f.write("{}")

            decoy = DecoyManager()
            self.assertTrue(decoy.is_configured())

    def test_not_configured(self):
        """Test when config doesn't exist"""
        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            self.assertFalse(decoy.is_configured())


class TestGetStatus(unittest.TestCase):
    """Test get_status method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")
        self.webroot = os.path.join(self.test_dir, "webroot")
        os.makedirs(self.webroot)

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_status_not_configured(self):
        """Test status when not configured"""
        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            status = decoy.get_status()

        self.assertFalse(status["configured"])
        self.assertFalse(status["enabled"])

    @patch.object(DecoyManager, '_run_command')
    def test_status_configured(self, mock_run):
        """Test status when configured"""
        mock_run.return_value = (True, "active")

        config = {
            "rotation": {
                "enabled": True,
                "interval_hours": 6,
                "last_rotated_at": "2024-01-01T12:00:00+00:00"
            },
            "max_total_files_mb": 3000
        }

        with open(self.config_file, 'w') as f:
            json.dump(config, f)

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_WEBROOT', self.webroot):
            decoy = DecoyManager()
            status = decoy.get_status()

        self.assertTrue(status["configured"])
        self.assertTrue(status["enabled"])
        self.assertEqual(status["interval_hours"], 6)
        self.assertTrue(status["timer_active"])

    @patch.object(DecoyManager, '_run_command')
    def test_status_with_files(self, mock_run):
        """Test status with files in webroot"""
        mock_run.return_value = (True, "active")

        config = {"rotation": {"enabled": True, "interval_hours": 3}}

        with open(self.config_file, 'w') as f:
            json.dump(config, f)

        # Create files with measurable size
        files_dir = os.path.join(self.webroot, "files")
        os.makedirs(files_dir)
        with open(os.path.join(files_dir, "test.jpg"), 'wb') as f:
            f.write(b"x" * (100 * 1024))  # 100 KB to ensure measurable size

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_WEBROOT', self.webroot):
            decoy = DecoyManager()
            status = decoy.get_status()

        self.assertEqual(status["file_count"], 1)
        self.assertGreater(status["total_size_mb"], 0)
        self.assertIn("jpg", status["files_by_type"])


class TestGetFilesList(unittest.TestCase):
    """Test get_files_list method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.webroot = os.path.join(self.test_dir, "webroot")
        self.files_dir = os.path.join(self.webroot, "files")
        os.makedirs(self.files_dir)

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_get_files_empty(self):
        """Test getting files when directory is empty"""
        with patch('decoy.DECOY_WEBROOT', self.webroot):
            decoy = DecoyManager()
            files = decoy.get_files_list()

        self.assertEqual(files, [])

    def test_get_files_with_content(self):
        """Test getting files with content"""
        # Create test files
        for name in ["file1.jpg", "file2.pdf", "file3.mp4"]:
            with open(os.path.join(self.files_dir, name), 'w') as f:
                f.write("x" * 100)

        with patch('decoy.DECOY_WEBROOT', self.webroot):
            decoy = DecoyManager()
            files = decoy.get_files_list()

        self.assertEqual(len(files), 3)
        # Check all expected types are present
        types = [f["type"] for f in files]
        self.assertIn("jpg", types)
        self.assertIn("pdf", types)
        self.assertIn("mp4", types)

    def test_get_files_limit(self):
        """Test files limit"""
        # Create more files than limit
        for i in range(10):
            with open(os.path.join(self.files_dir, f"file{i}.jpg"), 'w') as f:
                f.write("x")

        with patch('decoy.DECOY_WEBROOT', self.webroot):
            decoy = DecoyManager()
            files = decoy.get_files_list(limit=5)

        self.assertEqual(len(files), 5)

    def test_get_files_no_files_dir(self):
        """Test when files directory doesn't exist"""
        with patch('decoy.DECOY_WEBROOT', self.webroot):
            decoy = DecoyManager()
            files = decoy.get_files_list()

        self.assertEqual(files, [])


class TestRotateNow(unittest.TestCase):
    """Test rotate_now method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")
        self.rotate_script = os.path.join(self.test_dir, "rotate.sh")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_rotate_not_configured(self):
        """Test rotation when not configured"""
        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            success, message = decoy.rotate_now()

        self.assertFalse(success)
        self.assertEqual(message, "Decoy site not configured")

    def test_rotate_script_not_found(self):
        """Test rotation when script doesn't exist"""
        with open(self.config_file, 'w') as f:
            json.dump({}, f)

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_ROTATE_SCRIPT', self.rotate_script):
            decoy = DecoyManager()
            success, message = decoy.rotate_now()

        self.assertFalse(success)
        self.assertIn("Rotate script not found", message)

    @patch.object(DecoyManager, '_run_command')
    def test_rotate_success(self, mock_run):
        """Test successful rotation"""
        mock_run.return_value = (True, "Rotation completed")

        with open(self.config_file, 'w') as f:
            json.dump({}, f)
        with open(self.rotate_script, 'w') as f:
            f.write("#!/bin/bash\necho done")

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_ROTATE_SCRIPT', self.rotate_script):
            decoy = DecoyManager()
            success, message = decoy.rotate_now()

        self.assertTrue(success)
        self.assertEqual(message, "Rotation completed successfully")

    @patch.object(DecoyManager, '_run_command')
    def test_rotate_failed(self, mock_run):
        """Test failed rotation"""
        mock_run.return_value = (False, "Error occurred")

        with open(self.config_file, 'w') as f:
            json.dump({}, f)
        with open(self.rotate_script, 'w') as f:
            f.write("#!/bin/bash\nexit 1")

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_ROTATE_SCRIPT', self.rotate_script):
            decoy = DecoyManager()
            success, message = decoy.rotate_now()

        self.assertFalse(success)
        self.assertIn("Rotation failed", message)


class TestSetInterval(unittest.TestCase):
    """Test set_interval method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_set_interval_invalid_low(self):
        """Test invalid low interval"""
        decoy = DecoyManager()
        success, message = decoy.set_interval(0)
        self.assertFalse(success)
        self.assertIn("between 1 and 168", message)

    def test_set_interval_invalid_high(self):
        """Test invalid high interval"""
        decoy = DecoyManager()
        success, message = decoy.set_interval(200)
        self.assertFalse(success)
        self.assertIn("between 1 and 168", message)

    @patch.object(DecoyManager, '_load_config')
    def test_set_interval_config_load_failed(self, mock_load):
        """Test interval set when config load fails"""
        mock_load.return_value = None

        decoy = DecoyManager()
        success, message = decoy.set_interval(6)
        self.assertFalse(success)
        self.assertEqual(message, "Failed to load configuration")

    @patch.object(DecoyManager, '_run_command')
    @patch.object(DecoyManager, '_save_config')
    @patch.object(DecoyManager, '_load_config')
    def test_set_interval_success(self, mock_load, mock_save, mock_run):
        """Test successful interval set"""
        mock_load.return_value = {"rotation": {}}
        mock_save.return_value = True
        mock_run.return_value = (True, "")

        decoy = DecoyManager()
        success, message = decoy.set_interval(12)

        self.assertTrue(success)
        self.assertEqual(message, "Interval set to 12 hours")
        mock_save.assert_called_once()


class TestSetSizeLimit(unittest.TestCase):
    """Test set_size_limit method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_set_size_limit_invalid_low(self):
        """Test invalid low size limit"""
        decoy = DecoyManager()
        success, message = decoy.set_size_limit(50)
        self.assertFalse(success)
        self.assertIn("Minimum size limit is 100", message)

    @patch.object(DecoyManager, '_load_config')
    def test_set_size_limit_config_load_failed(self, mock_load):
        """Test size limit set when config load fails"""
        mock_load.return_value = None

        decoy = DecoyManager()
        success, message = decoy.set_size_limit(500)
        self.assertFalse(success)
        self.assertEqual(message, "Failed to load configuration")

    @patch.object(DecoyManager, '_load_config', return_value={"rotation": {}})
    @patch.object(DecoyManager, '_save_config', return_value=True)
    @patch.object(DecoyManager, '_run_command', return_value=(True, ""))
    def test_set_size_limit_success(self, mock_run, mock_save, mock_load):
        """Test successful size limit set"""
        decoy = DecoyManager()
        success, message = decoy.set_size_limit(2000)

        self.assertTrue(success)
        self.assertEqual(message, "Size limit set to 2000 MB")


class TestSetTypeWeight(unittest.TestCase):
    """Test set_type_weight method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_set_type_weight_invalid_type(self):
        """Test invalid file type"""
        decoy = DecoyManager()
        success, message = decoy.set_type_weight("png", 5)
        self.assertFalse(success)
        self.assertIn("Invalid type", message)

    def test_set_type_weight_invalid_low(self):
        """Test invalid low weight"""
        decoy = DecoyManager()
        success, message = decoy.set_type_weight("jpg", -1)
        self.assertFalse(success)
        self.assertIn("between 0 and 10", message)

    def test_set_type_weight_invalid_high(self):
        """Test invalid high weight"""
        decoy = DecoyManager()
        success, message = decoy.set_type_weight("jpg", 11)
        self.assertFalse(success)
        self.assertIn("between 0 and 10", message)

    @patch.object(DecoyManager, '_load_config')
    def test_set_type_weight_config_load_failed(self, mock_load):
        """Test type weight set when config load fails"""
        mock_load.return_value = None

        decoy = DecoyManager()
        success, message = decoy.set_type_weight("jpg", 5)
        self.assertFalse(success)
        self.assertEqual(message, "Failed to load configuration")

    @patch.object(DecoyManager, '_load_config', return_value={"rotation": {}})
    @patch.object(DecoyManager, '_save_config', return_value=True)
    @patch.object(DecoyManager, '_run_command', return_value=(True, ""))
    def test_set_type_weight_enable(self, mock_run, mock_save, mock_load):
        """Test enabling type weight"""
        decoy = DecoyManager()
        success, message = decoy.set_type_weight("jpg", 8)

        self.assertTrue(success)
        self.assertIn("enabled", message)
        self.assertIn("8", message)

    @patch.object(DecoyManager, '_load_config', return_value={"rotation": {}})
    @patch.object(DecoyManager, '_save_config', return_value=True)
    @patch.object(DecoyManager, '_run_command', return_value=(True, ""))
    def test_set_type_weight_disable(self, mock_run, mock_save, mock_load):
        """Test disabling type weight"""
        decoy = DecoyManager()
        success, message = decoy.set_type_weight("jpg", 0)

        self.assertTrue(success)
        self.assertIn("disabled", message)


class TestGetTypeWeights(unittest.TestCase):
    """Test get_type_weights method"""

    @patch.object(DecoyManager, '_load_config')
    def test_get_type_weights_empty(self, mock_load):
        """Test empty type weights"""
        mock_load.return_value = None

        decoy = DecoyManager()
        weights = decoy.get_type_weights()

        self.assertEqual(weights, {})

    @patch.object(DecoyManager, '_load_config')
    def test_get_type_weights_with_data(self, mock_load):
        """Test type weights with data"""
        mock_load.return_value = {
            "rotation": {
                "types": {
                    "jpg": {"enabled": True, "weight": 8},
                    "pdf": {"enabled": False, "weight": 0},
                }
            }
        }

        decoy = DecoyManager()
        weights = decoy.get_type_weights()

        self.assertEqual(weights["jpg"]["weight"], 8)
        self.assertEqual(weights["pdf"]["weight"], 0)


class TestToggleRotation(unittest.TestCase):
    """Test toggle_rotation method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    @patch.object(DecoyManager, '_load_config')
    def test_toggle_config_load_failed(self, mock_load):
        """Test toggle when config load fails"""
        mock_load.return_value = None

        decoy = DecoyManager()
        success, message = decoy.toggle_rotation(True)
        self.assertFalse(success)
        self.assertEqual(message, "Failed to load configuration")

    @patch.object(DecoyManager, '_load_config', return_value={"rotation": {}})
    @patch.object(DecoyManager, '_save_config', return_value=True)
    @patch.object(DecoyManager, '_run_command', return_value=(True, ""))
    def test_toggle_enable(self, mock_run, mock_save, mock_load):
        """Test enabling rotation"""
        decoy = DecoyManager()
        success, message = decoy.toggle_rotation(True)

        self.assertTrue(success)
        self.assertEqual(message, "Rotation enabled")
        mock_run.assert_called()

    @patch.object(DecoyManager, '_load_config', return_value={"rotation": {}})
    @patch.object(DecoyManager, '_save_config', return_value=True)
    @patch.object(DecoyManager, '_run_command', return_value=(True, ""))
    def test_toggle_disable(self, mock_run, mock_save, mock_load):
        """Test disabling rotation"""
        decoy = DecoyManager()
        success, message = decoy.toggle_rotation(False)

        self.assertTrue(success)
        self.assertEqual(message, "Rotation disabled")

    @patch.object(DecoyManager, '_load_config', return_value={"rotation": {}})
    @patch.object(DecoyManager, '_save_config', return_value=False)
    def test_toggle_save_failed(self, mock_save, mock_load):
        """Test toggle when save fails"""
        decoy = DecoyManager()
        success, message = decoy.toggle_rotation(True)
        self.assertFalse(success)
        self.assertEqual(message, "Failed to save configuration")


class TestCleanupOldFiles(unittest.TestCase):
    """Test cleanup_old_files method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")
        self.rotate_script = os.path.join(self.test_dir, "rotate.sh")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_cleanup_not_configured(self):
        """Test cleanup when not configured"""
        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            success, message, stats = decoy.cleanup_old_files()

        self.assertFalse(success)
        self.assertEqual(message, "Decoy site not configured")
        self.assertEqual(stats, {})

    @patch.object(DecoyManager, '_run_command')
    def test_cleanup_success_with_parsing(self, mock_run):
        """Test successful cleanup with output parsing"""
        mock_run.return_value = (True, "удалено файлов 5, освобождено ~100MB")

        with open(self.config_file, 'w') as f:
            json.dump({}, f)

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_ROTATE_SCRIPT', self.rotate_script):
            decoy = DecoyManager()
            success, message, stats = decoy.cleanup_old_files()

        self.assertTrue(success)
        self.assertEqual(message, "Cleanup completed")
        self.assertEqual(stats["deleted"], 5)
        self.assertEqual(stats["freed_mb"], 100)

    @patch.object(DecoyManager, '_run_command')
    def test_cleanup_failed(self, mock_run):
        """Test failed cleanup"""
        mock_run.return_value = (False, "Error occurred")

        with open(self.config_file, 'w') as f:
            json.dump({}, f)

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_ROTATE_SCRIPT', self.rotate_script):
            decoy = DecoyManager()
            success, message, stats = decoy.cleanup_old_files()

        self.assertFalse(success)
        self.assertIn("Cleanup failed", message)


class TestRegenerateAll(unittest.TestCase):
    """Test regenerate_all method"""

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.config_file = os.path.join(self.test_dir, "decoy.json")
        self.rotate_script = os.path.join(self.test_dir, "rotate.sh")

    def tearDown(self):
        shutil.rmtree(self.test_dir)

    def test_regenerate_not_configured(self):
        """Test regeneration when not configured"""
        with patch('decoy.DECOY_CONFIG', self.config_file):
            decoy = DecoyManager()
            success, message = decoy.regenerate_all()

        self.assertFalse(success)
        self.assertEqual(message, "Decoy site not configured")

    @patch.object(DecoyManager, '_run_command')
    def test_regenerate_success(self, mock_run):
        """Test successful regeneration"""
        mock_run.return_value = (True, "Regenerated")

        with open(self.config_file, 'w') as f:
            json.dump({}, f)

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_ROTATE_SCRIPT', self.rotate_script):
            decoy = DecoyManager()
            success, message = decoy.regenerate_all()

        self.assertTrue(success)
        self.assertEqual(message, "All files regenerated successfully")

    @patch.object(DecoyManager, '_run_command')
    def test_regenerate_failed(self, mock_run):
        """Test failed regeneration"""
        mock_run.return_value = (False, "Regeneration error")

        with open(self.config_file, 'w') as f:
            json.dump({}, f)

        with patch('decoy.DECOY_CONFIG', self.config_file), \
             patch('decoy.DECOY_ROTATE_SCRIPT', self.rotate_script):
            decoy = DecoyManager()
            success, message = decoy.regenerate_all()

        self.assertFalse(success)
        self.assertIn("Regeneration failed", message)


if __name__ == "__main__":
    unittest.main()
