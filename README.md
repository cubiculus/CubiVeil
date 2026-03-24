<div align="center">

![CubiVeil](logo.png)

# CubiVeil

[![CI](https://github.com/cubiculus/CubiVeil/actions/workflows/ci.yml/badge.svg)](https://github.com/cubiculus/CubiVeil/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%2022.04%20%7C%2024.04-orange)](https://ubuntu.com/)

[🇬🇧 **English Version**](#english-version)

</div>

> Установка приватного прокси-сервера: **Marzban + Sing-box**, 5 профилей,
> SSL-сертификат, защита сервера, Telegram-бот с мониторингом и бэкапами.

---

<div align="center">

### 🚀 Быстрый старт

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh)
```

</div>

---

---

## Что это

CubiVeil — модульный установочный скрипт для личного прокси-сервера на базе
[Marzban](https://github.com/Gozargah/Marzban) +
[Sing-box](https://github.com/SagerNet/sing-box).

**Что делает скрипт за один запуск:**
- Обновляет систему, настраивает автопатчи безопасности
- Включает BBR для лучшей скорости
- Настраивает файрвол (ufw) и Fail2ban
- Проверяет репутацию IP-подсети и предупреждает о риске
- Устанавливает Sing-box, Marzban, получает SSL-сертификат
- Создаёт 5 профилей с автогенерацией ключей и портов
- Настраивает health-check эндпоинт для мониторинга
- **Опционально**: устанавливает Telegram-бот через отдельный скрипт

Скрипт написан на русском и английском, прокомментирован и не содержит скрытых действий.

---

## Архитектура проекта

```
CubiVeil/
├── install.sh              # Основной установщик (88 строк)
├── setup-telegram.sh       # Отдельный скрипт для Telegram бота
├── run-tests.sh            # Универсальный тест-раннер
├── lang.sh                # Локализация (RU/EN)
├── lib/
│   ├── utils.sh           # Общие утилиты (генераторы, порты, IP)
│   └── install-steps.sh   # Шаги установки Marzban + Sing-box
└── tests/
    ├── integration-tests.sh # Интеграционные тесты (требуют root)
    ├── modular-structure.sh # Тесты модульной структуры
    ├── unit-utils.sh      # Тесты lib/utils.sh
    └── unit-telegram.sh   # Тесты setup-telegram.sh
```

**Преимущества модульной архитектуры:**
- Чистый и компактный `install.sh`
- Telegram-бот полностью отделён — можно добавить позже
- Код разбит на логические блоки для удобства поддержки
- Независимое тестирование каждого модуля

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

## Установка

### Основная установка

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh)
```

**Во время установки вас спросят:**
1. **Домен** — для панели и подписок (например, `panel.example.com`)
2. **Email** — для Let's Encrypt SSL сертификата
3. **Telegram-бот** — хотите ли установить (y/n)
   - Если да — после установки будет предложена команда для `setup-telegram.sh`

### Установка Telegram-бота

После основной установки:

```bash
# С GitHub
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/setup-telegram.sh)

# Или с локального файла
bash setup-telegram.sh
```

**Для настройки нужны:**
- Токен от [@BotFather](https://t.me/BotFather)
- Твой chat_id (узнать: [@userinfobot](https://t.me/userinfobot))

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
443/tcp  → VLESS Reality TCP + gRPC
443/udp  → Hysteria2
XXXXX/tcp → Trojan WebSocket TLS    (рандом 30000+)
XXXXX/tcp → Shadowsocks 2022        (рандом 30000+)
XXXXX/tcp → Панель Marzban HTTPS    (рандом 30000+)
XXXXX/tcp → Subscription link       (рандом 30000+)
XXXXX/tcp → Health Check endpoint   (рандом 30000+)
```

---

## Telegram-бот

**Ежедневный отчёт** (настраиваемое время):
```
🛡 CubiVeil — ежедневный отчёт
12.03.2026 09:00 UTC
━━━━━━━━━━━━━━━━━━━━━
🟢 CPU:   8%   ████░░░░░
🟢 RAM:   312/1024 МБ (30%)
🟢 Диск:  4/20 ГБ (20%)
⏱ Uptime: 14д 6ч 12м
━━━━━━━━━━━━━━━━━━━━━
👥 Активных пользователей: 4
━━━━━━━━━━━━━━━━━━━━━
📦 Бэкап базы прикреплён ниже
```

**Алерты** каждые 15 минут, без спама — только при переходе через порог:
```
⚠️ CubiVeil — Алерт!
━━━━━━━━━━━━━━━
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
    url: "https://твой-домен:ПОРТ/путь/{username}"
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
# Статус сервисов
systemctl status marzban          # статус панели
systemctl status cubiveil-bot     # статус бота
systemctl status marzban-health   # статус health-check

# Логи
journalctl -u marzban -f          # логи панели
journalctl -u cubiveil-bot -f     # логи бота

# Управление
systemctl restart marzban         # перезапуск панели
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

Если установлен Telegram-бот — перезапусти `setup-telegram.sh` на новом сервере.

---

## Тестирование

### Запуск тестов

CubiVeil включает набор тестов для проверки корректности установки.

```bash
# Unit тесты (без root)
./run-tests.sh

# Все тесты (требует root)
sudo ./run-tests.sh --full

# Только интеграционные тесты
sudo ./run-tests.sh --integration

# Справка
./run-tests.sh --help
```

### Unit тесты

Не требуют прав root, проверяют структуру и синтаксис:

- ✅ Модульная структура проекта
- ✅ Загрузка всех модулей
- ✅ Синтаксис всех скриптов
- ✅ Функции в `lib/utils.sh`
- ✅ Функции в `setup-telegram.sh`
- ✅ Отсутствие дублирования кода
- ✅ Размеры файлов

### Интеграционные тесты

Требуют root, проверяют работающую систему:

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

---

## Разработка

### Структура проекта

```
CubiVeil/
├── install.sh              # Точка входа (88 строк)
├── setup-telegram.sh       # Telegram бот (707 строк)
├── run-tests.sh            # Тест-раннер
├── lang.sh                # Локализация
└── lib/
    ├── utils.sh           # Утилиты (80 строк)
    └── install-steps.sh   # Шаги установки (996 строк)
```

### Добавление новых функций

1. **Утилиты** — добавь в `lib/utils.sh`
2. **Шаги установки** — добавь в `lib/install-steps.sh`
3. **Вызов в main()** — добавь в `install.sh`

### Тестирование новых функций

1. Добавь тесты в соответствующий файл в `tests/`
2. Запусти `./run-tests.sh` для проверки

---

## Лицензия

MIT — используй свободно, ссылка на репозиторий приветствуется.

---

<a id="english-version"></a>
<div align="center">

# English Version

</div>

> **CubiVeil** — Personal proxy server installer: **Marzban + Sing-box**, 5 profiles,
> SSL certificate, server protection, Telegram bot with monitoring and backups.

---

<div align="center">

### 🚀 Quick Start

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh)
```

</div>

---

---

## What Is It

CubiVeil is a modular installation script for a personal proxy server based on
[Marzban](https://github.com/Gozargah/Marzban) +
[Sing-box](https://github.com/SagerNet/sing-box).

**What script does in one run:**
- Updates system, configures automatic security patches
- Enables BBR for better performance
- Configures firewall (ufw) and Fail2ban
- Checks IP subnet reputation and warns about risks
- Installs Sing-box, Marzban, obtains SSL certificate
- Creates 5 profiles with auto-generated keys and ports
- Sets up health-check endpoint for monitoring
- **Optionally**: installs Telegram bot via separate script

The script is written in Russian and English, commented, and contains no hidden actions.

---

## Project Architecture

```
CubiVeil/
├── install.sh              # Main installer (88 lines)
├── setup-telegram.sh       # Separate Telegram bot script
├── run-tests.sh            # Universal test runner
├── lang.sh                # Localization (RU/EN)
├── lib/
│   ├── utils.sh           # Common utilities (generators, ports, IP)
│   └── install-steps.sh   # Installation steps Marzban + Sing-box
└── tests/
    ├── integration-tests.sh # Integration tests (requires root)
    ├── modular-structure.sh # Modular structure tests
    ├── unit-utils.sh      # lib/utils.sh tests
    └── unit-telegram.sh   # setup-telegram.sh tests
```

**Benefits of modular architecture:**
- Clean and compact `install.sh`
- Telegram bot fully separated — can be added later
- Code split into logical blocks for easy maintenance
- Independent testing of each module

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

## Installation

### Main Installation

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh)
```

**During installation you will be asked:**
1. **Domain** — for panel and subscriptions (e.g., `panel.example.com`)
2. **Email** — for Let's Encrypt SSL certificate
3. **Telegram bot** — do you want to install (y/n)
   - If yes — after installation you'll be prompted to run `setup-telegram.sh`

### Install Telegram Bot

After main installation:

```bash
# From GitHub
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/setup-telegram.sh)

# Or from local file
bash setup-telegram.sh
```

**Setup requires:**
- Token from [@BotFather](https://t.me/BotFather)
- Your chat_id (get from [@userinfobot](https://t.me/userinfobot))

---

## Telegram Bot

**Daily report** (configurable time):
```
🛡 CubiVeil — Daily Report
📅 23.03.2026 09:00 UTC

⚙️ System Metrics
CPU:    12%  ▓░░░░░░░░░░
RAM:    45%  ▓▓▓▓░░░░░░░
Disk:   38%  ▓▓▓░░░░░░░░
Uptime: 15d 7h 42m

👥 Active users: 3
💾 Backup created: marzban_20260323_0900.sqlite3
```

**Alerts** (when thresholds exceeded):
```
🚨 Server Alert — High CPU Load!

CPU: 92% (threshold: 80%)
Time: 23.03.2026 14:35 UTC

Check server immediately.
```

---

## Health Check — Availability Monitoring

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

---

## Testing

### Run Tests

```bash
# Unit tests (no root required)
./run-tests.sh

# All tests (requires root)
sudo ./run-tests.sh --full

# Only integration tests
sudo ./run-tests.sh --integration

# Help
./run-tests.sh --help
```

---

## License

MIT — use freely, link to repository is appreciated.
