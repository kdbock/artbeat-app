#!/bin/bash

# ARTbeat Ads - Dependency Cleanup Script
# Checks for and removes unused dependencies after legacy component removal

set -e  # Exit on any error

PACKAGE_ROOT="/Users/kristybock/artbeat/packages/artbeat_ads"

echo "🔍 ARTbeat Ads Dependency Cleanup"
echo "=================================="
echo ""

cd "$PACKAGE_ROOT"

echo "📦 Analyzing dependencies..."

# Check if any dependencies are no longer used
echo ""
echo "🔍 Checking for unused dependencies..."

# List of dependencies that might no longer be needed
POTENTIALLY_UNUSED=(
    "flutter_colorpicker"
    "flutter_datetime_picker"
    "flutter_form_builder"
    "form_builder_validators"
)

echo ""
echo "⚠️  Dependencies that might no longer be needed:"
for dep in "${POTENTIALLY_UNUSED[@]}"; do
    if grep -q "$dep" pubspec.yaml; then
        echo "  • $dep (check if still used in simplified system)"
    fi
done

echo ""
echo "🧹 Running flutter clean..."
flutter clean

echo ""
echo "📥 Getting dependencies..."
flutter pub get

echo ""
echo "🔍 Running dependency analysis..."
flutter pub deps

echo ""
echo "⚡ Running static analysis..."
flutter analyze --no-fatal-infos

echo ""
echo "✅ Dependency cleanup complete!"
echo ""
echo "📋 Manual review needed:"
echo "  1. Check pubspec.yaml for unused dependencies"
echo "  2. Remove any dependencies not used by simplified system"
echo "  3. Test that all functionality still works"
echo ""