import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';

// Get Firebase configuration from ConfigService
final firebaseConfig = ConfigService.instance.firebaseConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await ConfigService.instance.initialize();
    final config = ConfigService.instance.firebaseConfig;
    // Check if Firebase is already initialized to avoid duplicate initialization
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: config['apiKey'] ?? '',
          appId: config['appId'] ?? '',
          messagingSenderId: config['messagingSenderId'] ?? '',
          projectId: config['projectId'] ?? '',
          storageBucket: config['storageBucket'] ?? '',
        ),
      );
    } else {
      debugPrint('Firebase already initialized, using existing app instance');
    }
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Continue without Firebase when in development mode
    if (!kDebugMode) rethrow;
  }

  runApp(const ArtworkModuleApp());
}

class ArtworkModuleApp extends StatelessWidget {
  const ArtworkModuleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<UserService>(
          create: (_) => UserService(),
        ),
        // Corrected Provider for ArtworkService
        Provider<ArtworkService>(
          create: (_) => ArtworkService(),
        ),
      ],
      child: MaterialApp(
        title: 'ARTbeat Artwork Module',
        theme: ThemeData(
          primarySwatch: Colors.amber,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ArtworkModuleHome(),
      ),
    );
  }
}

class ArtworkModuleHome extends StatelessWidget {
  const ArtworkModuleHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: const EnhancedUniversalHeader(
          title: 'ARTbeat Artwork Module',
          showLogo: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Artwork Module Demo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // Navigation buttons to the artwork screens
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ArtworkBrowseScreen(),
                  ),
                ),
                child: const Text('Browse Artwork'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const EnhancedArtworkUploadScreen(),
                  ),
                ),
                child: const Text('Upload Artwork'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
