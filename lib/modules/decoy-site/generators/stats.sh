#!/bin/bash
# Генератор статистики для V2

SEED=$(date +%s)

# Парсим параметры
while [[ $# -gt 0 ]]; do
  case "$1" in
    --seed)
      SEED="$2"
      shift 2
      ;;
    --users|--files|--storage|--json)
      shift $([[ "$1" == --* ]] && echo 2 || echo 1)
      ;;
    *)
      shift
      ;;
  esac
done

# Генерируем значения на основе SEED (используем только цифры для модуля)
SEED_NUM=$(echo "$SEED" | tr -cd '0-9' | cut -c1-9)
# Если нет цифр или слишком короткий, используем timestamp
[[ ${#SEED_NUM} -lt 9 ]] && SEED_NUM=$(date +%s | cut -c1-9)
# Убеждаемся что это десятичное число
SEED_NUM=$((10#${SEED_NUM}))

users_total=$((SEED_NUM % 500 + 150))
files_total=$((SEED_NUM % 2000 + 500))
storage_total=$((SEED_NUM % 500 + 100))

cat <<EOF
{
  "storage": {
    "total_formatted": "${storage_total}GB",
    "used_formatted": "$((storage_total * 70 / 100))GB",
    "usage_percent": "70%"
  },
  "users": {
    "total": $users_total,
    "online": $((users_total * 30 / 100))
  },
  "content": {
    "total_files": $files_total,
    "total_folders": $((files_total / 10))
  },
  "traffic": {
    "daily_formatted": "$((SEED_MOD % 100 + 50))GB"
  },
  "events": {
    "daily_uploads": $((SEED_MOD % 100 + 20)),
    "daily_downloads": $((SEED_MOD % 200 + 50))
  }
}
EOF
