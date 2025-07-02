# Release Signing Guide for ARTbeat

## Current Signing Configuration

ARTbeat now uses a proper release signing configuration for Android builds. This ensures that the app can be uploaded to the Play Store and installed on user devices.

## Keystore Details

- **Location**: `android/app/signing/artbeat-upload-key.jks`
- **Key Alias**: `upload`
- **Store Password**: See `android/key.properties` (keep secure)
- **Key Password**: See `android/key.properties` (keep secure)
- **Validity**: 10,000 days (27 years) from creation date

## How to Build Signed Releases

### Android

To build a signed Android release, use one of the following methods:

**Method 1**: Use the build script:
```bash
./scripts/build_playstore_release.sh
```

**Method 2**: Run Flutter command directly:
```bash
flutter build appbundle --release
```

The signed app bundle will be available at:
```
build/app/outputs/bundle/release/app-release.aab
```

### iOS

For iOS, make sure to use the proper provisioning profiles:
```bash
./scripts/build_ios.sh
```

## Verifying the Signature

To verify that an APK is properly signed with the release key:
```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

## Play Store Requirements

When uploading to the Play Store:
1. Always use the same signing key for updates
2. Use the app bundle (.aab) format for upload
3. Keep the keystore file and passwords secure

## Important Security Notes

- Keep the keystore file secure - loss means you cannot update the app
- Keep the key.properties file out of version control
- The keystore file is required for all future app updates

## If You Need to Create a New Keystore

If you need to create a new keystore (not recommended unless the current one is compromised):

1. Create a new keystore:
```bash
keytool -genkey -v -keystore android/app/signing/new-key.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass YOUR_PASSWORD -keypass YOUR_PASSWORD -dname "CN=Word Nerd, OU=ARTbeat, O=Word Nerd LLC, L=Charlotte, S=North Carolina, C=US"
```

2. Update `android/key.properties` with new details
3. Note that you'll need to upload the app as a new listing on Play Store if you change the signing key

## Troubleshooting

If you encounter signing issues:
1. Verify the keystore path in `key.properties` matches the actual file location
2. Check that the passwords and alias in `key.properties` match the keystore
3. Run `./scripts/check_signing_config.sh` to validate the configuration
