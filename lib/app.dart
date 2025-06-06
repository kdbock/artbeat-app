import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_profile/artbeat_profile.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARTbeat',
      theme: ArtbeatTheme.lightTheme,
      home: const LoadingScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => DashboardScreen(
              screens: [
                // Use our core dashboard components in the correct order
                const DiscoverScreen(), // Home/Discover feed from core
                const ArtWalkMapScreen(), // Art walks
                const CommunityFeedScreen(), // Community
                const ArtworkBrowseScreen(), // Artwork
                ProfileViewScreen(
                    userId: FirebaseAuth.instance.currentUser?.uid ??
                        ''), // Profile
              ],
              onCapturePressed: () => _onCapture(context),
            ),
      },
    );
  }

  void _onCapture(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/capture');
    if (result != null && context.mounted) {
      await Navigator.pushNamed(context, '/artwork/upload',
          arguments: {'file': result});
    }
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final _services = ServiceHandler();
  String _status = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize app services
      setState(() {
        _status = 'Initializing services...';
        _hasError = false;
      });

      // Add a small delay to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      await _services.initializeServices();

      if (!mounted) return;

      // Navigate to appropriate screen
      if (_services.isLoggedIn) {
        debugPrint('✅ User is logged in, navigating to dashboard...');
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        debugPrint('⚠️ User not logged in, navigating to login...');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 24),
              Text(
                'ARTbeat',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Initialization Error',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check debug console for details',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Trigger a hot restart
                    const MethodChannel('flutter/hotRestart')
                        .invokeMethod<void>('hotRestart');
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
