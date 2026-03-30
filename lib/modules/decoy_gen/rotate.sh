#!/usr/bin/env bash
#
# rotate.sh - Смена активного сайта-прикрытия
# Позволяет переключаться между сгенерированными сайтами
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
SITES_DIR="$ROOT_DIR/sites"
ACTIVE_FILE="$ROOT_DIR/.active_site"
WEBROOT_DIR="$ROOT_DIR/webroot"

# Логирование
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Показ справки
show_help() {
    cat <<EOF
CubiVeil Site Rotator

Usage: $(basename "$0") [COMMAND] [OPTIONS]

Commands:
  list              List all available sites
  activate <name>   Activate a specific site
  current           Show currently active site
  random            Activate a random site
  status            Show rotation status

Options:
  --help, -h        Show this help

Examples:
  $(basename "$0") list                    # List all sites
  $(basename "$0") activate mysite         # Activate 'mysite'
  $(basename "$0") random                  # Activate random site
  $(basename "$0") current                 # Show current site

EOF
}

# Инициализация директорий
init_dirs() {
    mkdir -p "$SITES_DIR"
}

# Получить список сайтов
list_sites() {
    if [[ ! -d "$SITES_DIR" ]] || [[ -z "$(ls -A "$SITES_DIR" 2>/dev/null)" ]]; then
        echo "No sites found. Generate a site first with: bash generate.sh"
        return 1
    fi

    echo "Available sites:"
    echo ""

    local current=""
    if [[ -f "$ACTIVE_FILE" ]]; then
        current=$(cat "$ACTIVE_FILE")
    fi

    for site_dir in "$SITES_DIR"/*/; do
        if [[ -d "$site_dir" ]]; then
            local site_name
            site_name=$(basename "$site_dir")
            local marker=""
            if [[ "$site_name" == "$current" ]]; then
                marker=" [ACTIVE]"
            fi

            # Try to get site info
            local template=""
            local generated=""
            if [[ -f "$site_dir/.generation_meta.json" ]]; then
                template=$(jq -r '.template // "unknown"' "$site_dir/.generation_meta.json" 2>/dev/null || echo "unknown")
                generated=$(jq -r '.generated_at // "unknown"' "$site_dir/.generation_meta.json" 2>/dev/null || echo "unknown")
            fi

            echo "  📁 $site_name$marker"
            if [[ -n "$template" ]]; then
                echo "     Template: $template"
                echo "     Generated: $generated"
            fi
            echo ""
        fi
    done
}

# Получить текущий активный сайт
get_current() {
    if [[ -f "$ACTIVE_FILE" ]]; then
        cat "$ACTIVE_FILE"
    else
        echo "No active site"
    fi
}

# Активировать сайт
activate_site() {
    local site_name="$1"

    if [[ ! -d "$SITES_DIR/$site_name" ]]; then
        echo "Error: Site '$site_name' not found"
        echo "Use '$(basename "$0") list' to see available sites"
        return 1
    fi

    # Копируем сайт в webroot
    log "Activating site: $site_name"
    rm -rf "$WEBROOT_DIR"/*
    cp -r "$SITES_DIR/$site_name"/* "$WEBROOT_DIR"/

    # Сохраняем активный сайт
    echo "$site_name" > "$ACTIVE_FILE"

    log "Site '$site_name' is now active"

    # Показываем информацию
    if [[ -f "$SITES_DIR/$site_name/.generation_meta.json" ]]; then
        echo ""
        echo "Site Info:"
        jq '.' "$SITES_DIR/$site_name/.generation_meta.json" 2>/dev/null || true
    fi
}

# Активировать случайный сайт
activate_random() {
    local sites=()

    for site_dir in "$SITES_DIR"/*/; do
        if [[ -d "$site_dir" ]]; then
            sites+=("$(basename "$site_dir")")
        fi
    done

    if [[ ${#sites[@]} -eq 0 ]]; then
        echo "No sites found. Generate a site first with: bash generate.sh"
        return 1
    fi

    local idx
    idx=$(od -An -tu4 -N4 /dev/urandom | tr -d ' ' | awk -v len="${#sites[@]}" '{print int($1 % len)}')
    local random_site="${sites[$idx]}"

    activate_site "$random_site"
}

# Показать статус
show_status() {
    echo "CubiVeil Rotation Status"
    echo "========================"
    echo ""

    local current
    current=$(get_current)
    echo "Active Site: $current"
    echo ""

    if [[ -d "$SITES_DIR" ]]; then
        local count
        count=$(find "$SITES_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l)
        echo "Total Sites: $count"
    else
        echo "Total Sites: 0"
    fi

    echo ""
    echo "Webroot: $WEBROOT_DIR"
    echo "Sites Directory: $SITES_DIR"
}

# Основная функция
main() {
    init_dirs

    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi

    local command="$1"
    shift

    case "$command" in
        list)
            list_sites
            ;;
        activate)
            if [[ $# -lt 1 ]]; then
                echo "Error: Site name required"
                echo "Usage: $(basename "$0") activate <site-name>"
                exit 1
            fi
            activate_site "$1"
            ;;
        current)
            get_current
            ;;
        random)
            activate_random
            ;;
        status)
            show_status
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            echo "Use '$(basename "$0") --help' for usage information"
            exit 1
            ;;
    esac
}

main "$@"
