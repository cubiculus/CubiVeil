#!/bin/bash
# shellcheck disable=SC1071,SC2034
# ╔═══════════════════════════════════════════════════════════╗
# ║  CubiVeil — S-UI Profiles Module                         ║
# ║  github.com/cubiculus/cubiveil                           ║
# ║                                                           ║
# ║  Создаёт VPN-профили в s-ui:                             ║
# ║  • VLESS + Reality   — лучший камуфляж для РФ            ║
# ║  • Hysteria2         — UDP, высокая скорость              ║
# ║  • Shadowsocks 2022  — широкая совместимость              ║
# ╚═══════════════════════════════════════════════════════════╝

# Guard: защита от повторной загрузки
if [[ -n "${_PROFILES_MODULE_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
readonly _PROFILES_MODULE_LOADED=1

# ── Подключение зависимостей ────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# ── Константы ───────────────────────────────────────────────
readonly PROFILES_CREDS="/etc/cubiveil/s-ui.credentials"
readonly PROFILES_FILE="/etc/cubiveil/profiles.txt"
readonly SUI_DB="/usr/local/s-ui/db/s-ui.db"
readonly REALITY_SNI="${REALITY_SNI:-www.google.com}"
readonly REALITY_FP="${REALITY_FP:-chrome}"
readonly API_TIMEOUT=60

# ── Глобальные переменные ──────────────────────────────────
SUI_PANEL_PORT=""
SUI_PATH=""
SUI_ADMIN_USER=""
SUI_ADMIN_PASSWORD=""
SERVER_IP=""
SINGBOX_BIN=""
COOKIE_JAR=""
DB_SCHEMA_TYPE=""

# ── Утилиты ─────────────────────────────────────────────────

_profiles_info() { log_info "$*"; }
_profiles_ok() { log_success "$*"; }
_profiles_warn() { log_warn "$*"; }
_profiles_err() { log_error "$*"; }

# ── Загрузка credentials ────────────────────────────────────

_profiles_load_credentials() {
  if [[ ! -f "$PROFILES_CREDS" ]]; then
    log_error "Credentials not found: $PROFILES_CREDS"
    return 1
  fi
  # shellcheck source=/dev/null
  source "$PROFILES_CREDS"

  SUI_PANEL_PORT="${SUI_PANEL_PORT:-2095}"
  SUI_PATH="${SUI_PATH:-/app/}"
  SUI_ADMIN_USER="${SUI_ADMIN_USER:-}"
  SUI_ADMIN_PASSWORD="${SUI_ADMIN_PASSWORD:-}"

  if [[ -z "$SUI_ADMIN_USER" || -z "$SUI_ADMIN_PASSWORD" ]]; then
    log_error "SUI_ADMIN_USER or SUI_ADMIN_PASSWORD is not set"
    return 1
  fi

  log_info "Credentials loaded from $PROFILES_CREDS"
  return 0
}

# ── Поиск sing-box binary ───────────────────────────────────

_profiles_find_singbox() {
  local candidates=(
    "/usr/local/s-ui/bin/sing-box"
    "/usr/local/bin/sing-box"
    "/usr/bin/sing-box"
  )
  for p in "${candidates[@]}"; do
    if [[ -x "$p" ]]; then
      echo "$p"
      return 0
    fi
  done
  if command -v sing-box &>/dev/null; then
    command -v sing-box
    return 0
  fi
  return 1
}

# ── Получение IP сервера (используем lib/utils.sh) ──────────

_profiles_get_server_ip() {
  local ip
  ip=$(get_server_ip 2>/dev/null) || {
    # Fallback
    for svc in "https://api.ipify.org" "https://ifconfig.me" "https://icanhazip.com"; do
      ip=$(curl -sf --connect-timeout 5 --max-time 10 "$svc" 2>/dev/null | tr -d '[:space:]') || true
      if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "$ip"
        return 0
      fi
    done
    hostname -I | awk '{print $1}'
    return
  }
  echo "$ip"
}

# ── Генерация ключей ────────────────────────────────────────

_profiles_gen_uuid() {
  if [[ -n "$SINGBOX_BIN" ]]; then
    "$SINGBOX_BIN" generate uuid 2>/dev/null ||
      cat /proc/sys/kernel/random/uuid 2>/dev/null ||
      openssl rand -hex 16 | sed 's/.\{8\}/&-/;s/.\{13\}/&-/;s/.\{18\}/&-/;s/.\{23\}/&-/'
  else
    cat /proc/sys/kernel/random/uuid 2>/dev/null ||
      openssl rand -hex 16
  fi
}

_profiles_gen_reality_keypair() {
  if [[ -z "$SINGBOX_BIN" ]]; then
    log_error "sing-box binary not found — cannot generate Reality keypair"
    return 1
  fi

  local raw
  raw=$("$SINGBOX_BIN" generate reality-keypair 2>/dev/null) || {
    log_error "Failed to run: $SINGBOX_BIN generate reality-keypair"
    return 1
  }

  REALITY_PRIVATE_KEY=$(echo "$raw" | awk '/PrivateKey/{print $2}')
  REALITY_PUBLIC_KEY=$(echo "$raw" | awk '/PublicKey/{print $2}')

  if [[ -z "$REALITY_PRIVATE_KEY" || -z "$REALITY_PUBLIC_KEY" ]]; then
    log_error "Failed to parse Reality keypair output: $raw"
    return 1
  fi
  return 0
}

_profiles_gen_short_id() {
  openssl rand -hex 8
}

_profiles_gen_random_port() {
  echo $((RANDOM % 30001 + 20000))
}

# ── S-UI REST API ───────────────────────────────────────────

_profiles_api_base() {
  local path="${SUI_PATH%/}"
  echo "http://127.0.0.1:${SUI_PANEL_PORT}${path}"
}

_profiles_wait_for_api() {
  local elapsed=0
  local base
  base=$(_profiles_api_base)

  log_info "Waiting for s-ui API at ${base} (max ${API_TIMEOUT}s)..."

  while [[ $elapsed -lt $API_TIMEOUT ]]; do
    if curl -sf --connect-timeout 2 --max-time 3 "${base}/" &>/dev/null; then
      log_info "s-ui API is ready"
      return 0
    fi
    sleep 3
    elapsed=$((elapsed + 3))
  done

  log_warn "s-ui API not responding after ${API_TIMEOUT}s — will use SQLite fallback"
  return 1
}

_profiles_api_login() {
  COOKIE_JAR=$(mktemp /tmp/cubiveil-cookies.XXXXXX)
  local base
  base=$(_profiles_api_base)

  local endpoints=("${base}/api/login" "${base}/login")
  local body
  body=$(printf '{"username":"%s","password":"%s"}' \
    "$SUI_ADMIN_USER" "$SUI_ADMIN_PASSWORD")

  for ep in "${endpoints[@]}"; do
    local resp
    resp=$(curl -sf -c "$COOKIE_JAR" \
      -X POST "$ep" \
      -H "Content-Type: application/json" \
      -d "$body" \
      --connect-timeout 5 --max-time 15 2>/dev/null) || true

    if echo "$resp" | grep -qE '"success"\s*:\s*true|"msg"\s*:\s*""|"token"'; then
      log_info "API login successful (via $ep)"
      return 0
    fi
  done

  log_warn "API login failed — falling back to SQLite"
  rm -f "$COOKIE_JAR"
  COOKIE_JAR=""
  return 1
}

_profiles_api_create_inbound() {
  local payload="$1"
  local base
  base=$(_profiles_api_base)

  local endpoints=(
    "${base}/api/inbounds"
    "${base}/api/inbound/add"
  )

  for ep in "${endpoints[@]}"; do
    local resp
    resp=$(curl -sf -b "$COOKIE_JAR" \
      -X POST "$ep" \
      -H "Content-Type: application/json" \
      -d "$payload" \
      --connect-timeout 5 --max-time 30 2>/dev/null) || true

    if echo "$resp" | grep -qE '"success"\s*:\s*true|"id"\s*:'; then
      return 0
    fi
  done

  return 1
}

# ── SQLite — определение схемы ──────────────────────────────

_profiles_detect_db_schema() {
  if ! command -v sqlite3 &>/dev/null; then
    log_info "Installing sqlite3..."
    apt-get install -y -qq sqlite3 >/dev/null 2>&1
  fi

  if [[ ! -f "$SUI_DB" ]]; then
    log_warn "S-UI database not found: $SUI_DB"
    DB_SCHEMA_TYPE="unknown"
    return 1
  fi

  local schema
  schema=$(sqlite3 "$SUI_DB" ".schema inbounds" 2>/dev/null || echo "")

  if [[ -z "$schema" ]]; then
    log_warn "Table 'inbounds' not found in DB — s-ui may not be initialized yet"
    DB_SCHEMA_TYPE="unknown"
    return 1
  fi

  if echo "$schema" | grep -qi '"config"'; then
    DB_SCHEMA_TYPE="config_blob"
  elif echo "$schema" | grep -qi '"settings"'; then
    DB_SCHEMA_TYPE="columns"
  else
    log_warn "Unknown DB schema — will attempt generic insert"
    DB_SCHEMA_TYPE="unknown"
  fi

  log_info "Detected DB schema type: ${DB_SCHEMA_TYPE}"
  return 0
}

_profiles_sqlite_insert_inbound() {
  local remark="$1"
  local port="$2"
  local protocol="$3"
  local config_json="$4"
  local settings_json="$5"
  local stream_json="${6:-{}}"
  local tag="$7"

  local user_id
  user_id=$(sqlite3 "$SUI_DB" \
    "SELECT id FROM users ORDER BY id LIMIT 1;" 2>/dev/null || echo "1")

  local safe_remark="${remark//\'/\'\'}"
  local safe_config="${config_json//\'/\'\'}"
  local safe_settings="${settings_json//\'/\'\'}"
  local safe_stream="${stream_json//\'/\'\'}"
  local safe_tag="${tag//\'/\'\'}"

  case "$DB_SCHEMA_TYPE" in
  config_blob)
    sqlite3 "$SUI_DB" <<SQL 2>/dev/null
INSERT OR IGNORE INTO inbounds
    (user_id, up, down, total, remark, enable, expiry_time, config, listen, port, protocol, tag)
VALUES
    ($user_id, 0, 0, 0, '${safe_remark}', 1, 0,
     '${safe_config}', '0.0.0.0', $port, '${protocol}', '${safe_tag}');
SQL
    ;;
  columns)
    sqlite3 "$SUI_DB" <<SQL 2>/dev/null
INSERT OR IGNORE INTO inbounds
    (user_id, up, down, total, remark, enable, expiry_time,
     listen, port, protocol, settings, stream_settings, tag, sniffing)
VALUES
    ($user_id, 0, 0, 0, '${safe_remark}', 1, 0,
     '0.0.0.0', $port, '${protocol}',
     '${safe_settings}', '${safe_stream}',
     '${safe_tag}', '{"enabled":false}');
SQL
    ;;
  *)
    log_warn "Cannot insert: unknown DB schema for table 'inbounds'"
    return 1
    ;;
  esac

  local rc=$?
  if [[ $rc -ne 0 ]]; then
    log_warn "SQLite insert returned code $rc"
    return 1
  fi
  return 0
}

