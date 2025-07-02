#!/bin/zsh

# Function to update Firebase versions in a file
update_firebase_versions() {
  local file=$1
  
  # Use sed to replace the versions, being more specific with the patterns
  sed -i '' \
    -e 's/firebase_core:.*$/firebase_core: ^3.14.0/' \
    -e 's/firebase_auth:.*$/firebase_auth: ^5.6.0/' \
    -e 's/cloud_firestore:.*$/cloud_firestore: ^5.6.9/' \
    -e 's/firebase_storage:.*$/firebase_storage: ^12.4.7/' \
    -e 's/firebase_analytics:.*$/firebase_analytics: ^11.5.0/' \
    -e 's/firebase_app_check:.*$/firebase_app_check: ^0.3.2+7/' \
    -e 's/firebase_messaging:.*$/firebase_messaging: ^15.2.7/' \
    "$file"
}

echo "Updating Firebase versions in all modules..."

# Update versions in all pubspec.yaml files in packages directory
for module in packages/*/; do
  if [ -f "${module}pubspec.yaml" ]; then
    echo "Processing ${module}pubspec.yaml"
    update_firebase_versions "${module}pubspec.yaml"
  fi
done

echo "Firebase versions updated successfully!"
