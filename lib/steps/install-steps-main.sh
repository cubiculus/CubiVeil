#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Installation Steps                    ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Основные шаги установки для install.sh                   ║
# ╚═══════════════════════════════════════════════════════════╝

# Import utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils.sh"
source "${SCRIPT_DIR}/../security.sh"

# ── Проверка IP окружения / IP Neighborhood Check ───────────
step_check_ip_neighborhood() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_CHECK_SUBNET"
  else
    step_title="$STEP_CHECK_SUBNET"
  fi
  step "$step_title"

  # Получение IP сервера
  SERVER_IP=$(curl -sf --max-time 4 https://api4.ipify.org 2>/dev/null | tr -d '[:space:]')
  if [[ -z "$SERVER_IP" ]]; then
    SERVER_IP=$(hostname -I | awk '{print $1}')
  fi

  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "$(get_server_ip_info)"
    info "Проверяю соседние адреса в диапазоне /24..."
  else
    info "$(get_server_ip_info_en)"
    info "Checking neighboring IPs in /24 range..."
  fi

  # Извлечение первых трёх октетов для /24 подсети
  local subnet_prefix
  subnet_prefix=$(echo "$SERVER_IP" | cut -d'.' -f1-3)

  local vpn_count=0
  local hosting_count=0
  local checked=0
  local max_check=5
  local skip_own_ip=true

  # Проверка соседних IP
  for i in $(seq 1 254); do
    [[ $checked -ge $max_check ]] && break

    local neighbor_ip="${subnet_prefix}.${i}"

    # Пропуск собственного IP
    if [[ "$skip_own_ip" == true && "$neighbor_ip" == "$SERVER_IP" ]]; then
      continue
    fi

    # Запрос к ip-api.com (бесплатный лимит: 45 запросов/мин)
    local response
    response=$(curl -sf --max-time 5 "http://ip-api.com/json/${neighbor_ip}?fields=status,message,proxy,hosting,mobile" 2>/dev/null)

    if [[ -z "$response" ]]; then
      continue
    fi

    # Проверка статуса ответа
    local status
    status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [[ "$status" != "success" ]]; then
      continue
    fi

    ((checked++))

    # Проверка на proxy/hosting
    local is_proxy
    local is_hosting
    is_proxy=$(echo "$response" | grep -o '"proxy":[^,}]*' | cut -d':' -f2 | tr -d '[:space:]')
    is_hosting=$(echo "$response" | grep -o '"hosting":[^,}]*' | cut -d':' -f2 | tr -d '[:space:]')

    if [[ "$is_proxy" == "true" ]]; then
      ((vpn_count++))
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Обнаружен proxy/VPN: ${neighbor_ip}"
      else
        warn "Proxy/VPN detected: ${neighbor_ip}"
      fi
    fi

    if [[ "$is_hosting" == "true" ]]; then
      ((hosting_count++))
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Обнаружен хостинг: ${neighbor_ip}"
      else
        warn "Hosting detected: ${neighbor_ip}"
      fi
    fi

    # Небольшая задержка для соблюдения лимитов API
    sleep 0.2
  done

  local suspicious_count=$((vpn_count + hosting_count))

  if [[ "$LANG_NAME" == "Русский" ]]; then
    if [[ $suspicious_count -eq 0 ]]; then
      ok "В ${checked} проверенных соседних IP — 0 VPN/хостинг серверов. Подсеть чистая ✓"
    else
      warn "В ${checked} проверенных соседних IP — ${suspicious_count} подозрительных (${vpn_count} VPN/proxy, ${hosting_count} хостинг)"
    fi
  else
    if [[ $suspicious_count -eq 0 ]]; then
      ok "In ${checked} checked neighbor IPs — 0 VPN/hosting servers. Subnet is clean ✓"
    else
      warn "In ${checked} checked neighbor IPs — ${suspicious_count} suspicious (${vpn_count} VPN/proxy, ${hosting_count} hosting)"
    fi
  fi
}

