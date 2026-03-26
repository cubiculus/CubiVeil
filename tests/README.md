# CubiVeil Tests

Комплексные тесты для CubiVeil: unit-тесты, интеграционные тесты и end-to-end проверки.

---

## Быстрый старт

```bash
# Запуск всех unit-тестов (не требуют root)
./run-tests.sh

# Запуск всех тестов (требуются права root для интеграционных)
sudo ./run-tests.sh --full

# Только unit-тесты
./run-tests.sh --unit

# Только интеграционные тесты (требует root)
sudo ./run-tests.sh --integration

# Тесты Telegram-бота (Python)
cd telegram-bot
python3 run_tests.py
```

---

## Структура тестов

```
tests/
├── run-tests.sh              # Главный runner тестов
├── README.md                 # Эта документация
├── integration-test.sh       # Интеграционные тесты
├── modular-structure.sh      # Тесты модульной архитектуры
├── unit-utils.sh             # Unit-тесты lib/utils.sh
├── unit-install-steps.sh     # Unit-тесты lib/install-steps.sh
├── unit-install-steps-main.sh # Unit-тесты lib/steps/install-steps-main.sh
├── test-install-modes.sh     # Тесты режимов --dev и --dry-run
├── unit-lang.sh              # Unit-тесты lang.sh (локализация)
├── unit-install.sh           # Unit-тесты install.sh
├── unit-telegram.sh          # Unit-тесты setup-telegram.sh
├── unit-decoy-site.sh        # Unit-тесты decoy-site модуля
├── unit-traffic-shaping.sh   # Unit-тесты traffic-shaping модуля
└── telegram-bot/             # Python тесты Telegram-бота
    ├── run_tests.py          # Test runner
    ├── test_keyboards.py     # 16 тестов inline клавиатур
    ├── test_logs.py          # 13 тестов логов
    ├── test_profiles.py      # 13 тестов Marzban API
    ├── test_backup.py        # 13 тестов бэкапов
    ├── test_metrics.py       # 9 тестов метрик
    ├── test_commands.py      # 22 тестов команд
    └── test_telegram_client.py # 12 тестов Telegram API
```

---

## Unit-тесты

### 1. lib/utils.sh (`unit-utils.sh`)

Тестирует утилитные функции:

| Функция | Тесты |
|---------|-------|
| `gen_random()` | Длина строки, символы (a-zA-Z0-9), уникальность, граничные значения (0, 1, 1000), статистическая равномерность |
| `gen_hex()` | Длина строки, hex-символы (a-f0-9), lowercase, граничные значения, статистическая равномерность |
| `gen_port()` | Диапазон 30000-62000, уникальность |
| `unique_port()` | Уникальность портов, отсутствие в USED_PORTS |
| `open_port()` | Mock ufw, граничные порты (1, 80, 443, 65535), TCP/UDP, комментарии |
| `close_port()` | Mock ufw delete |
| `arch()` | Поддерживаемые архитектуры (amd64, arm64) |
| `get_server_ip()` | Получение внешнего IP |

**Запуск:**
```bash
bash tests/unit-utils.sh
```

---

### 2. lib/install-steps.sh (`unit-install-steps.sh`)

Тестирует функции установки:

| Функция | Проверки |
|---------|----------|
| `prompt_inputs()` | Наличие валидации домена, email, Telegram опции |
| `step_check_ip_neighborhood()` | Проверка репутации подсети |
| `step_system_update()` | apt-get update, DEBIAN_FRONTEND, пакеты |
| `step_auto_updates()` | 20auto-upgrades, 50unattended-upgrades, systemctl |
| `step_bbr()` | modprobe tcp_bbr, sysctl конфиг |
| `step_firewall()` | ufw reset, правила по умолчанию, open_port |
| `step_fail2ban()` | cubiveil.conf, SSH порт, systemctl |
| `step_install_singbox()` | GitHub API, скачивание, установка в /usr/local/bin |
| `step_generate_keys_and_ports()` | Reality keypair, UUID, unique_port, CDN camouflage |
| `step_install_marzban()` | Официальный скрипт, проверка наличия |
| `step_ssl()` | acme.sh, порт 80, сертификаты в /var/lib/marzban/certs |
| `step_configure()` | .env файл, sing-box-template.json, 5 профилей |
| `step_finish()` | restart marzban, health-check, проверка статуса |

**Запуск:**
```bash
bash tests/unit-install-steps.sh
```

---

### 3. lang.sh (`unit-lang.sh`)

Тестирует локализацию EN/RU:

