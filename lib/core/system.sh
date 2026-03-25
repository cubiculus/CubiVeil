#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║          CubiVeil — Core System Functions              ║
# ║          github.com/cubiculus/cubiveil                   ║
# ║                                                           ║
# ║  Общие системные функции для всех модулей               ║
# ║  - Управление пакетами (apt)                              ║
# ║  - Управление сервисами (systemctl)                       ║
# ║  - Проверка зависимостей                                 ║
# ╚═══════════════════════════════════════════════════════════╝

# ── Управление пакетами / Package Management ────────────────

# Установка пакета с проверкой
# Использование: pkg_install "package-name"
pkg_install() {
  local package="$1"

  # Проверяем, установлен ли пакет
  if dpkg -l | grep -q "^ii  ${package} "; then
    return 0
  fi

  apt-get install -y -qq "$package" >/dev/null 2>&1
}

# Установка нескольких пакетов
# Использование: pkg_install_packages "package1" "package2" "package3"
pkg_install_packages() {
  local packages=("$@")

  # Фильтруем уже установленные пакеты
  local to_install=()
  for pkg in "${packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  ${pkg} "; then
      to_install+=("$pkg")
    fi
  done

  if [[ ${#to_install[@]} -gt 0 ]]; then
    apt-get install -y -qq "${to_install[@]}" >/dev/null 2>&1
  fi
}

# Проверка установки пакета
# Возвращает 0 если пакет установлен, 1 если нет
pkg_check() {
  local package="$1"
  dpkg -l | grep -q "^ii  ${package} "
}

# Обновление индекса пакетов
pkg_update() {
  apt-get update -qq >/dev/null 2>&1
}

# Обновление установленных пакетов
pkg_upgrade() {
  local DPKG_OPTS='-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold'

  # Отключаем все интерактивные диалоги dpkg/debconf/needrestart
  export DEBIAN_FRONTEND=noninteractive
  export UCF_FORCE_CONFFOLD=1

  # needrestart спрашивает о перезапуске сервисов — переводим в автоматический режим
  if [[ -f /etc/needrestart/needrestart.conf ]]; then
    sed -i "s/#\$nrconf{restart} = 'i'/\$nrconf{restart} = 'a'/" \
      /etc/needrestart/needrestart.conf 2>/dev/null || true
  fi

  # shellcheck disable=SC2086
  apt-get upgrade -y -qq $DPKG_OPTS >/dev/null 2>&1
}

# Полное обновление системы
pkg_full_upgrade() {
  local DPKG_OPTS='-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold'

  export DEBIAN_FRONTEND=noninteractive
  export UCF_FORCE_CONFFOLD=1

  # shellcheck disable=SC2086
  apt-get dist-upgrade -y -qq $DPKG_OPTS >/dev/null 2>&1
}

# Очистка неиспользуемых пакетов
pkg_autoremove() {
  apt-get autoremove -y >/dev/null 2>&1
  apt-get autoclean -y >/dev/null 2>&1
}

# ── Управление сервисами / Service Management ──────────────

# Проверка существования сервиса
# Возвращает 0 если сервис существует, 1 если нет
svc_exists() {
  local service="$1"
  systemctl list-unit-files "${service}" &>/dev/null
}

# Проверка активности сервиса
# Возвращает 0 если сервис активен, 1 если нет
svc_active() {
  local service="$1"
  systemctl is-active --quiet "${service}" 2>/dev/null
}

# Проверка включённости сервиса
# Возвращает 0 если сервис включён, 1 если нет
svc_enabled() {
  local service="$1"
  systemctl is-enabled --quiet "${service}" 2>/dev/null
}

# Включение сервиса
svc_enable() {
  local service="$1"
  systemctl enable "${service}" >/dev/null 2>&1
}

# Запуск сервиса
svc_start() {
  local service="$1"
  systemctl start "${service}" >/dev/null 2>&1
}

# Остановка сервиса
svc_stop() {
  local service="$1"
  systemctl stop "${service}" >/dev/null 2>&1 || true
}

# Перезапуск сервиса
svc_restart() {
  local service="$1"
  systemctl restart "${service}" >/dev/null 2>&1
}

# Перезагрузка конфигурации systemd
svc_daemon_reload() {
  systemctl daemon-reload >/dev/null 2>&1
}

# Включение и запуск сервиса (обычная операция)
svc_enable_start() {
  local service="$1"
  svc_enable "$service"
  svc_start "$service"
}

# Перезапуск сервиса если он активен
svc_restart_if_active() {
  local service="$1"
  if svc_active "$service"; then
    svc_restart "$service"
  fi
}

# Получение статуса сервиса
# Возвращает статус (active, inactive, failed, unknown)
svc_status() {
  local service="$1"
  systemctl is-active "${service}" 2>/dev/null || echo "unknown"
}

# ── Проверка зависимостей / Dependency Checking ───────────

# Проверка команды
# Возвращает 0 если команда доступна, 1 если нет
cmd_check() {
  local cmd="$1"
  command -v "$cmd" &>/dev/null
}

# Требование команды (выходит с ошибкой если нет)
# Использование: cmd_require "curl" "wget" "jq"
cmd_require() {
  local missing=()

  for cmd in "$@"; do
    if ! cmd_check "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    if [[ "${LANG_NAME:-}" == "Русский" ]]; then
      echo "❌ Отсутствуют команды: ${missing[*]}. Установи: apt-get install ${missing[*]}" >&2
    else
      echo "❌ Missing commands: ${missing[*]}. Install: apt-get install ${missing[*]}" >&2
    fi
    return 1
  fi
}

# Проверка зависимости пакета
# Возвращает 0 если пакет установлен, 1 если нет
dep_check() {
  local package="$1"
  pkg_check "$package"
}

# Установка зависимости с выходом при ошибке
# Использование: dep_require "curl" "wget"
dep_require() {
  local missing=()

  for pkg in "$@"; do
    if ! dep_check "$pkg"; then
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    pkg_install_packages "${missing[@]}"
  fi

  # Повторная проверка после установки
  for pkg in "$@"; do
    if ! dep_check "$pkg"; then
      if [[ "${LANG_NAME:-}" == "Русский" ]]; then
        echo "❌ Не удалось установить зависимость: ${pkg}" >&2
      else
        echo "❌ Failed to install dependency: ${pkg}" >&2
      fi
      return 1
    fi
  done
}

# ── Работа с конфигами / Configuration Management ────────

# Создание файла конфигурации из шаблона
# Использование: config_create "/path/to/config.conf" "содержимое"
config_create() {
  local path="$1"
  local content="$2"

  local dir
  dir=$(dirname "$path")

  # Создаём директорию если нужно
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir"
  fi

  echo "$content" > "$path"
}

# Проверка существования конфигурации
# Возвращает 0 если файл существует, 1 если нет
config_exists() {
  local path="$1"
  [[ -f "$path" ]]
}

# Удаление конфигурации
config_remove() {
  local path="$1"
  rm -f "$path" 2>/dev/null || true
}

# ── Пользователи и группы / User & Group Management ───────

# Создание пользователя если не существует
user_create() {
  local username="$1"
  local home_dir="${2:-/home/${username}}"

  if ! id "$username" &>/dev/null; then
    useradd -m -d "$home_dir" -s /bin/bash "$username" 2>/dev/null || true
  fi
}

# Проверка существования пользователя
# Возвращает 0 если пользователь существует, 1 если нет
user_exists() {
  local username="$1"
  id "$username" &>/dev/null
}

# ── Файловая система / Filesystem ─────────────────────────

# Создание директории если не существует
# Использование: dir_ensure "/path/to/directory"
dir_ensure() {
  local path="$1"
  mkdir -p "$path" 2>/dev/null || true
}

# Проверка существования директории
# Возвращает 0 если директория существует, 1 если нет
dir_exists() {
  local path="$1"
  [[ -d "$path" ]]
}

# ── Переменные окружения / Environment Variables ─────────

# Установка переменной окружения в /etc/environment
env_set() {
  local key="$1"
  local value="$2"

  local env_file="/etc/environment"

  # Удаляем существующую переменную если есть
  if grep -q "^${key}=" "$env_file" 2>/dev/null; then
    sed -i "/^${key}=/d" "$env_file"
  fi

  # Добавляем новую переменную
  echo "${key}=\"${value}\"" >> "$env_file"
}

# Получение переменной окружения из /etc/environment
env_get() {
  local key="$1"
  grep "^${key}=" /etc/environment 2>/dev/null | cut -d= -f2- | tr -d '"'
}
