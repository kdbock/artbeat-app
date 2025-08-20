#!/usr/bin/env dart
// Script to get App Check debug token for Firebase Console configuration

import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:logging/logging.dart';

Future<void> main() async {
  // Initialize Flutter bindings first
  WidgetsFlutterBinding.ensureInitialized();

  final log = Logger('AppCheckTokenScript');
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Print log messages to the console
    stdout.writeln('[${record.level.name}] ${record.time}: ${record.message}');
  });
  log.info('🔐 Getting App Check Debug Token...\n');

  try {
    // Initialize Firebase with debug mode
    await SecureFirebaseConfig.ensureInitialized(
      teamId: 'H49R32NPY6',
      debug: true,
    );

    log.info('✅ Firebase initialized successfully');

    // Wait a moment for App Check to fully initialize
    await Future<void>.delayed(const Duration(seconds: 2));

    // Get the debug token
    final token = await SecureFirebaseConfig.getAppCheckDebugToken();

    if (token != null) {
      log.info('\n🎉 SUCCESS! Your App Check Debug Token:');
      log.info('=' * 60);
      log.info(token);
      log.info('=' * 60);
      log.info('\n📋 NEXT STEPS:');
      log.info('1. Copy the token above');
      log.info('2. Go to Firebase Console → App Check');
      log.info('3. Click on your app (com.wordnerd.artbeat)');
      log.info('4. Go to "Debug tokens" tab');
      log.info('5. Click "Add debug token"');
      log.info('6. Paste the token and save');
      log.info('7. Update your .env file:');
      log.info('   FIREBASE_APP_CHECK_DEBUG_TOKEN=$token');
    } else {
      log.severe('❌ Failed to get debug token');

      // Try validation
      final validation = await SecureFirebaseConfig.validateAppCheck();
      log.info('\n🔍 App Check Status:');
      validation.forEach((key, value) {
        log.info('  $key: $value');
      });
    }
  } catch (e, stackTrace) {
    final log = Logger('AppCheckTokenScript');
    log.severe('❌ Error: $e');
    log.severe('Stack trace: $stackTrace');
  }

  exit(0);
}
