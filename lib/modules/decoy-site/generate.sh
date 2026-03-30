#!/usr/bin/env bash
#
# generate.sh - Главный скрипт генерации сайтов-прикрытий CubiVeil
# Генерирует статические сайты, имитирующие реальные файловые хранилища
#

set -euo pipefail

# Определение путей
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
GENERATORS_DIR="$ROOT_DIR/generators"
TEMPLATES_DIR="$ROOT_DIR/templates"
LOGS_DIR="$ROOT_DIR/logs"
WEBROOT_DIR="$ROOT_DIR/webroot"

# Файлы логов
LOG_FILE="$LOGS_DIR/generate.log"
mkdir -p "$LOGS_DIR"

# Логирование
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    if [[ "$level" == "ERROR" ]]; then
        echo "[$level] $message" >&2
    fi
}

log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() { log "DEBUG" "$@"; }

# Обработка ошибок
error_exit() {
    log_error "$1"
    exit 1
}

# Генерация уникального seed
generate_seed() {
    local seed_parts=()

    # /dev/urandom
    if [[ -r /dev/urandom ]]; then
        seed_parts+=("$(od -An -tu4 -N8 /dev/urandom | tr -d ' ')")
    fi

    # hostname
    if command -v hostname &>/dev/null; then
        seed_parts+=("$(hostname 2>/dev/null || echo 'unknown')")
    fi

    # MAC адрес (если доступен)
    local mac=""
    if command -v ipconfig &>/dev/null; then
        # Windows
        mac=$(ipconfig /all 2>/dev/null | grep -i "physical address" | head -1 | awk '{print $NF}' | tr -d ':' || echo "")
    elif command -v ifconfig &>/dev/null; then
        # Linux/Mac
        mac=$(ifconfig 2>/dev/null | grep -i "ether" | head -1 | awk '{print $2}' | tr -d ':' || echo "")
    fi
    if [[ -n "$mac" ]]; then
        seed_parts+=("$mac")
    fi

    # Timestamp
    seed_parts+=("$(date +%s%N)")

    # Случайное число
    seed_parts+=("$(od -An -tu4 -N4 /dev/urandom | tr -d ' ')")

    # Хешируем всё вместе
    local combined
    combined=$(IFS='|'; echo "${seed_parts[*]}")
    echo -n "$combined" | md5sum | cut -c1-32
}

# Парсинг аргументов командной строки
parse_args() {
    TEMPLATE="auto"
    LANG="ru"
    COLOR_THEME="auto"
    BASE_HUE=""
    SEED=""
    USERS_COUNT=""
    FILES_COUNT=""
    STORAGE_SIZE=""
    OUTPUT_DIR=""
    OUTPUT_DIR_SET=0
    CONFIG_FILE="$ROOT_DIR/config.json"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --template|-t)
                TEMPLATE="$2"
                shift 2
                ;;
            --lang|-l)
                LANG="$2"
                shift 2
                ;;
            --theme)
                COLOR_THEME="$2"
                shift 2
                ;;
            --hue)
                BASE_HUE="$2"
                shift 2
                ;;
            --seed|-s)
                SEED="$2"
                shift 2
                ;;
            --users|-u)
                USERS_COUNT="$2"
                shift 2
                ;;
            --files|-f)
                FILES_COUNT="$2"
                shift 2
                ;;
            --storage)
                STORAGE_SIZE="$2"
                shift 2
                ;;
            --output|-o)
                OUTPUT_DIR="$2"
                OUTPUT_DIR_SET=1
                shift 2
                ;;
            --config|-c)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done

    # Загрузка из config.json если файл существует и параметры не переопределены
    if [[ -f "$CONFIG_FILE" ]]; then
        load_config
    fi
}

