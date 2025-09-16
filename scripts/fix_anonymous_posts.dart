import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to fix existing posts that show "Anonymous" as the author name
/// This updates the userName field with the correct display name from user profiles
Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;

    print('🔄 Starting anonymous posts fix...');

    // Query posts where userName is "Anonymous"
    final anonymousPostsQuery = await firestore
        .collection('posts')
        .where('userName', isEqualTo: 'Anonymous')
        .get();

    print(
      '📊 Found ${anonymousPostsQuery.docs.length} posts with "Anonymous" userName',
    );

    int updatedCount = 0;
    int errorCount = 0;

    for (final doc in anonymousPostsQuery.docs) {
      try {
        final postData = doc.data();
        final userId = postData['userId'] as String?;

        if (userId == null) {
          print('⚠️  Post ${doc.id} has no userId, skipping...');
          continue;
        }

        // Get user profile data
        final userDoc = await firestore.collection('users').doc(userId).get();

        if (!userDoc.exists) {
          print(
            '⚠️  User profile not found for userId: $userId, skipping post ${doc.id}',
          );
          continue;
        }

        final userData = userDoc.data() ?? {};

        // Determine the correct user name with multiple fallbacks
        final correctUserName =
            userData['displayName'] as String? ??
            userData['name'] as String? ??
            userData['fullName'] as String? ??
            'Anonymous'; // Keep as Anonymous if still not found

        if (correctUserName == 'Anonymous') {
          print(
            '⚠️  Could not find display name for user $userId, keeping as Anonymous',
          );
          continue;
        }

        // Update the post with the correct user name
        await doc.reference.update({'userName': correctUserName});

        updatedCount++;
        print('✅ Updated post ${doc.id}: "$correctUserName"');
      } catch (e) {
        errorCount++;
        print('❌ Error updating post ${doc.id}: $e');
      }
    }

    print('\n🎉 Fix complete!');
    print('📈 Updated: $updatedCount posts');
    print('❌ Errors: $errorCount posts');
  } catch (e) {
    print('💥 Fatal error: $e');
    rethrow;
  }
}