# ── Открытие порта (используем lib/utils.sh) ────────────────

_profiles_open_port() {
  local port="$1"
  local proto="${2:-tcp}"

  open_port "$port" "$proto" "cubiveil-profile" 2>/dev/null || {
    # Fallback если ufw не настроен
    if command -v ufw &>/dev/null; then
      case "$proto" in
      tcp) ufw allow "${port}/tcp" >/dev/null 2>&1 || true ;;
      udp) ufw allow "${port}/udp" >/dev/null 2>&1 || true ;;
      both)
        ufw allow "${port}/tcp" >/dev/null 2>&1 || true
        ufw allow "${port}/udp" >/dev/null 2>&1 || true
        ;;
      esac
    fi
  }
}

# ── Универсальный создатель инбаунда ────────────────────────

_profiles_create_inbound() {
  local remark="$1"
  local port="$2"
  local protocol="$3"
  local singbox_config="$4"
  local settings_json="$5"
  local stream_json="${6:-{}}"
  local tag="$7"
  local fw_proto="${8:-tcp}"

  local created=false

  # Попытка 1: REST API
  if [[ -n "$COOKIE_JAR" && -f "$COOKIE_JAR" ]]; then
    local api_payload
    api_payload=$(printf '{"remark":"%s","enable":true,"listen":"0.0.0.0","port":%d,"protocol":"%s","settings":%s,"streamSettings":%s,"tag":"%s","sniffing":{"enabled":false}}' \
      "$remark" "$port" "$protocol" "$settings_json" "$stream_json" "$tag")

    if _profiles_api_create_inbound "$api_payload"; then
      _profiles_ok "Created via API"
      created=true
    fi
  fi

  # Попытка 2: SQLite
  if [[ "$created" == "false" ]] && [[ "$DB_SCHEMA_TYPE" != "unknown" ]]; then
    if _profiles_sqlite_insert_inbound \
      "$remark" "$port" "$protocol" \
      "$singbox_config" "$settings_json" "$stream_json" "$tag"; then
      _profiles_ok "Created via SQLite (schema: $DB_SCHEMA_TYPE)"
      created=true
    fi
  fi

  if [[ "$created" == "false" ]]; then
    _profiles_err "Failed to create inbound '${remark}'"
    return 1
  fi

  _profiles_open_port "$port" "$fw_proto"
  return 0
}

