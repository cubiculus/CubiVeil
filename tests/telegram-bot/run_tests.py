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
        buffer=False  # Disabled to avoid stdout corruption in CI
    )

    result = runner.run(suite)

    # Determine exit code before any I/O that might fail
    success = result.wasSuccessful()

    # Print summary (handle CI stdout closure gracefully)
    try:
        print("\n" + "=" * 70)
        print("TEST SUMMARY")
        print("=" * 70)
        print(f"Tests run: {result.testsRun}")
        print(f"Failures: {len(result.failures)}")
        print(f"Errors: {len(result.errors)}")
        print(f"Skipped: {len(result.skipped)}")

        if success:
            print("\n✅ All tests passed!")
        else:
            print("\n❌ Some tests failed!")
    except OSError:
        # stdout may be closed in CI environments
        pass

    return 0 if success else 1


if __name__ == "__main__":
    exit_code = run_tests()
    # Use os._exit() to bypass interpreter shutdown
    # This prevents OSError from corrupted stdout during cleanup
    os._exit(exit_code)
