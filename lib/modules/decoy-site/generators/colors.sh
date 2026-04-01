#!/usr/bin/env bash
#
# generators/colors.sh - Генератор цветовых схем
# Генерирует согласованные цвета на основе base_hue или темы
#

set -euo pipefail

# Скрипт должен вызываться из корня cubiveil/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Логирование
log_info() {
  echo "[INFO] $*" >&2
}

log_success() {
  echo "[SUCCESS] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

# Функция для конвертации HSL в HEX
hsl_to_hex() {
  local h=$1
  local s=$2
  local l=$3

  # Нормализация hue
  h=$((h % 360))
  if [[ $h -lt 0 ]]; then
    h=$((h + 360))
  fi

  # Конвертация через awk для точности
  awk -v h="$h" -v s="$s" -v l="$l" 'BEGIN {
        s = s / 100
        l = l / 100

        c = (1 - (2 * l - 1 < 0 ? -(2 * l - 1) : (2 * l - 1))) * s
        x = c * (1 - ((h / 60) % 2 - 1 < 0 ? -((h / 60) % 2 - 1) : ((h / 60) % 2 - 1)))
        m = l - c / 2

        if (h < 60) { r = c; g = x; b = 0 }
        else if (h < 120) { r = x; g = c; b = 0 }
        else if (h < 180) { r = 0; g = c; b = x }
        else if (h < 240) { r = 0; g = x; b = c }
        else if (h < 300) { r = x; g = 0; b = c }
        else { r = c; g = 0; b = x }

        r = int((r + m) * 255 + 0.5)
        g = int((g + m) * 255 + 0.5)
        b = int((b + m) * 255 + 0.5)

        printf "#%02x%02x%02x\n", r, g, b
    }'
}

# Предопределённые темы
declare -A THEMES
THEMES=(
  ["ocean"]="200"
  ["forest"]="140"
  ["sunset"]="30"
  ["corporate"]="220"
  ["dark"]="230"
  ["light"]="200"
  ["purple"]="270"
  ["warm"]="25"
)

# Генерация цветовой схемы
generate_colors() {
  local base_hue="${1:-}"
  local theme="${2:-auto}"

  # Если передана тема, используем её
  if [[ -n "$theme" && "$theme" != "auto" ]]; then
    if [[ -v "THEMES[$theme]" ]]; then
      base_hue="${THEMES[$theme]}"
    else
      echo "Error: Unknown theme '$theme'" >&2
      exit 1
    fi
  fi

  # Если base_hue не передан, генерируем случайный
  if [[ -z "$base_hue" ]]; then
    base_hue=$(od -An -tu2 -N2 /dev/urandom | tr -d ' ' | awk '{print $1 % 360}')
  fi

  # Гарантируем, что base_hue в диапазоне 0-360
  base_hue=$((base_hue % 360))

  # Генерируем вариации для разных цветов
  # Primary - основной цвет
  local primary_hue=$base_hue
  local primary_sat=75
  local primary_light=45

  # Secondary - вторичный цвет (смещение на 30-60 градусов)
  local secondary_offset
  secondary_offset=$((30 + $(od -An -tu2 -N2 /dev/urandom | tr -d ' ') % 31))
  local secondary_hue=$(((base_hue + secondary_offset) % 360))
  local secondary_sat=65
  local secondary_light=50

  # Accent - акцентный цвет (дополнительный или контрастный)
  local accent_mode=$(od -An -tu1 -N1 /dev/urandom | tr -d ' ' | awk '{print $1 % 3}')
  local accent_hue
  case $accent_mode in
  0) accent_hue=$(((base_hue + 180) % 360)) ;; # Дополнительный
  1) accent_hue=$(((base_hue + 120) % 360)) ;; # Триадный
  2) accent_hue=$(((base_hue + 90) % 360)) ;;  # Квадратный
  esac
  local accent_sat=80
  local accent_light=55

  # Background - фон (зависит от темы)
  local bg_light
  if [[ "$theme" == "dark" ]]; then
    bg_light=12
  elif [[ "$theme" == "light" ]]; then
    bg_light=98
  else
    local bg_mode
    bg_mode=$(od -An -tu1 -N1 /dev/urandom | tr -d ' ' | awk '{print $1 % 3}')
    case $bg_mode in
    0) bg_light=98 ;; # Светлый
    1) bg_light=95 ;; # Очень светлый
    2) bg_light=15 ;; # Тёмный
    esac
  fi
  local bg_sat=15
  local bg_hue=$base_hue

  # Text - текст (контрастный к фону)
  local text_light
  if [[ $bg_light -lt 50 ]]; then
    text_light=95
  else
    text_light=15
  fi
  local text_sat=10
  local text_hue=$base_hue

  # Border - границы
  local border_light
  if [[ $bg_light -lt 50 ]]; then
    border_light=25
  else
    border_light=85
  fi
  local border_sat=20
  local border_hue=$base_hue

  # Генерируем HEX значения
  local primary secondary accent background text border

  primary=$(hsl_to_hex $primary_hue $primary_sat $primary_light)
  secondary=$(hsl_to_hex $secondary_hue $secondary_sat $secondary_light)
  accent=$(hsl_to_hex $accent_hue $accent_sat $accent_light)
  background=$(hsl_to_hex $bg_hue $bg_sat $bg_light)
  text=$(hsl_to_hex $text_hue $text_sat $text_light)
  border=$(hsl_to_hex $border_hue $border_sat $border_light)

  # Вывод в формате JSON
  cat <<EOF
{
    "primary": "$primary",
    "secondary": "$secondary",
    "accent": "$accent",
    "background": "$background",
    "text": "$text",
    "border": "$border",
    "base_hue": $base_hue,
    "theme": "${theme:-custom}"
}
EOF
}

