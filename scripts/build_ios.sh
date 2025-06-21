#!/bin/bash

echo "========================================="
echo "ARTbeat iOS Build Script"
echo "========================================="

# Clean the build folder to ensure a fresh build
echo "Cleaning build directory..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build for iOS in release mode
echo "Building iOS app..."
flutter build ios --release --no-codesign

echo "========================================="
echo "iOS build complete!"
echo "Open the Xcode workspace to archive and distribute:"
echo "open ios/Runner.xcworkspace"
echo "========================================="
