#!/usr/bin/env python3
"""
Telegram Bot Tests Runner
Run all tests for the Telegram bot modules
"""

import unittest
import sys
import os

# Add telegram-bot directory to path
TEST_DIR = os.path.dirname(__file__)
BOT_DIR = os.path.join(TEST_DIR, '..', '..', 'assets', 'telegram-bot')
sys.path.insert(0, BOT_DIR)

# Test discovery pattern
DISCOVER_PATTERN = "test_*.py"


def run_tests():
    """Run all tests and return results"""
    # Create test suite
    loader = unittest.TestLoader()
    suite = loader.discover(
        start_dir=TEST_DIR,
        pattern=DISCOVER_PATTERN
    )

    # Run tests
    runner = unittest.TextTestRunner(
        verbosity=2,
        failfast=False,
        buffer=True
    )

    result = runner.run(suite)

    # Print summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)
    print(f"Tests run: {result.testsRun}")
    print(f"Failures: {len(result.failures)}")
    print(f"Errors: {len(result.errors)}")
    print(f"Skipped: {len(result.skipped)}")

    if result.wasSuccessful():
        print("\n✅ All tests passed!")
        return 0
    else:
        print("\n❌ Some tests failed!")
        return 1


if __name__ == "__main__":
    sys.exit(run_tests())
