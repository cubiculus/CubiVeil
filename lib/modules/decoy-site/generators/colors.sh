#!/bin/bash
# shellcheck disable=SC1071
# Генератор цветовых схем для V2
set -euo pipefail

THEME="auto"
OUTPUT_MODE="json" # json или css
OUTPUT_DIR="."

# Парсим параметры
while [[ $# -gt 0 ]]; do
  case "$1" in
  --theme)
    THEME="$2"
    shift 2
    ;;
  --output)
    OUTPUT_DIR="$2"
    shift 2
    ;;
  --css)
    OUTPUT_MODE="css"
    shift
    ;;
  --json)
    OUTPUT_MODE="json"
    shift
    ;;
  *)
    shift
    ;;
  esac
done

# Цветовые палитры
declare -A THEMES=(
  [dark]="primary=2c3e50,secondary=34495e,accent=3498db"
  [light]="primary=ecf0f1,secondary=bdc3c7,accent=3498db"
  [blue]="primary=0052cc,secondary=0079bf,accent=2684ff"
  [warm]="primary=f39c12,secondary=e67e22,accent=e74c3c"
  [corporate]="primary=1e3a8a,secondary=2563eb,accent=3b82f6"
  [ocean]="primary=0369a1,secondary=0284c7,accent=06b6d4"
  [forest]="primary=166534,secondary=22c55e,accent=84cc16"
)

# Если auto - выбираем случайно
if [[ "$THEME" == "auto" ]]; then
  keys=("${!THEMES[@]}")
  idx=$((RANDOM % ${#keys[@]}))
  THEME="${keys[$idx]}"
fi

# Получить палитру или вернуть default
PALETTE="${THEMES[$THEME]:-${THEMES[blue]}}"

case "$OUTPUT_MODE" in
json)
  # Парсим палитру
  IFS=',' read -r primary secondary accent <<<"$PALETTE"
  # Выделяем значения цветов
  primary="${primary##*=}"
  secondary="${secondary##*=}"
  accent="${accent##*=}"
  echo "{"
  echo "  \"theme\": \"$THEME\","
  echo "  \"primary\": \"#$primary\","
  echo "  \"secondary\": \"#$secondary\","
  echo "  \"accent\": \"#$accent\""
  echo "}"
  ;;
css)
  # Парсим палитру
  IFS=',' read -r primary secondary accent <<<"$PALETTE"
  # Выделяем значения цветов
  primary="${primary##*=}"
  secondary="${secondary##*=}"
  accent="${accent##*=}"
  
  # Конвертируем hex в RGB для использования с rgba()
  # Функция для конвертации hex в RGB
  hex_to_rgb() {
    local hex="$1"
    # Удаляем # если есть
    hex="${hex#\#}"
    # Конвертируем hex в decimal
    printf "%d %d %d" 0x"${hex:0:2}" 0x"${hex:2:2}" 0x"${hex:4:2}"
  }
  
  # Получаем RGB значения
  read -r prr prg prb <<< "$(hex_to_rgb "$primary")"
  read -r scr scg scb <<< "$(hex_to_rgb "$secondary")"
  
  # Генерируем CSS с полученными цветами
  cat >"${OUTPUT_DIR}/colors.css" <<EOF
:root {
  --color-primary: #${primary};
  --color-primary-rgb: ${prr},${prg},${prb};
  --color-secondary: #${secondary};
  --color-secondary-rgb: ${scr},${scg},${scb};
  --color-accent: #${accent};
  --color-bg: #ffffff;
  --color-text: #333333;
  --color-border: #e0e0e0;
}

body.dark-theme {
  --color-bg: #1a1a1a;
  --color-text: #ffffff;
  --color-border: #333333;
}
EOF
  ;;
esac
