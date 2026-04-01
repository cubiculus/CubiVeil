# Decoy Gen V2 — Генератор Сайтов-Прикрытий

**Decoy Site Generator V2** — инструмент для генерации статических сайтов-прикрытий, имитирующих реальные файловые хранилища (Nextcloud, OneDrive, NAS и т.п.).

## 🚀 Возможности

- **15 уникальных вариантов** — от облачных хранилищ до корпоративных порталов
- **10 000+ комбинаций названий** — каждый сайт уникален
- **Генерация цветовых схем** — 8 предустановленных тем + случайные
- **Фейковая статистика** — правдоподобные числа пользователей, файлов, трафика
- **Фейковая авторизация** — 8 типов ошибок, блокировка после 3 попыток
- **Локализация** — поддержка русского и английского языков
- **Адаптивный дизайн** — mobile-friendly интерфейсы
- **Централизованная архитектура** — один шаблон, 15 вариантов конфигурации

## 📁 Структура Проекта

```
lib/modules/decoy-site/
├── generate.sh          # Главный скрипт генерации (V2)
├── rotate.sh            # Смена активного сайта
├── config.json          # Конфигурация по умолчанию
├── generators/
│   ├── variants.sh      # Централизованные определения вариантов
│   ├── colors.sh        # Генератор цветовых схем
│   ├── names.sh         # Генератор названий
│   ├── stats.sh         # Генератор статистики
│   └── content.sh       # Генератор контента
├── template/
│   └── index.html.tpl   # Адаптивный HTML-шаблон
├── webroot/             # Сгенерированный сайт (НЕ в git!)
└── logs/                # Логи генерации
```

> **Примечание:** Директория `webroot/` генерируется автоматически и **не хранится в репозитории**.
> После каждого запуска `generate.sh` содержимое `webroot/` обновляется.

## 🛠️ Установка

### Требования

- **Bash 5+** (Linux, macOS, WSL)
- **jq** — для работы с JSON
- **coreutils** — стандартные утилиты GNU

### Установка зависимостей

```bash
# Ubuntu/Debian
sudo apt-get install jq coreutils

# macOS (с Homebrew)
brew install jq coreutils

# Fedora/RHEL
sudo dnf install jq coreutils
```

## 📖 Использование

### Быстрый старт

```bash
cd lib/modules/decoy_gen

# Сгенерировать сайт с настройками по умолчанию
bash generate.sh

# Открыть в браузере
# webroot/index.html
```

### Параметры generate.sh

```bash
bash generate.sh [OPTIONS]

Options:
  --variant, -v <name>   Вариант сайта (или 'auto' для случайного)
                          Доступны: cloud_storage, backup_center, company_portal,
                          corporate_site, data_center, ecommerce, educational,
                          financial, government, healthcare, news_portal
  --lang, -l <lang>       Язык (ru или en, по умолчанию: ru)
  --theme <name>          Цветовая тема (или 'auto')
                          Доступны: ocean, forest, sunset, corporate,
                          dark, light, purple, warm
  --hue <0-360>           Базовый оттенок для генерации цветов
  --seed, -s <seed>       Seed для воспроизводимой генерации
  --users, -u <count>     Количество пользователей
  --files, -f <count>     Количество файлов
  --storage <bytes>       Размер хранилища в байтах
  --output, -o <dir>      Выходная директория (по умолчанию: ./webroot)
  --config, -c <file>     Файл конфигурации
  --help, -h              Показать справку
```

### Примеры

```bash
# Сгенерировать с конкретным вариантом
bash generate.sh --variant cloud_storage

# Английский язык с темой ocean
bash generate.sh --lang en --theme ocean

# Воспроизводимая генерация с seed
bash generate.sh --seed my-secret-seed-123

# Кастомные параметры
bash generate.sh --users 100 --files 5000 --storage 1099511627776
```

### Использование rotate.sh

```bash
# Показать все доступные сайты
bash rotate.sh list

# Активировать конкретный сайт
bash rotate.sh activate <site-name>

# Активировать случайный сайт
bash rotate.sh random

# Показать текущий активный сайт
bash rotate.sh current

# Показать статус
bash rotate.sh status
```

## ⚙️ Конфигурация

Файл `config.json`:

```json
{
  "variant": "auto",
  "lang": "ru",
  "color_theme": "auto",
  "base_hue": null,
  "users_count": null,
  "files_count": null,
  "storage_size": null,
  "seed": null,
  "output_dir": "./webroot"
}
```

## 🎨 Варианты сайтов

