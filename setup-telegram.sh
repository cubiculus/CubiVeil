#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║            CubiVeil — Telegram Bot Setup                 ║
# ║         github.com/cubiculus/cubiveil                     ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/lang.sh" ]]; then
  source "${SCRIPT_DIR}/lang.sh"
else
  # Fallback если файл локализации отсутствует
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  PLAIN='\033[0m'
  ok() { echo -e "${GREEN}[✓]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err() {
    echo -e "${RED}[✗]${PLAIN} $1"
    exit 1
  }
  info() { echo -e "${CYAN}[→]${PLAIN} $1"; }
  step() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
    echo -e "${BLUE}  $1${PLAIN}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  }
  step_title() {
    local num="$1"
    local ru="$2"
    local en="$3"
    if [[ "$LANG_NAME" == "Русский" ]]; then
      step "Шаг ${num}/4 — ${ru}"
    else
      step "Step ${num}/4 — ${en}"
    fi
  }
fi

# ── Подключение общих утилит ───────────────────────────────────
source "${SCRIPT_DIR}/lib/utils.sh" || {
  err "Не удалось загрузить lib/utils.sh"
}

# ── Баннер ─────────────────────────────────────────────────────
print_banner() {
  clear
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
  echo -e "${CYAN}  ║       CubiVeil Telegram Bot Setup       ║${PLAIN}"
  echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# ШАГ 1: Проверка окружения
# ══════════════════════════════════════════════════════════════
step_check_environment() {
  step_title "1" "Проверка окружения" "Environment check"

  # Проверка root
  if [[ $EUID -ne 0 ]]; then
    err "Этот скрипт должен быть запущен от root"
  fi

  # Проверка что Marzban установлен
  if [[ ! -f /opt/marzban/.env ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Marzban не найден. Сначала запусти основной установщик: bash install.sh"
    else
      err "Marzban not found. Run main installer first: bash install.sh"
    fi
  fi

  # Проверка Python3
  if ! command -v python3 &>/dev/null; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Python3 не установлен. Установи: apt-get install python3"
    else
      err "Python3 not found. Install: apt-get install python3"
    fi
  fi

  # Проверка curl
  if ! command -v curl &>/dev/null; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "curl не установлен. Установи: apt-get install curl"
    else
      err "curl not found. Install: apt-get install curl"
    fi
  fi

  ok "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Ввод данных Telegram
# ══════════════════════════════════════════════════════════════
step_prompt_telegram_config() {
  step_title "2" "Настройка Telegram" "Telegram configuration"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Telegram-бот: нужен токен от @BotFather и твой chat_id (узнать: @userinfobot)."
  else
    info "$INFO_TG_BOT"
  fi

  local prompt_token
  if [[ "$LANG_NAME" == "Русский" ]]; then
    prompt_token="  Telegram Bot Token: "
  else
    prompt_token="  $PROMPT_TG_TOKEN "
  fi
  read -rp "$prompt_token" TG_TOKEN
  TG_TOKEN="${TG_TOKEN// /}"

  # Валидация формата токена Telegram
  if [[ ! "$TG_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]{35}$ ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Некорректный формат токена Telegram. Ожидается: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
    else
      err "$ERR_TG_TOKEN_FORMAT"
    fi
  fi

  # Проверка валидности токена через API
  if ! curl -sf --max-time 5 "https://api.telegram.org/bot${TG_TOKEN}/getMe" >/dev/null 2>&1; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Токен Telegram недействителен. Проверь токен от @BotFather"
    else
      err "$ERR_TG_TOKEN_INVALID"
    fi
  fi

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Токен Telegram проверен ✓"
  else
    ok "$OK_TG_TOKEN_VERIFIED"
  fi

  local prompt_chat_id
  if [[ "$LANG_NAME" == "Русский" ]]; then
    prompt_chat_id="  Telegram Chat ID: "
  else
    prompt_chat_id="  $PROMPT_TG_CHAT_ID "
  fi
  read -rp "$prompt_chat_id" TG_CHAT_ID
  TG_CHAT_ID="${TG_CHAT_ID// /}"

  # Валидация Chat ID (число, может быть отрицательным для групп)
  if [[ ! "$TG_CHAT_ID" =~ ^-?[0-9]+$ ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Некорректный Chat ID. Ожидается число (например: 123456789)"
    else
      err "$ERR_CHAT_ID_FORMAT"
    fi
  fi

  local prompt_report
  if [[ "$LANG_NAME" == "Русский" ]]; then
    prompt_report="  Время ежедневного отчёта UTC [09:00]: "
  else
    prompt_report="  $PROMPT_REPORT_TIME "
  fi
  read -rp "$prompt_report" REPORT_TIME
  REPORT_TIME="${REPORT_TIME// /}"
  [[ -z "$REPORT_TIME" ]] && REPORT_TIME="09:00"
  REPORT_HOUR=$(echo "$REPORT_TIME" | cut -d: -f1)
  REPORT_MIN=$(echo "$REPORT_TIME" | cut -d: -f2)

  echo ""
  local info_alerts prompt_cpu prompt_ram prompt_disk
  if [[ "$LANG_NAME" == "Русский" ]]; then
    info_alerts="Пороги алертов (в %, Enter = по умолчанию):"
    prompt_cpu="  CPU  > ? % [80]: "
    prompt_ram="  RAM  > ? % [85]: "
    prompt_disk="  Диск > ? % [90]: "
  else
    info_alerts="$INFO_ALERT_THRESHOLDS"
    prompt_cpu="  $PROMPT_ALERT_CPU "
    prompt_ram="  $PROMPT_ALERT_RAM "
    prompt_disk="  $PROMPT_ALERT_DISK "
  fi
  info "$info_alerts"
  read -rp "$prompt_cpu" ALERT_CPU
  ALERT_CPU="${ALERT_CPU// /}"
  [[ -z "$ALERT_CPU" ]] && ALERT_CPU=80
  read -rp "$prompt_ram" ALERT_RAM
  ALERT_RAM="${ALERT_RAM// /}"
  [[ -z "$ALERT_RAM" ]] && ALERT_RAM=85
  read -rp "$prompt_disk" ALERT_DISK
  ALERT_DISK="${ALERT_DISK// /}"
  [[ -z "$ALERT_DISK" ]] && ALERT_DISK=90

  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Telegram: настроен (отчёт в ${REPORT_TIME} UTC)"
    ok "Пороги: CPU>${ALERT_CPU}% RAM>${ALERT_RAM}% Диск>${ALERT_DISK}%"
  else
    ok "$OK_TG_CONFIGURED"
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Установка бота
# ══════════════════════════════════════════════════════════════
step_install_bot() {
  step_title "3" "Установка бота" "Bot installation"

  mkdir -p /opt/cubiveil-bot/backups

  # ── Python-скрипт бота ────────────────────────────────────
  cat >/opt/cubiveil-bot/bot.py <<PYEOF
#!/usr/bin/env python3
"""
CubiVeil Telegram Bot
- Ежедневный отчёт: CPU, RAM, диск, uptime, активные пользователи + бэкап БД
- Алерты при превышении порогов
- Интерактивные команды только для авторизованного chat_id
"""

import os, json, time, subprocess, sqlite3, shutil
from datetime import datetime
import urllib.request, urllib.parse, urllib.error

# Чувствительные данные из переменных окружения (systemd Environment)
TOKEN     = os.environ.get("TG_TOKEN")
CHAT_ID   = os.environ.get("TG_CHAT_ID")
DB_PATH   = "/var/lib/marzban/db.sqlite3"
BAK_DIR   = "/opt/cubiveil-bot/backups"
STATE_FILE = "/opt/cubiveil-bot/alert_state.json"

ALERT_CPU  = ${ALERT_CPU}
ALERT_RAM  = ${ALERT_RAM}
ALERT_DISK = ${ALERT_DISK}

if not TOKEN or not CHAT_ID:
  print("[bot] ОШИБКА: TG_TOKEN и TG_CHAT_ID должны быть заданы в переменных окружения")
  exit(1)

os.makedirs(BAK_DIR, exist_ok=True)

# ── Отправка сообщений ────────────────────────────────────────
def tg_send(text, parse_mode="HTML"):
  url  = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
  data = urllib.parse.urlencode({
      "chat_id": CHAT_ID, "text": text, "parse_mode": parse_mode
  }).encode()
  try:
      urllib.request.urlopen(url, data, timeout=10)
  except Exception as e:
      print(f"[bot] Ошибка отправки: {e}")

def tg_send_file(path, caption=""):
  import http.client
  if not os.path.exists(path):
      tg_send("⚠️ Файл бэкапа не найден")
      return
  boundary = "CubiVeilBoundary"
  filename = os.path.basename(path)
  with open(path, "rb") as f:
      file_data = f.read()
  def field(name, value):
      return (f"--{boundary}\r\nContent-Disposition: form-data; "
              f'name="{name}"\r\n\r\n{value}\r\n').encode()
  body = (field("chat_id", CHAT_ID) + field("caption", caption) +
          f"--{boundary}\r\nContent-Disposition: form-data; "
          f'name="document"; filename="{filename}"\r\n'
          f"Content-Type: application/octet-stream\r\n\r\n".encode() +
          file_data + f"\r\n--{boundary}--\r\n".encode())
  try:
      conn = http.client.HTTPSConnection("api.telegram.org")
      conn.request("POST", f"/bot{TOKEN}/sendDocument", body,
          {"Content-Type": f"multipart/form-data; boundary={boundary}"})
      conn.getresponse()
  except Exception as e:
      print(f"[bot] Ошибка отправки файла: {e}")

# ── Метрики ───────────────────────────────────────────────────
def get_cpu():
  """Получает загрузку CPU из /proc/stat — быстрее и надёжнее top"""
  try:
      def read_cpu_stats():
          with open("/proc/stat") as f:
              line = f.readline()
          parts = line.split()[1:8]  # cpu user nice system idle iowait irq softirq
          return [int(x) for x in parts]

      cpu1 = read_cpu_stats()
      time.sleep(0.5)
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
              meminfo[parts[0].rstrip(":")] = int(parts[1]) // 1024  # kB → MB

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
  cpu               = get_cpu()
  ram_u, ram_t, ram_p = get_ram()
  dsk_u, dsk_t, dsk_p = get_disk()
  uptime            = get_uptime()
  users             = get_active_users()
  now               = datetime.now().strftime("%d.%m.%Y %H:%M UTC")

  ci = "🔴" if cpu   > ALERT_CPU  else "🟢"
  ri = "🔴" if ram_p > ALERT_RAM  else "🟢"
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
      cpu               = get_cpu()
      ram_u, ram_t, ram_p = get_ram()
      dsk_u, dsk_t, dsk_p = get_disk()
      uptime            = get_uptime()
      users             = get_active_users()
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
      r = subprocess.run(["systemctl", "restart", "marzban"],
          capture_output=True, timeout=30)
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
          url = (f"https://api.telegram.org/bot{TOKEN}/getUpdates"
                 f"?offset={offset}&timeout=30&allowed_updates=[\"message\"]")
          with urllib.request.urlopen(url, timeout=35) as resp:
              data = json.loads(resp.read())
          for upd in data.get("result", []):
              offset = upd["update_id"] + 1
              msg    = upd.get("message", {})
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
  if   cmd == "report": send_daily_report()
  elif cmd == "alert":  check_alerts()
  elif cmd == "poll":   poll()
PYEOF

  chmod +x /opt/cubiveil-bot/bot.py

  ok "Python-скрипт бота создан"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 4: Настройка systemd и cron
# ══════════════════════════════════════════════════════════════
step_configure_services() {
  step_title "4" "Настройка сервисов" "Service configuration"

  # ── Systemd сервис с безопасными переменными окружения ───
  cat >/etc/systemd/system/cubiveil-bot.service <<EOF
[Unit]
Description=CubiVeil Telegram Bot
After=network.target marzban.service

[Service]
Type=simple
# Чувствительные данные через Environment — не хранятся в файле скрипта
Environment="TG_TOKEN=${TG_TOKEN}"
Environment="TG_CHAT_ID=${TG_CHAT_ID}"
ExecStart=/usr/bin/python3 /opt/cubiveil-bot/bot.py poll
Restart=always
RestartSec=10s
StandardOutput=journal
StandardError=journal
# Защита от утечек через дампы
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/opt/cubiveil-bot/backups /var/lib/marzban
NoNewPrivileges=true
# Ограничение частоты логов
LogRateLimitInterval=30s
LogRateLimitBurst=1000

[Install]
WantedBy=multi-user.target
EOF

  ok "Systemd сервис создан"

  # ── Ротация логов через journald ─────────────────────────
  mkdir -p /etc/systemd/journald.d
  cat >/etc/systemd/journald.d/cubiveil-limit.conf <<EOF
# Ограничение размера логов для CubiVeil
[Journal]
# Максимум 1ГБ на все логи системы
SystemMaxUse=1G
# Хранить логи 14 дней
MaxFileSec=2week
EOF

  systemctl kill -s SIGHUP systemd-journald 2>/dev/null || true

  ok "Ротация логов journald настроена"

  # ── Ротация логов через logrotate ────────────────────────
  if command -v logrotate &>/dev/null; then
    cat >/etc/logrotate.d/cubiveil-services <<EOF
# Ротация логов CubiVeil сервисов
/var/log/journal/*/cubiveil-bot.service.log {
  weekly
  rotate 4
  compress
  delaycompress
  missingok
  notifempty
  size=50M
  maxage 30
}
EOF
    ok "Ротация логов настроена (logrotate: 4 недели, 50МБ)"
  fi

  # ── Cron: ежедневный отчёт + проверка алертов ────────────
  (
    crontab -l 2>/dev/null | grep -v "cubiveil-bot" || true
    echo "${REPORT_MIN} ${REPORT_HOUR} * * * /usr/bin/python3 /opt/cubiveil-bot/bot.py report"
    echo "*/15 * * * * /usr/bin/python3 /opt/cubiveil-bot/bot.py alert"
  ) | crontab -

  systemctl daemon-reload
  systemctl enable cubiveil-bot --now >/dev/null 2>&1

  ok "Telegram-бот запущен (systemd: cubiveil-bot)"
  ok "Ежедневный отчёт + бэкап: ${REPORT_TIME} UTC"
  ok "Алерты каждые 15 мин: CPU>${ALERT_CPU}% RAM>${ALERT_RAM}% Диск>${ALERT_DISK}%"
  ok "Команды: /status /backup /users /restart /help"
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════
main() {
  # Выбор языка если не выбран
  if [[ -z "${LANG_NAME:-}" ]]; then
    if [[ -f "${SCRIPT_DIR}/lang.sh" ]]; then
      select_language
    fi
  fi

  print_banner
  step_check_environment
  step_prompt_telegram_config
  step_install_bot
  step_configure_services

  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║      Telegram-бот установлен успешно! 🎉           ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  БОТ${PLAIN}"
    echo -e "  Статус: ${GREEN}systemctl status cubiveil-bot${PLAIN}"
    echo -e "  Логи:   ${GREEN}journalctl -u cubiveil-bot -f${PLAIN}"
    echo ""
    echo -e "${CYAN}  КОМАНДЫ${PLAIN}"
    echo -e "  /status  — CPU, RAM, диск, uptime"
    echo -e "  /backup  — получить бэкап прямо сейчас"
    echo -e "  /users   — активные пользователи"
    echo -e "  /restart — перезапустить Marzban"
    echo -e "  /help    — эта справка"
    echo ""
  else
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║      Telegram bot installed successfully! 🎉        ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  BOT${PLAIN}"
    echo -e "  Status: ${GREEN}systemctl status cubiveil-bot${PLAIN}"
    echo -e "  Logs:   ${GREEN}journalctl -u cubiveil-bot -f${PLAIN}"
    echo ""
    echo -e "${CYAN}  COMMANDS${PLAIN}"
    echo -e "  /status  — CPU, RAM, disk, uptime"
    echo -e "  /backup  — get backup right now"
    echo -e "  /users   — active users"
    echo -e "  /restart — restart Marzban"
    echo -e "  /help    — this help"
    echo ""
  fi
  echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
}

main "$@"
