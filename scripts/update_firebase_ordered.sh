#!/bin/zsh

# Make script exit on first error
set -e

# Function to update Firebase versions in a specific pubspec.yaml file
update_firebase_versions() {
    local file=$1
    sed -i '' \
        -e 's/firebase_core: \^3\.[0-9]\+\.[0-9]\+/firebase_core: ^3.14.0/g' \
        -e 's/firebase_auth: \^5\.[0-9]\+\.[0-9]\+/firebase_auth: ^4.16.0/g' \
        -e 's/firebase_storage: \^12\.[0-9]\+\.[0-9]\+/firebase_storage: ^11.6.0/g' \
        -e 's/firebase_analytics: \^11\.[0-9]\+\.[0-9]\+/firebase_analytics: ^10.8.0/g' \
        -e 's/firebase_messaging: \^15\.[0-9]\+\.[0-9]\+/firebase_messaging: ^14.7.10/g' \
        -e 's/cloud_firestore: \^5\.[0-9]\+\.[0-9]\+/cloud_firestore: ^4.14.0/g' \
        -e 's/firebase_app_check: \^0\.3\.[0-9]\+\.[0-9]\+/firebase_app_check: ^0.2.1+8/g' \
        -e 's/fake_cloud_firestore: \^[0-9]\+\.[0-9]\+\.[0-9]\+/fake_cloud_firestore: ^2.4.1/g' \
        -e 's/firebase_storage_mocks: \^[0-9]\+\.[0-9]\+\.[0-9]\+/firebase_storage_mocks: ^0.6.0/g' \
        "$file"
}

# Update core module first
echo "Updating artbeat_core..."
update_firebase_versions "packages/artbeat_core/pubspec.yaml"
(cd packages/artbeat_core && flutter pub get)

# Update authentication module
echo "Updating artbeat_auth..."
update_firebase_versions "packages/artbeat_auth/pubspec.yaml"
(cd packages/artbeat_auth && flutter pub get)

# Update other modules in order
all_modules=("artbeat_messaging" "artbeat_admin" "artbeat_artwork" "artbeat_artist" "artbeat_community" "artbeat_settings" "artbeat_profile" "artbeat_art_walk" "artbeat_capture")

for module in "${all_modules[@]}";

for module in "${all_modules[@]}"; do
    if [ -d "packages/$module" ]; then
        echo "Updating $module..."
        update_firebase_versions "packages/$module/pubspec.yaml"
        (cd "packages/$module" && flutter pub get || true)
    fi
done

# Update main app
echo "Updating main app..."
update_firebase_versions "pubspec.yaml"
flutter pub get

# Clean and rebuild iOS
echo "Rebuilding iOS..."
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter build ios
