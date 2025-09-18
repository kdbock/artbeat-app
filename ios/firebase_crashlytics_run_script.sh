# Firebase Crashlytics Build Phase Script
# Add this as a "Run Script" build phase in Xcode (after "Embed Frameworks")

if [[ "${CONFIGURATION}" == "Release" ]]; then
    echo "🔥 Firebase Crashlytics: Processing dSYMs for release build"

    # Path to Firebase Crashlytics run script
    CRASHLYTICS_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/run"

    if [[ -f "$CRASHLYTICS_SCRIPT" ]]; then
        echo "📤 Uploading dSYMs via Firebase Crashlytics script"
        "$CRASHLYTICS_SCRIPT"
        echo "✅ dSYM upload completed"
    else
        echo "⚠️  Firebase Crashlytics script not found at: $CRASHLYTICS_SCRIPT"
        echo "   Make sure Firebase/Crashlytics pod is properly installed"
    fi
else
    echo "⏭️  Skipping Firebase Crashlytics dSYM upload (not a Release build)"
fi