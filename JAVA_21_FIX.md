# Java 21 Setup Fix for Android CI Builds

## Issue
After fixing the `google-services.json` issue, the Android build was still failing with:
```
error: invalid source release: 21
```

This occurred after 26 minutes of build time.

## Root Cause
The Android project's `build.gradle.kts` is configured to use Java 21:
```kotlin
compileOptions {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
}

kotlinOptions {
    jvmTarget = JavaVersion.VERSION_21.toString()
}
```

However, the GitHub Actions runner did not have Java 21 installed, causing the build to fail when compiling Java code.

## Solution
Added Java 21 setup step to the GitHub Actions workflow before the Android build:

```yaml
- name: Setup Java 21 (for Android builds)
  if: matrix.platform == 'android'
  uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '21'
```

This step:
- Only runs for Android builds (`if: matrix.platform == 'android'`)
- Uses the official `actions/setup-java@v4` action
- Installs Temurin JDK 21 (Eclipse Adoptium)
- Runs before the `flutter build apk` command

## Order of Steps (Android Build)
1. ✅ Checkout code
2. ✅ Setup Flutter
3. ✅ Setup Android SDK
4. ✅ **Setup Java 21** ← New step
5. ✅ Create google-services.json from template
6. ✅ Get dependencies
7. ✅ Build APK

## Benefits
- Android builds will now succeed in CI/CD
- Matches local development Java version
- Uses official GitHub Actions for Java setup
- Properly configured for Java 21 features

## Testing
The fix will be validated when the workflow runs on the next push.

## Related Files
- `.github/workflows/comprehensive_tests.yml` - Updated with Java 21 setup
- `android/app/build.gradle.kts` - Requires Java 21

## Commit Message Suggestion
```
fix(ci): Add Java 21 setup for Android builds

- Install Java 21 (Temurin) before Android builds
- Required by build.gradle.kts configuration
- Fixes "invalid source release: 21" error
- Android builds should now complete successfully in CI/CD
```
