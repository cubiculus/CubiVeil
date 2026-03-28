#!/usr/bin/env python3
"""
Keyboards Module
Inline keyboards and menus for Telegram bot
"""

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# Callback data prefixes / Префиксы данных callback
CALLBACK_MAIN_STATUS = "main_status"
CALLBACK_MAIN_MONITOR = "main_monitor"
CALLBACK_MAIN_BACKUP = "main_backup"
CALLBACK_MAIN_USERS = "main_users"
CALLBACK_MAIN_LOGS = "main_logs"
CALLBACK_MAIN_HEALTH = "main_health"
CALLBACK_MAIN_PROFILES = "main_profiles"
CALLBACK_MAIN_SETTINGS = "main_settings"

CALLBACK_BACKUP_LIST = "backup_list"
CALLBACK_BACKUP_CREATE = "backup_create"
CALLBACK_BACKUP_RESTORE = "backup_restore"
CALLBACK_BACKUP_DELETE = "backup_delete"
CALLBACK_BACKUP_DOWNLOAD = "backup_download"

CALLBACK_LOGS_MARZBAN = "logs_marzban"
CALLBACK_LOGS_SINGBOX = "logs_singbox"
CALLBACK_LOGS_BOT = "logs_bot"
CALLBACK_LOGS_NGINX = "logs_nginx"
CALLBACK_LOGS_SYSTEM = "logs_system"

CALLBACK_PROFILES_LIST = "profiles_list"
CALLBACK_PROFILES_ACTIVE = "profiles_active"
CALLBACK_PROFILES_DISABLED = "profiles_disabled"
CALLBACK_PROFILES_EXPIRED = "profiles_expired"

CALLBACK_SETTINGS_ALERTS = "settings_alerts"
CALLBACK_SETTINGS_REPORT = "settings_report"
CALLBACK_SETTINGS_CPU = "settings_cpu"
CALLBACK_SETTINGS_RAM = "settings_ram"
CALLBACK_SETTINGS_DISK = "settings_disk"

CALLBACK_NAV_BACK = "nav_back"
CALLBACK_NAV_MAIN = "nav_main"

# Decoy Site callbacks / Callback сайта-прикрытия
CALLBACK_DECOY_MAIN = "decoy_main"
CALLBACK_DECOY_STATUS = "decoy_status"
CALLBACK_DECOY_ROTATE = "decoy_rotate"
CALLBACK_DECOY_FILES = "decoy_files"
CALLBACK_DECOY_CONFIG = "decoy_config"
CALLBACK_DECOY_SETTINGS = "decoy_settings"
CALLBACK_DECOY_INTERVAL = "decoy_interval"
CALLBACK_DECOY_LIMIT = "decoy_limit"
CALLBACK_DECOY_WEIGHTS = "decoy_weights"
CALLBACK_DECOY_ENABLE = "decoy_enable"
CALLBACK_DECOY_DISABLE = "decoy_disable"
CALLBACK_DECOY_CLEANUP = "decoy_cleanup"
CALLBACK_DECOY_REGENERATE = "decoy_regenerate"


def build_main_menu():
    """
    Build main menu inline keyboard
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "📊 Status", "callback_data": CALLBACK_MAIN_STATUS},
                {"text": "📈 Monitor", "callback_data": CALLBACK_MAIN_MONITOR}
            ],
            [
                {"text": "💾 Backup", "callback_data": CALLBACK_MAIN_BACKUP},
                {"text": "👥 Users", "callback_data": CALLBACK_MAIN_USERS}
            ],
            [
                {"text": "📋 Logs", "callback_data": CALLBACK_MAIN_LOGS},
                {"text": "🏥 Health", "callback_data": CALLBACK_MAIN_HEALTH}
            ],
            [
                {"text": "👤 Profiles", "callback_data": CALLBACK_MAIN_PROFILES},
                {"text": "⚙️ Settings", "callback_data": CALLBACK_MAIN_SETTINGS}
            ]
        ]
    }


def build_backup_menu():
    """
    Build backup management inline keyboard
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "📋 List Backups", "callback_data": CALLBACK_BACKUP_LIST},
                {"text": "💾 Create Now", "callback_data": CALLBACK_BACKUP_CREATE}
            ],
            [
                {"text": "↩️ Restore", "callback_data": CALLBACK_BACKUP_RESTORE},
                {"text": "🗑️ Delete Old", "callback_data": CALLBACK_BACKUP_DELETE}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_NAV_BACK}
            ]
        ]
    }


