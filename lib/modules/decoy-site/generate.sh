#!/bin/bash
# CubiVeil — Decoy Site: генерация при установке
# Все функции этого файла вызываются один раз из module_configure()

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck disable=SC2034
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi
if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# ── Константы / Constants ───────────────────────────────────
# Пути по умолчанию могут быть переопределены через переменные окружения
DECOY_WEBROOT="${DECOY_WEBROOT:-/var/www/decoy}"
DECOY_CONFIG="${DECOY_CONFIG:-/etc/cubiveil/decoy.json}"
NGINX_CONF="${NGINX_CONF:-/etc/nginx/sites-available/cubiveil-decoy}"
# shellcheck disable=SC2034
MAX_FILE_SIZE_MB=500

# В тестовом режиме используем временные директории
if [[ "${TEST_MODE:-false}" == "true" ]]; then
  TEST_DECOY_DIR="${TEST_DECOY_DIR:-/tmp/test-decoy-$$}"
  mkdir -p "$TEST_DECOY_DIR"
  DECOY_WEBROOT="${TEST_DECOY_DIR}/webroot"
  DECOY_CONFIG="${TEST_DECOY_DIR}/decoy.json"
fi

# ── Утилиты / Utilities ─────────────────────────────────────

# Генерация случайного числа в диапазоне [min, max]
gen_range() {
  local min="$1"
  local max="$2"
  echo $((min + RANDOM % (max - min + 1)))
}

# ── Профиль: выбор шаблона и генерация идентичности ─────────

decoy_generate_profile() {
  # Проверяем наличие jq для работы с JSON
  # Используем функцию is_command_available если есть, иначе command -v
  local _jq_available=false
  if type is_command_available &>/dev/null; then
    is_command_available "jq" && _jq_available=true
  elif command -v jq &>/dev/null; then
    _jq_available=true
  fi

  if [[ "$_jq_available" != "true" ]]; then
    log_error "jq not found — required for decoy-site configuration"
    return 1
  fi

  local templates=("portal" "dashboard" "admin" "storage")
  # $RANDOM допустим — выбор из массива, не криптография
  local template="${templates[$((RANDOM % 4))]}"

  local words=(
    "Nexus" "Vault" "Portal" "Core" "Hub" "Base" "Forge" "Grid"
    "Axis" "Link" "Node" "Gate" "Bridge" "Stack" "Layer" "Edge"
    "Apex" "Prime" "Atlas" "Sigma" "Delta" "Omega" "Vector" "Matrix"
    "Pulse" "Flow" "Stream" "Orbit" "Relay" "Index" "Proxy" "Sync"
    "Cloud" "Shield" "Prism" "Helix" "Quartz" "Zenith" "Vortex" "Cipher"
    "Beacon" "Harbor" "Anchor" "Sentry" "Bastion" "Citadel" "Phalanx"
    "Specter" "Phantom" "Vertex" "Lattice"
  )
  local w1="${words[$((RANDOM % ${#words[@]}))]}"
  local w2="${words[$((RANDOM % ${#words[@]}))]}"
  local site_name="${w1} ${w2}"

  # gen_hex из lib/utils.sh
  local accent_color
  accent_color="#$(gen_hex 6)"
  local copyright_year
  copyright_year=$(date +%Y)

  local server_tokens=("nginx" "Apache/2.4.54 (Ubuntu)" "cloudflare")
  local server_token="${server_tokens[$((RANDOM % 3))]}"

  mkdir -p /etc/cubiveil
  cat >"$DECOY_CONFIG" <<EOF
{
  "template":         "${template}",
  "site_name":        "${site_name}",
  "accent_color":     "${accent_color}",
  "copyright_year":   "${copyright_year}",
  "server_token":     "${server_token}",
  "content_types":    ["jpg", "pdf", "mp4", "mp3"],
  "max_total_files_mb": 5000,
  "rotation": {
    "enabled":         true,
    "interval_hours":  3,
    "files_per_cycle": 1,
    "last_rotated_at": null,
    "types": {
      "jpg": { "enabled": true,  "weight": 4, "size_min_mb": 5,   "size_max_mb": 20 },
      "pdf": { "enabled": true,  "weight": 2, "size_min_mb": 50,  "size_max_mb": 200 },
      "mp4": { "enabled": true,  "weight": 1, "size_min_mb": 100, "size_max_mb": 300 },
      "mp3": { "enabled": false, "weight": 1, "size_min_mb": 10,  "size_max_mb": 50 }
    }
  },
  "behavior": {
    "time_windows":    ["morning", "day", "evening"],
    "min_delay_min":   5,
    "max_delay_min":   40,
    "session_files":   3,
    "speed_kbps_min":  200,
    "speed_kbps_max":  1000
  }
}
EOF
  chmod 600 "$DECOY_CONFIG"

  # Проверяем что конфиг записан корректно
  if ! jq -e . "$DECOY_CONFIG" >/dev/null 2>&1; then
    log_error "Failed to write valid decoy config JSON"
    return 1
  fi

  log_info "Профиль: шаблон=${template} имя='${site_name}' цвет=${accent_color}"
}

