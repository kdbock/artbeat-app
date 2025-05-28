import 'package:flutter/material.dart';
// Added Firebase Core
// Uncommented
import 'package:firebase_core/firebase_core.dart'; // Add this import
import 'package:artbeat/utils/connectivity_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:artbeat/utils/env_validator.dart';
import 'package:artbeat/utils/env_loader.dart';
import 'package:artbeat/firebase_options.dart';
import 'package:artbeat/services/auth_profile_service.dart';
import 'package:artbeat/screens/loading_screen.dart';
import 'package:artbeat/screens/splash_screen.dart';
import 'package:artbeat/screens/authentication/login_screen.dart';
import 'package:artbeat/screens/authentication/register_screen.dart';
import 'package:artbeat/screens/authentication/forgot_password_screen.dart';
import 'package:artbeat/screens/dashboard_screen.dart';

// Import profile screens
import 'package:artbeat/screens/profile/profile_view_screen.dart';
import 'package:artbeat/screens/profile/edit_profile_screen.dart';
import 'package:artbeat/screens/profile/profile_picture_viewer_screen.dart';
import 'package:artbeat/screens/profile/followers_list_screen.dart';
import 'package:artbeat/screens/profile/following_list_screen.dart';
import 'package:artbeat/screens/profile/favorites_screen.dart'
    show FavoritesScreen;
import 'package:artbeat/screens/profile/favorite_detail_screen.dart';
import 'package:artbeat/screens/profile/achievements_screen.dart';

// Import settings screens
import 'package:artbeat/screens/settings/settings_screen.dart';
import 'package:artbeat/screens/settings/account_settings_screen.dart';
import 'package:artbeat/screens/settings/privacy_settings_screen.dart';
import 'package:artbeat/screens/settings/notification_settings_screen.dart';
import 'package:artbeat/screens/settings/security_settings_screen.dart';
import 'package:artbeat/screens/settings/blocked_users_screen.dart';

// Import discover screen
import 'package:artbeat/screens/discover_screen.dart';

// Import Art Walk screens
import 'package:artbeat/screens/art_walk/art_walk_map_screen.dart';
import 'package:artbeat/screens/art_walk/create_art_walk_screen.dart';
import 'package:artbeat/screens/art_walk/art_walk_list_screen.dart';
import 'package:artbeat/screens/art_walk/art_walk_detail_screen.dart';

// Import explore screens
import 'package:artbeat/screens/explore/nc_regions_explore_screen.dart';

// Import calendar screens
import 'package:artbeat/screens/calendar/calendar_screen.dart';
import 'package:artbeat/screens/calendar/event_form_screen.dart';
import 'package:artbeat/screens/calendar/event_detail_screen.dart';

// Import community screens
import 'package:artbeat/screens/community/community_feed_screen.dart';
import 'package:artbeat/screens/community/create_post_screen.dart';
import 'package:artbeat/screens/community/post_detail_screen.dart';

// Import artist subscription screens
import 'package:artbeat/screens/artist/artist_dashboard_screen.dart';
import 'package:artbeat/screens/artist/artist_profile_edit_screen.dart';
import 'package:artbeat/screens/artist/subscription_screen.dart';
import 'package:artbeat/screens/artist/artwork_upload_screen.dart';
import 'package:artbeat/screens/artist/artwork_browse_screen.dart';
import 'package:artbeat/screens/artist/artist_browse_screen.dart';
import 'package:artbeat/screens/artist/artist_public_profile_screen.dart';
import 'package:artbeat/screens/artist/artwork_detail_screen.dart';
import 'package:artbeat/screens/artist/payment_screen.dart';
import 'package:artbeat/screens/artist/analytics_dashboard_screen.dart';
import 'package:artbeat/screens/artist/subscription_analytics_screen.dart';
import 'package:artbeat/screens/artist/event_creation_screen.dart';
import 'package:artbeat/screens/artist/gallery_artists_management_screen.dart';
import 'package:artbeat/screens/artist/gallery_analytics_dashboard_screen.dart';
import 'package:artbeat/screens/artist/payment_methods_screen.dart';
import 'package:artbeat/services/payment_service.dart';
import 'package:artbeat/models/subscription_model.dart';
import 'package:logger/logger.dart'; // Import logger

final Logger _logger = Logger(); // Add a logger instance

