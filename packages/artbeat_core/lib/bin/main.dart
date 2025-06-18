// filepath: packages/artbeat_core/lib/bin/main.dart
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ConfigService first
  await ConfigService.instance.initialize();

  // Initialize Firebase with secure configuration
  try {
    final config = ConfigService.instance.firebaseConfig;

    final options = FirebaseOptions(
      apiKey: config['apiKey'] ?? '',
      appId: config['appId'] ?? '',
      messagingSenderId: config['messagingSenderId'] ?? '',
      projectId: config['projectId'] ?? '',
      storageBucket: config['storageBucket'] ?? '',
    );

    await Firebase.initializeApp(options: options);
    debugPrint('Firebase initialized successfully with secure configuration');

    if (kDebugMode &&
        const bool.fromEnvironment(
          'USE_FIREBASE_EMULATOR',
          defaultValue: false,
        )) {
      const String host = 'localhost';
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('Connected to Firebase emulators');
    }
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    if (!kDebugMode) rethrow;
  }

  runApp(const CoreModuleApp());
}

class CoreModuleApp extends StatelessWidget {
  const CoreModuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARTbeat Core Module',
      theme: ArtbeatTheme.lightTheme,
      darkTheme: ArtbeatTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const CoreModuleHome(),
    );
  }
}

class CoreModuleHome extends StatelessWidget {
  const CoreModuleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ARTbeat Core Module')),
      body: const Center(child: Text('Core Module Example')),
    );
  }
}
