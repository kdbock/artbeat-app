// Data migration utility for community posts
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPostMigration {
  static Future<void> migrateAllPosts() async {
    print('🔄 Starting community post data migration...');

    try {
      final firestore = FirebaseFirestore.instance;

      // Get all posts
      final postsSnapshot = await firestore.collection('posts').get();

      print('📋 Found ${postsSnapshot.docs.length} posts to check');

      int updatedCount = 0;
      int errorCount = 0;

      for (final doc in postsSnapshot.docs) {
        try {
          final data = doc.data();
          final updates = <String, dynamic>{};

          // Ensure applauseCount exists and is a number
          if (data['applauseCount'] == null) {
            updates['applauseCount'] = 0;
            print('  📝 Adding missing applauseCount to ${doc.id}');
          } else if (data['applauseCount'] is! int) {
            updates['applauseCount'] =
                int.tryParse(data['applauseCount'].toString()) ?? 0;
            print('  🔧 Fixing applauseCount type in ${doc.id}');
          }

          // Ensure commentCount exists and is a number
          if (data['commentCount'] == null) {
            updates['commentCount'] = 0;
            print('  📝 Adding missing commentCount to ${doc.id}');
          } else if (data['commentCount'] is! int) {
            updates['commentCount'] =
                int.tryParse(data['commentCount'].toString()) ?? 0;
            print('  🔧 Fixing commentCount type in ${doc.id}');
          }

          // Ensure shareCount exists and is a number
          if (data['shareCount'] == null) {
            updates['shareCount'] = 0;
            print('  📝 Adding missing shareCount to ${doc.id}');
          } else if (data['shareCount'] is! int) {
            updates['shareCount'] =
                int.tryParse(data['shareCount'].toString()) ?? 0;
            print('  🔧 Fixing shareCount type in ${doc.id}');
          }

          // Ensure isPublic exists and is a boolean
          if (data['isPublic'] == null) {
            updates['isPublic'] = true;
            print('  📝 Adding missing isPublic to ${doc.id}');
          } else if (data['isPublic'] is! bool) {
            updates['isPublic'] =
                data['isPublic'].toString().toLowerCase() == 'true';
            print('  🔧 Fixing isPublic type in ${doc.id}');
          }

          // Ensure isUserVerified exists and is a boolean
          if (data['isUserVerified'] == null) {
            updates['isUserVerified'] = false;
            print('  📝 Adding missing isUserVerified to ${doc.id}');
          } else if (data['isUserVerified'] is! bool) {
            updates['isUserVerified'] =
                data['isUserVerified'].toString().toLowerCase() == 'true';
            print('  🔧 Fixing isUserVerified type in ${doc.id}');
          }

          // Ensure userId exists
          if (data['userId'] == null || data['userId'] == '') {
            print(
              '  ⚠️  Post ${doc.id} has missing/empty userId - this needs manual review',
            );
          }

          // Ensure userName exists
          if (data['userName'] == null || data['userName'] == '') {
            print(
              '  ⚠️  Post ${doc.id} has missing/empty userName - this needs manual review',
            );
          }

          // Ensure userPhotoUrl is a string
          if (data['userPhotoUrl'] == null) {
            updates['userPhotoUrl'] = '';
            print('  📝 Adding missing userPhotoUrl to ${doc.id}');
          }

          // Ensure imageUrls is an array
          if (data['imageUrls'] == null) {
            updates['imageUrls'] = <String>[];
            print('  📝 Adding missing imageUrls to ${doc.id}');
          } else if (data['imageUrls'] is! List) {
            updates['imageUrls'] = <String>[];
            print('  🔧 Fixing imageUrls type in ${doc.id}');
          }

          // Ensure tags is an array
          if (data['tags'] == null) {
            updates['tags'] = <String>[];
            print('  📝 Adding missing tags to ${doc.id}');
          } else if (data['tags'] is! List) {
            updates['tags'] = <String>[];
            print('  🔧 Fixing tags type in ${doc.id}');
          }

          // Ensure content is a string
          if (data['content'] == null) {
            updates['content'] = '';
            print('  📝 Adding missing content to ${doc.id}');
          }

          // Ensure location is a string
          if (data['location'] == null) {
            updates['location'] = '';
            print('  📝 Adding missing location to ${doc.id}');
          }

          // Apply updates if any
          if (updates.isNotEmpty) {
            await doc.reference.update(updates);
            updatedCount++;
            print(
              '  ✅ Updated post ${doc.id} with ${updates.keys.length} fields',
            );
          }
        } catch (e) {
          errorCount++;
          print('  ❌ Error updating post ${doc.id}: $e');
        }
      }

      print('\n🎉 Migration completed!');
      print('  - Posts checked: ${postsSnapshot.docs.length}');
      print('  - Posts updated: $updatedCount');
      print('  - Errors: $errorCount');
    } catch (e) {
      print('❌ Migration failed: $e');
    }
  }
}
