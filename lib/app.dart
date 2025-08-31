import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_capture/artbeat_capture.dart' as capture;

import 'src/widgets/error_boundary.dart';
import 'src/services/firebase_initializer.dart';
import 'src/routing/app_router.dart';

class MyApp extends StatelessWidget {
  final navigatorKey = GlobalKey<NavigatorState>();
  final _firebaseInitializer = FirebaseInitializer();
  final _appRouter = AppRouter();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firebaseInitializer.ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error initializing app: ${snapshot.error}'),
              ),
            ),
          );
        }

        return ErrorBoundary(
          onError: (error, stackTrace) {
            debugPrint('❌ App-level error caught: $error');
            debugPrint('❌ Stack trace: $stackTrace');
          },
          child: MultiProvider(
            providers: [
              // Core providers
              ChangeNotifierProvider<core.UserService>(
                create: (_) => core.UserService(),
                lazy: true, // Changed to lazy to prevent early Firebase access
              ),
              Provider<AuthService>(create: (_) => AuthService(), lazy: true),
              ChangeNotifierProvider<core.ConnectivityService>(
                create: (_) => core.ConnectivityService(),
                lazy: false,
              ),
              Provider<ThemeData>(
                create: (_) => core.ArtbeatTheme.lightTheme,
                lazy: false,
              ),
              ChangeNotifierProvider<messaging.ChatService>(
                create: (_) => messaging.ChatService(),
                lazy: true, // Changed to lazy to prevent early Firebase access
              ),
              ChangeNotifierProvider<core.MessagingProvider>(
                create: (context) => core.MessagingProvider(
                  context.read<messaging.ChatService>(),
                ),
                lazy: true,
              ),
              // Presence Service for online status
              Provider<messaging.PresenceService>(
                create: (_) => messaging.PresenceService(),
                lazy: false, // Start immediately to track presence
              ),
              // Presence Provider for UI components
              ChangeNotifierProvider<messaging.PresenceProvider>(
                create: (context) => messaging.PresenceProvider(
                  context.read<messaging.PresenceService>(),
                ),
                lazy: false,
              ),
              // Community providers
              ChangeNotifierProvider<CommunityService>(
                create: (_) => CommunityService(),
                lazy: true, // Changed to lazy to prevent early Firebase access
              ),
              ChangeNotifierProvider<core.CommunityProvider>(
                create: (_) => core.CommunityProvider(),
                lazy: true,
              ),
              // Additional service providers for DashboardViewModel
              Provider<events.EventService>(
                create: (_) => events.EventService(),
                lazy: true,
              ),
              Provider<ArtworkService>(
                create: (_) => ArtworkService(),
                lazy: true,
              ),
              Provider<ArtWalkService>(
                create: (_) => ArtWalkService(),
                lazy: true,
              ),
              Provider<capture.CaptureService>(
                create: (_) => capture.CaptureService(),
                lazy: true,
              ),
              ChangeNotifierProvider<core.SubscriptionService>(
                create: (_) => core.SubscriptionService(),
                lazy: true,
              ),
              // Dashboard ViewModel - Create after required services
              ChangeNotifierProxyProvider6<
                events.EventService,
                ArtworkService,
                ArtWalkService,
                core.SubscriptionService,
                core.UserService,
                capture.CaptureService,
                core.DashboardViewModel
              >(
                create: (_) => core.DashboardViewModel(
                  eventService: events.EventService(),
                  artworkService: ArtworkService(),
                  artWalkService: ArtWalkService(),
                  subscriptionService: core.SubscriptionService(),
                  userService: core.UserService(),
                  captureService: capture.CaptureService(),
                ),
                update:
                    (
                      _,
                      events.EventService eventService,
                      ArtworkService artworkService,
                      ArtWalkService artWalkService,
                      core.SubscriptionService subscriptionService,
                      core.UserService userService,
                      capture.CaptureService captureService,
                      previous,
                    ) =>
                        previous ??
                        core.DashboardViewModel(
                          eventService: eventService,
                          artworkService: artworkService,
                          artWalkService: artWalkService,
                          subscriptionService: subscriptionService,
                          userService: userService,
                          captureService: captureService,
                        ),
              ),
            ],
            child: MaterialApp(
              navigatorKey: navigatorKey,
              title: 'ARTbeat',
              theme: core.ArtbeatTheme.lightTheme,
              initialRoute: '/splash',
              onGenerateRoute: _appRouter.onGenerateRoute,
              debugShowCheckedModeBanner: false, // Added for cleaner UI
            ),
          ),
        );
      },
    );
  }
}
