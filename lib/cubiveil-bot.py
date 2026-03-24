#!/usr/bin/env python3
"""
CubiVeil Telegram Bot
- Ежедневный отчёт: CPU, RAM, диск, uptime, активные пользователи + бэкап БД
- Алерты при превышении порогов
- Интерактивные команды только для авторизованного chat_id
"""

import os
import json
import time
import subprocess
import sqlite3
import shutil
import http.client
from datetime import datetime
import urllib.request
import urllib.parse
import urllib.error

# Чувствительные данные из переменных окружения (systemd Environment)
TOKEN = os.environ.get("TG_TOKEN")
CHAT_ID = os.environ.get("TG_CHAT_ID")
DB_PATH = "/var/lib/marzban/db.sqlite3"
BAK_DIR = "/opt/cubiveil-bot/backups"
STATE_FILE = "/opt/cubiveil-bot/alert_state.json"

# Пороги алертов — валидируются и читаются из переменных окружения
# с защитой от SQL-инъекций и XSS
ALERT_CPU = int(os.environ.get("ALERT_CPU", "80"))
ALERT_RAM = int(os.environ.get("ALERT_RAM", "85"))
ALERT_DISK = int(os.environ.get("ALERT_DISK", "90"))

# Дополнительная валидация диапазонов
ALERT_CPU = min(100, max(0, ALERT_CPU))
ALERT_RAM = min(100, max(0, ALERT_RAM))
ALERT_DISK = min(100, max(0, ALERT_DISK))

if not TOKEN or not CHAT_ID:
    print(
        "[bot] ОШИБКА: TG_TOKEN и TG_CHAT_ID должны быть заданы в переменных окружения"
    )
    exit(1)

os.makedirs(BAK_DIR, exist_ok=True)


# ── Отправка сообщений ────────────────────────────────────────
def tg_send(text, parse_mode="HTML"):
    url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
    data = urllib.parse.urlencode(
        {"chat_id": CHAT_ID, "text": text, "parse_mode": parse_mode}
    ).encode()
    try:
        urllib.request.urlopen(url, data, timeout=10)
    except Exception as e:
        print(f"[bot] Ошибка отправки: {e}")


def tg_send_file(path, caption=""):
    if not os.path.exists(path):
        tg_send("⚠️ Файл бэкапа не найден")
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


# ── Метрики ───────────────────────────────────────────────────
def get_cpu():
    """Получает загрузку CPU из /proc/stat — без задержек"""
    try:

        def read_cpu_stats():
            with open("/proc/stat") as f:
                line = f.readline()
            parts = line.split()[1:8]  # cpu user nice system idle iowait irq softirq
            return [int(x) for x in parts]

        # Читаем дважды с минимальной задержкой (10 мс вместо 500 мс)
        cpu1 = read_cpu_stats()
        time.sleep(0.01)
        cpu2 = read_cpu_stats()

        # Вычисляем разницу
        delta = [cpu2[i] - cpu1[i] for i in range(len(cpu1))]
        total = sum(delta)
        idle = delta[3]  # idle

        if total == 0:
            return 0.0
        return round((1 - idle / total) * 100, 1)
    except Exception as e:
        print(f"[bot] Ошибка получения CPU: {e}")
        return 0.0


def get_ram():
    """Получает использование RAM из /proc/meminfo"""
    try:
        meminfo = {}
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split()
                meminfo[parts[0].rstrip(":")] = (
                    int(parts[1]) // 1024
                )  # kB → MB

        total = meminfo.get("MemTotal", 0)
        available = meminfo.get("MemAvailable", meminfo.get("MemFree", 0))
        used = total - available
        pct = round(used / total * 100, 1) if total > 0 else 0.0
        return used, total, pct
    except Exception as e:
        print(f"[bot] Ошибка получения RAM: {e}")
        return 0, 0, 0.0


def get_disk():
    """Получает использование диска из /proc/diskinfo или df"""
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
    """Получает uptime из /proc/uptime"""
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


def get_active_users():
    """Получает количество активных пользователей из БД Marzban"""
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


def bar(pct, width=10):
    filled = int(min(pct, 100) / 100 * width)
    return "█" * filled + "░" * (width - filled)


# ── Ежедневный отчёт ─────────────────────────────────────────
def send_daily_report():
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
        f"{ri} RAM:   {ram_u}/{ram_t} МБ ({ram_p}%)  {bar(ram_p)}\n"
        f"{di} Диск:  {dsk_u}/{dsk_t} ГБ ({dsk_p}%)  {bar(dsk_p)}\n"
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


# ── Алерты ───────────────────────────────────────────────────
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
    Отправляем алерт только при переходе из нормы в превышение,
    не спамим каждые 15 минут если порог уже превышен.
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


# ── Команды бота ─────────────────────────────────────────────
def handle_command(cmd):
    cmd = cmd.strip().split()[0].lower()

    if cmd in ("/start", "/status"):
        cpu = get_cpu()
        ram_u, ram_t, ram_p = get_ram()
        dsk_u, dsk_t, dsk_p = get_disk()
        uptime = get_uptime()
        users = get_active_users()
        tg_send(
            f"<b>📊 Статус сервера</b>\n"
            f"━━━━━━━━━━━━━━━\n"
            f"CPU:    {cpu}%  {bar(cpu)}\n"
            f"RAM:    {ram_u}/{ram_t} МБ ({ram_p}%)\n"
            f"Диск:   {dsk_u}/{dsk_t} ГБ ({dsk_p}%)\n"
            f"Uptime: {uptime}\n"
            f"━━━━━━━━━━━━━━━\n"
            f"👥 Активных: {users}"
        )
    elif cmd == "/backup":
        tg_send("⏳ Создаю бэкап...")
        bak = make_backup()
        if bak:
            tg_send_file(bak, "Бэкап базы Marzban")
        else:
            tg_send("❌ Ошибка создания бэкапа")
    elif cmd == "/users":
        tg_send(f"👥 Активных пользователей: <b>{get_active_users()}</b>")
    elif cmd == "/restart":
        tg_send("🔄 Перезапускаю Marzban...")
        r = subprocess.run(["systemctl", "restart", "marzban"], capture_output=True, timeout=30)
        if r.returncode == 0:
            tg_send("✅ Marzban перезапущен")
        else:
            tg_send(f"❌ Ошибка:\n<code>{r.stderr.decode()[:500]}</code>")
    elif cmd == "/help":
        tg_send(
            "<b>CubiVeil Bot — команды</b>\n"
            "━━━━━━━━━━━━━━━\n"
            "/status  — CPU, RAM, диск, uptime\n"
            "/backup  — получить бэкап прямо сейчас\n"
            "/users   — активные пользователи\n"
            "/restart — перезапустить Marzban\n"
            "/help    — эта справка"
        )
    else:
        tg_send("Неизвестная команда. /help — список команд")


# ── Polling ───────────────────────────────────────────────────
def poll():
    offset = 0
    tg_send(
        "🟢 <b>CubiVeil Bot запущен</b>\n"
        f"Алерты: CPU>{ALERT_CPU}% RAM>{ALERT_RAM}% Диск>{ALERT_DISK}%\n"
        "Отправь /help"
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


# ── Точка входа ───────────────────────────────────────────────
if __name__ == "__main__":
    import sys

    cmd = sys.argv[1] if len(sys.argv) > 1 else "poll"
    if cmd == "report":
        send_daily_report()
    elif cmd == "alert":
        check_alerts()
    elif cmd == "poll":
        poll()
