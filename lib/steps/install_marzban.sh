#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: Install Marzban                 ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Установка Marzban                                        ║
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

# ── Функции / Functions ──────────────────────────────────────

# Загрузка скрипта установки Marzban
marzban_download_script() {
  log_step "marzban_download_script" "Downloading Marzban installation script"

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

  log_debug "Marzban script downloaded and validated"
}

# Установка Marzban
marzban_install() {
  log_step "marzban_install" "Installing Marzban"

  local MARZBAN_SCRIPT="/tmp/marzban-install.sh"

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

  log_debug "Marzban installed successfully"
}

# Основная функция шага (вызывается из install-steps.sh)
step_install_marzban() {
  step_title "9" "Marzban" "Marzban"

  info "Устанавливаю Marzban..."

  marzban_download_script
  marzban_install

  ok "Marzban установлен"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { step_install_marzban; }
module_configure() { :; }
module_enable() { :; }
module_disable() { :; }
