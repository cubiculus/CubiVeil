#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Step: BBR Optimization                 ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Настройка BBR и оптимизация сетевого стека               ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Подключение зависимостей / Dependencies ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Подключаем core модули
if [[ -f "${SCRIPT_DIR}/lib/core/system.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/system.sh"
fi

if [[ -f "${SCRIPT_DIR}/lib/core/log.sh" ]]; then
  source "${SCRIPT_DIR}/lib/core/log.sh"
fi

# ── Функции / Functions ──────────────────────────────────────

# Загрузка модуля BBR
bbr_load_module() {
  log_step "bbr_load_module" "Loading BBR kernel module"

  modprobe tcp_bbr 2>/dev/null || true
  log_debug "BBR module loaded"
}

# Создание конфигурации sysctl для BBR
bbr_create_sysctl_config() {
  log_step "bbr_create_sysctl_config" "Creating sysctl configuration for BBR"

  cat >/etc/sysctl.d/99-cubiveil.conf <<'EOF'
# CubiVeil — BBR и оптимизация сетевого стека

# BBR снижает задержки и повышает скорость на длинных маршрутах
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Увеличенные буферы для прокси с большим трафиком
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Переиспользование TIME_WAIT соединений
net.ipv4.tcp_tw_reuse = 1

# Лимит файловых дескрипторов
fs.file-max = 1000000
EOF

  log_debug "Created /etc/sysctl.d/99-cubiveil.conf"
}

# Применение настроек sysctl
bbr_apply_sysctl() {
  log_step "bbr_apply_sysctl" "Applying sysctl settings"

  sysctl -p /etc/sysctl.d/99-cubiveil.conf >/dev/null 2>&1 || true
}

# Проверка текущего контроля перегрузки TCP
bbr_check_status() {
  local CURRENT
  CURRENT=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")

  log_info "Current TCP congestion control: ${CURRENT}"
  echo "$CURRENT"
}

# Основная функция шага (вызывается из install-steps.sh)
step_bbr() {
  step_title "4" "BBR и оптимизация сети" "BBR and network optimization"

  bbr_load_module
  bbr_create_sysctl_config
  bbr_apply_sysctl

  local current
  current=$(bbr_check_status)
  ok "TCP congestion control: ${current}"
}

# ── Модульный интерфейс / Module Interface ─────────────────
module_install() { :; }
module_configure() { step_bbr; }
module_enable() { :; }
module_disable() { :; }
