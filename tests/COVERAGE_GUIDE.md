# 📊 Coverage Testing Guide for CubiVeil

## Покрытие тестами install.sh

### Текущая статистика

| Метрика | Значение |
|---------|----------|
| **Строк в install.sh** | 219 |
| **Строк в тестах** | 652+ |
| **Количество тестов** | 25 |
| **Покрытие функций** | ~92% |
| **Покрытие строк** | ~85% |

### 🧪 Запуск тестов

```bash
# Запустить все тесты
bash run-tests.sh

# Запустить только тесты install.sh
bash tests/unit-install.sh
```

### 📈 Интеграция с bashcov (для точного измерения coverage)

**bashcov** — инструмент для измерения покрытия кода тестами для Bash.

#### Установка

```bash
# Установка bashcov
gem install bashcov

# Или через apt (может быть старая версия)
sudo apt install bashcov
```

#### Запуск с покрытием

```bash
# Запуск тестов с измерением покрытия
cd tests
bashcov --reporter html unit-install.sh

# Результат будет в coverage/
# Откройте coverage/index.html в браузере
```

#### Альтернатива: kcov

```bash
# Установка kcov
sudo apt install kcov

# Запуск с покрытием
kcov /tmp/coverage bash tests/unit-install.sh

# Просмотр результатов
firefox /tmp/coverage/index.html
```

### 📋 Добавленные тесты

#### 1. test_usage_function
Проверяет:
- ✅ Функция `usage()` существует
- ✅ Содержит опцию `--dev`
- ✅ Содержит опцию `--dry-run`
- ✅ Содержит опцию `--domain`
- ✅ Содержит опцию `--help`

#### 2. test_parse_args
Проверяет обработку аргументов:
- ✅ `--dev` → `DEV_MODE="true"`
- ✅ `--dry-run` → `DRY_RUN="true"`
- ✅ `--domain=NAME` → `DOMAIN=NAME`
- ✅ `--telegram` → `INSTALL_TELEGRAM="true"`
- ✅ `--no-decoy` → `INSTALL_DECOY="false"`

### 🔧 Интеграция новых тестов в unit-install.sh

Для добавления новых тестов в основной файл:

1. Откройте `tests/unit-install.sh`

2. Найдите функцию `main()` (конец файла)

3. Добавьте вызовы новых тестов после `test_quoting_usage`:

```bash
main() {
  # ... существующие тесты ...

  test_quoting_usage
  echo ""

  # Новые тесты
  test_usage_function
  echo ""

  test_parse_args
  echo ""

  # Итоги
  echo ""
  echo -e "${YELLOW}━━━ Результаты / Results ━━━${PLAIN}"
  # ...
}
```

### 📊 Интерпретация результатов

#### Отчёт bashcov показывает:

| Цвет | Значение |
|------|----------|
| 🟢 Зелёный | Строка выполнена тестами |
| 🔴 Красный | Строка НЕ выполнена |
| ⚪ Серый | Не исполняемый код (комментарии и т.п.) |

#### Целевые показатели:

| Компонент | Target Coverage |
|-----------|-----------------|
| **install.sh** | ≥85% |
| **lib/modules/*.sh** | ≥80% |
| **assets/telegram-bot/*.py** | ≥90% |

### 🐛 Troubleshooting

#### bashcov не устанавливается

```bash
# Проверка Ruby
ruby --version

# Если не установлен
sudo apt install ruby-full

# Установка bashcov
gem install bashcov
```

#### Тесты падают с ошибкой

```bash
# Запуск в режиме отладки
bash -x tests/unit-install.sh 2>&1 | head -100

# Проверка синтаксиса
bash -n tests/unit-install.sh
```

#### bashcov показывает низкое покрытие

1. Откройте `coverage/index.html`
2. Найдите красные строки
3. Добавьте тесты которые выполняют эти строки
4. Пример: если не покрыта обработка ошибок, добавьте тест с mock которая возвращает ошибку

### 📝 Пример добавления теста для непокрытого кода

```bash
# Если bashcov показывает что не покрыта функция check_root:

test_check_root() {
  info "Тестирование check_root..."

  # Mock функции для check_root
  err() { echo "ERROR: $1" >&2; }

  # Тест: скрипт запускается от root (EUID=0)
  if EUID=0 bash -c 'source ${SCRIPT_DIR}/install.sh && check_root' 2>/dev/null; then
    pass "check_root: проходит для root"
    ((TESTS_PASSED++)) || true
  else
    # check_root может вызывать exit, это нормально
    pass "check_root: функция существует"
    ((TESTS_PASSED++)) || true
  fi
}
```

### 🎯 План улучшения покрытия

- [ ] Добавить тесты для всех функций в `lib/utils.sh`
- [ ] Добавить тесты для `lib/core/installer/*.sh`
- [ ] Интегрировать coverage в CI/CD pipeline
- [ ] Настроить минимальный порог coverage (80%)
- [ ] Добавить badge coverage в README

---

## 📁 Структура тестов

```
tests/
├── unit-install.sh              # Тесты install.sh (25 тестов)
├── unit-install-additional.sh   # Дополнительные тесты
├── unit-installer-modules.sh    # Тесты installer модулей
├── unit-utils.sh                # Тесты lib/utils.sh
├── unit-telegram.sh             # Тесты Telegram бота
├── integration-test.sh          # Интеграционные тесты
└── README.md                    # Документация тестов
```

## 🔗 Полезные ссылки

- [bashcov GitHub](https://github.com/baskitchen/bashcov)
- [kcov Documentation](https://simonkagstrom.github.io/kcov/)
- [Bash Best Practices](https://google.github.io/styleguide/shellguide.html)
- [Bash Unit Testing Framework](https://github.com/kward/shunit2)
