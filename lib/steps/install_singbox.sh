#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Install Sing-box                ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Установка Sing-box                                       ║
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

# ── Функции / Functions ──────────────────────────────────────

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
        gpg --keyserver keyserver.ubuntu.com --recv-keys "A6D6C9C0A6B5A6E0E6E0E6E0E6E0E6E0E6E0E6E0" 2>/dev/null || true
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
singbox_install() {
  log_step "singbox_install" "Installing Sing-box"

  tar -xzf /tmp/sing-box.tar.gz -C /tmp
  mv /tmp/sing-box-*/sing-box /usr/local/bin/sing-box
  chmod +x /usr/local/bin/sing-box
  rm -rf /tmp/sing-box*
}

# Основная функция шага (вызывается из install-steps.sh)
step_install_singbox() {
  step_title "7" "Sing-box" "Sing-box"

  local version_info
  version_info=$(singbox_get_version)

  IFS='|' read -r sb_tag sb_ver sb_url sb_sha256 <<< "$version_info"

  singbox_download "$sb_tag" "$sb_url"

  local gpg_verified
  gpg_verified=$(singbox_verify_gpg "$sb_tag")

  singbox_verify_sha256 "$sb_sha256" "$gpg_verified"

  singbox_install

  ok "Sing-box ${sb_tag} ($(arch)) установлен"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { step_install_singbox; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }
