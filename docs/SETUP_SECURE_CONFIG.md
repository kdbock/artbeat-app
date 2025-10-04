# 🔐 Secure Configuration Setup

## Quick Start

### 1. Set Up Local Environment

Copy the example environment file and fill in your API keys:

```bash
cp .env.local.example .env.local
```

Edit `.env.local` with your actual values:
```bash
export ENVIRONMENT=development
export GOOGLE_MAPS_API_KEY=AIzaSy...your_key...
export STRIPE_PUBLISHABLE_KEY=pk_test_...your_key...
```

**Important**: Never commit `.env.local` to git!

### 2. Build the App

Use the secure build script:

```bash
# Run in development
./scripts/build_secure.sh run

# Build Android APK
./scripts/build_secure.sh build-apk

# Build iOS
./scripts/build_secure.sh build-ios
```

### 3. Access Configuration in Code

```dart
import 'package:artbeat/config/app_config.dart';

final config = AppConfig();

// Use the keys
final mapsKey = config.googleMapsApiKey;
final stripeKey = config.stripePublishableKey;

// Validate configuration on app start
if (!config.validate()) {
  // Handle missing configuration
}
```

## Manual Build (Without Script)

If you prefer to build manually:

```bash
# Load environment variables
source .env.local

# Run with dart-define flags
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
  --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY \
  --dart-define=ENVIRONMENT=$ENVIRONMENT
```

## CI/CD Configuration

For GitHub Actions, add these secrets to your repository:
- Settings > Secrets and variables > Actions > New repository secret

Required secrets:
- `GOOGLE_MAPS_API_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_SECRET_KEY` (for Cloud Functions)

Then in your workflow:

```yaml
- name: Build
  run: |
    flutter build apk \
      --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }} \
      --dart-define=STRIPE_PUBLISHABLE_KEY=${{ secrets.STRIPE_PUBLISHABLE_KEY }} \
      --dart-define=ENVIRONMENT=production
```

## Getting API Keys

### Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new API key or use existing
3. **Important**: Restrict the key to your app's package name
4. Enable required APIs: Maps SDK for Android/iOS

### Stripe Keys
1. Go to [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. Copy your publishable key
3. Use `pk_test_*` for development
4. Use `pk_live_*` for production
5. **Never** use secret keys (`sk_*`) in the mobile app!

### Firebase Configuration
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/google-services.json`
3. Download `GoogleService-Info.plist` from Firebase Console
4. Add to iOS project in Xcode

These files are gitignored and must be set up on each development machine.

## Troubleshooting

### "Configuration not set" errors

If you see validation errors:
1. Verify `.env.local` exists and has correct values
2. Run with the build script: `./scripts/build_secure.sh run`
3. Check that you're using `source .env.local` before manual builds

### Build fails with "GOOGLE_MAPS_API_KEY not found"

The app is not receiving the environment variables. Make sure to:
1. Use `--dart-define` flags
2. Or use the provided `build_secure.sh` script

## Security Notes

✅ **Safe to commit:**
- `.env.local.example`
- `.env.example`
- `.env.production` (if it only contains placeholders)
- `lib/config/app_config.dart`

❌ **Never commit:**
- `.env.local` (your actual keys)
- `.env` (if it contains real values)
- `google-services.json`
- `GoogleService-Info.plist`
- Any file with real API keys or secrets

## Further Reading

- [Complete Security Guide](./docs/SECURITY_CONFIGURATION.md)
- [Security Incident Report](./docs/SECURITY_INCIDENT_2025_10_03.md)
- [Flutter Environment Variables](https://flutter.dev/docs/deployment/flavors)
