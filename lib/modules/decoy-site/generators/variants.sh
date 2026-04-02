#!/usr/bin/env bash
# shellcheck disable=SC1071
# ══════════════════════════════════════════════════════════════
#  CubiVeil — Decoy Site Variants
#  Все типы сайтов-прикрытий в одном месте.
#  Добавить новый тип = добавить одну секцию case ниже.
# ══════════════════════════════════════════════════════════════

set -euo pipefail

# ── Список всех доступных вариантов ─────────────────────────
# Чтобы добавить новый: добавь ID в массив + секцию в get_variant()

VARIANT_IDS=(
  "cloud_storage"
  "media_library"
  "backup_center"
  "corporate_portal"
  "personal_vault"
  "team_workspace"
  "secure_archive"
  "file_sharing"
  "nas_interface"
  "dev_repository"
  "photo_gallery"
  "document_hub"
  "data_room"
  "sync_service"
  "asset_manager"
)

# ── Выбор случайного варианта ────────────────────────────────
random_variant() {
  local count=${#VARIANT_IDS[@]}
  local idx
  idx=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ' | awk -v n="$count" '{print $1 % n}')
  echo "${VARIANT_IDS[$idx]}"
}

# ── Описание варианта ────────────────────────────────────────
# Устанавливает переменные с префиксом V_:
#   V_ICON         — иконка сайта (emoji)
#   V_TITLE_EN     — заголовок (EN)
#   V_TITLE_RU     — заголовок (RU)
#   V_TAGLINE_EN   — подзаголовок (EN)
#   V_TAGLINE_RU   — подзаголовок (RU)
#   V_NAV_EN       — элементы навигации через | (EN)
#   V_NAV_RU       — элементы навигации через | (RU)
#   V_LAYOUT       — класс CSS-раскладки: grid | list | dashboard | gallery
#   V_CONTENT_TYPE — тип основного контента: files | media | stats | mixed
#   V_COLOR_THEME  — подсказка для генератора цветов: auto | dark | light | blue | warm

get_variant() {
  local id="${1:-cloud_storage}"

  case "$id" in

  cloud_storage)
    V_ICON="☁️"
    V_TITLE_EN="Cloud Storage"
    V_TITLE_RU="Облачное хранилище"
    V_TAGLINE_EN="Your files, anywhere"
    V_TAGLINE_RU="Ваши файлы — везде"
    V_NAV_EN="Home|Files|Shared|Recent|Settings"
    V_NAV_RU="Главная|Файлы|Общие|Недавние|Настройки"
    V_LAYOUT="grid"
    V_CONTENT_TYPE="files"
    V_COLOR_THEME="blue"
    ;;

  media_library)
    V_ICON="🎬"
    V_TITLE_EN="Media Library"
    V_TITLE_RU="Медиатека"
    V_TAGLINE_EN="All your media in one place"
    V_TAGLINE_RU="Все медиафайлы в одном месте"
    V_NAV_EN="Home|Videos|Photos|Music|Albums"
    V_NAV_RU="Главная|Видео|Фото|Музыка|Альбомы"
    V_LAYOUT="gallery"
    V_CONTENT_TYPE="media"
    V_COLOR_THEME="dark"
    ;;

  backup_center)
    V_ICON="💾"
    V_TITLE_EN="Backup Center"
    V_TITLE_RU="Центр резервного копирования"
    V_TAGLINE_EN="Your data, always safe"
    V_TAGLINE_RU="Ваши данные всегда в безопасности"
    V_NAV_EN="Dashboard|Backups|Schedule|Reports|Settings"
    V_NAV_RU="Панель|Бэкапы|Расписание|Отчёты|Настройки"
    V_LAYOUT="dashboard"
    V_CONTENT_TYPE="stats"
    V_COLOR_THEME="corporate"
    ;;

  corporate_portal)
    V_ICON="🏢"
    V_TITLE_EN="Corporate Portal"
    V_TITLE_RU="Корпоративный портал"
    V_TAGLINE_EN="Enterprise file management"
    V_TAGLINE_RU="Корпоративное управление файлами"
    V_NAV_EN="Home|Documents|Projects|Users|Reports"
    V_NAV_RU="Главная|Документы|Проекты|Пользователи|Отчёты"
    V_LAYOUT="list"
    V_CONTENT_TYPE="files"
    V_COLOR_THEME="corporate"
    ;;

  personal_vault)
    V_ICON="🔐"
    V_TITLE_EN="Personal Vault"
    V_TITLE_RU="Личное хранилище"
    V_TAGLINE_EN="Private and secure"
    V_TAGLINE_RU="Приватно и безопасно"
    V_NAV_EN="My Files|Photos|Documents|Private|Trash"
    V_NAV_RU="Мои файлы|Фото|Документы|Приватное|Корзина"
    V_LAYOUT="grid"
    V_CONTENT_TYPE="files"
    V_COLOR_THEME="auto"
    ;;

  team_workspace)
    V_ICON="👥"
    V_TITLE_EN="Team Workspace"
    V_TITLE_RU="Командное пространство"
    V_TAGLINE_EN="Collaborate and share"
    V_TAGLINE_RU="Совместная работа и обмен"
    V_NAV_EN="Home|Projects|Shared|Members|Activity"
    V_NAV_RU="Главная|Проекты|Общее|Участники|Активность"
    V_LAYOUT="dashboard"
    V_CONTENT_TYPE="mixed"
    V_COLOR_THEME="auto"
    ;;

  secure_archive)
    V_ICON="🗄️"
    V_TITLE_EN="Secure Archive"
    V_TITLE_RU="Защищённый архив"
    V_TAGLINE_EN="Long-term storage you can trust"
    V_TAGLINE_RU="Надёжное долгосрочное хранение"
    V_NAV_EN="Archive|Search|Tags|Access Log|Settings"
    V_NAV_RU="Архив|Поиск|Теги|Журнал|Настройки"
    V_LAYOUT="list"
    V_CONTENT_TYPE="files"
    V_COLOR_THEME="dark"
    ;;

  file_sharing)
    V_ICON="🔗"
    V_TITLE_EN="File Sharing"
    V_TITLE_RU="Файлообменник"
    V_TAGLINE_EN="Share files instantly"
    V_TAGLINE_RU="Делитесь файлами мгновенно"
    V_NAV_EN="Upload|My Links|Received|Stats|Settings"
    V_NAV_RU="Загрузить|Мои ссылки|Полученное|Статистика|Настройки"
    V_LAYOUT="grid"
    V_CONTENT_TYPE="files"
    V_COLOR_THEME="warm"
    ;;

  nas_interface)
    V_ICON="🖥️"
    V_TITLE_EN="Network Storage"
    V_TITLE_RU="Сетевое хранилище"
    V_TAGLINE_EN="Access your NAS from anywhere"
    V_TAGLINE_RU="Доступ к NAS из любой точки"
    V_NAV_EN="Browser|Uploads|Users|Services|System"
    V_NAV_RU="Проводник|Загрузки|Пользователи|Сервисы|Система"
    V_LAYOUT="dashboard"
    V_CONTENT_TYPE="stats"
    V_COLOR_THEME="corporate"
    ;;

  dev_repository)
    V_ICON="📦"
    V_TITLE_EN="Repository"
    V_TITLE_RU="Репозиторий"
    V_TAGLINE_EN="Artifact and package storage"
    V_TAGLINE_RU="Хранилище артефактов и пакетов"
    V_NAV_EN="Packages|Artifacts|Access|Teams|Settings"
    V_NAV_RU="Пакеты|Артефакты|Доступ|Команды|Настройки"
    V_LAYOUT="list"
    V_CONTENT_TYPE="files"
    V_COLOR_THEME="dark"
    ;;

  photo_gallery)
    V_ICON="🖼️"
    V_TITLE_EN="Photo Gallery"
    V_TITLE_RU="Фотогалерея"
    V_TAGLINE_EN="Beautiful photos, organized"
    V_TAGLINE_RU="Красивые фото в порядке"
    V_NAV_EN="Gallery|Albums|Faces|Map|Settings"
    V_NAV_RU="Галерея|Альбомы|Лица|Карта|Настройки"
    V_LAYOUT="gallery"
    V_CONTENT_TYPE="media"
    V_COLOR_THEME="light"
    ;;

  document_hub)
    V_ICON="📄"
    V_TITLE_EN="Document Hub"
    V_TITLE_RU="Документооборот"
    V_TAGLINE_EN="Manage your documents"
    V_TAGLINE_RU="Управляйте вашими документами"
    V_NAV_EN="All Docs|Drafts|Approved|Archive|Templates"
    V_NAV_RU="Все документы|Черновики|Утверждённые|Архив|Шаблоны"
    V_LAYOUT="list"
    V_CONTENT_TYPE="files"
    V_COLOR_THEME="corporate"
    ;;

  data_room)
    V_ICON="🏛️"
    V_TITLE_EN="Data Room"
    V_TITLE_RU="Комната данных"
    V_TAGLINE_EN="Secure due diligence portal"
    V_TAGLINE_RU="Защищённый портал для проверки"
    V_NAV_EN="Overview|Documents|Activity|Users|Watermark"
    V_NAV_RU="Обзор|Документы|Активность|Пользователи|Защита"
    V_LAYOUT="dashboard"
    V_CONTENT_TYPE="mixed"
    V_COLOR_THEME="corporate"
    ;;

  sync_service)
    V_ICON="🔄"
    V_TITLE_EN="Sync Service"
    V_TITLE_RU="Сервис синхронизации"
    V_TAGLINE_EN="Keep everything in sync"
    V_TAGLINE_RU="Всё всегда синхронизировано"
    V_NAV_EN="Status|Devices|Files|History|Settings"
    V_NAV_RU="Статус|Устройства|Файлы|История|Настройки"
    V_LAYOUT="dashboard"
    V_CONTENT_TYPE="stats"
    V_COLOR_THEME="blue"
    ;;

  asset_manager)
    V_ICON="🎨"
    V_TITLE_EN="Asset Manager"
    V_TITLE_RU="Менеджер активов"
    V_TAGLINE_EN="Your digital assets, organized"
    V_TAGLINE_RU="Цифровые активы под контролем"
    V_NAV_EN="Assets|Collections|Tags|Shared|Analytics"
    V_NAV_RU="Активы|Коллекции|Теги|Общие|Аналитика"
    V_LAYOUT="gallery"
    V_CONTENT_TYPE="media"
    V_COLOR_THEME="warm"
    ;;

  *)
    # Fallback — cloud_storage
    get_variant "cloud_storage"
    return
    ;;
  esac
}