# ── Обновление системы / System Update ───────────────────────
step_system_update() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_UPDATE_RU"
  else
    step_title="$STEP_UPDATE"
  fi
  step "$step_title"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Обновление системы..."
  else
    info "Updating system..."
  fi

  apt-get update -qq
  apt-get upgrade -y -qq

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Система обновлена, зависимости установлены"
  else
    ok "System updated, dependencies installed"
  fi
}

# ── Автообновления / Auto Updates ────────────────────────────
step_auto_updates() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_AUTO_UPDATES_RU"
  else
    step_title="$STEP_AUTO_UPDATES"
  fi
  step "$step_title"

  # Настройка автоматических обновлений безопасности
  cat >/etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Автообновления security-патчей настроены (без интерактивных диалогов)"
  else
    ok "Security auto-updates configured (no interactive dialogs)"
  fi
}

# ── BBR оптимизация / BBR Optimization ───────────────────────
step_bbr() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_BBR_RU"
  else
    step_title="$STEP_BBR"
  fi
  step "$step_title"

  # Включение BBR
  if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    cat >>/etc/sysctl.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    sysctl -p >/dev/null 2>&1
  fi

  local current
  current=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "cubic")

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "TCP congestion control: ${current}"
  else
    ok "TCP congestion control: ${current}"
  fi
}

# ── Файрвол / Firewall ───────────────────────────────────────
step_firewall() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_FIREWALL_RU"
  else
    step_title="$STEP_FIREWALL"
  fi
  step "$step_title"

  # Установка ufw если не установлен
  if ! command -v ufw &>/dev/null; then
    apt-get install -y -qq ufw >/dev/null 2>&1
  fi

  # Настройка ufw
  ufw --force reset >/dev/null 2>&1
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow 22/tcp comment "SSH"
  ufw allow 443/tcp comment "HTTPS"
  ufw allow 443/udp comment "HTTPS UDP"
  ufw --force enable

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Файрвол включён: 22/tcp, 443/tcp, 443/udp"
    warn "SSH: после проверки нового порта закрой 22 → ufw delete allow 22/tcp"
  else
    ok "Firewall enabled: 22/tcp, 443/tcp, 443/udp"
    warn "SSH: after checking new port, close 22 → ufw delete allow 22/tcp"
  fi
}

# ── Fail2ban ─────────────────────────────────────────────────
step_fail2ban() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_FAIL2BAN_RU"
  else
    step_title="$STEP_FAIL2BAN"
  fi
  step "$step_title"

  # Установка fail2ban если не установлен
  if ! command -v fail2ban-client &>/dev/null; then
    apt-get install -y -qq fail2ban >/dev/null 2>&1
  fi

  # Получение SSH порта (или использование стандартного)
  local ssh_port
  ssh_port=$(grep -E "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
  SSH_PORT="${ssh_port:-22}"

  # Конфигурация fail2ban для SSH
  cat >/etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = ${SSH_PORT}
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400
EOF

  systemctl enable fail2ban >/dev/null 2>&1
  systemctl restart fail2ban >/dev/null 2>&1

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Fail2ban: SSH защита на порту ${SSH_PORT} (3 попытки → бан 24ч)"
  else
    ok "Fail2ban: SSH protection on port ${SSH_PORT} (3 attempts → 24h ban)"
  fi
}

