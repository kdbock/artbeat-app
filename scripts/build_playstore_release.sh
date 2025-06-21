#!/bin/bash

echo "========================================="
echo "ARTbeat Play Store Release Build Script"
echo "========================================="

# Make sure the directory exists
mkdir -p build/outputs

# Clean the build folder to ensure a fresh build
echo "Cleaning build directory..."
flutter clean

# Get dependencies 
echo "Getting dependencies..."
flutter pub get

# Build release app bundle for Play Store with release signing
echo "Building app bundle for Play Store with release signing..."
flutter build appbundle --release --verbose

# Verify the bundle was created
echo "========================================="
if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
  echo "✅ Release bundle created successfully!"
  echo "Bundle location: build/app/outputs/bundle/release/app-release.aab"
  
  # Copy to a more accessible location
  cp build/app/outputs/bundle/release/app-release.aab build/outputs/ARTbeat-release.aab
  echo "Bundle copied to: build/outputs/ARTbeat-release.aab"
else
  echo "❌ Failed to create release bundle!"
fi
echo "========================================="
