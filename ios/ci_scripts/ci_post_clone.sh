#!/bin/bash

# Post-Clone Script for Xcode Cloud
# This script runs after the repository is cloned and prepares the Flutter environment

set -e

echo "Starting Flutter setup for Xcode Cloud build..."

# Change to the project root directory
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter if not present
if ! command -v flutter &> /dev/null; then
    echo "Flutter not found. Installing Flutter..."
    git clone https://github.com/flutter/flutter.git ~/flutter --depth 1
    export PATH="$PATH:$HOME/flutter/bin"
    flutter precache --ios
fi

# Ensure flutter is in PATH
export PATH="$PATH:$HOME/flutter/bin"

# Get dependencies
echo "Running flutter pub get..."
flutter pub get

# Generate iOS build files
echo "Generating iOS build files..."
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub run build_runner build --release || true

# Generate Flutter iOS configuration
echo "Generating Flutter iOS configuration..."
flutter build ios --release --no-pub --analyze-size 2>&1 | head -100 || true

echo "Post-clone setup complete!"
