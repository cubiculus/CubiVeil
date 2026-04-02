#!/bin/bash
# shellcheck disable=SC1071
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Module Initializer                    ║
# ║          github.com/cubiculus/cubiveil                    ║
# ║                                                           ║
# ║  Централизованная загрузка всех модулей в правильном      ║
# ║  порядке для избежания циклических зависимостей           ║
# ╚═══════════════════════════════════════════════════════════╝

# Guard check - не подключать повторно
if [[ -n "${_CUBIVEIL_INIT_LOADED:-}" ]]; then
  return 0
fi
_CUBIVEIL_INIT_LOADED=1

# ── Определение директории скрипта ──────────────────────────────
INIT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ═══════════════════════════════════════════════════════════════
# Уровень 0: Базовые модули (нет зависимостей от других lib/*.sh)
# ═══════════════════════════════════════════════════════════════

# Output functions - базовый модуль вывода
if [[ -f "${INIT_SCRIPT_DIR}/output.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/output.sh"
fi

# Validation - валидация пользовательского ввода
if [[ -f "${INIT_SCRIPT_DIR}/validation.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/validation.sh"
fi

# ═══════════════════════════════════════════════════════════════
# Уровень 1: Модули с зависимостями от Уровня 0
# ═══════════════════════════════════════════════════════════════

# I18n - локализация (зависит от output.sh)
if [[ -f "${INIT_SCRIPT_DIR}/i18n.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/i18n.sh"
fi

# Security - модуль безопасности (зависит от output.sh)
if [[ -f "${INIT_SCRIPT_DIR}/security.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/security.sh"
fi

# Common - общие функции (зависит от output.sh)
if [[ -f "${INIT_SCRIPT_DIR}/common.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/common.sh"
fi

# Fallback - резервные функции (зависит от output.sh)
if [[ -f "${INIT_SCRIPT_DIR}/fallback.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/fallback.sh"
fi

# ═══════════════════════════════════════════════════════════════
# Уровень 2: Модули с зависимостями от Уровня 1
# ═══════════════════════════════════════════════════════════════

# Utils - утилиты (зависит от i18n.sh, validation.sh)
if [[ -f "${INIT_SCRIPT_DIR}/utils.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/utils.sh"
fi

# ═══════════════════════════════════════════════════════════════
# Уровень 3: Core модули
# ═══════════════════════════════════════════════════════════════

# Core Log - логирование (зависит от output.sh, i18n.sh)
if [[ -f "${INIT_SCRIPT_DIR}/core/log.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/core/log.sh"
fi

# Core System - системные функции (нет зависимостей от lib/*.sh)
if [[ -f "${INIT_SCRIPT_DIR}/core/system.sh" ]]; then
  source "${INIT_SCRIPT_DIR}/core/system.sh"
fi
