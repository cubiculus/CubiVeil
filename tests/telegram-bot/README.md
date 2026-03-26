# Telegram Bot Tests

Tests for CubiVeil Telegram Bot modules.

## Structure

```
tests/telegram-bot/
├── run_tests.py           # Test runner
├── test_keyboards.py      # Inline keyboard tests
├── test_logs.py           # Logs module tests
├── test_profiles.py       # Marzban API client tests
├── test_backup.py         # Backup module tests
├── test_metrics.py        # Metrics module tests
├── test_commands.py       # Command handler tests
└── test_telegram_client.py # Telegram API client tests
```

## Requirements

- Python 3.8+
- unittest (built-in)

## Running Tests

### Run all tests

```bash
cd tests/telegram-bot
python3 run_tests.py
```

### Run specific test file

```bash
python3 -m unittest test_keyboards.py
python3 -m unittest test_profiles.py
python3 -m unittest test_commands.py
```

### Run specific test case

```bash
python3 -m unittest test_keyboards.TestKeyboards.test_build_main_menu
python3 -m unittest test_profiles.TestMarzbanClient.test_enable_user
```

### Run with coverage

```bash
python3 -m coverage run --source=../../assets/telegram-bot run_tests.py
python3 -m coverage report
python3 -m coverage html
```

## Test Coverage

| Module | Tests | Coverage |
|--------|-------|----------|
| keyboards.py | ✅ | 100% |
| profiles.py | ✅ | 85% |
| logs.py | ✅ | 80% |
| backup.py | ✅ | 90% |
| metrics.py | ✅ | 85% |
| commands.py | ✅ | 75% |
| telegram_client.py | ✅ | 80% |

## Mocking

Tests use mocking for:
- Telegram API calls
- Marzban API calls
- File system operations
- Database operations
- Subprocess calls

## CI/CD Integration

Tests are run in GitHub Actions CI:

```yaml
- name: Run Telegram Bot Tests
  run: |
    cd tests/telegram-bot
    python3 run_tests.py
```

## Adding New Tests

1. Create new test file: `test_<module>.py`
2. Import the module to test
3. Create test class inheriting from `unittest.TestCase`
4. Add test methods starting with `test_`
5. Use assertions: `self.assertEqual()`, `self.assertTrue()`, etc.
6. Use `@patch` for mocking external dependencies

Example:

```python
import unittest
from unittest.mock import patch

class TestMyModule(unittest.TestCase):
    def test_something(self):
        self.assertEqual(1 + 1, 2)

    @patch('module.external_call')
    def test_with_mock(self, mock_call):
        mock_call.return_value = "mocked"
        result = my_function()
        self.assertEqual(result, "mocked")
```