| Категория | Проверки |
|-----------|----------|
| **Базовые** | Наличие файла, синтаксис, загрузка модуля |
| **Язык по умолчанию** | LANG_NAME установлен (Русский/English) |
| **Функции** | `select_language`, `step_title`, `get_str`, `check_root`, `check_ubuntu`, `print_banner` |
| **Цвета** | RED, GREEN, YELLOW, BLUE, CYAN, PLAIN |
| **Вывод** | ok, warn, err, info, step |
| **EN строки** | ERR_ROOT, PROMPT_DOMAIN, WARN_DNS_RECORD, и т.д. |
| **RU строки** | ERR_ROOT_RU, PROMPT_DOMAIN_RU, WARN_DNS_RECORD_RU, и т.д. |
| **Шаги** | STEP_CHECK_SUBNET, STEP_UPDATE, ..., STEP_TELEGRAM (EN + RU) |
| **Telegram** | PROMPT_TG_TOKEN, ERR_TG_TOKEN_FORMAT, OK_TG_TOKEN_VERIFIED |
| **Финальные** | SUCCESS_TITLE, NEXT_STEPS (EN + RU) |
| **Полнота** | Покрытие RU строк ≥ 80% от EN |
| **Качество** | Отсутствие пустых строк, корректное экранирование |

**Запуск:**
```bash
bash tests/unit-lang.sh
```

---

### 4. install.sh (`unit-install.sh`)

Тестирует главную точку входа:

