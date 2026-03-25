#!/usr/bin/env python3
"""
CubiVeil Telegram Bot — Enhanced Version
Интеграция с утилитами CubiVeil

Команды:
/status      — Статус сервера (CPU, RAM, диск, uptime)
/monitor     — Полный снимок состояния (через monitor.sh)
/backup      — Создать бэкап системы
/backups     — Список доступных бэкапов
/diagnose    — Диагностика системы
/users       — Активные пользователи
/adduser     — Добавить пользователя (интерактивно)
/qr          — QR-код для пользователя
/update       — Проверить обновления
/export       — Экспорт конфигурации
/services     — Статус сервисов
/restart     — Перезапустить сервис
/logs         — Последние логи
/alerts      — Статус алертов
/reports     — Настройка отчётов
/help        — Справка
"""

import os
import sys
import json
import time
import subprocess
import sqlite3
import shutil
import http.client
import tempfile
import glob
from datetime import datetime
import urllib.request
import urllib.parse
import urllib.error

# ── Конфигурация ────────────────────────────────────────────

# Пути к утилитам
UTILS_DIR = os.environ.get("CUBIVEIL_UTILS_DIR", "/opt/cubiveil/utils")
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Проверяем utils_dir
if not os.path.exists(UTILS_DIR):
    UTILS_DIR = os.path.join(PROJECT_DIR, "utils")
if not os.path.exists(UTILS_DIR):
    UTILS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "utils")

# Пути к файлам
DB_PATH = "/var/lib/marzban/db.sqlite3"
BAK_DIR = "/opt/cubiveil-bot/backups"
STATE_FILE = "/opt/cubiveil-bot/alert_state.json"
MARZBAN_DIR = "/opt/marzban"

# Чувствительные данные из переменных окружения
TOKEN = os.environ.get("TG_TOKEN")
CHAT_ID = os.environ.get("TG_CHAT_ID")

# Пороги алертов
ALERT_CPU = int(os.environ.get("ALERT_CPU", "80"))
ALERT_RAM = int(os.environ.get("ALERT_RAM", "85"))
ALERT_DISK = int(os.environ.get("ALERT_DISK", "90"))

# Валидация диапазонов
ALERT_CPU = min(100, max(0, ALERT_CPU))
ALERT_RAM = min(100, max(0, ALERT_RAM))
ALERT_DISK = min(100, max(0, ALERT_DISK))

if not TOKEN or not CHAT_ID:
    print("[bot] ОШИБКА: TG_TOKEN и TG_CHAT_ID должны быть заданы")
    sys.exit(1)

os.makedirs(BAK_DIR, exist_ok=True)
os.makedirs("/tmp/cubiveil-bot", exist_ok=True)


# ── Утилиты для работы с Telegram ────────────────────────

def tg_send(text, parse_mode="HTML"):
    """Отправить текстовое сообщение"""
    url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
    data = urllib.parse.urlencode(
        {"chat_id": CHAT_ID, "text": text, "parse_mode": parse_mode}
    ).encode()
    try:
        urllib.request.urlopen(url, data, timeout=10)
    except Exception as e:
        print(f"[bot] Ошибка отправки: {e}")


def tg_send_file(path, caption=""):
    """Отправить файл"""
    if not os.path.exists(path):
        tg_send("⚠️ Файл не найден")
        return
    boundary = "CubiVeilBoundary"
    filename = os.path.basename(path)
    with open(path, "rb") as f:
        file_data = f.read()

    def field(name, value):
        return (
            f"--{boundary}\r\nContent-Disposition: form-data; "
            f'name="{name}"\r\n\r\n{value}\r\n'
        ).encode()

    body = (
        field("chat_id", CHAT_ID)
        + field("caption", caption)
        + f"--{boundary}\r\nContent-Disposition: form-data; "
        f'name="document"; filename="{filename}"\r\n'
        f"Content-Type: application/octet-stream\r\n\r\n".encode()
        + file_data
        + f"\r\n--{boundary}--\r\n".encode()
    )
    try:
        conn = http.client.HTTPSConnection("api.telegram.org")
        conn.request(
            "POST",
            f"/bot{TOKEN}/sendDocument",
            body,
            {"Content-Type": f"multipart/form-data; boundary={boundary}"},
        )
        conn.getresponse()
    except Exception as e:
        print(f"[bot] Ошибка отправки файла: {e}")


