// filepath: /Users/kristybock/updated_artbeat_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase securely
    await SecureFirebaseConfig.initializeFirebase();

    debugPrint('Firebase initialized successfully');
    runApp(MyApp());
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Failed to initialize app: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
