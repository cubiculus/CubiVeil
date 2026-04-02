#!/usr/bin/env bash
# shellcheck disable=SC1071,SC2034
#
# generate.sh — Генератор сайтов-прикрытий CubiVeil (v2)
#
# Архитектура:
#   variants.sh  — ВСЕ типы сайтов в одном файле (добавить новый = 15 строк)
#   colors.sh    — генерация цветовой схемы
#   names.sh     — генерация названия
#   stats.sh     — генерация статистики
#   index.html.tpl — ОДИН адаптивный шаблон для всех типов
#
# Чтобы добавить новый тип сайта — только generators/variants.sh.
# Не нужно создавать новые HTML-файлы или директории.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATORS_DIR="${SCRIPT_DIR}/generators"
TEMPLATE_DIR="${SCRIPT_DIR}/template"
LOGS_DIR="${SCRIPT_DIR}/logs"

mkdir -p "$LOGS_DIR"
LOG_FILE="${LOGS_DIR}/generate.log"

log() { echo "[$(date '+%H:%M:%S')] [$1] $2" >>"$LOG_FILE"; }
log_info() { log "INFO" "$*"; }
log_success() { log "OK" "$*"; }
log_error() {
  log "ERR" "$*"
  echo "[ERR] $*" >&2
}

# Источники
source "${GENERATORS_DIR}/variants.sh"

# ── Параметры ────────────────────────────────────────────────
VARIANT="${VARIANT:-auto}"
LANG="${LANG:-ru}"
COLOR_THEME="${COLOR_THEME:-auto}"
SEED="${SEED:-}"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/webroot}"
USERS_COUNT="${USERS_COUNT:-}"
FILES_COUNT="${FILES_COUNT:-}"
STORAGE_SIZE="${STORAGE_SIZE:-}"

# Совместимость со старым интерфейсом
DECOY_WEBROOT="${DECOY_WEBROOT:-/var/www/decoy}"
DECOY_CONFIG="${DECOY_CONFIG:-/etc/cubiveil/decoy.json}"
NGINX_CONF="${NGINX_CONF:-/etc/nginx/sites-available/cubiveil-decoy}"
DECOY_ROTATE_TIMER="${DECOY_ROTATE_TIMER:-cubiveil-decoy-rotate}"

# ── Парсинг аргументов ───────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --variant | -V)
      VARIANT="$2"
      shift 2
      ;;
    --lang | -l)
      LANG="$2"
      shift 2
      ;;
    --theme)
      COLOR_THEME="$2"
      shift 2
      ;;
    --seed | -s)
      SEED="$2"
      shift 2
      ;;
    --output | -o)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --users | -u)
      USERS_COUNT="$2"
      shift 2
      ;;
    --files | -f)
      FILES_COUNT="$2"
      shift 2
      ;;
    --storage)
      STORAGE_SIZE="$2"
      shift 2
      ;;
    --list)
      list_variants
      exit 0
      ;;
    --help | -h)
      show_help
      exit 0
      ;;
    # Обратная совместимость с --template
    --template | -t)
      VARIANT="$2"
      shift 2
      ;;
    *) shift ;;
    esac
  done
}

list_variants() {
  echo ""
  echo "Available site variants (add new ones in generators/variants.sh):"
  echo ""
  for id in "${VARIANT_IDS[@]}"; do
    get_variant "$id"
    printf "  %-20s %s %s\n" "$id" "$V_ICON" "$V_TITLE_EN"
  done
  echo ""
}

show_help() {
  cat <<EOF
CubiVeil Decoy Site Generator v2

Usage: $(basename "$0") [OPTIONS]

Options:
  --variant, -V <id>   Site variant (default: random)
  --lang, -l <ru|en>   Language (default: ru)
  --theme <name>       Color theme (auto|dark|light|blue|warm|corporate|ocean|forest)
  --seed, -s <str>     Seed for reproducible generation
  --output, -o <dir>   Output directory (default: ./webroot)
  --users, -u <N>      Override users count
  --files, -f <N>      Override files count
  --storage <bytes>    Override storage size
  --list               Show all available variants
  --help, -h           Show this help

To add a new site type, edit: generators/variants.sh
EOF
}

