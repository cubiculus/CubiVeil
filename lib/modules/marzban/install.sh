#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Marzban Module                        ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль установки и настройки Marzban                     ║
# ║  - Установка Marzban через официальный скрипт             ║
# ║  - Настройка .env файла                                   ║
# ║  - Управление сервисом                                    ║
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

# ── Конфигурация / Configuration ────────────────────────────

MARZBAN_INSTALL_DIR="/opt/marzban"
MARZBAN_CONFIG_DIR="/var/lib/marzban"
MARZBAN_ENV_FILE="${MARZBAN_CONFIG_DIR}/.env"
MARZBAN_SERVICE="marzban"
MARZBAN_INSTALL_SCRIPT="/tmp/marzban-install.sh"

# ── Установка / Installation ────────────────────────────────

# Проверка наличия Marzban
marzban_is_installed() {
  pkg_check "marzban" || [[ -f "${MARZBAN_INSTALL_DIR}/marzban" ]]
}

# Установка Marzban
marzban_install() {
  log_step "marzban_install" "Installing Marzban"

  # Проверяем, установлен ли уже Marzban
  if marzban_is_installed; then
    log_info "Marzban already installed"
    return 0
  fi

  # Создаём директорию для установки
  mkdir -p "$MARZBAN_INSTALL_DIR"

  # Загружаем официальный скрипт установки
  log_info "Downloading Marzban installation script..."

  if ! curl -sfL --connect-timeout 10 --max-time 60 "https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh" -o "$MARZBAN_INSTALL_SCRIPT" 2>/dev/null; then
    log_error "Failed to download Marzban installation script"
    log_warn "Continuing without Marzban — you can install manually later:"
    log_warn "  curl -sfL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh | bash -s install --yes"
    return 0 # Не ошибка — продолжаем установку
  fi

  chmod +x "$MARZBAN_INSTALL_SCRIPT"

  # Запускаем установку в автоматическом режиме
  log_info "Running Marzban installation..."

  # Сначала устанавливаем необходимые зависимости
  log_info "Installing Marzban dependencies..."
  pkg_install_packages "python3" "python3-pip" "python3-venv" "git" "curl" "wget" "unzip" "docker.io" "docker-compose" || {
    log_warn "Failed to install some dependencies, continuing anyway..."
  }

  # Проверяем и запускаем Docker
  log_info "Checking Docker service..."
  if systemctl is-active --quiet docker; then
    log_info "Docker is already running"
  else
    log_info "Starting Docker service..."
    systemctl enable docker >/dev/null 2>&1
    systemctl start docker || {
      log_error "Failed to start Docker service"
      log_warn "Marzban requires Docker. Please start Docker manually:"
      log_warn "  sudo systemctl enable docker && sudo systemctl start docker"
      return 1
    }
  fi

  # Проверяем что Docker работает
  if ! docker info >/dev/null 2>&1; then
    log_error "Docker is not working properly"
    log_warn "Please check Docker installation and try again"
    return 1
  fi

  # Добавляем текущего пользователя в группу docker если нужно
  if ! groups | grep -q docker; then
    log_info "Adding user to docker group..."
    usermod -aG docker "$USER" || {
      log_warn "Failed to add user to docker group"
      log_warn "You may need to run Docker commands with sudo"
    }
  fi

  # Проверяем наличие предыдущей установки и удаляем если есть
  if docker ps -a --format '{{.Names}}' | grep -q "^marzban$"; then
    log_info "Removing existing Marzban container..."
    docker stop marzban >/dev/null 2>&1 || true
    docker rm marzban >/dev/null 2>&1 || true
  fi

  # Удаляем существующий volume если есть
  if docker volume ls --format '{{.Name}}' | grep -q "^marzban$"; then
    log_info "Removing existing Marzban volume..."
    docker volume rm marzban >/dev/null 2>&1 || true
  fi

  # Удаляем существующую директорию установки (/opt/marzban)
  if [[ -d /opt/marzban ]]; then
    log_info "Removing existing Marzban directory /opt/marzban..."
    rm -rf /opt/marzban
  fi

  # Запускаем установку с автоматическим подтверждением
  # Marzban installer не поддерживает --yes, поэтому используем pipe с 'y'
  export MARZBAN_TELEGRAM_ENABLED=0
  export MARZBAN_USERS_ENABLED=0

  # Перенаправляем вывод установщика в файл — не наследовать pipe родителя
  local _marzban_log="/var/log/cubiveil/marzban-install.log"
  mkdir -p "$(dirname "$_marzban_log")"
  log_info "Marzban install log: $_marzban_log"

  echo "y" | bash "$MARZBAN_INSTALL_SCRIPT" install \
    >"$_marzban_log" 2>&1 &
  local _marzban_bg_pid=$!

  # Ждём "Application startup complete" до 120 секунд
  local _max_wait=120
  local _started=false
  local _container
  local _start_time
  _start_time=$(date +%s)

  while true; do
    local _now
    _now=$(date +%s)
    local _elapsed=$((_now - _start_time))

    if [[ $_elapsed -ge $_max_wait ]]; then
      break
    fi

    # Контейнер может называться marzban или marzban_marzban_1 (docker-compose v1)
    _container=$(docker ps -a --format '{{.Names}}' | grep -E '^marzban(_marzban_1)?$' | head -1)
    if [[ -n "$_container" ]] && docker logs "$_container" 2>/dev/null | grep -q "Application startup complete"; then
      _started=true
      break
    fi

    echo -ne "\rWaiting for Marzban... ${_elapsed}s"
    sleep 1
  done
  echo -ne "\r"

  # Убиваем foreground docker compose up (контейнер продолжает работать)
  kill "$_marzban_bg_pid" 2>/dev/null || true
  wait "$_marzban_bg_pid" 2>/dev/null || true

  if [[ "$_started" != "true" ]]; then
    log_error "Marzban did not start within ${_max_wait}s"
    log_warn "Check: docker logs marzban"
    log_warn "Full install log: $_marzban_log"
    rm -f "$MARZBAN_INSTALL_SCRIPT"
    return 1
  fi

  # Очищаем временный файл
  rm -f "$MARZBAN_INSTALL_SCRIPT"

  log_success "Marzban installed successfully"
}