# ── Генерация CSS файла ────────────────────────────────────────────────────────

# Генерация style.css из base.css с подстановкой цветов
generate_css_file() {
  local output_dir="$1"
  local colors_json="$2"

  # Путь к base.css (в _shared)
  local templates_dir="$ROOT_DIR/templates"
  local base_css="$templates_dir/_shared/base.css"
  local output_css="$output_dir/style.css"

  if [[ ! -f "$base_css" ]]; then
    log_error "base.css not found at $base_css"
    return 1
  fi

  # Извлекаем цвета из JSON
  local primary secondary accent background text border
  primary=$(echo "$colors_json" | jq -r '.primary')
  secondary=$(echo "$colors_json" | jq -r '.secondary')
  accent=$(echo "$colors_json" | jq -r '.accent')
  background=$(echo "$colors_json" | jq -r '.background')
  text=$(echo "$colors_json" | jq -r '.text')
  border=$(echo "$colors_json" | jq -r '.border')

  # Копируем base.css в output как style.css и заменяем плейсхолдеры
  cp "$base_css" "$output_css"

  # Заменяем плейсхолдеры на реальные цвета
  # Используем | как разделитель в sed чтобы избежать проблем с /
  sed -i "s|{{PRIMARY_COLOR}}|$primary|g" "$output_css"
  sed -i "s|{{SECONDARY_COLOR}}|$secondary|g" "$output_css"
  sed -i "s|{{ACCENT_COLOR}}|$accent|g" "$output_css"
  sed -i "s|{{BACKGROUND_COLOR}}|$background|g" "$output_css"
  sed -i "s|{{TEXT_COLOR}}|$text|g" "$output_css"
  sed -i "s|{{BORDER_COLOR}}|$border|g" "$output_css"

  log_info "Generated style.css with colors: primary=$primary, background=$background"

  # Возвращаем путь к сгенерированному файлу
  echo "$output_css"
}

# Основная функция
main() {
  local base_hue=""
  local theme="auto"
  local output_dir=""
  local generate_css_flag=false
  local input_colors=""

  # Парсинг аргументов
  while [[ $# -gt 0 ]]; do
    case $1 in
    --hue | -h)
      base_hue="$2"
      shift 2
      ;;
    --theme | -t)
      theme="$2"
      shift 2
      ;;
    --output | -o)
      output_dir="$2"
      shift 2
      ;;
    --css)
      generate_css_flag=true
      shift
      ;;
    --help)
      echo "Usage: $0 [--hue <0-360>] [--theme <ocean|forest|sunset|corporate|dark|light|purple|warm>]"
      echo ""
      echo "Options:"
      echo "  --hue, -h     Base hue (0-360)"
      echo "  --theme, -t   Predefined theme"
      echo "  --output, -o  Output directory for CSS file"
      echo "  --css         Generate CSS file instead of JSON"
      echo "  --help        Show this help"
      exit 0
      ;;
    *)
      # Если это не флаг, считаем что это input colors JSON
      if [[ "$1" != -* ]]; then
        input_colors="$1"
      fi
      shift
      ;;
    esac
  done

  # Генерируем цвета или используем input
  local colors_json
  if [[ -n "$input_colors" ]]; then
    colors_json="$input_colors"
  else
    colors_json=$(generate_colors "$base_hue" "$theme")
  fi

  # Если флаг --css и указана output_dir, генерируем CSS
  if [[ "$generate_css_flag" == "true" && -n "$output_dir" ]]; then
    generate_css_file "$output_dir" "$colors_json"
  else
    # Вывод JSON
    echo "$colors_json"
  fi
}

# Запуск только если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
