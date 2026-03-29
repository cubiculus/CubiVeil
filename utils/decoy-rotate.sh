#!/bin/bash
# ╔══════════════════════════════════════════════════════╗
# ║  CubiVeil — Decoy Rotate Utility                     ║
# ║  Управление ротацией сайта-прикрытия                 ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

# ── Подключение зависимостей ────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Подключаем локализацию и утилиты
if [[ -f "${PROJECT_ROOT}/lang/main.sh" ]]; then
  source "${PROJECT_ROOT}/lang/main.sh"
fi
if [[ -f "${PROJECT_ROOT}/lib/utils.sh" ]]; then
  source "${PROJECT_ROOT}/lib/utils.sh"
fi
if [[ -f "${PROJECT_ROOT}/lib/core/log.sh" ]]; then
  source "${PROJECT_ROOT}/lib/core/log.sh"
fi

# ── Константы ───────────────────────────────────────────────
DECOY_CONFIG="/etc/cubiveil/decoy.json"
DECOY_WEBROOT="/var/www/decoy"
DECOY_ROTATE_TIMER="cubiveil-decoy-rotate"
DECOY_ROTATE_SCRIPT="/usr/local/lib/cubiveil/decoy-rotate.sh"

# ── Проверка прав root ──────────────────────────────────────
check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Эта утилита требует прав root"
    echo "Используйте: sudo bash $0 [command]"
    exit 1
  fi
}

# ── Проверка существования конфига ──────────────────────────
check_config() {
  if [[ ! -f "$DECOY_CONFIG" ]]; then
    log_error "Конфигурация не найдена: $DECOY_CONFIG"
    log_info "Сайт-прикрытие не настроено. Запустите: install.sh --decoy"
    exit 1
  fi
}

# ── Статус ротации ──────────────────────────────────────────
cmd_status() {
  check_config

  log_step "decoy_status" "Статус сайта-прикрытия"

  # Статус таймера
  local timer_status="неактивен"
  if systemctl is-active --quiet "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null; then
    timer_status="активен"
  fi

  # Конфигурация
  local enabled interval hours_limit
  enabled=$(jq -r '.rotation.enabled' "$DECOY_CONFIG" 2>/dev/null || echo "false")
  interval=$(jq -r '.rotation.interval_hours' "$DECOY_CONFIG" 2>/dev/null || echo "3")
  max_size=$(jq -r '.max_total_files_mb' "$DECOY_CONFIG" 2>/dev/null || echo "5000")
  last_rotation=$(jq -r '.rotation.last_rotated_at // "никогда"' "$DECOY_CONFIG" 2>/dev/null || echo "никогда")

  # Файлы
  local file_count total_size
  file_count=$(find "${DECOY_WEBROOT}/files" -type f 2>/dev/null | wc -l)
  total_size=$(du -sh "${DECOY_WEBROOT}/files" 2>/dev/null | cut -f1 || echo "0")

  # Веса типов
  local jpg_weight pdf_weight mp4_weight mp3_weight
  jpg_weight=$(jq -r '.rotation.types.jpg.weight // 0' "$DECOY_CONFIG" 2>/dev/null || echo "0")
  pdf_weight=$(jq -r '.rotation.types.pdf.weight // 0' "$DECOY_CONFIG" 2>/dev/null || echo "0")
  mp4_weight=$(jq -r '.rotation.types.mp4.weight // 0' "$DECOY_CONFIG" 2>/dev/null || echo "0")
  mp3_weight=$(jq -r '.rotation.types.mp3.weight // 0' "$DECOY_CONFIG" 2>/dev/null || echo "0")

  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║         Decoy Site — Статус ротации                 ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""
  echo "📊 Общее состояние:"
  echo "   Ротация:           $([ "$enabled" = "true" ] && echo "✅ Включена" || echo "❌ Выключена")"
  echo "   Таймер:            $timer_status"
  echo "   Интервал:          ${interval} ч."
  echo "   Последняя ротация: $last_rotation"
  echo ""
  echo "📁 Файлы:"
  echo "   Количество:        ${file_count} шт."
  echo "   Общий размер:      ${total_size}"
  echo "   Лимит размера:     ${max_size} MB"
  echo ""
  echo "⚖️ Веса типов файлов:"
  echo "   JPG:  ${jpg_weight}"
  echo "   PDF:  ${pdf_weight}"
  echo "   MP4:  ${mp4_weight}"
  echo "   MP3:  ${mp3_weight} $([ "$mp3_weight" = "0" ] && echo "(отключён)")"
  echo ""
}

