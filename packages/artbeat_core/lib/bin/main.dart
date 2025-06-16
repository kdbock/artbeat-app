// filepath: packages/artbeat_core/lib/bin/main.dart
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added import
import 'package:firebase_auth/firebase_auth.dart'; // Added import
import 'package:firebase_storage/firebase_storage.dart'; // Added import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:artbeat_core/src/screens/example_settings_screen.dart';
import 'package:artbeat_core/src/screens/example_user_profile_screen.dart';
import 'package:artbeat_core/src/screens/example_notifications_screen.dart';
import 'package:artbeat_core/src/screens/example_splash_screen.dart';
import 'package:artbeat_core/src/screens/example_loading_screen.dart';
import 'package:artbeat_core/src/screens/example_dashboard_screen.dart';
import 'package:artbeat_core/src/services/config_service.dart';

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
        const bool.fromEnvironment('USE_FIREBASE_EMULATOR',
            defaultValue: false)) {
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
  const CoreModuleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<UserService>(
          create: (_) => UserService(),
        ),
        // Add module-specific providers here
      ],
      child: MaterialApp(
        title: 'ARTbeat Ucore Module',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const UcoreModuleHome(),
      ),
    );
  }
}

class UcoreModuleHome extends StatelessWidget {
  const UcoreModuleHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARTbeat Core Module Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Core Module Demo Screens',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text(
                  'Use these screens to test core functionalities like theming, services, and models.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExampleSplashScreen()),
                  );
                },
                child: const Text('Splash Screen Demo'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExampleLoadingScreen()),
                  );
                },
                child: const Text('Loading Screen Demo'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExampleDashboardScreen()),
                  );
                },
                child: const Text('Dashboard Demo (with Home Tab)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExampleUserProfileScreen()),
                  );
                },
                child: const Text('User Profile Demo'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExampleSettingsScreen()),
                  );
                },
                child: const Text('Settings Demo'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExampleNotificationsScreen()),
                  );
                },
                child: const Text('Notifications Demo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
