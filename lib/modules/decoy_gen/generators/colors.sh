#!/usr/bin/env bash
#
# generators/colors.sh - Генератор цветовых схем
# Генерирует согласованные цвета на основе base_hue или темы
#

set -euo pipefail

# Скрипт должен вызываться из корня cubiveil/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

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
    local secondary_offset=$((30 + $(od -An -tu2 -N2 /dev/urandom | tr -d ' ') % 31))
    local secondary_hue=$(( (base_hue + secondary_offset) % 360 ))
    local secondary_sat=65
    local secondary_light=50

    # Accent - акцентный цвет (дополнительный или контрастный)
    local accent_mode=$(od -An -tu1 -N1 /dev/urandom | tr -d ' ' | awk '{print $1 % 3}')
    local accent_hue
    case $accent_mode in
        0) accent_hue=$(( (base_hue + 180) % 360 )) ;;  # Дополнительный
        1) accent_hue=$(( (base_hue + 120) % 360 )) ;;  # Триадный
        2) accent_hue=$(( (base_hue + 90) % 360 )) ;;   # Квадратный
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
        local bg_mode=$(od -An -tu1 -N1 /dev/urandom | tr -d ' ' | awk '{print $1 % 3}')
        case $bg_mode in
            0) bg_light=98 ;;   # Светлый
            1) bg_light=95 ;;   # Очень светлый
            2) bg_light=15 ;;   # Тёмный
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

# Основная функция
main() {
    local base_hue=""
    local theme="auto"

    # Парсинг аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            --hue|-h)
                base_hue="$2"
                shift 2
                ;;
            --theme|-t)
                theme="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [--hue <0-360>] [--theme <ocean|forest|sunset|corporate|dark|light|purple|warm>]"
                echo ""
                echo "Options:"
                echo "  --hue, -h     Base hue (0-360)"
                echo "  --theme, -t   Predefined theme"
                echo "  --help        Show this help"
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    generate_colors "$base_hue" "$theme"
}

# Запуск только если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