def tg_send_action(action="typing"):
    """Отправить action (typing, upload_document и т.д.)"""
    url = f"https://api.telegram.org/bot{TOKEN}/sendChatAction"
    data = urllib.parse.urlencode(
        {"chat_id": CHAT_ID, "action": action}
    ).encode()
    try:
        urllib.request.urlopen(url, data, timeout=5)
    except Exception as e:
        pass


# ── Запуск утилит CubiVeil ───────────────────────────────

def run_utility(name, args=None, timeout=120):
    """
    Запустить утилиту CubiVeil и вернуть вывод

    Args:
        name: имя утилиты (monitor, backup, diagnose и т.д.)
        args: список аргументов
        timeout: таймаут выполнения

    Returns:
        (returncode, stdout, stderr)
    """
    util_path = os.path.join(UTILS_DIR, f"{name}.sh")

    if not os.path.exists(util_path):
        # Проверяем с суффиксом .sh
        if not util_path.endswith(".sh"):
            util_path += ".sh"
        if not os.path.exists(util_path):
            return -1, "", f"Утилита не найдена: {util_path}"

    cmd = ["bash", util_path]
    if args:
        cmd.extend(args)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=UTILS_DIR
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", f"Таймаут выполнения ({timeout} сек)"
    except Exception as e:
        return -1, "", str(e)


# ── Метрики системы ───────────────────────────────────────────

def get_cpu():
    """Получает загрузку CPU"""
    try:
        def read_cpu_stats():
            with open("/proc/stat") as f:
                line = f.readline()
            parts = line.split()[1:8]
            return [int(x) for x in parts]

        cpu1 = read_cpu_stats()
        time.sleep(0.01)
        cpu2 = read_cpu_stats()

        delta = [cpu2[i] - cpu1[i] for i in range(len(cpu1))]
        total = sum(delta)
        idle = delta[3]

        if total == 0:
            return 0.0
        return round((1 - idle / total) * 100, 1)
    except Exception as e:
        print(f"[bot] Ошибка получения CPU: {e}")
        return 0.0


def get_ram():
    """Получает использование RAM"""
    try:
        meminfo = {}
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split()
                meminfo[parts[0].rstrip(":")] = (
                    int(parts[1]) // 1024
                )

        total = meminfo.get("MemTotal", 0)
        available = meminfo.get("MemAvailable", meminfo.get("MemFree", 0))
        used = total - available
        pct = round(used / total * 100, 1) if total > 0 else 0.0
        return used, total, pct
    except Exception as e:
        print(f"[bot] Ошибка получения RAM: {e}")
        return 0, 0, 0.0


def get_disk():
    """Получает использование диска"""
    try:
        r = subprocess.run(["df", "-BG", "/"], capture_output=True, text=True, timeout=5)
        lines = r.stdout.strip().split("\n")
        if len(lines) < 2:
            return 0, 0, 0
        p = lines[1].split()
        total = int(p[1].replace("G", ""))
        used = int(p[2].replace("G", ""))
        pct = int(p[4].replace("%", ""))
        return used, total, pct
    except Exception as e:
        print(f"[bot] Ошибка получения диска: {e}")
        return 0, 0, 0


def get_uptime():
    """Получает uptime"""
    try:
        with open("/proc/uptime") as f:
            secs = int(float(f.read().split()[0]))
        d = secs // 86400
        h = (secs % 86400) // 3600
        m = (secs % 3600) // 60
        return f"{d}д {h}ч {m}м"
    except Exception as e:
        print(f"[bot] Ошибка получения uptime: {e}")
        return "?"


def get_service_status(service):
    """Получить статус сервиса"""
    try:
        result = subprocess.run(
            ["systemctl", "is-active", service],
            capture_output=True,
            text=True,
            timeout=5
        )
        status = result.stdout.strip()
        if status == "active":
            return "🟢", "active"
        elif status == "inactive":
            return "🔴", "inactive"
        elif status == "failed":
            return "🔴", "failed"
        else:
            return "🟡", status
    except Exception as e:
        return "⚪", "unknown"


