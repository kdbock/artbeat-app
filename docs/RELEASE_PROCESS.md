# ARTbeat Release Process

This document outlines the process for creating and publishing new releases of the ARTbeat app.

## Release Naming Convention

ARTbeat uses artistic themes for release names:

- **1.0.0: "Canvas"** - The foundational release (June 2025)
- Future releases will follow artistic themes (e.g., "Palette", "Gallery", "Exhibit", etc.)

## Version Numbering

ARTbeat follows semantic versioning:

- **Major version (X.0.0)**: Significant changes or redesigns
- **Minor version (1.X.0)**: New features and functionality
- **Patch version (1.0.X)**: Bug fixes and minor improvements
- **Build number (+1)**: Increments with each submission to app stores

## Release Preparation Checklist

Before creating a new release:

1. **Code Freeze**:
   - Ensure all targeted features are complete
   - Run all tests and fix any critical bugs
   - Perform code reviews on all new changes

2. **Version Updates**:
   - Update version in `pubspec.yaml`
   - Choose an appropriate release name
   - Document changes in `docs/RELEASE_NOTES.md`
   - Create app store specific notes in `docs/APP_STORE_NOTES.md`

3. **Final Testing**:
   - Test on multiple physical devices (Android and iOS)
   - Verify all core functionality works as expected
   - Check performance and memory usage
   - Review accessibility features

## Creating the Release

Use the release script to build packages for both platforms:

```bash
./scripts/create_release.sh
```

This script will:
1. Clean the build environment
2. Update version information
3. Build release packages for Android and iOS
4. Create a Git tag for the release
5. Organize all release artifacts in `build/releases/[version]-[name]/`

## Release Artifacts

A complete release includes:

- **Android App Bundle (.aab)**: For Play Store submission
- **Android APK (.apk)**: For direct distribution and testing
- **iOS IPA (.ipa)**: For App Store submission
- **Release Notes**: Documentation of changes and features

## Publishing the Release

### Google Play Store

1. Log in to the [Google Play Console](https://play.google.com/console/)
2. Navigate to ARTbeat app > Release > Production
3. Create new release and upload the AAB file
4. Add release notes from `APP_STORE_NOTES.md`
5. Submit for review

### Apple App Store

1. Log in to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to ARTbeat app > App Store > iOS App
3. Create a new version with the current version number
4. Upload the IPA through Xcode or Transporter
5. Add release notes from `APP_STORE_NOTES.md`
6. Submit for review

## Post-Release

After publishing:

1. Push the Git tag to the remote repository
2. Create a release in GitHub with the release notes
3. Update internal documentation
4. Begin planning the next release cycle

## Hotfix Process

For critical issues requiring immediate fixes:

1. Create a hotfix branch from the release tag
2. Fix the issue and increment the patch version (e.g., 1.0.0 → 1.0.1)
3. Follow an expedited version of the standard release process
4. Document the issue and resolution in the release notes

---

Remember to maintain the release signing keystore securely, as it's required for all future Android releases.
