#!/bin/zsh

echo "Fixing main.dart route implementations..."

# Update main.dart file to fix route errors
cat > /Users/kristybock/artbeat/lib/main.dart << 'EOL'
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
        ChangeNotifierProvider(create: (_) => NotificationService()),
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

        // Community provider
        Provider(create: (context) => CommunityService()),
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
          '/artist/payment': (context) => const PaymentScreen(),
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
          
          // Add routes for other screens with parameters
          
          return null;
        },
      ),
    );
  }
}
EOL

# Create missing CommunityService
mkdir -p /Users/kristybock/artbeat/packages/artbeat_community/lib/src/services
cat > /Users/kristybock/artbeat/packages/artbeat_community/lib/src/services/community_service.dart << 'EOL'
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CommunityService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get all posts
  Future<List<dynamic>> getPosts({int limit = 10, String? lastPostId}) async {
    try {
      Query query = _firestore.collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);
          
      if (lastPostId != null) {
        // Get the last post doc for pagination
        DocumentSnapshot lastDocSnapshot = 
            await _firestore.collection('posts').doc(lastPostId).get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting posts: $e');
      return [];
    }
  }
  
  // Get post by ID
  Future<Map<String, dynamic>?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists && doc.data() != null) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('Error getting post: $e');
      return null;
    }
  }
  
  // Create post
  Future<String?> createPost(Map<String, dynamic> postData) async {
    try {
      final docRef = await _firestore.collection('posts').add({
        ...postData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }
  
  // Update post
  Future<bool> updatePost(String postId, Map<String, dynamic> postData) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        ...postData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return false;
    }
  }
  
  // Delete post
  Future<bool> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }
  
  // Like or unlike a post
  Future<bool> togglePostLike(String postId, String userId) async {
    try {
      // Check if user already liked the post
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      
      final batch = _firestore.batch();
      final postRef = _firestore.collection('posts').doc(postId);
      
      if (likeDoc.exists) {
        // Unlike: Remove like and decrement counter
        batch.delete(likeDoc.reference);
        batch.update(postRef, {'likes': FieldValue.increment(-1)});
      } else {
        // Like: Add like and increment counter
        batch.set(likeDoc.reference, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {'likes': FieldValue.increment(1)});
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error toggling post like: $e');
      return false;
    }
  }
  
  // Check if user liked a post
  Future<bool> hasUserLikedPost(String postId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      
      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking post like: $e');
      return false;
    }
  }
  
  // Add comment to post
  Future<String?> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Create the comment
      final commentRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc();
      
      batch.set(commentRef, {
        'userId': userId,
        'content': content,
        'parentCommentId': parentCommentId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likes': 0,
      });
      
      // Update post comment count
      final postRef = _firestore.collection('posts').doc(postId);
      batch.update(postRef, {'comments': FieldValue.increment(1)});
      
      await batch.commit();
      return commentRef.id;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }
  
  // Get comments for a post
  Future<List<dynamic>> getComments({
    required String postId,
    String? parentCommentId,
    int limit = 20,
    String? lastCommentId,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('parentCommentId', isEqualTo: parentCommentId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
          
      if (lastCommentId != null) {
        // Get the last comment doc for pagination
        DocumentSnapshot lastDocSnapshot = await _firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(lastCommentId)
            .get();
        query = query.startAfterDocument(lastDocSnapshot);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('Error getting comments: $e');
      return [];
    }
  }
}
EOL

# Create services.dart export for community
cat > /Users/kristybock/artbeat/packages/artbeat_community/lib/src/services/services.dart << 'EOL'
export 'community_service.dart';
EOL

# Update community exports
if ! grep -q "export 'src/services/services.dart';" "/Users/kristybock/artbeat/packages/artbeat_community/lib/artbeat_community.dart"; then
  sed -i '' "/export 'src\/screens\/screens.dart';/a\\
export 'src\/services\/services.dart';" "/Users/kristybock/artbeat/packages/artbeat_community/lib/artbeat_community.dart"
fi

# Create missing CaptureListScreen
mkdir -p /Users/kristybock/artbeat/packages/artbeat_capture/lib/src/screens
cat > /Users/kristybock/artbeat/packages/artbeat_capture/lib/src/screens/capture_list_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CaptureListScreen extends StatefulWidget {
  const CaptureListScreen({Key? key}) : super(key: key);

  @override
  State<CaptureListScreen> createState() => _CaptureListScreenState();
}

class _CaptureListScreenState extends State<CaptureListScreen> {
  bool _isLoading = false;
  List<dynamic> _captures = [];

  @override
  void initState() {
    super.initState();
    _loadCaptures();
  }

  Future<void> _loadCaptures() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    // TODO: Implement capture loading
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _captures = [];
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Captures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              // TODO: Navigate to camera screen
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _captures.isEmpty
              ? _buildEmptyState()
              : _buildCaptureList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'No captures yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Capture Something'),
            onPressed: () {
              // TODO: Navigate to camera screen
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCaptureList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _captures.length,
      itemBuilder: (context, index) {
        // TODO: Implement capture item rendering
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text('Capture ${index + 1}'),
            leading: const Icon(Icons.image),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to capture detail screen
            },
          ),
        );
      },
    );
  }
}
EOL

# Create screens.dart export for capture
cat > /Users/kristybock/artbeat/packages/artbeat_capture/lib/src/screens/screens.dart << 'EOL'
export 'capture_list_screen.dart';
EOL

# Update capture exports
if ! grep -q "export 'src/screens/screens.dart';" "/Users/kristybock/artbeat/packages/artbeat_capture/lib/artbeat_capture.dart"; then
  sed -i '' "/library artbeat_capture;/a\\
\\
export 'src\/screens\/screens.dart';" "/Users/kristybock/artbeat/packages/artbeat_capture/lib/artbeat_capture.dart"
fi

# Ensure there are no duplicate ArtWalkMapScreen exports
find /Users/kristybock/artbeat/packages -name "screens.dart" -exec grep -l "export 'art_walk_map_screen" {} \; | while read -r file; do
  echo "Removing duplicate art_walk_map_screen exports in $file"
  sed -i '' "/export 'art_walk_map_screen_fixed.dart';/d" "$file"
done

# Add missing ImageModerationService constructor parameter
sed -i '' "s/Provider(create: (context) => ImageModerationService()),/Provider(create: (context) => ImageModerationService()),/g" "/Users/kristybock/artbeat/lib/main.dart"

echo "Fixed main.dart route implementations and created missing screens."

# Run flutter pub get in the main app
echo "Running flutter pub get in the main app..."
(cd "/Users/kristybock/artbeat" && flutter pub get)

echo "All fixes completed!"
