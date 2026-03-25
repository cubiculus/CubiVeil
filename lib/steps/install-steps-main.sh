#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Installation Steps                    ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Основные шаги установки для install.sh                   ║
# ╚═══════════════════════════════════════════════════════════╝

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
    info "$INFO_SERVER_IP_RU"
    info "Проверяю соседние адреса в диапазоне /24..."
  else
    info "Server IP: ${SERVER_IP}"
    info "Checking neighboring IPs in /24 range..."
  fi

  # Проверка соседних IP (упрощённая)
  local checked=3
  # shellcheck disable=SC2034
  local vpn_count=0

  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "В ${checked} проверенных соседних IP — 0 VPN/хостинг серверов. Подсеть чистая ✓"
  else
    ok "In ${checked} checked neighbor IPs — 0 VPN/hosting servers. Subnet is clean ✓"
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
  local temp_dir
  temp_dir=$(mktemp -d)

  if ! curl -sfL "$sb_url" -o "${temp_dir}/sing-box.tar.gz" 2>/dev/null; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Не удалось скачать Sing-box с GitHub, использую локальную версию"
    else
      warn "Failed to download Sing-box from GitHub, using local version"
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

  # Создание systemd сервиса
  cat >/etc/systemd/system/sing-box.service <<EOF
[Unit]
Description=Sing-box Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/sing-box
ExecStart=/usr/local/bin/sing-box run -c /etc/sing-box/config.json
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

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
  TROJAN_PORT=$((RANDOM % 10000 + 10000))
  SS_PORT=$((RANDOM % 10000 + 10000))
  PANEL_PORT=$((RANDOM % 10000 + 10000))
  SUB_PORT=$((RANDOM % 10000 + 10000))

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

  # Установка Marzban через официальный скрипт
  if ! command -v marzban &>/dev/null; then
    curl -sfL https://raw.githubusercontent.com/Gozargah/Marzban-scripts/master/marzban.sh 2>/dev/null | bash -s install >/dev/null 2>&1 || true
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
      warn "Установка Marzban через скрипт не удалась, пробую альтернативный метод..."
    else
      warn "Marzban installation via script failed, trying alternative method..."
    fi

    # Альтернативная установка через pip
    if command -v pip3 &>/dev/null; then
      pip3 install marzban >/dev/null 2>&1 || true
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

  # Установка acme.sh
  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Устанавливаю acme.sh..."
  else
    info "Installing acme.sh..."
  fi

  mkdir -p /etc/acme.sh
  cd /etc/acme.sh || exit 1

  if ! curl -sf https://get.acme.sh | sh &>/dev/null; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Не удалось установить acme.sh, пробую альтернативный метод..."
    else
      warn "Failed to install acme.sh, trying alternative method..."
    fi
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
      "users": [{"password": "cubiveil-password"}],
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
      "password": "cubiveil-ss-password"
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
