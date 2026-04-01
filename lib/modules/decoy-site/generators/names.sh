#!/usr/bin/env bash
#
# generators/names.sh - Генератор названий сайтов
# Формат: <прилагательное> <существительное> <тип>
# Поддержка RU и EN, минимум 10 000 уникальных комбинаций
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Словари прилагательных (EN)
# shellcheck disable=SC2034
ADJECTIVES_EN=(
  # Технологии
  "Digital" "Smart" "Cyber" "Tech" "Quantum" "Neural" "Virtual" "Cloud"
  "Data" "Info" "Net" "Web" "Hyper" "Mega" "Ultra" "Super"
  # Природа
  "Ocean" "Forest" "Mountain" "River" "Sky" "Storm" "Thunder" "Lightning"
  "Solar" "Lunar" "Crystal" "Amber" "Silver" "Golden" "Iron" "Steel"
  # Космос
  "Cosmic" "Stellar" "Galactic" "Nebula" "Astro" "Lunar" "Solar" "Orbital"
  "Space" "Star" "Planet" "Comet" "Meteor" "Void" "Dark" "Light"
  # Абстракция
  "Prime" "Alpha" "Beta" "Omega" "Delta" "Gamma" "Zenith" "Nexus"
  "Core" "Edge" "Peak" "Apex" "Vertex" "Matrix" "Vector" "Pixel"
  # Архитектура
  "Grand" "Royal" "Imperial" "Noble" "Elite" "Classic" "Modern" "Future"
  "Ancient" "Mystic" "Secret" "Hidden" "Silent" "Swift" "Rapid" "Fast"
)

# shellcheck disable=SC2034
# Словари существительных (EN)
NOUNS_EN=(
  # Технологии
  "Box" "Hub" "Link" "Sync" "Store" "Base" "Zone" "Port"
  "Gate" "Way" "Point" "Net" "Grid" "Mesh" "Chain" "Block"
  # Природа
  "Wave" "Wind" "Fire" "Earth" "Stone" "Leaf" "Tree" "Flower"
  "Rain" "Snow" "Frost" "Mist" "Cloud" "Storm" "Thunder" "Light"
  # Космос
  "Star" "Sun" "Moon" "Sky" "Space" "Void" "Nebula" "Galaxy"
  "Orbit" "Pulse" "Beam" "Ray" "Flare" "Glow" "Spark" "Flame"
  # Абстракция
  "Flow" "Stream" "Pulse" "Wave" "Core" "Edge" "Peak" " Apex"
  "Mind" "Soul" "Spirit" "Dream" "Vision" "Hope" "Trust" "Faith"
  # Архитектура
  "Tower" "Castle" "Palace" "Hall" "Room" "Vault" "Archive" "Library"
  "Temple" "Fortress" "Citadel" "Dome" "Bridge" "Gate" "Portal" "Nexus"
)

# shellcheck disable=SC2034
# Типы продуктов (EN)
TYPES_EN=(
  "Drive" "Vault" "Cloud" "Hub" "Space" "Box" "Store" "Archive"
  "Center" "Portal" "Station" "Depot" "Repository" "Warehouse" "Locker" "Safe"
  "Share" "Sync" "Link" "Connect" "Network" "System" "Platform" "Service"
)

# shellcheck disable=SC2034
# Словари прилагательных (RU)
ADJECTIVES_RU=(
  # Технологии
  "Цифровой" "Умный" "Кибер" "Техно" "Квантовый" "Нейро" "Виртуальный" "Облачный"
  "Дата" "Инфо" "Сетевой" "Веб" "Гипер" "Мега" "Ультра" "Супер"
  # Природа
  "Океан" "Лесной" "Горный" "Речной" "Небесный" "Штормовой" "Громовой" "Молниеносный"
  "Солнечный" "Лунный" "Хрустальный" "Янтарный" "Серебряный" "Золотой" "Железный" "Стальной"
  # Космос
  "Космический" "Звёздный" "Галактический" "Туманный" "Астро" "Лунный" "Солнечный" "Орбитальный"
  "Пространственный" "Звездный" "Планетный" "Кометный" "Метеорный" "Пустотный" "Тёмный" "Светлый"
  # Абстракция
  "Главный" "Альфа" "Бета" "Омега" "Дельта" "Гамма" "Зенит" "Нексус"
  "Ядро" "Край" "Пик" "Вершина" "Вектор" "Матрица" "Векторный" "Пиксель"
  # Архитектура
  "Великий" "Королевский" "Имперский" "Благородный" "Элитный" "Классический" "Современный" "Будущий"
  "Древний" "Мистический" "Тайный" "Скрытый" "Тихий" "Быстрый" "Стремительный" "Скоростной"
)