# ── Сборка webroot ───────────────────────────────────────────

decoy_build_webroot() {
  local template site_name accent_color copyright_year
  template=$(jq -r '.template' "$DECOY_CONFIG")
  site_name=$(jq -r '.site_name' "$DECOY_CONFIG")
  accent_color=$(jq -r '.accent_color' "$DECOY_CONFIG")
  copyright_year=$(jq -r '.copyright_year' "$DECOY_CONFIG")

  # Очистка старых файлов перед генерацией новых (при переустановке/обновлении)
  if [[ -d "${DECOY_WEBROOT}/files" ]]; then
    log_info "Очистка старых файлов перед генерацией новых..."
    find "${DECOY_WEBROOT}/files" -type f -delete 2>/dev/null || true
  fi

  mkdir -p "${DECOY_WEBROOT}/files"

  _generate_html "$template" "$site_name" "$accent_color" "$copyright_year"
  _generate_images "$accent_color"
  _generate_docs  # PDF документы
  _generate_video # MP4/MP3 файлы
  _generate_aux "$site_name"
  _generate_inner_pages "$template" "$site_name" "$accent_color" "$copyright_year"

  find "$DECOY_WEBROOT" -type f -exec chmod 644 {} \;
  find "$DECOY_WEBROOT" -type d -exec chmod 755 {} \;
  chown -R www-data:www-data "$DECOY_WEBROOT"

  local fcount total_size
  fcount=$(find "${DECOY_WEBROOT}/files" -type f | wc -l)
  total_size=$(du -sh "${DECOY_WEBROOT}/files" 2>/dev/null | cut -f1)
  log_success "Webroot собран: ${fcount} файлов, ~${total_size} в ${DECOY_WEBROOT}"
}

# HTML из шаблона
_generate_html() {
  local template="$1" site_name="$2" accent_color="$3" copyright_year="$4"
  sed \
    -e "s|{{SITE_NAME}}|${site_name}|g" \
    -e "s|{{ACCENT_COLOR}}|${accent_color}|g" \
    -e "s|{{COPYRIGHT_YEAR}}|${copyright_year}|g" \
    "${MODULE_DIR}/templates/${template}.html" \
    >"${DECOY_WEBROOT}/index.html"
}

# Изображения — генерация через ImageMagick или заглушки
_generate_images() {
  local accent_color="$1"
  local fcount
  fcount=$(gen_range 3 5) # 3–5 файлов

  for _ in $(seq 1 "$fcount"); do
    local fname seed
    fname="$(gen_hex 8).jpg"
    seed=$(gen_hex 6)

    # Пробуем ImageMagick для красивых изображений
    if command -v convert &>/dev/null; then
      convert -size 4000x3000 \
        "plasma:#${seed}-${accent_color:1}" \
        -quality 88 \
        "${DECOY_WEBROOT}/files/${fname}" 2>/dev/null ||
        dd if=/dev/urandom of="${DECOY_WEBROOT}/files/${fname}" bs=1M count=10 status=none
    else
      # Fallback: случайные данные 5-15 MB
      local size
      size=$(gen_range 5 15)
      dd if=/dev/urandom of="${DECOY_WEBROOT}/files/${fname}" bs=1M count="$size" status=none
    fi
  done
}

