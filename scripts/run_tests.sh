#!/bin/bash
# run_tests.sh
# Reset the test database and run all unit tests.

# Config
RESET_DB_SCRIPT="./scripts/make_test_db.sh"

echo "=== Resetting test database ==="
$RESET_DB_SCRIPT

# Go to backend folder where pubspec.yaml exists
echo "=== Running backend unit tests ==="
cd backend || { echo "Backend folder not found"; exit 1; }
dart test          # or npx jest

# Optional: run frontend tests
echo "=== Running frontend unit tests ==="
cd ../frontend || { echo "Frontend folder not found"; exit 1; }
flutter test --no-pub --reporter=compact

echo "=== All tests finished ==="
