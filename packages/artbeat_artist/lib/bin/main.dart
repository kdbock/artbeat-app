// filepath: packages/artbeat_artist/lib/bin/main.dart
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_artist/src/screens/screens.dart';
import 'package:artbeat_artwork/src/screens/artwork_browse_screen.dart';

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

  runApp(const ArtistModuleApp());
}

class ArtistModuleApp extends StatelessWidget {
  const ArtistModuleApp({Key? key}) : super(key: key);

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
        title: 'ARTbeat Artist Module',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: true,
        ),
        home: const ArtistModuleHome(),
      ),
    );
  }
}

class ArtistModuleHome extends StatelessWidget {
  const ArtistModuleHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARTbeat Artist Module'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Artist Module Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Standalone development environment',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Main Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Artist Dashboard',
              'View your artist profile dashboard with analytics and artwork management',
              Icons.dashboard,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const ArtistDashboardScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              'Browse Artists',
              'Discover other artists on the platform',
              Icons.people,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const ArtistBrowseScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              'Artwork Browser',
              'Browse artwork by various artists',
              Icons.image,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const ArtworkBrowseScreen()),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Subscription Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Modern Onboarding',
              'Modern 2025 artist onboarding experience',
              Icons.card_membership,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const Modern2025OnboardingScreen()),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Gallery Features',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Gallery Analytics Dashboard',
              'View your gallery business analytics',
              Icons.analytics,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const GalleryAnalyticsDashboardScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              'Artist Management',
              'Manage artists in your gallery',
              Icons.group_work,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const GalleryArtistsManagementScreen()),
              ),
            ),
            _buildFeatureCard(
              context,
              'Event Creation',
              'Create and manage gallery events',
              Icons.event,
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => const EventCreationScreen()),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