# ── Генерация seed ───────────────────────────────────────────
_make_seed() {
  local parts=()
  [[ -r /dev/urandom ]] && parts+=("$(od -An -tu4 -N8 /dev/urandom | tr -d ' ')")
  parts+=("$(date +%s%N)" "$(hostname 2>/dev/null || echo x)")
  echo -n "${parts[*]}" | md5sum | cut -c1-32
}

# ── Генерация превью контента ────────────────────────────────
# В зависимости от типа контента рендерит разный блок
_build_content_preview() {
  local content_type="$1"
  local lang="$2"
  local files_json="$3"

  case "$content_type" in
  files | mixed)
    # Файловая сетка
    local html='<div class="file-grid" id="file-grid">'
    # Несколько статичных папок
    local folders_en=("Documents" "Projects" "Archives" "Backups" "Shared" "Personal")
    local folders_ru=("Документы" "Проекты" "Архивы" "Бэкапы" "Общие" "Личное")
    local count="${#folders_en[@]}"
    for ((i = 0; i < count; i++)); do
      local fname
      if [[ "$lang" == "ru" ]]; then
        fname="${folders_ru[$i]}"
      else
        fname="${folders_en[$i]}"
      fi
      html+="<div class=\"file-card folder\" data-type=\"folder\">
          <span class=\"file-card-icon\">📁</span>
          <span class=\"file-card-name\">${fname}</span>
        </div>"
    done
    html+='</div>
      <div class="files-footer" id="files-footer"></div>'
    echo "$html"
    ;;

  media | gallery)
    # Медиа-сетка с цветными плейсхолдерами
    local html='<div class="media-grid">'
    local icons=("🖼️" "🎬" "🎵" "🖼️" "🎬" "🖼️" "📸" "🎬" "🖼️")
    for icon in "${icons[@]}"; do
      html+="<div class=\"media-card\">
          <div class=\"media-thumb\">${icon}</div>
        </div>"
    done
    html+='</div>'
    echo "$html"
    ;;

  stats | dashboard)
    # Мини-дашборд
    local used_lbl upload_lbl download_lbl activity_lbl
    if [[ "$lang" == "ru" ]]; then
      used_lbl="Использовано"
      upload_lbl="Загружено"
      download_lbl="Скачано"
      activity_lbl="Активность"
    else
      used_lbl="Used"
      upload_lbl="Uploaded"
      download_lbl="Downloaded"
      activity_lbl="Activity"
    fi
    cat <<DASHHTML
<div class="dashboard-grid">
  <div class="dash-card">
    <div class="dash-card-label">${used_lbl}</div>
    <div class="dash-card-bar">
      <div class="dash-bar-fill" style="width:{{STORAGE_PERCENT}}%"></div>
    </div>
    <div class="dash-card-value">{{USED_STORAGE}} / {{TOTAL_STORAGE}}</div>
  </div>
  <div class="dash-card">
    <div class="dash-card-label">${upload_lbl}</div>
    <div class="dash-card-value dash-card-value--accent">↑ {{DAILY_UPLOAD}}</div>
  </div>
  <div class="dash-card">
    <div class="dash-card-label">${download_lbl}</div>
    <div class="dash-card-value dash-card-value--accent">↓ {{DAILY_DOWNLOAD}}</div>
  </div>
  <div class="dash-card dash-card--wide">
    <div class="dash-card-label">${activity_lbl}</div>
    <div class="activity-bars" id="activity-bars"></div>
  </div>
</div>
DASHHTML
    ;;
  esac
}