def build_logs_menu():
    """
    Build logs selection inline keyboard
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "🅼 Marzban", "callback_data": CALLBACK_LOGS_MARZBAN},
                {"text": "🆂 Sing-Box", "callback_data": CALLBACK_LOGS_SINGBOX}
            ],
            [
                {"text": "🤖 Bot", "callback_data": CALLBACK_LOGS_BOT},
                {"text": "🌐 Nginx", "callback_data": CALLBACK_LOGS_NGINX}
            ],
            [
                {"text": "💻 Systemd", "callback_data": CALLBACK_LOGS_SYSTEM}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_NAV_BACK}
            ]
        ]
    }


def build_profiles_menu():
    """
    Build profiles management inline keyboard
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "📋 All Profiles", "callback_data": CALLBACK_PROFILES_LIST},
                {"text": "🟢 Active", "callback_data": CALLBACK_PROFILES_ACTIVE}
            ],
            [
                {"text": "🔴 Disabled", "callback_data": CALLBACK_PROFILES_DISABLED},
                {"text": "⚫ Expired", "callback_data": CALLBACK_PROFILES_EXPIRED}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_NAV_BACK}
            ]
        ]
    }


def build_settings_menu():
    """
    Build settings inline keyboard
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "🔔 Alerts", "callback_data": CALLBACK_SETTINGS_ALERTS},
                {"text": "📅 Report Time", "callback_data": CALLBACK_SETTINGS_REPORT}
            ],
            [
                {"text": "🔹 CPU Threshold", "callback_data": CALLBACK_SETTINGS_CPU},
                {"text": "🔸 RAM Threshold", "callback_data": CALLBACK_SETTINGS_RAM}
            ],
            [
                {"text": "💿 Disk Threshold", "callback_data": CALLBACK_SETTINGS_DISK}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_NAV_BACK}
            ]
        ]
    }


def build_alerts_submenu():
    """
    Build alerts settings submenu
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "🔹 CPU", "callback_data": CALLBACK_SETTINGS_CPU},
                {"text": "🔸 RAM", "callback_data": CALLBACK_SETTINGS_RAM},
                {"text": "💿 Disk", "callback_data": CALLBACK_SETTINGS_DISK}
            ],
            [
                {"text": "◀️ Back to Settings", "callback_data": CALLBACK_NAV_BACK}
            ]
        ]
    }


def build_back_button():
    """
    Build simple back button
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [{"text": "◀️ Back", "callback_data": CALLBACK_NAV_BACK}]
        ]
    }


def build_confirm_keyboard(action: str, item: str):
    """
    Build confirmation keyboard for dangerous actions
    Args:
        action: Action type (restore, delete, etc.)
        item: Item identifier
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "✅ Confirm", "callback_data": f"{action}_confirm:{item}"},
                {"text": "❌ Cancel", "callback_data": f"{action}_cancel:{item}"}
            ]
        ]
    }


def build_pagination_keyboard(current_page: int, total_pages: int, callback_prefix: str):
    """
    Build pagination keyboard
    Args:
        current_page: Current page number (0-based)
        total_pages: Total pages count
        callback_prefix: Prefix for callback data
    Returns dict for JSON serialization
    """
    buttons = []
    row = []

    # Previous button
    if current_page > 0:
        row.append({"text": "◀️", "callback_data": f"{callback_prefix}_page:{current_page - 1}"})

    # Page indicator
    row.append({"text": f"{current_page + 1}/{total_pages}", "callback_data": "page_info"})

    # Next button
    if current_page < total_pages - 1:
        row.append({"text": "▶️", "callback_data": f"{callback_prefix}_page:{current_page + 1}"})

    buttons.append(row)

    # Back button
    buttons.append([{"text": "◀️ Back", "callback_data": CALLBACK_NAV_BACK}])

    return {"inline_keyboard": buttons}


