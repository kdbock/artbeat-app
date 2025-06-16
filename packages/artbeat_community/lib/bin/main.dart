// filepath: /Users/kristybock/artbeat/packages/artbeat_community/lib/bin/main.dart
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_community/screens/screens.dart';
import 'package:artbeat_community/services/services.dart';

// You can replace this with actual Firebase options for development
// Get Firebase configuration from ConfigService
final firebaseConfig = ConfigService.instance.firebaseConfig;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await ConfigService.instance.initialize();
    final config = ConfigService.instance.firebaseConfig;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: config['apiKey'] ?? '',
        appId: config['appId'] ?? '',
        messagingSenderId: config['messagingSenderId'] ?? '',
        projectId: config['projectId'] ?? '',
        storageBucket: config['storageBucket'] ?? '',
      ),
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    // Continue without Firebase when in development mode
    if (!kDebugMode) rethrow;
  }

  runApp(const CommunityModuleApp());
}

class CommunityModuleApp extends StatelessWidget {
  const CommunityModuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<UserService>(
          create: (_) => UserService(),
        ),
        ChangeNotifierProvider<CommunityService>(
          create: (_) => CommunityService(),
        ),
      ],
      child: MaterialApp(
        title: 'ARTbeat Community Module',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const CommunityModuleHome(),
      ),
    );
  }
}

class CommunityModuleHome extends StatelessWidget {
  const CommunityModuleHome({super.key});

  // Helper method to build navigation buttons
  Widget _buildNavButton(
      BuildContext context, String title, Widget destination, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => destination),
        ),
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 0),
        ),
      ),
    );
  }

  // Helper method to build a section card
  Widget _buildSectionCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ARTbeat Community Module'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Community Module Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 30),

            // Feed section
            const Text('Feed Screens',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSectionCard(
              context,
              [
                _buildNavButton(context, 'Community Feed',
                    const CommunityFeedScreen(), Icons.view_stream),
                _buildNavButton(context, 'Social Feed',
                    const SocialFeedScreen(), Icons.people),
                _buildNavButton(context, 'Create Post',
                    const CreatePostScreen(), Icons.add_box),
                _buildNavButton(context, 'Trending Content',
                    const TrendingContentScreen(), Icons.trending_up),
              ],
            ),
            const SizedBox(height: 20),

            // Moderation section
            const Text('Moderation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSectionCard(
              context,
              [
                _buildNavButton(context, 'Moderation Queue',
                    const ModerationQueueScreen(), Icons.admin_panel_settings),
              ],
            ),
            const SizedBox(height: 20),

            // Other features
            const Text('Other Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildSectionCard(
              context,
              [
                _buildNavButton(
                    context, 'Gifts', const GiftsScreen(), Icons.card_giftcard),
                _buildNavButton(context, 'Portfolios', const PortfoliosScreen(),
                    Icons.photo_album),
                _buildNavButton(
                    context, 'Studios', const StudiosScreen(), Icons.forum),
                _buildNavButton(context, 'Commissions',
                    const CommissionsScreen(), Icons.work),
                _buildNavButton(context, 'Sponsorships',
                    const SponsorshipScreen(), Icons.volunteer_activism),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
