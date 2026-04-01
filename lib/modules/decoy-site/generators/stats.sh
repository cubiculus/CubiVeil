#!/usr/bin/env bash
#
# generators/stats.sh - Генератор статистики сайта
# Генерирует консистентные числа для фейкового хранилища
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Функция для получения случайного числа в диапазоне
random_range() {
  local min=$1
  local max=$2
  local range=$((max - min + 1))
  local rand
  rand=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ')
  echo $((min + rand % range))
}

# Форматирование размера в человекочитаемый формат
format_size() {
  local bytes=$1

  if [[ $bytes -ge 1099511627776 ]]; then
    awk -v b="$bytes" 'BEGIN { printf "%.2f TB", b / 1099511627776 }'
  elif [[ $bytes -ge 1073741824 ]]; then
    awk -v b="$bytes" 'BEGIN { printf "%.2f GB", b / 1073741824 }'
  elif [[ $bytes -ge 1048576 ]]; then
    awk -v b="$bytes" 'BEGIN { printf "%.2f MB", b / 1048576 }'
  elif [[ $bytes -ge 1024 ]]; then
    awk -v b="$bytes" 'BEGIN { printf "%.2f KB", b / 1024 }'
  else
    echo "${bytes} B"
  fi
}

# Генерация статистики
generate_stats() {
  local seed="${1:-}"
  local users_count="${2:-}"
  local files_count="${3:-}"
  local storage_size="${4:-}"

  # Используем seed для воспроизводимости если передан
  if [[ -n "$seed" ]]; then
    # Псевдо-случайность на основе seed
    local hash
    hash=$(echo -n "$seed" | md5sum | cut -c1-8)
    local seed_val=$((16#$hash))

    # Функция псевдо-случайности
    pseudo_random() {
      local min=$1
      local max=$2
      seed_val=$(((seed_val * 1103515245 + 12345) % 2147483648))
      local range=$((max - min + 1))
      echo $((min + (seed_val % range)))
    }

    rand_range_func=pseudo_random
  else
    rand_range_func=random_range
  fi

  # Total storage: 500GB - 20TB (в байтах)
  if [[ -n "$storage_size" ]]; then
    total_storage=$storage_size
  else
    # 500GB = 536870912000, 20TB = 21990232555520
    local storage_tb
    storage_tb=$($rand_range_func 500 20000)
    total_storage=$((storage_tb * 1073741824))
  fi

  # Used storage: 20-85% от total
  local used_percent
  used_percent=$($rand_range_func 20 85)
  used_storage=$((total_storage * used_percent / 100))

  # Free storage
  free_storage=$((total_storage - used_storage))

  # Total users: 10-500
  if [[ -n "$users_count" ]]; then
    total_users=$users_count
  else
    total_users=$($rand_range_func 10 500)
  fi

  # Active users: 30-80% от total
  local active_percent
  active_percent=$($rand_range_func 30 80)
  active_users=$((total_users * active_percent / 100))

  # Online users: 5-25% от active
  local online_percent
  online_percent=$($rand_range_func 5 25)
  online_users=$((active_users * online_percent / 100))
  if [[ $online_users -lt 1 ]]; then
    online_users=1
  fi

  # Total files: 1000-500000
  if [[ -n "$files_count" ]]; then
    total_files=$files_count
  else
    total_files=$($rand_range_func 1000 500000)
  fi

  # Total folders: 100-50000 (примерно 10% от файлов)
  local folder_ratio
  folder_ratio=$($rand_range_func 8 15)
  total_folders=$((total_files * folder_ratio / 100))
  if [[ $total_folders -lt 100 ]]; then
    total_folders=100
  fi
  if [[ $total_folders -gt 50000 ]]; then
    total_folders=50000
  fi

  # Daily traffic: коррелирует с числом пользователей (1-10 GB на пользователя)
  local traffic_per_user
  traffic_per_user=$($rand_range_func 1 10)
  daily_traffic=$((active_users * traffic_per_user * 1048576))

  # Weekly traffic
  weekly_traffic=$((daily_traffic * 7))

  # Monthly traffic
  monthly_traffic=$((daily_traffic * 30))

  # Events (logins, uploads, errors)
  # Logins: примерно 2-5 в день на активного пользователя
  local logins_per_user
  logins_per_user=$($rand_range_func 2 5)
  daily_logins=$((active_users * logins_per_user))

  # Uploads: 1-3 в день на активного пользователя
  local uploads_per_user
  uploads_per_user=$($rand_range_func 1 3)
  daily_uploads=$((active_users * uploads_per_user))

  # Downloads: 5-15 в день на активного пользователя
  local downloads_per_user
  downloads_per_user=$($rand_range_func 5 15)
  daily_downloads=$((active_users * downloads_per_user))

  # Errors: 0.1-2% от операций
  local error_rate
  error_rate=$($rand_range_func 1 20)
  daily_errors=$(((daily_logins + daily_uploads + daily_downloads) * error_rate / 1000))

  # Shares: 1-5 в день на активного пользователя
  local shares_per_user
  shares_per_user=$($rand_range_func 1 5)
  daily_shares=$((active_users * shares_per_user))

  # Комментарии/аннотации: 0.5-2 на пользователя
  local comments_per_user
  comments_per_user=$($rand_range_func 5 20)
  total_comments=$((total_users * comments_per_user / 10))

  # Группы/команды
  local groups_per_users
  groups_per_users=$($rand_range_func 20 50)
  total_groups=$((total_users / groups_per_users))
  if [[ $total_groups -lt 1 ]]; then
    total_groups=1
  fi

  # Вывод в формате JSON
  cat <<EOF
{
    "storage": {
        "total": $total_storage,
        "used": $used_storage,
        "free": $free_storage,
        "total_formatted": "$(format_size $total_storage)",
        "used_formatted": "$(format_size $used_storage)",
        "free_formatted": "$(format_size $free_storage)",
        "usage_percent": $used_percent
    },
    "users": {
        "total": $total_users,
        "active": $active_users,
        "online": $online_users,
        "active_percent": $active_percent,
        "online_percent": $online_percent
    },
    "content": {
        "total_files": $total_files,
        "total_folders": $total_folders,
        "total_comments": $total_comments,
        "total_groups": $total_groups
    },
    "traffic": {
        "daily": $daily_traffic,
        "weekly": $weekly_traffic,
        "monthly": $monthly_traffic,
        "daily_formatted": "$(format_size $daily_traffic)",
        "weekly_formatted": "$(format_size $weekly_traffic)",
        "monthly_formatted": "$(format_size $monthly_traffic)"
    },
    "events": {
        "daily_logins": $daily_logins,
        "daily_uploads": $daily_uploads,
        "daily_downloads": $daily_downloads,
        "daily_shares": $daily_shares,
        "daily_errors": $daily_errors
    }
}
EOF
}

# Основная функция
main() {
  local seed=""
  local users_count=""
  local files_count=""
  local storage_size=""

  # Парсинг аргументов
  while [[ $# -gt 0 ]]; do
    case $1 in
    --seed | -s)
      seed="$2"
      shift 2
      ;;
    --users | -u)
      users_count="$2"
      shift 2
      ;;
    --files | -f)
      files_count="$2"
      shift 2
      ;;
    --storage)
      storage_size="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--seed <seed>] [--users <N>] [--files <N>] [--storage <bytes>]"
      echo ""
      echo "Options:"
      echo "  --seed, -s      Seed for reproducible generation"
      echo "  --users, -u     Override total users count"
      echo "  --files, -f     Override total files count"
      echo "  --storage       Override total storage in bytes"
      echo "  --help          Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  generate_stats "$seed" "$users_count" "$files_count" "$storage_size"
}

# Запуск только если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
