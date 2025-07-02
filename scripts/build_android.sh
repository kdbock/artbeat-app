#!/bin/bash
# Build the app without minification for development/debugging
echo "Building APK without minification for debugging..."
flutter build apk --debug --no-shrink

# Normal release build with our ProGuard rules
echo "Building release bundle with ProGuard rules..."
flutter build appbundle --release
