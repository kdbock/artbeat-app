#!/bin/bash
# Script to remove redundant test files and fix compatibility issues
# Created: June 15, 2025

echo "Cleaning up redundant test files..."

# Remove redundant subscription service test files
echo "Removing redundant subscription service test files..."
rm -f /Users/kristybock/artbeat/packages/artbeat_artist/test/services/testable_subscription_service_test.dart
rm -f /Users/kristybock/artbeat/packages/artbeat_artist/test/services/testable_subscription_service_test_fixed.dart

# Remove redundant chat service test file
echo "Removing redundant chat service test file..."
rm -f /Users/kristybock/artbeat/packages/artbeat_messaging/test/services/testable_chat_service_test.dart

# Create backup of art walk service test before fixing
echo "Creating backup of art walk service test before fixing..."
cp /Users/kristybock/artbeat/packages/artbeat_art_walk/test/services/testable_art_walk_service_test.dart /Users/kristybock/artbeat/packages/artbeat_art_walk/test/services/testable_art_walk_service_test.dart.bak

echo "Clean up complete! Now fixing type compatibility issues..."
