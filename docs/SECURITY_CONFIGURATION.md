# Security Configuration Guide

## 🔐 Secure Configuration Management

This guide explains how to properly manage API keys, secrets, and sensitive configuration in the ArtBeat app.

## ⚠️ CRITICAL: What NOT to Do

**NEVER** commit these to version control:

- Private keys or certificates
- API secret keys (Stripe secret keys, OAuth secrets)
- Service account credentials
- Production API keys
- `.env` files with real values
- `google-services.json` / `GoogleService-Info.plist`
- Keystore files with real signing keys

## ✅ Secure Configuration Methods

### 1. Build-Time Configuration (Recommended)

Use Flutter's `--dart-define` flags to inject secrets at build time:

```bash
# Development build
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy... \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_... \
  --dart-define=ENVIRONMENT=development

# Production build
flutter build apk \
  --dart-define=GOOGLE_MAPS_API_KEY=AIzaSy... \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_... \
  --dart-define=ENVIRONMENT=production
```

Access these in code via `AppConfig`:

```dart
import 'package:artbeat/config/app_config.dart';

final config = AppConfig();
final mapsKey = config.googleMapsApiKey;
final stripeKey = config.stripePublishableKey;
```

### 2. CI/CD Pipeline Configuration

#### GitHub Actions

Store secrets in GitHub repository settings (Settings > Secrets and variables > Actions):

```yaml
- name: Build APK
  run: |
    flutter build apk \
      --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }} \
      --dart-define=STRIPE_PUBLISHABLE_KEY=${{ secrets.STRIPE_PUBLISHABLE_KEY }}
```

#### Environment Variables File (Local Development)

Create a `.env.local` file (gitignored) for local development:

```bash
# .env.local (DO NOT COMMIT)
export GOOGLE_MAPS_API_KEY=AIzaSy...
export STRIPE_PUBLISHABLE_KEY=pk_test_...
```

Load it before building:

```bash
source .env.local
flutter run \
  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
  --dart-define=STRIPE_PUBLISHABLE_KEY=$STRIPE_PUBLISHABLE_KEY
```

## 🔑 API Key Management

### Google Maps API Key

1. **Restriction Required**: In Google Cloud Console, restrict the key to your app's package name
2. **Separate Keys**: Use different keys for Android, iOS, and Web
3. **Daily Limits**: Set daily quotas to prevent abuse

### Stripe Keys

1. **Test vs Live**: Use `pk_test_*` for development, `pk_live_*` for production
2. **Publishable Only**: NEVER put secret keys (`sk_*`) in client code
3. **Secret Keys**: Only use secret keys in Firebase Cloud Functions or backend

### Firebase Configuration

1. **google-services.json**: Download from Firebase Console, keep gitignored
2. **GoogleService-Info.plist**: Download from Firebase Console, keep gitignored
3. **API Keys**: Restrict in Firebase Console to your app's bundle ID/package name

## 🛡️ Security Best Practices

### Service Accounts

- Service account credentials should ONLY exist on backend servers
- Use Firebase Admin SDK in Cloud Functions, not in mobile app
- If you need Google Play verification, use Cloud Functions as a proxy

### Key Rotation

When rotating keys:

1. Generate new key in service console
2. Update in CI/CD secrets and local `.env.local`
3. Deploy new version with updated keys
4. Wait for users to update
5. Revoke old key

### Git History Cleanup

If you accidentally committed secrets:

```bash
# Install git-filter-repo
brew install git-filter-repo

# Remove file from all history
git filter-repo --path path/to/secret/file --invert-paths

# Force push (coordinate with team first!)
git push origin --force --all
```

Then **immediately revoke and regenerate** the exposed credentials.

## 📋 Required Keys Inventory

| Key Type           | Where to Get         | Where to Store                    | Client/Server |
| ------------------ | -------------------- | --------------------------------- | ------------- |
| Google Maps API    | Google Cloud Console | --dart-define                     | Client        |
| Stripe Publishable | Stripe Dashboard     | --dart-define                     | Client        |
| Stripe Secret      | Stripe Dashboard     | Cloud Functions Secret Manager    | Server Only   |
| Firebase Config    | Firebase Console     | google-services.json (gitignored) | Client        |
| Service Account    | Google Cloud Console | Cloud Functions/Backend only      | Server Only   |
| App Store Secret   | App Store Connect    | Cloud Functions Secret Manager    | Server Only   |

## 🚀 Deployment Checklist

Before deploying to production:

- [ ] All API keys are properly restricted
- [ ] No hardcoded secrets in source code
- [ ] `.gitignore` includes all sensitive file patterns
- [ ] CI/CD secrets are configured
- [ ] Using production keys (not test keys)
- [ ] Service account credentials are only on backend
- [ ] Key rotation procedure documented
- [ ] Team knows how to access keys securely

## 🆘 If Keys Are Exposed

1. **Immediately revoke** the exposed key
2. **Generate new key** in the service console
3. **Update all deployments** with new key
4. **Remove from git history** if committed
5. **Review access logs** for unauthorized usage
6. **Document the incident** for future reference

## 📞 Key Management Contacts

- **Google Cloud Console**: https://console.cloud.google.com
- **Firebase Console**: https://console.firebase.google.com
- **Stripe Dashboard**: https://dashboard.stripe.com
- **App Store Connect**: https://appstoreconnect.apple.com
- **Play Console**: https://play.google.com/console

---

**Remember**: Security is a continuous process, not a one-time setup. Review this guide regularly and update as needed.