# ── Принудительная ротация ──────────────────────────────────
cmd_rotate() {
  check_config

  log_step "decoy_rotate" "Принудительная ротация"

  # Проверяем наличие скрипта ротации
  if [[ ! -f "$DECOY_ROTATE_SCRIPT" ]]; then
    log_error "Скрипт ротации не найден: $DECOY_ROTATE_SCRIPT"
    log_info "Перезапустите модуль: install.sh --decoy"
    exit 1
  fi

  # Запускаем ротацию
  log_info "Запуск ротации..."

  if bash "$DECOY_ROTATE_SCRIPT" 2>&1; then
    log_success "Ротация завершена успешно"
  else
    log_error "Ошибка при ротации"
    exit 1
  fi
}

# ── Список файлов ───────────────────────────────────────────
cmd_files() {
  check_config

  log_step "decoy_files" "Список файлов"

  if [[ ! -d "${DECOY_WEBROOT}/files" ]]; then
    log_error "Директория файлов не найдена: ${DECOY_WEBROOT}/files"
    exit 1
  fi

  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║         Decoy Site — Файлы                          ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""

  # Считаем по типам
  local jpg_count pdf_count mp4_count mp3_count other_count
  jpg_count=$(find "${DECOY_WEBROOT}/files" -name "*.jpg" 2>/dev/null | wc -l)
  pdf_count=$(find "${DECOY_WEBROOT}/files" -name "*.pdf" 2>/dev/null | wc -l)
  mp4_count=$(find "${DECOY_WEBROOT}/files" -name "*.mp4" 2>/dev/null | wc -l)
  mp3_count=$(find "${DECOY_WEBROOT}/files" -name "*.mp3" 2>/dev/null | wc -l)

  echo "📊 По типам:"
  echo "   JPG:  ${jpg_count:-0}"
  echo "   PDF:  ${pdf_count:-0}"
  echo "   MP4:  ${mp4_count:-0}"
  echo "   MP3:  ${mp3_count:-0}"
  echo ""

  # Таблица файлов
  echo "📁 Файлы (отсортированы по дате):"
  echo ""
  printf "   %-30s %10s %s\n" "Имя" "Размер" "Дата"
  echo "   ──────────────────────────────────────────────────"

  find "${DECOY_WEBROOT}/files" -type f -printf '%T+ %s %p\n' 2>/dev/null |
    sort -r | head -20 | while read -r timestamp size path; do
    local filename size_mb date
    filename=$(basename "$path")
    size_mb=$((size / 1048576))
    date=$(echo "$timestamp" | cut -d'+' -f1 | cut -d'.' -f1 | sed 's/T/ /')
    printf "   %-30s %8d MB %s\n" "$filename" "$size_mb" "$date"
  done

  echo ""

  local total_files
  total_files=$(find "${DECOY_WEBROOT}/files" -type f 2>/dev/null | wc -l)
  if [[ $total_files -gt 20 ]]; then
    echo "   ... и ещё $((total_files - 20)) файлов"
  fi
  echo ""
}

# ── Показать конфигурацию ───────────────────────────────────
cmd_config() {
  check_config

  log_step "decoy_config" "Конфигурация"

  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║         Decoy Site — Конфигурация                   ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""

  if command -v jq &>/dev/null; then
    jq '.' "$DECOY_CONFIG"
  else
    cat "$DECOY_CONFIG"
  fi
  echo ""
}

# ── Включить ротацию ────────────────────────────────────────
cmd_enable() {
  check_config

  log_step "decoy_enable" "Включение ротации"

  # Обновляем конфиг
  local tmp_file="${DECOY_CONFIG}.tmp"
  if jq '.rotation.enabled = true' "$DECOY_CONFIG" >"$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$DECOY_CONFIG"
    chmod 600 "$DECOY_CONFIG"
    log_success "Ротация включена"
  else
    rm -f "$tmp_file"
    log_error "Не удалось обновить конфигурацию"
    exit 1
  fi

  # Включаем таймер
  if systemctl enable "${DECOY_ROTATE_TIMER}.timer" >/dev/null 2>&1 &&
    systemctl start "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null; then
    log_success "Таймер ротации запущен"
  else
    log_warn "Таймер не запущен (возможно, не установлен)"
  fi
}