# ── Профиль: VLESS + Reality ────────────────────────────────

_profiles_create_vless_reality() {
  log_info "Creating VLESS + Reality"

  local port uuid short_id tag

  port=$(_profiles_gen_random_port)
  uuid=$(_profiles_gen_uuid)
  short_id=$(_profiles_gen_short_id)
  tag="vless-reality-${short_id:0:8}"

  local REALITY_PRIVATE_KEY="" REALITY_PUBLIC_KEY=""
  if ! _profiles_gen_reality_keypair; then
    log_error "Skipping VLESS+Reality (keypair generation failed)"
    return 1
  fi

  local singbox_json
  singbox_json=$(
    cat <<JSON
{
  "type": "vless",
  "tag": "${tag}",
  "listen": "0.0.0.0",
  "listen_port": ${port},
  "users": [
    {
      "uuid": "${uuid}",
      "flow": "xtls-rprx-vision",
      "name": "${SUI_ADMIN_USER}"
    }
  ],
  "tls": {
    "enabled": true,
    "server_name": "${REALITY_SNI}",
    "reality": {
      "enabled": true,
      "handshake": {
        "server": "${REALITY_SNI}",
        "server_port": 443
      },
      "private_key": "${REALITY_PRIVATE_KEY}",
      "short_id": ["${short_id}"]
    }
  }
}
JSON
  )

  local settings_json
  settings_json=$(
    cat <<JSON
{
  "clients": [
    {
      "id": "${uuid}",
      "flow": "xtls-rprx-vision",
      "email": "${SUI_ADMIN_USER}@vless-reality",
      "limitIp": 0,
      "totalGB": 0,
      "expiryTime": 0
    }
  ],
  "decryption": "none"
}
JSON
  )

  local stream_json
  stream_json=$(
    cat <<JSON
{
  "network": "tcp",
  "security": "reality",
  "realitySettings": {
    "show": false,
    "dest": "${REALITY_SNI}:443",
    "serverNames": ["${REALITY_SNI}"],
    "privateKey": "${REALITY_PRIVATE_KEY}",
    "shortIds": ["${short_id}"]
  }
}
JSON
  )

  if ! _profiles_create_inbound \
    "VLESS+Reality" "$port" "vless" \
    "$singbox_json" "$settings_json" "$stream_json" \
    "$tag" "tcp"; then
    return 1
  fi

  local link="vless://${uuid}@${SERVER_IP}:${port}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${REALITY_SNI}&fp=${REALITY_FP}&pbk=${REALITY_PUBLIC_KEY}&sid=${short_id}&type=tcp&headerType=none#VLESS-Reality-CubiVeil"

  log_info "Port:       ${port}"
  log_info "UUID:       ${uuid}"
  log_info "Public Key: ${REALITY_PUBLIC_KEY}"
  log_info "Short ID:   ${short_id}"
  log_info "SNI:        ${REALITY_SNI}"

  # Сохраняем в файл профилей
  {
    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "  VLESS + Reality"
    echo "══════════════════════════════════════════════════════"
    echo "  Port:        $port"
    echo "  UUID:        $uuid"
    echo "  SNI:         $REALITY_SNI"
    echo "  Fingerprint: $REALITY_FP"
    echo "  Public Key:  $REALITY_PUBLIC_KEY"
    echo "  Short ID:    $short_id"
    echo ""
    echo "  Link:"
    echo "  $link"
  } >>"$PROFILES_FILE"

  echo "VLESS_REALITY_PRIVATE_KEY=${REALITY_PRIVATE_KEY}" >>"$PROFILES_CREDS"
  echo "VLESS_REALITY_PUBLIC_KEY=${REALITY_PUBLIC_KEY}" >>"$PROFILES_CREDS"

  return 0
}

