#!/bin/bash

# Firebase Crashlytics dSYM Upload Script for ARTbeat
# This script helps upload dSYM files to Firebase Crashlytics

set -e

echo "🔍 Searching for dSYM files..."

# Find dSYM files in common locations
DSYM_PATHS=(
    "$HOME/Library/Developer/Xcode/DerivedData/*/Build/Products/Release-iphoneos/*.app.dSYM"
    "$HOME/Library/Developer/Xcode/DerivedData/*/Build/Products/Release-iphonesimulator/*.app.dSYM"
    "ios/build/Release-iphoneos/*.app.dSYM"
    "build/ios/Release-iphoneos/*.app.dSYM"
    "build/ios/iphoneos/*.app.dSYM"
    "build/ios/Release-iphoneos/Runner.app.dSYM"
)

DSYM_FILES=()

for path in "${DSYM_PATHS[@]}"; do
    if compgen -G "$path" > /dev/null; then
        for file in $path; do
            if [[ -d "$file" ]]; then
                DSYM_FILES+=("$file")
                echo "📁 Found dSYM: $file"
            fi
        done
    fi
done

if [ ${#DSYM_FILES[@]} -eq 0 ]; then
    echo "❌ No dSYM files found. Make sure you've built the iOS app in Release mode."
    echo "   Run: flutter build ios --release"
    exit 1
fi

echo "📦 Found ${#DSYM_FILES[@]} dSYM file(s)"

# Check if Firebase CLI is available
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Install it with: npm install -g firebase-tools"
    exit 1
fi

# Upload each dSYM file
for dsym_file in "${DSYM_FILES[@]}"; do
    echo "⬆️  Uploading dSYM: $(basename "$dsym_file")"

    if firebase crashlytics:symbols:upload \
        --app=1:665020451634:ios:2aa5cc17ac7d0dad78652b \
        "$dsym_file"; then
        echo "✅ Successfully uploaded: $(basename "$dsym_file")"
    else
        echo "❌ Failed to upload: $(basename "$dsym_file")"
        exit 1
    fi
done

echo "🎉 All dSYM files uploaded successfully!"
echo "📊 Crash reports should now be properly symbolicated in Firebase Crashlytics."