# ── Подстановка переменных в шаблон ─────────────────────────
# Использует sed с ограниченным набором переменных.
# Все переменные берутся из параметров функции — не из внешнего ввода.
_render_template() {
  local tpl_file="$1"
  local output_file="$2"

  # Собираем все замены в одной команде sed (быстрее, без .bak файлов)
  # Только безопасные переменные, не из пользовательского ввода
  sed \
    -e "s|{{LANG}}|${_LANG}|g" \
    -e "s|{{SITE_NAME}}|${_SITE_NAME}|g" \
    -e "s|{{SITE_TITLE}}|${_SITE_TITLE}|g" \
    -e "s|{{SITE_ICON}}|${_SITE_ICON}|g" \
    -e "s|{{SITE_TAGLINE}}|${_SITE_TAGLINE}|g" \
    -e "s|{{LAYOUT_CLASS}}|${_LAYOUT_CLASS}|g" \
    -e "s|{{LOGIN_BUTTON}}|${_LOGIN_BUTTON}|g" \
    -e "s|{{LEARN_MORE}}|${_LEARN_MORE}|g" \
    -e "s|{{STORAGE_LABEL}}|${_STORAGE_LABEL}|g" \
    -e "s|{{USERS_LABEL}}|${_USERS_LABEL}|g" \
    -e "s|{{FILES_LABEL}}|${_FILES_LABEL}|g" \
    -e "s|{{ONLINE_LABEL}}|${_ONLINE_LABEL}|g" \
    -e "s|{{TOTAL_STORAGE}}|${_TOTAL_STORAGE}|g" \
    -e "s|{{USED_STORAGE}}|${_USED_STORAGE}|g" \
    -e "s|{{TOTAL_USERS}}|${_TOTAL_USERS}|g" \
    -e "s|{{ONLINE_USERS}}|${_ONLINE_USERS}|g" \
    -e "s|{{TOTAL_FILES}}|${_TOTAL_FILES}|g" \
    -e "s|{{TOTAL_FOLDERS}}|${_TOTAL_FOLDERS}|g" \
    -e "s|{{DAILY_TRAFFIC}}|${_DAILY_TRAFFIC}|g" \
    -e "s|{{DAILY_UPLOAD}}|${_DAILY_UPLOAD}|g" \
    -e "s|{{DAILY_DOWNLOAD}}|${_DAILY_DOWNLOAD}|g" \
    -e "s|{{STORAGE_PERCENT}}|${_STORAGE_PERCENT}|g" \
    -e "s|{{YEAR}}|${_YEAR}|g" \
    -e "s|{{RIGHTS_TEXT}}|${_RIGHTS_TEXT}|g" \
    -e "s|{{PRIVACY_TEXT}}|${_PRIVACY_TEXT}|g" \
    -e "s|{{TERMS_TEXT}}|${_TERMS_TEXT}|g" \
    "$tpl_file" >"${output_file}.tmp"

  # Блоки с HTML вставляем через python3 (sed плохо справляется с многострочным HTML)
  python3 - "${output_file}.tmp" "$output_file" \
    "{{NAV_ITEMS}}" "${_NAV_ITEMS}" \
    "{{FEATURE_BLOCKS}}" "${_FEATURE_BLOCKS}" \
    "{{CONTENT_PREVIEW}}" "${_CONTENT_PREVIEW}" <<'PYEOF'
import sys, re

infile, outfile = sys.argv[1], sys.argv[2]
replacements = {}
args = sys.argv[3:]
for i in range(0, len(args), 2):
    replacements[args[i]] = args[i+1]

with open(infile, 'r') as f:
    content = f.read()

for placeholder, value in replacements.items():
    content = content.replace(placeholder, value)

with open(outfile, 'w') as f:
    f.write(content)
PYEOF

  rm -f "${output_file}.tmp"
}

# ── Генерация CSS ────────────────────────────────────────────
_generate_css() {
  local output_dir="$1"
  local colors_json="$2"
  local layout="$3"

  bash "${GENERATORS_DIR}/colors.sh" --css --output "$output_dir" "$colors_json"

  # Добавляем layout-специфичные стили к style.css
  local layout_css=""
  case "$layout" in
  gallery)
    layout_css='
.media-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(120px, 1fr)); gap: 8px; }
.media-card { aspect-ratio: 1; border-radius: 8px; background: var(--color-border); display: flex; align-items: center; justify-content: center; font-size: 2rem; cursor: pointer; transition: transform .15s; }
.media-card:hover { transform: scale(1.05); }
.media-thumb { font-size: 2.5rem; }
.file-grid { display: none; }
.dashboard-grid { display: none; }'
    ;;
  dashboard)
    layout_css='
