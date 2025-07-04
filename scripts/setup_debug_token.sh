#!/bin/bash

# Firebase App Check Debug Token Setup Script
# This script helps configure App Check debug tokens for development

set -e

echo "🔐 Firebase App Check Debug Token Setup"
echo "========================================"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Please login first:"
    echo "firebase login"
    exit 1
fi

PROJECT_ID="wordnerd-artbeat"
IOS_APP_ID="1:665020451634:ios:2aa5cc17ac7d0dad78652b"
ANDROID_APP_ID="1:665020451634:android:70aaba9b305fa17b78652b"

echo "📱 Project ID: $PROJECT_ID"
echo "📱 iOS App ID: $IOS_APP_ID"
echo "📱 Android App ID: $ANDROID_APP_ID"
echo ""

# Extract debug token from logs if available
if [ -f ".github/buildfail" ]; then
    DEBUG_TOKEN=$(grep -o "App Check debug token: '[^']*'" .github/buildfail | sed "s/App Check debug token: '//;s/'//")
    if [ ! -z "$DEBUG_TOKEN" ]; then
        echo "🔍 Found debug token in logs: $DEBUG_TOKEN"
        echo ""
        echo "📋 To configure this token in Firebase Console:"
        echo "1. Go to https://console.firebase.google.com/project/$PROJECT_ID/settings/appcheck"
        echo "2. Find your iOS app and click 'Manage debug tokens'"
        echo "3. Add this debug token: $DEBUG_TOKEN"
        echo "4. Save the configuration"
        echo ""
    fi
fi

echo "🔧 Manual Steps Required:"
echo "1. Open Firebase Console: https://console.firebase.google.com/project/$PROJECT_ID"
echo "2. Go to Project Settings → App Check"
echo "3. For iOS app, configure debug tokens"
echo "4. For Android app, configure debug tokens"
echo ""

echo "💡 Debug tokens are automatically generated when running the app in debug mode"
echo "💡 Check your console logs for lines containing 'App Check debug token'"

echo ""
echo "✅ Setup script completed. Please follow the manual steps above."