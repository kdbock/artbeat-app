#!/bin/zsh

# Create a temporary file with the new versions
cat << EOF > /tmp/firebase_versions.txt
  firebase_core: ^3.14.0
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  firebase_analytics: ^10.7.4
  firebase_app_check: ^0.2.1+8
  firebase_messaging: ^14.7.9
EOF

# Function to update Firebase versions in a file
update_firebase_versions() {
  local file=$1
  while IFS=: read -r package version; do
    # Remove leading/trailing whitespace
    package=$(echo "$package" | xargs)
    version=$(echo "$version" | xargs)
    
    # Use sed to replace version numbers, being careful with the pattern
    # The pattern looks for the package name followed by any version number
    sed -i '' -E "s/$package: [^[:space:]]+/$package: $version/" "$file"
  done < /tmp/firebase_versions.txt
}

# Update all pubspec.yaml files in packages directory
echo "Updating Firebase versions in all modules..."
for module in packages/*/; do
  if [ -f "${module}pubspec.yaml" ]; then
    echo "Processing ${module}pubspec.yaml"
    update_firebase_versions "${module}pubspec.yaml"
  fi
done

# Clean up
rm /tmp/firebase_versions.txt

echo "Firebase versions updated successfully!"