# ── Sing-box установка / Sing-box Installation ───────────────
step_install_singbox() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_SINGBOX_RU"
  else
    step_title="$STEP_SINGBOX"
  fi
  step "$step_title"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Получаю последнюю версию с GitHub..."
  else
    info "Getting latest version from GitHub..."
  fi

  # Получение последней версии Sing-box
  local sb_tag
  sb_tag=$(curl -sf https://api.github.com/repos/SagerNet/sing-box/releases/latest 2>/dev/null | jq -r '.tag_name' | sed 's/^v//')
  sb_tag="${sb_tag:-1.10.1}"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Скачиваю Sing-box ${sb_tag}..."
  else
    info "Downloading Sing-box ${sb_tag}..."
  fi

  local arch
  arch=$(uname -m)
  case "$arch" in
  x86_64) arch="amd64" ;;
  aarch64) arch="arm64" ;;
  armv7l) arch="armv7" ;;
  esac

  local sb_url="https://github.com/SagerNet/sing-box/releases/download/v${sb_tag}/sing-box-${sb_tag}-linux-${arch}.tar.gz"
  local sb_sha_url="https://github.com/SagerNet/sing-box/releases/download/v${sb_tag}/sing-box-${sb_tag}-linux-${arch}.tar.gz.sha256sum"
  local temp_dir
  temp_dir=$(mktemp -d)

  if ! curl -sfL "$sb_url" -o "${temp_dir}/sing-box.tar.gz" 2>/dev/null; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Не удалось скачать Sing-box с GitHub, использую локальную версию"
    else
      warn "Failed to download Sing-box from GitHub, using local version"
    fi
  fi

  # Проверка SHA256
  if [[ -f "${temp_dir}/sing-box.tar.gz" ]]; then
    if curl -sfL "$sb_sha_url" -o "${temp_dir}/sing-box.sha256sum" 2>/dev/null; then
      expected_hash=$(awk '{print $1}' "${temp_dir}/sing-box.sha256sum")
      if [[ "$LANG_NAME" == "Русский" ]]; then
        info "Проверка SHA256..."
      else
        info "Verifying SHA256..."
      fi
      if ! verify_sha256 "${temp_dir}/sing-box.tar.gz" "$expected_hash"; then
        if [[ "$LANG_NAME" == "Русский" ]]; then
          err "SHA256 проверка не пройдена, Sing-box не установлен"
        else
          err "SHA256 verification failed, Sing-box not installed"
        fi
        rm -rf "${temp_dir}"
        return 1
      fi
    else
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Не удалось скачать SHA256 чексумму, продолжаю без проверки"
      else
        warn "Failed to download SHA256 checksum, continuing without verification"
      fi
    fi
  fi

  # Установка sing-box
  mkdir -p /usr/local/bin
  if [[ -f "${temp_dir}/sing-box.tar.gz" ]]; then
    tar -xzf "${temp_dir}/sing-box.tar.gz" -C "${temp_dir}"
    cp "${temp_dir}/sing-box-${sb_tag}-linux-${arch}/sing-box" /usr/local/bin/
    chmod +x /usr/local/bin/sing-box
  fi

  rm -rf "${temp_dir}"

  # Создание системного пользователя singbox
  if ! id -u singbox >/dev/null 2>&1; then
    useradd -r -s /usr/sbin/nologin singbox
  fi

  # Создание systemd сервиса
  cat >/etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=Sing-box Service
After=network.target

[Service]
Type=simple
User=singbox
WorkingDirectory=/etc/sing-box
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

  # Установка прав на директорию конфигурации
  chown -R singbox:singbox /etc/sing-box

  systemctl daemon-reload
  systemctl enable sing-box >/dev/null 2>&1

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Sing-box ${sb_tag} ($(arch)) установлен"
  else
    ok "Sing-box ${sb_tag} ($(arch)) installed"
  fi
}

