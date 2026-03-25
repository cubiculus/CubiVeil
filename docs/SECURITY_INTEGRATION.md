# 🔐 Подключение security.sh к модулям

## Обзор

Файл `lib/security.sh` содержит функции безопасности, которые уже используются в некоторых модулях. Это документация описывает текущее состояние и рекомендации по подключению.

## Текущее состояние

### Функции в security.sh

1. **secure_download()** — безопасная загрузка с проверкой GPG
2. **encrypt_to_file()** — шифрование через age
3. **verify_ssl_cert()** — проверка SSL сертификата
4. **verify_sha256()** — проверка целостности файла по SHA256
5. **generate_secure_key()** — генерация безопасного случайного ключа

### Модули, которые уже используют security.sh

#### ✅ singbox (lib/steps/install_singbox.sh)
```bash
# Подключает security.sh в начале файла
source "${SCRIPT_DIR}/lib/security.sh"

# Использует verify_sha256() для проверки скачанного Sing-box
if ! verify_sha256 /tmp/sing-box.tar.gz "$SB_SHA256"; then
  err "SHA256 проверка не пройдена"
fi
```

#### ✅ ssl (lib/steps/ssl.sh)
```bash
# Подключает security.sh в начале файла
source "${SCRIPT_DIR}/lib/security.sh"

# Может использовать verify_ssl_cert() для проверки сертификатов
# (текущая реализация использует acme.sh напрямую)
```

#### ✅ monitoring (lib/modules/monitoring/install.sh)
```bash
# Подключает security.sh в начале файла
source "${SCRIPT_DIR}/lib/security.sh"

# Может использовать verify_ssl_cert() для health check
```

### Модули, которые НЕ используют security.sh

#### ❌ singbox (lib/modules/singbox/install.sh)
```bash
# Подключает security.sh, но НЕ использует функции напрямую
# Вместо этого использует встроенную проверку
```

#### ❌ marzban (lib/modules/marzban/install.sh)
```bash
# НЕ подключает security.sh
# Использует только core модули
```

#### ❌ backup (lib/modules/backup/install.sh)
```bash
# Подключает security.sh, но НЕ использует функции напрямую
```

#### ❌ rollback (lib/modules/rollback/install.sh)
```bash
# Подключает security.sh, но НЕ использует функции напрямую
```

## Рекомендации по подключению

### 1. Sing-box модуль (lib/modules/singbox/install.sh)

**Текущее состояние:** Подключает security.sh, но не использует все функции

**Рекомендации:**
- ✅ Уже использует `verify_sha256()` — оставить как есть
- ✅ Добавить `verify_ssl_cert()` для health check
- ❌ Убрать дублирование GPG проверки (есть в step файле)

**Изменения:**
```bash
# Добавить функцию health check
singbox_health_check() {
  log_step "singbox_health_check" "Checking Sing-box health"

  # Проверка SSL сертификатов если используются
  if [[ -f "${SINGBOX_CONFIG_DIR}/tls.json" ]]; then
    # Извлекаем домен из конфига и проверяем SSL
    local domain
    domain=$(jq -r '.tls.server_name' "${SINGBOX_CONFIG_DIR}/tls.json")

    if [[ -n "$domain" ]]; then
      verify_ssl_cert "$domain" 443 5
      if [[ $? -eq 0 ]]; then
        log_success "SSL certificate valid for $domain"
      else
        log_warn "SSL certificate check failed for $domain"
      fi
    fi
  fi
}
```

### 2. Marzban модуль (lib/modules/marzban/install.sh)

**Текущее состояние:** НЕ подключает security.sh

**Рекомендации:**
- ❌ Добавить подключение security.sh в начало файла
- ✅ Добавить `verify_sha256()` при скачивании скрипта установки
- ✅ Добавить `verify_ssl_cert()` для health check панели

**Изменения:**
```bash
# В начало файла (после подключения core модулей):
# Подключаем security
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
  source "${SCRIPT_DIR}/lib/security.sh"
fi

# В функции marzban_download_script():
# После скачивания скрипта добавить проверку SHA256
if [[ -n "$EXPECTED_SHA256" ]]; then
  if ! verify_sha256 "$MARZBAN_SCRIPT" "$EXPECTED_SHA256"; then
    rm -f "$MARZBAN_SCRIPT"
    err "SHA256 проверка не пройдена для скрипта Marzban"
  fi
fi
```

### 3. Backup модуль (lib/modules/backup/install.sh)

**Текущее состояние:** Подключает security.sh, но не использует функции

**Рекомендации:**
- ✅ Добавить `encrypt_to_file()` для шифрования бэкапов
- ✅ Добавить `generate_secure_key()` для генерации ключей шифрования

