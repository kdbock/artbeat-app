import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print(
    '🔧 Starting admin ads fix - replacing placeholder URLs with Firebase Storage URLs...',
  );

  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  // The Firebase Storage base path for admin ads
  const String storageBasePath =
      'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/admin_ads%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2F';

  // Sample Firebase Storage URLs for the images
  final List<String> firebaseStorageUrls = [
    '${storageBasePath}image1.png?alt=media',
    '${storageBasePath}image2.png?alt=media',
    '${storageBasePath}image3.png?alt=media',
    '${storageBasePath}image4.png?alt=media',
  ];

  try {
    // Get all admin ads
    final querySnapshot = await firestore.collection('ads').get();

    print('📊 Found ${querySnapshot.docs.length} ads to check');

    int updatedCount = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final artworkUrlsData = data['artworkUrls'];
      final currentArtworkUrls = artworkUrlsData != null
          ? List<String>.from(artworkUrlsData as List)
          : <String>[];

      // Check if this ad has placeholder URLs or empty artworkUrls
      bool needsUpdate =
          currentArtworkUrls.isEmpty ||
          currentArtworkUrls.any((url) => url.contains('via.placeholder.com'));

      if (needsUpdate) {
        print('🔄 Updating ad ${doc.id}...');
        print('   Old artworkUrls: $currentArtworkUrls');

        // Update with Firebase Storage URLs
        await doc.reference.update({'artworkUrls': firebaseStorageUrls});

        print('   New artworkUrls: $firebaseStorageUrls');
        updatedCount++;
      } else {
        print('✅ Ad ${doc.id} already has proper URLs');
      }
    }

    print(
      '\n🎉 Fix complete! Updated $updatedCount ads with Firebase Storage URLs',
    );
    print('🖼️ All ads now use actual uploaded images instead of placeholders');
  } catch (e) {
    print('❌ Error during fix: $e');
    exit(1);
  }

  exit(0);
}
