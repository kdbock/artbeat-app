#!/bin/zsh

echo "Fixing routes and constructors in main.dart..."

# Update the main.dart file to fix constructor parameters
cat > "/Users/kristybock/artbeat/lib/main.dart.fixed" << 'EOL'
// filepath: /Users/kristybock/artbeat/lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// Import the modular packages
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_profile/artbeat_profile.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_settings/artbeat_settings.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => UserService()),
        Provider(create: (_) => NotificationService()),
        Provider(create: (_) => ConnectivityService()),
        Provider(create: (_) => PaymentService()),
        
        // Auth providers
        Provider(create: (context) => AuthProfileService()),
        
        // Artist providers
        Provider(create: (context) => AnalyticsService()),
        Provider(create: (context) => SubscriptionService()),
        Provider(create: (context) => GalleryInvitationService()),
        
        // Artwork providers
        Provider(create: (context) => ArtworkService()),
        Provider(create: (context) => ImageModerationService('assets/service_account.json')),
        
        // Art Walk providers
        Provider(create: (context) => AchievementService()),
        Provider(create: (context) => DirectionsService()),
        
        // Calendar provider
        Provider(create: (context) => EventService()),
      ],
      child: MaterialApp(
        title: 'ARTbeat',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        // Start with loading screen which will navigate to other screens
        home: const LoadingScreen(),
        routes: {
          // Core screens
          '/splash': (context) => const SplashScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          
          // Auth screens
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          
          // Profile screens - using builder methods for screens requiring parameters
          '/profile_view': (context) => ProfileViewScreen(userId: Provider.of<UserService>(context, listen: false).currentUserId ?? ''),
          '/edit_profile': (context) => EditProfileScreen(userId: Provider.of<UserService>(context, listen: false).currentUserId ?? ''),
          '/followers': (context) => FollowersListScreen(userId: Provider.of<UserService>(context, listen: false).currentUserId ?? ''),
          '/following': (context) => FollowingListScreen(userId: Provider.of<UserService>(context, listen: false).currentUserId ?? ''),
          '/favorites': (context) => FavoritesScreen(userId: Provider.of<UserService>(context, listen: false).currentUserId ?? ''),
          
          // Settings screens
          '/settings': (context) => const SettingsScreen(),
          '/settings/account': (context) => const AccountSettingsScreen(),
          '/settings/privacy': (context) => const PrivacySettingsScreen(),
          '/settings/notifications': (context) => const NotificationSettingsScreen(),
          '/settings/security': (context) => const SecuritySettingsScreen(),
          '/settings/blocked_users': (context) => const BlockedUsersScreen(),
          
          // Artist screens
          '/artist/dashboard': (context) => const ArtistDashboardScreen(),
          '/artist/profile': (context) => const ArtistProfileEditScreen(),
          '/artist/subscription': (context) => const SubscriptionScreen(),
          '/artist/payment': (context) => PaymentScreen(tier: SubscriptionTier.artistPro), // Default tier
          '/artist/payment_methods': (context) => const PaymentMethodsScreen(),
          '/artist/analytics': (context) => const AnalyticsDashboardScreen(),
          
          // Gallery screens
          '/gallery/analytics': (context) => const GalleryAnalyticsDashboardScreen(),
          '/gallery/artists': (context) => const GalleryArtistsManagementScreen(),
          
          // Artwork screens - using builder methods for screens requiring parameters
          '/artwork/upload': (context) => const ArtworkUploadScreen(),
          '/artwork/browse': (context) => const ArtworkBrowseScreen(),
          
          // Art Walk screens - using builder methods for screens requiring parameters
          '/art_walk/map': (context) => const ArtWalkMapScreen(),
          '/art_walk/list': (context) => const ArtWalkListScreen(),
          
          // Capture screens
          '/capture/list': (context) => const CaptureListScreen(),
        },
        onGenerateRoute: (RouteSettings settings) {
          // Handle routes with parameters
          if (settings.name?.startsWith('/artwork/detail/') ?? false) {
            final artworkId = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (context) => ArtworkDetailScreen(artworkId: artworkId),
            );
          }
          
          if (settings.name?.startsWith('/art_walk/detail/') ?? false) {
            final walkId = settings.name!.split('/').last;
            return MaterialPageRoute(
              builder: (context) => ArtWalkDetailScreen(walkId: walkId),
            );
          }
          
          return null;
        },
      ),
    );
  }
}
EOL

# Replace the main.dart file with the fixed version
mv "/Users/kristybock/artbeat/lib/main.dart.fixed" "/Users/kristybock/artbeat/lib/main.dart"

echo "Fixed main.dart routes and constructors!"
