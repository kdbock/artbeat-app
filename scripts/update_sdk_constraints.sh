#!/bin/zsh

# Function to update SDK constraints in a file
update_sdk_constraints() {
  local file=$1
  
  # Use sed to replace the SDK constraint line
  sed -i '' \
    -e 's/sdk: ">=3\.0\.0 <4\.0\.0"/sdk: ">=3.8.0 <4.0.0"/' \
    -e 's/sdk: ">=2\.17\.0 <3\.0\.0"/sdk: ">=3.8.0 <4.0.0"/' \
    -e 's/sdk: \^3\.7\.2/sdk: ">=3.8.0 <4.0.0"/' \
    -e 's/flutter: ">=3\.10\.0"/flutter: ">=3.32.0"/' \
    "$file"
}

echo "Updating SDK constraints in all modules..."

# Update constraints in all pubspec.yaml files in packages directory
for module in packages/*/; do
  if [ -f "${module}pubspec.yaml" ]; then
    echo "Processing ${module}pubspec.yaml"
    update_sdk_constraints "${module}pubspec.yaml"
  fi
done

echo "SDK constraints updated successfully!"
