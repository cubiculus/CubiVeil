#!/bin/bash
# CubiVeil — Decoy Site: генерация при установке
# Все функции этого файла вызываются один раз из module_configure()

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi
if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi
if [[ -f "${SCRIPT_DIR}/lib/utils.sh" ]]; then
  source "${SCRIPT_DIR}/lib/utils.sh"
fi

# ── Константы / Constants ───────────────────────────────────
DECOY_WEBROOT="/var/www/decoy"
DECOY_CONFIG="/etc/cubiveil/decoy.json"
NGINX_CONF="/etc/nginx/sites-available/cubiveil-decoy"
MAX_FILE_SIZE_MB=500

# ── Утилиты / Utilities ─────────────────────────────────────

# Генерация случайного числа в диапазоне [min, max]
gen_range() {
  local min="$1"
  local max="$2"
  echo $(( min + RANDOM % (max - min + 1) ))
}

# ── Профиль: выбор шаблона и генерация идентичности ─────────

decoy_generate_profile() {
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
  local accent_color="#$(gen_hex 6)"
  local copyright_year
  copyright_year=$(date +%Y)

  local server_tokens=("nginx" "Apache/2.4.54 (Ubuntu)" "cloudflare")
  local server_token="${server_tokens[$((RANDOM % 3))]}"

  mkdir -p /etc/cubiveil
  cat > "$DECOY_CONFIG" <<EOF
{
  "template":       "${template}",
  "site_name":      "${site_name}",
  "accent_color":   "${accent_color}",
  "copyright_year": "${copyright_year}",
  "server_token":   "${server_token}",
  "content_types":  ["jpg", "pdf", "mp4", "mp3"],
  "rotation": {
    "enabled":         true,
    "interval_hours":  3,
    "files_per_cycle": 1,
    "last_rotated_at": null
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
  log_info "Профиль: шаблон=${template} имя='${site_name}' цвет=${accent_color}"
}

# ── Сборка webroot ───────────────────────────────────────────

decoy_build_webroot() {
  local template site_name accent_color copyright_year
  template=$(jq -r '.template'         "$DECOY_CONFIG")
  site_name=$(jq -r '.site_name'       "$DECOY_CONFIG")
  accent_color=$(jq -r '.accent_color' "$DECOY_CONFIG")
  copyright_year=$(jq -r '.copyright_year' "$DECOY_CONFIG")

  mkdir -p "${DECOY_WEBROOT}/files"

  _generate_html   "$template" "$site_name" "$accent_color" "$copyright_year"
  _generate_images "$accent_color"
  _generate_docs               # PDF документы
  _generate_video              # MP4/MP3 файлы
  _generate_aux    "$site_name"

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
    -e "s|{{SITE_NAME}}|${site_name}|g"           \
    -e "s|{{ACCENT_COLOR}}|${accent_color}|g"     \
    -e "s|{{COPYRIGHT_YEAR}}|${copyright_year}|g" \
    "${MODULE_DIR}/templates/${template}.html"     \
    > "${DECOY_WEBROOT}/index.html"
}

# Изображения — генерация через ImageMagick или заглушки
_generate_images() {
  local accent_color="$1"
  local fcount
  fcount=$(gen_range 3 5)   # 3–5 файлов

  for _ in $(seq 1 "$fcount"); do
    local fname seed
    fname="$(gen_hex 8).jpg"
    seed=$(gen_hex 6)

    # Пробуем ImageMagick для красивых изображений
    if command -v convert &>/dev/null; then
      convert -size 4000x3000 \
        "plasma:#${seed}-${accent_color:1}" \
        -quality 88 \
        "${DECOY_WEBROOT}/files/${fname}" 2>/dev/null || \
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
  count=$(gen_range 1 2)  # 1-2 файла

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
      } > "${DECOY_WEBROOT}/files/${fname}"
    fi

    # Дополняем файл до нужного размера (target_size MB)
    local current_size
    current_size=$(stat -c%s "${DECOY_WEBROOT}/files/${fname}" 2>/dev/null || echo "0")
    local current_mb=$(( current_size / 1048576 ))

    if [[ $current_mb -lt $target_size ]]; then
      local add_mb=$(( target_size - current_mb ))
      # Добавляем случайные данные в конец PDF (будут проигнорированы читалками)
      dd if=/dev/urandom bs=1M count="$add_mb" status=none >> "${DECOY_WEBROOT}/files/${fname}" 2>/dev/null || true
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
    duration=$(gen_range 30 120)  # 30-120 секунд

    ffmpeg -f lavfi -i "color=c=black:s=1280x720:d=${duration}" \
      -c:v libx264 -tune stillimage -crf 23 -pix_fmt yuv420p \
      "${DECOY_WEBROOT}/files/${fname_mp4}" \
      -loglevel error -y 2>/dev/null || true
  fi

  # Если ffmpeg не сработал или файл слишком маленький — дополняем
  if [[ ! -f "${DECOY_WEBROOT}/files/${fname_mp4}" ]]; then
    # Создаем заглушку MP4 (минимальный валидный заголовок)
    # TODO: полноценная генерация MP4 без ffmpeg
    printf '\x00\x00\x00\x1cftypisom\x00\x00\x02\x00isomiso2mp41' > "${DECOY_WEBROOT}/files/${fname_mp4}"
  fi

  # Дополняем до нужного размера
  local current_size
  current_size=$(stat -c%s "${DECOY_WEBROOT}/files/${fname_mp4}" 2>/dev/null || echo "0")
  local current_mb=$(( current_size / 1048576 ))

  if [[ $current_mb -lt $mp4_size ]]; then
    local add_mb=$(( mp4_size - current_mb ))
    dd if=/dev/urandom bs=1M count="$add_mb" status=none >> "${DECOY_WEBROOT}/files/${fname_mp4}" 2>/dev/null || true
  fi

  # MP3 файл: 10-50 MB (реалистично для аудио)
  local fname_mp3
  fname_mp3="$(gen_hex 8).mp3"
  local mp3_size
  mp3_size=$(gen_range 10 50)

  if command -v ffmpeg &>/dev/null; then
    # Генерируем тишину/белый шум
    local audio_duration
    audio_duration=$(gen_range 120 600)  # 2-10 минут

    ffmpeg -f lavfi -i "anullsrc=r=44100:cl=stereo" \
      -t "$audio_duration" \
      "${DECOY_WEBROOT}/files/${fname_mp3}" \
      -loglevel error -y 2>/dev/null || true
  fi

  # Если ffmpeg не сработал — создаем заглушку
  if [[ ! -f "${DECOY_WEBROOT}/files/${fname_mp3}" ]]; then
    # TODO: полноценная генерация MP3 без ffmpeg
    # Заглушка: ID3 тег + случайные данные
    printf 'ID3\x03\x00\x00\x00\x00\x00\x00' > "${DECOY_WEBROOT}/files/${fname_mp3}"
  fi

  # Дополняем до нужного размера
  current_size=$(stat -c%s "${DECOY_WEBROOT}/files/${fname_mp3}" 2>/dev/null || echo "0")
  current_mb=$(( current_size / 1048576 ))

  if [[ $current_mb -lt $mp3_size ]]; then
    local add_mb=$(( mp3_size - current_mb ))
    dd if=/dev/urandom bs=1M count="$add_mb" status=none >> "${DECOY_WEBROOT}/files/${fname_mp3}" 2>/dev/null || true
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
  } > "${DECOY_WEBROOT}/robots.txt"

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
  } > "${DECOY_WEBROOT}/sitemap.xml"

  # favicon.ico через ImageMagick или минимальный fallback
  local accent_color
  accent_color=$(jq -r '.accent_color' "$DECOY_CONFIG" 2>/dev/null || echo "#4a90d9")
  if command -v convert &>/dev/null; then
    convert -size 32x32 "xc:${accent_color}" \
      -define icon:auto-resize=32,16 \
      "${DECOY_WEBROOT}/favicon.ico" 2>/dev/null || \
    _write_minimal_ico "${DECOY_WEBROOT}/favicon.ico"
  else
    _write_minimal_ico "${DECOY_WEBROOT}/favicon.ico"
  fi
}

