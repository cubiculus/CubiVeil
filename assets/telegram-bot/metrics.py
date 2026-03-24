#!/usr/bin/env python3
"""
Metrics Collection Module
Collects system metrics: CPU, RAM, disk, uptime, active users
"""

import subprocess
import sqlite3
import os
import time


class MetricsCollector:
    """Collects system metrics"""

    def __init__(self, db_path="/var/lib/marzban/db.sqlite3"):
        self.db_path = db_path

    def get_cpu(self):
        """
        Get CPU usage from /proc/stat
        Reads twice with minimal delay (10ms instead of 500ms)
        """
        try:
            def read_cpu_stats():
                with open("/proc/stat") as f:
                    line = f.readline()
                parts = line.split()[1:8]  # cpu user nice system idle iowait irq softirq
                return [int(x) for x in parts]

            # Read twice with minimal delay
            cpu1 = read_cpu_stats()
            time.sleep(0.01)
            cpu2 = read_cpu_stats()

            # Calculate difference
            delta = [cpu2[i] - cpu1[i] for i in range(len(cpu1))]
            total = sum(delta)
            idle = delta[3]  # idle

            if total == 0:
                return 0.0
            return round((1 - idle / total) * 100, 1)
        except Exception as e:
            print(f"[bot] Error getting CPU: {e}")
            return 0.0

    def get_ram(self):
        """
        Get RAM usage from /proc/meminfo
        Returns tuple: (used_mb, total_mb, used_percent)
        """
        try:
            meminfo = {}
            with open("/proc/meminfo") as f:
                for line in f:
                    parts = line.split()
                    meminfo[parts[0].rstrip(":")] = int(parts[1]) // 1024  # kB → MB

            total = meminfo.get("MemTotal", 0)
            available = meminfo.get("MemAvailable", meminfo.get("MemFree", 0))
            used = total - available
            pct = round(used / total * 100, 1) if total > 0 else 0.0
            return used, total, pct
        except Exception as e:
            print(f"[bot] Error getting RAM: {e}")
            return 0, 0, 0.0

    def get_disk(self):
        """
        Get disk usage from df
        Returns tuple: (used_gb, total_gb, used_percent)
        """
        try:
            result = subprocess.run(
                ["df", "-BG", "/"],
                capture_output=True,
                text=True,
                timeout=5
            )
            lines = result.stdout.strip().split("\n")
            if len(lines) < 2:
                return 0, 0, 0
            parts = lines[1].split()
            total = int(parts[1].replace("G", ""))
            used = int(parts[2].replace("G", ""))
            pct = int(parts[4].replace("%", ""))
            return used, total, pct
        except Exception as e:
            print(f"[bot] Error getting disk: {e}")
            return 0, 0, 0

    def get_uptime(self):
        """Get system uptime from /proc/uptime"""
        try:
            with open("/proc/uptime") as f:
                secs = int(float(f.read().split()[0]))
            days = secs // 86400
            hours = (secs % 86400) // 3600
            minutes = (secs % 3600) // 60
            return f"{days}d {hours}h {minutes}m"
        except Exception as e:
            print(f"[bot] Error getting uptime: {e}")
            return "?"

    def get_active_users(self):
        """Get count of active users from Marzban database"""
        if not os.path.exists(self.db_path):
            return "?"
        try:
            conn = sqlite3.connect(self.db_path, timeout=5)
            cur = conn.cursor()
            cur.execute("SELECT COUNT(*) FROM users WHERE status='active'")
            count = cur.fetchone()[0]
            conn.close()
            return count
        except Exception as e:
            print(f"[bot] Error getting users: {e}")
            return "?"