# ── Выключить ротацию ───────────────────────────────────────
cmd_disable() {
  check_config

  log_step "decoy_disable" "Выключение ротации"

  # Обновляем конфиг
  local tmp_file="${DECOY_CONFIG}.tmp"
  if jq '.rotation.enabled = false' "$DECOY_CONFIG" >"$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$DECOY_CONFIG"
    chmod 600 "$DECOY_CONFIG"
    log_success "Ротация выключена"
  else
    rm -f "$tmp_file"
    log_error "Не удалось обновить конфигурацию"
    exit 1
  fi

  # Выключаем таймер
  if systemctl stop "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null &&
    systemctl disable "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null; then
    log_success "Таймер ротации остановлен"
  fi
}

# ── Перезапустить таймер ────────────────────────────────────
cmd_restart() {
  check_config

  log_step "decoy_restart" "Перезапуск таймера"

  if systemctl restart "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null; then
    log_success "Таймер ротации перезапущен"
  else
    log_error "Не удалось перезапустить таймер"
    exit 1
  fi
}

# ── Установить интервал ─────────────────────────────────────
cmd_set_interval() {
  check_config

  local hours="${1:-}"

  if [[ -z "$hours" ]] || ! [[ "$hours" =~ ^[0-9]+$ ]] || [[ "$hours" -lt 1 ]] || [[ "$hours" -gt 168 ]]; then
    echo "Использование: $0 set-interval <часы>"
    echo "  Интервал от 1 до 168 часов (от 1 часа до 1 недели)"
    exit 1
  fi

  log_step "decoy_set_interval" "Установка интервала: ${hours} ч."

  local tmp_file="${DECOY_CONFIG}.tmp"
  if jq ".rotation.interval_hours = ${hours}" "$DECOY_CONFIG" >"$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$DECOY_CONFIG"
    chmod 600 "$DECOY_CONFIG"
    log_success "Интервал установлен: ${hours} ч."

    # Пересоздаём таймер
    source "${PROJECT_ROOT}/lib/modules/decoy-site/rotate.sh" 2>/dev/null || true
    decoy_write_rotate_timer 2>/dev/null || log_warn "Не удалось обновить таймер"
  else
    rm -f "$tmp_file"
    log_error "Не удалось обновить конфигурацию"
    exit 1
  fi
}

# ── Установить лимит размера ────────────────────────────────
cmd_set_limit() {
  check_config

  local limit="${1:-}"

  if [[ -z "$limit" ]] || ! [[ "$limit" =~ ^[0-9]+$ ]] || [[ "$limit" -lt 100 ]]; then
    echo "Использование: $0 set-limit <MB>"
    echo "  Минимальный лимит: 100 MB"
    exit 1
  fi

  log_step "decoy_set_limit" "Установка лимита: ${limit} MB"

  local tmp_file="${DECOY_CONFIG}.tmp"
  if jq ".max_total_files_mb = ${limit}" "$DECOY_CONFIG" >"$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$DECOY_CONFIG"
    chmod 600 "$DECOY_CONFIG"
    log_success "Лимит размера установлен: ${limit} MB"
  else
    rm -f "$tmp_file"
    log_error "Не удалось обновить конфигурацию"
    exit 1
  fi
}

# ── Установить вес типа файла ───────────────────────────────
cmd_set_weight() {
  check_config

  local file_type="${1:-}"
  local weight="${2:-}"

  if [[ -z "$file_type" ]] || [[ -z "$weight" ]]; then
    echo "Использование: $0 set-weight <тип> <вес>"
    echo "  Типы: jpg, pdf, mp4, mp3"
    echo "  Вес: 0-10 (0 = отключить тип)"
    exit 1
  fi

  if ! [[ "$file_type" =~ ^(jpg|pdf|mp4|mp3)$ ]]; then
    log_error "Неверный тип: $file_type (допустимы: jpg, pdf, mp4, mp3)"
    exit 1
  fi

  if ! [[ "$weight" =~ ^[0-9]+$ ]] || [[ "$weight" -gt 10 ]]; then
    log_error "Неверный вес: $weight (допустимо: 0-10)"
    exit 1
  fi

  log_step "decoy_set_weight" "Установка веса ${file_type}: ${weight}"

  local enabled="false"
  if [[ "$weight" -gt 0 ]]; then
    enabled="true"
  fi

  local tmp_file="${DECOY_CONFIG}.tmp"
  if jq ".rotation.types.${file_type}.weight = ${weight} | .rotation.types.${file_type}.enabled = ${enabled}" \
    "$DECOY_CONFIG" >"$tmp_file" 2>/dev/null; then
    mv "$tmp_file" "$DECOY_CONFIG"
    chmod 600 "$DECOY_CONFIG"
    log_success "Вес ${file_type} установлен: ${weight}"
  else
    rm -f "$tmp_file"
    log_error "Не удалось обновить конфигурацию"
    exit 1
  fi
}

