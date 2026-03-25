#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║            CubiVeil — Install Aliases                     ║
# ║         github.com/cubiculus/cubiveil                     ║
# ║                                                           ║
# ║  Установка алиасов для удобного запуска утилит            ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
if [[ -f "${PROJECT_DIR}/lang.sh" ]]; then
  source "${PROJECT_DIR}/lang.sh"
else
  source "${PROJECT_DIR}/lib/fallback.sh"
fi

# ── Подключение унифицированных функций вывода ───────────────
source "${PROJECT_DIR}/lib/output.sh" || {
  echo "❌ Не удалось загрузить lib/output.sh" >&2
  exit 1
}

# ── Константы ─────────────────────────────────────────────────
CUBIVEIL_CLI="/usr/local/bin/cubiveil"
ALIASES_FILE="/etc/bash_aliases.d/cubiveil"

# ── Локализация ───────────────────────────────────────────────
declare -A MSG=(
  [TITLE]="CubiVeil — Install Aliases"
  [INSTALLING_CLI]="Установка CLI..."
  [INSTALLING_ALIASES]="Установка алиасов..."
  [SUCCESS_CLI]="✓ CLI установлен в"
  [SUCCESS_ALIASES]="✓ Алиасы установлены в"
  [SUCCESS]="Готово! Теперь вы можете запускать утилиты так:"
  [EXAMPLE]="  cubiveil monitor"
  [REQUIRES_ROOT]="Требуется запуск от root"
  [ERR_INSTALL]="Не удалось установить"
)

msg() {
  local key="$1"
  echo "${MSG[$key]:-$key}"
}

# ══════════════════════════════════════════════════════════════
# Проверка окружения
# ══════════════════════════════════════════════════════════════

step_check_environment() {
  if [[ $EUID -ne 0 ]]; then
    err "$(msg REQUIRES_ROOT)"
  fi

  # Проверка что cubiveil.sh существует
  if [[ ! -f "${SCRIPT_DIR}/cubiveil.sh" ]]; then
    err "cubiveil.sh не найден"
  fi

  success "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# Установка CLI в /usr/local/bin
# ══════════════════════════════════════════════════════════════

step_install_cli() {
  info "$(msg INSTALLING_CLI)..."

  # Создаём symlink
  ln -sf "${SCRIPT_DIR}/cubiveil.sh" "${CUBIVEIL_CLI}"
  chmod +x "${CUBIVEIL_CLI}"

  if [[ -x "${CUBIVEIL_CLI}" ]]; then
    success "$(msg SUCCESS_CLI) ${CUBIVEIL_CLI}"
  else
    err "$(msg ERR_INSTALL) ${CUBIVEIL_CLI}"
  fi
}

# ══════════════════════════════════════════════════════════════
# Установка алиасов для коротких команд
# ══════════════════════════════════════════════════════════════

step_install_aliases() {
  info "$(msg INSTALLING_ALIASES)..."

  # Создаём директорию для алиасов
  mkdir -p "$(dirname "${ALIASES_FILE}")"

  # Создаём файл с алиасами
  cat > "${ALIASES_FILE}" << 'EOF'
# CubiVeil Aliases
alias cv='cubiveil'
alias cv-update='cubiveil update'
alias cv-rollback='cubiveil rollback'
alias cv-export='cubiveil export'
alias cv-monitor='cubiveil monitor'
alias cv-diagnose='cubiveil diagnose'
alias cv-profiles='cubiveil profiles'
alias cv-backup='cubiveil backup'
EOF

  chmod 644 "${ALIASES_FILE}"
  success "$(msg SUCCESS_ALIASES) ${ALIASES_FILE}"

  # Добавляем загрузку алиасов в .bashrc если нужно
  if ! grep -q "bash_aliases.d" /root/.bashrc 2>/dev/null; then
    cat >> /root/.bashrc << 'EOF'

# Load CubiVeil aliases
if [ -d /etc/bash_aliases.d ]; then
  for alias_file in /etc/bash_aliases.d/*; do
    [ -f "$alias_file" ] && source "$alias_file"
  done
fi
EOF
    success "Алиасы добавлены в /root/.bashrc"
  fi

  # Загружаем алиасы в текущую сессию
  if [[ -f "${ALIASES_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${ALIASES_FILE}" 2>/dev/null || true
  fi
}

# ══════════════════════════════════════════════════════════════
# Завершение
# ══════════════════════════════════════════════════════════════

step_finish() {
  echo ""
  success "$(msg SUCCESS)"
  echo ""
  echo "  $(msg EXAMPLE)"
  echo "  cv monitor"
  echo "  cv backup create"
  echo "  cv profiles list"
  echo ""
  echo "  Или с полным путём:"
  echo "  sudo cubiveil monitor"
  echo ""
  info "Для применения алиасов в новых сессиях:"
  echo "  source /root/.bashrc"
  echo ""
}

# ══════════════════════════════════════════════════════════════
# Точка входа
# ══════════════════════════════════════════════════════════════

main() {
  select_language

  step_check_environment
  step_install_cli
  step_install_aliases
  step_finish
}

main "$@"
