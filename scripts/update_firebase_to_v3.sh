#!/bin/zsh

# Make script exit on first error
set -e

# Function to update Firebase versions in a specific pubspec.yaml file
update_firebase_versions() {
    local file=$1
    sed -i '' \
        -e 's/firebase_core: \^2\.[0-9]\+\.[0-9]\+/firebase_core: ^3.14.0/g' \
        -e 's/firebase_auth: \^4\.[0-9]\+\.[0-9]\+/firebase_auth: ^5.6.0/g' \
        -e 's/firebase_storage: \^11\.[0-9]\+\.[0-9]\+/firebase_storage: ^12.4.7/g' \
        -e 's/firebase_analytics: \^10\.[0-9]\+\.[0-9]\+/firebase_analytics: ^11.5.0/g' \
        -e 's/firebase_messaging: \^14\.[0-9]\+\.[0-9]\+/firebase_messaging: ^15.2.7/g' \
        -e 's/cloud_firestore: \^4\.[0-9]\+\.[0-9]\+/cloud_firestore: ^5.6.9/g' \
        -e 's/firebase_app_check: \^0\.2\.[0-9]\+\.[0-9]\+/firebase_app_check: ^0.3.2+7/g' \
        -e 's/fake_cloud_firestore: \^2\.[0-9]\+\.[0-9]\+/fake_cloud_firestore: ^3.1.0/g' \
        -e 's/firebase_storage_mocks: \^[0-9]\+\.[0-9]\+\.[0-9]\+/firebase_storage_mocks: ^0.6.0+1/g' \
        "$file"
}

echo "Updating Firebase versions to v3.x..."

# Start with core module since others depend on it
echo "Updating artbeat_core..."
update_firebase_versions "packages/artbeat_core/pubspec.yaml"
(cd packages/artbeat_core && flutter pub get)

# Update auth module next
echo "Updating artbeat_auth..."
update_firebase_versions "packages/artbeat_auth/pubspec.yaml"
(cd packages/artbeat_auth && flutter pub get)

# Update other modules in dependency order
modules=(
    "artbeat_messaging"
    "artbeat_admin" 
    "artbeat_artwork"
    "artbeat_artist"
    "artbeat_community"
    "artbeat_settings"
    "artbeat_profile"
    "artbeat_art_walk"
    "artbeat_capture"
)

for module in "${modules[@]}"; do
    if [ -d "packages/$module" ]; then
        echo "Updating $module..."
        update_firebase_versions "packages/$module/pubspec.yaml"
        (cd "packages/$module" && flutter pub get)
    fi
done

# Update main app last
echo "Updating main app..."
update_firebase_versions "pubspec.yaml"
flutter pub get

# Clean and rebuild iOS
echo "Rebuilding iOS..."
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter clean
flutter build ios
