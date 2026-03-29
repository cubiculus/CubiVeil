#!/usr/bin/env python3
"""
Tests for Telegram Bot Keyboards Module
"""

import sys
import os
import json
import unittest

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'telegram-bot'))

from keyboards import (
    build_main_menu,
    build_backup_menu,
    build_logs_menu,
    build_settings_menu,
    build_alerts_submenu,
    build_back_button,
    build_confirm_keyboard,
    build_pagination_keyboard,
    build_backup_actions_keyboard,
    build_logs_lines_keyboard,
    build_decoy_menu,
    build_decoy_settings_menu,
)


class TestKeyboards(unittest.TestCase):
    """Test cases for keyboards module"""

    def test_build_main_menu_structure(self):
        """Test main menu has correct structure"""
        menu = build_main_menu()
        self.assertIn("inline_keyboard", menu)
        self.assertIsInstance(menu["inline_keyboard"], list)
        # Should have 3 rows (no Users/Profiles after s-ui migration)
        self.assertEqual(len(menu["inline_keyboard"]), 3)

    def test_build_main_menu_buttons(self):
        """Test main menu has all required buttons"""
        menu = build_main_menu()
        keyboard = menu["inline_keyboard"]

        # Check first row
        self.assertEqual(keyboard[0][0]["text"], "📊 Status")
        self.assertEqual(keyboard[0][0]["callback_data"], "main_status")
        self.assertEqual(keyboard[0][1]["text"], "📈 Monitor")
        self.assertEqual(keyboard[0][1]["callback_data"], "main_monitor")

        # Check second row (no Users button)
        self.assertEqual(keyboard[1][0]["text"], "💾 Backup")
        self.assertEqual(keyboard[1][0]["callback_data"], "main_backup")
        self.assertEqual(keyboard[1][1]["text"], "📋 Logs")
        self.assertEqual(keyboard[1][1]["callback_data"], "main_logs")

        # Check third row (no Profiles button)
        self.assertEqual(keyboard[2][0]["text"], "🏥 Health")
        self.assertEqual(keyboard[2][0]["callback_data"], "main_health")
        self.assertEqual(keyboard[2][1]["text"], "⚙️ Settings")
        self.assertEqual(keyboard[2][1]["callback_data"], "main_settings")

    def test_build_backup_menu_structure(self):
        """Test backup menu has correct structure"""
        menu = build_backup_menu()
        self.assertIn("inline_keyboard", menu)
        # Should have 3 rows (2 action rows + 1 back)
        self.assertEqual(len(menu["inline_keyboard"]), 3)

    def test_build_backup_menu_buttons(self):
        """Test backup menu has all required buttons"""
        menu = build_backup_menu()
        keyboard = menu["inline_keyboard"]

        self.assertEqual(keyboard[0][0]["text"], "📋 List Backups")
        self.assertEqual(keyboard[0][0]["callback_data"], "backup_list")
        self.assertEqual(keyboard[0][1]["text"], "💾 Create Now")
        self.assertEqual(keyboard[0][1]["callback_data"], "backup_create")

    def test_build_logs_menu_structure(self):
        """Test logs menu has correct structure"""
        menu = build_logs_menu()
        self.assertIn("inline_keyboard", menu)
        # Should have 3 rows (2 service rows + 1 back, no Marzban/Singbox)
        self.assertEqual(len(menu["inline_keyboard"]), 3)

    def test_build_logs_menu_buttons(self):
        """Test logs menu has all required buttons"""
        menu = build_logs_menu()
        keyboard = menu["inline_keyboard"]

        # No Marzban/Sing-box buttons after s-ui migration
        self.assertEqual(keyboard[0][0]["text"], "🤖 Bot")
        self.assertEqual(keyboard[0][0]["callback_data"], "logs_bot")
        self.assertEqual(keyboard[0][1]["text"], "🌐 Nginx")
        self.assertEqual(keyboard[0][1]["callback_data"], "logs_nginx")

    def test_build_settings_menu_structure(self):
        """Test settings menu has correct structure"""
        menu = build_settings_menu()
        self.assertIn("inline_keyboard", menu)
        # Should have 4 rows (3 setting rows + 1 back)
        self.assertEqual(len(menu["inline_keyboard"]), 4)

    def test_build_back_button(self):
        """Test back button has correct structure"""
        menu = build_back_button()
        keyboard = menu["inline_keyboard"]
        self.assertEqual(len(keyboard), 1)
        self.assertEqual(keyboard[0][0]["text"], "◀️ Back")
        self.assertEqual(keyboard[0][0]["callback_data"], "nav_back")

    def test_build_confirm_keyboard(self):
        """Test confirm keyboard has correct structure"""
        menu = build_confirm_keyboard("test_action", "test_item")
        keyboard = menu["inline_keyboard"]
        self.assertEqual(len(keyboard), 1)
        self.assertEqual(keyboard[0][0]["text"], "✅ Confirm")
        self.assertEqual(keyboard[0][0]["callback_data"], "test_action_confirm:test_item")
        self.assertEqual(keyboard[0][1]["text"], "❌ Cancel")
        self.assertEqual(keyboard[0][1]["callback_data"], "test_action_cancel:test_item")

    def test_build_pagination_keyboard(self):
        """Test pagination keyboard has correct structure"""
        # Test middle page
        menu = build_pagination_keyboard(1, 5, "test_prefix")
        keyboard = menu["inline_keyboard"]
        self.assertEqual(len(keyboard), 2)  # Page row + back button

        # First row should have prev, page info, next
        self.assertEqual(keyboard[0][0]["text"], "◀️")
        self.assertEqual(keyboard[0][1]["text"], "2/5")
        self.assertEqual(keyboard[0][2]["text"], "▶️")

        # Test first page (no prev button)
        menu = build_pagination_keyboard(0, 5, "test_prefix")
        keyboard = menu["inline_keyboard"]
        self.assertEqual(keyboard[0][0]["text"], "1/5")
        self.assertEqual(keyboard[0][1]["text"], "▶️")

        # Test last page (no next button)
        menu = build_pagination_keyboard(4, 5, "test_prefix")
        keyboard = menu["inline_keyboard"]
        self.assertEqual(keyboard[0][0]["text"], "◀️")
        self.assertEqual(keyboard[0][1]["text"], "5/5")

    def test_build_backup_actions_keyboard(self):
        """Test backup actions keyboard has correct structure"""
        menu = build_backup_actions_keyboard("test_backup.sqlite3")
        keyboard = menu["inline_keyboard"]
        self.assertEqual(len(keyboard), 3)  # 2 action rows + 1 back

        # Check first row
        self.assertEqual(keyboard[0][0]["text"], "⬇️ Download")
        self.assertEqual(keyboard[0][1]["text"], "↩️ Restore")

    def test_build_logs_lines_keyboard(self):
        """Test logs lines keyboard has correct structure"""
        menu = build_logs_lines_keyboard("bot", 50)
        keyboard = menu["inline_keyboard"]
        self.assertEqual(len(keyboard), 3)  # 2 line selection rows + 1 back

        # Check first row
        self.assertEqual(keyboard[0][0]["text"], "📄 25 lines")
        self.assertEqual(keyboard[0][0]["callback_data"], "logs_lines:bot:25")
        self.assertEqual(keyboard[0][1]["text"], "📄 50 lines")
        self.assertEqual(keyboard[0][1]["callback_data"], "logs_lines:bot:50")

    def test_build_decoy_menu_structure(self):
        """Test decoy menu has correct structure"""
        menu = build_decoy_menu()
        self.assertIn("inline_keyboard", menu)
        self.assertIsInstance(menu["inline_keyboard"], list)

    def test_build_decoy_settings_menu_structure(self):
        """Test decoy settings menu has correct structure"""
        menu = build_decoy_settings_menu()
        self.assertIn("inline_keyboard", menu)
        self.assertIsInstance(menu["inline_keyboard"], list)

    def test_all_menus_valid_json(self):
        """Test all menus can be serialized to JSON"""
        menus = [
            build_main_menu(),
            build_backup_menu(),
            build_logs_menu(),
            build_settings_menu(),
            build_alerts_submenu(),
            build_back_button(),
            build_decoy_menu(),
            build_decoy_settings_menu(),
        ]

        for menu in menus:
            try:
                json.dumps(menu)
            except (TypeError, ValueError) as e:
                self.fail(f"Menu is not JSON serializable: {e}")


if __name__ == "__main__":
    unittest.main()
