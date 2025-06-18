#!/bin/zsh

echo "Starting complete migration process..."

# Source directories
mkdir -p packages/artbeat_{core,auth,artist,artwork,art_walk,community,profile,settings,calendar,capture}/lib/src/{models,services,screens,widgets}

echo "Step 1: Finalizing module structures..."
./scripts/finalize_modules.sh

echo "Step 2: Updating import statements..."
./scripts/update_imports.sh

echo "Step 3: Creating a modular main.dart file..."
./scripts/create_modular_main.sh

echo "Step 4: Running flutter pub get to update dependencies..."
flutter pub get

echo "Migration completed successfully!"
echo ""
echo "Next steps:"
echo "1. Verify that all files are in the correct locations"
echo "2. Test building and running the app"
echo "3. Fix any remaining import or architecture issues"
echo ""
echo "You can use the following command to build the app:"
echo "flutter build apk --debug # for Android"
echo "flutter build ios --debug # for iOS"