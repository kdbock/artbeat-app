#!/bin/bash

echo "========================================="
echo "ARTbeat Android Production Build Script"
echo "========================================="

# Clean the build folder to ensure a fresh build
echo "Cleaning build directory..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build release APK with special handling for Stripe SDK
echo "Building release APK with Stripe workaround..."
flutter build apk --release --no-shrink

# Build app bundle for Play Store with Stripe workaround
echo "Building app bundle for Play Store..."
flutter build appbundle --release --no-shrink

echo "========================================="
echo "Build complete! Check the output files:"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "Bundle: build/app/outputs/bundle/release/app-release.aab"
echo "========================================="