# ── Профиль: Hysteria2 ──────────────────────────────────────

_profiles_create_hysteria2() {
  log_info "Creating Hysteria2"

  local port password tag
  port=$(_profiles_gen_random_port)
  password=$(openssl rand -base64 24 | tr -d '=+/\n' | cut -c1-24)
  tag="hysteria2-$(openssl rand -hex 4)"

  local cert_path="" key_path=""
  local tls_mode="self"

  local cert_candidates=(
    "/usr/local/s-ui/cert/cert.pem:/usr/local/s-ui/cert/key.pem"
    "/etc/cubiveil/ssl/cert.pem:/etc/cubiveil/ssl/key.pem"
    "/etc/ssl/certs/cubiveil.pem:/etc/ssl/private/cubiveil.key"
  )

  for pair in "${cert_candidates[@]}"; do
    local c="${pair%%:*}"
    local k="${pair##*:}"
    if [[ -f "$c" && -f "$k" ]]; then
      cert_path="$c"
      key_path="$k"
      tls_mode="file"
      break
    fi
  done

  local sni="${DOMAIN:-${SERVER_IP}}"

  local tls_block=""
  if [[ "$tls_mode" == "file" ]]; then
    tls_block=$(
      cat <<JSON
  "tls": {
    "enabled": true,
    "certificate_path": "${cert_path}",
    "key_path": "${key_path}"
  },
JSON
    )
  fi

  local singbox_json
  singbox_json=$(
    cat <<JSON
{
  "type": "hysteria2",
  "tag": "${tag}",
  "listen": "0.0.0.0",
  "listen_port": ${port},
  "users": [
    {
      "password": "${password}",
      "name": "${SUI_ADMIN_USER}"
    }
  ],
  "up_mbps": 100,
  "down_mbps": 100,
  ${tls_block}
  "masquerade": "https://${REALITY_SNI}"
}
JSON
  )

  local settings_json
  settings_json=$(
    cat <<JSON
{
  "clients": [
    {
      "password": "${password}",
      "email": "${SUI_ADMIN_USER}@hysteria2"
    }
  ],
  "up_mbps": 100,
  "down_mbps": 100
}
JSON
  )

  if ! _profiles_create_inbound \
    "Hysteria2" "$port" "hysteria2" \
    "$singbox_json" "$settings_json" "{}" \
    "$tag" "udp"; then
    return 1
  fi

  local insecure="0"
  [[ "$tls_mode" != "file" ]] && insecure="1"

  local link="hysteria2://${password}@${SERVER_IP}:${port}/?insecure=${insecure}&sni=${sni}#Hysteria2-CubiVeil"

  log_info "Port:     ${port} (UDP)"
  log_info "Password: ${password}"
  log_info "SNI:      ${sni}"
  [[ "$tls_mode" == "file" ]] && log_info "TLS cert: ${cert_path}"
  [[ "$insecure" == "1" ]] && log_warn "TLS cert not found — client will use insecure=1"

  {
    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "  Hysteria2"
    echo "══════════════════════════════════════════════════════"
    echo "  Port:     $port (UDP)"
    echo "  Password: $password"
    echo "  SNI:      $sni"
    echo "  Insecure: $insecure"
    echo ""
    echo "  Link:"
    echo "  $link"
  } >>"$PROFILES_FILE"

  return 0
}