**Изменения:**
```bash
# В функции backup_create_archive():
# Добавить шифрование архива
backup_encrypt_archive() {
  local archive="$1"

  log_step "backup_encrypt_archive" "Encrypting backup archive"

  # Генерируем ключ шифрования
  local key
  key=$(generate_secure_key 32)

  # Сохраняем ключ
  echo "$key" > "${BACKUP_DIR}/backup-key.txt"
  chmod 600 "${BACKUP_DIR}/backup-key.txt"

  # Шифруем архив
  local encrypted_file="${archive}.age"
  encrypt_to_file "$(cat "$archive")" "$key" "$encrypted_file"

  # Удаляем оригинальный архив
  rm -f "$archive"

  log_success "Backup encrypted: $encrypted_file"
  log_info "Encryption key: ${BACKUP_DIR}/backup-key.txt"
}
```

### 4. Rollback модуль (lib/modules/rollback/install.sh)

**Текущее состояние:** Подключает security.sh, но не использует функции

**Рекомендации:**
- ✅ Добавить проверку `verify_sha256()` для архивов бэкапов
- ✅ Добавить `decrypt_to_file()` если будет поддерживаться decryption

**Изменения:**
```bash
# В функции rollback_extract_archive():
# После распаковки добавить проверку целостности
rollback_verify_integrity() {
  local extracted_dir="$1"

  log_step "rollback_verify_integrity" "Verifying backup integrity"

  # Проверяем SHA256 базы данных
  if [[ -f "${extracted_dir}/marzban-db.sqlite3.sha256" ]]; then
    local expected_hash
    expected_hash=$(cat "${extracted_dir}/marzban-db.sqlite3.sha256")

    if verify_sha256 "${extracted_dir}/marzban-db.sqlite3" "$expected_hash"; then
      log_success "Database integrity verified"
    else
      log_warn "Database integrity check failed"
    fi
  fi
}
```

### 5. Monitoring модуль (lib/modules/monitoring/install.sh)

**Текущее состояние:** Подключает security.sh, но не использует функции

**Рекомендации:**
- ✅ Добавить `verify_ssl_cert()` для health check HTTPS
- ✅ Использовать `secure_download()` для проверки соединения

**Изменения:**
```bash
# В функции monitor_network_check():
# Добавить проверку SSL сертификата
monitor_check_ssl() {
  log_step "monitor_check_ssl" "Checking SSL certificates"

  local domains=("$(monitor_external_ip)" "google.com")

  for domain in "${domains[@]}"; do
    if verify_ssl_cert "$domain" 443 5; then
      log_success "SSL certificate valid: $domain"
    else
      log_warn "SSL certificate check failed: $domain"
    fi
  done
}
```

## План действий (Priority)

### Высокий приоритет (Critical)
1. ✅ Sing-box: уже использует verify_sha256() — оставить как есть
2. ⚠️  Sing-box: добавить verify_ssl_cert() для health check
3. ⚠️  Marzban: добавить подключение security.sh и verify_sha256()
4. ⚠️  Backup: добавить encrypt_to_file() для шифрования архивов

### Средний приоритет (Important)
5. ⚠️  Rollback: добавить проверку целостности бэкапов
6. ⚠️  Monitoring: добавить verify_ssl_cert() для health check

### Низкий приоритет (Nice to have)
7. 📌  Все модули: документация по использованию security.sh
8. 📌  Интеграция: добавить unified error handling для security ошибок

## Пример полного подключения

### Шаблон для нового модуля

```bash
#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Module Name                        ║
# ╚═══════════════════════════════════════════════════════════╝

# Подключение зависимостей
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# Security модуль (ВЫСОКИЙ ПРИОРИТЕТ)
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
  source "${SCRIPT_DIR}/lib/security.sh"
fi

# ── Использование security.sh ────────────────────────────

# Пример: проверка скачанного файла
module_download_and_verify() {
  local url="$1"
  local dest="$2"
  local expected_sha256="$3"

  log_step "module_download_and_verify" "Downloading and verifying: $dest"

  # Загружаем
  curl -fLo "$dest" "$url" || return 1

  # Проверяем SHA256 если предоставлен
  if [[ -n "$expected_sha256" ]]; then
    if ! verify_sha256 "$dest" "$expected_sha256"; then
      rm -f "$dest"
      return 1
    fi
  fi

  log_success "Download verified: $dest"
}

# Пример: проверка SSL сертификата
module_check_ssl() {
  local host="$1"

  log_step "module_check_ssl" "Checking SSL for: $host"

  if verify_ssl_cert "$host" 443 5; then
    log_success "SSL certificate valid: $host"
    return 0
  else
    log_warn "SSL certificate check failed: $host"
    return 1
  fi
}
```

## Заключение

**Текущий статус:** security.sh частично интегрирован

**Следующие шаги:**
1. ✅ Создать эту документацию (выполнено)
2. ⚠️  Добавить функции в Sing-box модуль (health check)
3. ⚠️  Подключить security.sh в Marzban модуль
4. ⚠️  Добавить шифрование в Backup модуль
5. ⚠️  Добавить проверки целостности в Rollback модуль
6. ⚠️  Добавить SSL проверки в Monitoring модуль

Все изменения можно выполнять параллельно, так как модули независимы.
