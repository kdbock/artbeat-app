import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Migration script to update admin ads with correct Firebase Storage URLs
void main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();

    final firestore = FirebaseFirestore.instance;

    // Get all admin ads
    final adsSnapshot = await firestore.collection('ads').get();

    print('🔍 Found ${adsSnapshot.docs.length} ads to check');

    // Firebase Storage URLs for the actual uploaded images
    final firebaseStorageUrls = [
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362607_upload.png?alt=media&token=e5d392d1-601a-4096-96ef-2acab37bf810',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362608_upload.png?alt=media&token=f6e403e2-702b-4197-a7f7-3a4e86f2d921',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362609_upload.png?alt=media&token=074f4f43-813c-42a8-b8f8-4b5f97f3e032',
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F1755734362610_upload.png?alt=media&token=185f5f54-924d-43b9-c9f9-5c6fa8f4f143',
    ];

    int updatedCount = 0;

    for (final doc in adsSnapshot.docs) {
      final data = doc.data();
      final artworkUrls =
          (data['artworkUrls'] as List<dynamic>?)?.cast<String>() ?? <String>[];

      print('📄 Ad ${doc.id}: ${artworkUrls.length} URLs');

      // Check if this ad has placeholder URLs that need updating
      final hasPlaceholderUrls = artworkUrls.any(
        (url) => url.contains('via.placeholder.com'),
      );

      if (hasPlaceholderUrls || artworkUrls.isEmpty) {
        print('🔄 Updating ad ${doc.id} with Firebase Storage URLs');

        await doc.reference.update({
          'artworkUrls': firebaseStorageUrls,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        updatedCount++;
        print('✅ Updated ad ${doc.id}');
      } else {
        print('ℹ️ Ad ${doc.id} already has proper URLs, skipping');
      }
    }

    print(
      '🎉 Migration complete! Updated $updatedCount ads with Firebase Storage URLs',
    );
  } catch (e) {
    print('❌ Error during migration: $e');
  }
}