# PDF документы — генерация нужного размера
_generate_docs() {
  local count
  count=$(gen_range 1 2) # 1-2 файла

  for i in $(seq 1 "$count"); do
    local fname
    fname="$(gen_hex 8).pdf"

    # Размер PDF: 50-200 MB (реалистично для технических документов)
    local target_size
    target_size=$(gen_range 50 200)

    # Если есть enscript/ghostscript — генерируем реальный PDF
    if command -v enscript &>/dev/null && command -v ps2pdf &>/dev/null; then
      local pages
      pages=$(gen_range 100 300)

      # Генерируем текст документа
      {
        echo "Technical Document $i"
        echo "Generated: $(date +%Y-%m-%d)"
        echo ""
        for p in $(seq 1 "$pages"); do
          echo "════════════════════════════════════════════════════════════"
          echo "Page $p — Section $(gen_hex 4)"
          echo ""
          echo "System architecture analysis — component $(gen_hex 8)"
          echo "  Protocol version: $(gen_hex 16)"
          echo "  Encoding: UTF-8, Compression: LZ4"
          echo "  Encryption: AES-256-GCM"
          echo ""
          echo "Network topology overview:"
          echo "  - Frontend interface layer"
          echo "  - Backend processing unit"
          echo "  - Data storage subsystem"
          echo "  - Network communication module"
          echo ""
          echo "Performance metrics:"
          echo "  - Throughput: $(gen_range 100 999) MB/s"
          echo "  - Latency: $(gen_range 1 50) ms"
          echo "  - Error rate: 0.0$(gen_range 1 99)%"
          echo ""
          echo ""
        done
      } | enscript -B -p - 2>/dev/null | ps2pdf - "${DECOY_WEBROOT}/files/${fname}" 2>/dev/null || true
    fi

    # Если PDF не создан или весит мало — дополняем до нужного размера
    if [[ ! -f "${DECOY_WEBROOT}/files/${fname}" ]]; then
      # Создаем минимальный PDF + случайные данные
      {
        printf '%%PDF-1.4\n'
        printf '1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n'
        printf '2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n'
        printf '3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R>>endobj\n'
        printf 'xref\n0 4\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n193\n%%%%EOF\n'
      } >"${DECOY_WEBROOT}/files/${fname}"
    fi

    # Дополняем файл до нужного размера (target_size MB)
    local current_size
    current_size=$(stat -c%s "${DECOY_WEBROOT}/files/${fname}" 2>/dev/null || echo "0")
    local current_mb=$((current_size / 1048576))

    if [[ $current_mb -lt $target_size ]]; then
      local add_mb=$((target_size - current_mb))
      # Добавляем случайные данные в конец PDF (будут проигнорированы читалками)
      dd if=/dev/urandom bs=1M count="$add_mb" status=none >>"${DECOY_WEBROOT}/files/${fname}" 2>/dev/null || true
    fi
  done
}

# Видео/аудио файлы — генерация нужного размера
_generate_video() {
  # MP4 файл: 100-300 MB (реалистично для короткого видео)
  local fname_mp4
  fname_mp4="$(gen_hex 8).mp4"
  local mp4_size
  mp4_size=$(gen_range 100 300)

  if command -v ffmpeg &>/dev/null; then
    # Генерируем короткое видео с градиентом
    local duration
    duration=$(gen_range 30 120) # 30-120 секунд

    ffmpeg -f lavfi -i "color=c=black:s=1280x720:d=${duration}" \
      -c:v libx264 -tune stillimage -crf 23 -pix_fmt yuv420p \
      "${DECOY_WEBROOT}/files/${fname_mp4}" \
      -loglevel error -y 2>/dev/null || true
  fi

  # Если ffmpeg не сработал или файл слишком маленький — дополняем
  if [[ ! -f "${DECOY_WEBROOT}/files/${fname_mp4}" ]]; then
    # Создаем заглушку MP4 (минимальный валидный заголовок)
    # TODO: полноценная генерация MP4 без ffmpeg
    printf '\x00\x00\x00\x1cftypisom\x00\x00\x02\x00isomiso2mp41' >"${DECOY_WEBROOT}/files/${fname_mp4}"
  fi

  # Дополняем до нужного размера
  local current_size
  current_size=$(stat -c%s "${DECOY_WEBROOT}/files/${fname_mp4}" 2>/dev/null || echo "0")
  local current_mb=$((current_size / 1048576))

  if [[ $current_mb -lt $mp4_size ]]; then
    local add_mb=$((mp4_size - current_mb))
    dd if=/dev/urandom bs=1M count="$add_mb" status=none >>"${DECOY_WEBROOT}/files/${fname_mp4}" 2>/dev/null || true
  fi

  # MP3 файл: 10-50 MB (реалистично для аудио)
  local fname_mp3
  fname_mp3="$(gen_hex 8).mp3"
  local mp3_size
  mp3_size=$(gen_range 10 50)

  if command -v ffmpeg &>/dev/null; then
    # Генерируем тишину/белый шум
    local audio_duration
    audio_duration=$(gen_range 120 600) # 2-10 минут

    ffmpeg -f lavfi -i "anullsrc=r=44100:cl=stereo" \
      -t "$audio_duration" \
      "${DECOY_WEBROOT}/files/${fname_mp3}" \
      -loglevel error -y 2>/dev/null || true
  fi

  # Если ffmpeg не сработал — создаем заглушку
  if [[ ! -f "${DECOY_WEBROOT}/files/${fname_mp3}" ]]; then
    # TODO: полноценная генерация MP3 без ffmpeg
    # Заглушка: ID3 тег + случайные данные
    printf 'ID3\x03\x00\x00\x00\x00\x00\x00' >"${DECOY_WEBROOT}/files/${fname_mp3}"
  fi

  # Дополняем до нужного размера
  current_size=$(stat -c%s "${DECOY_WEBROOT}/files/${fname_mp3}" 2>/dev/null || echo "0")
  current_mb=$((current_size / 1048576))

  if [[ $current_mb -lt $mp3_size ]]; then
    local add_mb=$((mp3_size - current_mb))
    dd if=/dev/urandom bs=1M count="$add_mb" status=none >>"${DECOY_WEBROOT}/files/${fname_mp3}" 2>/dev/null || true
  fi
}

