// Copyright (c) 2025 ArtBeat. All rights reserved.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await ConfigService.instance.initialize();

    if (Firebase.apps.isEmpty) {
      await SecureFirebaseConfig.configureAppCheck(
        teamId: 'H49R32NPY6',
        debug: kDebugMode,
      );
      await SecureFirebaseConfig.initializeFirebase();
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    } else {
      rethrow;
    }
  }

  runApp(MyApp());
}
