#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — SSL Module                            ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль управления SSL сертификатами (Let's Encrypt)      ║
# ║  - Установка Certbot                                      ║
# ║  - Генерация сертификатов                                 ║
# ║  - Автоматическое обновление                              ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# Подключаем utils
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# Подключаем validation
if [[ -f "${SCRIPT_DIR}/lib/validation.sh" ]]; then
  source "${SCRIPT_DIR}/lib/validation.sh"
fi

# Подключаем security
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
  source "${SCRIPT_DIR}/lib/security.sh"
fi

# ── Глобальные переменные / Global Variables ────────────────

# Пути к SSL сертификатам
SSL_CERT_DIR="/etc/letsencrypt/live"
SSL_CERT_ARCHIVE="/etc/letsencrypt/archive"
SSL_CONFIG_DIR="/etc/letsencrypt"
SSL_ACCOUNT_DIR="${SSL_CONFIG_DIR}/accounts"

# Имя сервиса (для systemd таймера)
SSL_RENEW_SERVICE="certbot-renew"
SSL_RENEW_TIMER="certbot-renew.timer"

# ── Установка / Installation ────────────────────────────────

# Установка Certbot
ssl_install() {
  log_step "ssl_install" "Installing Certbot"

  # Проверяем, установлен ли Certbot
  if cmd_check "certbot"; then
    log_info "Certbot already installed"
    return 0
  fi

  # Устанавливаем зависимости
  pkg_install_packages "certbot" "openssl" "ca-certificates"

  log_success "Certbot installed successfully"
}

# ── Генерация сертификатов / Certificate Generation ─────────

# Генерация SSL сертификата
# Использование: ssl_generate "domain.com" "email@example.com"
ssl_generate() {
  local domain="$1"
  local email="${2:-}"

  # Валидация домена
  if ! validate_domain "$domain"; then
    log_error "Invalid domain: ${domain}"
    return 1
  fi

  # Валидация email если указан
  if [[ -n "$email" ]] && ! validate_email "$email"; then
    log_error "Invalid email: ${email}"
    return 1
  fi

  log_step "ssl_generate" "Generating SSL certificate for ${domain}"

  # Открываем порт 80 для валидации Let's Encrypt
  if [[ -f "${SCRIPT_DIR}/lib/modules/firewall/install.sh" ]]; then
    source "${SCRIPT_DIR}/lib/modules/firewall/install.sh"
    firewall_open_port 80 tcp "Let's Encrypt validation"
  fi

  # Параметры Certbot
  local certbot_opts=(
    certonly
    --non-interactive
    --agree-tos
    --webroot
    -w "/var/www/html"
  )

  # Добавляем email если указан
  if [[ -n "$email" ]]; then
    certbot_opts+=(--email "$email")
  else
    certbot_opts+=(--register-unsafely-without-email)
  fi

  # Добавляем домен
  certbot_opts+=(-d "$domain")

  # Генерируем сертификат
  if ! "${certbot_opts[@]}" >/dev/null 2>&1; then
    log_error "Failed to generate SSL certificate for ${domain}"

    # Закрываем порт 80
    if [[ -f "${SCRIPT_DIR}/lib/modules/firewall/install.sh" ]]; then
      source "${SCRIPT_DIR}/lib/modules/firewall/install.sh"
      firewall_close_port 80 tcp
    fi

    return 1
  fi

  # Закрываем порт 80 после успешной генерации
  if [[ -f "${SCRIPT_DIR}/lib/modules/firewall/install.sh" ]]; then
    source "${SCRIPT_DIR}/lib/modules/firewall/install.sh"
    firewall_close_port 80 tcp
  fi

  log_success "SSL certificate generated for ${domain}"
}

# ── Настройка / Configuration ───────────────────────────────

# Создание директории для webroot
ssl_configure_webroot() {
  log_step "ssl_configure_webroot" "Configuring webroot directory"

  local webroot_dir="/var/www/html"

  # Создаём директорию если нужно
  dir_ensure "$webroot_dir"

  # Создаём тестовую страницу
  cat > "${webroot_dir}/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Welcome to Nginx</title>
</head>
<body>
  <h1>Server is ready for SSL validation</h1>
</body>
</html>
EOF

  log_success "Webroot configured at ${webroot_dir}"
}

# Настройка автоматического обновления
ssl_configure_renewal() {
  log_step "ssl_configure_renewal" "Configuring automatic certificate renewal"

  # Проверяем, есть ли systemd timer
  if [[ -f "/etc/systemd/system/${SSL_RENEW_TIMER}" ]]; then
    log_info "Certbot renewal timer already configured"
    return 0
  fi

  # Certbot обычно автоматически создаёт systemd timer при установке
  # Просто проверяем, что он активен
  if systemctl list-unit-files | grep -q "certbot.timer"; then
    svc_enable "certbot.timer"
    svc_start "certbot.timer"

    log_success "Certbot renewal timer enabled"
  else
    log_warn "Certbot renewal timer not found, manual renewal required"
  fi
}

# Основная настройка
ssl_configure() {
  log_step "ssl_configure" "Configuring SSL module"

  # Настраиваем webroot
  ssl_configure_webroot

  # Настраиваем автоматическое обновление
  ssl_configure_renewal

  log_success "SSL module configured"
}

