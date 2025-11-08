// This file contains additional Firebase configuration for Apple Sign-In
// These configurations should match your Firebase Console settings

class FirebaseAppleConfig {
  // Apple OAuth Provider Configuration
  static const String appleProviderId = 'apple.com';

  // Your Apple Team ID (from Apple Developer Console)
  static const String appleTeamId = 'H49R32NPY6';

  // Your Apple Services ID (from Apple Developer Console)
  static const String appleServicesId = 'com.wordnerd.artbeat';

  // Your Apple Key ID (from Apple Developer Console)
  static const String appleKeyId = '5G5237Z826';

  // Firebase Project Configuration
  static const String firebaseProjectId = 'wordnerd-artbeat';
  static const String firebaseAuthDomain = 'wordnerd-artbeat.firebaseapp.com';

  // OAuth Callback URL (should match Firebase Auth settings)
  static const String oauthCallbackUrl =
      'https://wordnerd-artbeat.firebaseapp.com/__/auth/handler';

  // Bundle ID (should match your iOS app bundle ID)
  static const String bundleId = 'com.wordnerd.artbeat';
}