# ── Профиль: Shadowsocks 2022 ───────────────────────────────

_profiles_create_shadowsocks2022() {
  log_info "Creating Shadowsocks 2022"

  local port tag
  port=$(_profiles_gen_random_port)
  tag="ss2022-$(openssl rand -hex 4)"

  local method="2022-blake3-aes-256-gcm"
  local server_key
  server_key=$(openssl rand -base64 32 | tr -d '\n')

  local singbox_json
  singbox_json=$(
    cat <<JSON
{
  "type": "shadowsocks",
  "tag": "${tag}",
  "listen": "0.0.0.0",
  "listen_port": ${port},
  "method": "${method}",
  "password": "${server_key}",
  "multiplex": {
    "enabled": true
  }
}
JSON
  )

  local settings_json
  settings_json=$(
    cat <<JSON
{
  "method": "${method}",
  "password": "${server_key}",
  "clients": [
    {
      "password": "${server_key}",
      "email": "${SUI_ADMIN_USER}@ss2022"
    }
  ]
}
JSON
  )

  if ! _profiles_create_inbound \
    "Shadowsocks-2022" "$port" "shadowsocks" \
    "$singbox_json" "$settings_json" '{"network":"tcp+udp"}' \
    "$tag" "both"; then
    return 1
  fi

  local userinfo
  userinfo=$(printf '%s:%s' "$method" "$server_key" | base64 | tr -d '\n')
  local link="ss://${userinfo}@${SERVER_IP}:${port}#SS2022-CubiVeil"

  log_info "Port:   ${port} (TCP+UDP)"
  log_info "Method: ${method}"
  log_info "Key:    ${server_key}"

  {
    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "  Shadowsocks 2022"
    echo "══════════════════════════════════════════════════════"
    echo "  Port:   $port"
    echo "  Method: $method"
    echo "  Key:    $server_key"
    echo ""
    echo "  Link:"
    echo "  $link"
  } >>"$PROFILES_FILE"

  return 0
}