# ── Управление сертификатами / Certificate Management ────

# Проверка существования сертификата
# Возвращает 0 если сертификат существует, 1 если нет
ssl_cert_exists() {
  local domain="$1"
  [[ -d "${SSL_CERT_DIR}/${domain}" ]]
}

# Получение пути к сертификату
ssl_get_cert_path() {
  local domain="$1"
  echo "${SSL_CERT_DIR}/${domain}/fullchain.pem"
}

# Получение пути к ключу
ssl_get_key_path() {
  local domain="$1"
  echo "${SSL_CERT_DIR}/${domain}/privkey.pem"
}

# Проверка валидности сертификата
ssl_verify_cert() {
  local domain="$1"
  local cert_path
  cert_path=$(ssl_get_cert_path "$domain")

  if [[ ! -f "$cert_path" ]]; then
    log_error "Certificate not found: ${cert_path}"
    return 1
  fi

  # Проверяем срок действия сертификата
  local expiry
  expiry=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
  local expiry_date
  expiry_date=$(date -d "$expiry" +%s)
  local current_date
  current_date=$(date +%s)
  local days_left
  days_left=$(( (expiry_date - current_date) / 86400 ))

  log_info "Certificate for ${domain} expires in ${days_left} days"

  if [[ $days_left -lt 30 ]]; then
    log_warn "Certificate will expire soon (${days_left} days)"
    return 1
  fi

  return 0
}

# Обновление сертификата
ssl_renew() {
  local domain="${1:-}"

  log_step "ssl_renew" "Renewing SSL certificate"

  if [[ -n "$domain" ]]; then
    # Обновляем конкретный сертификат
    if certbot renew --cert-name "$domain" --noninteractive >/dev/null 2>&1; then
      log_success "Certificate renewed for ${domain}"
    else
      log_error "Failed to renew certificate for ${domain}"
      return 1
    fi
  else
    # Обновляем все сертификаты
    if certbot renew --noninteractive >/dev/null 2>&1; then
      log_success "All certificates renewed"
    else
      log_warn "Some certificates may have failed to renew"
    fi
  fi
}

# Удаление сертификата
ssl_remove() {
  local domain="$1"

  log_step "ssl_remove" "Removing SSL certificate for ${domain}"

  if ! ssl_cert_exists "$domain"; then
    log_error "Certificate not found for ${domain}"
    return 1
  fi

  certbot delete --cert-name "$domain" --noninteractive >/dev/null 2>&1

  log_success "Certificate removed for ${domain}"
}

# ── Включение / Enabling ───────────────────────────────────

# Включение SSL модуля
ssl_enable() {
  log_step "ssl_enable" "Enabling SSL module"

  # Проверяем наличие сертификатов
  local cert_count
  cert_count=$(find "${SSL_CERT_DIR}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)

  if [[ $cert_count -eq 0 ]]; then
    log_warn "No SSL certificates found"
    return 0
  fi

  log_info "Found ${cert_count} SSL certificate(s)"

  # Перезагружаем сервисы которые используют SSL
  svc_restart_if_active "marzban"
  svc_restart_if_active "nginx"

  log_success "SSL module enabled"
}

# Отключение SSL модуля
ssl_disable() {
  log_step "ssl_disable" "Disabling SSL module"

  # Ничего особенного не делаем, просто логируем
  log_info "SSL module disabled (certificates remain installed)"
}

# ── Статус и проверка / Status & Verification ─────────────

# Получение списка сертификатов
ssl_list() {
  log_step "ssl_list" "Listing SSL certificates"

  if [[ ! -d "${SSL_CERT_DIR}" ]]; then
    log_info "No SSL certificates directory found"
    return 0
  fi

  echo ""
  echo "SSL Certificates:"
  echo "────────────────"

  for cert_dir in "${SSL_CERT_DIR}"/*; do
    if [[ -d "$cert_dir" ]]; then
      local domain
      domain=$(basename "$cert_dir")

      echo ""
      echo "  Domain: ${domain}"

      if ssl_verify_cert "$domain" >/dev/null 2>&1; then
        local expiry
        expiry=$(openssl x509 -enddate -noout -in "${cert_dir}/fullchain.pem" | cut -d= -f2)
        echo "    Status: Valid"
        echo "    Expires: ${expiry}"
      else
        echo "    Status: Invalid or expired"
      fi
    fi
  done

  echo ""
  echo "────────────────"
  echo ""
}

# Проверка активности SSL
ssl_is_active() {
  [[ -d "${SSL_CERT_DIR}" ]] && [[ "$(ls -A "${SSL_CERT_DIR}")" ]]
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { ssl_install; }
module_configure() { ssl_configure; }
module_enable() { ssl_enable; }
module_disable() { ssl_disable; }

# Обновление модуля
module_update() {
  log_step "module_update" "Updating SSL module"
  ssl_renew
}

# Удаление модуля
module_remove() {
  log_step "module_remove" "Removing SSL module"

  # Останавливаем таймер обновления
  svc_stop "certbot.timer" 2>/dev/null || true
  svc_disable "certbot.timer" 2>/dev/null || true

  log_success "SSL module removed (certificates remain installed)"
}
