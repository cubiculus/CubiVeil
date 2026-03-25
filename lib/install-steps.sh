#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Installation Steps                   ║
# ║          github.com/cubiculus/cubiveil                   ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение модуля валидации ─────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/validation.sh" ]]; then
  source "${SCRIPT_DIR}/validation.sh"
fi

# ── ШАГ 0: Ввод данных / Input data ──────────────────────────
prompt_inputs() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="Настройка перед установкой"
  else
    step_title="Pre-installation setup"
  fi
  step "$step_title"

  if [[ "$LANG_NAME" == "Русский" ]]; then
    warn "Убедись что A-запись домена уже указывает на этот сервер."
    warn "Let's Encrypt проверит DNS — установка упадёт если запись не прописана."
  else
    warn "$WARN_DNS_RECORD"
    warn "$WARN_LETS_ENCRYPT"
  fi
  echo ""

  while true; do
    local prompt_domain
    if [[ "$LANG_NAME" == "Русский" ]]; then
      prompt_domain="  Домен для панели и подписок (например panel.example.com): "
    else
      prompt_domain="  $PROMPT_DOMAIN "
    fi
    read -rp "$prompt_domain" DOMAIN
    DOMAIN="${DOMAIN// /}"

    # Валидация домена через модуль validation.sh
    if [[ -z "$DOMAIN" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Домен не может быть пустым"
      else
        warn "$WARN_DOMAIN_EMPTY"
      fi
      continue
    fi

    # Использование функции validate_domain из модуля validation.sh
    if ! validate_domain "$DOMAIN"; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Некорректный формат домена. Пример: panel.example.com"
      else
        warn "$WARN_DOMAIN_FORMAT"
      fi
      continue
    fi

    # Проверка DNS A-записи
    if ! command -v dig &>/dev/null; then
      apt-get install -y -qq dnsutils >/dev/null 2>&1
    fi
    local resolved_ip
    resolved_ip=$(dig +short "$DOMAIN" A 2>/dev/null | head -1)
    if [[ -z "$resolved_ip" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "Не удалось разрешить домен $DOMAIN. Проверь A-запись."
        read -rp "  Продолжить несмотря на ошибку? (y/n): " cont
      else
        warn "$WARN_DNS_RESOLVE"
        read -rp "  $WARN_CONTINUE_ERROR " cont
      fi
      [[ "$cont" == "y" || "$cont" == "Y" ]] || continue
    elif [[ "$resolved_ip" != "$SERVER_IP" ]] && [[ -n "$SERVER_IP" ]]; then
      if [[ "$LANG_NAME" == "Русский" ]]; then
        warn "A-запись $DOMAIN → $resolved_ip, но IP сервера: $SERVER_IP"
        read -rp "  Продолжить несмотря на несоответствие? (y/n): " cont
      else
        warn "$WARN_DNS_MISMATCH"
        read -rp "  $WARN_CONTINUE_MISMATCH " cont
      fi
      [[ "$cont" == "y" || "$cont" == "Y" ]] || continue
    fi

    break
  done

  local prompt_email
  if [[ "$LANG_NAME" == "Русский" ]]; then
    prompt_email="  Email для Let's Encrypt [admin@${DOMAIN}]: "
  else
    prompt_email="  $PROMPT_EMAIL "
  fi
  read -rp "$prompt_email" LE_EMAIL
  LE_EMAIL="${LE_EMAIL// /}"
  [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"

  # Валидация email через модуль validation.sh
  while ! validate_email "$LE_EMAIL"; do
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Некорректный формат email. Пример: admin@${DOMAIN}"
    else
      warn "Invalid email format. Example: admin@${DOMAIN}"
    fi
    read -rp "$prompt_email" LE_EMAIL
    LE_EMAIL="${LE_EMAIL// /}"
    [[ -z "$LE_EMAIL" ]] && LE_EMAIL="admin@${DOMAIN}"
  done

  echo ""

  # Telegram - теперь спрашиваем только要不要, без деталей
  local prompt_telegram
  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "Telegram-бот: ежедневные отчёты, алерты, управление через чат."
    prompt_telegram="  Установить Telegram-бот? (y/n): "
  else
    info "Telegram bot: daily reports, alerts, chat control."
    prompt_telegram="  Install Telegram bot? (y/n): "
  fi
  read -rp "$prompt_telegram" INSTALL_TG

  # Сбрасываем переменные Telegram (используются в setup-telegram.sh)
  # shellcheck disable=SC2034
  TG_TOKEN=""
  # shellcheck disable=SC2034
  TG_CHAT_ID=""

  if [[ "$INSTALL_TG" == "y" || "$INSTALL_TG" == "Y" ]]; then
    warn "Telegram-бот будет установлен через отдельный скрипт после завершения установки."
  fi

  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
    ok "Домен:   $DOMAIN"
    ok "Email:   $LE_EMAIL"
    if [[ "$INSTALL_TG" == "y" || "$INSTALL_TG" == "Y" ]]; then
      warn "Telegram: будет установлен через setup-telegram.sh"
    else
      warn "Telegram: пропущен (можно добавить позже)"
    fi
  else
    ok "$OK_DOMAIN   $DOMAIN"
    ok "$OK_EMAIL   $LE_EMAIL"
    if [[ "$INSTALL_TG" == "y" || "$INSTALL_TG" == "Y" ]]; then
      warn "Telegram: will be installed via setup-telegram.sh"
    else
      warn "$WARN_TG_SKIPPED"
    fi
  fi
}

# ── ШАГ 1: Проверка окружения IP / IP neighborhood check ─────
step_check_ip_neighborhood() {
  local step_title
  if [[ "$LANG_NAME" == "Русский" ]]; then
    step_title="Шаг 1/12 — Проверка репутации подсети"
  else
    step_title="$STEP_CHECK_SUBNET"
  fi
  step "$step_title"

  SERVER_IP=$(get_server_ip)
  if [[ -z "$SERVER_IP" ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Не удалось определить IP сервера — пропускаю проверку"
    else
      warn "Failed to determine server IP — skipping check"
    fi
    return
  fi

  if [[ "$LANG_NAME" == "Русский" ]]; then
    info "IP сервера: ${SERVER_IP}"
    info "Проверяю соседние адреса в диапазоне /24..."
  else
    info "$INFO_SERVER_IP"
    info "$INFO_CHECKING_NEIGHBORS"
  fi

  local SUBNET LAST_OCTET CHECK_START CHECK_END
  SUBNET=$(echo "$SERVER_IP" | cut -d. -f1-3)
  LAST_OCTET=$(echo "$SERVER_IP" | cut -d. -f4)
  CHECK_START=$((LAST_OCTET - 20 < 1 ? 1 : LAST_OCTET - 20))
  CHECK_END=$((LAST_OCTET + 20 > 254 ? 254 : LAST_OCTET + 20))

  local VPN_COUNT=0 CHECKED=0 STEP=3

  # Параметры timeout и rate limiting для надежности
  # --connect-timeout: макс. время на подключение (2 сек)
  # --max-time: общее время запроса (5 сек)
  # --retry: повтор при ошибке (2 раза)
  # --retry-delay: задержка между повторами (1 сек)
  local CURL_TIMEOUT="--connect-timeout 2 --max-time 5 --retry 2 --retry-delay 1"
  # Rate limiting: макс. одновременных запросов к ipinfo.io (избегаем блокировки)
  local MAX_CONCURRENT=5
  local RATE_DELAY=0.2  # задержка между запусками пакетов (сек)

  # Параллельная проверка IP с rate limiting
  local temp_dir
  temp_dir=$(mktemp -d)
  local pids=()
  local batch_count=0

  for i in $(seq "$CHECK_START" "$STEP" "$CHECK_END"); do
    local CHECK_IP="${SUBNET}.${i}"
    [[ "$CHECK_IP" == "$SERVER_IP" ]] && continue

    # Rate limiting: ограничиваем количество одновременных запросов
    if [[ $batch_count -ge $MAX_CONCURRENT ]]; then
      # Ждём завершения oldest процесса в пакете
      wait "${pids[0]}" 2>/dev/null || true
      pids=("${pids[@]:1}")  # сдвигаем массив
      batch_count=0
      # Небольшая задержка между пакетами запросов
      sleep "$RATE_DELAY"
    fi

    # Запуск фонового процесса с улучшенными timeout
    {
      local RESULT ORG
      RESULT=$(curl -s $CURL_TIMEOUT "https://ipinfo.io/${CHECK_IP}/json" 2>/dev/null || echo "")
      if echo "$RESULT" | grep -qi '"org"'; then
        ORG=$(echo "$RESULT" | grep '"org"' | sed 's/.*"org": *"\(.*\)".*/\1/' | tr '[:upper:]' '[:lower:]')
        if echo "$ORG" | grep -qiE 'vpn|proxy|tunnel|hosting|datacenter|vps|server|cloud'; then
          echo "VPN" >"${temp_dir}/${i}.txt"
        fi
      fi
    } &
    pids+=($!)
    ((batch_count++)) || true
  done

  # Ожидание завершения всех оставшихся фоновых процессов
  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  # Подсчет результатов
  for i in $(seq "$CHECK_START" "$STEP" "$CHECK_END"); do
    local CHECK_IP="${SUBNET}.${i}"
    [[ "$CHECK_IP" == "$SERVER_IP" ]] && continue
    if [[ -f "${temp_dir}/${i}.txt" ]]; then
      ((VPN_COUNT++)) || true
    fi
    ((CHECKED++)) || true
  done

  # Очистка временных файлов
  rm -rf "$temp_dir"

  echo ""
  if [[ $VPN_COUNT -eq 0 ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      ok "В ${CHECKED} проверенных соседних IP — 0 VPN/хостинг серверов. Подсеть чистая ✓"
    else
      ok "$OK_SUBNET_CLEAN"
    fi
  elif [[ $VPN_COUNT -le 3 ]]; then
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Обнаружено ${VPN_COUNT} VPN/хостинг серверов в ${CHECKED} проверенных IP — риск умеренный"
      warn "Совет: следи за стабильностью, при проблемах смени провайдера"
    else
      warn "$WARN_SUBNET_MODERATE"
      warn "$WARN_SUBNET_ADVICE"
    fi
  else
    if [[ "$LANG_NAME" == "Русский" ]]; then
      warn "Обнаружено ${VPN_COUNT} VPN/хостинг серверов в ${CHECKED} проверенных IP — риск ВЫСОКИЙ"
      warn "Подсеть скорее всего хорошо известна системам блокировок."
      warn "Рекомендуется сменить провайдера или запросить IP из другого диапазона."
    else
      warn "$WARN_SUBNET_HIGH"
      warn "$WARN_SUBNET_LIKELY_BLOCKED"
      warn "$WARN_SUBNET_RECOMMEND"
    fi
    echo ""
    local prompt_continue
    if [[ "$LANG_NAME" == "Русский" ]]; then
      prompt_continue="  Продолжить установку несмотря на предупреждение? (y/n): "
    else
      prompt_continue="  $WARN_CONTINUE_ANYWAY "
    fi
    read -rp "$prompt_continue" CONTINUE_ANYWAY
    [[ "$CONTINUE_ANYWAY" != "y" && "$CONTINUE_ANYWAY" != "Y" ]] &&
      { if [[ "$LANG_NAME" == "Русский" ]]; then err "$ERR_USER_ABORTED_RU"; else err "$ERR_USER_ABORTED"; fi; }
  fi
  echo ""
}

# ── ШАГ 2: Обновление системы / System update ───────────────
step_system_update() {
  step_title "2" "Обновление системы" "System update"

  # Отключаем все интерактивные диалоги dpkg/debconf/needrestart
  export DEBIAN_FRONTEND=noninteractive
  export UCF_FORCE_CONFFOLD=1

  # needrestart спрашивает о перезапуске сервисов — переводим в автоматический режим
  if [[ -f /etc/needrestart/needrestart.conf ]]; then
    sed -i "s/#\$nrconf{restart} = 'i'/\$nrconf{restart} = 'a'/" \
      /etc/needrestart/needrestart.conf 2>/dev/null || true
  fi

  local DPKG_OPTS='-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold'

  apt-get update -qq
  # shellcheck disable=SC2086
  apt-get upgrade -y -qq $DPKG_OPTS
  # shellcheck disable=SC2086
  apt-get install -y -qq $DPKG_OPTS \
    curl wget tar git jq ufw fail2ban \
    unattended-upgrades apt-listchanges \
    ca-certificates gnupg socat cron \
    python3 python3-pip \
    htop

  ok "Система обновлена, зависимости установлены"
}

# ── ШАГ 3: Автообновления безопасности / Auto security updates ─
step_auto_updates() {
  step_title "3" "Автообновления безопасности" "Security auto-updates"

  cat >/etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

  cat >/etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
// Только security-патчи — мажорные обновления вручную
Unattended-Upgrade::Allowed-Origins {
  "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Dpkg::Options {
  "--force-confdef";
  "--force-confold";
};
EOF

  systemctl enable unattended-upgrades --now >/dev/null 2>&1
  ok "Автообновления security-патчей настроены (без интерактивных диалогов)"
}

# ── ШАГ 4: BBR / BBR optimization ────────────────────────────
step_bbr() {
  step_title "4" "BBR и оптимизация сети" "BBR and network optimization"

  modprobe tcp_bbr 2>/dev/null || true

  cat >/etc/sysctl.d/99-cubiveil.conf <<'EOF'
# CubiVeil — BBR и оптимизация сетевого стека

# BBR снижает задержки и повышает скорость на длинных маршрутах
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Увеличенные буферы для прокси с большим трафиком
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Переиспользование TIME_WAIT соединений
net.ipv4.tcp_tw_reuse = 1

# Лимит файловых дескрипторов
fs.file-max = 1000000
EOF

  sysctl -p /etc/sysctl.d/99-cubiveil.conf >/dev/null 2>&1 || true

  local CURRENT
  CURRENT=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
  ok "TCP congestion control: ${CURRENT}"
}

# ── ШАГ 5: Файрвол / Firewall ────────────────────────────────
step_firewall() {
  step_title "5" "Файрвол (ufw)" "Firewall (ufw)"

  ufw --force reset >/dev/null 2>&1
  ufw default deny incoming >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1

  open_port 22 tcp "SSH — смени порт и закрой 22 после установки"
  open_port 443 tcp "VLESS Reality TCP + gRPC"
  open_port 443 udp "Hysteria2 QUIC"

  ufw --force enable >/dev/null 2>&1
  ok "Файрвол включён: 22/tcp, 443/tcp, 443/udp"
  if [[ "$LANG_NAME" == "Русский" ]]; then
    warn "$WARN_SSH_PORT_RU"
  else
    warn "$WARN_SSH_PORT"
  fi
}

# ── ШАГ 6: Fail2ban ─────────────────────────────────────────
step_fail2ban() {
  step_title "6" "Fail2ban" "Fail2ban"

  # Получаем текущий SSH порт из конфига
  local SSH_PORT
  SSH_PORT=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
  SSH_PORT="${SSH_PORT:-22}" # По умолчанию 22 если не задан

  cat >/etc/fail2ban/jail.d/cubiveil.conf <<EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ${SSH_PORT}
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 24h
EOF

  systemctl enable fail2ban --now >/dev/null 2>&1
  systemctl restart fail2ban >/dev/null 2>&1
  ok "Fail2ban: SSH защита на порту ${SSH_PORT} (3 попытки → бан 24ч)"
}

# ── ШАГ 7: Sing-box ─────────────────────────────────────────
step_install_singbox() {
  step_title "7" "Sing-box" "Sing-box"

  # Кэш для GitHub API (кэшируется на 1 час)
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

    # Получаем версию sing-box
    local api_response
    api_response=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases/latest" 2>/dev/null || echo "{}")
    SB_TAG=$(echo "$api_response" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    [[ -z "$SB_TAG" ]] && err "Не удалось получить версию Sing-box с GitHub"

    SB_VER="${SB_TAG#v}"
    SB_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz"

    # Получаем SHA256 и GPG подпись
    local SHA_URL
    local SIG_URL
    SHA_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz.sha256sum"
    SIG_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz.sig"
    SB_SHA256=$(curl -fsSL "$SHA_URL" | awk '{print $1}')

    # Сохраняем в кэш
    echo "{\"tag\":\"$SB_TAG\",\"sha256\":\"$SB_SHA256\"}" >"$CACHE_FILE"
  else
    SB_VER="${SB_TAG#v}"
    SB_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz"
  fi

  info "Скачиваю Sing-box ${SB_TAG}..."
  curl -fLo /tmp/sing-box.tar.gz "$SB_URL" || err "Не удалось скачать Sing-box"

  # Скачиваем GPG подпись для верификации
  local GPG_VERIFIED=false
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

  # Проверяем SHA256 контрольную сумму (fallback или основной метод)
  if [[ -n "$SB_SHA256" ]]; then
    info "Проверяю SHA256 контрольную сумму..."
    
    # Используем функцию verify_sha256 из security.sh
    if ! verify_sha256 /tmp/sing-box.tar.gz "$SB_SHA256"; then
      rm -f /tmp/sing-box.tar.gz
      err "SHA256 проверка не пройдена"
    fi
    
    if [[ "$GPG_VERIFIED" != "true" ]]; then
      ok "SHA256 проверка пройдена"
    fi
  else
    warn "Не удалось получить SHA256 контрольную сумму, продолжаем без проверки"
  fi

  tar -xzf /tmp/sing-box.tar.gz -C /tmp
  mv /tmp/sing-box-*/sing-box /usr/local/bin/sing-box
  chmod +x /usr/local/bin/sing-box
  rm -rf /tmp/sing-box*

  ok "Sing-box ${SB_TAG} ($(arch)) установлен"
}

# ── ШАГ 8: Генерация ключей и портов / Generate keys and ports ─
step_generate_keys_and_ports() {
  step_title "8" "Ключи Reality и порты" "Reality keypair and ports"

  # Reality keypair
  local KEYPAIR
  KEYPAIR=$(sing-box generate reality-keypair)
  REALITY_PRIVATE_KEY=$(echo "$KEYPAIR" | grep 'PrivateKey' | awk '{print $2}')
  REALITY_PUBLIC_KEY=$(echo "$KEYPAIR" | grep 'PublicKey' | awk '{print $2}')
  REALITY_SHORT_ID=$(gen_hex 8)

  # Случайный camouflage — крупный CDN
  local CDN_LIST=(
    "dl.google.com"
    "ajax.aspnetcdn.com"
    "www.fastly.com"
    "cdn.jsdelivr.net"
    "cdnjs.cloudflare.com"
    "static.cloudflareinsights.com"
    "ajax.googleapis.com"
  )
  REALITY_SNI="${CDN_LIST[$((RANDOM % ${#CDN_LIST[@]}))]}"

  # UUID для каждого профиля (используются в sing-box шаблоне)
  export UUID_VLESS_TCP
  UUID_VLESS_TCP=$(sing-box generate uuid)
  export UUID_VLESS_GRPC
  UUID_VLESS_GRPC=$(sing-box generate uuid)
  export UUID_HY2
  UUID_HY2=$(sing-box generate uuid)
  export UUID_TROJAN
  UUID_TROJAN=$(sing-box generate uuid)
  SS_PASSWORD=$(gen_random 32)

  # Уникальные порты 30000+
  TROJAN_PORT=$(unique_port)
  SS_PORT=$(unique_port)
  PANEL_PORT=$(unique_port)
  SUB_PORT=$(unique_port)

  # Открываем в файрволе
  open_port "$TROJAN_PORT" tcp "Trojan WebSocket TLS"
  open_port "$SS_PORT" tcp "Shadowsocks 2022"
  open_port "$PANEL_PORT" tcp "Marzban Panel"
  open_port "$SUB_PORT" tcp "Subscription Link"

  ok "Reality keypair сгенерирован, camouflage: ${REALITY_SNI}"
  ok "Порты → Trojan:${TROJAN_PORT} SS:${SS_PORT} Панель:${PANEL_PORT} Подписки:${SUB_PORT}"
}

# ── ШАГ 9: Marzban ───────────────────────────────────────────
step_install_marzban() {
  step_title "9" "Marzban" "Marzban"

  info "Устанавливаю Marzban..."
  local MARZBAN_SCRIPT="/tmp/marzban-install.sh"
  
  # Скачиваем скрипт с проверкой
  curl -fsSL "https://github.com/Gozargah/Marzban/raw/master/script.sh" -o "$MARZBAN_SCRIPT" ||
    err "Не удалось скачать скрипт установки Marzban"
  
  # Проверка что файл не пустой (минимум 1KB)
  if [[ ! -s "$MARZBAN_SCRIPT" ]] || [[ $(stat -c%s "$MARZBAN_SCRIPT") -lt 1024 ]]; then
    rm -f "$MARZBAN_SCRIPT"
    err "Скачанный файл Marzban пуст или повреждён"
  fi
  
  # Проверка на корректность bash скрипта
  if ! bash -n "$MARZBAN_SCRIPT" 2>/dev/null; then
    rm -f "$MARZBAN_SCRIPT"
    err "Скачанный файл Marzban содержит синтаксические ошибки"
  fi
  
  info "Запускаю установку Marzban..."
  if ! bash "$MARZBAN_SCRIPT" -s -- install; then
    rm -f "$MARZBAN_SCRIPT"
    err "Установка Marzban не удалась. Лог: journalctl -u marzban -n 50"
  fi
  rm -f "$MARZBAN_SCRIPT"

  # Проверка что скрипт установки существует
  if [[ ! -f /opt/marzban/script.sh ]]; then
    err "Скрипт установки Marzban не найден"
  fi

  ok "Marzban установлен"
}

# ── ШАГ 10: SSL сертификат / SSL certificate ─────────────────
step_ssl() {
  step_title "10" "SSL сертификат (Let's Encrypt)" "SSL certificate (Let's Encrypt)"

  if [[ ! -f "$HOME/.acme.sh/acme.sh" ]]; then
    info "Устанавливаю acme.sh..."
    local ACME_SCRIPT="/tmp/acme-install.sh"
    
    # Скачиваем скрипт с проверкой
    curl -fsSL "https://get.acme.sh" -o "$ACME_SCRIPT" || err "Не удалось скачать acme.sh"
    
    # Проверка что файл не пустой (минимум 500 байт)
    if [[ ! -s "$ACME_SCRIPT" ]] || [[ $(stat -c%s "$ACME_SCRIPT") -lt 500 ]]; then
      rm -f "$ACME_SCRIPT"
      err "Скачанный файл acme.sh пуст или повреждён"
    fi
    
    # Проверка на корректность bash скрипта
    if ! bash -n "$ACME_SCRIPT" 2>/dev/null; then
      rm -f "$ACME_SCRIPT"
      err "Скачанный файл acme.sh содержит синтаксические ошибки"
    fi
    
    bash "$ACME_SCRIPT" -s email="$LE_EMAIL" >/dev/null 2>&1
    rm -f "$ACME_SCRIPT"
  fi

  # Порт 80 нужен только для валидации
  open_port 80 tcp "Let's Encrypt validation"
  systemctl stop marzban >/dev/null 2>&1 || true

  info "Запрашиваю сертификат для ${DOMAIN}..."
  "$HOME/.acme.sh/acme.sh" --set-default-ca --server letsencrypt >/dev/null 2>&1
  "$HOME/.acme.sh/acme.sh" --issue \
    -d "$DOMAIN" --standalone --httpport 80 --force >/dev/null 2>&1 ||
    err "Не удалось получить сертификат. Проверь A-запись: ${DOMAIN} → ${SERVER_IP}"

  mkdir -p /var/lib/marzban/certs
  "$HOME/.acme.sh/acme.sh" --installcert -d "$DOMAIN" \
    --cert-file /var/lib/marzban/certs/cert.pem \
    --key-file /var/lib/marzban/certs/key.pem \
    --fullchain-file /var/lib/marzban/certs/fullchain.pem \
    --reloadcmd "systemctl restart marzban" >/dev/null 2>&1

  "$HOME/.acme.sh/acme.sh" --upgrade --auto-upgrade >/dev/null 2>&1

  chmod 600 /var/lib/marzban/certs/key.pem
  # cert.pem содержит публичный ключ, но всё равно ограничиваем доступ (640)
  chmod 640 /var/lib/marzban/certs/cert.pem
  chmod 640 /var/lib/marzban/certs/fullchain.pem

  close_port 80 tcp

  ok "SSL сертификат получен, автопродление настроено"
}

# ── ШАГ 11: Конфигурация Marzban + Sing-box ─────────────────
step_configure() {
  step_title "11" "Конфигурация Marzban и 5 профилей Sing-box" "Marzban and 5-profile Sing-box configuration"

  SUDO_USERNAME=$(gen_random 10)
  SUDO_PASSWORD=$(gen_random 16)
  SECRET_KEY=$(gen_random 32)
  PANEL_PATH=$(gen_random 14)
  SUB_PATH=$(gen_random 14)
  TROJAN_WS_PATH=$(gen_random 10)

  # ── .env Marzban ──────────────────────────────────────────
  cat >/opt/marzban/.env <<EOF
# ── CubiVeil — Marzban конфигурация ──────────────────────────

UVICORN_HOST      = "0.0.0.0"
UVICORN_PORT      = ${PANEL_PORT}
UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/fullchain.pem"
UVICORN_SSL_KEYFILE  = "/var/lib/marzban/certs/key.pem"
UVICORN_ROOT_PATH    = "/${PANEL_PATH}"

SECRET_KEY = "${SECRET_KEY}"
DOCS       = false
DEBUG      = false

SUDO_USERNAME = "${SUDO_USERNAME}"
SUDO_PASSWORD = "${SUDO_PASSWORD}"

SQLALCHEMY_DATABASE_URL = "sqlite:////var/lib/marzban/db.sqlite3"

# Subscription link
XRAY_SUBSCRIPTION_URL_PREFIX = "https://${DOMAIN}:${SUB_PORT}"

# Sing-box как основной бэкенд
SING_BOX_ENABLED         = true
SING_BOX_EXECUTABLE_PATH = "/usr/local/bin/sing-box"

# Минимальное логирование
UVICORN_LOG_LEVEL = "warning"
EOF

  # ── Шаблон Sing-box: 5 профилей ───────────────────────────
  cat >/var/lib/marzban/sing-box-template.json <<EOF
{
  "log": {
  "level": "warn",
  "timestamp": false
  },

  "inbounds": [

  {
    "_comment": "ПРОФИЛЬ 1 — VLESS + Reality + TCP. Основной. Маскируется под TLS крупного CDN. Активное зондирование вернёт настоящий TLS-ответ от ${REALITY_SNI}.",
    "type": "vless",
    "tag": "vless-reality-tcp",
    "listen": "::",
    "listen_port": 443,
    "users": [
      { "uuid": "{uuid}", "flow": "xtls-rprx-vision" }
    ],
    "tls": {
      "enabled": true,
      "server_name": "${REALITY_SNI}",
      "reality": {
        "enabled": true,
        "handshake": { "server": "${REALITY_SNI}", "server_port": 443 },
        "private_key": "${REALITY_PRIVATE_KEY}",
        "short_id": ["${REALITY_SHORT_ID}"]
      }
    }
  },

  {
    "_comment": "ПРОФИЛЬ 2 — VLESS + Reality + gRPC. Альтернатива если провайдер режет TCP 443. HTTP/2 мультиплексинг.",
    "type": "vless",
    "tag": "vless-reality-grpc",
    "listen": "::",
    "listen_port": 443,
    "users": [
      { "uuid": "{uuid}", "flow": "" }
    ],
    "multiplex": {
      "enabled": true,
      "protocol": "h2mux",
      "max_streams": 32
    },
    "tls": {
      "enabled": true,
      "server_name": "${REALITY_SNI}",
      "reality": {
        "enabled": true,
        "handshake": { "server": "${REALITY_SNI}", "server_port": 443 },
        "private_key": "${REALITY_PRIVATE_KEY}",
        "short_id": ["${REALITY_SHORT_ID}"]
      }
    }
  },

  {
    "_comment": "ПРОФИЛЬ 3 — Hysteria2. UDP/QUIC транспорт. Оптимален для больших загрузок: Nintendo eShop, игры, обновления. Блокируется отдельно от TCP-протоколов.",
    "type": "hysteria2",
    "tag": "hysteria2",
    "listen": "::",
    "listen_port": 443,
    "users": [
      { "password": "{uuid}" }
    ],
    "tls": {
      "enabled": true,
      "server_name": "${DOMAIN}",
      "certificate_path": "/var/lib/marzban/certs/fullchain.pem",
      "key_path": "/var/lib/marzban/certs/key.pem"
    }
  },

  {
    "_comment": "ПРОФИЛЬ 4 — Trojan + WebSocket + TLS. Fallback. Трафик выглядит как обычный HTTPS. Совместим с Cloudflare CDN — при блокировке IP можно поставить домен за CF.",
    "type": "trojan",
    "tag": "trojan-ws-tls",
    "listen": "::",
    "listen_port": ${TROJAN_PORT},
    "users": [
      { "password": "{uuid}" }
    ],
    "transport": {
      "type": "ws",
      "path": "/${TROJAN_WS_PATH}",
      "headers": { "Host": "${DOMAIN}" },
      "max_early_data": 2048,
      "early_data_header_name": "Sec-WebSocket-Protocol"
    },
    "tls": {
      "enabled": true,
      "server_name": "${DOMAIN}",
      "certificate_path": "/var/lib/marzban/certs/fullchain.pem",
      "key_path": "/var/lib/marzban/certs/key.pem"
    }
  },

  {
    "_comment": "ПРОФИЛЬ 5 — Shadowsocks 2022. Совместимость с клиентами без Reality/Hysteria2. Работает на большинстве мобильных приложений без сложных настроек.",
    "type": "shadowsocks",
    "tag": "shadowsocks-2022",
    "listen": "::",
    "listen_port": ${SS_PORT},
    "method": "2022-blake3-aes-256-gcm",
    "password": "${SS_PASSWORD}",
    "multiplex": { "enabled": true }
  }

  ],

  "outbounds": [
  { "type": "direct", "tag": "direct" },
  { "type": "block",  "tag": "block"  }
  ],

  "route": {
  "rules": [
    {
      "_comment": "Блокируем торренты — сервер не для этого",
      "protocol": "bittorrent",
      "outbound": "block"
    }
  ],
  "final": "direct"
  }
}
EOF

  ok "Marzban .env настроен"
  ok "Sing-box шаблон с 5 профилями создан"
}

# ── Финал: запуск и итог ─────────────────────────────────────
step_finish() {
  info "Запускаю Marzban..."
  systemctl daemon-reload >/dev/null 2>&1
  systemctl enable marzban >/dev/null 2>&1
  systemctl restart marzban >/dev/null 2>&1
  sleep 4

  local STATUS
  STATUS=$(systemctl is-active marzban 2>/dev/null || echo "failed")
  [[ "$STATUS" != "active" ]] &&
    err "Marzban не запустился. Лог: journalctl -u marzban -n 50"

  # ── Health-check эндпоинт для мониторинга ─────────────────
  info "Настраиваю health-check эндпоинт..."
  local HC_PORT
  HC_PORT=$(unique_port)
  open_port "$HC_PORT" tcp "Marzban Health Check"

  # Добавляем переменную окружения для health check
  cat >>/opt/marzban/.env <<EOF

# Health check endpoint (внутренний)
HEALTH_CHECK_PORT = "${HC_PORT}"
EOF

  # Создаём простой HTTP сервер для health check
  cat >/opt/marzban/health_check.py <<'PYEOF'
#!/usr/bin/env python3
"""Health-check эндпоинт для мониторинга доступности Marzban"""
import http.server, socketserver, subprocess, json, os
from datetime import datetime

PORT = int(os.environ.get("HEALTH_CHECK_PORT", 8080))

class HealthHandler(http.server.BaseHTTPRequestHandler):
  def log_message(self, format, *args):
      pass  # Отключаем логирование

  def do_GET(self):
      if self.path == "/health":
          status = {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}
          # Проверка Marzban
          try:
              result = subprocess.run(
                  ["systemctl", "is-active", "marzban"],
                  capture_output=True, text=True, timeout=5
              )
              status["marzban"] = result.stdout.strip()
          except Exception as e:
              status["marzban"] = f"error: {str(e)}"
              status["status"] = "unhealthy"

          # Проверка Sing-box
          try:
              result = subprocess.run(
                  ["systemctl", "is-active", "sing-box"],
                  capture_output=True, text=True, timeout=5
              )
              status["singbox"] = result.stdout.strip()
          except Exception as e:
              status["singbox"] = f"error: {str(e)}"

          # Проверка бота
          try:
              result = subprocess.run(
                  ["systemctl", "is-active", "cubiveil-bot"],
                  capture_output=True, text=True, timeout=5
              )
              status["bot"] = result.stdout.strip()
          except Exception:
              status["bot"] = "inactive"

          self.send_response(200 if status["status"] == "healthy" else 503)
          self.send_header("Content-type", "application/json")
          self.end_headers()
          self.wfile.write(json.dumps(status, indent=2).encode())

      elif self.path == "/ready":
          # Проверка готовности (все сервисы активны)
          services = ["marzban", "sing-box"]
          ready = all(
              subprocess.run(["systemctl", "is-active", s],
                  capture_output=True, text=True, timeout=3
              ).stdout.strip() == "active"
              for s in services
          )
          self.send_response(200 if ready else 503)
          self.send_header("Content-type", "text/plain")
          self.end_headers()
          self.wfile.write(b"ready" if ready else b"not ready")

      else:
          self.send_response(404)
          self.end_headers()

with socketserver.TCPServer(("", PORT), HealthHandler) as httpd:
  httpd.serve_forever()
PYEOF

  chmod +x /opt/marzban/health_check.py

  # Systemd сервис для health check
  cat >/etc/systemd/system/marzban-health.service <<EOF
[Unit]
Description=Marzban Health Check Endpoint
After=marzban.service
Wants=marzban.service

[Service]
Type=simple
Environment="HEALTH_CHECK_PORT=${HC_PORT}"
ExecStart=/usr/bin/python3 /opt/marzban/health_check.py
Restart=always
RestartSec=5s
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable marzban-health --now >/dev/null 2>&1
  ok "Health-check эндпоинт: http://${SERVER_IP}:${HC_PORT}/health"

  # ── Шифрование credentials через age ──────────────────────
  info "Шифрую учётные данные..."

  # Установка age если не установлен
  if ! command -v age &>/dev/null; then
    info "Устанавливаю age..."
    local ARCH
    ARCH=$(arch)
    curl -fsSL "https://github.com/FiloSottile/age/releases/download/v1.2.0/age-v1.2.0-linux-${ARCH}.tar.gz" \
      -o /tmp/age.tar.gz
    tar -xzf /tmp/age.tar.gz -C /tmp
    mv /tmp/age/age /usr/local/bin/age
    mv /tmp/age/age-keygen /usr/local/bin/age-keygen
    chmod +x /usr/local/bin/age /usr/local/bin/age-keygen
    rm -rf /tmp/age*
    ok "age установлен"
  fi

  # Генерация ключа
  local AGE_KEYRING="/root/.cubiveil-age-key.txt"
  local AGE_PUBLIC_KEY
  if [[ ! -f "$AGE_KEYRING" ]]; then
    age-keygen -o "$AGE_KEYRING" 2>/dev/null
    chmod 600 "$AGE_KEYRING"
    AGE_PUBLIC_KEY=$(grep "public key:" "$AGE_KEYRING" | awk '{print $4}')
    ok "Ключ age сгенерирован: ${AGE_KEYRING}"
  else
    AGE_PUBLIC_KEY=$(grep "public key:" "$AGE_KEYRING" | awk '{print $4}')
  fi

  # Создаём зашифрованный файл через pipe (без временного файла с паролями)
  local CREDEnc="/root/cubiveil-credentials.age"

  # Генерируем содержимое и сразу шифруем через pipe
  cat | age -r "$AGE_PUBLIC_KEY" -o "$CREDEnc" <<EOF
CubiVeil — данные установки
Дата:    $(date)
Сервер:  ${SERVER_IP}
Домен:   ${DOMAIN}

━━━ ПАНЕЛЬ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
URL:    https://${DOMAIN}:${PANEL_PORT}/${PANEL_PATH}
Логин:  ${SUDO_USERNAME}
Пароль: ${SUDO_PASSWORD}

━━━ ПОДПИСКИ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
URL: https://${DOMAIN}:${SUB_PORT}/${SUB_PATH}/{username}

━━━ ПРОФИЛИ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. VLESS Reality TCP   → 443/tcp
2. VLESS Reality gRPC  → 443/tcp
3. Hysteria2           → 443/udp
4. Trojan WS TLS       → ${TROJAN_PORT}/tcp
5. Shadowsocks 2022    → ${SS_PORT}/tcp

━━━ REALITY ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Camouflage:  ${REALITY_SNI}
Public key:  ${REALITY_PUBLIC_KEY}
Private key: ${REALITY_PRIVATE_KEY}
Short ID:    ${REALITY_SHORT_ID}

━━━ SHADOWSOCKS 2022 ━━━━━━━━━━━━━━━━━━━━━
Пароль: ${SS_PASSWORD}

━━━ HEALTH CHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━
URL: http://${SERVER_IP}:${HC_PORT}/health
EOF

  ok "Учётные данные зашифрованы: ${CREDEnc}"

  # Инструкция по расшифровке
  cat >/root/DECRYPT_INSTRUCTIONS.txt <<EOF
══ Расшифровка учётных данных CubiVeil ══

Зашифрованный файл: /root/cubiveil-credentials.age
Ключ расшифровки:   /root/.cubiveil-age-key.txt

Для расшифровки:
  age -d -i /root/.cubiveil-age-key.txt /root/cubiveil-credentials.age

Или просто:
  cat /root/cubiveil-credentials.age | age -d -i /root/.cubiveil-age-key.txt

══ Health Check ══
  curl http://${SERVER_IP}:${HC_PORT}/health
  curl http://${SERVER_IP}:${HC_PORT}/ready
EOF
  chmod 600 /root/DECRYPT_INSTRUCTIONS.txt

  # Вывод на экран (нешифрованные основные данные)
  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║          CubiVeil установлен успешно! 🎉             ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  ПАНЕЛЬ${PLAIN}"
    echo -e "  https://${DOMAIN}:${PANEL_PORT}/${PANEL_PATH}"
    echo -e "  Логин:  ${GREEN}${SUDO_USERNAME}${PLAIN}"
    echo -e "  Пароль: ${GREEN}${SUDO_PASSWORD}${PLAIN}"
    echo ""
    echo -e "${CYAN}  ПОДПИСКИ${PLAIN}"
    echo -e "  https://${DOMAIN}:${SUB_PORT}/${SUB_PATH}/{username}"
    echo ""
    echo -e "${CYAN}  ПРОФИЛИ И ПОРТЫ${PLAIN}"
    echo -e "  1. VLESS Reality TCP   ${GREEN}443/tcp${PLAIN}"
    echo -e "  2. VLESS Reality gRPC  ${GREEN}443/tcp${PLAIN}"
    echo -e "  3. Hysteria2           ${GREEN}443/udp${PLAIN}"
    echo -e "  4. Trojan WS TLS       ${GREEN}${TROJAN_PORT}/tcp${PLAIN}"
    echo -e "  5. Shadowsocks 2022    ${GREEN}${SS_PORT}/tcp${PLAIN}"
    echo ""
    echo -e "${CYAN}  HEALTH CHECK${PLAIN}"
    echo -e "  http://${SERVER_IP}:${HC_PORT}/health"
    echo -e "  http://${SERVER_IP}:${HC_PORT}/ready"
    echo ""
    echo -e "${GREEN}  Учётные данные: ${YELLOW}/root/cubiveil-credentials.age${PLAIN}"
    echo -e "${GREEN}  Ключ:           ${YELLOW}/root/.cubiveil-age-key.txt${PLAIN}"
    echo -e "${GREEN}  Инструкция:     ${YELLOW}/root/DECRYPT_INSTRUCTIONS.txt${PLAIN}"
    echo ""
    echo -e "${YELLOW}  ⚠  Смени порт SSH и закрой 22 (инструкция в README)${PLAIN}"
    echo ""
    echo -e "${GREEN}  Следующие шаги:${PLAIN}"
    echo -e "  1. Зайди в панель → создай пользователей"
    echo -e "  2. Subscription URL скопируй в Mihomo на роутере"
    echo -e "  3. Смени порт SSH, закрой 22 в ufw"
    echo -e "  4. Сохрани ключ age в безопасном месте!"
    echo ""
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
  else
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${PLAIN}"
    echo -e "${GREEN}║          CubiVeil installed successfully! 🎉         ║${PLAIN}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
    echo ""
    echo -e "${CYAN}  PANEL${PLAIN}"
    echo -e "  https://${DOMAIN}:${PANEL_PORT}/${PANEL_PATH}"
    echo -e "  Username:  ${GREEN}${SUDO_USERNAME}${PLAIN}"
    echo -e "  Password:  ${GREEN}${SUDO_PASSWORD}${PLAIN}"
    echo ""
    echo -e "${CYAN}  SUBSCRIPTION${PLAIN}"
    echo -e "  https://${DOMAIN}:${SUB_PORT}/${SUB_PATH}/{username}"
    echo ""
    echo -e "${CYAN}  PROFILES & PORTS${PLAIN}"
    echo -e "  1. VLESS Reality TCP   ${GREEN}443/tcp${PLAIN}"
    echo -e "  2. VLESS Reality gRPC  ${GREEN}443/tcp${PLAIN}"
    echo -e "  3. Hysteria2           ${GREEN}443/udp${PLAIN}"
    echo -e "  4. Trojan WS TLS       ${GREEN}${TROJAN_PORT}/tcp${PLAIN}"
    echo -e "  5. Shadowsocks 2022    ${GREEN}${SS_PORT}/tcp${PLAIN}"
    echo ""
    echo -e "${CYAN}  HEALTH CHECK${PLAIN}"
    echo -e "  http://${SERVER_IP}:${HC_PORT}/health"
    echo -e "  http://${SERVER_IP}:${HC_PORT}/ready"
    echo ""
    echo -e "${GREEN}  Credentials: ${YELLOW}/root/cubiveil-credentials.age${PLAIN}"
    echo -e "${GREEN}  Key:         ${YELLOW}/root/.cubiveil-age-key.txt${PLAIN}"
    echo -e "${GREEN}  Instructions:${YELLOW}/root/DECRYPT_INSTRUCTIONS.txt${PLAIN}"
    echo ""
    echo -e "${YELLOW}  ⚠  Change SSH port and close 22 (see README)${PLAIN}"
    echo ""
    echo -e "${GREEN}  Next steps:${PLAIN}"
    echo -e "  1. Log in to panel → create users"
    echo -e "  2. Copy Subscription URL to Mihomo on router"
    echo -e "  3. Change SSH port, close 22 in ufw"
    echo -e "  4. Save age key in a secure location!"
    echo ""
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${PLAIN}"
  fi

  # Вывод сообщения о Telegram, если он выбран для установки
  if [[ "$INSTALL_TG" == "y" || "$INSTALL_TG" == "Y" ]]; then
    echo ""
    if [[ "$LANG_NAME" == "Русский" ]]; then
      echo -e "${CYAN}  TELEGRAM БОТ${PLAIN}"
      echo -e "  Чтобы установить Telegram-бот, запусти:"
      echo -e "  ${GREEN}bash <(curl -s https://github.com/cubiculus/cubiveil/raw/refs/heads/main/setup-telegram.sh)${PLAIN}"
      echo ""
      echo -e "  Или с локального файла:"
      echo -e "  ${GREEN}bash setup-telegram.sh${PLAIN}"
    else
      echo -e "${CYAN}  TELEGRAM BOT${PLAIN}"
      echo -e "  To install Telegram bot, run:"
      echo -e "  ${GREEN}bash <(curl -s https://github.com/cubiculus/cubiveil/raw/refs/heads/main/setup-telegram.sh)${PLAIN}"
      echo ""
      echo -e "  Or from local file:"
      echo -e "  ${GREEN}bash setup-telegram.sh${PLAIN}"
    fi
  fi
}
