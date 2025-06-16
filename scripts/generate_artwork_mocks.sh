#!/bin/bash

# Script to generate mocks for the artbeat_artwork module
echo "Generating mocks for artbeat_artwork module..."

# Navigate to the artwork module directory
cd "$(dirname "$0")/../packages/artbeat_artwork" || exit 1

# Clean any previously generated mocks
flutter pub run build_runner clean

# Generate mock files for testing
flutter pub run build_runner build --delete-conflicting-outputs

echo "Mock generation for artwork module complete"
