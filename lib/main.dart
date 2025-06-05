import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show NavigationService, DashboardScreen, SplashScreen;
import 'package:artbeat_auth/artbeat_auth.dart'
    show LoginScreen, RegisterScreen;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:artbeat_settings/artbeat_settings.dart' as settings;
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_community/screens/feed/community_feed_screen.dart';
import 'package:artbeat_community/screens/studios/studio_chat_screen.dart';
import 'package:artbeat_community/screens/sponsorships/sponsorship_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ARTbeatApp());
}

class ARTbeatApp extends StatelessWidget {
  const ARTbeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService();

    return MaterialApp(
      title: 'ARTbeat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorKey: navigationService.navigatorKey,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardScreen(),

        // Auth routes
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),

        // Profile routes
        '/profile/view': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return profile.ProfileViewScreen(userId: args?['userId'] ?? '');
        },
        '/profile/edit': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return profile.EditProfileScreen(userId: args?['userId'] ?? '');
        },
        '/profile/achievements': (context) =>
            const profile.AchievementsScreen(),
        '/profile/favorites': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return profile.FavoritesScreen(userId: args?['userId'] ?? '');
        },

        // Artist routes
        '/artist/dashboard': (context) => const artist.ArtistDashboardScreen(),
        '/artist/analytics': (context) =>
            const artist.AnalyticsDashboardScreen(),
        '/artist/subscription': (context) => const artist.SubscriptionScreen(),

        // Settings routes
        '/settings/account': (context) =>
            const settings.AccountSettingsScreen(),
        '/settings/notifications': (context) =>
            const settings.NotificationSettingsScreen(),
        '/settings/privacy': (context) =>
            const settings.PrivacySettingsScreen(),
        '/settings/security': (context) =>
            const settings.SecuritySettingsScreen(),

        // Community routes
        '/community/feed': (context) => const CommunityFeedScreen(),
        '/community/studio': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final studioId = args?['studioId'] ?? '';
          return StudioChatScreen(studioId: studioId);
        },
        '/community/sponsorship': (context) => const SponsorshipScreen(),
      },
    );
  }
}