# ── Генерация HTML для навигации ────────────────────────────
# Принимает строку "Item1|Item2|Item3" и active_index (0-based)
# Возвращает HTML <a> теги

build_nav_html() {
  local nav_str="$1"
  local active_idx="${2:-0}"

  local html=""
  local idx=0
  IFS='|' read -ra items <<<"$nav_str"
  for item in "${items[@]}"; do
    if [[ $idx -eq $active_idx ]]; then
      html+="<a href=\"#\" class=\"nav-link active\">${item}</a>"
    else
      html+="<a href=\"#\" class=\"nav-link\">${item}</a>"
    fi
    ((idx++))
  done
  echo "$html"
}

# ── Генерация блока фич для главной страницы ─────────────────
# Зависит от content_type варианта

build_features_html() {
  local content_type="$1"
  local lang="${2:-en}"

  case "$content_type" in
  files)
    if [[ "$lang" == "ru" ]]; then
      echo '<div class="feature"><span class="feature-icon">📁</span><h3>Файловый менеджер</h3><p>Интуитивный интерфейс для работы с файлами</p></div>
<div class="feature"><span class="feature-icon">🔒</span><h3>Шифрование</h3><p>AES-256 для всех файлов в хранилище</p></div>
<div class="feature"><span class="feature-icon">⚡</span><h3>Быстрый доступ</h3><p>Доступ к файлам из любой точки мира</p></div>'
    else
      echo '<div class="feature"><span class="feature-icon">📁</span><h3>File Manager</h3><p>Intuitive interface for managing your files</p></div>
