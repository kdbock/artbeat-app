#!/bin/bash

# Script to generate mocks for the artbeat_artist module
echo "Generating mocks for artbeat_artist module..."

# Navigate to the artist module directory
cd "$(dirname "$0")/../packages/artbeat_artist" || exit 1

# Clean any previously generated mocks
flutter pub run build_runner clean

# Generate mock files for testing
flutter pub run build_runner build --delete-conflicting-outputs

echo "Mock generation for artist module complete"
