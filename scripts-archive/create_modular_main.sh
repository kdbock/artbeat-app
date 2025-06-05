#!/bin/zsh

echo "Creating a new modular main.dart file..."

# Create a backup of the current main.dart
cp lib/main.dart lib/main.dart.original

# Create a new modular main.dart
cat > lib/main.dart << 'EOF'
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
        Provider(create: (context) => ImageModerationService()),
        
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
          '/discover': (context) => const DiscoverScreen(),
          
          // Auth screens
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
          
          // Profile screens
          '/profile_view': (context) => const ProfileViewScreen(),
          '/edit_profile': (context) => const EditProfileScreen(),
          '/followers': (context) => const FollowersListScreen(),
          '/following': (context) => const FollowingListScreen(),
          '/favorites': (context) => const FavoritesScreen(),
          
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
          '/artist/payment': (context) => const PaymentScreen(),
          '/artist/payment_methods': (context) => const PaymentMethodsScreen(),
          '/artist/analytics': (context) => const AnalyticsDashboardScreen(),
          
          // Gallery screens
          '/gallery/analytics': (context) => const GalleryAnalyticsDashboardScreen(),
          '/gallery/artists': (context) => const GalleryArtistsManagementScreen(),
          
          // Artwork screens
          '/artwork/upload': (context) => const ArtworkUploadScreen(),
          '/artwork/browse': (context) => const ArtworkBrowseScreen(),
          '/artwork/detail': (context) => const ArtworkDetailScreen(),
          
          // Art Walk screens
          '/art_walk/map': (context) => const ArtWalkMapScreen(),
          '/art_walk/list': (context) => const ArtWalkListScreen(),
          '/art_walk/detail': (context) => const ArtWalkDetailScreen(),
          '/art_walk/create': (context) => const CreateArtWalkScreen(),
          
          // Event screens
          '/event/create': (context) => const EventCreationScreen(),
          
          // Capture screens
          '/capture/camera': (context) => const CameraScreen(),
        },
      ),
    );
  }
}
EOF

echo "✅ Created modular main.dart"
echo "The original main.dart has been backed up to lib/main.dart.original"