| Категория | Проверки |
|-----------|----------|
| **Базовые** | Наличие файла, синтаксис, shebang (#!/bin/bash) |
| **Strict mode** | set -euo pipefail |
| **Модули** | Загрузка lang.sh, lib/utils.sh, lib/install-steps.sh |
| **Функции** | main существует и вызывается |
| **Шаги** | Использование 15+ функций из модулей, последовательность |
| **Обработка ошибок** | err функция, || и && операторы |
| **Fallback** | Резервные определения если lang.sh отсутствует |
| **Размер** | < 200 строк (компактный) |
| **Документация** | Комментарии (≥ 5) |
| **Безопасность** | Проверка root, проверка Ubuntu, отсутствие хардкодных секретов |
| **Кавычки** | Переменные в кавычках |
| **Интеграция** | Упоминание setup-telegram.sh, INSTALL_TG переменная |

**Запуск:**
```bash
bash tests/unit-install.sh
```

---

### 5. lib/steps/install-steps-main.sh (`unit-install-steps-main.sh`)

Тестирует основные шаги установки из нового модуля:

| Категория | Проверки |
|-----------|----------|
| **Базовые** | Наличие файла, синтаксис |
| **Функции шагов** | Все 13 step_* функций существуют |
| **step_ssl_dev** | Генерация self-signed SSL через openssl, директория /var/lib/marzban/certs, срок действия 100 лет |
| **step_ssl** | Проверка DEV_MODE, вызов step_ssl_dev в dev-режиме |
| **step_finish** | Отображение URL панели, предупреждения о dev-режиме и self-signed SSL |
| **Локализация** | Поддержка EN/RU в функциях |

**Запуск:**
```bash
bash tests/unit-install-steps-main.sh
```

---

### 6. install.sh режимы (`test-install-modes.sh`)

Тестирует режимы --dev и --dry-run:

| Категория | Проверки |
|-----------|----------|
| **Переменные** | DEV_MODE, DRY_RUN, DEV_DOMAIN определены |
| **Аргументы** | --dev, --dry-run, --domain, --help обрабатываются |
| **Usage** | Содержит описание режимов и примеры |
| **Dry-run** | Показывает план установки, проверяет root и Ubuntu, не вносит изменения |
| **Dev-режим** | Предупреждения о self-signed SSL, dev.cubiveil.local по умолчанию |
| **step_ssl_dev** | Функция существует, использует openssl |
| **prompt_inputs** | Проверяет DEV_MODE, пропускает ввод в dev-режиме |

**Запуск:**
```bash
bash tests/test-install-modes.sh
```

---

### 7. setup-telegram.sh (`unit-telegram.sh`)

Тестирует скрипт установки Telegram бота:

| Категория | Проверки |
|-----------|----------|
| **Базовые** | Наличие файла, синтаксис, функции (step_check_environment, main, и т.д.) |
| **Зависимости** | Загрузка lang.sh, lib/utils.sh |
| **Безопасность** | Токен в os.environ.get, ProtectHome, ProtectSystem, NoNewPrivileges |
| **Python бот** | |
| └─ Метрики | get_cpu, get_ram, get_disk, get_uptime, get_active_users |
| └─ Отправка | tg_send, tg_send_file |
| └─ Команды | /start, /status, /backup, /users, /restart, /help |
| └─ Polling | getUpdates API, авторизация по chat_id |
| └─ Алерты | check_alerts, load_state/save_state, пороги |
| └─ Бэкапы | make_backup, /var/lib/marzban/db.sqlite3, удаление старых |
| └─ Точка входа | if __name__ == "__main__", режимы report/alert/poll |
| └─ Ошибки | try/except, URLError, Exception |
| └─ Визуализация | bar функция, emoji |
| **Systemd** | cubiveil-bot.service, Environment переменные, директивы |
| **Cron** | Ежедневный отчёт, алерты каждые 15 мин |
| **Логирование** | journald конфиг, logrotate конфиг |
| **Валидация** | Формат токена, проверка через API, формат Chat ID |

**Запуск:**
```bash
bash tests/unit-telegram.sh
```

---

### 6. modular-structure.sh

Тестирует модульную архитектуру проекта:

| Проверка | Описание |
|----------|----------|
| Структура директорий | lib/, tests/ существуют |
| Основные файлы | install.sh, setup-telegram.sh, lang.sh, README.md, run-tests.sh |
| Модули lib/ | utils.sh, install-steps.sh |
| Тестовые файлы | Все тесты существуют |
| Синтаксис | Все скрипты проходят bash -n |
| Исполнимость | Скрипты имеют +x флаг |
| Загрузка модулей | source работает без ошибок |
| Функции | Все функции в utils.sh и install-steps.sh существуют |
| Дублирование | install.sh не содержит код бота, utils.sh не содержит step_* |
| Размеры | install.sh < 200 строк |
| Интеграция | install.sh загружает модули и использует функции |

**Запуск:**
```bash
bash tests/modular-structure.sh
```

---

## Интеграционные тесты (`integration-test.sh`)

Проверяют установленную систему (требуют root):

### Базовые проверки
- Uptime сервера
- Свободное место на диске
- Использование RAM

### Сервисы
- Marzban активен
- Sing-box активен
- Health-check сервис активен
- Telegram бот (опционально)

### Сеть
- Порт 443/tcp открыт (VLESS Reality)
- Порт 443/udp открыт (Hysteria2)
- Health-check endpoint отвечает (/health, /ready)

### Безопасность
- UFW активен
- Fail2ban активен
- Credentials зашифрованы (age)
- Ключ age существует
- Незашифрованный файл удалён

### SSL
- Сертификат валиден
- Сертификат не истёк

### Конфигурация
- Marzban .env содержит все переменные
- Sing-box шаблон — валидный JSON
- Sing-box шаблон содержит 5 профилей

### Логирование
- Journald конфиг создан
- Logrotate конфиг создан

**Запуск:**
```bash
sudo bash tests/integration-test.sh
```

---

## Запуск тестов

### Все unit-тесты (без root)
```bash
./run-tests.sh
```

### Все тесты (требует root для интеграционных)
```bash
sudo ./run-tests.sh --full
```

### Только конкретный тест
```bash
bash tests/unit-utils.sh
bash tests/unit-install-steps.sh
bash tests/unit-lang.sh
bash tests/unit-install.sh
bash tests/unit-telegram.sh
bash tests/modular-structure.sh
sudo bash tests/integration-test.sh
```

---

## Интерпретация результатов

### Все тесты пройдены ✅
```
╔══════════════════════════════════════════════════════╗
║        CubiVeil Unit Tests - lib/utils.sh            ║
╚══════════════════════════════════════════════════════╝

[INFO] Тестирование gen_random...
[PASS] gen_random(10): длина = 10
[PASS] gen_random(10): только буквы и цифры

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Пройдено: 42
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Все тесты пройдены
```

### Некоторые тесты провалены ❌
```
[INFO] Тестирование gen_hex...
[PASS] gen_hex(16): длина = 16
[FAIL] gen_hex(16): содержит недопустимые символы

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Пройдено: 38
Провалено:  4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ Тесты провалены
```

**Exit code:** `0` — все пройдены, `1` — есть проваленные

---

## Добавление новых тестов

### Unit-тесты

1. Создай файл `tests/unit-<module>.sh`
2. Используй стандартную структуру:
   ```bash
   #!/bin/bash
   set -euo pipefail

   # Цвета
   RED='\033[0;31m'
   GREEN='\033[0;32m'
   YELLOW='\033[0;33m'
   PLAIN='\033[0m'

   pass() { echo -e "${GREEN}[PASS]${PLAIN} $1"; }
   fail() {
     echo -e "${RED}[FAIL]${PLAIN} $1"
     ((TESTS_FAILED++))
   }
   warn() { echo -e "${YELLOW}[WARN]${PLAIN} $1"; }
   info() { echo -e "[INFO] $1"; }

   TESTS_PASSED=0
   TESTS_FAILED=0

   # Mock зависимостей
   # ...

   # Тесты
   test_my_function() {
     info "Тестирование..."
     # Твой код
   }

   # Основная функция
   main() {
     test_my_function
     # Итоги...
   }

   main "$@"
   ```

3. Добавь тест в `run-tests.sh`

### Интеграционные тесты

1. Открой `tests/integration-test.sh`
2. Добавь функцию:
   ```bash
   check_my_feature() {
     if [[ condition ]]; then
       pass "Описание"
       ((TESTS_PASSED++))
     else
       fail "Ошибка"
       ((TESTS_FAILED++))
     fi
   }
   ```
3. Вызови в `main()`

---

## Утилиты для тестов

| Функция | Описание | Пример |
|---------|----------|--------|
| `pass` | Отметить тест как пройденный | `pass "Всё хорошо"` |
| `fail` | Отметить тест как проваленный | `fail "Что-то не так"` |
| `warn` | Предупреждение (не критично) | `warn "Опционально"` |
| `info` | Информационное сообщение | `info "Тестирование..."` |

### Интеграционные утилиты

| Функция | Описание |
|---------|----------|
| `check_service_active` | Проверка systemd сервиса |
| `check_port_open` | Проверка открытого порта |
| `check_file_exists` | Проверка существования файла |
| `check_file_encrypted` | Проверка шифрования age |
| `check_health_endpoint` | Проверка HTTP endpoint |
| `check_ssl_cert` | Проверка SSL сертификата |

---

## Покрытие тестов

| Модуль | Файл теста | Покрытие |
|--------|-----------|----------|
| lib/utils.sh | unit-utils.sh | ✅ gen_random, gen_hex, gen_port, unique_port, open_port, arch, get_server_ip |
| lib/install-steps.sh | unit-install-steps.sh | ✅ Все 13 функций установки |
| lib/steps/install-steps-main.sh | unit-install-steps-main.sh | ✅ Все step_* функции, step_ssl_dev, dev-режим |
| install.sh режимы | test-install-modes.sh | ✅ --dev, --dry-run, аргументы, usage |
| lang.sh | unit-lang.sh | ✅ EN/RU строки, функции, локализация |
| install.sh | unit-install.sh | ✅ Структура, модули, обработка ошибок |
| setup-telegram.sh | unit-telegram.sh | ✅ Python бот, systemd, cron, валидация |
| lib/modules/decoy-site/ | unit-decoy-site.sh | ✅ Генерация контента, ротация, MikroTik скрипт |
| lib/modules/traffic-shaping/ | unit-traffic-shaping.sh | ✅ TC/netem правила, персистентность |
| Модульная структура | modular-structure.sh | ✅ Архитектура, зависимости |
| Установленная система | integration-test.sh | ✅ Сервисы, сеть, безопасность |
| **Telegram Bot (Python)** | | |
| └─ keyboards.py | test_keyboards.py | ✅ 16 тестов: все inline клавиатуры |
| └─ profiles.py | test_profiles.py | ✅ 13 тестов: Marzban API client |
| └─ logs.py | test_logs.py | ✅ 13 тестов: модуль логов |
| └─ backup.py | test_backup.py | ✅ 13 тестов: управление бэкапами |
| └─ metrics.py | test_metrics.py | ✅ 9 тестов: сбор метрик |
| └─ commands.py | test_commands.py | ✅ 22 тестов: обработчик команд |
| └─ telegram_client.py | test_telegram_client.py | ✅ 12 тестов: Telegram API client |
| **ВСЕГО** | **98 тестов** | ✅ **100% проходят** |

---

## CI/CD Интеграция

### GitHub Actions
```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run unit tests
        run: ./tests/run-tests.sh --unit

      - name: Run integration tests
        run: sudo ./tests/run-tests.sh --integration
```

### GitLab CI
```yaml
test:
  script:
    - ./tests/run-tests.sh --unit
    - sudo ./tests/run-tests.sh --integration
```

---

## Лицензия

MIT — как и основной проект.
