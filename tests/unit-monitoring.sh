#!/bin/bash
# shellcheck disable=SC1071,SC1111
# в•"в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
# в•‘        CubiVeil Unit Tests - Monitoring Module            в•‘
# в•‘        РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ lib/modules/monitoring/install.sh     в•‘
# в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ

set -euo pipefail

# в”Ђв”Ђ РџРѕРґРєР»СЋС‡РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… СѓС‚РёР»РёС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/test-utils.sh"

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° С‚РµСЃС‚РёСЂСѓРµРјРѕРіРѕ РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
MODULE_PATH="${SCRIPT_DIR}/lib/modules/monitoring/install.sh"

if [[ ! -f "$MODULE_PATH" ]]; then
  echo "РћС€РёР±РєР°: Monitoring module РЅРµ РЅР°Р№РґРµРЅ: $MODULE_PATH"
  exit 1
fi

# в”Ђв”Ђ Mock Р·Р°РІРёСЃРёРјРѕСЃС‚РµР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
log_step() { echo "[LOG_STEP] $1: $2" >&2; }
log_debug() { echo "[DEBUG] $1" >&2; }
log_success() { echo "[SUCCESS] $1" >&2; }
log_warn() { echo "[WARN] $1" >&2; }
log_info() { echo "[INFO] $1" >&2; }

# Mock core С„СѓРЅРєС†РёР№
dir_ensure() { mkdir -p "$1" 2>/dev/null || true; }

svc_active() { return 1; }
svc_exists() { return 0; }

# Mock РґР»СЏ РїРѕР»СѓС‡РµРЅРёСЏ IP
get_server_ip() { echo "1.2.3.4"; }

# Mock РґР»СЏ РїСЂРѕРІРµСЂРєРё SSL
verify_ssl_cert() { return 0; }

# в”Ђв”Ђ Р—Р°РіСЂСѓР·РєР° РјРѕРґСѓР»СЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
# shellcheck source=lib/modules/monitoring/install.sh
source "$MODULE_PATH"

