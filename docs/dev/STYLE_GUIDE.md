# CubiVeil Style Guide

Руководство по стилю кода для проекта CubiVeil.

## Содержание

- [Python Style Guide](#python-style-guide)
- [Bash Style Guide](#bash-style-guide)
- [Документирование кода](#документирование-кода)

---

## Python Style Guide

### Именование

#### Константы

Константы объявляются в начале файла, сразу после импортов. Используются заглавные буквы с подчёркиваниями.

```python
# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# File paths / Пути к файлам
BACKUP_DIR = "/opt/cubiveil-bot/backups"

# Time intervals in seconds / Временные интервалы в секундах
HEALTH_CHECK_INTERVAL = 300  # 5 minutes
POLL_ERROR_DELAY = 5

# Threshold validation bounds / Границы проверки порогов
THRESHOLD_MIN = 0
THRESHOLD_MAX = 100
```

**Правила:**
- Константы группируются по назначению с комментариями-заголовками
- Каждая константа имеет комментарий на английском и русском
- Значения выносятся в константы, если они используются более одного раза или являются "магическими числами"

#### Переменные и функции

Используется `snake_case`:

```python
# Правильно:
alert_cpu = 80

def get_cpu_usage():
    pass

def _validate_threshold(value):
    pass
```

#### Классы

Используется `PascalCase`:

```python
class CubiVeilBot:
    """Main bot class coordinating all components"""

    def __init__(self):
        pass
```

### Документирование

#### Docstrings для модулей

Каждый файл начинается с docstring, описывающего назначение модуля:

```python
#!/usr/bin/env python3
"""
Metrics Collection Module
Collects system metrics: CPU, RAM, disk, uptime, active users
"""
```

#### Docstrings для функций

Все функции должны иметь docstring с описанием, параметров и возвращаемого значения:

```python
def get_cpu(self):
    """
    Get CPU usage from /proc/stat
    Reads twice with minimal delay

    Returns:
        float: CPU usage percentage
    """
```

```python
def check_connection_speed(self, target: str = "https://www.google.com",
                            timeout: int = CONNECTION_TIMEOUT) -> dict:
    """
    Check connection speed to a target URL

    Args:
        target: URL to check connection to
        timeout: Request timeout in seconds

    Returns:
        dict: Dictionary with latency_ms, success, error keys
    """
```

### Структура файла

```python
#!/usr/bin/env python3
"""Module docstring"""

# Imports
import os
import sys

# Local imports
from module import Class

# Constants (with bilingual comments)
# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# Group name / Название группы
CONSTANT_ONE = 1
CONSTANT_TWO = 2

# Classes
class MyClass:
    """Class docstring"""

    def __init__(self):
        """Initializer docstring"""
        pass

    def method(self):
        """Method docstring"""
        pass

# Main entry point
if __name__ == "__main__":
    main()
```

---

## Bash Style Guide

### Именование

#### Константы

Константы объявляются в начале файла с использованием `readonly` и заглавных букв:

```bash
# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# ── Цвета / Colors ───────────────────────────────────────────
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'

# ── Порты / Ports ────────────────────────────────────────────
readonly PORT_MIN=30000
readonly PORT_MAX=62000

# ── Таймауты / Timeouts ──────────────────────────────────────
readonly IP_CHECK_TIMEOUT=4
```

**Правила:**
- Использовать `readonly` для констант
- Группировать по назначению с комментариями-разделителями
- Двухъязычные комментарии (английский/русский)

#### Функции

Используется `snake_case` с маленькими буквами:

```bash
# Проверка root прав
# Выходит с ошибкой если не root
check_root() {
  local err_msg="${1:-}"
  local err_msg_ru="${2:-}"

  if [[ $EUID -ne 0 ]]; then
    err "Scripts must be run as root (sudo)"
  fi
}

# Проверка что это Ubuntu
check_ubuntu() {
  if ! grep -qi "ubuntu" /etc/os-release; then
    err "This script is only for Ubuntu"
  fi
}
```

#### Переменные

Локальные переменные объявляются через `local`:

```bash
my_function() {
  local my_var="$1"
  local count=0

  # Использование
  echo "$my_var"
}
```

### Документирование

#### Заголовок файла

Каждый файл начинается с заголовка:

```bash
#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Common Utilities                      ║
# ║          github.com/cubiculus/cubiveil                    ║
# ╚═══════════════════════════════════════════════════════════╝
```

#### Комментарии к функциям

Перед каждой функцией указывается описание на двух языках:

```bash
# Проверка root без выхода (возвращает 0/1)
# Check root without exit (returns 0/1)
is_root() {
  [[ $EUID -eq 0 ]]
}

# Проверка Ubuntu без выхода (возвращает 0/1)
# Check Ubuntu without exit (returns 0/1)
is_ubuntu() {
  grep -qi "ubuntu" /etc/os-release
}
```

#### Параметры функций

Для функций с параметрами указывается документация:

```bash
# Заголовок шага с номером и локализацией
# Parameters:
#   $1 - step number
#   $2 - Russian description
#   $3 - English description
step_title() {
  local step="$1"
  local ru="$2"
  local en="$3"
  # ...
}
```

### Структура файла

```bash
#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Module Name                           ║
# ║          github.com/cubiculus/cubiveil                    ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение модулей / Module imports ────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/other.sh" ]]; then
  source "${SCRIPT_DIR}/other.sh"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# ── Group / Группа ──────────────────────────────────────────
readonly CONSTANT="value"

# ── Functions / Функции ─────────────────────────────────────

# Function description / Описание функции
# Parameters:
#   $1 - parameter description
my_function() {
  local param="$1"

  # Implementation
}

# ── Main / Основное ──────────────────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

---

## Общие правила

### Магические числа

Запрещается использование магических чисел в коде. Все числовые значения должны быть вынесены в константы:

**Python:**
```python
# ❌ Плохо:
if cpu > 80:
    send_alert()

time.sleep(5)

# ✅ Хорошо:
DEFAULT_ALERT_CPU = 80
POLL_ERROR_DELAY = 5

if cpu > DEFAULT_ALERT_CPU:
    send_alert()

time.sleep(POLL_ERROR_DELAY)
```

**Bash:**
```bash
# ❌ Плохо:
if [[ $attempts -lt 50 ]]; then
    # ...
fi

# ✅ Хорошо:
readonly MAX_PORT_ATTEMPTS=50

if [[ $attempts -lt $MAX_PORT_ATTEMPTS ]]; then
    # ...
fi
```

### Двухъязычные комментарии

Все комментарии должны быть на английском и русском языках:

```python
# Alert thresholds defaults / Пороги уведомлений по умолчанию
DEFAULT_ALERT_CPU = 80
```

```bash
# ── Порты / Ports ────────────────────────────────────────────
readonly PORT_MIN=30000
```

### Разделители секций

Для разделения секций используются специальные комментарии-разделители:

**Python:**
```python
# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════
```

**Bash:**
```bash
# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# ── Group / Группа ──────────────────────────────────────────
```

---

## Проверка стиля

### Python

Для проверки стиля Python используется mypy и bandit:

```bash
mypy bot.py
bandit bot.py
```

### Bash

Для проверки Bash скриптов используется shellcheck:

```bash
shellcheck script.sh
```

---

## Примеры

### Python пример

```python
#!/usr/bin/env python3
"""
Metrics Collection Module
Collects system metrics: CPU, RAM, disk, uptime, active users
"""

import subprocess
import time

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# File paths / Пути к файлам
PROC_STAT_PATH = "/proc/stat"

# Time delays in seconds / Временные задержки в секундах
CPU_READ_DELAY = 0.01  # Minimal delay between CPU readings


class MetricsCollector:
    """Collects system metrics"""

    def __init__(self, db_path=DEFAULT_DB_PATH):
        """
        Initialize metrics collector

        Args:
        """
        self.db_path = db_path

    def get_cpu(self):
        """
        Get CPU usage from /proc/stat
        Reads twice with minimal delay

        Returns:
            float: CPU usage percentage
        """
        try:
            def read_cpu_stats():
                with open(PROC_STAT_PATH) as f:
                    line = f.readline()
                parts = line.split()[1:8]
                return [int(x) for x in parts]

            cpu1 = read_cpu_stats()
            time.sleep(CPU_READ_DELAY)
            cpu2 = read_cpu_stats()

            delta = [cpu2[i] - cpu1[i] for i in range(len(cpu1))]
            total = sum(delta)
            idle = delta[3]

            if total == 0:
                return 0.0
            return round((1 - idle / total) * 100, 1)
        except Exception as e:
            print(f"[bot] Error getting CPU: {e}")
            return 0.0
```

### Bash пример

```bash
#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Common Utilities                      ║
# ║          github.com/cubiculus/cubiveil                    ║
# ╚═══════════════════════════════════════════════════════════╝

# ══════════════════════════════════════════════════════════════════════════════
# Constants / Константы
# ══════════════════════════════════════════════════════════════════════════════

# ── Порты / Ports ────────────────────────────────────────────
readonly PORT_MIN=30000
readonly PORT_MAX=62000

# ── Таймауты / Timeouts ──────────────────────────────────────
readonly IP_CHECK_TIMEOUT=4

# ── Генераторы случайных значений ────────────────────────────

# Генерация случайного порта из диапазона
# Generate random port from range
gen_port() {
  shuf -i ${PORT_MIN}-${PORT_MAX} -n 1
}

# Поиск уникального порта
# Find unique port
unique_port() {
  local p
  local max_attempts=${MAX_PORT_ATTEMPTS}
  local attempts=0

  while [[ $attempts -lt $max_attempts ]]; do
    p=$(gen_port)

    if ! validate_port "$p"; then
      ((attempts++))
      continue
    fi

    if [[ -z "${USED_PORTS_MAP[$p]:-}" ]]; then
      USED_PORTS_MAP[$p]=1
      echo "$p"
      return
    fi
    ((attempts++))
  done

  err "Failed to find free port after ${max_attempts} attempts"
}
```

---

## История изменений

- **2026-03-31**: Полная унификация CSS шаблонов decoy-site
  - ✅ Создан `_shared/base.css` — единый базовый файл стилей (~1268 строк)
  - ✅ Модифицирован `generators/colors.sh` — генерация CSS с динамическими цветами
  - ✅ Интегрировано в `generate.sh` — автоматическая генерация style.css
  - ✅ Удалены **все 12 файлов** `style.css` из шаблонов
  - ✅ HTML файлы ссылаются на `style.css` который генерируется при сборке
  - ✅ В шаблонах остались только уникальные файлы (`nginx.conf.tpl`)
  - **Результат:** ~2400 строк дублей → 1268 строк в одном файле + генерация
- **2026-03-31**: Полная унификация шаблонов decoy-site
  - ✅ Исправлено: Дублирование JS/HTML файлов в шаблонах decoy-site
  - ✅ Исправлено: Неиспользуемые функции `resetAttempts()` и `animateValue()` в JS-шаблонах
  - ✅ Исправлено: Избыточные `if/else` для `get_str` в `ui.sh`
- **2026-03-31**: Добавлен раздел о техническом долге
  - Документированы отложенные проблемы
  - Указаны причины откладки и планируемые решения
- **2026-03-25**: Первоначальная версия руководства по стилю
  - Унифицировано именование констант
  - Вынесены магические числа в константы
  - Добавлены требования к документации

---

## Технический долг

Ниже перечислены известные проблемы, которые были сознательно отложены для последующего исправления.

### Отложенные проблемы (0)

**Все проблемы исправлены!** ✅

~~#### 1. Дублирование JS/HTML файлов в шаблонах decoy-site~~

**Статус:** Исправлено 2026-03-31

**Было:** ~180 идентичных файлов в 12 шаблонах сайтов-прикрытий:
- `auth.js, 2fa.js, app.js, files.js` — по 12 копий
- `forgot-password.js, settings.js, stats.js, users.js` — по 12 копий
- `404.html, files.html, users.html, stats.html, settings.html, login.html, 2fa.html` — по 12 копий

**Решение:**
1. Создана папка `lib/modules/decoy-site/templates/_shared/` для общих файлов
2. Модифицирован `generate.sh` для копирования из `_shared/` при генерации шаблона
3. Удалены дубликаты из конкретных шаблонов (остались только уникальные файлы: `style.css`, `nginx.conf.tpl`)

**Результат:**
- **17 общих файлов** перемещены в `_shared/`
- **~170 файлов** удалены из шаблонов
- Уникальные файлы шаблонов сохранены (`style.css`, `nginx.conf.tpl`)

---

#### 2. Избыточные if/else в ui.sh (ИСПРАВЛЕНО ✅)

**Статус:** Исправлено 2026-03-31

**Было:** В файле `lib/core/installer/ui.sh` встречались конструкции вида:
```bash
if [[ "$LANG_NAME" == "Русский" ]]; then
  echo "  $(get_str MSG_...)"
else
  echo "  $(get_str MSG_...)"  # тот же вызов
fi
```

**Решение:** Все конструкции заменены на прямой вызов `get_str()`, который уже учитывает язык внутри себя.

---

### Примечания

- Отложенные проблемы не влияют на критическую функциональность
- Все проблемы задокументированы для последующего исправления
- Приоритеты могут быть пересмотрены при изменении требований