<div class="feature"><span class="feature-icon">🔒</span><h3>Encryption</h3><p>AES-256 encryption for all stored files</p></div>
<div class="feature"><span class="feature-icon">⚡</span><h3>Fast Access</h3><p>Access your files from anywhere in the world</p></div>'
    fi
    ;;
  media)
    if [[ "$lang" == "ru" ]]; then
      echo '<div class="feature"><span class="feature-icon">🎬</span><h3>Видео потоком</h3><p>Стриминг без скачивания</p></div>
<div class="feature"><span class="feature-icon">🖼️</span><h3>Авто-альбомы</h3><p>Умная организация по дате и месту</p></div>
<div class="feature"><span class="feature-icon">📱</span><h3>Мобильное приложение</h3><p>Доступ с любого устройства</p></div>'
    else
      echo '<div class="feature"><span class="feature-icon">🎬</span><h3>Video Streaming</h3><p>Stream without downloading</p></div>
<div class="feature"><span class="feature-icon">🖼️</span><h3>Auto Albums</h3><p>Smart organization by date and location</p></div>
<div class="feature"><span class="feature-icon">📱</span><h3>Mobile App</h3><p>Access from any device</p></div>'
    fi
    ;;
  stats | dashboard)
    if [[ "$lang" == "ru" ]]; then
      echo '<div class="feature"><span class="feature-icon">📊</span><h3>Аналитика</h3><p>Подробные отчёты и статистика</p></div>
<div class="feature"><span class="feature-icon">🔔</span><h3>Уведомления</h3><p>Алерты при важных событиях</p></div>
<div class="feature"><span class="feature-icon">🔧</span><h3>Автоматизация</h3><p>Расписания и автоматические задачи</p></div>'
    else
      echo '<div class="feature"><span class="feature-icon">📊</span><h3>Analytics</h3><p>Detailed reports and statistics</p></div>
<div class="feature"><span class="feature-icon">🔔</span><h3>Notifications</h3><p>Alerts for important events</p></div>
<div class="feature"><span class="feature-icon">🔧</span><h3>Automation</h3><p>Schedules and automated tasks</p></div>'
    fi
    ;;
  *)
    build_features_html "files" "$lang"
    ;;
  esac
}

# Если вызван напрямую — вывести список вариантов
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-list}" in
  list)
    echo "Available variants:"
    for id in "${VARIANT_IDS[@]}"; do
      get_variant "$id"
      echo "  ${id}: ${V_ICON} ${V_TITLE_EN} [layout:${V_LAYOUT}]"
    done
    ;;
  get)
    get_variant "${2:-cloud_storage}"
    echo "ID:           $2"
    echo "Icon:         $V_ICON"
    echo "Title EN:     $V_TITLE_EN"
    echo "Title RU:     $V_TITLE_RU"
    echo "Layout:       $V_LAYOUT"
    echo "Content type: $V_CONTENT_TYPE"
    echo "Color theme:  $V_COLOR_THEME"
    ;;
  random)
    random_variant
    ;;
  *)
    echo "Usage: $0 [list|get <id>|random]"
    ;;
  esac
fi