def get_active_users():
    """Получает количество активных пользователей из БД"""
    if not os.path.exists(DB_PATH):
        return "?"
    try:
        conn = sqlite3.connect(DB_PATH, timeout=5)
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM users WHERE status='active'")
        count = cur.fetchone()[0]
        conn.close()
        return count
    except Exception as e:
        print(f"[bot] Ошибка получения пользователей: {e}")
        return "?"


def bar(pct, width=10):
    """Визуальная шкала загрузки"""
    filled = int(min(pct, 100) / 100 * width)
    return "█" * filled + "░" * (width - filled)


# ── Функция бэкапа БД (для совместимости) ────────────────

def make_backup():
    """Создаёт бэкап БД и удаляет старые бэкапы (>7 дней)"""
    ts = datetime.now().strftime("%Y%m%d_%H%M")
    dst = f"{BAK_DIR}/marzban_{ts}.sqlite3"
    try:
        shutil.copy2(DB_PATH, dst)
        # Удаляем бэкапы старше 7 дней
        now = time.time()
        for fn in os.listdir(BAK_DIR):
            fp = os.path.join(BAK_DIR, fn)
            if os.path.isfile(fp) and now - os.path.getmtime(fp) > 7 * 86400:
                os.remove(fp)
                print(f"[bot] Удалён старый бэкап: {fn}")
        return dst
    except Exception as e:
        print(f"[bot] Ошибка бэкапа: {e}")
        return None


# ── Команды бота ─────────────────────────────────────────────

# ── /status — Статус сервера ───────────────────────────────

def cmd_status():
    """Показать краткий статус сервера"""
    cpu = get_cpu()
    ram_u, ram_t, ram_p = get_ram()
    dsk_u, dsk_t, dsk_p = get_disk()
    uptime = get_uptime()
    users = get_active_users()

    ci = "🔴" if cpu > ALERT_CPU else "🟢"
    ri = "🔴" if ram_p > ALERT_RAM else "🟢"
    di = "🔴" if dsk_p > ALERT_DISK else "🟢"

    tg_send(
        f"<b>📊 Статус сервера</b>\n"
        f"<code>{datetime.now().strftime('%d.%m.%Y %H:%M')}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━\n"
        f"{ci} CPU:    {cpu}%  {bar(cpu)}\n"
        f"{ri} RAM:    {ram_u}/{ram_t} МБ ({ram_p}%)\n"
        f"{di} Диск:   {dsk_u}/{dsk_t} ГБ ({dsk_p}%)\n"
        f"⏱ Uptime:  {uptime}\n"
        f"👥 Пользователи: <b>{users}</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━\n"
        f"<i>Используй /monitor для подробного состояния</i>"
    )


# ── /monitor — Полный снимок состояния ───────────────────────

