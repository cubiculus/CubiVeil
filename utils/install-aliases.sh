#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Install Aliases                       ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Установка алиасов для удобного запуска утилит            ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение локализации ───────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"

# Подключаем i18n модуль для единых функций локализации
if [[ -f "${PROJECT_DIR}/lib/i18n.sh" ]]; then
  source "${PROJECT_DIR}/lib/i18n.sh"
elif [[ -f "${PROJECT_DIR}/lang/main.sh" ]]; then
  source "${PROJECT_DIR}/lang/main.sh"
else
  source "${PROJECT_DIR}/lib/fallback.sh"
fi

# ── Подключение унифицированных функций вывода ───────────────
source "${PROJECT_DIR}/lib/output.sh" || {
  echo "❌ Не удалось загрузить lib/output.sh" >&2
  exit 1
}

# ── Константы ─────────────────────────────────────────────────
ALIASES_FILE="/etc/bash_aliases.d/cubiveil"

# ── Локализация ───────────────────────────────────────────────
declare -A MSG=(
  [TITLE]="CubiVeil — Install Aliases"
  [INSTALLING_ALIASES]="Установка алиасов..."
  [SUCCESS_ALIASES]="✓ Алиасы установлены в"
  [SUCCESS]="Готово! Теперь вы можете запускать утилиты так:"
  [EXAMPLE]="  cv-monitor"
  [REQUIRES_ROOT]="Требуется запуск от root"
  [ERR_INSTALL]="Не удалось установить"
)

# Функция msg импортируется из lib/i18n.sh

# ══════════════════════════════════════════════════════════════
# Проверка окружения
# ══════════════════════════════════════════════════════════════

step_check_environment() {
  if [[ $EUID -ne 0 ]]; then
    err "$(msg REQUIRES_ROOT)"
  fi

  # Проверка что основные утилиты существуют
  local required_utils=("backup.sh" "update.sh" "rollback.sh" "monitor.sh" "diagnose.sh")
  for util in "${required_utils[@]}"; do
    if [[ ! -f "${PROJECT_DIR}/utils/${util}" ]]; then
      err "utils/${util} не найден"
    fi
  done

  success "Окружение проверено"
}

# ══════════════════════════════════════════════════════════════
# Установка алиасов для коротких команд
# ══════════════════════════════════════════════════════════════

step_install_aliases() {
  info "$(msg INSTALLING_ALIASES)..."

  # Создаём директорию для алиасов
  mkdir -p "$(dirname "${ALIASES_FILE}")"

  # Создаём файл с алиасами
  cat >"${ALIASES_FILE}" <<EOF
# CubiVeil Aliases
# Прямые алиасы на утилиты
alias cv-monitor='sudo bash ${PROJECT_DIR}/utils/monitor.sh'
alias cv-backup='sudo bash ${PROJECT_DIR}/utils/backup.sh'
alias cv-update='sudo bash ${PROJECT_DIR}/utils/update.sh'
alias cv-rollback='sudo bash ${PROJECT_DIR}/utils/rollback.sh'
alias cv-export='sudo bash ${PROJECT_DIR}/utils/export-config.sh'
alias cv-import='sudo bash ${PROJECT_DIR}/utils/import-config.sh'
alias cv-diagnose='sudo bash ${PROJECT_DIR}/utils/diagnose.sh'
EOF

  chmod 644 "${ALIASES_FILE}"
  success "$(msg SUCCESS_ALIASES) ${ALIASES_FILE}"

  # Добавляем загрузку алиасов в .bashrc если нужно
  if ! grep -q "bash_aliases.d" /root/.bashrc 2>/dev/null; then
    cat >>/root/.bashrc <<'EOF'

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
  echo "  cv-monitor"
  echo "  cv-backup"
  echo "  cv-update"
  echo "  cv-rollback"
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
  step_install_aliases
  step_finish
}

main "$@"
