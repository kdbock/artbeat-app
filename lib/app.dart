import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_ads/artbeat_ads.dart' as ads;
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
          // Dashboard ViewModel
          ChangeNotifierProvider<core.DashboardViewModel>(
            create: (_) => core.DashboardViewModel(),
            lazy: true,
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
      case '/gallery/artists-management':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: GalleryArtistsManagementScreen(),
          ),
        );
      case '/gallery/analytics':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: GalleryAnalyticsDashboardScreen(),
          ),
        );
      // Core routes
      case '/splash':
        return MaterialPageRoute(builder: (_) => const core.SplashScreen());

      // Main dashboard route
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => const core.FluidDashboardScreen(),
        );

      // Profile routes
      case '/profile':
        return MaterialPageRoute(
          builder: (_) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Scaffold(
                  body: Center(
                    child: Text('Please log in to view your profile'),
                  ),
                ),
              );
            }
            return ProfileViewScreen(
              userId: currentUserId,
              isCurrentUser: true,
            );
          },
        );
      case '/profile/edit':
        return MaterialPageRoute(
          builder: (_) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: Scaffold(
                  body: Center(
                    child: Text('Please log in to edit your profile'),
                  ),
                ),
              );
            }
            return EditProfileScreen(userId: currentUserId);
          },
        );
      case '/favorites':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Fan Club',
                showLogo: false,
              ),
              body: Center(child: Text('Fan Club coming soon')),
            ),
          ),
        );

      // Auth routes
      case '/login':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: LoginScreen()),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: RegisterScreen()),
        );
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ForgotPasswordScreen(),
          ),
        );
      case '/captures':
        return MaterialPageRoute(builder: (_) => const MyCapturesScreen());
      case '/achievements':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: AchievementsScreen(),
          ),
        );
      case '/capture/camera':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: CaptureScreen()),
        );
      case '/community/feed':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: UnifiedCommunityFeed(),
          ),
        );
      case '/art-walk/map':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ArtWalkMapScreen(),
          ),
        );
      case '/art-walk/list':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ArtWalkListScreen(),
          ),
        );
      case '/art-walk/create':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: CreateArtWalkScreen(),
          ),
        );
      case '/events/dashboard':
        return MaterialPageRoute(builder: (_) => const EventsDashboardScreen());
      case '/art-walk/dashboard':
        return MaterialPageRoute(
          builder: (_) => const ArtWalkDashboardScreen(),
        );
      case '/capture/dashboard':
        return MaterialPageRoute(
          builder: (_) => const CaptureDashboardScreen(),
        );
      case '/community/dashboard':
        return MaterialPageRoute(
          builder: (_) => const CommunityDashboardScreen(),
        );
      case '/dev':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: DeveloperMenu()),
        );
      case '/feedback':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: core.FeedbackForm(),
          ),
        );
      case '/artist/artwork':
        return MaterialPageRoute(
          builder: (_) =>
              const core.MainLayout(currentIndex: -1, child: MyArtworkScreen()),
        );
      case '/artwork/upload':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: artwork.ArtworkUploadScreen(),
          ),
        );
      // ...existing code...

      // Subscription routes
      case '/subscription/comparison':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: SubscriptionComparisonScreen(),
          ),
        );

      // Artist routes
      case '/artist/dashboard':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ArtistDashboardScreen(),
          ),
        );
      case '/artist/profile-edit':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ArtistProfileEditScreen(),
          ),
        );
      case '/artist/analytics':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: AnalyticsDashboardScreen(),
          ),
        );
      case '/artist/approved-ads':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Approved Ads',
                showLogo: false,
              ),
              body: Center(child: Text('Approved ads coming soon')),
            ),
          ),
        );

      case '/artist/public-profile':
        final args = settings.arguments as Map<String, dynamic>?;
        final artistId = args?['artistId'] as String?;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        // If no artistId is provided, use the current user's ID
        final targetUserId = artistId ?? currentUserId;

        if (targetUserId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.EnhancedUniversalHeader(
                  title: 'Artist Profile',
                  showLogo: false,
                ),
                body: Center(child: Text('Please log in to view your profile')),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: -1,
            child: ArtistPublicProfileScreen(userId: targetUserId),
          ),
        );
      case '/artist/artwork-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final artworkId = args?['artworkId'] as String?;
        if (artworkId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.EnhancedUniversalHeader(
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
              appBar: core.EnhancedUniversalHeader(
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
              appBar: core.EnhancedUniversalHeader(
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
              appBar: core.EnhancedUniversalHeader(
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
              appBar: core.EnhancedUniversalHeader(
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
                appBar: core.EnhancedUniversalHeader(
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

      // Event routes (continued)
      case '/events/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId == null) {
          return MaterialPageRoute(
            builder: (_) => const core.MainLayout(
              currentIndex: -1,
              child: Scaffold(
                appBar: core.EnhancedUniversalHeader(
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
      case '/events/my-tickets':
        return MaterialPageRoute(
          builder: (_) => Consumer<core.UserService>(
            builder: (context, userService, child) {
              final userId = userService.currentUser?.uid;
              if (userId == null) {
                return const core.MainLayout(
                  currentIndex: -1,
                  child: Scaffold(
                    appBar: core.EnhancedUniversalHeader(
                      title: 'My Tickets',
                      showLogo: false,
                    ),
                    body: Center(
                      child: Text('Please log in to view your tickets'),
                    ),
                  ),
                );
              }
              return MyTicketsScreen(userId: userId);
            },
          ),
        );
      case '/events/create':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: CreateEventScreen(),
          ),
        );

      // Settings routes
      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Settings coming soon')),
            ),
          ),
        );
      case '/settings/account':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
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
              appBar: core.EnhancedUniversalHeader(
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
              appBar: core.EnhancedUniversalHeader(
                title: 'Notification Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Notification settings coming soon')),
            ),
          ),
        );
      case '/settings/security':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Security Settings',
                showLogo: false,
              ),
              body: Center(child: Text('Security settings coming soon')),
            ),
          ),
        );
      case '/support':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: Scaffold(
              appBar: core.EnhancedUniversalHeader(
                title: 'Help & Support',
                showLogo: false,
              ),
              body: Center(child: Text('Help & Support coming soon')),
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
              appBar: core.EnhancedUniversalHeader(
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
              appBar: core.EnhancedUniversalHeader(
                title: 'System Settings',
                showLogo: false,
              ),
              body: Center(child: Text('System Settings coming soon')),
            ),
          ),
        );
      case '/admin/ad-review':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.AdminAdReviewScreen(),
          ),
        );

      // Developer menu (already handled above)

      // Feedback submission route (already handled above)
      case '/developer-feedback-admin':
        return MaterialPageRoute(
          builder: (_) => const core.DeveloperFeedbackAdminScreen(),
        );
      case '/search/results':
        final searchArgs = settings.arguments as Map<String, dynamic>;
        final searchQuery = searchArgs['query'] as String;
        return MaterialPageRoute(
          builder: (_) => core.MainLayout(
            currentIndex: -1,
            child: core.SearchResultsScreen(query: searchQuery),
          ),
        );

      // Ad Creation Routes
      case '/ad-create/user':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.UserAdCreateScreen(),
          ),
        );
      case '/ad-create/artist':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.ArtistAdCreateScreen(),
          ),
        );
      case '/ad-create/gallery':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.GalleryAdCreateScreen(),
          ),
        );
      case '/ad-create/admin':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.AdminAdCreateScreen(),
          ),
        );

      // Ad Review Routes
      case '/ad-review/user':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.UserAdReviewScreen(),
          ),
        );
      case '/ad-status/artist':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.ArtistAdStatusScreen(),
          ),
        );
      case '/ad-status/gallery':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.GalleryAdStatusScreen(),
          ),
        );
      case '/ad-review/admin':
        return MaterialPageRoute(
          builder: (_) => const core.MainLayout(
            currentIndex: -1,
            child: ads.AdminAdReviewScreen(),
          ),
        );
    }
    // Fallback: return splash screen if no route matched
    return MaterialPageRoute(
      builder: (_) =>
          const core.MainLayout(currentIndex: -1, child: core.SplashScreen()),
    );
  }
}