.dashboard-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; }
.dash-card { background: white; padding: 16px; border-radius: 12px; border: 1px solid var(--color-border); }
.dash-card--wide { grid-column: 1 / -1; }
.dash-card-label { font-size: .75rem; color: var(--color-secondary); text-transform: uppercase; letter-spacing: .05em; margin-bottom: 8px; }
.dash-card-value { font-size: 1.5rem; font-weight: 700; color: var(--color-text); }
.dash-card-value--accent { color: var(--color-primary); }
.dash-bar-fill { height: 6px; background: var(--color-primary); border-radius: 3px; margin: 8px 0; }
.dash-card-bar { width: 100%; height: 6px; background: var(--color-border); border-radius: 3px; }
.activity-bars { display: flex; align-items: flex-end; gap: 4px; height: 48px; }
.file-grid { display: none; }
.media-grid { display: none; }'
    ;;
  list)
    layout_css='
.file-grid { display: flex; flex-direction: column; gap: 2px; }
.file-card { display: flex; align-items: center; gap: 12px; padding: 10px 16px; border-radius: 8px; background: white; border: 1px solid var(--color-border); cursor: pointer; transition: background .1s; }
.file-card:hover { background: rgba(0,0,0,.03); }
.file-card-icon { font-size: 1.25rem; }
.file-card-name { font-size: .875rem; }
.media-grid { display: none; }
.dashboard-grid { display: none; }'
    ;;
  grid | *)
    layout_css='
.file-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); gap: 12px; }
.file-card { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 16px 8px; border-radius: 12px; background: white; border: 1px solid var(--color-border); cursor: pointer; text-align: center; transition: box-shadow .15s, transform .15s; }
.file-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,.08); transform: translateY(-2px); }
.file-card-icon { font-size: 2rem; }
.file-card-name { font-size: .75rem; word-break: break-word; color: var(--color-text); }
.media-grid { display: none; }
.dashboard-grid { display: none; }'
    ;;
  esac

  echo "$layout_css" >>"${output_dir}/style.css"

  # Стили для страницы входа
  cat >>"${output_dir}/style.css" <<'LOGIN_CSS'
.login-page { min-height: 100vh; display: flex; align-items: center; justify-content: center; background: var(--color-bg); }
.login-container { width: 100%; max-width: 400px; padding: 20px; }
.login-box { background: white; border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,.1); overflow: hidden; }
.login-header { text-align: center; padding: 32px 32px 24px; border-bottom: 1px solid var(--color-border); }
.login-header .logo-icon { font-size: 3rem; display: block; margin-bottom: 16px; }
.login-header h1 { margin: 0 0 8px; font-size: 1.5rem; color: var(--color-text); }
.login-header p { margin: 0; color: var(--color-secondary); }
.login-form { padding: 32px; }
.form-group { margin-bottom: 20px; }
.form-group label { display: block; margin-bottom: 6px; font-size: .875rem; color: var(--color-text); }
.form-group input { width: 100%; padding: 12px 16px; border: 1px solid var(--color-border); border-radius: 8px; font-size: 1rem; }
.form-group input:focus { outline: none; border-color: var(--color-primary); box-shadow: 0 0 0 3px rgba(var(--color-primary-rgb), .1); }
.btn { display: inline-block; padding: 12px 24px; border: none; border-radius: 8px; font-size: 1rem; font-weight: 500; text-decoration: none; cursor: pointer; transition: all .15s; }
.btn-primary { background: var(--color-primary); color: white; }
.btn-primary:hover { background: var(--color-primary-dark); }
.btn-block { width: 100%; }
.error-message { margin-top: 16px; padding: 12px; background: #fee; color: #c33; border: 1px solid #fcc; border-radius: 6px; font-size: .875rem; }
LOGIN_CSS
}

