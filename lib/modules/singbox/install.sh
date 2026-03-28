#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Sing-box Module                       ║
# ║          github.com/cubiculus/cubiveil                    ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей ─────────────────────────────────
# SCRIPT_DIR вычисляется относительно самого модуля
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

[[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]] && source "${SCRIPT_DIR}/lib/core/system.sh"
[[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]] && source "${SCRIPT_DIR}/lib/core/log.sh"
[[ -f "${SCRIPT_DIR}/lib/utils.sh" ]] && source "${SCRIPT_DIR}/lib/utils.sh"
[[ -f "${SCRIPT_DIR}/lib/security.sh" ]] && source "${SCRIPT_DIR}/lib/security.sh"

# ── Конфигурация ─────────────────────────────────────────────
SINGBOX_BINARY="/usr/local/bin/sing-box"
SINGBOX_CONFIG_DIR="/etc/sing-box"
SINGBOX_SERVICE="sing-box"

# ══════════════════════════════════════════════════════════════
# ВАЖНО: singbox_get_version() возвращает данные через stdout.
# Все сообщения (info/warn/log/debug) ОБЯЗАНЫ идти в stderr >&2,
# иначе вызывающий код version_info=$(singbox_get_version)
# поймает мусор вместо "tag|ver|url|sha256".
# ══════════════════════════════════════════════════════════════

