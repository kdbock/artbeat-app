# API Key Quick Start Guide

This guide provides quick instructions for working with API keys in the ARTbeat application.

## For New Developers

1. **No Setup Needed**: Since we're using a private repository, you can run the app immediately without any API key configuration.

2. **Optional Environment Setup**:
   - Copy `.env.example` to `.env`
   - You can use the original API keys already in the repository
   - Run the app with `flutter run`

3. **How It Works**:
   - The app first tries to load API keys from environment variables
   - If not found, it automatically falls back to the original keys
   - All API access is handled through secure service classes

## Accessing API Keys in Code

Always use these methods to access API keys:

```dart
// For Firebase API keys
final androidKey = AppConfig.firebaseAndroidApiKey;
final iosKey = AppConfig.firebaseIosApiKey;

// For Google Maps API key
final mapsKey = AppConfig.googleMapsApiKey;
```

## Troubleshooting

If you encounter API key issues:

1. Check if you have a `.env` file with valid keys
2. Try removing the `.env` file to force fallback to original keys
3. Check the logs for any API key related warnings
4. Make sure you're using the AppConfig getters and not hardcoding keys

## Adding New API Keys

To add a new API key:

1. Add it to the `.env` file with a descriptive name
2. Add it to the `.env.example` file
3. Add a getter method in the `AppConfig` class
4. Consider adding a fallback for private repository use

## Questions?

Refer to these documents for more details:
- `PRIVATE_REPO_API_SECURITY.md` - Security approach for private repositories
- `API_KEY_MANAGEMENT.md` - General API key management guidelines
- `SECURITY.md` - Overall security guidelines
- `API_IMPLEMENTATION_SUMMARY.md` - Technical implementation details