# ── Локализация строк ────────────────────────────────────────
_set_locale() {
  local lang="$1"
  if [[ "$lang" == "ru" ]]; then
    _LOGIN_BUTTON="Войти"
    _LEARN_MORE="Узнать больше"
    _STORAGE_LABEL="Хранилище"
    _USERS_LABEL="Пользователей"
    _FILES_LABEL="Файлов"
    _ONLINE_LABEL="Онлайн"
    _RIGHTS_TEXT="Все права защищены."
    _PRIVACY_TEXT="Конфиденциальность"
    _TERMS_TEXT="Условия"
  else
    _LOGIN_BUTTON="Sign In"
    _LEARN_MORE="Learn More"
    _STORAGE_LABEL="Storage"
    _USERS_LABEL="Users"
    _FILES_LABEL="Files"
    _ONLINE_LABEL="Online"
    _RIGHTS_TEXT="All rights reserved."
    _PRIVACY_TEXT="Privacy"
    _TERMS_TEXT="Terms"
  fi
  _LANG="$lang"
}

# ── Главная функция генерации ────────────────────────────────
generate() {
  local start_time
  start_time=$(date +%s)
  log_info "=== Generation started ==="

  # 1. Seed
  [[ -z "$SEED" ]] && SEED=$(_make_seed)
  log_info "Seed: $SEED"

  # 2. Вариант сайта
  local variant_id
  if [[ "$VARIANT" == "auto" ]]; then
    variant_id=$(random_variant)
  else
    variant_id="$VARIANT"
  fi
  get_variant "$variant_id"
  log_info "Variant: $variant_id ($V_TITLE_EN)"

  # 3. Цветовая схема — используем подсказку варианта, если не задано явно
  local theme="${COLOR_THEME}"
  if [[ "$theme" == "auto" && "${V_COLOR_THEME}" != "auto" ]]; then
    theme="${V_COLOR_THEME}"
  fi
  local colors_json
  colors_json=$(bash "${GENERATORS_DIR}/colors.sh" --theme "$theme")

  # 4. Название сайта
  local names_json site_name
  names_json=$(bash "${GENERATORS_DIR}/names.sh" --lang "$LANG" --json)
  site_name=$(echo "$names_json" | python3 -c "import sys,json; print(json.load(sys.stdin)['full_name'])")
  log_info "Site name: $site_name"

  # 5. Статистика
  local stats_json
  stats_json=$(bash "${GENERATORS_DIR}/stats.sh" --seed "$SEED" \
    ${USERS_COUNT:+--users "$USERS_COUNT"} \
    ${FILES_COUNT:+--files "$FILES_COUNT"} \
    ${STORAGE_SIZE:+--storage "$STORAGE_SIZE"})

  # 6. Извлекаем нужные значения из статистики (один вызов python3)
  eval "$(echo "$stats_json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
s = d['storage']; u = d['users']; c = d['content']; t = d['traffic']; e = d['events']
print(f\"STAT_TOTAL_STORAGE='{s['total_formatted']}'\" )
print(f\"STAT_USED_STORAGE='{s['used_formatted']}'\"  )
print(f\"STAT_STORAGE_PCT='{s['usage_percent']}'\"    )
print(f\"STAT_TOTAL_USERS='{u['total']}'\"            )
print(f\"STAT_ONLINE_USERS='{u['online']}'\"          )
print(f\"STAT_TOTAL_FILES='{c['total_files']}'\"      )
print(f\"STAT_TOTAL_FOLDERS='{c['total_folders']}'\"  )
print(f\"STAT_DAILY_TRAFFIC='{t['daily_formatted']}'\" )
upload_mb = round(e['daily_uploads'] * 2.5, 1)
download_mb = round(e['daily_downloads'] * 4.2, 1)
print(f\"STAT_DAILY_UPLOAD='{upload_mb} MB'\"         )
print(f\"STAT_DAILY_DOWNLOAD='{download_mb} MB'\"     )
")"

  # 7. Локализация
  _set_locale "$LANG"

  # 8. Заголовок и теглайн в зависимости от языка
  if [[ "$LANG" == "ru" ]]; then
    _SITE_TITLE="${V_TITLE_RU}"
    _SITE_TAGLINE="${V_TAGLINE_RU}"
    _NAV_ITEMS=$(build_nav_html "${V_NAV_RU}" 0)
    _FEATURE_BLOCKS=$(build_features_html "${V_CONTENT_TYPE}" "ru")
  else
    _SITE_TITLE="${V_TITLE_EN}"
    _SITE_TAGLINE="${V_TAGLINE_EN}"
    _NAV_ITEMS=$(build_nav_html "${V_NAV_EN}" 0)
    _FEATURE_BLOCKS=$(build_features_html "${V_CONTENT_TYPE}" "en")
  fi

  # 9. Переменные для шаблона
  _SITE_NAME="$site_name"
  _SITE_ICON="${V_ICON}"
  _LAYOUT_CLASS="${V_LAYOUT}"
  _TOTAL_STORAGE="$STAT_TOTAL_STORAGE"
  _USED_STORAGE="$STAT_USED_STORAGE"
  _STORAGE_PERCENT="$STAT_STORAGE_PCT"
  _TOTAL_USERS="$STAT_TOTAL_USERS"
  _ONLINE_USERS="$STAT_ONLINE_USERS"
  _TOTAL_FILES="$STAT_TOTAL_FILES"
  _TOTAL_FOLDERS="$STAT_TOTAL_FOLDERS"
  _DAILY_TRAFFIC="$STAT_DAILY_TRAFFIC"
  _DAILY_UPLOAD="$STAT_DAILY_UPLOAD"
  _DAILY_DOWNLOAD="$STAT_DAILY_DOWNLOAD"
  _YEAR="$(date +%Y)"

  # 10. Превью контента (зависит от типа)
  _CONTENT_PREVIEW=$(_build_content_preview "${V_CONTENT_TYPE}" "$LANG" "")

  # 11. Копируем статику и генерируем
  mkdir -p "$OUTPUT_DIR"
  # Копируем JS из template/
  for f in auth.js app.js; do
    [[ -f "${TEMPLATE_DIR}/${f}" ]] && cp "${TEMPLATE_DIR}/${f}" "${OUTPUT_DIR}/${f}"
  done

  # 12. Рендерим index.html из единого шаблона
  _render_template "${TEMPLATE_DIR}/index.html.tpl" "${OUTPUT_DIR}/index.html"

  # 13. Рендерим login.html (статичная страница)
  if [[ -f "${TEMPLATE_DIR}/login.html.tpl" ]]; then
    _render_template "${TEMPLATE_DIR}/login.html.tpl" "${OUTPUT_DIR}/login.html"
  else
    _build_simple_login_page "${OUTPUT_DIR}/login.html"
  fi

  # 14. CSS с layout-вариантом
  _generate_css "$OUTPUT_DIR" "$colors_json" "${V_LAYOUT}"

  # 15. config.js для JS-кода
  echo "$stats_json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
site = '${site_name}'
lang = '${LANG}'
print(f'window.SITE_CONFIG = {{')
print(f'  siteName: {json.dumps(site)},')
print(f'  language: {json.dumps(lang)},')
print(f'  stats: {json.dumps(d)},')
print(f'}};')
" >"${OUTPUT_DIR}/config.js"

  # 16. nginx.conf (один, больше не дублируется по шаблонам)
  cat >"${OUTPUT_DIR}/nginx.conf" <<NGINX
server {
    listen 80;
    server_name localhost;
    root ${OUTPUT_DIR};
    index index.html;
    server_tokens off;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    location ~* \.(css|js|jpg|png|ico|woff2)$ { expires 30d; }
    location / { try_files \$uri \$uri/ /index.html; }
    error_page 404 /index.html;
}
NGINX

  # 17. Метаданные для ротации и отладки
  python3 -c "
import json, sys
print(json.dumps({
  'seed': '${SEED}',
  'variant': '${variant_id}',
  'language': '${LANG}',
  'color_theme': '${theme}',
  'site_name': '${site_name}',
  'generated_at': '$(date -Iseconds)',
  'version': '2.0'
}, indent=2))
" >"${OUTPUT_DIR}/.generation_meta.json"

  local end_time duration
  end_time=$(date +%s)
  duration=$((end_time - start_time))
  log_success "Generated '$site_name' [${variant_id}/${V_LAYOUT}] in ${duration}s → $OUTPUT_DIR"
  echo "Site: $site_name | Variant: $variant_id | Layout: ${V_LAYOUT} | Time: ${duration}s"
}

# Простая страница логина если нет шаблона
_build_simple_login_page() {
  local out="$1"
  cat >"$out" <<HTML
<!DOCTYPE html>
<html lang="${_LANG}"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${_SITE_NAME} — ${_LOGIN_BUTTON}</title><link rel="stylesheet" href="style.css"></head>
<body class="login-page"><div class="login-container"><div class="login-box">
<div class="login-header"><span class="logo-icon">${_SITE_ICON}</span><h1>${_SITE_NAME}</h1><p>${_SITE_TAGLINE}</p></div>
<form id="login-form" class="login-form">
<div class="form-group"><label>Username</label><input type="text" id="username" autocomplete="username" required></div>
<div class="form-group"><label>Password</label><input type="password" id="password" autocomplete="current-password" required></div>
<button type="submit" class="btn btn-primary btn-block">${_LOGIN_BUTTON}</button>
<div id="error-message" class="error-message" style="display:none"></div>
</form></div></div>
<script src="config.js"></script><script src="auth.js"></script></body></html>
HTML
}

# ── Совместимость с install.sh ───────────────────────────────

decoy_generate_profile() {
  parse_args "$@"
  local tmp
  tmp=$(mktemp -d)
  local orig_out="$OUTPUT_DIR"
  OUTPUT_DIR="$tmp"
  generate

  local meta="${tmp}/.generation_meta.json"
  mkdir -p "$(dirname "$DECOY_CONFIG")"
  if [[ -f "$meta" ]]; then
    python3 -c "
import json
with open('${meta}') as f: m = json.load(f)
config = {
  'template': m.get('variant', 'unknown'),
  'site_name': m.get('site_name', 'Decoy Site'),
  'language': m.get('language', 'ru'),
  'rotation': {'enabled': True, 'interval_hours': 3, 'last_rotated_at': None},
  'types': {
    'jpg': {'enabled': True, 'weight': 40},
    'pdf': {'enabled': True, 'weight': 30},
    'mp4': {'enabled': True, 'weight': 20},
    'mp3': {'enabled': True, 'weight': 10}
  },
  'max_total_files_mb': 5000
}
print(json.dumps(config, indent=2))
" >"$DECOY_CONFIG"
    chmod 600 "$DECOY_CONFIG"
  fi

  rm -rf "$tmp"
  OUTPUT_DIR="$orig_out"
}

decoy_build_webroot() {
  parse_args "$@"
  local orig_out="$OUTPUT_DIR"
  OUTPUT_DIR="$DECOY_WEBROOT"
  generate
  OUTPUT_DIR="$orig_out"
}

decoy_write_nginx_conf() {
  local tpl="${SCRIPT_DIR}/nginx.conf.tpl"
  [[ ! -f "$tpl" ]] && return 0
  local site_name generated_at variant_id
  site_name=$(python3 -c "import json; print(json.load(open('$DECOY_CONFIG')).get('site_name','Decoy Site'))" 2>/dev/null || echo "Decoy Site")
  generated_at=$(date -Iseconds)
  variant_id=$(python3 -c "import json; print(json.load(open('$DECOY_CONFIG')).get('template','unknown'))" 2>/dev/null || echo "unknown")
  mkdir -p "$(dirname "$NGINX_CONF")"
  sed -e "s|{{DECOY_WEBROOT}}|$DECOY_WEBROOT|g" \
    -e "s|{{SITE_NAME}}|$site_name|g" \
    -e "s|{{GENERATED_AT}}|$generated_at|g" \
    -e "s|{{TEMPLATE}}|$variant_id|g" \
    "$tpl" >"$NGINX_CONF"
}

# Этот файл уже определён в rotate.sh, оставляем совместимость
decoy_write_rotate_timer() {
  source "${SCRIPT_DIR}/rotate.sh"
  decoy_write_rotate_timer
}

# ── Точка входа ──────────────────────────────────────────────
main() {
  parse_args "$@"
  generate
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
