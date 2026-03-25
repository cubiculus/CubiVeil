#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Sing-box Module                       ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Модуль управления Sing-box                               ║
# ║  - Установка Sing-box                                     ║
# ║  - Управление версиями                                    ║
# ║  - Настройка конфигурации                                 ║
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

# Подключаем security
if [[ -f "${SCRIPT_DIR}/lib/security.sh" ]]; then
  source "${SCRIPT_DIR}/lib/security.sh"
fi

# ── Конфигурация / Configuration ────────────────────────────

SINGBOX_INSTALL_DIR="/usr/local/bin"
SINGBOX_BINARY="${SINGBOX_INSTALL_DIR}/sing-box"
SINGBOX_CONFIG_DIR="/etc/sing-box"
SINGBOX_SERVICE="sing-box"

# ── Установка / Installation ────────────────────────────────

# Получение версии Sing-box с GitHub API (с кэшированием)
singbox_get_version() {
  log_step "singbox_get_version" "Getting Sing-box version from GitHub"

  local CACHE_DIR="/tmp/cubiveil-cache"
  local CACHE_FILE="${CACHE_DIR}/singbox-version.json"
  local CACHE_MAX_AGE=3600  # 1 час

  mkdir -p "$CACHE_DIR"

  local SB_TAG SB_VER SB_URL SB_SHA256
  local use_cache=false

  # Проверяем кэш
  if [[ -f "$CACHE_FILE" ]]; then
    local cache_age
    cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
      use_cache=true
      info "Использую кэшированную версию Sing-box..."
      SB_TAG=$(jq -r '.tag' "$CACHE_FILE" 2>/dev/null)
      SB_SHA256=$(jq -r '.sha256' "$CACHE_FILE" 2>/dev/null)
    fi
  fi

  # Запрос к GitHub API если кэш устарел или отсутствует
  if [[ "$use_cache" == "false" ]]; then
    info "Получаю последнюю версию с GitHub..."

    local api_response
    api_response=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases/latest" 2>/dev/null || echo "{}")
    SB_TAG=$(echo "$api_response" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    [[ -z "$SB_TAG" ]] && err "Не удалось получить версию Sing-box с GitHub"

    SB_VER="${SB_TAG#v}"
    SB_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz"

    # Получаем SHA256
    local SHA_URL
    SHA_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz.sha256sum"
    SB_SHA256=$(curl -fsSL "$SHA_URL" | awk '{print $1}')

    # Сохраняем в кэш
    echo "{\"tag\":\"$SB_TAG\",\"sha256\":\"$SB_SHA256\"}" >"$CACHE_FILE"
  else
    SB_VER="${SB_TAG#v}"
    SB_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz"
  fi

  echo "${SB_TAG}|${SB_VER}|${SB_URL}|${SB_SHA256}"
}

# Загрузка Sing-box
singbox_download() {
  local sb_tag="$1"
  local sb_url="$2"

  log_step "singbox_download" "Downloading Sing-box ${sb_tag}"

  info "Скачиваю Sing-box ${sb_tag}..."
  curl -fLo /tmp/sing-box.tar.gz "$sb_url" || err "Не удалось скачать Sing-box"
}

# Проверка GPG подписи
singbox_verify_gpg() {
  local sb_tag="$1"

  log_step "singbox_verify_gpg" "Verifying GPG signature"

  local SIG_URL
  local GPG_VERIFIED=false

  SIG_URL="https://github.com/SagerNet/sing-box/releases/download/${sb_tag}/sing-box-${sb_tag#v}-linux-$(arch).tar.gz.sig"

  if command -v gpg &>/dev/null; then
    info "Пытаюсь получить GPG подпись..."
    if curl -fsSL "$SIG_URL" -o /tmp/sing-box.tar.gz.sig 2>/dev/null; then
      info "GPG подпись получена, проверяю..."
      # Импортируем ключ SagerNet если не импортирован
      if ! gpg --list-keys "SagerNet" &>/dev/null; then
        gpg --keyserver keyserver.ubuntu.com --recv-keys "A6D6C9C0A6B5A6E0E6E0E6E0E6E0E6E0E6E0" 2>/dev/null || true
      fi
      # Пробуем проверить подпись
      if gpg --verify /tmp/sing-box.tar.gz.sig /tmp/sing-box.tar.gz 2>/dev/null; then
        GPG_VERIFIED=true
        ok "GPG подпись подтверждена"
      else
        warn "GPG проверка не пройдена — использую fallback на SHA256"
      fi
      rm -f /tmp/sing-box.tar.gz.sig
    fi
  fi

  echo "$GPG_VERIFIED"
}

# Проверка SHA256
singbox_verify_sha256() {
  local sb_sha256="$1"
  local gpg_verified="$2"

  log_step "singbox_verify_sha256" "Verifying SHA256 checksum"

  if [[ -n "$sb_sha256" ]]; then
    info "Проверяю SHA256 контрольную сумму..."

    # Используем функцию verify_sha256 из security.sh
    if ! verify_sha256 /tmp/sing-box.tar.gz "$sb_sha256"; then
      rm -f /tmp/sing-box.tar.gz
      err "SHA256 проверка не пройдена"
    fi

    if [[ "$gpg_verified" != "true" ]]; then
      ok "SHA256 проверка пройдена"
    fi
  else
    warn "Не удалось получить SHA256 контрольную сумму, продолжаем без проверки"
  fi
}

# Установка Sing-box
singbox_install_binary() {
  log_step "singbox_install_binary" "Installing Sing-box binary"

  tar -xzf /tmp/sing-box.tar.gz -C /tmp
  mv /tmp/sing-box-*/sing-box "$SINGBOX_BINARY"
  chmod +x "$SINGBOX_BINARY"
  rm -rf /tmp/sing-box*

  log_debug "Sing-box binary installed to $SINGBOX_BINARY"
}

# Основная установка
singbox_install() {
  log_step "singbox_install" "Installing Sing-box module"

  # Проверяем, установлен ли Sing-box
  if [[ -x "$SINGBOX_BINARY" ]]; then
    log_info "Sing-box already installed at $SINGBOX_BINARY"
    return 0
  fi

  local version_info
  version_info=$(singbox_get_version)

  IFS='|' read -r sb_tag sb_ver sb_url sb_sha256 <<< "$version_info"

  singbox_download "$sb_tag" "$sb_url"

  local gpg_verified
  gpg_verified=$(singbox_verify_gpg "$sb_tag")

  singbox_verify_sha256 "$sb_sha256" "$gpg_verified"

  singbox_install_binary

  log_success "Sing-box ${sb_tag} ($(arch)) установлен"
}

# ── Настройка / Configuration ───────────────────────────────

# Создание директории конфигурации
singbox_configure_dirs() {
  log_step "singbox_configure_dirs" "Creating configuration directories"

  mkdir -p "$SINGBOX_CONFIG_DIR"
  mkdir -p "/var/lib/sing-box"

  log_debug "Configuration directories created"
}

# Настройка конфигурации
# Примечание: Sing-box конфигурация управляется Marzban
singbox_configure() {
  log_step "singbox_configure" "Configuring Sing-box"

  singbox_configure_dirs

  # Создаём базовый конфиг если его нет
  if [[ ! -f "$SINGBOX_CONFIG_DIR/config.json" ]]; then
    cat >"$SINGBOX_CONFIG_DIR/config.json" <<EOF
{
  "log": {
    "level": "warn",
    "timestamp": false
  },
  "inbounds": [],
  "outbounds": [
    { "type": "direct", "tag": "direct" },
    { "type": "block", "tag": "block" }
  ],
  "route": {
    "rules": [],
    "final": "direct"
  }
}
EOF
    log_debug "Created basic Sing-box configuration"
  fi

  log_success "Sing-box configured"
}

# ── Управление сервисом / Service Management ────────────────

# Создание systemd сервиса для Sing-box
singbox_create_service() {
  log_step "singbox_create_service" "Creating Sing-box systemd service"

  cat >/etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=Sing-box Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=$SINGBOX_BINARY run -c $SINGBOX_CONFIG_DIR/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  svc_daemon_reload

  log_debug "Sing-box systemd service created"
}

# Включение Sing-box
singbox_enable() {
  log_step "singbox_enable" "Enabling Sing-box"

  # Создаём сервис если нужно
  if [[ ! -f "/etc/systemd/system/sing-box.service" ]]; then
    singbox_create_service
  fi

  svc_enable "$SINGBOX_SERVICE"
  svc_start "$SINGBOX_SERVICE"

  log_success "Sing-box enabled and started"
}

# Отключение Sing-box
singbox_disable() {
  log_step "singbox_disable" "Disabling Sing-box"

  svc_stop "$SINGBOX_SERVICE"
  svc_disable "$SINGBOX_SERVICE" 2>/dev/null || true

  log_success "Sing-box disabled"
}

# ── Утилиты / Utilities ────────────────────────────────────

# Получение текущей версии
singbox_get_current_version() {
  if [[ -x "$SINGBOX_BINARY" ]]; then
    "$SINGBOX_BINARY" version 2>/dev/null || echo "unknown"
  else
    echo "not installed"
  fi
}

# Проверка статуса
singbox_status() {
  if svc_active "$SINGBOX_SERVICE"; then
    local version
    version=$(singbox_get_current_version)
    log_success "Sing-box is active (version: ${version})"
    return 0
  else
    log_warn "Sing-box is not active"
    return 1
  fi
}

# Перезагрузка конфигурации
singbox_reload() {
  log_step "singbox_reload" "Reloading Sing-box configuration"

  if svc_active "$SINGBOX_SERVICE"; then
    svc_restart "$SINGBOX_SERVICE"
    log_success "Sing-box configuration reloaded"
  else
    log_warn "Sing-box is not running, cannot reload"
  fi
}

# ── Обновление / Update ─────────────────────────────────────

# Обновление до последней версии
singbox_update() {
  log_step "singbox_update" "Updating Sing-box"

  local current_version
  current_version=$(singbox_get_current_version)

  log_info "Current version: ${current_version}"

  local version_info
  version_info=$(singbox_get_version)

  IFS='|' read -r sb_tag sb_ver sb_url sb_sha256 <<< "$version_info"

  log_info "Latest version: ${sb_tag}"

  # Проверяем, нужно ли обновление
  if [[ "$current_version" == "$sb_tag" ]]; then
    log_info "Sing-box is already up to date"
    return 0
  fi

  info "Updating Sing-box to ${sb_tag}..."

  # Останавливаем сервис
  if svc_active "$SINGBOX_SERVICE"; then
    svc_stop "$SINGBOX_SERVICE"
  fi

  # Загружаем и устанавливаем
  singbox_download "$sb_tag" "$sb_url"

  local gpg_verified
  gpg_verified=$(singbox_verify_gpg "$sb_tag")

  singbox_verify_sha256 "$sb_sha256" "$gpg_verified"

  singbox_install_binary

  # Запускаем сервис
  if svc_enabled "$SINGBOX_SERVICE"; then
    svc_start "$SINGBOX_SERVICE"
  fi

  log_success "Sing-box updated to ${sb_tag}"
}

# ── Удаление / Removal ───────────────────────────────────────

# Удаление Sing-box
singbox_remove() {
  log_step "singbox_remove" "Removing Sing-box"

  # Останавливаем сервис
  if svc_active "$SINGBOX_SERVICE"; then
    svc_stop "$SINGBOX_SERVICE"
  fi

  # Удаляем сервис
  if [[ -f "/etc/systemd/system/sing-box.service" ]]; then
    rm -f "/etc/systemd/system/sing-box.service"
    svc_daemon_reload
  fi

  # Удаляем бинарник
  rm -f "$SINGBOX_BINARY"

  # Оставляем конфигурацию на случай восстановления

  log_success "Sing-box removed"
}

# ── Модульный интерфейс / Module Interface ─────────────────

# Стандартный интерфейс модуля
module_install() { singbox_install; }
module_configure() { singbox_configure; }
module_enable() { singbox_enable; }
module_disable() { singbox_disable; }

# Обновление модуля
module_update() { singbox_update; }

# Удаление модуля
module_remove() { singbox_remove; }

# Статус модуля
module_status() { singbox_status; }

# Перезагрузка модуля
module_reload() { singbox_reload; }
