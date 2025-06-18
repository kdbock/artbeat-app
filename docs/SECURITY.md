# Security Guidelines for API Keys

This document outlines the security measures implemented to protect API keys and sensitive information in the ARTbeat application.

## Recent Security Changes (May 21, 2025)

In response to a security notice, we have:

1. Implemented environment variable-based configuration for API key management
2. Created a secure API key management system that works with our private repository
3. Added a script to update platform-specific configuration files
4. Updated documentation on proper API key management
5. Clarified that our repository is private, providing an additional layer of security

## How API Keys Are Managed

1. **Environment Variables**: All API keys are stored in a `.env` file that is NOT committed to version control
2. **Secure Access**: Keys are accessed through the `AppConfig` utility class
3. **Fallback Values**: Development environments use placeholder values
4. **Platform Files**: A script updates necessary platform configuration files with keys from the environment

## Setting Up API Keys

1. Create a `.env` file in the project root based on `.env.example`
2. Add your API keys to the file:
   ```
   FIREBASE_ANDROID_API_KEY=your_android_api_key_here
   FIREBASE_IOS_API_KEY=your_ios_api_key_here
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   ```
3. Run the update script: `./scripts/update_api_keys.sh`
4. Build or run the app as usual

## API Key Security Best Practices

### Google Maps API Key Security
1. **Restrict API Keys**: In the Google Cloud Console, add restrictions to your Maps API key:
   - For Android, restrict by application with your package name and SHA-1
   - For iOS, restrict by bundle ID
   - For web usage, restrict by HTTP referrer or IP address

### Firebase API Key Security
1. **App Check**: Enable Firebase App Check in the Firebase Console
2. **Authentication Rules**: Ensure proper Firebase Rules are in place
3. **Monitor Usage**: Regularly check usage patterns in the Google Cloud Console

## When to Regenerate Keys

API keys should be regenerated when:
1. A key is exposed publicly
2. Unusual activity is detected
3. Team members with access to keys leave the project
4. As part of regular security rotation (every 6-12 months)

## How to Regenerate API Keys

### Google Maps API Key
1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to "APIs & Services" > "Credentials"
3. Find your API key and click "Regenerate Key"
4. Add appropriate restrictions
5. Update your `.env` file with the new key
6. Run `./scripts/update_api_keys.sh`

### Firebase API Keys
1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings > General
4. Scroll to "Your apps" section
5. For Android/iOS apps, you'll need to download new configuration files
6. Update your `.env` file with the new keys
7. Run `./scripts/update_api_keys.sh`

## Continuous Integration/Deployment

For CI/CD pipelines, store API keys as secure environment variables and inject them during the build process.
