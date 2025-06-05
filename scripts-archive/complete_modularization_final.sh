#!/bin/bash
# filepath: /Users/kristybock/artbeat/scripts/complete_modularization_final.sh

echo "===== Starting Final Modularization Process ====="

# Make all scripts executable
chmod +x /Users/kristybock/artbeat/scripts/fix_models.sh
chmod +x /Users/kristybock/artbeat/scripts/fix_fl_chart_issues.sh
chmod +x /Users/kristybock/artbeat/scripts/fix_duplicate_imports.sh
chmod +x /Users/kristybock/artbeat/scripts/fix_routes.sh
chmod +x /Users/kristybock/artbeat/scripts/fix_remaining_imports.sh

# Run scripts in order
echo "1. Fixing models..."
/Users/kristybock/artbeat/scripts/fix_models.sh

echo "2. Fixing FL Chart issues..."
/Users/kristybock/artbeat/scripts/fix_fl_chart_issues.sh

echo "3. Fixing duplicate imports..."
/Users/kristybock/artbeat/scripts/fix_duplicate_imports.sh

echo "4. Fixing remaining imports..."
/Users/kristybock/artbeat/scripts/fix_remaining_imports.sh

echo "5. Fixing routes..."
/Users/kristybock/artbeat/scripts/fix_routes.sh

# Fix ImageModerationService constructor
echo "6. Fixing ImageModerationService constructor..."
sed -i '' 's/Provider(create: (context) => ImageModerationService())/Provider(create: (context) => ImageModerationService(apiKey: '\''assets\/service_account.json'\''))/g' /Users/kristybock/artbeat/lib/main.dart

# Run flutter pub get in each package
echo "7. Running flutter pub get in each package..."
for module in artbeat_core artbeat_auth artbeat_artist artbeat_artwork artbeat_art_walk artbeat_community artbeat_profile artbeat_settings artbeat_calendar artbeat_capture; do
  echo "Running flutter pub get in $module"
  (cd "/Users/kristybock/artbeat/packages/$module" && flutter pub get)
done

# Run flutter pub get in the main app
echo "8. Running flutter pub get in the main app..."
(cd "/Users/kristybock/artbeat" && flutter pub get)

echo "===== Modularization process completed! ====="
echo ""
echo "Next steps:"
echo "1. Run the app to verify everything is working"
echo "2. Test each module individually"
echo "3. Update tests for the new modular architecture"
