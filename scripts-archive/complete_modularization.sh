#!/bin/zsh

echo "===== Starting modularization completion process ====="

# Make all scripts executable
chmod +x /Users/kristybock/artbeat/scripts/fix_import_syntax.sh
chmod +x /Users/kristybock/artbeat/scripts/create_firebase_options.sh
chmod +x /Users/kristybock/artbeat/scripts/fix_main_routes.sh
chmod +x /Users/kristybock/artbeat/scripts/fix_data_imports.sh

# Run scripts in order
echo "1. Creating Firebase options..."
/Users/kristybock/artbeat/scripts/create_firebase_options.sh

echo "2. Creating data files and utility classes..."
/Users/kristybock/artbeat/scripts/fix_data_imports.sh

echo "3. Fixing import syntax issues..."
/Users/kristybock/artbeat/scripts/fix_import_syntax.sh

echo "4. Fixing main.dart routes..."
/Users/kristybock/artbeat/scripts/fix_main_routes.sh

echo "5. Running flutter pub get in each package..."
for module in artbeat_core artbeat_auth artbeat_artist artbeat_artwork artbeat_art_walk artbeat_community artbeat_profile artbeat_settings artbeat_calendar artbeat_capture; do
  echo "Running flutter pub get in $module"
  (cd "/Users/kristybock/artbeat/packages/$module" && flutter pub get)
done

echo "6. Running flutter pub get in the main app..."
(cd "/Users/kristybock/artbeat" && flutter pub get)

echo "===== Modularization process completed! ====="
echo ""
echo "Next steps:"
echo "1. Run the app and fix any remaining issues"
echo "2. Test each module individually"
echo "3. Update tests for the new modular architecture"
