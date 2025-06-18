import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

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
    await Firebase.initializeApp(
      options: mockFirebaseOptions,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Continue without Firebase when in development mode
    if (!kDebugMode) rethrow;
  }

  runApp(const ArtWalkModuleApp());
}

class ArtWalkModuleApp extends StatelessWidget {
  const ArtWalkModuleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<core.UserService>(
          create: (_) => core.UserService(),
        ),
        // Provider fix: use Provider<ArtWalkService> instead of ChangeNotifierProvider
        Provider<ArtWalkService>(
          create: (_) => ArtWalkService(),
        ),
      ],
      child: MaterialApp(
        title: 'ARTbeat Art Walk Module',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ArtWalkModuleHome(),
      ),
    );
  }
}

class ArtWalkModuleHome extends StatelessWidget {
  const ArtWalkModuleHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARTbeat Art Walk Module'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Art Walk Module Demo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            // Navigation buttons to art walk screens
            ElevatedButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ArtWalkMapScreen(),
                ),
              ),
              child: const Text('Art Walk Map'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ArtWalkListScreen(),
                ),
              ),
              child: const Text('Browse Art Walks'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CreateArtWalkScreen(),
                ),
              ),
              child: const Text('Create Art Walk'),
            ),
          ],
        ),
      ),
    );
  }
}
