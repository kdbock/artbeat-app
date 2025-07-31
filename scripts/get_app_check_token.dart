#!/usr/bin/env dart
// Script to get App Check debug token for Firebase Console configuration

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';

Future<void> main() async {
  print('🔐 Getting App Check Debug Token...\n');

  try {
    // Initialize Firebase with debug mode
    await SecureFirebaseConfig.ensureInitialized(
      teamId: 'H49R32NPY6',
      debug: true,
    );

    print('✅ Firebase initialized successfully');

    // Wait a moment for App Check to fully initialize
    await Future.delayed(const Duration(seconds: 2));

    // Get the debug token
    final token = await SecureFirebaseConfig.getAppCheckDebugToken();

    if (token != null) {
      print('\n🎉 SUCCESS! Your App Check Debug Token:');
      print('=' * 60);
      print(token);
      print('=' * 60);
      print('\n📋 NEXT STEPS:');
      print('1. Copy the token above');
      print('2. Go to Firebase Console → App Check');
      print('3. Click on your app (com.wordnerd.artbeat)');
      print('4. Go to "Debug tokens" tab');
      print('5. Click "Add debug token"');
      print('6. Paste the token and save');
      print('7. Update your .env file:');
      print('   FIREBASE_APP_CHECK_DEBUG_TOKEN=$token');
    } else {
      print('❌ Failed to get debug token');

      // Try validation
      final validation = await SecureFirebaseConfig.validateAppCheck();
      print('\n🔍 App Check Status:');
      validation.forEach((key, value) {
        print('  $key: $value');
      });
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }

  exit(0);
}