# ── Генерация ключей и портов / Keys and Ports Generation ───
step_generate_keys_and_ports() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_KEYS_RU"
  else
    step_title="$STEP_KEYS"
  fi
  step "$step_title"

  # Создание директории для ключей
  mkdir -p /etc/cubiveil

  # Генерация Reality ключей
  local reality_private_key
  reality_private_key=$(/usr/local/bin/sing-box generate reality-keypair 2>/dev/null | grep "PrivateKey:" | awk '{print $2}' || echo "$(openssl rand -base64 32)")

  # Сохранение ключей
  cat >/etc/cubiveil/reality.json <<EOF
{
  "private_key": "${reality_private_key}",
  "sni": "www.microsoft.com"
}
EOF

  # Генерация портов
  TROJAN_PORT=$(unique_port)
  SS_PORT=$(unique_port)
  PANEL_PORT=$(unique_port)
  SUB_PORT=$(unique_port)

  # Сохранение портов
  cat >/etc/cubiveil/ports.json <<EOF
{
  "trojan": ${TROJAN_PORT},
  "shadowsocks": ${SS_PORT},
  "panel": ${PANEL_PORT},
  "subscription": ${SUB_PORT}
}
EOF

  REALITY_SNI="www.microsoft.com"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Reality keypair сгенерирован, camouflage: ${REALITY_SNI}"
    ok "Порты → Trojan:${TROJAN_PORT} SS:${SS_PORT} Панель:${PANEL_PORT} Подписки:${SUB_PORT}"
  else
    ok "Reality keypair generated, camouflage: ${REALITY_SNI}"
    ok "Ports → Trojan:${TROJAN_PORT} SS:${SS_PORT} Panel:${PANEL_PORT} Subscription:${SUB_PORT}"
  fi
}

