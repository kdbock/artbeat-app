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
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_settings/artbeat_settings.dart';
import 'package:artbeat_events/artbeat_events.dart';
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
        // Community providers
        ChangeNotifierProvider<CommunityService>(
          create: (_) => CommunityService(),
          lazy: true, // Changed to lazy to prevent early Firebase access
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
                builder: (_) => const UnifiedCommunityFeed(),
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
            case '/art-walk/create':
              return MaterialPageRoute(
                builder: (_) => const CreateArtWalkScreen(),
              );

            // Artist routes
            case '/artist/onboarding':
              final user = settings.arguments as core.UserModel?;
              return MaterialPageRoute(
                builder: (_) => ArtistOnboardingScreen(
                  user:
                      user ??
                      core.UserModel(
                        id: core.UserService().currentUser?.uid ?? '',
                        email: core.UserService().currentUser?.email ?? '',
                        fullName:
                            core.UserService().currentUser?.displayName ?? '',
                        userType: core.UserType.artist,
                        level: 1,
                        experiencePoints: 0,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                ),
              );
            case '/artist/dashboard':
              return MaterialPageRoute(
                builder: (_) => const ArtistDashboardScreen(),
              );
            case '/artist/profile/edit':
              return MaterialPageRoute(
                builder: (_) => const ArtistProfileEditScreen(),
              );
            case '/artist/profile':
              final artistId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => ArtistPublicProfileScreen(userId: artistId),
              );
            case '/artist/profile/public':
              return MaterialPageRoute(
                builder: (_) => ArtistPublicProfileScreen(
                  userId: core.UserService().currentUser?.uid ?? '',
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
            case '/artist/artwork':
              return MaterialPageRoute(
                builder: (_) => const artwork.ArtworkBrowseScreen(),
              );
            case '/artist/artwork/upload':
              return MaterialPageRoute(
                builder: (_) => const artwork.ArtworkUploadScreen(),
              );

            // Artwork detail route
            case '/artwork/details':
              final artworkId = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) =>
                    artwork.ArtworkDetailScreen(artworkId: artworkId),
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
            case '/support':
              return MaterialPageRoute(
                builder: (_) => core.MainLayout(
                  currentIndex: -1,
                  child: Scaffold(
                    appBar: const core.UniversalHeader(
                      title: 'Help & Support',
                      showLogo: false,
                    ),
                    body: const Center(child: Text('Support page coming soon')),
                  ),
                ),
              );
            case '/feedback':
              return MaterialPageRoute(
                builder: (_) => const core.FeedbackForm(),
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
            case '/events/all':
              return MaterialPageRoute(
                builder: (_) => const EventsListScreen(),
              );
            case '/events/my-tickets':
              return MaterialPageRoute(
                builder: (_) => MyTicketsScreen(
                  userId: core.UserService().currentUser?.uid ?? '',
                ),
              );
            case '/events/create':
              return MaterialPageRoute(
                builder: (_) => const CreateEventScreen(),
              );
            case '/events/my-events':
              return MaterialPageRoute(
                builder: (_) => EventsListScreen(
                  title: 'My Events',
                  artistId: core.UserService().currentUser?.uid ?? '',
                  showCreateButton: true,
                ),
              );
            case '/events/details':
              final eventId = settings.arguments as String?;
              if (eventId == null) {
                return MaterialPageRoute(
                  builder: (_) => const core.SplashScreen(),
                );
              }
              return MaterialPageRoute(
                builder: (_) => EventDetailsWrapper(eventId: eventId),
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
