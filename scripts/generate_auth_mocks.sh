#!/bin/bash

echo "Generating mocks for artbeat_auth tests..."
cd packages/artbeat_auth
flutter pub run build_runner build --delete-conflicting-outputs
echo "Mock generation completed."
