# CubiVeil Utilities

Набор утилит для управления и обслуживания CubiVeil.

## 📁 Структура

```
utils/
├── cubiveil.sh        # CLI менеджер (единая точка входа)
├── install-aliases.sh # Установка алиасов для команд
├── update.sh          # Обновление системы
├── rollback.sh        # Откат к предыдущей версии
├── export-config.sh   # Экспорт конфигурации
├── monitor.sh         # Мониторинг сервера
├── diagnose.sh        # Диагностика проблем
├── manage-profiles.sh # Управление профилями
└── backup.sh          # Резервное копирование
```

## 🚀 Быстрый старт

### Установка алиасов (рекомендуется)

```bash
sudo bash utils/install-aliases.sh
```

После установки используйте короткие команды:
- `cv` — справка
- `cv monitor` — мониторинг
- `cv backup create` — бэкап
- `cv profiles list` — профили
- `cv diagnose` — диагностика

### Прямой запуск через CLI

```bash
sudo bash utils/cubiveil.sh <команда> [аргументы]
```

### Прямой запуск скриптов

```bash
sudo bash utils/update.sh
sudo bash utils/backup.sh create
```

## 📖 Описание утилит

### cubiveil.sh — CLI менеджер

Единая точка доступа ко всем утилитам.

```bash
sudo bash utils/cubiveil.sh --help   # справка
sudo bash utils/cubiveil.sh --list   # список команд
sudo bash utils/cubiveil.sh update   # обновить
```

### install-aliases.sh — установка алиасов

Устанавливает CLI в `/usr/local/bin/cubiveil` и добавляет алиасы.

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

### manage-profiles.sh — профили

Управление профилями прокси.

```bash
sudo bash utils/manage-profiles.sh list      # список
sudo bash utils/manage-profiles.sh add       # добавить
sudo bash utils/manage-profiles.sh remove    # удалить
sudo bash utils/manage-profiles.sh enable    # включить
sudo bash utils/manage-profiles.sh disable   # выключить
sudo bash utils/manage-profiles.sh qr        # QR-код
sudo bash utils/manage-profiles.sh stats     # статистика
```

### backup.sh — бэкап

Полное резервное копирование.

```bash
sudo bash utils/backup.sh create    # создать
sudo bash utils/backup.sh list      # список
sudo bash utils/backup.sh restore <файл>  # восстановить
sudo bash utils/backup.sh cleanup   # очистка
```

## 🔧 Технические детали

### Подключение к проекту

Все утилиты автоматически подключают:
- `lang.sh` — локализация (RU/EN)
- `lib/utils.sh` — общие функции
- `lib/fallback.sh` — резервная локализация

### Требования

- **root** — все утилиты требуют прав root
- **bash 4.0+** — используются ассоциативные массивы
- **age** — для шифрования (опционально)

### Безопасность

Все скрипты используют:
- `set -euo pipefail` — строгий режим
- Проверку прав root
- Локализацию сообщений
- Обработку ошибок

## 📝 Лицензия

MIT — см. основной LICENSE в корне проекта.
