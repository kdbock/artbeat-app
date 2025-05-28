# API Key Management Guide

This guide explains how to properly manage API keys and sensitive information in the WordNerd application, which is hosted in a private repository.

## Environment Variables

The application uses environment variables to securely store and access API keys. These environment variables are loaded at runtime using the `flutter_dotenv` package.

### Setup

1. Create a `.env` file in the root of the project
2. Add your API keys and sensitive information to this file
3. While our repository is private, it's still a good practice to keep the `.env` file in your `.gitignore` to prevent accidental commits in case the repository is ever made public

### Required Environment Variables

The following environment variables are required:

```
# Firebase API Keys
FIREBASE_ANDROID_API_KEY=your_android_api_key_here
FIREBASE_IOS_API_KEY=your_ios_api_key_here

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### Accessing Environment Variables

Environment variables are accessed through the `AppConfig` utility class:

```dart
import 'package:emptytemplate/utils/app_config.dart';

// Get a Firebase API key
String apiKey = AppConfig.firebaseAndroidApiKey;

// Get the Google Maps API key
String mapsApiKey = AppConfig.googleMapsApiKey;
```

## Security Best Practices

1. **Never commit API keys to version control**
   - Ensure `.env` is in your `.gitignore`
   - Use `.env.example` to document required variables without actual values

2. **Restrict API keys in production**
   - Set up API key restrictions in the respective service consoles
   - For Google API keys, restrict by IP, referrer, or application
   - For Firebase, use Firebase App Check to prevent unauthorized usage

3. **Monitor API key usage**
   - Regularly check usage patterns for unusual activity
   - Set up alerts for excessive or unusual usage

4. **Rotate API keys periodically**
   - Establish a process for regular key rotation
   - Update the `.env` file when keys are rotated

## Getting API Keys

### Firebase API Keys
Firebase API keys are automatically generated when you create a Firebase project and add Android/iOS apps to it. Follow the Firebase setup guide in the main README for instructions.

### Google Maps API Key
1. Visit the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the APIs you need (Maps SDK for Android/iOS, Directions API, etc.)
4. Create API keys with appropriate restrictions
5. Add the keys to your `.env` file
