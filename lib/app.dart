import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'widgets/developer_menu.dart';

class MyApp extends StatelessWidget {
  final navigatorKey = GlobalKey<NavigatorState>();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers with proper types
        ChangeNotifierProvider<core.UserService>(
          create: (_) => core.UserService(),
          lazy: false,
        ),
        Provider<core.NotificationService>(
          create: (_) => core.NotificationService(),
          lazy: false,
        ),
        ChangeNotifierProvider<core.ConnectivityService>(
          create: (_) => core.ConnectivityService(),
          lazy: false,
        ),
        Provider<core.PaymentService>(
          create: (_) => core.PaymentService(),
          lazy: false,
        ),

        // Theme setup
        Provider<ThemeData>(
          create: (_) => core.ArtbeatTheme.lightTheme,
          lazy: false,
        ),

        // Auth service
        Provider<AuthService>(
          create: (_) => AuthService(),
          lazy: false,
        ),

        // Message services
        ChangeNotifierProvider<messaging.ChatService>(
          create: (_) => messaging.ChatService(),
        ),
        ProxyProvider<messaging.ChatService, messaging.ChatController>(
          create: (context) => messaging.ChatController(
            context.read<messaging.ChatService>(),
          ),
          update: (context, chatService, previous) =>
              previous ?? messaging.ChatController(chatService),
        ),
      ],
      child: Builder(
        builder: (context) {
          final theme = Provider.of<ThemeData>(context);

          return MaterialApp(
            title: 'ARTbeat',
            theme: theme,
            navigatorKey: navigatorKey,
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: child,
              );
            },
            home: const LoadingScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/dashboard': (context) => core.DashboardScreen(
                    screens: [
                      const DiscoverScreen(),
                      const ArtWalkMapScreen(),
                      const CommunityFeedScreen(),
                      // TODO: Calendar screen temporarily disabled
                    ],
                    onCapturePressed: () => _onCapture(context),
                  ),
              '/capture': (context) => const CaptureScreen(),
              '/artwork/upload': (context) {
                final args = ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
                final file = args['file'] as File;
                return artwork.ArtworkUploadScreen(imageFile: file);
              },
              '/artwork/browse': (context) =>
                  const artist.ArtworkBrowseScreen(),
            },
          );
        },
      ),
    );
  }

  Future<void> _onCapture(BuildContext context) async {
    Navigator.pushNamed(context, '/capture');
  }
}

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: child,
      endDrawer: const DeveloperMenu(),
      appBar: AppBar(
        leading: canPop ? const BackButton() : null,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.developer_mode),
              onPressed: () {
                final scaffold = Scaffold.of(context);
                scaffold.openEndDrawer();
              },
              tooltip: 'Developer Menu',
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final core.UserService _userService = core.UserService();
  String _status = 'Initializing...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      setState(() {
        _status = 'Initializing services...';
        _hasError = false;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final user = _userService.currentUser;
      if (user != null) {
        debugPrint('✅ User is logged in, navigating to dashboard...');
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        debugPrint('⚠️ User not logged in, navigating to login...');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Error: $e';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_hasError)
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(_status,
                  style: TextStyle(
                      color: _hasError
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface)),
              if (_hasError)
                TextButton(
                  onPressed: _initialize,
                  child: const Text('Retry'),
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