# ── Перезапуск s-ui ─────────────────────────────────────────

_profiles_restart_sui() {
  log_info "Restarting s-ui to apply changes"

  if systemctl is-active --quiet s-ui 2>/dev/null; then
    systemctl restart s-ui 2>/dev/null
    sleep 5

    if systemctl is-active --quiet s-ui 2>/dev/null; then
      _profiles_ok "s-ui restarted successfully"
    else
      _profiles_warn "s-ui may not have restarted — check: systemctl status s-ui"
    fi
  else
    _profiles_warn "s-ui is not running — start with: systemctl start s-ui"
  fi

  if systemctl is-active --quiet sing-box 2>/dev/null; then
    systemctl restart sing-box 2>/dev/null || true
    _profiles_ok "sing-box restarted"
  fi
}

# ── Инициализация файла профилей ────────────────────────────

_profiles_init_file() {
  mkdir -p /etc/cubiveil
  {
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  CubiVeil VPN Profiles                               ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo "  Generated : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Server IP : ${SERVER_IP}"
    echo ""
    echo "  Supported clients:"
    echo "  • v2rayN / v2rayNG   (VLESS+Reality, Shadowsocks)"
    echo "  • NekoBox / NekoRay  (all protocols)"
    echo "  • Clash Meta         (all protocols)"
    echo "  • Hiddify            (all protocols)"
    echo "  • Streisand          (all protocols)"
  } >"$PROFILES_FILE"
  chmod 600 "$PROFILES_FILE"
}

# ── Главная функция создания профилей ───────────────────────

