#!/bin/bash

echo "Generating mocks for artbeat_core tests..."
cd packages/artbeat_core
flutter pub run build_runner build --delete-conflicting-outputs
echo "Mock generation completed."
