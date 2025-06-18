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
        // Core providers
        ChangeNotifierProvider<core.UserService>(
          create: (_) => core.UserService(),
          lazy: false,
        ),
        Provider<AuthService>(create: (_) => AuthService(), lazy: false),
        ChangeNotifierProvider<core.ConnectivityService>(
          create: (_) => core.ConnectivityService(),
          lazy: false,
        ),

        // Theme setup
        Provider<ThemeData>(
          create: (_) => core.ArtbeatTheme.lightTheme,
          lazy: false,
        ),

        // Auth service
        Provider<AuthService>(create: (_) => AuthService(), lazy: false),

        // Message services
        ChangeNotifierProvider<messaging.ChatService>(
          create: (_) => messaging.ChatService(),
        ),
        ProxyProvider<messaging.ChatService, messaging.ChatController>(
          create: (context) =>
              messaging.ChatController(context.read<messaging.ChatService>()),
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
            initialRoute: '/splash',
            routes: {
              '/': (context) => const core.SplashScreen(),
              '/splash': (context) => const core.SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/dashboard': (context) => const core.DashboardScreen(),
              '/capture': (context) => const CaptureScreen(),
              '/artwork/upload': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments
                        as Map<String, dynamic>;
                final file = args['file'] as File;
                return artwork.ArtworkUploadScreen(imageFile: file);
              },
              '/chat': (context) => const messaging.ChatListScreen(),
              '/chat/new': (context) =>
                  const messaging.ContactSelectionScreen(),
            },
          );
        },
      ),
    );
  }

  void _onCapture(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/capture');
    if (result != null && context.mounted) {
      await Navigator.pushNamed(
        context,
        '/artwork/upload',
        arguments: {'file': result},
      );
    }
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
                    const MethodChannel(
                      'flutter/hotRestart',
                    ).invokeMethod<void>('hotRestart');
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