# ── Установка Marzban / Marzban Installation ─────────────────
step_install_marzban() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_MARZBAN_RU"
  else
    step_title="$STEP_MARZBAN"
  fi
  step "$step_title"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Устанавливаю Marzban..."
  else
    info "Installing Marzban..."
  fi

  # Установка Marzban через официальный скрипт с проверкой целостности
  if ! command -v marzban &>/dev/null; then
    local temp_dir
    temp_dir=$(mktemp -d)
    local marzban_script="${temp_dir}/marzban.sh"
    local install_success=false

    # SHA256 хеш стабильной версии marzban.sh
    # Для получения актуального хеша:
    #   curl -sfL https://raw.githubusercontent.com/Gozargah/Marzban-scripts/master/marzban.sh | sha256sum
    # Обновляйте expected_hash при обновлении скрипта в репозитории Marzban
    local expected_hash="REPLACE_WITH_ACTUAL_SHA256"
    local hash_check_enabled=true

    # Проверка: если хеш не обновлён, предупреждаем
    if [[ "$expected_hash" == "REPLACE_WITH_ACTUAL_SHA256" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "SHA256 хеш не настроен! Обновите expected_hash в install-steps-main.sh"
        info "Продолжаю установку без проверки целостности (небезопасно)..."
      else
        warn "SHA256 hash not configured! Update expected_hash in install-steps-main.sh"
        info "Continuing installation without integrity check (insecure)..."
      fi
      hash_check_enabled=false
    fi

    if curl -sfL "https://raw.githubusercontent.com/Gozargah/Marzban-scripts/master/marzban.sh" -o "$marzban_script" 2>/dev/null; then
      local actual_hash
      actual_hash=$(sha256sum "$marzban_script" | awk '{print $1}')

      if [[ "$hash_check_enabled" == "true" ]]; then
        if [[ "$actual_hash" == "$expected_hash" ]]; then
          if bash "$marzban_script" install >/dev/null 2>&1; then
            install_success=true
          fi
        else
          if [[ "$LANG_NAME" == "Русский" ]]; then
            warn "SHA256 хеш не совпадает! Скрипт мог быть изменён."
            info "Ожидалось: ${expected_hash}"
            info "Получено:  ${actual_hash}"
            info "Пропускаю установку через скрипт, пробую альтернативный метод..."
          else
            warn "SHA256 hash mismatch! Script may have been tampered."
            info "Expected: ${expected_hash}"
            info "Got:      ${actual_hash}"
            info "Skipping script installation, trying alternative method..."
          fi
        fi
      else
        # Hash check disabled, proceed with caution
        if bash "$marzban_script" install >/dev/null 2>&1; then
          install_success=true
        fi
      fi
    else
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Не удалось скачать скрипт Marzban, пробую альтернативный метод..."
      else
        warn "Failed to download Marzban script, trying alternative method..."
      fi
    fi

    rm -rf "$temp_dir"

    # Проверка успешности установки
    if [[ "$install_success" != "true" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        err "Установка Marzban не удалась. Лог: journalctl -u marzban -n 50"
      else
        err "Marzban installation failed. Log: journalctl -u marzban -n 50"
      fi
    fi
  fi

  # Проверка установки
  if command -v marzban &>/dev/null || [[ -f "/usr/local/bin/marzban" ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      ok "Marzban установлен"
    else
      ok "Marzban installed"
    fi
  else
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Marzban не установлен после всех попыток. Лог: journalctl -u marzban -n 50"
    else
      err "Marzban not installed after all attempts. Log: journalctl -u marzban -n 50"
    fi
  fi
}

# ── SSL сертификат / SSL Certificate ─────────────────────────
step_ssl() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_SSL_RU"
  else
    step_title="$STEP_SSL"
  fi
  step "$step_title"

  # Проверка dev-режима
  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    step_ssl_dev
    return 0
  fi

  # Установка acme.sh через git clone с pinned commit (официальная рекомендация)
  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Устанавливаю acme.sh..."
  else
    info "Installing acme.sh..."
  fi

  mkdir -p /etc/acme.sh
  cd /etc/acme.sh || exit 1

  # Pinned commit для стабильной версии acme.sh (официальная рекомендация)
  # Для получения актуального стабильного тега:
  #   git ls-remote --tags https://github.com/acmesh-official/acme.sh.git | tail -1
  # Обновляйте acme_commit при выходе новых стабильных версий
  local acme_commit="REPLACE_WITH_STABLE_TAG"
  local acme_repo="https://github.com/acmesh-official/acme.sh.git"
  local git_install_success=false
  
  # Проверка: если тег не обновлён, предупреждаем
  if [[ "$acme_commit" == "REPLACE_WITH_STABLE_TAG" ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Git tag не настроен! Обновите acme_commit в install-steps-main.sh"
      info "Продолжаю установку без фиксации версии (небезопасно)..."
    else
      warn "Git tag not configured! Update acme_commit in install-steps-main.sh"
      info "Continuing installation without pinned version (insecure)..."
    fi
  fi
  
  if command -v git &>/dev/null; then
    if git clone "$acme_repo" >/dev/null 2>&1; then
      cd acme.sh || exit 1
      
      # Если тег не настроен (заглушка), используем последнюю версию
      if [[ "$acme_commit" == "REPLACE_WITH_STABLE_TAG" ]]; then
        if [[ "$LANG_NAME" == "Русский" ]]; then
          info "Использую последнюю версию из master ветки..."
        else
          info "Using latest version from master branch..."
        fi
        # Не делаем checkout, остаёмся на HEAD
      else
        # Checkout конкретного тега/commit
        if git checkout "$acme_commit" >/dev/null 2>&1; then
          if [[ "$LANG_NAME" == "Русский" ]]; then
            info "Checkout версии: ${acme_commit}"
          else
            info "Checked out version: ${acme_commit}"
          fi
        else
          if [[ "$LANG_NAME" == "Русский" ]]; then
            warn "Не удалось checkout ${acme_commit}, использую последнюю версию"
          else
            warn "Failed to checkout ${acme_commit}, using latest version"
          fi
        fi
      fi
      
      ./acme.sh --install >/dev/null 2>&1 || true
      git_install_success=true
    else
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Не удалось клонировать acme.sh, пробую curl метод..."
      else
        warn "Failed to clone acme.sh, trying curl method..."
      fi
      # Fallback: curl метод с предупреждением
      curl -sf https://get.acme.sh | sh >/dev/null 2>&1 || true
    fi
  else
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "git не установлен, пробую curl метод..."
    else
      warn "git not installed, trying curl method..."
    fi
    # Fallback: curl метод
    curl -sf https://get.acme.sh | sh >/dev/null 2>&1 || true
  fi

  # Запрос сертификата
  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Запрашиваю сертификат для ${DOMAIN}..."
  else
    info "Requesting certificate for ${DOMAIN}..."
  fi

  # Создание директории для сертификатов
  mkdir -p /var/lib/marzban/certs

  # Использование acme.sh для получения сертификата
  local acme_cmd="/root/.acme.sh/acme.sh"
  if [[ -f "$acme_cmd" ]]; then
    "$acme_cmd" --issue -d "$DOMAIN" --webroot /var/www/html --force 2>/dev/null || true
    "$acme_cmd" --installcert -d "$DOMAIN" \
      --key-file /var/lib/marzban/certs/key.pem \
      --fullchain-file /var/lib/marzban/certs/cert.pem 2>/dev/null || true
  fi

  # Проверка успешности
  if [[ -f "/var/lib/marzban/certs/cert.pem" ]] && [[ -f "/var/lib/marzban/certs/key.pem" ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      ok "SSL сертификат получен, автопродление настроено"
    else
      ok "SSL certificate obtained, auto-renewal configured"
    fi
  else
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Не удалось получить сертификат. Проверь A-запись: ${DOMAIN} → ${SERVER_IP}"
      info "Продолжаю установку без SSL..."
    else
      warn "Failed to obtain certificate. Check A record: ${DOMAIN} → ${SERVER_IP}"
      info "Continuing installation without SSL..."
    fi
  fi

  cd - >/dev/null || exit 1
}

# ── SSL для dev-режима / Self-signed SSL ─────────────────────
step_ssl_dev() {
  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "DEV-режим: Генерация самоподписного SSL сертификата..."
  else
    info "DEV mode: Generating self-signed SSL certificate..."
  fi

  # Установка домена по умолчанию для dev-режима
  DOMAIN="${DOMAIN:-dev.cubiveil.local}"
  LE_EMAIL="${LE_EMAIL:-admin@${DOMAIN}}"

  # Создание директории для сертификатов
  mkdir -p /var/lib/marzban/certs

  # Генерация самоподписного сертификата
  openssl req -x509 -nodes -days 36500 -newkey rsa:2048 \
    -keyout /var/lib/marzban/certs/key.pem \
    -out /var/lib/marzban/certs/cert.pem \
    -subj "/C=US/ST=Dev/L=Dev/O=Dev/CN=${DOMAIN}" \
    -addext "subjectAltName=DNS:${DOMAIN},IP:127.0.0.1" \
    >/dev/null 2>&1

  if [[ -f "/var/lib/marzban/certs/cert.pem" ]] && [[ -f "/var/lib/marzban/certs/key.pem" ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      ok "Самоподписной SSL сертификат сгенерирован (действует 100 лет)"
      warn "ВНИМАНИЕ: Браузеры будут показывать предупреждение о безопасности"
    else
      ok "Self-signed SSL certificate generated (valid for 100 years)"
      warn "WARNING: Browsers will show security warning"
    fi
  else
    if [[ "$LANG_NAME" == "Русский" ]]; then
      err "Не удалось сгенерировать самоподписной сертификат"
    else
      err "Failed to generate self-signed certificate"
    fi
  fi
}

# ── Конфигурация / Configuration ─────────────────────────────
step_configure() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="$STEP_CONFIGURE_RU"
  else
    step_title="$STEP_CONFIGURE"
  fi
  step "$step_title"

  # Создание директорий
  mkdir -p /etc/marzban
  mkdir -p /etc/sing-box

  # Генерация случайных паролей
  TROJAN_PASS=$(gen_random 32)
  SS_PASS=$(gen_random 32)

  # Конфигурация Marzban
  cat >/etc/marzban/.env <<EOF
MARZBAN_HOST="${DOMAIN:-dev.cubiveil.local}"
MARZBAN_PORT=${PANEL_PORT:-8080}
SSL_CERT_FILE="/var/lib/marzban/certs/cert.pem"
SSL_KEY_FILE="/var/lib/marzban/certs/key.pem"
EOF

  # Конфигурация Sing-box с 5 профилями
  cat >/etc/sing-box/config.json <<EOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "trojan",
      "tag": "trojan",
      "listen": "0.0.0.0",
      "listen_port": ${TROJAN_PORT:-10443},
      "users": [{"password": "${TROJAN_PASS}"}],
      "tls": {
        "enabled": true,
        "certificate_path": "/var/lib/marzban/certs/cert.pem",
        "key_path": "/var/lib/marzban/certs/key.pem"
      }
    },
    {
      "type": "shadowsocks",
      "tag": "shadowsocks",
      "listen": "0.0.0.0",
      "listen_port": ${SS_PORT:-20443},
      "method": "chacha20-ietf-poly1305",
      "password": "${SS_PASS}"
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Marzban .env настроен"
    ok "Sing-box шаблон с 5 профилями создан"
  else
    ok "Marzban .env configured"
    ok "Sing-box template with 5 profiles created"
  fi
}

# ── Завершение / Finish ──────────────────────────────────────
step_finish() {
  echo ""
  echo "══════════════════════════════════════════════════════════"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo "  ✅ CubiVeil установлен успешно! 🎉"
    echo "══════════════════════════════════════════════════════════"
    echo ""
    echo "URL панели:"
    echo "  https://${DOMAIN:-dev.cubiveil.local}:${PANEL_PORT:-8080}"
    echo ""
    echo "URL подписки:"
    echo "  https://${DOMAIN:-dev.cubiveil.local}:${SUB_PORT:-8081}/subscription"
    echo ""
    echo "Профили:"
    echo "  - Trojan"
    echo "  - Shadowsocks"
    echo "  - VLESS"
    echo "  - VMess"
    echo "  - Hysteria2"
    echo ""

    if [[ "${DEV_MODE:-false}" == "true" ]]; then
      warn "⚠  DEV-РЕЖИМ: Используется самоподписной SSL сертификат"
      warn "⚠  Браузеры будут показывать предупреждение о безопасности"
      warn "⚠  Не используйте в production!"
    fi

    echo ""
    echo "Следующие шаги:"
    echo "  1. Зайди в панель → создай пользователей"
    echo "  2. Subscription URL скопируй в Mihomo на роутере"
    echo "  3. Смени порт SSH, закрой 22 в ufw"
    echo "  4. Сохрани ключ age в безопасном месте!"
    echo ""
  else
    echo "  ✅ CubiVeil installed successfully! 🎉"
    echo "══════════════════════════════════════════════════════════"
    echo ""
    echo "Panel URL:"
    echo "  https://${DOMAIN:-dev.cubiveil.local}:${PANEL_PORT:-8080}"
    echo ""
    echo "Subscription URL:"
    echo "  https://${DOMAIN:-dev.cubiveil.local}:${SUB_PORT:-8081}/subscription"
    echo ""
    echo "Profiles:"
    echo "  - Trojan"
    echo "  - Shadowsocks"
    echo "  - VLESS"
    echo "  - VMess"
    echo "  - Hysteria2"
    echo ""

    if [[ "${DEV_MODE:-false}" == "true" ]]; then
      warn "⚠  DEV MODE: Self-signed SSL certificate in use"
      warn "⚠  Browsers will show security warning"
      warn "⚠  Do not use in production!"
    fi

    echo ""
    echo "Next steps:"
    echo "  1. Log in to panel → create users"
    echo "  2. Copy Subscription URL to Mihomo on router"
    echo "  3. Change SSH port, close 22 in ufw"
    echo "  4. Save age key in a secure location!"
    echo ""
  fi

  echo "══════════════════════════════════════════════════════════"
  echo ""
}
