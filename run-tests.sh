#!/bin/bash
# ╔═══════════════════════════════════════════════════════════╗
# ║        CubiVeil Test Runner                               ║
# ║        Запуск интеграционных тестов                       ║
# ╚═══════════════════════════════════════════════════════════╝

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(dirname "$SCRIPT_DIR")/tests"

echo "CubiVeil Test Runner"
echo "===================="
echo ""

# Проверка что запускаем от root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Требуется запуск от root (sudo)"
    echo ""
    echo "Использование:"
    echo "  sudo ./run-tests.sh"
    exit 1
fi

# Проверка что тесты существуют
if [[ ! -f "$TESTS_DIR/integration-tests.sh" ]]; then
    echo "❌ Файл тестов не найден: $TESTS_DIR/integration-tests.sh"
    exit 1
fi

# Запуск тестов
echo "Запуск интеграционных тестов..."
echo ""
bash "$TESTS_DIR/integration-tests.sh"