def build_profile_actions_keyboard(username: str):
    """
    Build profile actions keyboard
    Args:
        username: Profile username
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "📊 Info", "callback_data": f"profile_info:{username}"},
                {"text": "⏳ Extend", "callback_data": f"profile_extend:{username}"}
            ],
            [
                {"text": "⛔ Disable", "callback_data": f"profile_disable:{username}"},
                {"text": "✅ Enable", "callback_data": f"profile_enable:{username}"}
            ],
            [
                {"text": "🔄 Reset Traffic", "callback_data": f"profile_reset:{username}"},
                {"text": "📱 QR Code", "callback_data": f"profile_qr:{username}"}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_PROFILES_LIST}
            ]
        ]
    }


def build_backup_actions_keyboard(filename: str):
    """
    Build backup actions keyboard
    Args:
        filename: Backup filename
    Returns dict for JSON serialization
    """
    # Encode filename for callback (replace special chars)
    safe_filename = filename.replace("/", "_").replace(":", "_")
    return {
        "inline_keyboard": [
            [
                {"text": "⬇️ Download", "callback_data": f"backup_download:{safe_filename}"},
                {"text": "↩️ Restore", "callback_data": f"backup_restore:{safe_filename}"}
            ],
            [
                {"text": "🗑️ Delete", "callback_data": f"backup_delete:{safe_filename}"}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_BACKUP_LIST}
            ]
        ]
    }


def build_logs_lines_keyboard(service: str, lines: int = 50):
    """
    Build log lines selection keyboard
    Args:
        service: Service name
        lines: Current lines count
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "📄 25 lines", "callback_data": f"logs_lines:{service}:25"},
                {"text": "📄 50 lines", "callback_data": f"logs_lines:{service}:50"}
            ],
            [
                {"text": "📄 100 lines", "callback_data": f"logs_lines:{service}:100"},
                {"text": "📄 200 lines", "callback_data": f"logs_lines:{service}:200"}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_MAIN_LOGS}
            ]
        ]
    }


def build_decoy_menu():
    """
    Build Decoy Site main menu keyboard
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "📊 Status", "callback_data": CALLBACK_DECOY_STATUS},
                {"text": "🔄 Rotate Now", "callback_data": CALLBACK_DECOY_ROTATE}
            ],
            [
                {"text": "📁 Files List", "callback_data": CALLBACK_DECOY_FILES},
                {"text": "⚙️ Settings", "callback_data": CALLBACK_DECOY_SETTINGS}
            ],
            [
                {"text": "📄 Config", "callback_data": CALLBACK_DECOY_CONFIG}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_NAV_MAIN}
            ]
        ]
    }


def build_decoy_settings_menu():
    """
    Build Decoy Settings menu keyboard
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "🔔 Interval", "callback_data": CALLBACK_DECOY_INTERVAL},
                {"text": "💾 Size Limit", "callback_data": CALLBACK_DECOY_LIMIT}
            ],
            [
                {"text": "⚖️ File Weights", "callback_data": CALLBACK_DECOY_WEIGHTS}
            ],
            [
                {"text": "✅ Enable", "callback_data": CALLBACK_DECOY_ENABLE},
                {"text": "🔴 Disable", "callback_data": CALLBACK_DECOY_DISABLE}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_DECOY_MAIN}
            ]
        ]
    }


def build_decoy_weights_menu():
    """
    Build Decoy file weights selection keyboard
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "🖼️ JPG", "callback_data": "decoy_weight:jpg"},
                {"text": "📄 PDF", "callback_data": "decoy_weight:pdf"}
            ],
            [
                {"text": "🎬 MP4", "callback_data": "decoy_weight:mp4"},
                {"text": "🎵 MP3", "callback_data": "decoy_weight:mp3"}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_DECOY_SETTINGS}
            ]
        ]
    }


def build_decoy_weight_edit_keyboard(file_type: str, current_weight: int):
    """
    Build keyboard for editing specific file type weight
    Args:
        file_type: Type (jpg, pdf, mp4, mp3)
        current_weight: Current weight value
    Returns dict for JSON serialization
    """
    type_names = {"jpg": "🖼️ JPG", "pdf": "📄 PDF", "mp4": "🎬 MP4", "mp3": "🎵 MP3"}
    type_name = type_names.get(file_type, file_type)

    return {
        "inline_keyboard": [
            [
                {"text": "◀️ -1", "callback_data": f"decoy_weight_dec:{file_type}"},
                {"text": f"Current: {current_weight}", "callback_data": "weight_info"},
                {"text": "➡️ +1", "callback_data": f"decoy_weight_inc:{file_type}"}
            ],
            [
                {"text": "⏮️ -5", "callback_data": f"decoy_weight_dec5:{file_type}"},
                {"text": "➡️ +5", "callback_data": f"decoy_weight_inc5:{file_type}"}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_DECOY_WEIGHTS}
            ]
        ]
    }


def build_decoy_advanced_menu():
    """
    Build Decoy advanced actions menu (cleanup, regenerate)
    Returns dict for JSON serialization
    """
    return {
        "inline_keyboard": [
            [
                {"text": "🧹 Cleanup Old", "callback_data": CALLBACK_DECOY_CLEANUP},
                {"text": "🔄 Regenerate All", "callback_data": CALLBACK_DECOY_REGENERATE}
            ],
            [
                {"text": "◀️ Back", "callback_data": CALLBACK_DECOY_SETTINGS}
            ]
        ]
    }
