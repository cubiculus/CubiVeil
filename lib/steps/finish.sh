#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Finish                           ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Финальный запуск и шифрование credentials                 ║
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

# Запуск Marzban
finish_start_marzban() {
  log_step "finish_start_marzban" "Starting Marzban"

  info "Запускаю Marzban..."

  svc_daemon_reload
  svc_enable "marzban"
  svc_restart "marzban"

  sleep 4

  local STATUS
  STATUS=$(svc_status "marzban")

  if [[ "$STATUS" != "active" ]]; then
    err "Marzban не запустился. Лог: journalctl -u marzban -n 50"
  fi

  log_debug "Marzban started successfully"
}

# Настройка health-check эндпоинта
finish_setup_health_check() {
  log_step "finish_setup_health_check" "Setting up health-check endpoint"

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

  svc_daemon_reload
  svc_enable_start "marzban-health"

  ok "Health-check эндпоинт: http://${SERVER_IP}:${HC_PORT}/health"
}

# Установка age если не установлен
finish_install_age() {
  log_step "finish_install_age" "Installing age encryption tool"

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
  else
    log_debug "age already installed"
  fi
}

# Генерация ключа age и шифрование credentials
finish_encrypt_credentials() {
  log_step "finish_encrypt_credentials" "Encrypting credentials with age"

  info "Шифрую учётные данные..."

  # Генерация ключа
  local KEY_FILE="/var/lib/marzban/credentials.key"
  local ENCRYPTED_FILE="/var/lib/marzban/credentials.age"

  age-keygen -o "$KEY_FILE" >/dev/null 2>&1
  chmod 600 "$KEY_FILE"

  # Создаём JSON с credentials
  local CREDENTIALS_JSON
  CREDENTIALS_JSON=$(cat <<EOF
{
  "panel_url": "https://${DOMAIN}:${PANEL_PORT}/${PANEL_PATH}",
  "username": "${SUDO_USERNAME}",
  "password": "${SUDO_PASSWORD}",
  "panel_path": "/${PANEL_PATH}",
  "subscription_url": "https://${DOMAIN}:${SUB_PORT}/${SUB_PATH}",
  "subscription_path": "/${SUB_PATH}",
  "domain": "${DOMAIN}"
}
EOF
)

  # Шифруем
  echo "$CREDENTIALS_JSON" | age -r "$(age-keygen -y "$KEY_FILE")" -o "$ENCRYPTED_FILE"
  chmod 600 "$ENCRYPTED_FILE"

  log_debug "Credentials encrypted and saved"
}

# Создание файла с инструкциями
finish_create_instructions() {
  log_step "finish_create_instructions" "Creating installation instructions"

  cat >"/tmp/cubiveil-installation-${DOMAIN}.txt" <<EOF
══════════════════════════════════════════════════════════
  CubiVeil Installation Complete
══════════════════════════════════════════════════════════

Panel URL: https://${DOMAIN}:${PANEL_PORT}/${PANEL_PATH}
Username:   ${SUDO_USERNAME}
Password:   ${SUDO_PASSWORD}

Subscription: https://${DOMAIN}:${SUB_PORT}/${SUB_PATH}

Ports:
  - Panel:     ${PANEL_PORT} (TCP)
  - Subscriptions: ${SUB_PORT} (TCP)
  - Trojan:    ${TROJAN_PORT} (TCP)
  - Shadowsocks: ${SS_PORT} (TCP)

Health Check: http://${SERVER_IP}:$(grep "HEALTH_CHECK_PORT" /opt/marzban/.env | cut -d= -f2 | tr -d '"')/health

Credentials encrypted: /var/lib/marzban/credentials.age
Age key: /var/lib/marzban/credentials.key

To decrypt credentials:
  age --decrypt -i /var/lib/marzban/credentials.key /var/lib/marzban/credentials.age

══════════════════════════════════════════════════════════
EOF

  ok "Инструкция сохранена: /tmp/cubiveil-installation-${DOMAIN}.txt"
}

# Основная функция шага (вызывается из install-steps.sh)
step_finish() {
  finish_start_marzban
  finish_setup_health_check
  finish_install_age
  finish_encrypt_credentials
  finish_create_instructions

  echo ""
  success "✅ CubiVeil установлен успешно!"
  echo ""
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { :; }
module_configure() { step_finish; }
module_enable() { :; }
module_disable() { :; }