# ── Настройка / Configuration ───────────────────────────────

# Настройка .env файла
marzban_configure_env() {
  log_step "marzban_configure_env" "Configuring Marzban .env"

  # Читаем порты из /etc/cubiveil/ports.json если файл существует
  local ports_file="/etc/cubiveil/ports.json"
  if [[ -f "$ports_file" ]]; then
    PANEL_PORT=$(jq -r '.panel' "$ports_file" 2>/dev/null || echo "8080")
    SUB_PORT=$(jq -r '.subscription' "$ports_file" 2>/dev/null || echo "8081")
    TROJAN_PORT=$(jq -r '.trojan' "$ports_file" 2>/dev/null || echo "8443")
    SS_PORT=$(jq -r '.shadowsocks' "$ports_file" 2>/dev/null || echo "8082")
    log_info "Loaded ports from $ports_file"
  fi

  # Читаем домен из переменных окружения или из /etc/cubiveil/domain.json
  local domain="${DOMAIN:-}"
  local domain_file="/etc/cubiveil/domain.json"
  if [[ -z "$domain" && -f "$domain_file" ]]; then
    domain=$(jq -r '.domain' "$domain_file" 2>/dev/null || echo "")
  fi
  [[ -z "$domain" ]] && domain="0.0.0.0"

  # Генерируем учётные данные админа если не заданы
  local sudo_username="${SUDO_USERNAME:-admin}"
  local sudo_password="${SUDO_PASSWORD:-}"
  if [[ -z "$sudo_password" ]]; then
    # Генерируем случайный пароль
    sudo_password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)
    export SUDO_USERNAME="$sudo_username"
    export SUDO_PASSWORD="$sudo_password"
  fi

  # Проверяем наличие .env файла
  if [[ ! -f "$MARZBAN_ENV_FILE" ]]; then
    log_warn ".env file not found, creating..."
    mkdir -p "$MARZBAN_CONFIG_DIR"
    # Создаём новый .env файл с базовыми настройками
    cat >"$MARZBAN_ENV_FILE" <<EOF
