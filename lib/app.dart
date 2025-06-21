import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_settings/artbeat_settings.dart';
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
        Provider<ThemeData>(
          create: (_) => core.ArtbeatTheme.lightTheme,
          lazy: false,
        ),
        Provider<AuthService>(create: (_) => AuthService(), lazy: false),
        ChangeNotifierProvider<messaging.ChatService>(
          create: (_) => messaging.ChatService(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'ARTbeat',
        theme: core.ArtbeatTheme.lightTheme,
        initialRoute: '/splash',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            // Core routes
            case '/splash':
              return MaterialPageRoute(
                builder: (_) => const core.SplashScreen(),
              );

            // Auth routes
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginScreen());
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterScreen());
            case '/forgot-password':
              return MaterialPageRoute(
                builder: (_) => const ForgotPasswordScreen(),
              );

            // Profile routes
            case '/profile':
              return MaterialPageRoute(
                builder: (_) => ProfileViewScreen(
                  userId: core.UserService().currentUser?.uid ?? '',
                ),
              );
            case '/profile/public':
              return MaterialPageRoute(
                builder: (_) => ProfileViewScreen(
                  userId: core.UserService().currentUser?.uid ?? '',
                ),
              );
            case '/profile/edit':
              return MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  userId: core.UserService().currentUser?.uid ?? '',
                ),
              );
            case '/favorites':
              return MaterialPageRoute(
                builder: (_) => FavoritesScreen(
                  userId: core.UserService().currentUser?.uid ?? '',
                ),
              );
            case '/captures':
              return MaterialPageRoute(
                builder: (_) => const CaptureListScreen(),
              );
            case '/achievements':
              return MaterialPageRoute(
                builder: (_) => const AchievementsScreen(),
              );
            case '/following':
              return MaterialPageRoute(
                builder: (_) => FollowingListScreen(
                  userId: core.UserService().currentUser?.uid ?? '',
                ),
              );

            // Capture routes
            case '/capture/camera':
              return MaterialPageRoute(builder: (_) => const CaptureScreen());
            case '/capture/detail':
              final captureId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => CaptureDetailScreen(captureId: captureId),
              );

            // Community routes
            case '/community/feed':
              return MaterialPageRoute(
                builder: (_) => const CommunityFeedScreen(),
              );
            case '/community/dashboard':
              return MaterialPageRoute(
                builder: (_) => const CommunityDashboardScreen(),
              );

            // Art Walk routes
            case '/art-walk/map':
              return MaterialPageRoute(
                builder: (_) => const ArtWalkMapScreen(),
              );
            case '/art-walk/dashboard':
              return MaterialPageRoute(
                builder: (_) => const ArtWalkDashboardScreen(),
              );

            // Artist routes
            case '/artist/dashboard':
              return MaterialPageRoute(
                builder: (_) => const ArtistDashboardScreen(),
              );
            case '/artist/profile/edit':
              return MaterialPageRoute(
                builder: (_) => const ArtistProfileEditScreen(),
              );
            case '/artist/profile/public':
              return MaterialPageRoute(
                builder: (_) => ArtistPublicProfileScreen(
                  artistProfileId: core.UserService().currentUser?.uid ?? '',
                ),
              );
            case '/artist/analytics':
              return MaterialPageRoute(
                builder: (_) => const AnalyticsDashboardScreen(),
              );
            case '/artist/approved-ads':
              return MaterialPageRoute(
                builder: (_) => const ArtistApprovedAdsScreen(),
              );

            // Gallery routes
            case '/gallery/artists-management':
              return MaterialPageRoute(
                builder: (_) => const GalleryArtistsManagementScreen(),
              );
            case '/gallery/analytics':
              return MaterialPageRoute(
                builder: (_) => const GalleryAnalyticsDashboardScreen(),
              );

            // Settings routes
            case '/settings/account':
              return MaterialPageRoute(
                builder: (_) => const AccountSettingsScreen(),
              );
            case '/settings/notifications':
              return MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              );
            case '/settings/privacy':
              return MaterialPageRoute(
                builder: (_) => const PrivacySettingsScreen(),
              );
            case '/settings/security':
              return MaterialPageRoute(
                builder: (_) => const SecuritySettingsScreen(),
              );

            // Dashboard route
            case '/dashboard':
              return MaterialPageRoute(
                builder: (_) => const core.DashboardScreen(),
              );

            // Events routes
            case '/events/dashboard':
              return MaterialPageRoute(
                builder: (_) => const core.EventsDashboardScreen(),
              );

            // Developer menu
            case '/dev':
              return MaterialPageRoute(builder: (_) => const DeveloperMenu());

            default:
              return MaterialPageRoute(
                builder: (_) => const core.SplashScreen(),
              );
          }
        },
      ),
    );
  }
}
