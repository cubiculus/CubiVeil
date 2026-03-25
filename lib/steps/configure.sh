#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Configure                       ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Конфигурация Marzban и 5 профилей Sing-box              ║
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

# ── Функции / Functions ──────────────────────────────────────

# Генерация учетных данных для Marzban
configure_generate_credentials() {
  log_step "configure_generate_credentials" "Generating Marzban credentials"

  SUDO_USERNAME=$(gen_random 10)
  SUDO_PASSWORD=$(gen_random 16)
  SECRET_KEY=$(gen_random 32)
  PANEL_PATH=$(gen_random 14)
  SUB_PATH=$(gen_random 14)
  TROJAN_WS_PATH=$(gen_random 10)

  log_debug "Credentials generated"
}

# Создание .env конфигурации Marzban
configure_create_env() {
  log_step "configure_create_env" "Creating Marzban .env configuration"

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

  log_debug "Created /opt/marzban/.env"
}

# Создание шаблона Sing-box с 5 профилями
configure_create_singbox_template() {
  log_step "configure_create_singbox_template" "Creating Sing-box template with 5 profiles"

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

  log_debug "Created /var/lib/marzban/sing-box-template.json"
}

# Основная функция шага (вызывается из install-steps.sh)
step_configure() {
  step_title "11" "Конфигурация Marzban и 5 профилей Sing-box" "Marzban and 5-profile Sing-box configuration"

  configure_generate_credentials
  configure_create_env
  configure_create_singbox_template

  ok "Marzban .env настроен"
  ok "Sing-box шаблон с 5 профилями создан"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { :; }
module_configure() { step_configure; }
module_enable() { :; }
module_disable() { :; }
