# CubiVeil

<p align="center">
  <img src="assets/logo.png" alt="CubiVeil Logo" width="200"/>
</p>

<p align="center">
  <strong>Автоматизированная установка и управление Marzban + Sing-box</strong>
</p>

<p align="center">
  <a href="docs/README_EN.md">English version</a>
</p>

---

## 🚀 Быстрый старт

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/cubiculus/cubiveil/main/install.sh)
```

---

## 📋 О проекте

**CubiVeil** — это комплексное решение для развёртывания и управления прокси-инфраструктурой на базе **Marzban** и **Sing-box** на серверах Ubuntu.

Проект предоставляет:
- 🚀 Автоматическую установку всех компонентов
- 🔒 Настройку firewall, Fail2ban и SSL-сертификатов
- 📊 Мониторинг ресурсов и алерты
- 💾 Автоматическое резервное копирование
- 🤖 Telegram-бот для управления сервером
- 🛠 Набор утилит для обслуживания

## ⚡ Быстрый старт

### Требования

- **ОС:** Ubuntu 20.04+
- **Права:** root (sudo)
- **Домен:** для панели и SSL-сертификатов
- **DNS:** A-запись домена на IP сервера

### Установка

```bash
# Клонирование репозитория
git clone https://github.com/cubiculus/cubiveil.git
cd cubiveil

# Запуск установщика
sudo bash install.sh
```

Установщик автоматически:
1. Проверит окружение
2. Обновит систему
3. Настроит firewall и Fail2ban
4. Установит Sing-box и Marzban
5. Настроит SSL-сертификаты Let's Encrypt
6. Сгенерирует ключи и конфигурации

### Dev-режим (для тестирования)

Для установки на тестовую виртуальную машину без домена:

```bash
sudo bash install.sh --dev
```

**Dev-режим:**
- ✅ Не требует домен
- ✅ Использует самоподписной SSL сертификат (действует 100 лет)
- ✅ Не проверяет DNS A-записи
- ✅ Идеально для тестирования и разработки
- ⚠️ Браузеры будут показывать предупреждение о безопасности
- ⚠️ Не используйте в production!

### Dry-run режим (симуляция)

Для тестирования установщика без внесения изменений в систему:

```bash
sudo bash install.sh --dry-run
```

**Dry-run режим:**
- ✅ Не вносит никаких изменений в систему
- ✅ Показывает все шаги которые будут выполнены
- ✅ Проверяет окружение и зависимости
- ✅ Безопасно запускать на любой системе
- ✅ Можно комбинировать с `--dev`

**Комбинирование режимов:**

```bash
# Dev + Dry-run: проверить dev-установку без изменений
sudo bash install.sh --dev --dry-run
```

**С опциями:**

```bash
# Dev-режим с кастомным доменом
sudo bash install.sh --dev --domain=mytest.local

