#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║                        CubiVeil                           ║
# ║         github.com/cubiculus/cubiveil                     ║
# ║                                                           ║
# ║  Marzban + Sing-box | 5 profiles | Telegram bot           ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/lang.sh" ]]; then
  # Временная установка языка по умолчанию (будет изменено после выбора)
  LANG_NAME="Русский"
  source "${SCRIPT_DIR}/lang.sh"
else
  # Fallback если файл локализации отсутствует
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
  BLUE='\033[0;34m'; CYAN='\033[0;36m'; PLAIN='\033[0m'
  ok()   { echo -e "${GREEN}[✓]${PLAIN} $1"; }
  warn() { echo -e "${YELLOW}[!]${PLAIN} $1"; }
  err()  { echo -e "${RED}[✗]${PLAIN} $1"; exit 1; }
  info() { echo -e "${CYAN}[→]${PLAIN} $1"; }
  step() {
      echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
      echo -e "${BLUE}  $1${PLAIN}"
      echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${PLAIN}"
  }
fi

# ── Проверки ───────────────────────────────────────────────────
check_root
check_ubuntu
command -v curl &>/dev/null || apt-get install -y -qq curl

# ── Вспомогательные функции ────────────────────────────────────
gen_random() { LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$1" | head -n 1; }
gen_hex()    { LC_ALL=C tr -dc 'a-f0-9'    </dev/urandom | fold -w "$1" | head -n 1; }
gen_port()   { shuf -i 30000-62000 -n 1; }

USED_PORTS=(443)
unique_port() {
  local p
  local max_attempts=50
  local attempts=0
  while [[ $attempts -lt $max_attempts ]]; do
      p=$(gen_port)
      # Проверка: не используется ли порт в списке и не занят ли процессом
      if [[ ! " ${USED_PORTS[*]} " =~ ${p} ]] && \
         ! ss -tlnp 2>/dev/null | grep -q ":${p} "; then
          USED_PORTS+=("$p")
          echo "$p"
          return
      fi
      ((attempts++))
  done
  err "Не удалось найти свободный порт после ${max_attempts} попыток"
}

arch() {
  case "$(uname -m)" in
      x86_64|amd64)  echo 'amd64' ;;
      aarch64|arm64) echo 'arm64' ;;
      *) err "Неизвестная архитектура: $(uname -m)" ;;
  esac
}

get_server_ip() {
  local ip
  for url in https://api4.ipify.org https://ipv4.icanhazip.com https://4.ident.me; do
      ip=$(curl -s --max-time 4 "$url" 2>/dev/null | tr -d '[:space:]')
      [[ -n "$ip" ]] && echo "$ip" && return
  done
  echo ""
}

open_port() {
  local port="$1"
  local proto="${2:-tcp}"
  local comment="${3:-cubiveil}"
  if ! ufw allow "${port}/${proto}" comment "${comment}" >/dev/null 2>&1; then
      # Пробуем без comment (некоторые версии ufw не поддерживают)
      if ! ufw allow "${port}/${proto}" >/dev/null 2>&1; then
          err "Не удалось открыть порт ${port}/${proto} в файрволе"
      fi
  fi
}

