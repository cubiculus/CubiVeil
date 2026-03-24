#!/usr/bin/env python3
"""
Alert State Management Module
Manages alert state to avoid spamming alerts
"""

import json
import os


class AlertStateManager:
    """Manages alert state persistence"""

    def __init__(self, state_file="/opt/cubiveil-bot/alert_state.json"):
        self.state_file = state_file

    def load(self):
        """Load alert state from file"""
        try:
            with open(self.state_file) as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {}

    def save(self, state):
        """Save alert state to file"""
        with open(self.state_file, "w") as f:
            json.dump(state, f)