# Минимальный валидный ICO файл (32x32, 1 цвет)
_write_minimal_ico() {
  local output="$1"
  # ICO header + BMP 32x32 + маска
  printf '\x00\x00\x01\x00\x01\x00\x20\x20\x00\x00\x01\x00\x20\x00' > "$output"
  printf '\x28\x00\x00\x00\x20\x00\x00\x00\x40\x00\x00\x00\x01\x00' >> "$output"
  printf '\x20\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x00' >> "$output"
  printf '\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' >> "$output"
  # Прозрачность (маска)
  dd if=/dev/zero bs=1024 count=1 status=none >> "$output" 2>/dev/null
}

# ── Nginx конфигурация ───────────────────────────────────────

decoy_write_nginx_conf() {
  local server_token
  server_token=$(jq -r '.server_token' "$DECOY_CONFIG")

  # Пути к сертификатам — не копируем, ссылаемся на существующие
  local cert_file key_file
  if [[ "${DEV_MODE:-false}" == "true" ]]; then
    cert_file="/var/lib/marzban/certs/cert.pem"
    key_file="/var/lib/marzban/certs/key.pem"
  else
    cert_file="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
    key_file="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
  fi

  local referrer_opts=("no-referrer" "strict-origin" "same-origin")
  local referrer="${referrer_opts[$((RANDOM % 3))]}"

  sed \
    -e "s|{{DOMAIN}}|${DOMAIN:-_}|g"          \
    -e "s|{{WEBROOT}}|${DECOY_WEBROOT}|g"     \
    -e "s|{{CERT_FILE}}|${cert_file}|g"       \
    -e "s|{{KEY_FILE}}|${key_file}|g"         \
    -e "s|{{SERVER_TOKEN}}|${server_token}|g" \
    -e "s|{{REFERRER_POLICY}}|${referrer}|g"  \
    "${MODULE_DIR}/nginx.conf.tpl"             \
    > "$NGINX_CONF"

  chmod 640 "$NGINX_CONF"
  log_info "Nginx конфиг записан: ${NGINX_CONF}"
}