_profiles_setup_inbounds() {
  log_step "profiles_setup" "Creating VPN profiles"

  # Инициализация
  SINGBOX_BIN=$(_profiles_find_singbox 2>/dev/null || echo "")
  [[ -z "$SINGBOX_BIN" ]] && log_warn "sing-box binary not found (Reality profile may be skipped)"

  SERVER_IP=$(_profiles_get_server_ip)
  log_info "Server IP: ${SERVER_IP}"

  _profiles_init_file

  _profiles_detect_db_schema 2>/dev/null || true

  local api_ready=false
  if _profiles_wait_for_api 2>/dev/null; then
    if _profiles_api_login; then
      api_ready=true
    fi
  fi

  [[ "$api_ready" == "false" ]] && COOKIE_JAR=""

  # Создаём профили
  local created=0
  local failed=()

  if _profiles_create_vless_reality; then
    ((created++))
  else
    failed+=("VLESS+Reality")
  fi

  if _profiles_create_hysteria2; then
    ((created++))
  else
    failed+=("Hysteria2")
  fi

  if _profiles_create_shadowsocks2022; then
    ((created++))
  else
    failed+=("Shadowsocks-2022")
  fi

  # Перезапускаем сервисы если что-то создали
  if [[ $created -gt 0 ]]; then
    _profiles_restart_sui
  fi

  # Очистка
  [[ -n "$COOKIE_JAR" && -f "$COOKIE_JAR" ]] && rm -f "$COOKIE_JAR"

  # Итог
  local failed_str=""
  [[ ${#failed[@]} -gt 0 ]] && failed_str="${failed[*]}"

  log_info "Profiles created: ${created}"
  [[ -n "$failed_str" ]] && log_warn "Failed: ${failed_str}"
  log_info "Profiles file: ${PROFILES_FILE}"

  if [[ ${#failed[@]} -gt 0 ]]; then
    return 1
  fi
  return 0
}

# ── Модульный интерфейс / Module Interface ─────────────────

module_install() {
  log_step "profiles_install" "Installing S-UI profiles dependencies"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install profiles dependencies"
    return 0
  fi

  # Устанавливаем sqlite3 если не установлен
  if ! command -v sqlite3 &>/dev/null; then
    log_info "Installing sqlite3..."
    apt-get install -y -qq sqlite3 >/dev/null 2>&1 || {
      log_warn "Failed to install sqlite3 — profiles may not work"
    }
  else
    log_info "sqlite3 already installed"
  fi
}

module_configure() {
  log_step "profiles_configure" "Configuring S-UI VPN profiles"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would create VPN profiles"
    log_info "[DRY-RUN] VLESS+Reality, Hysteria2, Shadowsocks-2022"
    return 0
  fi

  # Загружаем credentials
  if ! _profiles_load_credentials; then
    log_error "Cannot load credentials — skipping profile creation"
    return 1
  fi

  # Создаём профили
  _profiles_setup_inbounds
}

module_enable() {
  log_step "profiles_enable" "Verifying VPN profiles"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would verify VPN profiles"
    return 0
  fi

  # Проверяем что файл профилей создан
  if [[ -f "$PROFILES_FILE" ]]; then
    local profile_count
    profile_count=$(grep -c "Link:" "$PROFILES_FILE" 2>/dev/null || echo "0")
    log_info "VPN profiles verified: ${profile_count} profiles in ${PROFILES_FILE}"
    return 0
  else
    log_warn "Profiles file not found — profiles may not have been created"
    return 1
  fi
}

module_disable() {
  log_step "profiles_disable" "Disabling VPN profiles"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would disable VPN profiles"
    return 0
  fi

  # Удаляем файл профилей (credentials сохраняем)
  if [[ -f "$PROFILES_FILE" ]]; then
    rm -f "$PROFILES_FILE"
    log_info "Profiles file removed"
  fi
}

module_update() {
  log_step "profiles_update" "Updating VPN profiles"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would update VPN profiles"
    return 0
  fi

  log_info "VPN profiles are static — no update needed"
}

module_remove() {
  log_step "profiles_remove" "Removing VPN profiles"

  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would remove VPN profiles"
    return 0
  fi

  if [[ -f "$PROFILES_FILE" ]]; then
    rm -f "$PROFILES_FILE"
    log_info "Profiles file removed"
  fi

  # Удаляем ключи Reality из credentials
  if [[ -f "$PROFILES_CREDS" ]]; then
    sed -i '/VLESS_REALITY_PRIVATE_KEY/d' "$PROFILES_CREDS"
    sed -i '/VLESS_REALITY_PUBLIC_KEY/d' "$PROFILES_CREDS"
  fi

  log_success "VPN profiles removed"
}

module_status() {
  log_step "profiles_status" "Checking VPN profiles status"

  echo ""
  echo "══════════════════════════════════════════════════════"
  echo "  VPN Profiles Status"
  echo "══════════════════════════════════════════════════════"
  echo ""

  if [[ -f "$PROFILES_FILE" ]]; then
    local profile_count
    profile_count=$(grep -c "Link:" "$PROFILES_FILE" 2>/dev/null || echo "0")
    echo -e "  Profiles file: \033[0;32mExists\033[0m ($profile_count profiles)"
    echo "  Location: ${PROFILES_FILE}"
  else
    echo -e "  Profiles file: \033[0;31mNot found\033[0m"
  fi

  echo ""

  if [[ -f "$PROFILES_CREDS" ]]; then
    echo "  Credentials:"
    if grep -q "VLESS_REALITY_PRIVATE_KEY" "$PROFILES_CREDS" 2>/dev/null; then
      echo -e "    VLESS Reality keys: \033[0;32mPresent\033[0m"
    else
      echo -e "    VLESS Reality keys: \033[0;33mNot found\033[0m"
    fi
  fi

  echo ""
  echo "══════════════════════════════════════════════════════"
  echo ""
}

module_health_check() {
  local errors=0

  # Check sqlite3
  if ! command -v sqlite3 &>/dev/null; then
    log_warn "sqlite3 not installed"
    errors=$((errors + 1))
  fi

  # Check credentials
  if [[ ! -f "$PROFILES_CREDS" ]]; then
    log_error "Credentials file not found"
    errors=$((errors + 1))
  fi

  # Check profiles file
  if [[ ! -f "$PROFILES_FILE" ]]; then
    log_warn "Profiles file not found"
    errors=$((errors + 1))
  fi

  return $errors
}