# Показать справку
sudo bash install.sh --help
```

### Модульная установка

Для выбора компонентов:

```bash
sudo bash install-modular.sh
```

#### Dry-run режим

Для тестирования установки без внесения изменений в систему:

```bash
sudo bash install-modular.sh --dry-run
```

Режим симуляции покажет, какие действия будут выполнены, какие модули установлены и настроены, но не внесёт никаких изменений в систему.

## 📦 Компоненты

### Основные

| Компонент | Описание |
|-----------|----------|
| **Marzban** | Панель управления пользователями и подписками |
| **Sing-box** | Ядро прокси с поддержкой современных протоколов |
| **Fail2ban** | Защита от брутфорс-атак |
| **UFW** | Межсетевой экран |
| **Let's Encrypt** | SSL-сертификаты |

### Утилиты

Все утилиты находятся в директории `utils/`:

| Утилита | Описание |
|---------|----------|
| `cubiveil.sh` | CLI-менеджер (единая точка входа) |
| `monitor.sh` | Мониторинг ресурсов сервера |
| `backup.sh` | Создание и восстановление бэкапов |
| `diagnose.sh` | Диагностика проблем |
| `manage-profiles.sh` | Управление профилями пользователей |
| `export-config.sh` | Экспорт конфигурации для миграции |
| `update.sh` | Обновление CubiVeil |
| `rollback.sh` | Откат к предыдущей версии |

#### Установка алиасов

Для удобного доступа к утилитам:

```bash
sudo bash utils/install-aliases.sh
source /root/.bashrc
```

После установки доступны команды:
- `cv` — справка
- `cv monitor` — мониторинг
- `cv backup create` — создать бэкап
- `cv profiles list` — список профилей
- `cv diagnose` — диагностика

## 🤖 Telegram-бот

CubiVeil Bot предоставляет полный контроль над сервером через Telegram.

### Установка бота

```bash
bash setup-telegram.sh
```

### Основные команды

#### Мониторинг
- `/status` — краткий статус сервера
- `/monitor` — полный снимок состояния
- `/services` — статус всех сервисов
- `/alerts` — статус алертов и порогов

#### Бэкапы
- `/backup` — создать полный бэкап
- `/backups` — список доступных бэкапов

#### Пользователи
- `/users` — список всех пользователей
- `/qr <username>` — QR-код для подключения

#### Управление
- `/restart <service>` — перезапустить сервис
- `/update` — проверить обновления
- `/export` — экспорт конфигурации
- `/diagnose` — полная диагностика

#### Логи
- `/logs <service> [lines]` — логи сервиса

Подробная документация: [BOT_INTEGRATION.md](BOT_INTEGRATION.md)

## 📊 Автоматизация

### Ежедневные отчёты

Бот автоматически отправляет отчёты в заданное время (по умолчанию 09:00 UTC):
- Загрузка CPU, RAM, диска
- Uptime сервера
- Количество активных пользователей
- Бэкап базы данных

### Алерты

Автоматические уведомления при превышении порогов:
- **CPU:** 80% (настраивается)
- **RAM:** 85% (настраивается)
- **Disk:** 90% (настраивается)

Проверка каждые 15 минут. Алерт отправляется только при переходе из нормы в превышение.

## 🔧 Конфигурация

### Локализация

Проект поддерживает русский и английский языки. Переключение в `lang.sh`.

### Переменные окружения

Настройки бота задаются через systemd Environment:
- `TG_TOKEN` — токен Telegram-бота
- `TG_CHAT_ID` — авторизованный chat_id
- `ALERT_CPU`, `ALERT_RAM`, `ALERT_DISK` — пороги алертов

## 🛡 Безопасность

### Ограничения бота

Systemd-сервис бота имеет ограничения:
- `ProtectHome=true` — нет доступа к домашним директориям
- `ProtectSystem=strict` — только чтение системных файлов
- `NoNewPrivileges=true` — нет дополнительных привилегий
- `ReadWritePaths` — запись только в `/opt/cubiveil-bot/`

### Авторизация

Бот принимает команды только от авторизованного `CHAT_ID`.

### Шифрование бэкапов

Утилиты поддерживают шифрование через `age`. Для зашифрованных бэкапов используйте SSH.

## 📁 Структура проекта

```
cubiveil/
├── assets/
│   ├── logo.png
│   └── telegram-bot/
│       ├── bot.py
│       ├── commands.py
│       ├── metrics.py
│       └── ...
├── lib/
│   ├── core/
│   ├── modules/
│   ├── common.sh
│   ├── i18n.sh
│   ├── install-steps.sh
│   └── ...
├── utils/
│   ├── cubiveil.sh
│   ├── monitor.sh
│   ├── backup.sh
│   ├── diagnose.sh
│   └── ...
├── tests/
├── install.sh
├── install-modular.sh
├── setup-telegram.sh
└── README.md
```

## 🧪 Тестирование

Запуск тестов:

```bash
bash run-tests.sh
```

CI/CD включает проверки:
- **Shellcheck** — статический анализ bash-скриптов
- **shfmt** — форматирование кода
- **bash -n** — проверка синтаксиса
- **Mypy** — проверка типов Python
- **Bandit** — анализ безопасности Python

## 🔧 Устранение неполадок

### Бот не отвечает

```bash
# Проверка статуса
systemctl status cubiveil-bot

# Перезапуск
systemctl restart cubiveil-bot

# Просмотр логов
journalctl -u cubiveil-bot -n 50
```

### Утилиты не выполняются

```bash
# Проверка путей
ls -la /opt/cubiveil/utils/

# Проверка прав
chmod +x /opt/cubiveil/utils/*.sh
```

### Проблемы с SSL

Убедитесь, что:
- A-запись домена указывает на IP сервера
- Порт 80/443 открыт в firewall
- Домен не внутренний (не localhost, не .local)

## 📄 Документация

- [Интеграция Telegram-бота](BOT_INTEGRATION.md)
- [Утилиты CubiVeil](utils/README.md)
- [Английская версия README](docs/README_EN.md)

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature-ветку (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

### Pre-commit хуки

Проект использует pre-commit для автоматических проверок перед коммитом:

```bash
# Установка зависимостей
pip install pre-commit detect-secrets

# Активация хуков
pre-commit install
```

**Что проверяется:**
- 🔐 Пароли, API-ключи, токены (detect-secrets)
- 🔐 Приватные ключи SSH/GPG/SSL
- 🐛 Синтаксис Bash-скриптов (shellcheck)
- 📦 Файлы >1MB блокируются

**Опционально (для полной защиты):**
```bash
# Установка trufflehog для проверки истории Git
# Linux/MacOS:
go install github.com/trufflesecurity/trufflehog/v3@latest

# Ручная проверка истории:
trufflehog git file://. --only-verified --fail
```

**Первичное сканирование на секреты:**
```bash
detect-secrets scan --baseline .secrets.baseline
```

> **Примечание для Windows:** shellcheck может иметь проблемы с кодировкой файлов. Для исправления конвертируйте файлы в Unix LF: `tr -d '\r' < file.sh > file.tmp`

## 📝 Лицензия

MIT License — см. файл [LICENSE](LICENSE)

## 👤 Автор

**cubiculus** — [GitHub](https://github.com/cubiculus/cubiveil)

---

<p align="center">
  <strong>CubiVeil</strong> | 
  <a href="docs/README_EN.md">English</a> | 
  <a href="https://github.com/cubiculus/cubiveil">GitHub</a>
</p>
