#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Security Module                      ║
# ║          Модуль безопасности                               ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение fallback функций ─────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/fallback.sh" ]]; then
  source "${SCRIPT_DIR}/fallback.sh"
fi

# ── Безопасная загрузка с проверкой GPG ──────────────────────
# Параметры:
#   $1 - URL для загрузки
#   $2 - Путь назначения
#   $3 - URL подписи (опционально)
# Возвращает 0 если успешно, 1 если ошибка
secure_download() {
  local url="$1"
  local dest="$2"
  local sig_url="${3:-}"
  
  # Загрузка файла
  if ! curl -fLo "$dest" "$url" 2>/dev/null; then
    warn "Failed to download from $url"
    return 1
  fi
  
  # Загрузка и проверка GPG подписи если указан URL
  if [[ -n "$sig_url" ]]; then
    local sig_dest="${dest}.sig"
    if ! curl -fLo "$sig_dest" "$sig_url" 2>/dev/null; then
      warn "Failed to download signature from $sig_url"
      return 1
    fi
    
    if ! gpg --verify "$sig_dest" "$dest" 2>/dev/null; then
      warn "GPG signature verification failed"
      return 1
    fi
  fi
  
  return 0
}

# ── Безопасное шифрование через pipe ─────────────────────────
# Параметры:
#   $1 - Данные для шифрования
#   $2 - Публичный ключ
#   $3 - Путь назначения
# Возвращает 0 если успешно, 1 если ошибка
encrypt_to_file() {
  local data="$1"
  local public_key="$2"
  local dest_file="$3"
  
  # Проверка наличия age
  if ! command -v age &>/dev/null; then
    warn "age encryption tool not found"
    return 1
  fi
  
  # Шифрование через pipe без временного файла
  if ! echo "$data" | age -r "$public_key" -o "$dest_file" 2>/dev/null; then
    warn "Failed to encrypt data"
    return 1
  fi
  
  return 0
}

# ── Проверка SSL сертификата ─────────────────────────────────
# Параметры:
#   $1 - Хост
#   $2 - Порт (по умолчанию 443)
#   $3 - Таймаут в секундах (по умолчанию 5)
# Возвращает 0 если сертификат валиден, 1 если ошибка
verify_ssl_cert() {
  local host="$1"
  local port="${2:-443}"
  local timeout="${3:-5}"
  
  # Проверка наличия openssl
  if ! command -v openssl &>/dev/null; then
    warn "openssl not found"
    return 1
  fi
  
  # Проверка SSL сертификата с верификацией
  if ! openssl s_client -connect "$host:$port" \
    -servername "$host" \
    -verify_return_error \
    -timeout "$timeout" </dev/null 2>/dev/null; then
    return 1
  fi
  
  return 0
}

# ── Проверка целостности файла по SHA256 ─────────────────────
# Параметры:
#   $1 - Путь к файлу
#   $2 - Ожидаемый хеш
# Возвращает 0 если хеш совпадает, 1 если не совпадает
verify_sha256() {
  local file="$1"
  local expected_hash="$2"
  
  if [[ ! -f "$file" ]]; then
    warn "File not found: $file"
    return 1
  fi
  
  local actual_hash
  actual_hash=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')
  
  if [[ "$actual_hash" != "$expected_hash" ]]; then
    warn "SHA256 hash mismatch for $file"
    warn "Expected: $expected_hash"
    warn "Got:      $actual_hash"
    return 1
  fi
  
  return 0
}

# ── Генерация безопасного случайного ключа ───────────────────
# Параметры:
#   $1 - Длина ключа в байтах (по умолчанию 32)
# Выводит base64 закодированный ключ
generate_secure_key() {
  local length="${1:-32}"
  
  if [[ ! -r /dev/urandom ]]; then
    warn "/dev/urandom not accessible"
    return 1
  fi
  
  head -c "$length" /dev/urandom | base64 | tr -d '\n'
}
