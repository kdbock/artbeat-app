#!/bin/bash

# ARTbeat Release Builder
# This script prepares and builds release versions for both Android and iOS platforms

RELEASE_NAME="Canvas"
VERSION="1.0.0"
BUILD_NUMBER="1"
RELEASE_DATE=$(date +"%Y-%m-%d")

echo "========================================="
echo "🎨 ARTbeat Release Builder"
echo "========================================="
echo "Release: $RELEASE_NAME"
echo "Version: $VERSION+$BUILD_NUMBER"
echo "Date: $RELEASE_DATE"
echo "========================================="

# Create release directory
RELEASE_DIR="build/releases/$VERSION-$RELEASE_NAME"
mkdir -p "$RELEASE_DIR"

# Clean build directory
echo "Cleaning build directory..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build Android release
echo "Building Android release..."
flutter build appbundle --release

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
  cp build/app/outputs/bundle/release/app-release.aab "$RELEASE_DIR/ARTbeat-$VERSION-$BUILD_NUMBER.aab"
  echo "✅ Android App Bundle saved to $RELEASE_DIR/ARTbeat-$VERSION-$BUILD_NUMBER.aab"
  
  # Build APK for testing
  flutter build apk --release
  if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    cp build/app/outputs/flutter-apk/app-release.apk "$RELEASE_DIR/ARTbeat-$VERSION-$BUILD_NUMBER.apk"
    echo "✅ Android APK saved to $RELEASE_DIR/ARTbeat-$VERSION-$BUILD_NUMBER.apk"
  fi
else
  echo "❌ Android build failed!"
fi

# Ask if we should build iOS
read -p "Do you want to build for iOS? (y/n) " BUILD_IOS
if [[ $BUILD_IOS == "y" || $BUILD_IOS == "Y" ]]; then
  echo "Building iOS release..."
  flutter build ipa --release
  
  if [ -d "build/ios/archive/Runner.xcarchive" ]; then
    # Copy IPA if it exists
    if [ -f "build/ios/ipa/ARTbeat.ipa" ]; then
      cp build/ios/ipa/ARTbeat.ipa "$RELEASE_DIR/ARTbeat-$VERSION-$BUILD_NUMBER.ipa"
      echo "✅ iOS IPA saved to $RELEASE_DIR/ARTbeat-$VERSION-$BUILD_NUMBER.ipa"
    fi
  else
    echo "❌ iOS build failed or archive not found!"
  fi
else
  echo "Skipping iOS build."
fi

# Copy release notes to release directory
echo "Copying release notes..."
cp docs/RELEASE_NOTES.md "$RELEASE_DIR/"
cp docs/APP_STORE_NOTES.md "$RELEASE_DIR/"

echo "========================================="
echo "✅ Release build complete!"
echo "Release files available in: $RELEASE_DIR"
echo "========================================="

# Ask if we should create a Git tag for this release
read -p "Create Git tag for v$VERSION? (y/n) " CREATE_TAG
if [[ $CREATE_TAG == "y" || $CREATE_TAG == "Y" ]]; then
  git tag -a "v$VERSION" -m "Release $RELEASE_NAME (v$VERSION)"
  echo "✅ Git tag v$VERSION created. Use 'git push origin v$VERSION' to push to remote."
fi