# ── Очистка старых файлов ───────────────────────────────────
cmd_cleanup() {
  check_config

  log_step "decoy_cleanup" "Очистка старых файлов"

  if [[ ! -d "${DECOY_WEBROOT}/files" ]]; then
    log_error "Директория файлов не найдена"
    exit 1
  fi

  local max_size
  max_size=$(jq -r '.max_total_files_mb' "$DECOY_CONFIG" 2>/dev/null || echo "5000")

  # Подключаем функцию очистки из rotate.sh
  source "${PROJECT_ROOT}/lib/modules/decoy-site/rotate.sh" 2>/dev/null || {
    log_error "Не удалось загрузить модуль ротации"
    exit 1
  }

  # Запускаем очистку
  _decoy_enforce_size_limit
}

# ── Перегенерация всех файлов ───────────────────────────────
cmd_regenerate() {
  check_config

  log_step "decoy_regenerate" "Перегенерация всех файлов"

  echo ""
  echo "⚠️  ВНИМАНИЕ: Это действие удалит ВСЕ текущие файлы"
  echo "    и сгенерирует новые заново."
  echo ""
  read -r -p "Продолжить? (y/N): " confirm

  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    log_info "Отменено"
    exit 0
  fi

  # Подключаем функции из generate.sh
  source "${PROJECT_ROOT}/lib/modules/decoy-site/generate.sh" 2>/dev/null || {
    log_error "Не удалось загрузить модуль генерации"
    exit 1
  }

  log_info "Остановка таймера ротации..."
  systemctl stop "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null || true

  log_info "Удаление старых файлов..."
  find "${DECOY_WEBROOT}/files" -type f -delete 2>/dev/null || true

  log_info "Генерация новых файлов..."
  decoy_build_webroot

  log_info "Запуск таймера ротации..."
  systemctl start "${DECOY_ROTATE_TIMER}.timer" 2>/dev/null || true

  log_success "Перегенерация завершена"
}

# ── Справка ─────────────────────────────────────────────────
cmd_help() {
  echo ""
  echo "╔══════════════════════════════════════════════════════╗"
  echo "║         Decoy Rotate — Управление ротацией          ║"
  echo "╚══════════════════════════════════════════════════════╝"
  echo ""
  echo "Использование: sudo bash $0 <command> [args]"
  echo ""
  echo "Команды:"
  echo "  status              Показать статус ротации"
  echo "  rotate              Принудительная ротация"
  echo "  files               Список файлов"
  echo "  config              Показать конфигурацию"
  echo ""
  echo "  enable              Включить ротацию"
  echo "  disable             Выключить ротацию"
  echo "  restart             Перезапустить таймер"
  echo ""
  echo "  set-interval <ч>    Установить интервал (1-168 ч)"
  echo "  set-limit <MB>      Установить лимит размера (мин. 100)"
  echo "  set-weight <тип> <вес>"
  echo "                      Установить вес типа (0-10)"
  echo "                      Типы: jpg, pdf, mp4, mp3"
  echo ""
  echo "  cleanup             Очистка старых файлов"
  echo "  regenerate          Перегенерация всех файлов"
  echo ""
  echo "  help                Эта справка"
  echo ""
  echo "Примеры:"
  echo "  sudo bash $0 status"
  echo "  sudo bash $0 rotate"
  echo "  sudo bash $0 set-interval 6"
  echo "  sudo bash $0 set-limit 10000"
  echo "  sudo bash $0 set-weight pdf 3"
  echo ""
}

# ── Основная функция ────────────────────────────────────────
main() {
  check_root

  local command="${1:-help}"
  shift || true

  case "$command" in
  status)
    cmd_status
    ;;
  rotate)
    cmd_rotate
    ;;
  files)
    cmd_files
    ;;
  config)
    cmd_config
    ;;
  enable)
    cmd_enable
    ;;
  disable)
    cmd_disable
    ;;
  restart)
    cmd_restart
    ;;
  set-interval)
    cmd_set_interval "$@"
    ;;
  set-limit)
    cmd_set_limit "$@"
    ;;
  set-weight)
    cmd_set_weight "$@"
    ;;
  cleanup)
    cmd_cleanup
    ;;
  regenerate)
    cmd_regenerate
    ;;
  help | --help | -h)
    cmd_help
    ;;
  *)
    log_error "Неизвестная команда: $command"
    echo "Используйте '$0 help' для справки"
    exit 1
    ;;
  esac
}

main "$@"
