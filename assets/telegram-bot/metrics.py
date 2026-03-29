#!/usr/bin/env python3
"""
Metrics Collection Module
Collects system metrics: CPU, RAM, disk, uptime, active users
"""

import subprocess  # nosec B404
import sqlite3
import os
import time
import logging
from typing import Tuple, Union

logger = logging.getLogger(__name__)

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# File paths / Пути к файлам
DEFAULT_DB_PATH = "/var/lib/marzban/db.sqlite3"

# Time delays in seconds / Временные задержки в секундах
CPU_READ_DELAY = 0.01  # Minimal delay between CPU readings
DB_TIMEOUT = 5  # Database connection timeout
DISK_CHECK_TIMEOUT = 5  # Disk check command timeout

# File paths / Системные файлы
PROC_STAT_PATH = "/proc/stat"
PROC_MEMINFO_PATH = "/proc/meminfo"
PROC_UPTIME_PATH = "/proc/uptime"

# Unit conversion / Конвертация единиц
KB_TO_MB_DIVISOR = 1024  # Convert kB to MB
SECONDS_PER_DAY = 86400
SECONDS_PER_HOUR = 3600
SECONDS_PER_MINUTE = 60


class MetricsError(Exception):
    """Custom exception for metrics collection errors"""
    pass


class MetricsCollector:
    """Collects system metrics"""

    def __init__(self, db_path=DEFAULT_DB_PATH):
        self.db_path = db_path

    def get_cpu(self):
        """
        Get CPU usage from /proc/stat
        Reads twice with minimal delay
        Returns:
            float: CPU usage percentage
        """
        try:
            def read_cpu_stats():
                with open(PROC_STAT_PATH) as f:
                    line = f.readline()
                parts = line.split()[1:8]
                return [int(x) for x in parts]

            cpu1 = read_cpu_stats()
            time.sleep(CPU_READ_DELAY)
            cpu2 = read_cpu_stats()

            delta = [cpu2[i] - cpu1[i] for i in range(len(cpu1))]
            total = sum(delta)
            idle = delta[3]

            if total == 0:
                return 0.0
            return round((1 - idle / total) * 100, 1)
        except FileNotFoundError as e:
            logger.error(f"CPU stats file not found: {e}")
            return 0.0
        except (IOError, OSError) as e:
            logger.error(f"Error reading CPU stats: {e}")
            return 0.0
        except (ValueError, IndexError) as e:
            logger.error(f"Error parsing CPU stats: {e}")
            return 0.0
        except Exception as e:
            logger.error(f"Unexpected error getting CPU: {e}")
            return 0.0

    def get_ram(self):
        """
        Get RAM usage from /proc/meminfo
        Returns tuple: (used_mb, total_mb, used_percent)
        """
        try:
            meminfo = {}
            with open(PROC_MEMINFO_PATH) as f:
                for line in f:
                    parts = line.split()
                    meminfo[parts[0].rstrip(":")] = int(parts[1]) // KB_TO_MB_DIVISOR

            total = meminfo.get("MemTotal", 0)
            available = meminfo.get("MemAvailable", meminfo.get("MemFree", 0))
            used = total - available
            pct = round(used / total * 100, 1) if total > 0 else 0.0
            return used, total, pct
        except FileNotFoundError as e:
            logger.error(f"Memory info file not found: {e}")
            return 0, 0, 0.0
        except (IOError, OSError) as e:
            logger.error(f"Error reading memory info: {e}")
            return 0, 0, 0.0
        except (ValueError, KeyError) as e:
            logger.error(f"Error parsing memory info: {e}")
            return 0, 0, 0.0
        except Exception as e:
            logger.error(f"Unexpected error getting RAM: {e}")
            return 0, 0, 0.0

    def get_disk(self):
        """
        Get disk usage from df
        Returns tuple: (used_gb, total_gb, used_percent)
        """
        try:
            result = subprocess.run(  # nosec B607, B603
                ["df", "-BG", "/"],
                capture_output=True,
                text=True,
                timeout=DISK_CHECK_TIMEOUT,
                check=True
            )
            lines = result.stdout.strip().split("\n")
            if len(lines) < 2:
                logger.warning("df output has insufficient lines")
                return 0, 0, 0
            parts = lines[1].split()
            total = int(parts[1].replace("G", ""))
            used = int(parts[2].replace("G", ""))
            pct = int(parts[4].replace("%", ""))
            return used, total, pct
        except subprocess.TimeoutExpired as e:
            logger.error(f"df command timed out: {e}")
            return 0, 0, 0
        except subprocess.CalledProcessError as e:
            logger.error(f"df command failed: {e}")
            return 0, 0, 0
        except (ValueError, IndexError) as e:
            logger.error(f"Error parsing df output: {e}")
            return 0, 0, 0
        except Exception as e:
            logger.error(f"Unexpected error getting disk: {e}")
            return 0, 0, 0

    def get_uptime(self):
        """Get system uptime from /proc/uptime"""
        try:
            with open(PROC_UPTIME_PATH) as f:
                secs = int(float(f.read().split()[0]))
            days = secs // SECONDS_PER_DAY
            hours = (secs % SECONDS_PER_DAY) // SECONDS_PER_HOUR
            minutes = (secs % SECONDS_PER_HOUR) // SECONDS_PER_MINUTE
            return f"{days}d {hours}h {minutes}m"
        except FileNotFoundError as e:
            logger.error(f"Uptime file not found: {e}")
            return "?"
        except (IOError, OSError) as e:
            logger.error(f"Error reading uptime: {e}")
            return "?"
        except (ValueError, IndexError) as e:
            logger.error(f"Error parsing uptime: {e}")
            return "?"
        except Exception as e:
            logger.error(f"Unexpected error getting uptime: {e}")
            return "?"
