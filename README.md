# CubiVeil

[![CI](https://github.com/cubiculus/CubiVeil/actions/workflows/ci.yml/badge.svg)](https://github.com/cubiculus/CubiVeil/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%2022.04%20%7C%2024.04-orange)](https://ubuntu.com/)
[![Python](https://img.shields.io/badge/python-3.10-blue)](https://www.python.org/)
[![myPy](https://img.shields.io/badge/type%20checked-mypy-blue)](https://mypy.readthedocs.io/)
[![Security: Bandit](https://img.shields.io/badge/security-bandit-green)](https://github.com/PyCQA/bandit)

[🇬🇧 English version](#english-version)

> Установка приватного прокси-сервера: **Marzban + Sing-box**, 5 протоколов,
> SSL-сертификат, защита сервера, Telegram-бот с мониторингом и бэкапами.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh)
```

---

## Что это

CubiVeil — установочный скрипт для личного прокси-сервера на базе
[Marzban](https://github.com/Gozargah/Marzban) +
[Sing-box](https://github.com/SagerNet/sing-box).

**Что делает скрипт за один запуск:**
- Обновляет систему, настраивает автопатчи безопасности
- Включает BBR для лучшей скорости
- Настраивает файрвол (ufw) и Fail2ban
- Проверяет репутацию IP-подсети и предупреждает о риске
- Устанавливает Sing-box, Marzban, получает SSL-сертификат
- Создаёт 5 профилей с автогенерацией ключей и портов
- Запускает Telegram-бота с мониторингом и ежедневными бэкапами

Скрипт написан на русском, прокомментирован и не содержит скрытых действий.

---

## Требования

| | Минимум | Рекомендуется |
|---|---|---|
| ОС | Ubuntu 22.04 | Ubuntu 24.04 |
| RAM | 512 МБ | 1 ГБ |
| CPU | 1 ядро | 1 ядро |
| Диск | 5 ГБ | 10 ГБ |
| Права | root | root |
| Домен | A-запись → IP сервера **до запуска** | |

---

## Профили

### Профиль 1 — VLESS + Reality + TCP *(основной)*
Маскируется под TLS-соединение с крупным CDN. При активном зондировании
возвращает настоящий TLS-ответ — сервер неотличим от обычного сайта.
Camouflage-домен выбирается случайно при каждой установке.
**Порт:** 443/tcp

### Профиль 2 — VLESS + Reality + gRPC *(альтернатива)*
Тот же Reality, но с HTTP/2 мультиплексингом. Использовать если провайдер
нестабильно пропускает TCP на 443.
**Порт:** 443/tcp

### Профиль 3 — Hysteria2 *(быстрые загрузки)*
UDP/QUIC транспорт — принципиально другой стек, блокируется отдельно от TCP.
Оптимален для больших файлов: Nintendo eShop, игры, обновления.
**Порт:** 443/udp

### Профиль 4 — Trojan + WebSocket + TLS *(fallback)*
Трафик выглядит как обычный HTTPS. Совместим с Cloudflare CDN —
если IP сервера заблокируют, можно поставить домен за CF и продолжить
работу без смены сервера.
**Порт:** случайный 30000+

### Профиль 5 — Shadowsocks 2022 *(совместимость)*
Для клиентов без поддержки Reality или Hysteria2. Работает на большинстве
мобильных приложений без дополнительных настроек.
**Порт:** случайный 30000+

---

## Архитектура портов

```
443/tcp  →  VLESS Reality TCP + gRPC
443/udp  →  Hysteria2
XXXXX/tcp → Trojan WebSocket TLS    (рандом 30000+)
XXXXX/tcp → Shadowsocks 2022        (рандом 30000+)
XXXXX/tcp → Панель Marzban HTTPS    (рандом 30000+)
XXXXX/tcp → Subscription link       (рандом 30000+)
```

---

## Telegram-бот

**Ежедневный отчёт** (настраиваемое время):
```
🛡 CubiVeil — ежедневный отчёт
12.03.2026 09:00 UTC
━━━━━━━━━━━━━━━━━━━━━
🟢 CPU:   8%   ████░░░░░░
🟢 RAM:   312/1024 МБ (30%)
🟢 Диск:  4/20 ГБ (20%)
⏱ Uptime: 14д 6ч 12м
━━━━━━━━━━━━━━━━━━━━━
👥 Активных пользователей: 4
📦 Бэкап базы прикреплён ниже
```

**Алерты** каждые 15 минут, без спама — только при переходе через порог:
```
⚠️ CubiVeil — Алерт!
🔴 CPU: 87% (порог 80%)
```

**Интерактивные команды** (только для авторизованного chat_id):
```
/status  — текущее состояние сервера
/backup  — получить бэкап прямо сейчас
/users   — активные пользователи
/restart — перезапустить Marzban
/help    — список команд
```

Для настройки нужен токен от [@BotFather](https://t.me/BotFather)
и твой chat_id (узнать: [@userinfobot](https://t.me/userinfobot)).

---

## После установки

### Health Check — мониторинг доступности

CubiVeil предоставляет endpoints для мониторинга:

```bash
# Полная информация о сервисах
curl http://IP_СЕРВЕРА:PORT/health

# Пример ответа:
{
  "status": "healthy",
  "timestamp": "2026-03-23T12:00:00.000000",
  "marzban": "active",
  "singbox": "active",
  "bot": "active"
}

# Проверка готовности (только marzban + sing-box)
curl http://IP_СЕРВЕРА:PORT/ready
# Ответ: "ready" (200) или "not ready" (503)
```

**Интеграция с системами мониторинга:**
- Uptime Kuma: HTTP-проверка на `/health`
- Prometheus Blackbox: `/ready`
- Cron + webhook: `curl -sf IP/ready || отправить_алерт`

Порт health-check отображается при установке и сохраняется в `/root/cubiveil-credentials.age`.

---

### Шифрование учётных данных

Все чувствительные данные шифруются через [age](https://age-encryption.org/):

```bash
# Расшифровка
age -d -i /root/.cubiveil-age-key.txt /root/cubiveil-credentials.age

# Или
cat /root/cubiveil-credentials.age | age -d -i /root/.cubiveil-age-key.txt
```

**Важно:** Сохрани ключ `/root/.cubiveil-age-key.txt` в надёжном месте!
Без него невозможно расшифровать учётные данные.

---

### Subscription URL для Mihomo на MikroTik

```yaml
proxy-providers:
  cubiveil:
    type: http
    url: "https://твой-домен:ПОРТ/путь/username"
    interval: 3600
    health-check:
      enable: true
      url: https://www.gstatic.com/generate_204
      interval: 300
```

URL отображается в панели Marzban у каждого пользователя.

### Сменить порт SSH и закрыть 22

```bash
# 1. Выбираем новый порт
NEW_PORT=2222

# 2. Прописываем в конфиге SSH
sed -i "s/#Port 22/Port ${NEW_PORT}/" /etc/ssh/sshd_config
sed -i "s/^Port 22/Port ${NEW_PORT}/" /etc/ssh/sshd_config
systemctl restart sshd

# 3. Открываем новый порт в файрволе
ufw allow ${NEW_PORT}/tcp comment 'SSH'

# 4. Подключаемся через новый порт и проверяем соединение
# ssh -p 2222 root@сервер

# 5. Только после успешного подключения — закрываем 22
ufw delete allow 22/tcp
```

> ⚠️ Сначала убедись что новое подключение работает, потом закрывай 22.

### Полезные команды

```bash
systemctl status marzban          # статус панели
systemctl status cubiveil-bot     # статус бота
systemctl status marzban-health   # статус health-check
journalctl -u marzban -f          # логи панели
journalctl -u cubiveil-bot -f     # логи бота
systemctl restart marzban         # перезапуск
ufw status numbered               # состояние файрвола
crontab -l                        # cron задачи

# Health check
curl http://localhost:PORT/health  # полная информация
curl http://localhost:PORT/ready   # проверка готовности

# Расшифровка учётных данных
age -d -i /root/.cubiveil-age-key.txt /root/cubiveil-credentials.age

# Управление логами
journalctl --disk-usage           # размер логов
journalctl --vacuum-size=100M     # очистить до 100МБ
journalctl --vacuum-time=7d       # удалить логи старше 7 дней
```

---

## Переезд на новый сервер

1. Запусти скрипт на новом сервере
2. Смени A-запись домена на новый IP
3. Subscription URL в Mihomo обновится автоматически по `interval`
4. Готово

---

## Разработка

### Интеграционные тесты

CubiVeil включает набор интеграционных тестов для проверки корректности установки.

```bash
# Запуск тестов (требуются права root)
sudo ./run-tests.sh

# Или напрямую
sudo bash tests/integration-tests.sh
```

**Что проверяют тесты:**
- ✅ Все сервисы активны (Marzban, Sing-box, бот, health-check)
- ✅ Порты открыты (443/tcp, 443/udp, health-check)
- ✅ SSL сертификат валиден
- ✅ Credentials зашифрованы через age
- ✅ Конфигурация корректна (5 профилей, все переменные)
- ✅ UFW и Fail2ban активны
- ✅ Ротация логов настроена

**Интерпретация:**
- `✅ Все тесты пройдены` — установка корректна
- `❌ Тесты провалены` — см. логи для деталей

📖 [Полная документация по тестам →](tests/README.md)

---

### Статическая типизация (mypy)

Проект использует [mypy](https://mypy.readthedocs.io/) с максимальной строгостью проверок.

```bash
# Установка зависимостей
pip install -r requirements-dev.txt

# Запуск проверки
mypy
```

Конфигурация в `pyproject.toml` включает:
- `strict = true` — все строгие флаги
- `disallow_any_generics` — запрет немаркизированных дженериков
- `no_implicit_reexport` — явный реэкспорт импортов
- `strict_equality` — запрет сравнения несовместимых типов

### Проверка безопасности (bandit)

[Bandit](https://bandit.readthedocs.io/) анализирует код на уязвимости безопасности.

```bash
# Запуск проверки
bandit
```

Проверяемые категории:
- **B1xx** — проблемы с импортами и выполнением кода
- **B2xx** — устаревшие и опасные функции
- **B3xx** — криптография и случайные числа
- **B4xx** — импорты модулей
- **B5xx** — SSL/TLS и хеширование
- **B6xx** — subprocess и shell-инъекции
- **B7xx** — логирование и отладка

---

## Разработка

### Pre-commit хуки

Для автоматической проверки кода перед коммитом:

```bash
# Установка pre-commit
pip install pre-commit

# Установка хуков в репозиторий
pre-commit install

# Проверка всех файлов вручную
pre-commit run --all-files
```

**Что проверяется:**
- `shellcheck` — поиск уязвимостей и ошибок в Bash
- `shfmt` — форматирование кода
- `bash -n` — проверка синтаксиса

---

## Лицензия

MIT — используй свободно, ссылка на репозиторий приветствуется.

---

<a id="english-version"></a>
# English Version

> 🇬🇧 **CubiVeil** — Personal proxy server installer: **Marzban + Sing-box**, 5 protocols,
> SSL certificate, server protection, Telegram bot with monitoring and backups.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh)
```

---

## What Is It

CubiVeil is an installation script for a personal proxy server based on
[Marzban](https://github.com/Gozargah/Marzban) +
[Sing-box](https://github.com/SagerNet/sing-box).

**What the script does in one run:**
- Updates the system, configures automatic security patches
- Enables BBR for better performance
- Configures firewall (ufw) and Fail2ban
- Checks IP subnet reputation and warns about risks
- Installs Sing-box, Marzban, obtains SSL certificate
- Creates 5 profiles with auto-generated keys and ports
- Launches Telegram bot with monitoring and daily backups

The script is written in Russian and English, commented, and contains no hidden actions.

---

## Requirements

| | Minimum | Recommended |
|---|---|---|
| OS | Ubuntu 22.04 | Ubuntu 24.04 |
| RAM | 512 MB | 1 GB |
| CPU | 1 core | 1 core |
| Disk | 5 GB | 10 GB |
| Privileges | root | root |
| Domain | A record → server IP **before running** | |

---

## Profiles

### Profile 1 — VLESS + Reality + TCP *(main)*
Disguised as a TLS connection to a major CDN. When actively probed,
it returns a real TLS response — the server is indistinguishable from a regular website.
Camouflage domain is randomly selected at each installation.
**Port:** 443/tcp

### Profile 2 — VLESS + Reality + gRPC *(alternative)*
Same Reality, but with HTTP/2 multiplexing. Use if your provider
unreliably passes TCP on 443.
**Port:** 443/tcp

### Profile 3 — Hysteria2 *(fast downloads)*
UDP/QUIC transport — a fundamentally different stack, blocked separately from TCP.
Optimal for large files: Nintendo eShop, games, updates.
**Port:** 443/udp

### Profile 4 — Trojan + WebSocket + TLS *(fallback)*
Traffic looks like regular HTTPS. Compatible with Cloudflare CDN —
if the server IP is blocked, you can put the domain behind CF and continue
working without changing the server.
**Port:** random 30000+

### Profile 5 — Shadowsocks 2022 *(compatibility)*
For clients without Reality or Hysteria2 support. Works on most
mobile applications without additional configuration.
**Port:** random 30000+

---

## Port Architecture

```
443/tcp  →  VLESS Reality TCP + gRPC
443/udp  →  Hysteria2 QUIC
XXXXX/tcp → Trojan WebSocket TLS    (random 30000+)
XXXXX/tcp → Shadowsocks 2022        (random 30000+)
XXXXX/tcp → Marzban Panel HTTPS     (random 30000+)
XXXXX/tcp → Subscription link       (random 30000+)
```

---

## Telegram Bot

**Daily report** (configurable time):
```
🛡 CubiVeil — Daily Report
📅 23.03.2026 09:00 UTC

⚙️ System Metrics
CPU:    12%  ▓░░░░░░░░░
RAM:    45%  ▓▓▓▓░░░░░░
Disk:   38%  ▓▓▓░░░░░░░
Uptime: 15d 7h 42m

👥 Active users: 3
💾 Backup created: marzban_20260323_0900.sqlite3
```

**Alerts** (when thresholds exceeded):
```
🚨 Server Alert — High CPU Load!

CPU: 92% (threshold: 80%)
Time: 23.03.2026 14:35 UTC

Check the server immediately.
```

**Setup:** Get token from [@BotFather](https://t.me/BotFather), chat_id from [@userinfobot](https://t.me/userinfobot).

---

## Installation

```bash
# Download and run (requires root)
wget https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

**During installation you will be asked:**
1. **Domain** — for panel and subscriptions (e.g., `panel.example.com`)
2. **Email** — for Let's Encrypt SSL certificate
3. **Telegram Bot Token** — optional, for notifications
4. **Telegram Chat ID** — your personal/group ID
5. **Report time** — daily report time in UTC
6. **Alert thresholds** — CPU, RAM, Disk (%)

---

## After Installation

### Health Check — Availability Monitoring

CubiVeil provides endpoints for monitoring:

```bash
# Full information about services
curl http://SERVER_IP:PORT/health

# Example response:
{
  "status": "healthy",
  "timestamp": "2026-03-23T12:00:00.000000",
  "marzban": "active",
  "singbox": "active",
  "bot": "active"
}

# Readiness check (marzban + sing-box only)
curl http://SERVER_IP:PORT/ready
# Response: "ready" (200) or "not ready" (503)
```

**Integration with monitoring systems:**
- Uptime Kuma: HTTP check on `/health`
- Prometheus Blackbox: `/ready`
- Cron + webhook: `curl -sf IP/ready || send_alert`

Health-check port is displayed during installation and saved in `/root/cubiveil-credentials.age`.

---

### Encryption of Credentials

All sensitive data is encrypted via [age](https://age-encryption.org/):

```bash
# Decrypt
age -d -i /root/.cubiveil-age-key.txt /root/cubiveil-credentials.age

# Or
cat /root/cubiveil-credentials.age | age -d -i /root/.cubiveil-age-key.txt
```

**Important:** Save the key `/root/.cubiveil-age-key.txt` in a secure place!
Without it, you cannot decrypt the credentials.

---

### Useful Commands

```bash
systemctl status marzban          # panel status
systemctl status cubiveil-bot     # bot status
systemctl status marzban-health   # health-check status
journalctl -u marzban -f          # panel logs
journalctl -u cubiveil-bot -f     # bot logs
systemctl restart marzban         # restart
ufw status numbered               # firewall status
crontab -l                        # cron tasks

# Health check
curl http://localhost:PORT/health  # full information
curl http://localhost:PORT/ready   # readiness check

# Decrypt credentials
age -d -i /root/.cubiveil-age-key.txt /root/cubiveil-credentials.age

# Log management
journalctl --disk-usage           # log size
journalctl --vacuum-size=100M     # clean to 100MB
journalctl --vacuum-time=7d       # delete logs older than 7 days
```

---

## Integration Tests

CubiVeil includes a set of integration tests to verify installation correctness.

```bash
# Run tests (requires root privileges)
sudo ./run-tests.sh

# Or directly
sudo bash tests/integration-tests.sh
```

**What tests check:**
- ✅ All services active (Marzban, Sing-box, bot, health-check)
- ✅ Ports open (443/tcp, 443/udp, health-check)
- ✅ SSL certificate valid
- ✅ Credentials encrypted via age
- ✅ Configuration correct (5 profiles, all variables)
- ✅ UFW and Fail2ban active
- ✅ Log rotation configured

**Interpretation:**
- `✅ All tests passed` — installation is correct
- `❌ Tests failed` — see logs for details

📖 [Full test documentation →](tests/README.md)

---

## Development

### Static Typing (mypy)

The project uses [mypy](https://mypy.readthedocs.io/) with maximum strictness checks.

```bash
# Run check
mypy
```

Configuration in `pyproject.toml` includes:
- `strict = true` — all strict flags
- `disallow_any_generics` — disallow unmarked generics
- `no_implicit_reexport` — explicit import re-export
- `strict_equality` — disallow comparison of incompatible types

### Security Check (bandit)

[Bandit](https://bandit.readthedocs.io/) analyzes code for security vulnerabilities.

```bash
# Run check
bandit
```

Checked categories:
- **B1xx** — import and code execution issues
- **B2xx** — obsolete and dangerous functions
- **B3xx** — cryptography and random numbers
- **B4xx** — module imports
- **B5xx** — SSL/TLS and hashing
- **B6xx** — subprocess and shell injections
- **B7xx** — logging and debugging

---

## Pre-commit Hooks

For automatic code check before commit:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks in repository
pre-commit install

# Manual check of all files
pre-commit run --all-files
```

**What is checked:**
- `shellcheck` — search for vulnerabilities and errors in Bash
- `shfmt` — code formatting
- `bash -n` — syntax check

---

## License

MIT — use freely, link to repository is appreciated.