void main() async {
  // Made main async
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensured Flutter binding is initialized

  try {
    // Load environment variables directly as a string
    final envString = await EnvLoader.loadEnvStringFromAssets();
    if (envString != null && envString.isNotEmpty) {
      dotenv.testLoad(fileInput: envString); // Use testLoad with fileInput
      _logger
          .i('Environment variables loaded directly from string via testLoad.');
    } else {
      _logger.w(
          'No environment string loaded or string was empty, AppConfig might use fallbacks.');
    }

    // Validate environment variables are properly loaded
    EnvValidator.validateRequiredEnvVars();
  } catch (e) {
    _logger.e('Error loading environment variables: $e');
    // Continue execution with fallback values in development
  }

  // Initialize Firebase and App Check
  try {
    // Check if Firebase app already exists
    if (Firebase.apps.isNotEmpty) {
      _logger.i(
          'Firebase app "[DEFAULT]" already initialized. Using existing instance.');
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _logger.i(
          '✅ Firebase successfully initialized with project: wordnerd-artbeat');
    }

    // Initialize App Check
    // IMPORTANT: For production, use PlayIntegrityProvider.
    // For debugging, you can use AndroidProvider.debug.
    // Ensure you have registered your debug token in the Firebase console.
    // Temporarily disabled for troubleshooting login issues
    /*
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          AndroidProvider.debug, // Or AndroidProvider.playIntegrity
      // appleProvider: AppleProvider.appAttest, // For iOS
    );
    */
    _logger.i('✅ Firebase App Check activated.');
  } catch (e) {
    _logger.e('⚠️ Firebase initialization or App Check error: $e');
  }

  // Set up auth state listener for automatic profile creation
  AuthProfileService.setupAuthStateListener();

  // Initialize connectivity utilities
  await ConnectivityUtils.instance.initialize();

  // Initialize Stripe payment
  await PaymentService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Additional initialization can be done here
  }

  @override
  Widget build(BuildContext context) {
    // This will be called after build to show warning if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EnvValidator.showWarningIfNeeded(context);
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ARTbeat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoadingScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/discover': (context) => const DiscoverScreen(),

        // Profile routes
        '/profile/view': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ProfileViewScreen(
            userId: args['userId'] as String,
            isCurrentUser: args['isCurrentUser'] as bool,
          );
        },
        '/profile/edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return EditProfileScreen(userId: args['userId'] as String);
        },
        '/profile/picture-viewer': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ProfilePictureViewerScreen(
            imageUrl: args['imageUrl'] as String,
          );
        },
        '/profile/followers': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FollowersListScreen(userId: args['userId'] as String);
        },
        '/profile/following': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FollowingListScreen(userId: args['userId'] as String);
        },
        '/profile/favorites': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FavoritesScreen(userId: args['userId'] as String);
        },
        '/profile/favorite-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return FavoriteDetailScreen(
            favoriteId: args['favoriteId'] as String,
            userId: args['userId'] as String,
          );
        },
        '/profile/achievements': (context) => const AchievementsScreen(),

        // Calendar routes
        '/calendar': (context) => const CalendarScreen(),
        '/calendar/create-event': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return EventFormScreen(
            selectedDate: args['selectedDate'] as DateTime,
          );
        },
        '/calendar/edit-event': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return EventFormScreen(
            selectedDate: args['selectedDate'] as DateTime,
            eventId: args['eventId'] as String,
          );
        },
        '/calendar/event-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return EventDetailScreen(eventId: args['eventId'] as String);
        },

        // Settings routes
        '/settings': (context) => const SettingsScreen(),
        '/settings/account': (context) => const AccountSettingsScreen(),
        '/settings/privacy': (context) => const PrivacySettingsScreen(),
        '/settings/notifications': (context) =>
            const NotificationSettingsScreen(),
        '/settings/security': (context) => const SecuritySettingsScreen(),
        '/settings/blocked-users': (context) => const BlockedUsersScreen(),

        // Community routes
        '/community/feed': (context) => const CommunityFeedScreen(),
        '/community/create-post': (context) => const CreatePostScreen(),
        '/community/post-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return PostDetailScreen(postId: args['postId'] as String);
        },

        // Artist subscription routes
        '/artist/dashboard': (context) => const ArtistDashboardScreen(),
        '/artist/create-profile': (context) => const ArtistProfileEditScreen(),
        '/artist/edit-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ArtistProfileEditScreen(
            artistProfileId: args['artistProfileId'] as String,
          );
        },
        '/artist/subscription': (context) => const SubscriptionScreen(),
        '/artist/payment': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return PaymentScreen(
            tier: args['tier'] as SubscriptionTier,
          );
        },
        '/artist/payment-methods': (context) => const PaymentMethodsScreen(),
        '/artist/upload-artwork': (context) => const ArtworkUploadScreen(),
        '/artist/edit-artwork': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ArtworkUploadScreen(
            artworkId: args['artworkId'] as String,
          );
        },
        '/artist/browse': (context) => const ArtistBrowseScreen(),
        '/artist/public-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ArtistPublicProfileScreen(
            artistProfileId: args['artistProfileId'] as String,
          );
        },
        '/artist/artwork-detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ArtworkDetailScreen(
            artworkId: args['artworkId'] as String,
          );
        },
        '/artist/analytics': (context) => const AnalyticsDashboardScreen(),
        '/artist/subscription-analytics': (context) =>
            const SubscriptionAnalyticsScreen(),
        '/artist/create-event': (context) => const EventCreationScreen(),
        '/artist/edit-event': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return EventCreationScreen(
            eventId: args['eventId'] as String,
          );
        },
        '/artist/gallery-management': (context) =>
            const GalleryArtistsManagementScreen(),
        '/artist/gallery-analytics': (context) =>
            const GalleryAnalyticsDashboardScreen(),
        '/artwork/browse': (context) => const ArtworkBrowseScreen(),

        // Art Walk routes
        '/art-walk/map': (context) => const ArtWalkMapScreen(),
        '/art-walk/list': (context) => const ArtWalkListScreen(),
        '/art-walk/create': (context) => const CreateArtWalkScreen(),
        '/art-walk/detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ArtWalkDetailScreen(
            walkId: args['walkId'] as String,
          );
        },

        // Explore routes
        '/explore/nc-regions': (context) => const NCRegionsExploreScreen(),
      },
    );
  }
}