# Marzban Configuration
MARZBAN_HOST=${domain}
MARZBAN_PORT=${PANEL_PORT}
MARZBAN_API_PORT=${PANEL_PORT}
SINGBOX_PORT=${PANEL_PORT}
TROJAN_PORT=${TROJAN_PORT}
SS_PORT=${SS_PORT}
SUBSCRIPTION_PORT=${SUB_PORT}
SUDO_USERNAME=${sudo_username}
SUDO_PASSWORD=${sudo_password}
EOF
    log_success "Marzban .env created with domain=$domain, panel=$PANEL_PORT, sub=$SUB_PORT"
  else
    # Файл существует — обновляем переменные
    local temp_env
    temp_env=$(mktemp)

    # Копируем существующий файл
    cp "$MARZBAN_ENV_FILE" "$temp_env"

    # Функция для обновления или добавления переменной
    _update_var() {
      local var="$1"
      local value="$2"
      if grep -q "^${var}=" "$temp_env" 2>/dev/null; then
        sed -i "s|^${var}=.*|${var}=${value}|" "$temp_env"
      else
        echo "${var}=${value}" >>"$temp_env"
      fi
    }

    # Обновляем переменные
    _update_var "MARZBAN_HOST" "$domain"
    _update_var "MARZBAN_PORT" "$PANEL_PORT"
    _update_var "MARZBAN_API_PORT" "$PANEL_PORT"
    _update_var "SINGBOX_PORT" "$PANEL_PORT"
    _update_var "TROJAN_PORT" "$TROJAN_PORT"
    _update_var "SS_PORT" "$SS_PORT"
    _update_var "SUBSCRIPTION_PORT" "$SUB_PORT"
    _update_var "SUDO_USERNAME" "$sudo_username"
    _update_var "SUDO_PASSWORD" "$sudo_password"

    # Копируем обратно
    cat "$temp_env" >"$MARZBAN_ENV_FILE"
    rm -f "$temp_env"

    log_success "Marzban .env updated with domain=$domain, panel=$PANEL_PORT, sub=$SUB_PORT"
  fi

  # Сохраняем учётные данные в файл
  mkdir -p /etc/cubiveil
  cat >/etc/cubiveil/admin.credentials <<EOF
MARZBAN_USERNAME=${sudo_username}
MARZBAN_PASSWORD=${sudo_password}
EOF
  chmod 600 /etc/cubiveil/admin.credentials
  log_success "Admin credentials saved to /etc/cubiveil/admin.credentials"
}

# Настройка SSL для Marzban
marzban_configure_ssl() {
  log_step "marzban_configure_ssl" "Configuring SSL for Marzban"

  # SSL сертификаты настраиваются через ssl модуль
  # Проверяем наличие сертификатов
  if [[ -d "/var/lib/marzban/certs" ]] && [[ -n "$(ls -A /var/lib/marzban/certs 2>/dev/null)" ]]; then
    log_success "SSL certificates configured for Marzban"
    return 0
  fi

  log_info "SSL certificates will be configured by ssl module"
}

# Основная функция конфигурации
marzban_configure() {
  log_step "marzban_configure" "Configuring Marzban"

  marzban_configure_env
  marzban_configure_ssl

  log_success "Marzban configured successfully"
}

# ── Включение / Enable ──────────────────────────────────────