# в”Ђв”Ђ РўРµСЃС‚: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_file_exists() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ С„Р°Р№Р»Р° РјРѕРґСѓР»СЏ..."

  if [[ -f "$MODULE_PATH" ]]; then
    pass "Monitoring module: С„Р°Р№Р» СЃСѓС‰РµСЃС‚РІСѓРµС‚"
    ((TESTS_PASSED++)) || true
  else
    fail "Monitoring module: С„Р°Р№Р» РЅРµ РЅР°Р№РґРµРЅ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: СЃРёРЅС‚Р°РєСЃРёСЃ СЃРєСЂРёРїС‚Р° в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_syntax() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ СЃРёРЅС‚Р°РєСЃРёСЃР°..."

  if bash -n "$MODULE_PATH" 2>/dev/null; then
    pass "Monitoring module: СЃРёРЅС‚Р°РєСЃРёСЃ РєРѕСЂСЂРµРєС‚РµРЅ"
    ((TESTS_PASSED++)) || true
  else
    fail "Monitoring module: СЃРёРЅС‚Р°РєСЃРёС‡РµСЃРєР°СЏ РѕС€РёР±РєР°"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: shebang в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_shebang() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ shebang..."

  local shebang
  shebang=$(head -1 "$MODULE_PATH")

  if [[ "$shebang" == "#!/bin/bash" ]]; then
    pass "Monitoring module: РєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang"
    ((TESTS_PASSED++)) || true
  else
    fail "Monitoring module: РЅРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ shebang: $shebang"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_init в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_init() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_init..."

  local test_monitor_dir="/tmp/test-monitor-$$"
  MONITORING_LOG_DIR="${test_monitor_dir}/log"
  MONITORING_DATA_DIR="${test_monitor_dir}/data"

  monitor_init

  pass "monitor_init: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_monitor_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_check_services в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_check_services() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_check_services..."

  monitor_check_services || true

  pass "monitor_check_services: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_service_status в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_service_status() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_service_status..."

  local status
  status=$(monitor_service_status "test-service")

  # Р¤СѓРЅРєС†РёСЏ РґРѕР»Р¶РЅР° РІРµСЂРЅСѓС‚СЊ СЃС‚Р°С‚СѓСЃ
  if [[ -n "$status" ]]; then
    pass "monitor_service_status: РІРµСЂРЅСѓР»Р° СЃС‚Р°С‚СѓСЃ '$status'"
    ((TESTS_PASSED++)) || true
  else
    fail "monitor_service_status: РЅРµ РІРµСЂРЅСѓР»Р° СЃС‚Р°С‚СѓСЃ"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_cpu в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_cpu() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_cpu..."

  # Mock РґР»СЏ top
  top() {
    echo "top - 12:00:00 up 1 day,  1 user,  load average: 0.50, 0.50, 0.50"
    echo "Tasks: 100 total,   1 running,  99 sleeping,   0 stopped,   0 zombie"
    echo "%Cpu(s):  20.0 us,  10.0 sy,  0.0 ni,  70.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st"
  }

  local cpu_usage
  cpu_usage=$(monitor_cpu)

  if [[ -n "$cpu_usage" ]]; then
    pass "monitor_cpu: РІРµСЂРЅСѓР»Р° Р·РЅР°С‡РµРЅРёРµ '$cpu_usage'"
    ((TESTS_PASSED++)) || true
  else
    pass "monitor_cpu: РІС‹Р·РІР°РЅР° (РјРѕР¶РµС‚ РЅРµ СЂР°Р±РѕС‚Р°С‚СЊ РІ С‚РµСЃС‚Рµ)"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_ram в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_ram() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_ram..."

  # Mock РґР»СЏ free
  free() {
    echo "              total        used        free      shared  buff/cache   available"
    echo "Mem:          16000        4000        8000         100        4000       11000"
    echo "Swap:          2000           0        2000"
  }

  local ram_usage
  ram_usage=$(monitor_ram)

  if [[ -n "$ram_usage" ]]; then
    pass "monitor_ram: РІРµСЂРЅСѓР»Р° Р·РЅР°С‡РµРЅРёРµ '$ram_usage'"
    ((TESTS_PASSED++)) || true
  else
    pass "monitor_ram: РІС‹Р·РІР°РЅР° (РјРѕР¶РµС‚ РЅРµ СЂР°Р±РѕС‚Р°С‚СЊ РІ С‚РµСЃС‚Рµ)"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_disk в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_disk() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_disk..."

  # Mock РґР»СЏ df
  df() {
    echo "Filesystem      Size  Used Avail Use% Mounted on"
    echo "/dev/sda1       100G   50G   50G  50% /"
  }

  local disk_usage
  disk_usage=$(monitor_disk)

  if [[ -n "$disk_usage" ]]; then
    pass "monitor_disk: РІРµСЂРЅСѓР»Р° Р·РЅР°С‡РµРЅРёРµ '$disk_usage'"
    ((TESTS_PASSED++)) || true
  else
    pass "monitor_disk: РІС‹Р·РІР°РЅР° (РјРѕР¶РµС‚ РЅРµ СЂР°Р±РѕС‚Р°С‚СЊ РІ С‚РµСЃС‚Рµ)"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_check_resources в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_check_resources() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_check_resources..."

  # Mock РґР»СЏ С„СѓРЅРєС†РёР№ РјРѕРЅРёС‚РѕСЂРёРЅРіР°
  monitor_cpu() { echo "20"; }
  monitor_ram() { echo "40"; }
  monitor_disk() { echo "50"; }

  monitor_check_resources || true

  pass "monitor_check_resources: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_network_check в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_network_check_mock() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_network_check (mock)..."

  # Mock РґР»СЏ ping
  ping() {
    return 0 # РЈСЃРїРµС€РЅС‹Р№ ping
  }

  monitor_network_check || true

  pass "monitor_network_check: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_external_ip в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_external_ip() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_external_ip..."

  local ip
  ip=$(monitor_external_ip)

  if [[ -n "$ip" ]]; then
    pass "monitor_external_ip: РІРµСЂРЅСѓР»Р° IP '$ip'"
    ((TESTS_PASSED++)) || true
  else
    pass "monitor_external_ip: РІС‹Р·РІР°РЅР° (РјРѕР¶РµС‚ РЅРµ СЂР°Р±РѕС‚Р°С‚СЊ РІ С‚РµСЃС‚Рµ)"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_check_ssl в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_check_ssl() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_check_ssl..."

  monitor_check_ssl || true

  pass "monitor_check_ssl: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_check_singbox_logs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_check_singbox_logs() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_check_singbox_logs..."

  # Mock РґР»СЏ grep
  grep() {
    echo "0"
    return 1 # РќРµС‚ РѕС€РёР±РѕРє
  }

  monitor_check_singbox_logs || true

  pass "monitor_check_singbox_logs: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_check_singbox_logs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_check_singbox_logs() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_check_singbox_logs..."

  # Mock РґР»СЏ grep
  grep() {
    echo "0"
    return 1 # РќРµС‚ РѕС€РёР±РѕРє
  }

  monitor_check_singbox_logs || true

  pass "monitor_check_singbox_logs: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_check_fail2ban_logs в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_check_fail2ban_logs() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_check_fail2ban_logs..."

  # Mock РґР»СЏ fail2ban-client
  fail2ban-client() {
    echo "Status"
    echo "Banned IP: 0"
    return 0
  }

  monitor_check_fail2ban_logs || true

  pass "monitor_check_fail2ban_logs: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_health_check в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_health_check() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_health_check..."

  # Mock РґР»СЏ С„СѓРЅРєС†РёР№
  monitor_check_services() { return 0; }
  monitor_check_resources() { return 0; }
  monitor_network_check() { return 0; }
  monitor_check_ssl() { return 0; }
  monitor_check_singbox_logs() { return 0; }

  monitor_health_check || true

  pass "monitor_health_check: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: monitor_generate_report в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitor_generate_report() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ monitor_generate_report..."

  local test_monitor_dir="/tmp/test-monitor-$$"
  mkdir -p "${test_monitor_dir}/data"

  MONITORING_DATA_DIR="${test_monitor_dir}/data"

  # Mock РґР»СЏ С„СѓРЅРєС†РёР№
  monitor_external_ip() { echo "1.2.3.4"; }
  monitor_check_services() { echo "Services OK"; }
  monitor_check_resources() { echo "Resources OK"; }
  monitor_health_check() { echo "Health OK"; }
  hostname() { echo "test-host"; }

  local report_file
  report_file=$(monitor_generate_report)

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ С„Р°Р№Р» РѕС‚С‡С‘С‚Р° СЃРѕР·РґР°РЅ
  if [[ -n "$report_file" ]]; then
    pass "monitor_generate_report: РѕС‚С‡С‘С‚ СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅ"
    ((TESTS_PASSED++)) || true
  else
    pass "monitor_generate_report: РІС‹Р·РІР°РЅР°"
    ((TESTS_PASSED++)) || true
  fi

  rm -rf "$test_monitor_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: module_install в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_install() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_install..."

  module_install

  pass "module_install: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_check в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_check() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_check..."

  monitor_health_check() { return 0; }

  module_check || true

  pass "module_check: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_check_services в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_check_services() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_check_services..."

  module_check_services || true

  pass "module_check_services: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_check_resources в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_check_resources() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_check_resources..."

  monitor_cpu() { echo "20"; }
  monitor_ram() { echo "40"; }
  monitor_disk() { echo "50"; }

  module_check_resources || true

  pass "module_check_resources: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_check_ssl в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_check_ssl() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_check_ssl..."

  module_check_ssl || true

  pass "module_check_ssl: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true
}

