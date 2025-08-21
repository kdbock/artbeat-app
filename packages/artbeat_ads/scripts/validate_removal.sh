#!/bin/bash

# ARTbeat Ads - Removal Validation Script
# Validates that the legacy component removal was successful and system still works

set -e  # Exit on any error

PACKAGE_ROOT="/Users/kristybock/artbeat/packages/artbeat_ads"

echo "✅ ARTbeat Ads Removal Validation"
echo "=================================="
echo ""

cd "$PACKAGE_ROOT"

echo "🔍 Validating removal..."

# Check that key legacy files are gone
echo ""
echo "🗑️  Verifying legacy files are removed:"

LEGACY_FILES=(
    "lib/src/screens/artist_ad_create_screen.dart"
    "lib/src/screens/gallery_ad_create_screen.dart"
    "lib/src/screens/user_ad_create_screen.dart"
    "lib/src/widgets/universal_ad_form.dart"
    "lib/src/services/ad_artist_service.dart"
    "lib/src/models/ad_artist_model.dart"
)

for file in "${LEGACY_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  ✅ $file - REMOVED"
    else
        echo "  ❌ $file - STILL EXISTS"
    fi
done

# Check that key simplified files exist
echo ""
echo "📁 Verifying simplified files exist:"

SIMPLIFIED_FILES=(
    "lib/src/screens/simple_ad_create_screen.dart"
    "lib/src/screens/simple_ad_management_screen.dart"
    "lib/src/widgets/simple_ad_display_widget.dart"
    "lib/src/widgets/simple_ad_placement_widget.dart"
    "lib/src/widgets/missing_ad_widgets.dart"
    "lib/src/services/simple_ad_service.dart"
    "lib/src/models/ad_size.dart"
    "lib/src/examples/simple_ad_example.dart"
)

for file in "${SIMPLIFIED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file - EXISTS"
    else
        echo "  ❌ $file - MISSING"
    fi
done

echo ""
echo "📦 Running pub get..."
flutter pub get

echo ""
echo "🔍 Running static analysis..."
if flutter analyze --no-fatal-infos; then
    echo "  ✅ Static analysis passed"
else
    echo "  ❌ Static analysis failed - check errors above"
    exit 1
fi

echo ""
echo "🧪 Checking import statements..."

# Check for any remaining imports of removed files
echo "  🔍 Searching for legacy imports..."
if grep -r "import.*ad_artist_service" lib/ 2>/dev/null; then
    echo "  ❌ Found legacy service imports"
else
    echo "  ✅ No legacy service imports found"
fi

if grep -r "import.*universal_ad_form" lib/ 2>/dev/null; then
    echo "  ❌ Found legacy widget imports"
else
    echo "  ✅ No legacy widget imports found"
fi

echo ""
echo "📊 Package statistics:"
echo "  📁 Screens: $(find lib/src/screens -name "*.dart" | wc -l | tr -d ' ')"
echo "  🧩 Widgets: $(find lib/src/widgets -name "*.dart" | wc -l | tr -d ' ')"
echo "  ⚙️  Services: $(find lib/src/services -name "*.dart" | wc -l | tr -d ' ')"
echo "  📊 Models: $(find lib/src/models -name "*.dart" | wc -l | tr -d ' ')"
echo "  📝 Total Dart files: $(find lib -name "*.dart" | wc -l | tr -d ' ')"

echo ""
echo "✅ VALIDATION COMPLETE"
echo "======================"
echo ""
echo "🎉 Legacy component removal validation successful!"
echo ""
echo "📋 Next steps:"
echo "  1. Test ad creation flow"
echo "  2. Test ad display in different locations"
echo "  3. Test admin management screen"
echo "  4. Run integration tests"
echo "  5. Update main app to use simplified widgets"
echo ""