# Включение сервиса Marzban
marzban_enable() {
  log_step "marzban_enable" "Enabling Marzban service"

  # Определяем реальное имя контейнера (compose v1 или v2)
  local _container
  _container=$(docker ps -a --format '{{.Names}}' | grep -E '^marzban(_marzban_1)?$' | head -1)

  if [[ -z "$_container" ]]; then
    log_error "Marzban container not found"
    return 1
  fi

  if docker ps --format '{{.Names}}' | grep -qF "$_container"; then
    log_success "Marzban Docker container is running"
  else
    log_info "Starting Marzban Docker container..."
    docker start "$_container" >/dev/null 2>&1 || {
      log_error "Failed to start Marzban container"
      return 1
    }
  fi

  # Ждём пока Marzban запустится
  log_info "Waiting for Marzban to start..."
  sleep 5

  # Проверяем что контейнер работает
  if docker ps --format '{{.Names}}' | grep -qF "$_container"; then
    log_success "Marzban is running"
  else
    log_error "Marzban is not running"
    return 1
  fi

  log_success "Marzban enabled and started"
}

# Выключение сервиса Marzban
marzban_disable() {
  log_step "marzban_disable" "Disabling Marzban service"

  svc_stop "$MARZBAN_SERVICE"
  svc_disable "$MARZBAN_SERVICE"

  log_success "Marzban service disabled"
}

# ── Проверки / Checks ───────────────────────────────────────

# Проверка активности Marzban
marzban_is_active() {
  svc_active "$MARZBAN_SERVICE"
}

# Проверка здоровья Marzban
marzban_health_check() {
  log_step "marzban_health_check" "Checking Marzban health"

  # Проверяем статус сервиса
  if ! svc_active "$MARZBAN_SERVICE"; then
    log_error "Marzban service is not active"
    return 1
  fi

  # Проверяем .env файл
  if [[ ! -f "$MARZBAN_ENV_FILE" ]]; then
    log_error "Marzban .env file not found"
    return 1
  fi

  # Проверяем конфигурацию
  if [[ ! -d "${MARZBAN_CONFIG_DIR}" ]]; then
    log_error "Marzban config directory not found"
    return 1
  fi

  log_success "Marzban health check passed"
}

# ── Управление / Management ─────────────────────────────────

# Перезагрузка Marzban
marzban_restart() {
  log_step "marzban_restart" "Restarting Marzban"

  svc_restart "$MARZBAN_SERVICE"

  log_success "Marzban restarted"
}

# Остановка Marzban
marzban_stop() {
  log_step "marzban_stop" "Stopping Marzban"

  svc_stop "$MARZBAN_SERVICE"

  log_success "Marzban stopped"
}

# Запуск Marzban
marzban_start() {
  log_step "marzban_start" "Starting Marzban"

  svc_start "$MARZBAN_SERVICE"

  log_success "Marzban started"
}

# Статус Marzban
marzban_status() {
  log_step "marzban_status" "Marzban status"

  if svc_active "$MARZBAN_SERVICE"; then
    log_success "Marzban is running"
    return 0
  else
    log_error "Marzban is not running"
    return 1
  fi
}

# ── Удаление / Removal ──────────────────────────────────────

# Удаление Marzban
marzban_remove() {
  log_step "marzban_remove" "Removing Marzban"

  # Останавливаем сервис
  svc_stop "$MARZBAN_SERVICE" 2>/dev/null || true
  svc_disable "$MARZBAN_SERVICE" 2>/dev/null || true

  # Удаляем директорию установки
  if [[ -d "$MARZBAN_INSTALL_DIR" ]]; then
    rm -rf "$MARZBAN_INSTALL_DIR"
    log_info "Marzban installation directory removed"
  fi

  # Удаляем сервис systemd
  if [[ -f "/etc/systemd/system/${MARZBAN_SERVICE}.service" ]]; then
    rm -f "/etc/systemd/system/${MARZBAN_SERVICE}.service"
    systemctl daemon-reload
    log_info "Marzban systemd service removed"
  fi

  log_success "Marzban removed (data directory preserved)"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { marzban_install; }
module_configure() { marzban_configure; }
module_enable() { marzban_enable; }
module_disable() { marzban_disable; }

# Обновление модуля
module_update() {
  log_step "module_update" "Updating Marzban module"
  marzban_restart
}

# Удаление модуля
module_remove() {
  marzban_remove
}

# Статус модуля
module_status() {
  marzban_status
}

# Проверка здоровья
module_health_check() {
  marzban_health_check
}
