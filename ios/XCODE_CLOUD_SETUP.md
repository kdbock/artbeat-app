# Xcode Cloud Build Setup for ARTbeat

This document outlines the setup required to successfully build ARTbeat on Xcode Cloud.

## Overview

ARTbeat is a Flutter application, which requires special handling on Xcode Cloud because Flutter build files must be generated before the Xcode build process begins.

## Build Scripts

Two CI/CD scripts have been created to handle the Flutter build environment:

### 1. `ci_scripts/ci_post_clone.sh`
**When**: Runs immediately after the repository is cloned  
**Purpose**: 
- Installs Flutter if not present on the build system
- Runs `flutter pub get` to download dependencies
- Generates Flutter iOS configuration files
- Runs build_runner to generate code

### 2. `ci_scripts/ci_pre_xcodebuild.sh`
**When**: Runs immediately before the `xcodebuild archive` command  
**Purpose**:
- Verifies Flutter is installed and in PATH
- Checks for `Generated.xcconfig` and other required Flutter files
- Regenerates files if missing
- Ensures all Flutter iOS build artifacts are present

## Required Xcode Cloud Settings

### 1. Environment Variables
No special environment variables are required. Xcode Cloud will automatically set `CI_PRIMARY_REPOSITORY_PATH` which the scripts use.

### 2. Signing and Capabilities
Ensure the following are configured in App Store Connect:

**Team ID**: `H49R32NPY6`  
**Bundle ID**: `com.wordnerd.artbeat`  
**Signing Certificate**: Automatic code signing enabled  

### 3. Build Configuration
- **Scheme**: Runner
- **Archive**: iOS (Generic iOS Device)
- **Export Method**: App Store

## Troubleshooting Build Failures

### Error: "could not find included file 'Generated.xcconfig'"
**Cause**: Flutter files were not generated before the build started  
**Solution**: Verify that `ci_scripts/ci_pre_xcodebuild.sh` ran successfully. Check the build logs for the pre-xcodebuild phase.

### Error: "Unable to load contents of file list"
**Cause**: CocoaPods files are missing or incomplete  
**Solution**: The `ci_post_clone.sh` script should run `pod install --repo-update`. Verify this completed in the logs.

### Error: "Archive failed to generate"
**Cause**: Multiple possible causes - missing dependencies, signing issues, or build configuration problems  
**Solution**: 
1. Check the build logs for specific errors
2. Run a test build locally: `flutter build ios --release`
3. Verify all certificates and provisioning profiles are valid in App Store Connect

## Manual Local Testing

To simulate the Xcode Cloud build locally:

```bash
# Simulate post-clone
cd /path/to/artbeat/ios/ci_scripts
bash ci_post_clone.sh

# Verify setup
bash ci_pre_xcodebuild.sh

# Build archive
cd /path/to/artbeat
flutter build ios --release
```

## Xcode Cloud Workflow Configuration

When setting up the workflow in App Store Connect:

1. **Build Branch**: `main`
2. **Scripts**: 
   - Post-Clone: `ios/ci_scripts/ci_post_clone.sh`
   - Pre-Xcodebuild: `ios/ci_scripts/ci_pre_xcodebuild.sh`
3. **Archive Destination**: App Store
4. **Code Signing**: Automatic

## Key Notes

- **Flutter Version**: The scripts install Flutter from the official repository. The version will be the latest stable release at build time.
- **Build Time**: First builds may take 10-15 minutes due to Flutter dependency resolution and compilation.
- **Caching**: Xcode Cloud caches are used to speed up subsequent builds. Derived data from previous builds is preserved.
- **Parallel Builds**: Only one build can run at a time on the standard tier. Queue subsequent builds if needed.

## Additional Resources

- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode-cloud)
- [Flutter iOS Build Guide](https://flutter.dev/docs/deployment/ios)
- [App Store Connect API Reference](https://developer.apple.com/documentation/appstoreconnectapi)
