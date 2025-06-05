#!/bin/zsh

echo "Starting import syntax fixes..."

# Function to fix incorrect import statements
fix_imports() {
  # Fix imports with missing space between package paths
  find /Users/kristybock/artbeat/packages -name "*.dart" -type f -exec grep -l "artbeat_core/artbeat_core.dart'" {} \; | while read -r file; do
    echo "Fixing imports in $file"
    sed -i '' "s|'package:artbeat_core/artbeat_core.dart'\\([a-zA-Z_]*\\).dart'|'package:artbeat_core/artbeat_core.dart'\n\nimport 'package:artbeat_core/src/utils/\\1.dart'|g" "$file"
  done
  
  # Fix missing dependencies by updating package pubspecs
  echo "Adding missing dependencies to packages..."
  
  # Fix artbeat_core pubspec
  echo "Updating artbeat_core dependencies..."
  if ! grep -q "flutter_local_notifications:" "/Users/kristybock/artbeat/packages/artbeat_core/pubspec.yaml"; then
    sed -i '' '/dependencies:/a\\
  flutter_local_notifications: ^14.0.0+1\
  connectivity_plus: ^4.0.2' "/Users/kristybock/artbeat/packages/artbeat_core/pubspec.yaml"
  fi
  
  # Fix artbeat_artwork pubspec
  echo "Updating artbeat_artwork dependencies..."
  if ! grep -q "pointycastle:" "/Users/kristybock/artbeat/packages/artbeat_artwork/pubspec.yaml"; then
    sed -i '' '/dependencies:/a\\
  pointycastle: ^3.7.3\
  asn1lib: ^1.5.0' "/Users/kristybock/artbeat/packages/artbeat_artwork/pubspec.yaml"
  fi
  
  # Fix artbeat_artist pubspec
  echo "Updating artbeat_artist dependencies..."
  if ! grep -q "url_launcher:" "/Users/kristybock/artbeat/packages/artbeat_artist/pubspec.yaml"; then
    sed -i '' '/dependencies:/a\\
  url_launcher: ^6.2.1\
  fl_chart: ^0.63.0' "/Users/kristybock/artbeat/packages/artbeat_artist/pubspec.yaml"
  fi
  
  # Fix artbeat_art_walk pubspec
  echo "Updating artbeat_art_walk dependencies..."
  if ! grep -q "share_plus:" "/Users/kristybock/artbeat/packages/artbeat_art_walk/pubspec.yaml"; then
    sed -i '' '/dependencies:/a\\
  share_plus: ^7.2.1' "/Users/kristybock/artbeat/packages/artbeat_art_walk/pubspec.yaml"
  fi
  
  # Fix artbeat_calendar pubspec
  echo "Updating artbeat_calendar dependencies..."
  if ! grep -q "table_calendar:" "/Users/kristybock/artbeat/packages/artbeat_calendar/pubspec.yaml"; then
    sed -i '' '/dependencies:/a\\
  table_calendar: ^3.0.9' "/Users/kristybock/artbeat/packages/artbeat_calendar/pubspec.yaml"
  fi
}

# Run the fixes
fix_imports

# Run flutter pub get in each package
echo "Running flutter pub get in each package..."
for module in artbeat_core artbeat_auth artbeat_artist artbeat_artwork artbeat_art_walk artbeat_community artbeat_profile artbeat_settings artbeat_calendar artbeat_capture; do
  echo "Running flutter pub get in $module"
  (cd "/Users/kristybock/artbeat/packages/$module" && flutter pub get)
done

# Run flutter pub get in the main app
echo "Running flutter pub get in the main app..."
(cd "/Users/kristybock/artbeat" && flutter pub get)

echo "Import fixes completed!"
