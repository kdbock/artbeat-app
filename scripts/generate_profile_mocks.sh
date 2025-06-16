#!/bin/bash

# Script to generate mocks for the artbeat_profile module
echo "Generating mocks for artbeat_profile module..."

# Navigate to the profile module directory
cd "$(dirname "$0")/../packages/artbeat_profile" || exit 1

# Clean any previously generated mocks
flutter pub run build_runner clean

# Generate mock files for testing
flutter pub run build_runner build --delete-conflicting-outputs

echo "Mock generation for profile module complete"
