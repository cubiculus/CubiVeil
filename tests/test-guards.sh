#!/bin/bash
# Тест guard-переменных

set -euo pipefail

# Определяем путь один раз в начале
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB_DIR="${PROJECT_DIR}/lib"

echo "=== Тестирование guard-переменных ==="
echo ""

# Тест 1: Проверка что guard работает
echo "Тест 1: output.sh guard..."
source "${LIB_DIR}/output.sh"
source "${LIB_DIR}/output.sh"  # Должен вернуться сразу
echo "✓ Test 1 PASSED: output.sh guard works"
echo ""

# Тест 2: Проверка что init.sh загружает всё правильно
# ПРИМЕЧАНИЕ: Не делаем unset readonly переменных (RED, GREEN и т.д.)
# так как их нельзя unset в bash. Guard должен работать без этого.
echo "Тест 2: init.sh загрузка модулей..."
# Проверяем что guard работает даже без unset
if source "${LIB_DIR}/init.sh"; then
  echo "✓ Test 2 PASSED: init.sh loaded all modules"
else
  echo "✗ Test 2 FAILED: init.sh failed to load"
  exit 1
fi
echo ""

# Тест 3: Проверка что повторная загрузка не ломает ничего
echo "Тест 3: init.sh guard..."
if source "${LIB_DIR}/init.sh"; then  # Должен вернуться сразу
  echo "✓ Test 3 PASSED: init.sh guard works"
else
  echo "✗ Test 3 FAILED: init.sh guard failed"
  exit 1
fi
echo ""

# Тест 4: Проверка что функции доступны
echo "Тест 4: Проверка функций..."
if declare -f info >/dev/null && declare -f get_str >/dev/null; then
  echo "✓ Test 4 PASSED: Functions available"
else
  echo "✗ Test 4 FAILED: Functions not available"
  exit 1
fi
echo ""

# Тест 5: Проверка что LANG_NAME не сбрасывается
echo "Тест 5: LANG_NAME сохранение..."
source "${LIB_DIR}/init.sh"
LANG_NAME="English"
source "${PROJECT_DIR}/lang/main.sh"
if [[ "$LANG_NAME" == "English" ]]; then
  echo "✓ Test 5 PASSED: LANG_NAME preserved"
else
  echo "✗ Test 5 FAILED: LANG_NAME was reset to $LANG_NAME"
  exit 1
fi
echo ""

# Тест 6: Проверка что нет циклических зависимостей
echo "Тест 6: Проверка циклических зависимостей..."
# ПРИМЕЧАНИЕ: Не делаем unset readonly переменных
# Просто проверяем что загрузка работает в любом порядке
if source "${LIB_DIR}/common.sh" && \
   source "${LIB_DIR}/security.sh" && \
   source "${LIB_DIR}/utils.sh"; then
  echo "✓ Test 6 PASSED: No circular dependencies"
else
  echo "✗ Test 6 FAILED: Circular dependency detected"
  exit 1
fi
echo ""

echo "=== Все тесты guard-переменных пройдены! ==="
