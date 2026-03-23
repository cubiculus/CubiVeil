# CubiVeil Tests

Интеграционные тесты для проверки корректности установки CubiVeil.

---

## Быстрый старт

```bash
# Запуск тестов (требуются права root)
sudo ./run-tests.sh

# Или напрямую
sudo bash tests/integration-tests.sh
```

---

## Что проверяют тесты

### Базовые проверки
- ✅ Uptime сервера
- ✅ Свободное место на диске
- ✅ Использование RAM

### Сервисы
- ✅ Marzban активен
- ✅ Sing-box активен
- ✅ Health-check сервис активен
- ✅ Telegram бот активен
- ✅ Токен бота в переменной окружения (не в файле)

### Сеть
- ✅ Порт 443/tcp открыт (VLESS Reality)
- ✅ Порт 443/udp открыт (Hysteria2)
- ✅ Health-check endpoint отвечает
- ✅ `/health` возвращает 200
- ✅ `/ready` возвращает 200

### Безопасность
- ✅ UFW активен
- ✅ Fail2ban активен
- ✅ Credentials зашифрованы (age)
- ✅ Ключ age существует
- ✅ Незашифрованный файл удалён

### SSL
- ✅ Сертификат валиден
- ✅ Сертификат не истёк

### Конфигурация
- ✅ Marzban .env содержит все переменные
- ✅ Sing-box шаблон — валидный JSON
- ✅ Sing-box шаблон содержит 5 профилей

### Логирование
- ✅ Journald конфиг создан
- ✅ Logrotate конфиг создан

---

## Интерпретация результатов

### Все тесты пройдены ✅
```
╔══════════════════════════════════════════════════════╗
║        CubiVeil Installation Tests                   ║
╚══════════════════════════════════════════════════════╝

━━━ Базовые проверки ━━━
[PASS] Сервер работает: 15 мин
[PASS] Диск: свободно 18ГБ
[PASS] RAM: использовано 35%

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Пройдено: 28
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Все тесты пройдены
```

**Что делать:** Ничего, всё работает!

---

### Некоторые тесты провалены ❌
```
━━━ Сервисы ━━━
[PASS] Marzban активен
[FAIL] Sing-box: inactive (ожидался: active)
[PASS] Health-check сервис активен

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Пройдено: 25
Провалено:  3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ Тесты провалены
```

**Что делать:**

1. Посмотреть логи упавшего сервиса:
   ```bash
   journalctl -u sing-box -n 50
   ```

2. Проверить статус:
   ```bash
   systemctl status sing-box
   ```

3. Попробовать перезапустить:
   ```bash
   systemctl restart sing-box
   ```

4. Перезапустить тесты:
   ```bash
   sudo ./run-tests.sh
   ```

---

## Предупреждения ⚠️

### `warn` — не критично
```
[WARN] Fail2ban не активен
[WARN] Ротация логов: logrotate конфиг не найден
```

**Что делать:** Можно игнорировать если функционал не нужен.

---

## Интеграция с CI/CD

### GitHub Actions
```yaml
- name: Run CubiVeil Tests
  run: sudo ./run-tests.sh
```

### GitLab CI
```yaml
test:
  script:
    - sudo ./run-tests.sh
```

### Jenkins
```groovy
sh 'sudo ./run-tests.sh'
```

---

## Добавление новых тестов

1. Открой `tests/integration-tests.sh`

2. Добавь функцию проверки:
   ```bash
   check_my_feature() {
       if [[ condition ]]; then
           pass "Описание проверки"
           ((TESTS_PASSED++))
       else
           fail "Описание ошибки"
           ((TESTS_FAILED++))
       fi
   }
   ```

3. Вызови в `main()`:
   ```bash
   echo -e "${YELLOW}━━━ Моя проверка ━━━${PLAIN}"
   check_my_feature
   ```

---

## Утилиты для тестов

| Функция | Описание | Пример |
|---------|----------|--------|
| `check_service_active` | Проверка systemd сервиса | `check_service_active "marzban"` |
| `check_port_open` | Проверка открытого порта | `check_port_open 443 tcp "HTTPS"` |
| `check_file_exists` | Проверка существования файла | `check_file_exists "/path/to/file"` |
| `check_file_encrypted` | Проверка шифрования age | `check_file_encrypted "/root/secrets.age"` |
| `check_health_endpoint` | Проверка HTTP endpoint | `check_health_endpoint "localhost" 8080 "/health"` |
| `check_ssl_cert` | Проверка SSL сертификата | `check_ssl_cert "/path/to/cert.pem"` |
| `pass` | Отметить тест как пройденный | `pass "Всё хорошо"` |
| `fail` | Отметить тест как проваленный | `fail "Что-то не так"` |
| `warn` | Предупреждение (не критично) | `warn "Опционально"` |

---

## Отчёт о тестах

После запуска тесты выводят:
- Количество пройденных тестов
- Количество проваленных тестов
- Детальный лог каждой проверки

**Exit code:**
- `0` — все тесты пройдены
- `1` — есть проваленные тесты

---

## Частые проблемы

### `command not found: ss`
```bash
apt-get install -y iproute2
```

### `command not found: jq`
```bash
apt-get install -y jq
```

### `systemctl is-active` возвращает `inactive`
```bash
# Посмотреть логи
journalctl -u <сервис> -n 50

# Перезапустить
systemctl restart <сервис>
```

### Health-check не отвечает
```bash
# Найти порт
grep HEALTH_CHECK_PORT /opt/marzban/.env

# Проверить вручную
curl http://localhost:<PORT>/health
```

---

## Лицензия

MIT — как и основной проект.