# ── Баннер ─────────────────────────────────────────────────────
print_banner() {
  clear
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${PLAIN}"
  echo -e "${CYAN}  ║            CubiVeil Installer            ║${PLAIN}"
  echo -e "${CYAN}  ║    github.com/cubiculus/cubiveil         ║${PLAIN}"
  echo -e "${CYAN}  ║    Marzban + Sing-box + Telegram бот     ║${PLAIN}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${PLAIN}"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# ШАГ 0: Ввод данных / Input data
# ══════════════════════════════════════════════════════════════
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

      # Более строгая валидация домена
      if [[ -z "$DOMAIN" ]]; then
          if [[ "$LANG_NAME" == "Русский" ]]; then
              warn "Домен не может быть пустым"
          else
              warn "$WARN_DOMAIN_EMPTY"
          fi
          continue
      fi

      # Проверка формата: только буквы, цифры, дефис, точка; хотя бы одна точка; TLD 2+ символов
      if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ ]]; then
          if [[ "$LANG_NAME" == "Русский" ]]; then
              warn "Некорректный формат домена. Пример: panel.example.com"
          else
              warn "$WARN_DOMAIN_FORMAT"
          fi
          continue
      fi

      # Проверка на внутренние IP/домены (защита от SSRF)
      if [[ "$DOMAIN" =~ ^localhost$ ]] || \
         [[ "$DOMAIN" =~ \.local$ ]] || \
         [[ "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
          if [[ "$LANG_NAME" == "Русский" ]]; then
              warn "Домен не должен быть внутренним (localhost, .local, IP-адрес)"
          else
              warn "$WARN_DOMAIN_INTERNAL"
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

  echo ""
  
  local info_tg prompt_token
  if [[ "$LANG_NAME" == "Русский" ]]; then
      info_tg="Telegram-бот: нужен токен от @BotFather и твой chat_id (узнать: @userinfobot)."
      prompt_token="  Telegram Bot Token (Enter — пропустить): "
  else
      info_tg="$INFO_TG_BOT"
      prompt_token="  $PROMPT_TG_TOKEN "
  fi
  info "$info_tg"
  read -rp "$prompt_token" TG_TOKEN
  TG_TOKEN="${TG_TOKEN// /}"

  # Валидация формата токена Telegram
  if [[ -n "$TG_TOKEN" ]]; then
      if [[ ! "$TG_TOKEN" =~ ^[0-9]+:[A-Za-z0-9_-]{35}$ ]]; then
          if [[ "$LANG_NAME" == "Русский" ]]; then
              err "Некорректный формат токена Telegram. Ожидается: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
          else
              err "$ERR_TG_TOKEN_FORMAT"
          fi
      fi
      # Проверка валидности токена через API
      if ! curl -sf --max-time 5 "https://api.telegram.org/bot${TG_TOKEN}/getMe" >/dev/null 2>&1; then
          if [[ "$LANG_NAME" == "Русский" ]]; then
              err "Токен Telegram недействителен. Проверь токен от @BotFather"
          else
              err "$ERR_TG_TOKEN_INVALID"
          fi
      fi
      if [[ "$LANG_NAME" == "Русский" ]]; then
          ok "Токен Telegram проверен ✓"
      else
          ok "$OK_TG_TOKEN_VERIFIED"
      fi

      local prompt_chat_id
      if [[ "$LANG_NAME" == "Русский" ]]; then
          prompt_chat_id="  Telegram Chat ID: "
      else
          prompt_chat_id="  $PROMPT_TG_CHAT_ID "
      fi
      read -rp "$prompt_chat_id" TG_CHAT_ID
      TG_CHAT_ID="${TG_CHAT_ID// /}"

      # Валидация Chat ID (число, может быть отрицательным для групп)
      if [[ ! "$TG_CHAT_ID" =~ ^-?[0-9]+$ ]]; then
          if [[ "$LANG_NAME" == "Русский" ]]; then
              err "Некорректный Chat ID. Ожидается число (например: 123456789)"
          else
              err "$ERR_CHAT_ID_FORMAT"
          fi
      fi

      local prompt_report
      if [[ "$LANG_NAME" == "Русский" ]]; then
          prompt_report="  Время ежедневного отчёта UTC [09:00]: "
      else
          prompt_report="  $PROMPT_REPORT_TIME "
      fi
      read -rp "$prompt_report" REPORT_TIME
      REPORT_TIME="${REPORT_TIME// /}"
      [[ -z "$REPORT_TIME" ]] && REPORT_TIME="09:00"
      REPORT_HOUR=$(echo "$REPORT_TIME" | cut -d: -f1)
      REPORT_MIN=$(echo  "$REPORT_TIME" | cut -d: -f2)

      echo ""
      local info_alerts prompt_cpu prompt_ram prompt_disk
      if [[ "$LANG_NAME" == "Русский" ]]; then
          info_alerts="Пороги алертов (в %, Enter = по умолчанию):"
          prompt_cpu="  CPU  > ? % [80]: "
          prompt_ram="  RAM  > ? % [85]: "
          prompt_disk="  Диск > ? % [90]: "
      else
          info_alerts="$INFO_ALERT_THRESHOLDS"
          prompt_cpu="  $PROMPT_ALERT_CPU "
          prompt_ram="  $PROMPT_ALERT_RAM "
          prompt_disk="  $PROMPT_ALERT_DISK "
      fi
      info "$info_alerts"
      read -rp "$prompt_cpu" ALERT_CPU
      ALERT_CPU="${ALERT_CPU// /}";   [[ -z "$ALERT_CPU"  ]] && ALERT_CPU=80
      read -rp "$prompt_ram" ALERT_RAM
      ALERT_RAM="${ALERT_RAM// /}";   [[ -z "$ALERT_RAM"  ]] && ALERT_RAM=85
      read -rp "$prompt_disk" ALERT_DISK
      ALERT_DISK="${ALERT_DISK// /}"; [[ -z "$ALERT_DISK" ]] && ALERT_DISK=90
  fi

  echo ""
  if [[ "$LANG_NAME" == "Русский" ]]; then
      ok "Домен:   $DOMAIN"
      ok "Email:   $LE_EMAIL"
      if [[ -n "$TG_TOKEN" ]]; then
          ok "Telegram: настроен (отчёт в ${REPORT_TIME} UTC)"
      else
          warn "Telegram: пропущен (можно добавить позже)"
      fi
  else
      ok "$OK_DOMAIN   $DOMAIN"
      ok "$OK_EMAIL   $LE_EMAIL"
      if [[ -n "$TG_TOKEN" ]]; then
          ok "$OK_TG_CONFIGURED"
      else
          warn "$WARN_TG_SKIPPED"
      fi
  fi
}

# ══════════════════════════════════════════════════════════════
# ШАГ 1: Проверка окружения IP / IP neighborhood check
# ══════════════════════════════════════════════════════════════
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
  CHECK_START=$(( LAST_OCTET - 20 <   1 ?   1 : LAST_OCTET - 20 ))
  CHECK_END=$(( LAST_OCTET + 20 > 254 ? 254 : LAST_OCTET + 20 ))

  local VPN_COUNT=0 CHECKED=0 STEP=3

  for i in $(seq "$CHECK_START" "$STEP" "$CHECK_END"); do
      local CHECK_IP="${SUBNET}.${i}"
      [[ "$CHECK_IP" == "$SERVER_IP" ]] && continue

      local RESULT ORG
      RESULT=$(curl -s --max-time 3 "https://ipinfo.io/${CHECK_IP}/json" 2>/dev/null || echo "")
      if echo "$RESULT" | grep -qi '"org"'; then
          ORG=$(echo "$RESULT" | grep '"org"' | sed 's/.*"org": *"\(.*\)".*/\1/' | tr '[:upper:]' '[:lower:]')
          if echo "$ORG" | grep -qiE 'vpn|proxy|tunnel|hosting|datacenter|vps|server|cloud'; then
              (( VPN_COUNT++ )) || true
          fi
      fi
      (( CHECKED++ )) || true
      sleep 0.2
  done

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
      [[ "$CONTINUE_ANYWAY" != "y" && "$CONTINUE_ANYWAY" != "Y" ]] \
          && { if [[ "$LANG_NAME" == "Русский" ]]; then err "$ERR_USER_ABORTED_RU"; else err "$ERR_USER_ABORTED"; fi; }
  fi
  echo ""
}