# Загрузка конфигурации из JSON
load_config() {
    if ! command -v jq &>/dev/null; then
        log_info "jq not found, skipping config file"
        return
    fi

    local config_template config_lang config_theme config_hue config_seed
    local config_users config_files config_storage config_output

    config_template=$(jq -r '.template // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    config_lang=$(jq -r '.lang // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    config_theme=$(jq -r '.color_theme // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    config_hue=$(jq -r '.base_hue // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    config_seed=$(jq -r '.seed // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    config_users=$(jq -r '.users_count // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    config_files=$(jq -r '.files_count // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    config_storage=$(jq -r '.storage_size // empty' "$CONFIG_FILE" 2>/dev/null || echo "")
    config_output=$(jq -r '.output_dir // empty' "$CONFIG_FILE" 2>/dev/null || echo "")

    # Применяем из конфига только если не задано в CLI
    [[ "$TEMPLATE" == "auto" && -n "$config_template" ]] && TEMPLATE="$config_template"
    [[ "$LANG" == "ru" && -n "$config_lang" ]] && LANG="$config_lang"
    [[ "$COLOR_THEME" == "auto" && -n "$config_theme" ]] && COLOR_THEME="$config_theme"
    [[ -z "$BASE_HUE" && -n "$config_hue" && "$config_hue" != "null" ]] && BASE_HUE="$config_hue"
    [[ -z "$SEED" && -n "$config_seed" && "$config_seed" != "null" ]] && SEED="$config_seed"
    [[ -z "$USERS_COUNT" && -n "$config_users" && "$config_users" != "null" ]] && USERS_COUNT="$config_users"
    [[ -z "$FILES_COUNT" && -n "$config_files" && "$config_files" != "null" ]] && FILES_COUNT="$config_files"
    [[ -z "$STORAGE_SIZE" && -n "$config_storage" && "$config_storage" != "null" ]] && STORAGE_SIZE="$config_storage"
    [[ "$OUTPUT_DIR_SET" -eq 0 && -n "$config_output" ]] && OUTPUT_DIR="$config_output"

    # По умолчанию используем WEBROOT_DIR
    if [[ -z "$OUTPUT_DIR" ]]; then
        OUTPUT_DIR="$WEBROOT_DIR"
    fi
}

# Показ справки
show_help() {
    cat <<EOF
CubiVeil Decoy Site Generator

Usage: $(basename "$0") [OPTIONS]

Options:
  --template, -t <name>   Template to use (or 'auto' for random)
                          Available: single_page, minimal, corporate, personal,
                          multi_page, cloud_service, media_library, backup_center,
                          dashboard, admin_panel, secure_vault, team_workspace
  --lang, -l <lang>       Language (ru or en, default: ru)
  --theme <name>          Color theme (or 'auto' for random)
                          Available: ocean, forest, sunset, corporate, dark,
                          light, purple, warm
  --hue <0-360>           Base hue for color generation
  --seed, -s <seed>       Seed for reproducible generation
  --users, -u <count>     Number of users
  --files, -f <count>     Number of files
  --storage <bytes>       Total storage size in bytes
  --output, -o <dir>      Output directory (default: ./webroot)
  --config, -c <file>     Config file (default: ./config.json)
  --help, -h              Show this help

Examples:
  $(basename "$0")                           # Generate with defaults
  $(basename "$0") --template cloud_service  # Use specific template
  $(basename "$0") --lang en --theme ocean   # English with ocean theme
  $(basename "$0") --seed myseed123          # Reproducible generation

EOF
}

# Выбор случайного шаблона
select_template() {
    if [[ "$TEMPLATE" != "auto" ]]; then
        if [[ ! -d "$TEMPLATES_DIR/$TEMPLATE" ]]; then
            error_exit "Template '$TEMPLATE' not found"
        fi
        echo "$TEMPLATE"
        return
    fi

    # Случайный выбор из доступных
    local templates=()
    for dir in "$TEMPLATES_DIR"/*/; do
        templates+=("$(basename "$dir")")
    done

    local idx
    idx=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ' | awk -v len="${#templates[@]}" '{print int($1 % len)}')
    echo "${templates[$idx]}"
}

# Копирование шаблона в output
copy_template() {
    local template_name="$1"
    local output_dir="$2"

    log_info "Copying template '$template_name' to '$output_dir'"

    # Создаём и очищаем output
    mkdir -p "$output_dir"
    rm -rf "$output_dir"/*

    # Копируем файлы шаблона
    cp -r "$TEMPLATES_DIR/$template_name"/* "$output_dir/"
}

# Замена переменных в файлах
replace_variables() {
    local output_dir="$1"
    local site_name="$2"
    local colors_json="$3"
    local stats_json="$4"
    local content_json="$5"
    local lang="$6"

    log_info "Replacing variables in templates"

    # Извлекаем цвета из JSON
    local primary secondary accent background text border
    primary=$(echo "$colors_json" | jq -r '.primary')
    secondary=$(echo "$colors_json" | jq -r '.secondary')
    accent=$(echo "$colors_json" | jq -r '.accent')
    background=$(echo "$colors_json" | jq -r '.background')
    text=$(echo "$colors_json" | jq -r '.text')
    border=$(echo "$colors_json" | jq -r '.border')

    # Извлекаем статистику
    local total_users active_users online_users
    local total_files total_folders
    local total_storage used_storage free_storage
    local daily_traffic

    total_users=$(echo "$stats_json" | jq -r '.users.total')
    active_users=$(echo "$stats_json" | jq -r '.users.active')
    online_users=$(echo "$stats_json" | jq -r '.users.online')
    total_files=$(echo "$stats_json" | jq -r '.content.total_files')
    total_folders=$(echo "$stats_json" | jq -r '.content.total_folders')
    total_storage=$(echo "$stats_json" | jq -r '.storage.total_formatted')
    used_storage=$(echo "$stats_json" | jq -r '.storage.used_formatted')
    free_storage=$(echo "$stats_json" | jq -r '.storage.free_formatted')
    daily_traffic=$(echo "$stats_json" | jq -r '.traffic.daily_formatted')

    # Извлекаем контент
    local users_json files_json folders_json
    users_json=$(echo "$content_json" | jq -c '.users')
    files_json=$(echo "$content_json" | jq -c '.files')
    folders_json=$(echo "$content_json" | jq -c '.folders')

    # Локализация
    local site_title login_title files_title stats_title users_title settings_title
    local welcome_text login_button forgot_password error_title not_found
    local storage_label users_label files_label traffic_label

    if [[ "$lang" == "ru" ]]; then
        site_title="Корпоративное хранилище"
        login_title="Вход в систему"
        files_title="Файлы"
        stats_title="Статистика"
        users_title="Пользователи"
        settings_title="Настройки"
        welcome_text="Добро пожаловать"
        login_button="Войти"
        forgot_password="Забыли пароль?"
        error_title="Ошибка"
        not_found="Страница не найдена"
        storage_label="Хранилище"
        users_label="Пользователи"
        files_label="Файлы"
        traffic_label="Трафик"
    else
        site_title="Corporate Storage"
        login_title="Login"
        files_title="Files"
        stats_title="Statistics"
        users_title="Users"
        settings_title="Settings"
        welcome_text="Welcome"
        login_button="Sign In"
        forgot_password="Forgot password?"
        error_title="Error"
        not_found="Page not found"
        storage_label="Storage"
        users_label="Users"
        files_label="Files"
        traffic_label="Traffic"
    fi

    # Получаем список HTML файлов
    local html_files
    html_files=$(find "$output_dir" -name "*.html" -type f 2>/dev/null || true)

    # Проходим по всем HTML файлам и заменяем переменные
    for file in $html_files; do
        [[ -z "$file" ]] && continue

        # Замена через sed (кроссплатформенно) - каждая команда в подшелле
        (sed -i.bak "s/{{SITE_NAME}}/$site_name/g" "$file" 2>/dev/null || sed -i "" "s/{{SITE_NAME}}/$site_name/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{SITE_TITLE}}/$site_title/g" "$file" 2>/dev/null || sed -i "" "s/{{SITE_TITLE}}/$site_title/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{LOGIN_TITLE}}/$login_title/g" "$file" 2>/dev/null || sed -i "" "s/{{LOGIN_TITLE}}/$login_title/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{FILES_TITLE}}/$files_title/g" "$file" 2>/dev/null || sed -i "" "s/{{FILES_TITLE}}/$files_title/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{STATS_TITLE}}/$stats_title/g" "$file" 2>/dev/null || sed -i "" "s/{{STATS_TITLE}}/$stats_title/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{USERS_TITLE}}/$users_title/g" "$file" 2>/dev/null || sed -i "" "s/{{USERS_TITLE}}/$users_title/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{SETTINGS_TITLE}}/$settings_title/g" "$file" 2>/dev/null || sed -i "" "s/{{SETTINGS_TITLE}}/$settings_title/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{WELCOME_TEXT}}/$welcome_text/g" "$file" 2>/dev/null || sed -i "" "s/{{WELCOME_TEXT}}/$welcome_text/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{LOGIN_BUTTON}}/$login_button/g" "$file" 2>/dev/null || sed -i "" "s/{{LOGIN_BUTTON}}/$login_button/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{FORGOT_PASSWORD}}/$forgot_password/g" "$file" 2>/dev/null || sed -i "" "s/{{FORGOT_PASSWORD}}/$forgot_password/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{ERROR_TITLE}}/$error_title/g" "$file" 2>/dev/null || sed -i "" "s/{{ERROR_TITLE}}/$error_title/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{NOT_FOUND}}/$not_found/g" "$file" 2>/dev/null || sed -i "" "s/{{NOT_FOUND}}/$not_found/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{STORAGE_LABEL}}/$storage_label/g" "$file" 2>/dev/null || sed -i "" "s/{{STORAGE_LABEL}}/$storage_label/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{USERS_LABEL}}/$users_label/g" "$file" 2>/dev/null || sed -i "" "s/{{USERS_LABEL}}/$users_label/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{FILES_LABEL}}/$files_label/g" "$file" 2>/dev/null || sed -i "" "s/{{FILES_LABEL}}/$files_label/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{TRAFFIC_LABEL}}/$traffic_label/g" "$file" 2>/dev/null || sed -i "" "s/{{TRAFFIC_LABEL}}/$traffic_label/g" "$file" 2>/dev/null || true)

        # Числовые значения
        (sed -i.bak "s/{{TOTAL_USERS}}/$total_users/g" "$file" 2>/dev/null || sed -i "" "s/{{TOTAL_USERS}}/$total_users/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{ACTIVE_USERS}}/$active_users/g" "$file" 2>/dev/null || sed -i "" "s/{{ACTIVE_USERS}}/$active_users/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{ONLINE_USERS}}/$online_users/g" "$file" 2>/dev/null || sed -i "" "s/{{ONLINE_USERS}}/$online_users/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{TOTAL_FILES}}/$total_files/g" "$file" 2>/dev/null || sed -i "" "s/{{TOTAL_FILES}}/$total_files/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{TOTAL_FOLDERS}}/$total_folders/g" "$file" 2>/dev/null || sed -i "" "s/{{TOTAL_FOLDERS}}/$total_folders/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{TOTAL_STORAGE}}/$total_storage/g" "$file" 2>/dev/null || sed -i "" "s/{{TOTAL_STORAGE}}/$total_storage/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{USED_STORAGE}}/$used_storage/g" "$file" 2>/dev/null || sed -i "" "s/{{USED_STORAGE}}/$used_storage/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{FREE_STORAGE}}/$free_storage/g" "$file" 2>/dev/null || sed -i "" "s/{{FREE_STORAGE}}/$free_storage/g" "$file" 2>/dev/null || true)
        (sed -i.bak "s/{{DAILY_TRAFFIC}}/$daily_traffic/g" "$file" 2>/dev/null || sed -i "" "s/{{DAILY_TRAFFIC}}/$daily_traffic/g" "$file" 2>/dev/null || true)

        # Удаляем backup файлы
        rm -f "${file}.bak" 2>/dev/null || true
    done

    # Обновляем CSS переменные
    if [[ -f "$output_dir/style.css" ]]; then
        # Создаём временный файл с новыми переменными
        local temp_css
        temp_css=$(mktemp)

        # Добавляем CSS переменные в начало файла
        cat > "$temp_css" <<EOF
:root {
    --color-primary: $primary;
    --color-secondary: $secondary;
    --color-accent: $accent;
    --color-background: $background;
    --color-text: $text;
    --color-border: $border;
}

EOF

        # Добавляем оригинальный CSS
        cat "$output_dir/style.css" >> "$temp_css"
        mv "$temp_css" "$output_dir/style.css"
    fi

    # Создаём data.json для JavaScript
    cat > "$output_dir/data.json" <<EOF
{
    "siteName": "$site_name",
    "language": "$lang",
    "stats": $stats_json,
    "content": {
        "users": $users_json,
        "files": $files_json,
        "folders": $folders_json
    },
    "colors": $colors_json
}
EOF

    # Создаём config.js для удобного доступа из JS
    cat > "$output_dir/config.js" <<EOF
window.SITE_CONFIG = {
    siteName: "$site_name",
    language: "$lang",
    stats: $stats_json,
    users: $users_json,
    files: $files_json,
    folders: $folders_json,
    colors: $colors_json
};
EOF
}

# Генерация nginx.conf
generate_nginx_config() {
    local output_dir="$1"
    local site_name="$2"

    log_info "Generating nginx.conf"

    cat > "$output_dir/nginx.conf" <<EOF
server {
    listen 80;
    server_name localhost;

    root $output_dir;
    index index.html;

    # Site: $site_name

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Handle SPA routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
}
EOF
}

# Основная функция генерации
generate() {
    local start_time
    start_time=$(date +%s)

    log_info "=== Starting generation ==="

    # 1. Генерация seed
    if [[ -z "$SEED" ]]; then
        SEED=$(generate_seed)
    fi
    log_info "Using seed: $SEED"

    # 2. Выбор шаблона
    local selected_template
    selected_template=$(select_template)
    log_info "Selected template: $selected_template"

    # 3. Генерация названия сайта
    log_info "Generating site name"
    local site_name_json
    site_name_json=$(bash "$GENERATORS_DIR/names.sh" --lang "$LANG" --json)
    local site_name
    site_name=$(echo "$site_name_json" | jq -r '.full_name')
    log_info "Site name: $site_name"

    # 4. Генерация цветовой схемы
    log_info "Generating color scheme"
    local colors_json
    if [[ -n "$BASE_HUE" ]]; then
        colors_json=$(bash "$GENERATORS_DIR/colors.sh" --hue "$BASE_HUE" --theme "$COLOR_THEME")
    else
        colors_json=$(bash "$GENERATORS_DIR/colors.sh" --theme "$COLOR_THEME")
    fi

    # 5. Генерация статистики
    log_info "Generating statistics"
    local stats_json
    stats_json=$(bash "$GENERATORS_DIR/stats.sh" --seed "$SEED" \
        ${USERS_COUNT:+--users "$USERS_COUNT"} \
        ${FILES_COUNT:+--files "$FILES_COUNT"} \
        ${STORAGE_SIZE:+--storage "$STORAGE_SIZE"})

    # 6. Генерация контента
    log_info "Generating content"
    local content_json
    content_json=$(bash "$GENERATORS_DIR/content.sh" --lang "$LANG" \
        ${USERS_COUNT:+--users "$USERS_COUNT"} \
        ${FILES_COUNT:+--files "$FILES_COUNT"})

    # 7. Копирование шаблона
    mkdir -p "$OUTPUT_DIR"
    copy_template "$selected_template" "$OUTPUT_DIR"

    # 8. Замена переменных
    replace_variables "$OUTPUT_DIR" "$site_name" "$colors_json" "$stats_json" "$content_json" "$LANG"

    # 9. Генерация nginx.conf
    generate_nginx_config "$OUTPUT_DIR" "$site_name"

    # 10. Сохранение metadata
    cat > "$OUTPUT_DIR/.generation_meta.json" <<EOF
{
    "seed": "$SEED",
    "template": "$selected_template",
    "language": "$LANG",
    "color_theme": "$COLOR_THEME",
    "site_name": "$site_name",
    "generated_at": "$(date -Iseconds)",
    "version": "1.0.0"
}
EOF

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_info "=== Generation completed in ${duration}s ==="
    log_info "Output: $OUTPUT_DIR"
    log_info "Site hash: $(find "$OUTPUT_DIR" -type f -exec md5sum {} \; | sort | md5sum | cut -c1-16)"

    echo "Generated site '$site_name' using template '$selected_template'"
    echo "Output: $OUTPUT_DIR"
    echo "Time: ${duration}s"
}

# ══════════════════════════════════════════════════════════════════════════════
# Обёртки для совместимости со старым интерфейсом / Compatibility Wrappers
# ══════════════════════════════════════════════════════════════════════════════

# Глобальные переменные для совместимости
DECOY_WEBROOT="${DECOY_WEBROOT:-/var/www/decoy}"
DECOY_CONFIG="${DECOY_CONFIG:-/etc/cubiveil/decoy.json}"
NGINX_CONF="${NGINX_CONF:-/etc/nginx/sites-available/cubiveil-decoy}"
DECOY_ROTATE_TIMER="${DECOY_ROTATE_TIMER:-cubiveil-decoy-rotate}"

# decoy_generate_profile - генерация профиля сайта
decoy_generate_profile() {
    local config_dir
    config_dir="$(dirname "$DECOY_CONFIG")"
    mkdir -p "$config_dir"

    # Генерируем сайт во временную директорию
    local temp_dir
    temp_dir=$(mktemp -d)

    # Запускаем генератор
    bash "$SCRIPT_DIR/generate.sh" --output "$temp_dir" "$@"

    # Копируем конфиг
    if [[ -f "$temp_dir/.generation_meta.json" ]]; then
        # Преобразуем meta.json в decoy.json формат
        cat > "$DECOY_CONFIG" <<EOF
{
    "template": "$(jq -r '.template // "minimal"' "$temp_dir/.generation_meta.json")",
    "site_name": "$(jq -r '.site_name // "Decoy Site"' "$temp_dir/.generation_meta.json")",
    "language": "$(jq -r '.language // "ru"' "$temp_dir/.generation_meta.json")",
    "rotation": {
        "enabled": true,
        "interval_hours": 3,
        "last_rotated_at": null
    },
    "types": {
        "jpg": {"enabled": true, "weight": 40},
        "pdf": {"enabled": true, "weight": 30},
        "mp4": {"enabled": true, "weight": 20},
        "mp3": {"enabled": true, "weight": 10}
    },
    "max_total_files_mb": 5000
}
EOF
        chmod 600 "$DECOY_CONFIG"
    fi

    rm -rf "$temp_dir"
}

# decoy_build_webroot - сборка webroot из шаблонов
decoy_build_webroot() {
    # Просто запускаем генератор в DECOY_WEBROOT
    bash "$SCRIPT_DIR/generate.sh" --output "$DECOY_WEBROOT" "$@"
}

# decoy_write_nginx_conf - запись конфигурации nginx
decoy_write_nginx_conf() {
    local config_dir
    config_dir="$(dirname "$NGINX_CONF")"
    mkdir -p "$config_dir"

    # Читаем шаблон и заменяем переменные
    local template_file="$SCRIPT_DIR/nginx.conf.tpl"
    if [[ -f "$template_file" ]]; then
        local site_name generated_at template_name
        site_name=$(jq -r '.site_name // "Decoy Site"' "$DECOY_CONFIG" 2>/dev/null || echo "Decoy Site")
        generated_at=$(date -Iseconds)
        template_name=$(jq -r '.template // "minimal"' "$DECOY_CONFIG" 2>/dev/null || echo "minimal")

        sed -e "s|{{DECOY_WEBROOT}}|$DECOY_WEBROOT|g" \
            -e "s|{{SITE_NAME}}|$site_name|g" \
            -e "s|{{GENERATED_AT}}|$generated_at|g" \
            -e "s|{{TEMPLATE}}|$template_name|g" \
            "$template_file" > "$NGINX_CONF"
    fi
}

# decoy_write_rotate_timer - запись таймера ротации
decoy_write_rotate_timer() {
    # Записываем systemd timer unit
    cat > "/etc/systemd/system/${DECOY_ROTATE_TIMER}.service" <<EOF
[Unit]
Description=CubiVeil Decoy Site Rotation
After=network.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_DIR/rotate.sh rotate
User=root
Group=root
EOF

    cat > "/etc/systemd/system/${DECOY_ROTATE_TIMER}.timer" <<EOF
[Unit]
Description=Run CubiVeil Decoy Site Rotation every 3 hours
Requires=${DECOY_ROTATE_TIMER}.service

[Timer]
OnBootSec=5min
OnUnitActiveSec=3h
Unit=${DECOY_ROTATE_TIMER}.service

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
}

# Точка входа
main() {
    parse_args "$@"
    generate
}

main "$@"