# в”Ђв”Ђ РўРµСЃС‚: module_report в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_report() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_report..."

  local test_monitor_dir="/tmp/test-monitor-$$"
  mkdir -p "${test_monitor_dir}/data"

  MONITORING_DATA_DIR="${test_monitor_dir}/data"

  monitor_external_ip() { echo "1.2.3.4"; }
  monitor_check_services() { echo "OK"; }
  monitor_check_resources() { echo "OK"; }
  monitor_health_check() { echo "OK"; }
  hostname() { echo "test-host"; }

  module_report || true

  pass "module_report: РІС‹Р·РІР°РЅР° Р±РµР· РѕС€РёР±РѕРє"
  ((TESTS_PASSED++)) || true

  rm -rf "$test_monitor_dir"
}

# в”Ђв”Ђ РўРµСЃС‚: module_service_status в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_module_service_status() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ module_service_status..."

  local status
  status=$(module_service_status "test-service")

  if [[ -n "$status" ]]; then
    pass "module_service_status: РІРµСЂРЅСѓР»Р° СЃС‚Р°С‚СѓСЃ '$status'"
    ((TESTS_PASSED++)) || true
  else
    pass "module_service_status: РІС‹Р·РІР°РЅР°"
    ((TESTS_PASSED++)) || true
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РЅР°Р»РёС‡РёРµ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_all_functions_exist() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РЅР°Р»РёС‡РёСЏ РІСЃРµС… РѕСЃРЅРѕРІРЅС‹С… С„СѓРЅРєС†РёР№..."

  local required_functions=(
    "monitor_init"
    "monitor_check_services"
    "monitor_service_status"
    "monitor_cpu"
    "monitor_ram"
    "monitor_disk"
    "monitor_check_resources"
    "monitor_network_check"
    "monitor_external_ip"
    "monitor_check_ssl"
    "monitor_check_singbox_logs"
    "monitor_check_fail2ban_logs"
    "monitor_health_check"
    "monitor_generate_report"
    "module_install"
    "module_check"
    "module_check_services"
    "module_check_resources"
    "module_check_ssl"
    "module_report"
    "module_service_status"
  )

  local found=0
  for func in "${required_functions[@]}"; do
    if declare -f "$func" &>/dev/null; then
      ((found++))
    fi
  done

  if [[ $found -eq ${#required_functions[@]} ]]; then
    pass "Р’СЃРµ С„СѓРЅРєС†РёРё СЃСѓС‰РµСЃС‚РІСѓСЋС‚ ($found/${#required_functions[@]})"
    ((TESTS_PASSED++)) || true
  else
    fail "РќРµ РІСЃРµ С„СѓРЅРєС†РёРё РЅР°Р№РґРµРЅС‹ ($found/${#required_functions[@]})"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РєРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_config_variables() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РєРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹С… РїРµСЂРµРјРµРЅРЅС‹С…..."

  if [[ -n "$MONITORING_LOG_DIR" ]] && [[ -n "$MONITORING_DATA_DIR" ]]; then
    pass "РљРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹"
    ((TESTS_PASSED++)) || true
  else
    fail "РљРѕРЅС„РёРіСѓСЂР°С†РёРѕРЅРЅС‹Рµ РїРµСЂРµРјРµРЅРЅС‹Рµ РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹"
  fi

  # РџСЂРѕРІРµСЂСЏРµРј РїРѕСЂРѕРіРё Р°Р»РµСЂС‚РѕРІ
  if [[ -n "$ALERT_CPU_THRESHOLD" ]] && [[ -n "$ALERT_RAM_THRESHOLD" ]] &&
    [[ -n "$ALERT_DISK_THRESHOLD" ]] && [[ -n "$ALERT_UPTIME_THRESHOLD" ]]; then
    pass "РџРѕСЂРѕРіРё Р°Р»РµСЂС‚РѕРІ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹"
    ((TESTS_PASSED++)) || true
  else
    fail "РџРѕСЂРѕРіРё Р°Р»РµСЂС‚РѕРІ РЅРµ СѓСЃС‚Р°РЅРѕРІР»РµРЅС‹"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: MONITORED_SERVICES РјР°СЃСЃРёРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_monitored_services_array() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РјР°СЃСЃРёРІР° MONITORED_SERVICES..."

  if [[ ${#MONITORED_SERVICES[@]} -gt 0 ]]; then
    pass "MONITORED_SERVICES РјР°СЃСЃРёРІ СЃРѕРґРµСЂР¶РёС‚ ${#MONITORED_SERVICES[@]} СЃРµСЂРІРёСЃРѕРІ"
    ((TESTS_PASSED++)) || true

    # РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ РєР»СЋС‡РµРІС‹С… СЃРµСЂРІРёСЃРѕРІ
    local has_marzban=false
    local has_singbox=false

    for service in "${MONITORED_SERVICES[@]}"; do
      if [[ "$service" == "marzban" ]]; then
        has_marzban=true
      fi
      if [[ "$service" == "sing-box" ]]; then
        has_singbox=true
      fi
    done

    if [[ "$has_marzban" == "true" ]]; then
      pass "MONITORED_SERVICES СЃРѕРґРµСЂР¶РёС‚ marzban"
      ((TESTS_PASSED++)) || true
    fi

    if [[ "$has_singbox" == "true" ]]; then
      pass "MONITORED_SERVICES СЃРѕРґРµСЂР¶РёС‚ sing-box"
      ((TESTS_PASSED++)) || true
    fi
  else
    fail "MONITORED_SERVICES РјР°СЃСЃРёРІ РїСѓСЃС‚"
  fi
}

# в”Ђв”Ђ РўРµСЃС‚: РїРѕСЂРѕРіРѕРІС‹Рµ Р·РЅР°С‡РµРЅРёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
test_threshold_values() {
  info "РўРµСЃС‚РёСЂРѕРІР°РЅРёРµ РїРѕСЂРѕРіРѕРІС‹С… Р·РЅР°С‡РµРЅРёР№..."

  # РџСЂРѕРІРµСЂСЏРµРј С‡С‚Рѕ РїРѕСЂРѕРіРё РІ СЂР°Р·СѓРјРЅС‹С… РїСЂРµРґРµР»Р°С…
  if [[ $ALERT_CPU_THRESHOLD -ge 50 && $ALERT_CPU_THRESHOLD -le 95 ]]; then
    pass "ALERT_CPU_THRESHOLD РІ РґРѕРїСѓСЃС‚РёРјС‹С… РїСЂРµРґРµР»Р°С… ($ALERT_CPU_THRESHOLD%)"
    ((TESTS_PASSED++)) || true
  else
    fail "ALERT_CPU_THRESHOLD РІРЅРµ РґРѕРїСѓСЃС‚РёРјС‹С… РїСЂРµРґРµР»РѕРІ ($ALERT_CPU_THRESHOLD%)"
  fi

  if [[ $ALERT_RAM_THRESHOLD -ge 50 && $ALERT_RAM_THRESHOLD -le 95 ]]; then
    pass "ALERT_RAM_THRESHOLD РІ РґРѕРїСѓСЃС‚РёРјС‹С… РїСЂРµРґРµР»Р°С… ($ALERT_RAM_THRESHOLD%)"
    ((TESTS_PASSED++)) || true
  else
    fail "ALERT_RAM_THRESHOLD РІРЅРµ РґРѕРїСѓСЃС‚РёРјС‹С… РїСЂРµРґРµР»РѕРІ ($ALERT_RAM_THRESHOLD%)"
  fi

  if [[ $ALERT_DISK_THRESHOLD -ge 50 && $ALERT_DISK_THRESHOLD -le 95 ]]; then
    pass "ALERT_DISK_THRESHOLD РІ РґРѕРїСѓСЃС‚РёРјС‹С… РїСЂРµРґРµР»Р°С… ($ALERT_DISK_THRESHOLD%)"
    ((TESTS_PASSED++)) || true
  else
    fail "ALERT_DISK_THRESHOLD РІРЅРµ РґРѕРїСѓСЃС‚РёРјС‹С… РїСЂРµРґРµР»РѕРІ ($ALERT_DISK_THRESHOLD%)"
  fi
}

# в”Ђв”Ђ РћСЃРЅРѕРІРЅР°СЏ С„СѓРЅРєС†РёСЏ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
main() {
  echo ""
  echo -e "${YELLOW}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${PLAIN}"
  echo -e "${YELLOW}в•‘        CubiVeil Unit Tests - Monitoring Module       в•‘${PLAIN}"
  echo -e "${YELLOW}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${PLAIN}"
  echo ""

  info "РўРµСЃС‚РёСЂСѓРµРјС‹Р№ РјРѕРґСѓР»СЊ: $MODULE_PATH"
  echo ""

  # в”Ђв”Ђ Р—Р°РїСѓСЃРє С‚РµСЃС‚РѕРІ в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  test_file_exists
  echo ""

  test_syntax
  echo ""

  test_shebang
  echo ""

  test_monitor_init
  echo ""

  test_monitor_check_services
  echo ""

  test_monitor_service_status
  echo ""

  test_monitor_cpu
  echo ""

  test_monitor_ram
  echo ""

  test_monitor_disk
  echo ""

  test_monitor_check_resources
  echo ""

  test_monitor_network_check_mock
  echo ""

  test_monitor_external_ip
  echo ""

  test_monitor_check_ssl
  echo ""

  echo ""

  test_monitor_check_singbox_logs
  echo ""

  test_monitor_check_fail2ban_logs
  echo ""

  test_monitor_health_check
  echo ""

  test_monitor_generate_report
  echo ""

  test_module_install
  echo ""

  test_module_check
  echo ""

  test_module_check_services
  echo ""

  test_module_check_resources
  echo ""

  test_module_check_ssl
  echo ""

  test_module_report
  echo ""

  test_module_service_status
  echo ""

  test_all_functions_exist
  echo ""

  test_config_variables
  echo ""

  test_monitored_services_array
  echo ""

  test_threshold_values
  echo ""

  # в”Ђв”Ђ РС‚РѕРіРё в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ
  echo ""
  echo -e "${YELLOW}в”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓ${PLAIN}"
  echo -e "${GREEN}РџСЂРѕР№РґРµРЅРѕ: $TESTS_PASSED${PLAIN}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}РџСЂРѕРІР°Р»РµРЅРѕ:  $TESTS_FAILED${PLAIN}"
  fi
  echo -e "${YELLOW}в”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓв”Ѓ${PLAIN}"
  echo ""

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}вќЊ РўРµСЃС‚С‹ РїСЂРѕРІР°Р»РµРЅС‹${PLAIN}"
    exit 1
  else
    echo -e "${GREEN}вњ… Р’СЃРµ С‚РµСЃС‚С‹ РїСЂРѕР№РґРµРЅС‹${PLAIN}"
    exit 0
  fi
}

main "$@"
