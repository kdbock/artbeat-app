#!/bin/bash
# Script to update API keys in platform-specific files
# This should be run after setting up your .env file and before building the app
# Since we're using a private repository, the keys are already secure

# Load environment variables from .env file
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "Warning: .env file not found, continuing with existing keys"
fi

# Check if required environment variables are set
if [ -z "$GOOGLE_MAPS_API_KEY" ] || [ -z "$FIREBASE_ANDROID_API_KEY" ] || [ -z "$FIREBASE_IOS_API_KEY" ]; then
  echo "Error: Required API keys are missing from .env file"
  exit 1
fi

echo "Updating Android and iOS configuration files with API keys..."

# Update Android AndroidManifest.xml with Google Maps API key
if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
  sed -i -e "s|android:value=\"AIzaSyAclolfPruwSH4oQ-keOXkfTPQJT86-dPU\"|android:value=\"$GOOGLE_MAPS_API_KEY\"|g" android/app/src/main/AndroidManifest.xml
  echo "Updated Android manifest with Google Maps API key"
fi

# Update iOS Info.plist with Google Maps API key
if [ -f "ios/Runner/Info.plist" ]; then
  sed -i -e "s|<string>AIzaSyAclolfPruwSH4oQ-keOXkfTPQJT86-dPU</string>|<string>$GOOGLE_MAPS_API_KEY</string>|g" ios/Runner/Info.plist
  echo "Updated iOS Info.plist with Google Maps API key"
fi

# Create temporary google-services.json with updated API key
if [ -f "android/app/google-services.json" ]; then
  sed -i -e "s|\"current_key\": \"AIzaSyD84GjBUiz_XI3ckluibO82uuPQ01u50sQ\"|\"current_key\": \"$FIREBASE_ANDROID_API_KEY\"|g" android/app/google-services.json
  echo "Updated android/app/google-services.json with new Firebase API key"
fi

echo "API key updates complete!"