# Вспомогательные файлы — robots.txt, sitemap.xml, favicon.ico
_generate_aux() {
  local site_name="$1"

  # robots.txt — случайные Disallow
  local disallow=("/admin/" "/api/" "/backup/" "/private/"
    "/internal/" "/config/" "/data/" "/uploads/" "/tmp/")
  local count
  count=$(gen_range 2 4)
  {
    echo "User-agent: *"
    for p in "${disallow[@]:0:$count}"; do echo "Disallow: ${p}"; done
  } >"${DECOY_WEBROOT}/robots.txt"

  # sitemap.xml — 3–7 фиктивных путей
  local fake=("/about" "/services" "/contact" "/docs"
    "/team" "/pricing" "/faq" "/news" "/blog")
  local scount
  scount=$(gen_range 3 7)
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    for p in "${fake[@]:0:$scount}"; do
      echo "  <url><loc>https://${DOMAIN:-localhost}${p}</loc></url>"
    done
    echo '</urlset>'
  } >"${DECOY_WEBROOT}/sitemap.xml"

  # favicon.ico через ImageMagick или минимальный fallback
  local accent_color
  accent_color=$(jq -r '.accent_color' "$DECOY_CONFIG" 2>/dev/null || echo "#4a90d9")
  if command -v convert &>/dev/null; then
    convert -size 32x32 "xc:${accent_color}" \
      -define icon:auto-resize=32,16 \
      "${DECOY_WEBROOT}/favicon.ico" 2>/dev/null ||
      _write_minimal_ico "${DECOY_WEBROOT}/favicon.ico"
  else
    _write_minimal_ico "${DECOY_WEBROOT}/favicon.ico"
  fi
}

# Минимальный валидный ICO файл (32x32, 1 цвет)
_write_minimal_ico() {
  local output="$1"
  # ICO header + BMP 32x32 + маска
  printf '\x00\x00\x01\x00\x01\x00\x20\x20\x00\x00\x01\x00\x20\x00' >"$output"
  printf '\x28\x00\x00\x00\x20\x00\x00\x00\x40\x00\x00\x00\x01\x00' >>"$output"
  printf '\x20\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00' >>"$output"
  printf '\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' >>"$output"
  # Прозрачность (маска)
  dd if=/dev/zero bs=1024 count=1 status=none >>"$output" 2>/dev/null
}

# ── Внутренние страницы / Inner Pages ───────────────────────

