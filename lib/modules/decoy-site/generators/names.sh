#!/bin/bash
# Генератор имен и описаний для V2
set -euo pipefail

LANG="en"
OUTPUT_MODE="json"

# Парсим параметры
while [[ $# -gt 0 ]]; do
  case "$1" in
  --lang)
    LANG="$2"
    shift 2
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

declare -A SITE_NAMES_EN=(
  [company]="TechCorp Solutions"
  [startup]="InnovateLab"
  [agency]="Digital Forge"
  [studio]="Creative Canvas"
  [store]="OnlineHub"
  [blog]="TechInsights"
  [portfolio]="DevShowcase"
  [saas]="CloudSync Pro"
)

declare -A SITE_NAMES_RU=(
  [company]="ТехКорп"
  [startup]="ИнноваЛаб"
  [agency]="ЦифроваяКузница"
  [studio]="ТворческийХолст"
  [store]="ОнлайнХаб"
  [blog]="ТехСведения"
  [portfolio]="ПоказВозможностей"
  [saas]="ОблачнаяСинхро"
)

case "$OUTPUT_MODE" in
json)
  if [[ "$LANG" == "ru" ]]; then
    echo "{"
    first=true
    for key in "${!SITE_NAMES_RU[@]}"; do
      if [[ "$first" == "true" ]]; then
        echo "  \"$key\": \"${SITE_NAMES_RU[$key]}\","
        first=false
      else
        echo "  \"$key\": \"${SITE_NAMES_RU[$key]}\","
      fi
    done
    echo "  \"full_name\": \"${SITE_NAMES_RU[company]}\""
    echo "}"
  else
    echo "{"
    first=true
    for key in "${!SITE_NAMES_EN[@]}"; do
      if [[ "$first" == "true" ]]; then
        echo "  \"$key\": \"${SITE_NAMES_EN[$key]}\","
        first=false
      else
        echo "  \"$key\": \"${SITE_NAMES_EN[$key]}\","
      fi
    done
    echo "  \"full_name\": \"${SITE_NAMES_EN[company]}\""
    echo "}"
  fi
  ;;
esac