| Вариант | Описание | Стиль | Иконка |
|---------|----------|-------|--------|
| cloud_storage | Облачное хранилище | Файлы в сетке | ☁️ |
| media_library | Медиатека | Галерея медиа | 🎬 |
| backup_center | Центр резервного копирования | Панель управления | 💾 |
| corporate_portal | Корпоративный портал | Корпоративный | 🏢 |
| personal_vault | Личное хранилище | Приватные файлы | 🔐 |
| team_workspace | Командное пространство | Совместная работа | 👥 |
| secure_archive | Защищённый архив | Долгосрочное хранение | 🗄️ |
| file_sharing | Файлообменник | Обмен файлами | 🔗 |
| nas_interface | Сетевое хранилище | NAS интерфейс | 🖥️ |
| dev_repository | Репозиторий | Артефакты и пакеты | 📦 |
| photo_gallery | Фотогалерея | Фото в альбомах | 🖼️ |
| document_hub | Документооборот | Управление документами | 📄 |
| data_room | Комната данных | Due diligence | 🏛️ |
| sync_service | Сервис синхронизации | Синхронизация устройств | 🔄 |
| asset_manager | Менеджер активов | Цифровые активы | 🎨 |

## 🔐 Фейковая Авторизация

Все шаблоны включают систему фейковой авторизации:

- **8 типов ошибок**:
  - Неверный пароль
  - Аккаунт заблокирован
  - Требуется 2FA
  - Слишком много попыток
  - Аккаунт не найден
  - Неверное имя пользователя
  - Сессия истекла
  - Требуется подтверждение email

- **Блокировка**: После 3 неудачных попыток — блокировка на 5 минут (через sessionStorage)

- **Страницы**: `/login`, `/2fa`, `/forgot-password`

## 📊 Генераторы

### colors.sh
Генерирует согласованные цветовые схемы:
- Primary, Secondary, Accent, Background, Text, Border
- Контраст текста/фона ≥ 4.5:1 (WCAG)
- 8 предустановленных тем

### names.sh
Генерирует названия сайтов:
- Формат: `<прилагательное> <существительное> <тип>`
- Словари: технологии, природа, космос, архитектура, абстракция
- 10 000+ уникальных комбинаций
- Поддержка RU и EN

### stats.sh
Генерирует консистентную статистику:
- Хранилище: 500GB–20TB
- Пользователи: 10–500
- Файлы: 1000–500000
- Коррелированные метрики трафика

### content.sh
Генерирует контент:
- Имена папок (категоризированные)
- Имена файлов (разные расширения)
- Имена пользователей (firstname.lastname)
- Размеры файлов

## 🧪 Тестирование

### Проверка уникальности (100 запусков)

```bash
cd lib/modules/decoy_gen

# Запустить 100 генераций и проверить уникальность
for i in {1..100}; do
    bash generate.sh --output "test_sites/site_$i" 2>/dev/null
    find "test_sites/site_$i" -type f -exec md5sum {} \; | sort | md5sum | cut -c1-16 >> hashes.txt
done

# Проверить дубликаты
sort hashes.txt | uniq -d
# Пустой вывод = все сайты уникальны
```

### Shellcheck

```bash
# Проверка всех скриптов
shellcheck generate.sh rotate.sh generators/*.sh
```

## 📝 Логирование

Все события генерации записываются в `logs/generate.log`:

```
[2024-01-15 10:30:45] [INFO] === Starting generation ===
[2024-01-15 10:30:45] [INFO] Using seed: abc123def456
[2024-01-15 10:30:45] [INFO] Selected template: cloud_service
[2024-01-15 10:30:46] [INFO] Site name: Quantum Nexus Cloud
[2024-01-15 10:30:47] [INFO] === Generation completed in 2s ===
```

## 🚀 Развёртывание

### nginx

```bash
# Скопировать конфиг
cp webroot/nginx.conf /etc/nginx/sites-available/cubiveil

# Активировать
ln -s /etc/nginx/sites-available/cubiveil /etc/nginx/sites-enabled/

# Перезагрузить nginx
sudo nginx -t && sudo systemctl reload nginx
```

### Docker

```dockerfile
FROM nginx:alpine
COPY webroot/ /usr/share/nginx/html/
EXPOSE 80
```

## 📄 Лицензия

MIT License — см. файл LICENSE.

## 🤝 Вклад

1. Fork репозиторий
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📞 Контакты

- GitHub: [decoy_gen](https://github.com/yourusername/decoy_gen)
- Issues: [GitHub Issues](https://github.com/yourusername/decoy_gen/issues)

---

**Decoy Gen** — Делайте ваши настоящие данные невидимыми.
