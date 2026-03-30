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

from constants import (
    DEFAULT_DB_PATH,
    SUI_DB_DIR,
    CPU_READ_DELAY,
    DB_TIMEOUT,
    DISK_CHECK_TIMEOUT,
    PROC_STAT_PATH,
    PROC_MEMINFO_PATH,
    PROC_UPTIME_PATH,
    KB_TO_MB_DIVISOR,
    SECONDS_PER_DAY,
    SECONDS_PER_HOUR,
    SECONDS_PER_MINUTE,
)

logger = logging.getLogger(__name__)


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

    def get_active_users(self):
        """
        Get count of active users from S-UI database
        Returns:
            Union[int, str]: Count of active users or "?" if DB not found
        """
        try:
            if not os.path.exists(self.db_path):
                logger.warning(f"S-UI DB not found: {self.db_path}")
                return "?"

            conn = sqlite3.connect(self.db_path, timeout=DB_TIMEOUT)
            cursor = conn.cursor()

            # Count active users (status = 'active')
            cursor.execute(
                "SELECT COUNT(*) FROM users WHERE status = 'active'"
            )
            result = cursor.fetchone()
            conn.close()

            if result:
                return result[0]
            return 0

        except sqlite3.Error as e:
            logger.error(f"Database error getting active users: {e}")
            return "?"
        except Exception as e:
            logger.error(f"Unexpected error getting active users: {e}")
            return "?"