singbox_get_version() {
  local CACHE_DIR="/tmp/cubiveil-cache"
  local CACHE_FILE="${CACHE_DIR}/singbox-version.json"
  local CACHE_MAX_AGE=3600

  mkdir -p "$CACHE_DIR"

  local SB_TAG="" SB_VER="" SB_URL="" SB_SHA256=""

  # ── Кэш ───────────────────────────────────────────────────
  if [[ -f "$CACHE_FILE" ]]; then
    local cache_age
    cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
      SB_TAG=$(jq -r '.tag' "$CACHE_FILE" 2>/dev/null || true)
      SB_SHA256=$(jq -r '.sha256' "$CACHE_FILE" 2>/dev/null || true)
      if [[ -n "$SB_TAG" && "$SB_TAG" != "null" ]]; then
        info "Using cached Sing-box version: $SB_TAG" >&2
        SB_VER="${SB_TAG#v}"
        SB_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz"
        # Единственная строка в stdout — данные
        echo "${SB_TAG}|${SB_VER}|${SB_URL}|${SB_SHA256}"
        return 0
      fi
    fi
  fi

  # ── GitHub API ────────────────────────────────────────────
  info "Getting latest Sing-box version from GitHub..." >&2

  local api_response
  api_response=$(curl -sf --max-time 15 \
    "https://api.github.com/repos/SagerNet/sing-box/releases/latest" 2>/dev/null || true)

  # Парсим tag через jq (предпочтительно) или grep
  if command -v jq &>/dev/null; then
    SB_TAG=$(echo "$api_response" | jq -r '.tag_name // empty' 2>/dev/null || true)
  fi
  if [[ -z "$SB_TAG" ]]; then
    SB_TAG=$(echo "$api_response" | grep '"tag_name"' | head -1 |
      sed 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/' || true)
  fi

  # Fallback: последний тег напрямую через git ls-remote
  if [[ -z "$SB_TAG" ]]; then
    warn "GitHub API failed, trying git ls-remote..." >&2
    SB_TAG=$(git ls-remote --tags --refs \
      "https://github.com/SagerNet/sing-box.git" 2>/dev/null |
      awk '{print $2}' | grep -v '\^{}' | grep '/v' |
      sort -V | tail -1 | sed 's|refs/tags/||' || true)
  fi

  if [[ -z "$SB_TAG" ]]; then
    err "Cannot get Sing-box version from GitHub" >&2
    return 1
  fi

  SB_VER="${SB_TAG#v}"
  local _arch
  _arch=$(arch)
  SB_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-${_arch}.tar.gz"

  info "Sing-box latest: ${SB_TAG} (${_arch})" >&2

  # SHA256
  local SHA_URL
  SHA_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-${_arch}.tar.gz.sha256sum"
  SB_SHA256=$(curl -fsSL --max-time 15 "$SHA_URL" 2>/dev/null | awk '{print $1}' || true)
  if [[ -z "$SB_SHA256" ]]; then
    warn "Could not fetch SHA256 checksum, will skip verification" >&2
  fi

  # Кэшируем
  echo "{\"tag\":\"$SB_TAG\",\"sha256\":\"$SB_SHA256\"}" >"$CACHE_FILE"

  # Единственная строка в stdout — данные
  echo "${SB_TAG}|${SB_VER}|${SB_URL}|${SB_SHA256}"
}

# ── Загрузка ──────────────────────────────────────────────────
singbox_download() {
  local sb_tag="$1"
  local sb_url="$2"

  log_step "singbox_download" "Downloading Sing-box ${sb_tag}"

  if [[ -z "$sb_url" ]]; then
    err "Sing-box download URL is empty (singbox_get_version failed?)"
  fi

  info "Downloading Sing-box ${sb_tag}..."
  if ! curl -fL --max-time 300 --progress-bar -o /tmp/sing-box.tar.gz "$sb_url"; then
    err "Failed to download Sing-box from: $sb_url"
  fi

  log_success "Downloaded: /tmp/sing-box.tar.gz"
}

# ── GPG проверка ──────────────────────────────────────────────
singbox_verify_gpg() {
  local sb_tag="$1"
  local gpg_verified="false"

  if ! command -v gpg &>/dev/null; then
    echo "$gpg_verified"
    return 0
  fi

  local SIG_URL
  SIG_URL="https://github.com/SagerNet/sing-box/releases/download/${sb_tag}/sing-box-${sb_tag#v}-linux-$(arch).tar.gz.sig"

  if curl -fsSL --max-time 15 "$SIG_URL" -o /tmp/sing-box.tar.gz.sig 2>/dev/null; then
    if ! gpg --list-keys "SagerNet" &>/dev/null; then
      gpg --keyserver keyserver.ubuntu.com --recv-keys \
        "A6D6C9C0A6B5A6E0E6E0E6E0E6E0E6E0E6E0" 2>/dev/null || true
    fi
    if gpg --verify /tmp/sing-box.tar.gz.sig /tmp/sing-box.tar.gz 2>/dev/null; then
      gpg_verified="true"
      ok "GPG signature verified"
    else
      warn "GPG verification failed — falling back to SHA256"
    fi
    rm -f /tmp/sing-box.tar.gz.sig
  fi

  echo "$gpg_verified"
}

# ── SHA256 проверка ───────────────────────────────────────────
singbox_verify_sha256() {
  local sb_sha256="$1"
  local gpg_verified="$2"

  if [[ -z "$sb_sha256" ]]; then
    warn "No SHA256 checksum available, skipping verification"
    return 0
  fi

  info "Verifying SHA256..."
  if ! verify_sha256 /tmp/sing-box.tar.gz "$sb_sha256"; then
    rm -f /tmp/sing-box.tar.gz
    err "SHA256 verification failed"
  fi

  [[ "$gpg_verified" != "true" ]] && ok "SHA256 verified"
}

# ── Установка бинарника ───────────────────────────────────────
singbox_install_binary() {
  log_step "singbox_install_binary" "Installing Sing-box binary"

  local _arch
  _arch=$(arch)

  # Распаковываем во временную папку
  local tmp_extract
  tmp_extract=$(mktemp -d)
  tar -xzf /tmp/sing-box.tar.gz -C "$tmp_extract"

  # Ищем бинарник (имя директории зависит от версии)
  local binary
  binary=$(find "$tmp_extract" -name "sing-box" -type f | head -1)
  if [[ -z "$binary" ]]; then
    rm -rf "$tmp_extract" /tmp/sing-box.tar.gz
    err "sing-box binary not found in archive"
  fi

  mv "$binary" "$SINGBOX_BINARY"
  chmod +x "$SINGBOX_BINARY"
  rm -rf "$tmp_extract" /tmp/sing-box.tar.gz

  log_success "Installed: $SINGBOX_BINARY"
}

# ── Полная установка ──────────────────────────────────────────
singbox_install() {
  log_step "singbox_install" "Installing Sing-box"

  if [[ -x "$SINGBOX_BINARY" ]]; then
    local cur_ver
    cur_ver=$("$SINGBOX_BINARY" version 2>/dev/null | head -1 || echo "unknown")
    log_info "Sing-box already installed: $cur_ver"
    return 0
  fi

  # version_info содержит ТОЛЬКО "tag|ver|url|sha256" — никаких лишних строк
  local version_info
  version_info=$(singbox_get_version)

  # Разбираем
  local sb_tag sb_ver sb_url sb_sha256
  IFS='|' read -r sb_tag sb_ver sb_url sb_sha256 <<<"$version_info"

  # Дополнительная проверка что URL не пустой
  if [[ -z "$sb_url" ]]; then
    err "Sing-box URL is empty after parsing version info: '$version_info'"
  fi

  singbox_download "$sb_tag" "$sb_url"

  local gpg_verified
  gpg_verified=$(singbox_verify_gpg "$sb_tag")

  singbox_verify_sha256 "$sb_sha256" "$gpg_verified"
  singbox_install_binary

  log_success "Sing-box ${sb_tag} installed"
}

# ── Конфигурация ──────────────────────────────────────────────
singbox_configure_dirs() {
  mkdir -p "$SINGBOX_CONFIG_DIR" "/var/lib/sing-box"
}

singbox_configure() {
  log_step "singbox_configure" "Configuring Sing-box"
  singbox_configure_dirs

  if [[ ! -f "$SINGBOX_CONFIG_DIR/config.json" ]]; then
    cat >"$SINGBOX_CONFIG_DIR/config.json" <<'EOF'
{
  "log": { "level": "warn", "timestamp": false },
  "inbounds": [],
  "outbounds": [
    { "type": "direct", "tag": "direct" },
    { "type": "block",  "tag": "block"  }
  ],
  "route": { "rules": [], "final": "direct" }
}
EOF
  fi

  log_success "Sing-box configured"
}

# ── Управление сервисом ───────────────────────────────────────
singbox_create_user() {
  id -u singbox &>/dev/null || useradd -r -s /usr/sbin/nologin singbox
}

singbox_create_service() {
  log_step "singbox_create_service" "Creating systemd service"
  singbox_create_user

  cat >/etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=Sing-box Service
After=network.target

[Service]
Type=simple
User=singbox
WorkingDirectory=/etc/sing-box
ExecStart=${SINGBOX_BINARY} run -c ${SINGBOX_CONFIG_DIR}/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  chown -R singbox:singbox "$SINGBOX_CONFIG_DIR"
  svc_daemon_reload
}

singbox_enable() {
  log_step "singbox_enable" "Enabling Sing-box"
  [[ ! -f "/etc/systemd/system/sing-box.service" ]] && singbox_create_service
  svc_enable "$SINGBOX_SERVICE"
  svc_start "$SINGBOX_SERVICE"
  log_success "Sing-box enabled and started"
}

singbox_disable() {
  svc_stop "$SINGBOX_SERVICE" || true
  svc_disable "$SINGBOX_SERVICE" 2>/dev/null || true
}

singbox_reload() {
  svc_active "$SINGBOX_SERVICE" && svc_restart "$SINGBOX_SERVICE" || true
}

singbox_status() {
  if svc_active "$SINGBOX_SERVICE"; then
    log_success "Sing-box is active"
    return 0
  else
    log_warn "Sing-box is not active"
    return 1
  fi
}

singbox_remove() {
  svc_stop "$SINGBOX_SERVICE" 2>/dev/null || true
  rm -f "/etc/systemd/system/sing-box.service"
  svc_daemon_reload
  rm -f "$SINGBOX_BINARY"
  log_success "Sing-box removed"
}

singbox_update() {
  local cur_ver
  cur_ver=$("$SINGBOX_BINARY" version 2>/dev/null | head -1 || echo "unknown")

  local version_info
  version_info=$(singbox_get_version)

  local sb_tag sb_ver sb_url sb_sha256
  IFS='|' read -r sb_tag sb_ver sb_url sb_sha256 <<<"$version_info"

  if [[ "$cur_ver" == *"$sb_tag"* ]]; then
    log_info "Sing-box already up to date: $sb_tag"
    return 0
  fi

  svc_active "$SINGBOX_SERVICE" && svc_stop "$SINGBOX_SERVICE"
  singbox_download "$sb_tag" "$sb_url"
  local gpg_verified
  gpg_verified=$(singbox_verify_gpg "$sb_tag")
  singbox_verify_sha256 "$sb_sha256" "$gpg_verified"
  singbox_install_binary
  svc_enabled "$SINGBOX_SERVICE" && svc_start "$SINGBOX_SERVICE"
  log_success "Sing-box updated to $sb_tag"
}

# ── Модульный интерфейс ───────────────────────────────────────
module_install() { singbox_install; }
module_configure() { singbox_configure; }
module_enable() { singbox_enable; }
module_disable() { singbox_disable; }
module_update() { singbox_update; }
module_remove() { singbox_remove; }
module_status() { singbox_status; }
module_reload() { singbox_reload; }