# shellcheck disable=SC2034
# Словари существительных (RU)
NOUNS_RU=(
  # Технологии
  "Бокс" "Хаб" "Линк" "Синк" "Стор" "База" "Зона" "Порт"
  "Гейт" "Вей" "Пойнт" "Нет" "Грид" "Меш" "Чейн" "Блок"
  # Природа
  "Волна" "Ветер" "Огонь" "Земля" "Камень" "Лист" "Дерево" "Цветок"
  "Дождь" "Снег" "Иней" "Туман" "Облако" "Шторм" "Гром" "Свет"
  # Космос
  "Звезда" "Солнце" "Луна" "Небо" "Космос" "Пустота" "Туманность" "Галактика"
  "Орбита" "Импульс" "Луч" "Сияние" "Вспышка" "Свечение" "Искра" "Пламя"
  # Абстракция
  "Поток" "Струя" "Импульс" "Волна" "Ядро" "Край" "Пик" "Вершина"
  "Разум" "Душа" "Дух" "Мечта" "Видение" "Надежда" "Доверие" "Вера"
  # Архитектура
  "Башня" "Замок" "Дворец" "Зал" "Комната" "Хранилище" "Архив" "Библиотека"
  "Храм" "Крепость" "Цитадель" "Купол" "Мост" "Ворота" "Портал" "Нексус"
)

# shellcheck disable=SC2034
# Типы продуктов (RU)
TYPES_RU=(
  "Диск" "Хранилище" "Облако" "Центр" "Пространство" "Бокс" "Магазин" "Архив"
  "Центр" "Портал" "Станция" "Депо" "Репозиторий" "Склад" "Ящик" "Сейф"
  "Шеринг" "Синхронизация" "Связь" "Подключение" "Сеть" "Система" "Платформа" "Сервис"
)

# Функция для получения случайного элемента массива
random_element() {
  local -n arr=$1
  local len=${#arr[@]}
  local idx
  idx=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ' | awk -v len="$len" '{print int($1 % len)}')
  echo "${arr[$idx]}"
}

# Генерация названия
generate_name() {
  local lang="${1:-en}"
  local adjective noun type

  # Нормализация языка: извлекаем базовый язык (например, из C.UTF-8 -> en)
  case "$lang" in
  ru | RU | русский | Russian | ru_RU*)
    lang="ru"
    ;;
  en | EN | english | English | C* | POSIX | en_US* | en_GB*)
    lang="en"
    ;;
  esac

  case "$lang" in
  ru)
    adjective=$(random_element ADJECTIVES_RU)
    noun=$(random_element NOUNS_RU)
    type=$(random_element TYPES_RU)
    ;;
  en)
    adjective=$(random_element ADJECTIVES_EN)
    noun=$(random_element NOUNS_EN)
    type=$(random_element TYPES_EN)
    ;;
  *)
    echo "Error: Unknown language '$lang'" >&2
    exit 1
    ;;
  esac

  echo "$adjective $noun $type"
}

# Генерация нескольких вариантов
generate_names() {
  local count="${1:-1}"
  local lang="${2:-en}"

  for ((i = 0; i < count; i++)); do
    generate_name "$lang"
  done
}

# Вывод в формате JSON
generate_json() {
  local lang="${1:-en}"
  local name
  name=$(generate_name "$lang")

  # Разбиваем на части
  local parts
  read -ra parts <<<"$name"

  local adjective="${parts[0]}"
  local noun="${parts[1]:-}"
  local type="${parts[2]:-}"

  # Если noun пустой, берём из type
  if [[ -z "$noun" ]]; then
    noun="$type"
    type=""
  fi

  # Формируем slug (URL-friendly)
  local slug
  slug=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')

  cat <<EOF
{
    "full_name": "$name",
    "adjective": "$adjective",
    "noun": "$noun",
    "type": "$type",
    "slug": "$slug",
    "language": "$lang"
}
EOF
}

# Основная функция
main() {
  local lang="en"
  local count=1
  local format="text"

  # Парсинг аргументов
  while [[ $# -gt 0 ]]; do
    case $1 in
    --lang | -l)
      lang="$2"
      shift 2
      ;;
    --count | -c)
      count="$2"
      shift 2
      ;;
    --json | -j)
      format="json"
      shift
      ;;
    --help)
      echo "Usage: $0 [--lang <ru|en>] [--count <N>] [--json]"
      echo ""
      echo "Options:"
      echo "  --lang, -l    Language (ru or en, default: en)"
      echo "  --count, -c   Number of names to generate (default: 1)"
      echo "  --json, -j    Output in JSON format"
      echo "  --help        Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    esac
  done

  if [[ "$format" == "json" ]]; then
    generate_json "$lang"
  else
    generate_names "$count" "$lang"
  fi
}

# Запуск только если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