def cmd_monitor():
    """Полный снимок состояния через monitor.sh"""
    tg_send("⏳ Получаю снимок состояния...")
    tg_send_action("typing")

    returncode, stdout, stderr = run_utility("monitor", ["--snapshot"], timeout=30)

    if returncode == 0:
        # Сохраняем в файл для отправки
        temp_file = f"/tmp/cubiveil-bot/monitor_{int(time.time())}.txt"
        with open(temp_file, "w") as f:
            f.write(stdout)

        tg_send("✅ Снимок получен, отправляю файл...")
        tg_send_file(
            temp_file,
            f"📊 Server Snapshot\n\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
    else:
        tg_send(
            f"❌ Ошибка получения снимка:\n"
            f"<code>{stderr[:500]}</code>"
        )


# ── /backup — Создать бэкап ─────────────────────────────────

def cmd_backup():
    """Создать бэкап через backup.sh"""
    tg_send("⏳ Создаю бэкап системы...")
    tg_send_action("upload_document")

    returncode, stdout, stderr = run_utility(
        "backup",
        ["create", "--no-interact"],
        timeout=300  # 5 минут
    )

    if returncode == 0:
        # Ищем путь к архиву в выводе
        backup_path = None
        for line in stdout.split('\n'):
            if '/cubiveil-backup-' in line and '.tar.gz' in line:
                backup_path = line.split(']')[-1].strip()
                break

        if backup_path and os.path.exists(backup_path):
            tg_send("✅ Бэкап создан успешно")
            tg_send_file(
                backup_path,
                f"📦 CubiVeil Backup\n\n"
                f"Created: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
            )
        else:
            tg_send("✅ Бэкап создан (файл не найден для отправки)")
    else:
        tg_send(
            f"❌ Ошибка создания бэкапа:\n"
            f"<code>{stderr[:500]}</code>"
        )


# ── /backups — Список бэкапов ───────────────────────────────

def cmd_backups():
    """Список доступных бэкапов"""
    returncode, stdout, stderr = run_utility("backup", ["list"], timeout=30)

    if returncode == 0:
        # Форматируем для Telegram
        lines = stdout.split('\n')
        formatted = []
        for line in lines:
            if line.strip():
                formatted.append(f"<code>{line}</code>")

        tg_send(
            f"📦 <b>Доступные бэкапы</b>\n\n"
            f"{'<br>'.join(formatted)}\n\n"
            f"<i>Используй /backup для создания нового</i>"
        )
    else:
        tg_send(f"❌ Ошибка получения списка:\n<code>{stderr[:300]}</code>")


# ── /diagnose — Диагностика ─────────────────────────────────

def cmd_diagnose():
    """Запустить диагностику"""
    tg_send("🔍 Запускаю диагностику...")
    tg_send_action("typing")

    returncode, stdout, stderr = run_utility("diagnose", [], timeout=120)

    if returncode == 0:
        # Ищем файл отчёта
        report_path = None
        reports = glob.glob("/root/cubiveil-diagnose/diagnose_report_*.txt")
        if reports:
            report_path = max(reports, key=os.path.getctime)

        if report_path and os.path.exists(report_path):
            tg_send("✅ Диагностика завершена")
            tg_send_file(
                report_path,
                f"📋 Diagnose Report\n\n"
                f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
            )
        else:
            # Отправляем краткий отчёт текстом
            tg_send(
                f"✅ <b>Диагностика завершена</b>\n\n"
                f"<code>{stdout[-1000:]}</code>"
            )
    else:
        tg_send(
            f"❌ Ошибка диагностики:\n"
            f"<code>{stderr[:500]}</code>"
        )


# ── /users — Список пользователей ─────────────────────────────

def cmd_users():
    """Список пользователей через manage-profiles.sh"""
    returncode, stdout, stderr = run_utility("manage-profiles", ["list"], timeout=30)

    if returncode == 0:
        lines = stdout.split('\n')
        # Ограничиваем вывод
        if len(lines) > 50:
            lines = lines[:50] + ["..."]
            tg_send("⚠️ Список слишком длинный, показаны первые 50 строк")

        formatted = []
        for line in lines:
            if line.strip():
                formatted.append(f"<code>{line}</code>")

        tg_send(
            f"👥 <b>Пользователи</b>\n\n"
            f"{'<br>'.join(formatted)}"
        )
    else:
        tg_send(f"❌ Ошибка получения списка:\n<code>{stderr[:300]}</code>")


# ── /adduser — Добавить пользователя ───────────────────────────

def cmd_adduser():
    """Инструкция по добавлению пользователя"""
    tg_send(
        "➕ <b>Добавление пользователя</b>\n\n"
        "Для добавления пользователя используйте SSH:\n"
        "<code>bash /opt/cubiveil/utils/manage-profiles.sh add</code>\n\n"
        "Это интерактивный процесс, требующий ввода данных пользователя."
    )


# ── /qr — QR-код для пользователя ────────────────────────────

def cmd_qr(args):
    """Сгенерировать QR-код"""
    if not args:
        tg_send("❌ Использование: /qr &lt;username&gt;")
        return

    username = args[0]
    tg_send(f"⏳ Генерирую QR для <code>{username}</code>...")
    tg_send_action("typing")

    returncode, stdout, stderr = run_utility(
        "manage-profiles",
        ["qr", username],
        timeout=30
    )

    if returncode == 0:
        # Парсим QR из вывода (ищем символы █)
        qr_lines = []
        qr_found = False
        for line in stdout.split('\n'):
            if '█' in line or '▀' in line or '▄' in line:
                qr_found = True
                qr_lines.append(line)
            elif qr_found and line.strip() == '':
                break

        if qr_lines:
            qr_code = '\n'.join(qr_lines[:20])  # Ограничиваем высоту
            tg_send(
                f"📱 <b>QR для {username}</b>\n\n"
                f"<code>{qr_code}</code>\n\n"
                f"<i>QR-код обрезан для Telegram. "
                f"Используй SSH для полного QR.</i>"
            )
        else:
            # Отправляем ссылку
            for line in stdout.split('\n'):
                if 'https://' in line:
                    tg_send(
                        f"🔗 <b>Ссылка для {username}</b>\n\n"
                        f"<code>{line.strip()}</code>"
                    )
                    return

        tg_send(f"⚠️ Не удалось извлечь QR/ссылку")
    else:
        tg_send(f"❌ Ошибка:\n<code>{stderr[:300]}</code>")


# ── /update — Проверка обновлений ─────────────────────────────

def cmd_update():
    """Проверить и показать информацию об обновлениях"""
    tg_send("🔍 Проверяю обновления...")
    tg_send_action("typing")

    # Проверяем версию (без установки)
    returncode, stdout, stderr = run_utility("update", [], timeout=60)

    if "Новая версия доступна" in stdout or "New version available" in stdout:
        tg_send(
            "🆕 <b>Доступна новая версия!</b>\n\n"
            "Для обновления выполните через SSH:\n"
            "<code>bash /opt/cubiveil/utils/update.sh</code>\n\n"
            "⚠️ Перед обновлением будет создан автоматический бэкап."
        )
    elif "Уже актуально" in stdout or "Up to date" in stdout or returncode == 0:
        tg_send("✅ <b>Система обновлена!</b>")
    else:
        tg_send(
            f"⚠️ <b>Не удалось проверить обновления</b>\n\n"
            f"<code>{stderr[:300]}</code>"
        )


# ── /export — Экспорт конфигурации ───────────────────────────

def cmd_export():
    """Экспорт конфигурации через export-config.sh"""
    tg_send("⏳ Экспортирую конфигурацию...")
    tg_send_action("upload_document")

    returncode, stdout, stderr = run_utility("export-config", [], timeout=30)

    if returncode == 0:
        # Сохраняем как файл
        export_path = f"/tmp/cubiveil-bot/export_{int(time.time())}.json"
        with open(export_path, "w") as f:
            f.write(stdout)

        tg_send("✅ Конфигурация экспортирована")
        tg_send_file(
            export_path,
            f"📄 CubiVeil Configuration\n\n"
            f"Exported: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
        )
    else:
        tg_send(
            f"❌ Ошибка экспорта:\n"
            f"<code>{stderr[:300]}</code>"
        )


# ── /services — Статус сервисов ───────────────────────────────

def cmd_services():
    """Статус всех сервисов"""
    services = [
        ("marzban", "Marzban Panel"),
        ("sing-box", "Sing-box Core"),
        ("cubiveil-bot", "CubiVeil Bot"),
        ("ufw", "Firewall (UFW)"),
        ("fail2ban", "Fail2ban"),
        ("marzban-health", "Health Check"),
    ]

    status_text = []
    for service, name in services:
        emoji, status = get_service_status(service)
        status_text.append(f"{emoji} <b>{name}</b>: {status}")

    tg_send(
        "🔧 <b>Статус сервисов</b>\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "\n".join(status_text)
    )


# ── /restart — Перезапуск сервиса ─────────────────────────────

def cmd_restart(args):
    """Перезапустить сервис"""
    if not args:
        tg_send(
            "❌ Использование: /restart &lt;service&gt;\n\n"
            "Доступные сервисы:\n"
            "• marzban\n"
            "• sing-box\n"
            "• cubiveil-bot\n"
            "• all (все сервисы)"
        )
        return

    service = args[0].lower()

    if service == "all":
        services = ["sing-box", "marzban", "cubiveil-bot"]
        tg_send("🔄 Перезапускаю все сервисы...")
    elif service in ["marzban", "sing-box", "cubiveil-bot"]:
        services = [service]
        tg_send(f"🔄 Перезапускаю {service}...")
    else:
        tg_send(f"❌ Неизвестный сервис: {service}")
        return

    restarted = []
    failed = []

    for svc in services:
        try:
            result = subprocess.run(
                ["systemctl", "restart", svc],
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0:
                time.sleep(2)
                if subprocess.run(
                    ["systemctl", "is-active", svc],
                    capture_output=True,
                    timeout=5
                ).stdout.strip() == "active":
                    restarted.append(svc)
                else:
                    failed.append(svc)
            else:
                failed.append(svc)
        except Exception as e:
            failed.append(svc)
            print(f"[bot] Ошибка перезапуска {svc}: {e}")

    if restarted:
        tg_send(f"✅ Перезапущено: {', '.join(restarted)}")
    if failed:
        tg_send(f"❌ Ошибка: {', '.join(failed)}")


# ── /logs — Последние логи ──────────────────────────────────

def cmd_logs(args):
    """Получить последние логи"""
    service = args[0] if args else "marzban"
    lines = int(args[1]) if len(args) > 1 else 20

    if service not in ["marzban", "sing-box", "cubiveil-bot"]:
        tg_send("❌ Использование: /logs &lt;service&gt; [lines]\n\nДоступные сервисы: marzban, sing-box, cubiveil-bot")
        return

    tg_send(f"⏳ Получаю последние {lines} строк логов {service}...")
    tg_send_action("typing")

    try:
        result = subprocess.run(
            ["journalctl", "-u", service, "-n", str(lines), "--no-pager"],
            capture_output=True,
            text=True,
            timeout=30
        )

        logs = result.stdout[-2000:]  # Ограничиваем размер

        # Форматируем для Telegram
        log_lines = logs.split('\n')
        formatted = []
        for line in log_lines[-lines:]:
            if line.strip():
                formatted.append(f"<code>{line[:100]}</code>")

        tg_send(
            f"📋 <b>Логи {service}</b> (последние {lines} строк)\n\n"
            f"{'<br>'.join(formatted)}\n\n"
            f"<i>Полные логи: journalctl -u {service} -f</i>"
        )
    except Exception as e:
        tg_send(f"❌ Ошибка получения логов:\n<code>{str(e)[:300]}</code>")


# ── /alerts — Статус алертов ───────────────────────────────

def cmd_alerts():
    """Показать статус алертов"""
    cpu = get_cpu()
    _, ram_p = get_ram()
    _, _, dsk_p = get_disk()

    status_lines = [
        f"{'🔴' if cpu > ALERT_CPU else '🟢'} CPU: {cpu}% (порог: {ALERT_CPU}%)",
        f"{'🔴' if ram_p > ALERT_RAM else '🟢'} RAM: {ram_p}% (порог: {ALERT_RAM}%)",
        f"{'🔴' if dsk_p > ALERT_DISK else '🟢'} Диск: {dsk_p}% (порог: {ALERT_DISK}%)",
    ]

    # Загружаем состояние алертов
    try:
        with open(STATE_FILE) as f:
            state = json.load(f)
        if state.get("cpu"):
            status_lines[0] += " ⚠️ АКТИВЕН"
        if state.get("ram"):
            status_lines[1] += " ⚠️ АКТИВЕН"
        if state.get("disk"):
            status_lines[2] += " ⚠️ АКТИВЕН"
    except:
        pass

    tg_send(
        "⚠️ <b>Статус алертов</b>\n\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "\n".join(status_lines)
    )


# ── /reports — Настройка отчётов ────────────────────────────

def cmd_reports():
    """Информация о настройках отчётов"""
    try:
        # Читаем crontab для отчётов
        result = subprocess.run(
            ["crontab", "-l"],
            capture_output=True,
            text=True,
            timeout=5
        )

        cron_jobs = []
        for line in result.stdout.split('\n'):
            if 'cubiveil-bot' in line:
                cron_jobs.append(f"<code>{line}</code>")

        if not cron_jobs:
            cron_info = "⚠️ Автоотчёты не настроены"
        else:
            cron_info = "\n".join(cron_jobs)

        tg_send(
            "📊 <b>Настройки отчётов</b>\n\n"
            "━━━━━━━━━━━━━━━━━━━━━\n"
            f"📧 E-mail: {os.environ.get('LE_EMAIL', 'не настроен')}\n"
            f"👥 Chat ID: <code>{CHAT_ID}</code>\n\n"
            f"⏰ Расписание:\n{cron_info}\n\n"
            f"<i>Изменить расписание можно через crontab</i>"
        )
    except Exception as e:
        tg_send(f"❌ Ошибка:\n<code>{str(e)[:300]}</code>")


# ── /help — Справка ─────────────────────────────────────────

def cmd_help():
    """Показать справку"""
    help_text = """
<b>🛡 CubiVeil Bot — Справка</b>

━━━━━━━━━━━━━━━━━━━━━

📊 <b>Мониторинг</b>
/status    — Краткий статус сервера
/monitor   — Полный снимок состояния
/services  — Статус всех сервисов
/alerts    — Статус алертов
/logs      — Последние логи

💾 <b>Бэкапы</b>
/backup    — Создать бэкап
/backups   — Список бэкапов

👥 <b>Пользователи</b>
/users     — Список пользователей
/adduser   — Добавить пользователя (SSH)
/qr &lt;user&gt; — QR-код для пользователя

🔧 <b>Управление</b>
/restart &lt;svc&gt; — Перезапустить сервис
/update    — Проверить обновления
/export    — Экспорт конфигурации
/diagnose  — Диагностика системы

📊 <b>Отчёты</b>
/reports   — Настройка отчётов

━━━━━━━━━━━━━━━━━━━━━

<i>Все команды доступны только для авторизованного chat_id</i>
"""
    tg_send(help_text)


# ── Ежедневный отчёт (для cron) ─────────────────────────────

def send_daily_report():
    """Отправить ежедневный отчёт"""
    cpu = get_cpu()
    ram_u, ram_t, ram_p = get_ram()
    dsk_u, dsk_t, dsk_p = get_disk()
    uptime = get_uptime()
    users = get_active_users()
    now = datetime.now().strftime("%d.%m.%Y %H:%M UTC")

    ci = "🔴" if cpu > ALERT_CPU else "🟢"
    ri = "🔴" if ram_p > ALERT_RAM else "🟢"
    di = "🔴" if dsk_p > ALERT_DISK else "🟢"

    tg_send(
        f"<b>🛡 CubiVeil — ежедневный отчёт</b>\n"
        f"<code>{now}</code>\n"
        f"━━━━━━━━━━━━━━━━━━━━━\n"
        f"{ci} CPU:   {cpu}%  {bar(cpu)}\n"
        f"{ri} RAM:   {ram_u}/{ram_t} МБ ({ram_p}%)\n"
        f"{di} Диск:  {dsk_u}/{dsk_t} ГБ ({dsk_p}%)\n"
        f"⏱ Uptime:  {uptime}\n"
        f"━━━━━━━━━━━━━━━━━━━━━\n"
        f"👥 Активных пользователей: <b>{users}</b>\n"
        f"━━━━━━━━━━━━━━━━━━━━━\n"
        f"📦 Бэкап базы прикреплён ниже"
    )

    bak = make_backup()
    if bak:
        tg_send_file(bak, f"Бэкап Marzban • {datetime.now().strftime('%d.%m.%Y')}")
    else:
        tg_send("⚠️ Не удалось создать бэкап базы")


# ── Алерты (для cron) ────────────────────────────────────────

def load_state():
    try:
        with open(STATE_FILE) as f:
            return json.load(f)
    except:
        return {}


def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f)


def check_alerts():
    """
    Отправляем алерт только при переходе из нормы в превышение.
    Не спамим каждые 15 минут если порог уже превышен.
    """
    state = load_state()
    alerts = []
    new_state = {}

    cpu = get_cpu()
    cpu_alert = cpu > ALERT_CPU
    if cpu_alert and not state.get("cpu"):
        alerts.append(f"🔴 <b>CPU</b>: {cpu}% (порог {ALERT_CPU}%)")
    new_state["cpu"] = cpu_alert

    _, _, ram_p = get_ram()
    ram_alert = ram_p > ALERT_RAM
    if ram_alert and not state.get("ram"):
        alerts.append(f"🔴 <b>RAM</b>: {ram_p}% (порог {ALERT_RAM}%)")
    new_state["ram"] = ram_alert

    _, _, dsk_p = get_disk()
    dsk_alert = dsk_p > ALERT_DISK
    if dsk_alert and not state.get("disk"):
        alerts.append(f"🔴 <b>Диск</b>: {dsk_p}% (порог {ALERT_DISK}%)")
    new_state["disk"] = dsk_alert

    save_state(new_state)

    if alerts:
        tg_send(
            "⚠️ <b>CubiVeil — Алерт!</b>\n"
            "━━━━━━━━━━━━━━━\n" + "\n".join(alerts)
        )


# ── Обработка команд ───────────────────────────────────────────

COMMANDS = {
    "start": cmd_status,
    "status": cmd_status,
    "monitor": cmd_monitor,
    "backup": cmd_backup,
    "backups": cmd_backups,
    "diagnose": cmd_diagnose,
    "users": cmd_users,
    "adduser": cmd_adduser,
    "qr": cmd_qr,
    "update": cmd_update,
    "export": cmd_export,
    "services": cmd_services,
    "restart": cmd_restart,
    "logs": cmd_logs,
    "alerts": cmd_alerts,
    "reports": cmd_reports,
    "help": cmd_help,
}


def handle_command(text):
    """Обработать команду от пользователя"""
    parts = text.strip().split()
    cmd = parts[0].lower()
    args = parts[1:]

    handler = COMMANDS.get(cmd)
    if handler:
        try:
            if cmd == "qr":
                handler(args)
            elif cmd == "restart":
                handler(args)
            elif cmd == "logs":
                handler(args)
            else:
                handler()
        except Exception as e:
            print(f"[bot] Ошибка выполнения команды {cmd}: {e}")
            tg_send(f"❌ Ошибка: <code>{str(e)[:300]}</code>")
    else:
        tg_send("❌ Неизвестная команда. /help — список команд")


# ── Polling ───────────────────────────────────────────────────

def poll():
    """Основной цикл polling"""
    offset = 0

    tg_send(
        "🟢 <b>CubiVeil Bot запущен</b>\n"
        f"Алерты: CPU>{ALERT_CPU}% RAM>{ALERT_RAM}% Диск>{ALERT_DISK}%\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "📊 Мониторинг: /status, /monitor\n"
        "💾 Бэкапы: /backup, /backups\n"
        "👥 Пользователи: /users, /qr &lt;user&gt;\n"
        "🔧 Управление: /restart, /update, /diagnose\n"
        "━━━━━━━━━━━━━━━━━━━━━\n"
        "❓ Справка: /help"
    )

    while True:
        try:
            url = (
                f"https://api.telegram.org/bot{TOKEN}/getUpdates"
                f"?offset={offset}&timeout=30&allowed_updates=[\"message\"]"
            )
            with urllib.request.urlopen(url, timeout=35) as resp:
                data = json.loads(resp.read())

            for upd in data.get("result", []):
                offset = upd["update_id"] + 1
                msg = upd.get("message", {})

                # Строгая авторизация — только свой chat_id
                if str(msg.get("chat", {}).get("id", "")) != str(CHAT_ID):
                    continue

                text = msg.get("text", "")
                if text.startswith("/"):
                    handle_command(text)

        except urllib.error.URLError:
            time.sleep(10)
        except Exception as e:
            print(f"[bot] poll error: {e}")
            time.sleep(5)


# ── Точка входа ─────────────────────────────────────────────

if __name__ == "__main__":
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        if cmd == "report":
            send_daily_report()
        elif cmd == "alert":
            check_alerts()
        elif cmd == "poll":
            poll()
        else:
            print(f"Неизвестная команда: {cmd}")
            print("Использование: python3 cubiveil-bot.py [report|alert|poll]")
    else:
        poll()
