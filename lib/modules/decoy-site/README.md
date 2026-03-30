# Decoy Gen — Генератор Сайтов-Прикрытий

**Decoy Site Generator** — инструмент для генерации статических сайтов-прикрытий, имитирующих реальные файловые хранилища (Nextcloud, OneDrive, NAS и т.п.).

## 🚀 Возможности

- **12 уникальных шаблонов** — от минимализма до корпоративных панелей
- **10 000+ комбинаций названий** — каждый сайт уникален
- **Генерация цветовых схем** — 8 предустановленных тем + случайные
- **Фейковая статистика** — правдоподобные числа пользователей, файлов, трафика
- **Фейковая авторизация** — 8 типов ошибок, блокировка после 3 попыток
- **Локализация** — поддержка русского и английского языков
- **Адаптивный дизайн** — mobile-friendly интерфейсы

## 📁 Структура Проекта

```
lib/modules/decoy_gen/
├── generate.sh          # Главный скрипт генерации
├── rotate.sh            # Смена активного сайта
├── config.json          # Конфигурация по умолчанию
├── generators/
│   ├── colors.sh        # Генератор цветовых схем
│   ├── names.sh         # Генератор названий
│   ├── stats.sh         # Генератор статистики
│   └── content.sh       # Генератор контента
├── templates/           # 12 HTML-шаблонов
│   ├── minimal/         # Минималистичный
│   ├── single_page/     # Одностраничный лендинг
│   ├── corporate/       # Корпоративный
│   ├── personal/        # Персональный
│   ├── multi_page/      # Классический
│   ├── cloud_service/   # Современный SaaS
│   ├── media_library/   # Медиа-галерея
│   ├── backup_center/   # Технический
│   ├── dashboard/       # Панель управления
│   ├── admin_panel/     # Админ-панель
│   ├── secure_vault/    # Защищённое хранилище
│   └── team_workspace/  # Командная работа
├── webroot/             # Сгенерированный сайт
└── logs/                # Логи генерации
```

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
  --template, -t <name>   Шаблон (или 'auto' для случайного)
                          Доступны: minimal, single_page, corporate,
                          personal, multi_page, cloud_service,
                          media_library, backup_center, dashboard,
                          admin_panel, secure_vault, team_workspace
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
# Сгенерировать с конкретным шаблоном
bash generate.sh --template cloud_service

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
  "template": "auto",
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

## 🎨 Шаблоны

| Шаблон | Описание | Стиль |
|--------|----------|-------|
| minimal | Минималистичный интерфейс | Чистый, простой |
| single_page | Одностраничный лендинг | Современный градиент |
| corporate | Корпоративный портал | Бизнес-стиль |
| personal | Персональное хранилище | Дружелюбный |
| multi_page | Классическая навигация | Традиционный |
| cloud_service | SaaS-платформа | Тёмная тема, неон |
| media_library | Медиа-галерея | Кино-стиль |
| backup_center | Центр резервных копий | Терминальный |
| dashboard | Панель управления | Admin dashboard |
| admin_panel | Админ-панель | Контрольный центр |
| secure_vault | Защищённое хранилище | Security style |
| team_workspace | Командная работа | Collaboration |

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
