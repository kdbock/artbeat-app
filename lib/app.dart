import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:artbeat_artist/artbeat_artist.dart'
    show ArtistPublicProfileScreen;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:artbeat_art_walk/src/screens/my_captures_screen.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_admin/artbeat_admin.dart' as admin;

import 'widgets/developer_menu.dart';
import 'src/widgets/error_boundary.dart';

class MyApp extends StatelessWidget {
  final navigatorKey = GlobalKey<NavigatorState>();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stackTrace) {
        // Log the error and stack trace
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
          onGenerateRoute: onGenerateRoute,
        ),
      ),
    );
  }

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Core routes
      case '/splash':
        return MaterialPageRoute(builder: (_) => const core.SplashScreen());

      // Main dashboard route
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const core.DashboardScreen());

      // Auth routes
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      // Profile routes
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) =>
                ProfileViewScreen(userId: userService.currentUser?.uid ?? ''),
          ),
        );
      case '/profile/public':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) =>
                ProfileViewScreen(userId: userService.currentUser?.uid ?? ''),
          ),
        );
      case '/profile/edit':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) =>
                EditProfileScreen(userId: userService.currentUser?.uid ?? ''),
          ),
        );
      case '/favorites':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) =>
                FavoritesScreen(userId: userService.currentUser?.uid ?? ''),
          ),
        );
      case '/captures':
        return MaterialPageRoute(builder: (_) => const MyCapturesScreen());
      case '/achievements':
        return MaterialPageRoute(builder: (_) => const AchievementsScreen());
      case '/following':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) =>
                FollowingListScreen(userId: userService.currentUser?.uid ?? ''),
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
        return MaterialPageRoute(builder: (_) => const UnifiedCommunityFeed());
      case '/community/dashboard':
        return MaterialPageRoute(
          builder: (_) => const CommunityDashboardScreen(),
        );

      // Art Walk routes
      case '/art-walk/map':
        return MaterialPageRoute(builder: (_) => const ArtWalkMapScreen());
      case '/art-walk/dashboard':
        return MaterialPageRoute(
          builder: (_) => const ArtWalkDashboardScreen(),
        );
      case '/art-walk/list':
        return MaterialPageRoute(builder: (_) => const ArtWalkListScreen());
      case '/art-walk/detail':
        final walkId = settings.arguments as String?;
        if (walkId == null) {
          return MaterialPageRoute(
            builder: (_) => const ArtWalkDashboardScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ArtWalkDetailScreen(walkId: walkId),
        );
      case '/art-walk/create':
        return MaterialPageRoute(builder: (_) => const CreateArtWalkScreen());
      case '/art-walk/edit':
        final args = settings.arguments as Map<String, dynamic>?;
        final walkId = args?['walkId'] as String?;
        final artWalk = args?['artWalk'] as ArtWalkModel?;
        if (walkId == null) {
          return MaterialPageRoute(
            builder: (_) => const ArtWalkDashboardScreen(),
          );
        }
        return MaterialPageRoute(
          builder: (_) =>
              ArtWalkEditScreen(artWalkId: walkId, artWalk: artWalk),
        );

      // Artist routes
      case '/artist/search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Search Artists',
                showLogo: false,
              ),
              body: Center(child: Text('Artist search coming soon')),
            ),
          ),
        );
      case '/artist/featured':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Featured Artists',
                showLogo: false,
              ),
              body: Center(child: Text('Featured artists coming soon')),
            ),
          ),
        );
      case '/artist/local':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Local Artists',
                showLogo: false,
              ),
              body: Center(child: Text('Local artists coming soon')),
            ),
          ),
        );
      case '/artist/categories':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Browse Categories',
                showLogo: false,
              ),
              body: Center(child: Text('Artist categories coming soon')),
            ),
          ),
        );
      case '/artist/dashboard':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Artist Dashboard',
                showLogo: false,
              ),
              body: Center(child: Text('Artist dashboard coming soon')),
            ),
          ),
        );
      case '/artist/subscription':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Subscription',
                showLogo: false,
              ),
              body: Center(child: Text('Subscription coming soon')),
            ),
          ),
        );
      case '/artist/commissions':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Commissions',
                showLogo: false,
              ),
              body: Center(child: Text('Commissions coming soon')),
            ),
          ),
        );
      case '/artist/events':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(title: 'Events', showLogo: false),
              body: Center(child: Text('Events coming soon')),
            ),
          ),
        );
      case '/artist/create-profile':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Create Artist Profile',
                showLogo: false,
              ),
              body: Center(child: Text('Create artist profile coming soon')),
            ),
          ),
        );
      case '/artist/activity':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(title: 'Activity', showLogo: false),
              body: Center(child: Text('Activity coming soon')),
            ),
          ),
        );
      case '/artist/public-profile':
        final args = settings.arguments as Map<String, dynamic>?;
        final artistId = args?['artistId'] as String?;
        if (artistId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.UniversalHeader(
                  title: 'Artist Profile',
                  showLogo: false,
                ),
                body: Center(child: Text('Artist not found')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ArtistPublicProfileScreen(userId: artistId),
        );
      case '/artist/artwork-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final artworkId = args?['artworkId'] as String?;
        if (artworkId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.UniversalHeader(
                  title: 'Artwork Detail',
                  showLogo: false,
                ),
                body: Center(child: Text('Artwork not found')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => artwork.ArtworkDetailScreen(artworkId: artworkId),
        );

      // Artwork routes
      case '/artwork/search':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Search Artwork',
                showLogo: false,
              ),
              body: Center(child: Text('Artwork search coming soon')),
            ),
          ),
        );
      case '/artwork/featured':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Featured Artwork',
                showLogo: false,
              ),
              body: Center(child: Text('Featured artwork coming soon')),
            ),
          ),
        );
      case '/artwork/recent':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Recent Artwork',
                showLogo: false,
              ),
              body: Center(child: Text('Recent artwork coming soon')),
            ),
          ),
        );
      case '/artwork/trending':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Trending Artwork',
                showLogo: false,
              ),
              body: Center(child: Text('Trending artwork coming soon')),
            ),
          ),
        );
      case '/artwork/edit':
        final args = settings.arguments as Map<String, dynamic>?;
        final artworkId = args?['artworkId'] as String?;
        final artworkModel = args?['artwork'] as artwork.ArtworkModel?;
        if (artworkId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.UniversalHeader(
                  title: 'Edit Artwork',
                  showLogo: false,
                ),
                body: Center(child: Text('Artwork not found')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => artwork.ArtworkEditScreen(
            artworkId: artworkId,
            artwork: artworkModel,
          ),
        );

      // Event routes
      case '/events/dashboard':
        return MaterialPageRoute(
          builder: (_) => const core.EventsDashboardScreen(),
        );
      case '/events/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.UniversalHeader(
                  title: 'Event Details',
                  showLogo: false,
                ),
                body: Center(child: Text('Event not found')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EventDetailsScreen(eventId: eventId),
        );
      case '/events/upcoming':
        return MaterialPageRoute(
          builder: (_) => const EventsListScreen(
            title: 'Upcoming Events',
            showCreateButton: false,
          ),
        );
      case '/events/all':
        return MaterialPageRoute(
          builder: (_) => const EventsListScreen(
            title: 'All Events',
            showCreateButton: true,
          ),
        );
      case '/events/my-events':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) => EventsListScreen(
              title: 'My Events',
              artistId: userService.currentUser?.uid,
              showCreateButton: true,
            ),
          ),
        );

      // Settings routes
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(title: 'Settings', showLogo: false),
              body: Center(child: Text('Settings coming soon')),
            ),
          ),
        );
      case '/settings/account':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Account Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Account settings coming soon')),
            ),
          ),
        );
      case '/settings/privacy':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Privacy Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Privacy settings coming soon')),
            ),
          ),
        );
      case '/settings/notifications':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Notification Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Notification settings coming soon')),
            ),
          ),
        );

      // Admin routes
      case '/admin/dashboard':
        return MaterialPageRoute(
          builder: (_) => const admin.AdminDashboardScreen(),
        );
      case '/admin/users':
        return MaterialPageRoute(
          builder: (_) => const admin.AdminUserManagementScreen(),
        );
      case '/admin/moderation':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'Content Moderation',
                showLogo: false,
              ),
              body: Center(child: Text('Content Moderation coming soon')),
            ),
          ),
        );
      case '/admin/settings':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.UniversalHeader(
                title: 'System Settings',
                showLogo: false,
              ),
              body: Center(child: Text('System Settings coming soon')),
            ),
          ),
        );

      // Developer menu
      case '/dev':
        return MaterialPageRoute(builder: (_) => const DeveloperMenu());

      // Handle dynamic event routes
      default:
        if (settings.name?.startsWith('/event/') ?? false) {
          final eventId = settings.name!.replaceFirst('/event/', '');
          return MaterialPageRoute(
            builder: (_) => EventDetailsScreen(eventId: eventId),
          );
        }

        // Return to splash screen for unknown routes
        return MaterialPageRoute(builder: (_) => const core.SplashScreen());
    }
  }
}