# ══════════════════════════════════════════════════════════════
# ШАГ 2: Обновление системы / System update
# ══════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════
# ШАГ 3: Автообновления безопасности / Auto security updates
# ══════════════════════════════════════════════════════════════
step_auto_updates() {
  step_title "3" "Автообновления безопасности" "Security auto-updates"

  cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

  cat > /etc/apt/apt.conf.d/50unattended-upgrades <<'EOF'
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

# ══════════════════════════════════════════════════════════════
# ШАГ 4: BBR / BBR optimization
# ══════════════════════════════════════════════════════════════
step_bbr() {
  step_title "4" "BBR и оптимизация сети" "BBR and network optimization"

  modprobe tcp_bbr 2>/dev/null || true

  cat > /etc/sysctl.d/99-cubiveil.conf <<'EOF'
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

# ══════════════════════════════════════════════════════════════
# ШАГ 5: Файрвол / Firewall
# ══════════════════════════════════════════════════════════════
step_firewall() {
  step_title "5" "Файрвол (ufw)" "Firewall (ufw)"

  ufw --force reset         >/dev/null 2>&1
  ufw default deny incoming >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1

  open_port 22  tcp  "SSH — смени порт и закрой 22 после установки"
  open_port 443 tcp  "VLESS Reality TCP + gRPC"
  open_port 443 udp  "Hysteria2 QUIC"

  ufw --force enable >/dev/null 2>&1
  ok "Файрвол включён: 22/tcp, 443/tcp, 443/udp"
  warn "SSH: после проверки нового порта закрой 22 → ufw delete allow 22/tcp"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 6: Fail2ban
# ══════════════════════════════════════════════════════════════
step_fail2ban() {
  step_title "6" "Fail2ban" "Fail2ban"

  # Получаем текущий SSH порт из конфига
  local SSH_PORT
  SSH_PORT=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | head -1 | awk '{print $2}')
  SSH_PORT="${SSH_PORT:-22}"  # По умолчанию 22 если не задан

  cat > /etc/fail2ban/jail.d/cubiveil.conf <<EOF
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
  systemctl restart fail2ban       >/dev/null 2>&1
  ok "Fail2ban: SSH защита на порту ${SSH_PORT} (3 попытки → бан 24ч)"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 7: Sing-box
# ══════════════════════════════════════════════════════════════
step_install_singbox() {
  step_title "7" "Sing-box" "Sing-box"

  info "Получаю последнюю версию с GitHub..."
  local SB_TAG
  SB_TAG=$(curl -s "https://api.github.com/repos/SagerNet/sing-box/releases/latest" \
      | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  [[ -z "$SB_TAG" ]] && err "Не удалось получить версию Sing-box с GitHub"

  local SB_VER="${SB_TAG#v}"
  local SB_URL
  SB_URL="https://github.com/SagerNet/sing-box/releases/download/${SB_TAG}/sing-box-${SB_VER}-linux-$(arch).tar.gz"

  info "Скачиваю Sing-box ${SB_TAG}..."
  curl -fLo /tmp/sing-box.tar.gz "$SB_URL"
  tar -xzf /tmp/sing-box.tar.gz -C /tmp
  mv /tmp/sing-box-*/sing-box /usr/local/bin/sing-box
  chmod +x /usr/local/bin/sing-box
  rm -rf /tmp/sing-box*

  ok "Sing-box ${SB_TAG} ($(arch)) установлен"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 8: Генерация ключей и портов / Generate keys and ports
# ══════════════════════════════════════════════════════════════
step_generate_keys_and_ports() {
  step_title "8" "Ключи Reality и порты" "Reality keypair and ports"

  # Reality keypair
  local KEYPAIR
  KEYPAIR=$(sing-box generate reality-keypair)
  REALITY_PRIVATE_KEY=$(echo "$KEYPAIR" | grep 'PrivateKey' | awk '{print $2}')
  REALITY_PUBLIC_KEY=$(echo  "$KEYPAIR" | grep 'PublicKey'  | awk '{print $2}')
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
  UUID_VLESS_TCP=$(sing-box  generate uuid)
  export UUID_VLESS_GRPC
  UUID_VLESS_GRPC=$(sing-box generate uuid)
  export UUID_HY2
  UUID_HY2=$(sing-box        generate uuid)
  export UUID_TROJAN
  UUID_TROJAN=$(sing-box     generate uuid)
  SS_PASSWORD=$(gen_random 32)

  # Уникальные порты 30000+
  TROJAN_PORT=$(unique_port)
  SS_PORT=$(unique_port)
  PANEL_PORT=$(unique_port)
  SUB_PORT=$(unique_port)

  # Открываем в файрволе
  open_port "$TROJAN_PORT" tcp "Trojan WebSocket TLS"
  open_port "$SS_PORT"     tcp "Shadowsocks 2022"
  open_port "$PANEL_PORT"  tcp "Marzban Panel"
  open_port "$SUB_PORT"    tcp "Subscription Link"

  ok "Reality keypair сгенерирован, camouflage: ${REALITY_SNI}"
  ok "Порты → Trojan:${TROJAN_PORT} SS:${SS_PORT} Панель:${PANEL_PORT} Подписки:${SUB_PORT}"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 9: Marzban
# ══════════════════════════════════════════════════════════════
step_install_marzban() {
  step_title "9" "Marzban" "Marzban"

  info "Устанавливаю Marzban..."
  if ! curl -fsSL https://github.com/Gozargah/Marzban/raw/master/script.sh \
      | bash -s -- install; then
      err "Установка Marzban не удалась. Лог: journalctl -u marzban -n 50"
  fi

  # Проверка что скрипт установки существует
  if [[ ! -f /opt/marzban/script.sh ]]; then
      err "Скрипт установки Marzban не найден"
  fi

  ok "Marzban установлен"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 10: SSL сертификат / SSL certificate
# ══════════════════════════════════════════════════════════════
step_ssl() {
  step_title "10" "SSL сертификат (Let's Encrypt)" "SSL certificate (Let's Encrypt)"

  if [[ ! -f "$HOME/.acme.sh/acme.sh" ]]; then
      info "Устанавливаю acme.sh..."
      curl -fsSL https://get.acme.sh | sh -s email="$LE_EMAIL" >/dev/null 2>&1
  fi

  # Порт 80 нужен только для валидации
  ufw allow 80/tcp >/dev/null 2>&1
  systemctl stop marzban >/dev/null 2>&1 || true

  info "Запрашиваю сертификат для ${DOMAIN}..."
  "$HOME/.acme.sh/acme.sh" --set-default-ca --server letsencrypt >/dev/null 2>&1
  "$HOME/.acme.sh/acme.sh" --issue \
      -d "$DOMAIN" --standalone --httpport 80 --force >/dev/null 2>&1 \
      || err "Не удалось получить сертификат. Проверь A-запись: ${DOMAIN} → ${SERVER_IP}"

  mkdir -p /var/lib/marzban/certs
  "$HOME/.acme.sh/acme.sh" --installcert -d "$DOMAIN" \
      --cert-file      /var/lib/marzban/certs/cert.pem \
      --key-file       /var/lib/marzban/certs/key.pem  \
      --fullchain-file /var/lib/marzban/certs/fullchain.pem \
      --reloadcmd      "systemctl restart marzban" >/dev/null 2>&1

  "$HOME/.acme.sh/acme.sh" --upgrade --auto-upgrade >/dev/null 2>&1

  chmod 600 /var/lib/marzban/certs/key.pem
  chmod 644 /var/lib/marzban/certs/cert.pem \
            /var/lib/marzban/certs/fullchain.pem

  ufw delete allow 80/tcp >/dev/null 2>&1

  ok "SSL сертификат получен, автопродление настроено"
}

# ══════════════════════════════════════════════════════════════
# ШАГ 11: Конфигурация Marzban + Sing-box
# ══════════════════════════════════════════════════════════════
step_configure() {
  step_title "11" "Конфигурация Marzban и 5 профилей Sing-box" "Marzban and 5-profile Sing-box configuration"

  SUDO_USERNAME=$(gen_random 10)
  SUDO_PASSWORD=$(gen_random 16)
  SECRET_KEY=$(gen_random 32)
  PANEL_PATH=$(gen_random 14)
  SUB_PATH=$(gen_random 14)
  TROJAN_WS_PATH=$(gen_random 10)

  # ── .env Marzban ──────────────────────────────────────────
  cat > /opt/marzban/.env <<EOF
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
  cat > /var/lib/marzban/sing-box-template.json <<EOF
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

# ══════════════════════════════════════════════════════════════
# ШАГ 12: Telegram-бот / Telegram bot
# ══════════════════════════════════════════════════════════════
step_telegram_bot() {
  step_title "12" "Telegram-бот" "Telegram bot"

  if [[ -z "${TG_TOKEN:-}" || -z "${TG_CHAT_ID:-}" ]]; then
      warn "Telegram пропущен. Добавить позже: повторно запусти скрипт"
      return
  fi

  mkdir -p /opt/cubiveil-bot/backups

  # ── Python-скрипт бота ────────────────────────────────────
  cat > /opt/cubiveil-bot/bot.py <<PYEOF
#!/usr/bin/env python3
"""
CubiVeil Telegram Bot
- Ежедневный отчёт: CPU, RAM, диск, uptime, активные пользователи + бэкап БД
- Алерты при превышении порогов
- Интерактивные команды только для авторизованного chat_id
"""

import os, json, time, subprocess, sqlite3, shutil
from datetime import datetime
import urllib.request, urllib.parse, urllib.error

# Чувствительные данные из переменных окружения (systemd Environment)
TOKEN     = os.environ.get("TG_TOKEN")
CHAT_ID   = os.environ.get("TG_CHAT_ID")
DB_PATH   = "/var/lib/marzban/db.sqlite3"
BAK_DIR   = "/opt/cubiveil-bot/backups"
STATE_FILE = "/opt/cubiveil-bot/alert_state.json"

ALERT_CPU  = ${ALERT_CPU}
ALERT_RAM  = ${ALERT_RAM}
ALERT_DISK = ${ALERT_DISK}

if not TOKEN or not CHAT_ID:
  print("[bot] ОШИБКА: TG_TOKEN и TG_CHAT_ID должны быть заданы в переменных окружения")
  exit(1)

os.makedirs(BAK_DIR, exist_ok=True)

# ── Отправка сообщений ────────────────────────────────────────
def tg_send(text, parse_mode="HTML"):
  url  = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
  data = urllib.parse.urlencode({
      "chat_id": CHAT_ID, "text": text, "parse_mode": parse_mode
  }).encode()
  try:
      urllib.request.urlopen(url, data, timeout=10)
  except Exception as e:
      print(f"[bot] Ошибка отправки: {e}")

def tg_send_file(path, caption=""):
  import http.client
  if not os.path.exists(path):
      tg_send("⚠️ Файл бэкапа не найден")
      return
  boundary = "CubiVeilBoundary"
  filename = os.path.basename(path)
  with open(path, "rb") as f:
      file_data = f.read()
  def field(name, value):
      return (f"--{boundary}\r\nContent-Disposition: form-data; "
              f'name="{name}"\r\n\r\n{value}\r\n').encode()
  body = (field("chat_id", CHAT_ID) + field("caption", caption) +
          f"--{boundary}\r\nContent-Disposition: form-data; "
          f'name="document"; filename="{filename}"\r\n'
          f"Content-Type: application/octet-stream\r\n\r\n".encode() +
          file_data + f"\r\n--{boundary}--\r\n".encode())
  try:
      conn = http.client.HTTPSConnection("api.telegram.org")
      conn.request("POST", f"/bot{TOKEN}/sendDocument", body,
          {"Content-Type": f"multipart/form-data; boundary={boundary}"})
      conn.getresponse()
  except Exception as e:
      print(f"[bot] Ошибка отправки файла: {e}")

# ── Метрики ───────────────────────────────────────────────────
def get_cpu():
  """Получает загрузку CPU из /proc/stat — быстрее и надёжнее top"""
  try:
      def read_cpu_stats():
          with open("/proc/stat") as f:
              line = f.readline()
          parts = line.split()[1:8]  # cpu user nice system idle iowait irq softirq
          return [int(x) for x in parts]

      cpu1 = read_cpu_stats()
      time.sleep(0.5)
      cpu2 = read_cpu_stats()

      # Вычисляем разницу
      delta = [cpu2[i] - cpu1[i] for i in range(len(cpu1))]
      total = sum(delta)
      idle = delta[3]  # idle

      if total == 0:
          return 0.0
      return round((1 - idle / total) * 100, 1)
  except Exception as e:
      print(f"[bot] Ошибка получения CPU: {e}")
      return 0.0

def get_ram():
  """Получает использование RAM из /proc/meminfo"""
  try:
      meminfo = {}
      with open("/proc/meminfo") as f:
          for line in f:
              parts = line.split()
              meminfo[parts[0].rstrip(":")] = int(parts[1]) // 1024  # kB → MB

      total = meminfo.get("MemTotal", 0)
      available = meminfo.get("MemAvailable", meminfo.get("MemFree", 0))
      used = total - available
      pct = round(used / total * 100, 1) if total > 0 else 0.0
      return used, total, pct
  except Exception as e:
      print(f"[bot] Ошибка получения RAM: {e}")
      return 0, 0, 0.0

def get_disk():
  """Получает использование диска из /proc/diskinfo или df"""
  try:
      r = subprocess.run(["df", "-BG", "/"], capture_output=True, text=True, timeout=5)
      lines = r.stdout.strip().split("\n")
      if len(lines) < 2:
          return 0, 0, 0
      p = lines[1].split()
      total = int(p[1].replace("G", ""))
      used = int(p[2].replace("G", ""))
      pct = int(p[4].replace("%", ""))
      return used, total, pct
  except Exception as e:
      print(f"[bot] Ошибка получения диска: {e}")
      return 0, 0, 0

def get_uptime():
  """Получает uptime из /proc/uptime"""
  try:
      with open("/proc/uptime") as f:
          secs = int(float(f.read().split()[0]))
      d = secs // 86400
      h = (secs % 86400) // 3600
      m = (secs % 3600) // 60
      return f"{d}д {h}ч {m}м"
  except Exception as e:
      print(f"[bot] Ошибка получения uptime: {e}")
      return "?"

def get_active_users():
  """Получает количество активных пользователей из БД Marzban"""
  if not os.path.exists(DB_PATH):
      return "?"
  try:
      conn = sqlite3.connect(DB_PATH, timeout=5)
      cur = conn.cursor()
      cur.execute("SELECT COUNT(*) FROM users WHERE status='active'")
      count = cur.fetchone()[0]
      conn.close()
      return count
  except Exception as e:
      print(f"[bot] Ошибка получения пользователей: {e}")
      return "?"

def make_backup():
  """Создаёт бэкап БД и удаляет старые бэкапы (>7 дней)"""
  ts = datetime.now().strftime("%Y%m%d_%H%M")
  dst = f"{BAK_DIR}/marzban_{ts}.sqlite3"
  try:
      shutil.copy2(DB_PATH, dst)
      # Удаляем бэкапы старше 7 дней
      now = time.time()
      for fn in os.listdir(BAK_DIR):
          fp = os.path.join(BAK_DIR, fn)
          if os.path.isfile(fp) and now - os.path.getmtime(fp) > 7 * 86400:
              os.remove(fp)
              print(f"[bot] Удалён старый бэкап: {fn}")
      return dst
  except Exception as e:
      print(f"[bot] Ошибка бэкапа: {e}")
      return None

def bar(pct, width=10):
  filled = int(min(pct, 100) / 100 * width)
  return "█" * filled + "░" * (width - filled)

# ── Ежедневный отчёт ─────────────────────────────────────────
def send_daily_report():
  cpu               = get_cpu()
  ram_u, ram_t, ram_p = get_ram()
  dsk_u, dsk_t, dsk_p = get_disk()
  uptime            = get_uptime()
  users             = get_active_users()
  now               = datetime.now().strftime("%d.%m.%Y %H:%M UTC")

  ci = "🔴" if cpu   > ALERT_CPU  else "🟢"
  ri = "🔴" if ram_p > ALERT_RAM  else "🟢"
  di = "🔴" if dsk_p > ALERT_DISK else "🟢"

  tg_send(
      f"<b>🛡 CubiVeil — ежедневный отчёт</b>\n"
      f"<code>{now}</code>\n"
      f"━━━━━━━━━━━━━━━━━━━━━\n"
      f"{ci} CPU:   {cpu}%  {bar(cpu)}\n"
      f"{ri} RAM:   {ram_u}/{ram_t} МБ ({ram_p}%)  {bar(ram_p)}\n"
      f"{di} Диск:  {dsk_u}/{dsk_t} ГБ ({dsk_p}%)  {bar(dsk_p)}\n"
      f"⏱ Uptime:  {uptime}\n"
      f"━━━━━━━━━━━━━━━━━━━━━\n"
      f"👥 Активных пользователей: <b>{users}</b>\n"
      f"━━━━━━━━━━━━━━━━━━━━━\n"
      f"📦 Бэкап базы прикреплён ниже"
  )
  bak = make_backup()
  if bak:
      tg_send_file(bak, f"Бэкап Marzban • {datetime.now().strftime('%d.%m.%Y')}")
  else:
      tg_send("⚠️ Не удалось создать бэкап базы")

# ── Алерты ───────────────────────────────────────────────────
def load_state():
  try:
      with open(STATE_FILE) as f:
          return json.load(f)
  except:
      return {}

def save_state(state):
  with open(STATE_FILE, "w") as f:
      json.dump(state, f)

def check_alerts():
  """
  Отправляем алерт только при переходе из нормы в превышение,
  не спамим каждые 15 минут если порог уже превышен.
  """
  state = load_state()
  alerts = []
  new_state = {}

  cpu = get_cpu()
  cpu_alert = cpu > ALERT_CPU
  if cpu_alert and not state.get("cpu"):
      alerts.append(f"🔴 <b>CPU</b>: {cpu}% (порог {ALERT_CPU}%)")
  new_state["cpu"] = cpu_alert

  _, _, ram_p = get_ram()
  ram_alert = ram_p > ALERT_RAM
  if ram_alert and not state.get("ram"):
      alerts.append(f"🔴 <b>RAM</b>: {ram_p}% (порог {ALERT_RAM}%)")
  new_state["ram"] = ram_alert

  _, _, dsk_p = get_disk()
  dsk_alert = dsk_p > ALERT_DISK
  if dsk_alert and not state.get("disk"):
      alerts.append(f"🔴 <b>Диск</b>: {dsk_p}% (порог {ALERT_DISK}%)")
  new_state["disk"] = dsk_alert

  save_state(new_state)

  if alerts:
      tg_send(
          "⚠️ <b>CubiVeil — Алерт!</b>\n"
          "━━━━━━━━━━━━━━━\n" + "\n".join(alerts)
      )

# ── Команды бота ─────────────────────────────────────────────
def handle_command(cmd):
  cmd = cmd.strip().split()[0].lower()

  if cmd in ("/start", "/status"):
      cpu               = get_cpu()
      ram_u, ram_t, ram_p = get_ram()
      dsk_u, dsk_t, dsk_p = get_disk()
      uptime            = get_uptime()
      users             = get_active_users()
      tg_send(
          f"<b>📊 Статус сервера</b>\n"
          f"━━━━━━━━━━━━━━━\n"
          f"CPU:    {cpu}%  {bar(cpu)}\n"
          f"RAM:    {ram_u}/{ram_t} МБ ({ram_p}%)\n"
          f"Диск:   {dsk_u}/{dsk_t} ГБ ({dsk_p}%)\n"
          f"Uptime: {uptime}\n"
          f"━━━━━━━━━━━━━━━\n"
          f"👥 Активных: {users}"
      )
  elif cmd == "/backup":
      tg_send("⏳ Создаю бэкап...")
      bak = make_backup()
      if bak:
          tg_send_file(bak, "Бэкап базы Marzban")
      else:
          tg_send("❌ Ошибка создания бэкапа")
  elif cmd == "/users":
      tg_send(f"👥 Активных пользователей: <b>{get_active_users()}</b>")
  elif cmd == "/restart":
      tg_send("🔄 Перезапускаю Marzban...")
      r = subprocess.run(["systemctl", "restart", "marzban"],
          capture_output=True, timeout=30)
      if r.returncode == 0:
          tg_send("✅ Marzban перезапущен")
      else:
          tg_send(f"❌ Ошибка:\n<code>{r.stderr.decode()[:500]}</code>")
  elif cmd == "/help":
      tg_send(
          "<b>CubiVeil Bot — команды</b>\n"
          "━━━━━━━━━━━━━━━\n"
          "/status  — CPU, RAM, диск, uptime\n"
          "/backup  — получить бэкап прямо сейчас\n"
          "/users   — активные пользователи\n"
          "/restart — перезапустить Marzban\n"
          "/help    — эта справка"
      )
  else:
      tg_send("Неизвестная команда. /help — список команд")

# ── Polling ───────────────────────────────────────────────────
def poll():
  offset = 0
  tg_send(
      "🟢 <b>CubiVeil Bot запущен</b>\n"
      f"Алерты: CPU>{ALERT_CPU}% RAM>{ALERT_RAM}% Диск>{ALERT_DISK}%\n"
      "Отправь /help"
  )
  while True:
      try:
          url = (f"https://api.telegram.org/bot{TOKEN}/getUpdates"
                 f"?offset={offset}&timeout=30&allowed_updates=[\"message\"]")
          with urllib.request.urlopen(url, timeout=35) as resp:
              data = json.loads(resp.read())
          for upd in data.get("result", []):
              offset = upd["update_id"] + 1
              msg    = upd.get("message", {})
              # Строгая авторизация — только свой chat_id
              if str(msg.get("chat", {}).get("id", "")) != str(CHAT_ID):
                  continue
              text = msg.get("text", "")
              if text.startswith("/"):
                  handle_command(text)
      except urllib.error.URLError:
          time.sleep(10)
      except Exception as e:
          print(f"[bot] poll error: {e}")
          time.sleep(5)

# ── Точка входа ───────────────────────────────────────────────
if __name__ == "__main__":
  import sys
  cmd = sys.argv[1] if len(sys.argv) > 1 else "poll"
  if   cmd == "report": send_daily_report()
  elif cmd == "alert":  check_alerts()
  elif cmd == "poll":   poll()
PYEOF

  chmod +x /opt/cubiveil-bot/bot.py

  # ── Systemd сервис с безопасными переменными окружения ───
  cat > /etc/systemd/system/cubiveil-bot.service <<EOF
[Unit]
Description=CubiVeil Telegram Bot
After=network.target marzban.service

[Service]
Type=simple
# Чувствительные данные через Environment — не хранятся в файле скрипта
Environment="TG_TOKEN=${TG_TOKEN}"
Environment="TG_CHAT_ID=${TG_CHAT_ID}"
ExecStart=/usr/bin/python3 /opt/cubiveil-bot/bot.py poll
Restart=always
RestartSec=10s
StandardOutput=journal
StandardError=journal
# Защита от утечек через дампы
ProtectHome=true
ProtectSystem=strict
ReadWritePaths=/opt/cubiveil-bot/backups /var/lib/marzban
NoNewPrivileges=true
# Ограничение частоты логов
LogRateLimitInterval=30s
LogRateLimitBurst=1000

[Install]
WantedBy=multi-user.target
EOF

  # ── Ротация логов через journald ─────────────────────────
  # Создаём конфиг для ограничения размера логов
  mkdir -p /etc/systemd/journald.d
  cat > /etc/systemd/journald.d/cubiveil-limit.conf <<EOF
# Ограничение размера логов для CubiVeil
[Journal]
# Максимум 1ГБ на все логи системы
SystemMaxUse=1G
# Хранить логи 14 дней
MaxFileSec=2week
EOF

  # Для самого бота — отдельный лимит через systemd
  # Перезапускаем journald чтобы применились настройки
  systemctl kill -s SIGHUP systemd-journald 2>/dev/null || true

  # ── Ротация логов через logrotate ────────────────────────
  # Дополнительная ротация для логов сервисов
  if command -v logrotate &>/dev/null; then
      cat > /etc/logrotate.d/cubiveil-services <<EOF
# Ротация логов CubiVeil сервисов
/var/log/journal/*/marzban.service.log
/var/log/journal/*/cubiveil-bot.service.log
/var/log/journal/*/marzban-health.service.log
/var/log/journal/*/sing-box.service.log {
  weekly
  rotate 4
  compress
  delaycompress
  missingok
  notifempty
  size=50M
  maxage 30
}
EOF
      ok "Ротация логов настроена (logrotate: 4 недели, 50МБ)"
  fi

  # ── Cron: ежедневный отчёт + проверка алертов ────────────
  (crontab -l 2>/dev/null || true
   echo "${REPORT_MIN} ${REPORT_HOUR} * * * /usr/bin/python3 /opt/cubiveil-bot/bot.py report"
   echo "*/15 * * * * /usr/bin/python3 /opt/cubiveil-bot/bot.py alert") | crontab -

  systemctl daemon-reload
  systemctl enable cubiveil-bot --now >/dev/null 2>&1

  ok "Telegram-бот запущен (systemd: cubiveil-bot)"
  ok "Ежедневный отчёт + бэкап: ${REPORT_TIME} UTC"
  ok "Алерты каждые 15 мин: CPU>${ALERT_CPU}% RAM>${ALERT_RAM}% Диск>${ALERT_DISK}%"
  ok "Команды: /status /backup /users /restart /help"
}

# ══════════════════════════════════════════════════════════════
# Финал: запуск и итог
# ══════════════════════════════════════════════════════════════
step_finish() {
  info "Запускаю Marzban..."
  systemctl daemon-reload  >/dev/null 2>&1
  systemctl enable marzban >/dev/null 2>&1
  systemctl restart marzban >/dev/null 2>&1
  sleep 4

  local STATUS
  STATUS=$(systemctl is-active marzban 2>/dev/null || echo "failed")
  [[ "$STATUS" != "active" ]] && \
      err "Marzban не запустился. Лог: journalctl -u marzban -n 50"

  # ── Health-check эндпоинт для мониторинга ─────────────────
  info "Настраиваю health-check эндпоинт..."
  local HC_PORT
  HC_PORT=$(unique_port)
  open_port "$HC_PORT" tcp "Marzban Health Check"

  # Добавляем переменную окружения для health check
  cat >> /opt/marzban/.env <<EOF

# Health check endpoint (внутренний)
HEALTH_CHECK_PORT = "${HC_PORT}"
EOF

  # Создаём простой HTTP сервер для health check
  cat > /opt/marzban/health_check.py <<'PYEOF'
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
  cat > /etc/systemd/system/marzban-health.service <<EOF
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

  # Создаём зашифрованный файл
  local CREDPlain="/root/cubiveil-credentials.txt"
  local CREDEnc="/root/cubiveil-credentials.age"

  cat > "$CREDPlain" <<EOF
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

  # Шифрование
  age -r "$AGE_PUBLIC_KEY" -o "$CREDEnc" "$CREDPlain"
  chmod 600 "$CREDEnc"
  rm -f "$CREDPlain"

  ok "Учётные данные зашифрованы: ${CREDEnc}"

  # Инструкция по расшифровке
  cat > /root/DECRYPT_INSTRUCTIONS.txt <<EOF
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
}

# ══════════════════════════════════════════════════════════════
# Точка входа / Entry point
# ══════════════════════════════════════════════════════════════
main() {
  select_language
  print_banner
  prompt_inputs
  step_check_ip_neighborhood
  step_system_update
  step_auto_updates
  step_bbr
  step_firewall
  step_fail2ban
  step_install_singbox
  step_generate_keys_and_ports
  step_install_marzban
  step_ssl
  step_configure
  step_telegram_bot
  step_finish
}

main "$@"
