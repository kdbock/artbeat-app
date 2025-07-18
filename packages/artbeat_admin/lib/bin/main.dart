// filepath: packages/artbeat_admin/lib/bin/main.dart
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// You can replace this with actual Firebase options for development
const mockFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
  appId: '1:665020451634:android:70aaba9b305fa17b78652b',
  messagingSenderId: '665020451634',
  projectId: 'wordnerd-artbeat',
  storageBucket: 'wordnerd-artbeat.appspot.com',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    // Check if Firebase is already initialized to avoid duplicate initialization
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
      options: mockFirebaseOptions,
    );
    } else {
      debugPrint('Firebase already initialized, using existing app instance');
    }
    debugPrint('Firebase initialized successfully');

    // Connect to Firebase emulators if requested
    if (const bool.fromEnvironment('USE_FIREBASE_EMULATOR',
        defaultValue: false)) {
      const String host = 'localhost';
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('Connected to Firebase emulators');
    }
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Continue without Firebase when in development mode
    if (!kDebugMode) rethrow;
  }

  runApp(const UadminModuleApp());
}

class UadminModuleApp extends StatelessWidget {
  const UadminModuleApp({Key? key}) : super(key: key);

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
        title: 'ARTbeat Uadmin Module',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const UadminModuleHome(),
      ),
    );
  }
}

class UadminModuleHome extends StatelessWidget {
  const UadminModuleHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARTbeat Uadmin Module'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Uadmin Module Demo',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('Standalone development environment',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            const SizedBox(height: 30),
            // Add navigation buttons to module screens here
            const Text(
                'Edit this file to add navigation buttons to module screens',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Example Button'),
            ),
          ],
        ),
      ),
    );
  }
}