_generate_inner_pages() {
  local template="$1" site_name="$2" accent="$3" year="$4"

  # Общие CSS переменные для всех страниц
  local css_vars="--accent:${accent};--accent-dim:${accent}22;"

  # Список fake-файлов для /files/
  local fake_files=()
  while IFS= read -r f; do
    fake_files+=("$f")
  done < <(find "${DECOY_WEBROOT}/files" -maxdepth 1 -type f -printf '%f\n' 2>/dev/null | head -10)

  # Генерируем fake строки таблицы файлов
  local files_rows=""
  for fname in "${fake_files[@]}"; do
    local ext="${fname##*.}"
    local size_mb
    size_mb=$(gen_range 10 500)
    local date_offset
    date_offset=$(gen_range 1 30)
    local fdate
    fdate=$(date -d "-${date_offset} days" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d")
    local icon="📄"
    [[ "$ext" == "jpg" || "$ext" == "png" ]] && icon="🖼"
    [[ "$ext" == "mp4" ]] && icon="🎬"
    [[ "$ext" == "mp3" ]] && icon="🎵"
    [[ "$ext" == "pdf" ]] && icon="📕"
    files_rows+="<tr><td>${icon} <a href='/files/${fname}'>${fname}</a></td>"
    files_rows+="<td>${size_mb} MB</td><td>${fdate}</td>"
    files_rows+="<td><button onclick='return false' class='btn-sm'>⬇ Download</button></td></tr>"
  done

  # Fake строки для /audit/logs
  local log_rows=""
  local log_actions=("LOGIN" "LOGOUT" "UPLOAD" "DELETE" "DOWNLOAD" "SHARE" "RENAME" "MOVE")
  local log_users=("admin" "system" "api_user" "backup_agent" "monitor")
  local log_ips=("10.0.0.1" "192.168.1.1" "172.16.0.5" "10.10.0.2")
  for i in $(seq 1 20); do
    local action="${log_actions[$((RANDOM % ${#log_actions[@]}))]}"
    local user="${log_users[$((RANDOM % ${#log_users[@]}))]}"
    local ip="${log_ips[$((RANDOM % ${#log_ips[@]}))]}"
    local mins_ago
    mins_ago=$(gen_range 1 1440)
    local ltime
    ltime=$(date -d "-${mins_ago} minutes" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date +"%Y-%m-%d %H:%M:%S")
    local status_class="ok"
    [[ "$((RANDOM % 5))" -eq 0 ]] && status_class="warn"
    log_rows+="<tr class='${status_class}'><td>${ltime}</td><td>${user}</td>"
    log_rows+="<td>${action}</td><td>${ip}</td>"
    log_rows+="<td>$(gen_hex 8)</td></tr>"
  done

  # Общий <head> для всех страниц
  _inner_head() {
    local title="$1"
    cat <<ENDHEAD
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title} — ${site_name}</title>
<style>
  :root{${css_vars}}
  *{box-sizing:border-box;margin:0;padding:0}
  body{font-family:system-ui,sans-serif;background:#0f1117;color:#cdd6f4;min-height:100vh}
  a{color:var(--accent);text-decoration:none}
  a:hover{text-decoration:underline}
  .nav{background:#1e2030;border-bottom:1px solid var(--accent)33;padding:0 2rem;
       display:flex;align-items:center;gap:2rem;height:52px}
  .nav .logo{color:var(--accent);font-weight:700;font-size:1.1rem;letter-spacing:.05em}
  .nav a{color:#cdd6f4;font-size:.9rem;opacity:.8}
  .nav a:hover,.nav a.active{opacity:1;color:var(--accent)}
  .nav .spacer{flex:1}
  .nav .user{font-size:.85rem;opacity:.6}
  .container{max-width:1100px;margin:2rem auto;padding:0 1.5rem}
  h1{font-size:1.4rem;margin-bottom:1.5rem;color:#fff}
  .card{background:#1e2030;border:1px solid #313244;border-radius:8px;padding:1.5rem;margin-bottom:1.5rem}
  table{width:100%;border-collapse:collapse;font-size:.9rem}
  th{text-align:left;padding:.6rem 1rem;border-bottom:1px solid #313244;
     color:var(--accent);font-weight:600;font-size:.8rem;text-transform:uppercase;letter-spacing:.05em}
  td{padding:.7rem 1rem;border-bottom:1px solid #1e203055}
  tr:hover td{background:#313244}
  tr.warn td{color:#f38ba8}
  tr.ok td{color:#cdd6f4}
  .btn{background:var(--accent);color:#fff;border:none;padding:.5rem 1.2rem;
       border-radius:5px;cursor:pointer;font-size:.9rem}
  .btn:hover{opacity:.85}
  .btn-sm{background:transparent;border:1px solid var(--accent)66;color:var(--accent);
          padding:.25rem .7rem;border-radius:4px;cursor:pointer;font-size:.8rem}
  .breadcrumb{font-size:.85rem;opacity:.5;margin-bottom:1rem}
  .breadcrumb a{color:inherit}
  .alert{padding:.75rem 1rem;border-radius:6px;margin-bottom:1rem;font-size:.9rem}
  .alert-err{background:#f38ba822;border:1px solid #f38ba844;color:#f38ba8}
  .form-group{margin-bottom:1rem}
  .form-group label{display:block;font-size:.85rem;margin-bottom:.35rem;opacity:.7}
  .form-group input,.form-group select{width:100%;padding:.6rem .9rem;
    background:#0f1117;border:1px solid #313244;border-radius:5px;color:#cdd6f4;font-size:.9rem}
  .form-group input:focus{outline:none;border-color:var(--accent)}
  .footer{text-align:center;padding:2rem;font-size:.8rem;opacity:.3;margin-top:2rem}
</style>
</head>
<body>
<nav class="nav">
  <span class="logo">${site_name}</span>
  <a href="/">Dashboard</a>
  <a href="/files/">Files</a>
  <a href="/audit/logs">Audit Log</a>
  <span class="spacer"></span>
  <span class="user">admin@system</span>
</nav>
ENDHEAD
  }

  _inner_foot() {
    cat <<ENDFOOT
<div class="footer">© ${year} ${site_name}. All rights reserved.</div>
</body></html>
ENDFOOT
  }

  # ── /files/index.html ───────────────────────────────────────
  mkdir -p "${DECOY_WEBROOT}/files"
  {
    _inner_head "File Storage"
    cat <<ENDFILES
<div class="container">
  <div class="breadcrumb"><a href="/">Home</a> / Files</div>
  <h1>File Storage</h1>
  <div class="card">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem">
      <span style="font-size:.9rem;opacity:.6">${#fake_files[@]} objects</span>
      <button class="btn" onclick="window.location='/files/upload'">⬆ Upload</button>
    </div>
    <table>
      <thead><tr><th>Name</th><th>Size</th><th>Modified</th><th>Actions</th></tr></thead>
      <tbody>${files_rows}</tbody>
    </table>
  </div>
</div>
ENDFILES
    _inner_foot
  } >"${DECOY_WEBROOT}/files/index.html"

  # ── /files/upload/index.html ────────────────────────────────
  mkdir -p "${DECOY_WEBROOT}/files/upload"
  {
    _inner_head "Upload File"
    cat <<ENDUPLOAD
<div class="container">
  <div class="breadcrumb"><a href="/">Home</a> / <a href="/files/">Files</a> / Upload</div>
  <h1>Upload File</h1>
  <div class="card" style="max-width:520px">
    <form action="/files/upload" method="post" enctype="multipart/form-data">
      <div class="form-group">
        <label>Select file</label>
        <input type="file" name="file">
      </div>
      <div class="form-group">
        <label>Destination folder</label>
        <select name="folder">
          <option>/ (root)</option>
          <option>/backup</option>
          <option>/archive</option>
          <option>/shared</option>
        </select>
      </div>
      <div class="form-group">
        <label>Description (optional)</label>
        <input type="text" name="desc" placeholder="File description...">
      </div>
      <button class="btn" type="submit">Upload</button>
      <a href="/files/" style="margin-left:1rem;font-size:.9rem">Cancel</a>
    </form>
  </div>
</div>
ENDUPLOAD
    _inner_foot
  } >"${DECOY_WEBROOT}/files/upload/index.html"

  # ── /audit/logs/index.html ──────────────────────────────────
  mkdir -p "${DECOY_WEBROOT}/audit/logs"
  {
    _inner_head "Audit Log"
    cat <<ENDAUDIT
<div class="container">
  <div class="breadcrumb"><a href="/">Home</a> / Audit Log</div>
  <h1>Audit Log</h1>
  <div class="card">
    <div style="display:flex;gap:1rem;margin-bottom:1rem;align-items:center">
      <input style="flex:1;padding:.5rem .8rem;background:#0f1117;border:1px solid #313244;
             border-radius:5px;color:#cdd6f4" placeholder="Filter events...">
      <select style="padding:.5rem;background:#0f1117;border:1px solid #313244;
              border-radius:5px;color:#cdd6f4">
        <option>All events</option>
        <option>LOGIN</option>
        <option>UPLOAD</option>
        <option>DELETE</option>
      </select>
      <button class="btn-sm" onclick="return false">Export CSV</button>
    </div>
    <table>
      <thead><tr><th>Timestamp</th><th>User</th><th>Action</th><th>IP</th><th>Request ID</th></tr></thead>
      <tbody>${log_rows}</tbody>
    </table>
  </div>
</div>
ENDAUDIT
    _inner_foot
  } >"${DECOY_WEBROOT}/audit/logs/index.html"

  # ── /404.html ───────────────────────────────────────────────
  {
    _inner_head "404 Not Found"
    cat <<END404
<div class="container" style="text-align:center;padding-top:4rem">
  <div style="font-size:4rem;opacity:.2;margin-bottom:1rem">404</div>
  <h1 style="margin-bottom:.5rem">Page Not Found</h1>
  <p style="opacity:.5;margin-bottom:2rem">The requested resource could not be found.</p>
  <a href="/" class="btn">← Back to Dashboard</a>
</div>
END404
    _inner_foot
  } >"${DECOY_WEBROOT}/404.html"

  log_info "Inner pages generated: /files/, /files/upload, /audit/logs, /404.html"
}

# ── Nginx конфигурация ───────────────────────────────────────

decoy_write_nginx_conf() {
  local server_token
  server_token=$(jq -r '.server_token' "$DECOY_CONFIG")

  # Определяем версию nginx для выбора правильного синтаксиса http2
  # nginx >= 1.25.1: отдельная директива "http2 on;"
  # nginx < 1.25.1: inline "listen 443 ssl http2;"
  local _nginx_ver _nginx_major _nginx_minor
  local HTTP2_LISTEN HTTP2_DIRECTIVE

  if command -v nginx &>/dev/null; then
    _nginx_ver=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "0.0.0")
    _nginx_major=$(echo "$_nginx_ver" | cut -d. -f1)
    _nginx_minor=$(echo "$_nginx_ver" | cut -d. -f2)

    if [[ $_nginx_major -gt 1 || ($_nginx_major -eq 1 && $_nginx_minor -ge 25) ]]; then
      # nginx >= 1.25.1: отдельная директива
      HTTP2_LISTEN="listen 443 ssl;"
      HTTP2_DIRECTIVE="http2 on;"
    else
      # nginx < 1.25.1: inline в listen
      HTTP2_LISTEN="listen 443 ssl http2;"
      HTTP2_DIRECTIVE=""
    fi
  else
    # nginx не установлен — используем старый синтаксис (совместимый)
    HTTP2_LISTEN="listen 443 ssl http2;"
    HTTP2_DIRECTIVE=""
  fi

  # Пути к сертификатам — не копируем, ссылаемся на существующие
  local cert_file key_file
  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    cert_file="/usr/local/s-ui/cert/cert.pem"
    key_file="/usr/local/s-ui/cert/key.pem"
  else
    cert_file="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    key_file="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
  fi

  local referrer_opts=("no-referrer" "strict-origin" "same-origin")
  local referrer="${referrer_opts[$((RANDOM % 3))]}"

  sed \
    -e "s|{{DOMAIN}}|${DOMAIN:-_}|g" \
    -e "s|{{WEBROOT}}|${DECOY_WEBROOT}|g" \
    -e "s|{{CERT_FILE}}|${cert_file}|g" \
    -e "s|{{KEY_FILE}}|${key_file}|g" \
    -e "s|{{SERVER_TOKEN}}|${server_token}|g" \
    -e "s|{{REFERRER_POLICY}}|${referrer}|g" \
    -e "s|{{HTTP2_LISTEN}}|${HTTP2_LISTEN}|g" \
    -e "s|{{HTTP2_DIRECTIVE}}|${HTTP2_DIRECTIVE}|g" \
    "${MODULE_DIR}/nginx.conf.tpl" \
    >"$NGINX_CONF"

  chmod 640 "$NGINX_CONF"
  log_info "Nginx конфиг записан: ${NGINX_CONF} (nginx ${_nginx_ver:-unknown})"
}
