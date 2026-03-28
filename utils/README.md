# CubiVeil Utilities

Набор утилит для управления и обслуживания CubiVeil.

## 📁 Структура

```
utils/
├── install-aliases.sh # Установка алиасов для команд
├── update.sh          # Обновление системы
├── rollback.sh        # Откат к предыдущей версии
├── export-config.sh   # Экспорт конфигурации
├── import-config.sh   # Импорт конфигурации
├── monitor.sh         # Мониторинг сервера
├── diagnose.sh        # Диагностика проблем
├── backup.sh          # Резервное копирование
├── decoy-rotate.sh    # Управление ротацией decoy-site
└── README.md          # Этот файл
```

## 🚀 Быстрый старт

### Установка алиасов (рекомендуется)

```bash
sudo bash utils/install-aliases.sh
```

После установки используйте короткие команды:
- `cv-monitor` — мониторинг
- `cv-backup` — бэкап
- `cv-update` — обновление
- `cv-rollback` — откат
- `cv-export` — экспорт конфигурации
- `cv-import` — импорт конфигурации
- `cv-diagnose` — диагностика

### Прямой запуск скриптов

```bash
sudo bash utils/update.sh
sudo bash utils/backup.sh
sudo bash utils/monitor.sh
```

## 📖 Описание утилит

### install-aliases.sh — установка алиасов

Устанавливает алиасы для удобного запуска утилит.

```bash
sudo bash utils/install-aliases.sh
source /root/.bashrc  # обновить сессию
```

### update.sh — обновление

Обновляет CubiVeil до последней версии с GitHub.

```bash
sudo bash utils/update.sh
```

### rollback.sh — откат

Откат к предыдущей версии из бэкапа.

```bash
sudo bash utils/rollback.sh              # выбор бэкапа
sudo bash utils/rollback.sh /path/to/backup  # конкретный бэкап
```

### export-config.sh — экспорт

Экспорт конфигурации для миграции на другой сервер.

```bash
sudo bash utils/export-config.sh
```

### import-config.sh — импорт

Импорт конфигурации после экспорта.

```bash
sudo bash utils/import-config.sh /path/to/export
```

### monitor.sh — мониторинг

Мониторинг сервера в реальном времени.

```bash
sudo bash utils/monitor.sh              # непрерывный
sudo bash utils/monitor.sh --snapshot   # однократно
sudo bash utils/monitor.sh -i 10        # интервал 10с
```

### diagnose.sh — диагностика

Диагностика проблем и сбор отчётов.

```bash
sudo bash utils/diagnose.sh
```

### backup.sh — бэкап

Полное резервное копирование (Marzban + Sing-box + CubiVeil).

```bash
sudo bash utils/backup.sh           # меню бэкапа
sudo bash utils/backup.sh create    # создать
sudo bash utils/backup.sh list      # список
sudo bash utils/backup.sh restore   # восстановить
sudo bash utils/backup.sh cleanup   # очистка
```

### decoy-rotate.sh — управление ротацией decoy-site

Управление сайтом-прикрытием и ротацией файлов.

```bash
# Статус
sudo bash utils/decoy-rotate.sh status

# Принудительная ротация
sudo bash utils/decoy-rotate.sh rotate

# Список файлов
sudo bash utils/decoy-rotate.sh files

# Конфигурация
sudo bash utils/decoy-rotate.sh config

# Управление
sudo bash utils/decoy-rotate.sh enable      # Включить ротацию
sudo bash utils/decoy-rotate.sh disable     # Выключить ротацию
sudo bash utils/decoy-rotate.sh restart     # Перезапустить таймер

# Настройка
sudo bash utils/decoy-rotate.sh set-interval 6     # Интервал (часы)
sudo bash utils/decoy-rotate.sh set-limit 5000     # Лимит (MB)
sudo bash utils/decoy-rotate.sh set-weight jpg 4   # Вес типа

# Очистка
sudo bash utils/decoy-rotate.sh cleanup     # Очистка старых файлов
sudo bash utils/decoy-rotate.sh regenerate  # Перегенерация всех файлов
```

**Telegram-бот:**

После установки доступны команды:
- `/decoy` — меню управления decoy-site
- `/decoy_status` — статус ротации
- `/decoy_rotate` — принудительная ротация
- `/decoy_files` — список файлов
- `/decoy_config` — конфигурация

## 🔧 Управление профилями

Для управления профилями используйте **Telegram-бота** (рекомендуется) или Marzban CLI:

### Через Telegram-бота

После установки бота (`bash setup-telegram.sh`) доступны команды:
- `/profiles` — список профилей
- `/create` — создать профиль
- `/enable` — включить профиль
- `/disable` — отключить профиль
- `/extend` — продлить профиль
- `/qr` — QR-код для подключения
- `/traffic` — статистика трафика
- `/subscription` — ссылка на подписку

### Через Marzban CLI

```bash
# Список пользователей
marzban-cli user list

# Создать пользователя
marzban-cli user create --username myuser --expire 30 --data-limit 100

# Удалить пользователя
marzban-cli user delete myuser
```

## 🔧 Технические детали

### Подключение к проекту

Все утилиты автоматически подключают:
- `lang/main.sh` — локализация (RU/EN)
- `lib/utils.sh` — общие функции
- `lib/fallback.sh` — резервная локализация

### Требования

- **root** — все утилиты требуют прав root
- **bash 4.0+** — используются ассоциативные массивы
- **age** — для шифрования (опционально, требуется для export-config.sh)

### Безопасность

Все скрипты используют:
- `set -euo pipefail` — строгий режим
- Проверку прав root
- Локализацию сообщений
- Обработку ошибок

## 📝 Лицензия

MIT — см. основной LICENSE в корне проекта.
