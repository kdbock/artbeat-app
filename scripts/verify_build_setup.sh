#!/bin/bash
# Verify project setup for iOS and Android builds
set -e

echo "============================================="
echo "ARTbeat Flutter App Build Verification Script"
echo "============================================="

echo "Verifying Flutter setup..."
flutter doctor -v

echo "Verifying dependencies..."
flutter pub get

echo "Verifying Android setup..."
cd android && ./gradlew :app:dependencies && cd ..

echo "Verifying package and version consistency..."
grep -r "artbeat" --include="*.xml" --include="*.plist" --include="*.yaml" --include="*.gradle*" .

echo "============================================="
echo "Verification complete"
echo "============================================="
