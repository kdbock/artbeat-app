import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🔧 Starting ad database fix...');

  try {
    // Initialize Firebase with your project configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
        appId: '1:665020451634:ios:2aa5cc17ac7d0dad78652b',
        messagingSenderId: '665020451634',
        projectId: 'wordnerd-artbeat',
        storageBucket: 'wordnerd-artbeat.firebasestorage.app',
      ),
    );
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;

    // Get all ads
    final adsSnapshot = await firestore.collection('ads').get();
    print('📊 Found ${adsSnapshot.docs.length} ads to check');

    int fixedCount = 0;

    for (final doc in adsSnapshot.docs) {
      final data = doc.data();
      final adId = doc.id;

      print('\n🔍 Checking ad: ${data['title']} (ID: $adId)');

      // Check if artworkUrls field exists and is properly formatted
      bool needsFix = false;
      List<String> artworkUrls = [];

      if (data.containsKey('artworkUrls')) {
        final rawUrls = data['artworkUrls'];
        if (rawUrls is String && rawUrls.isNotEmpty) {
          artworkUrls = rawUrls
              .split(',')
              .map((url) => url.trim())
              .where((url) => url.isNotEmpty)
              .toList();
          print(
            '  📱 Found ${artworkUrls.length} artwork URLs in string format',
          );

          // Convert from comma-separated string to List<String> format
          if (artworkUrls.length > 1) {
            needsFix = true; // Convert string to list format
            print('  🔄 Converting from string to list format');
          }
        } else if (rawUrls is List) {
          artworkUrls = rawUrls
              .map((url) => url.toString())
              .where((url) => url.isNotEmpty)
              .toList();
          print('  📱 Found ${artworkUrls.length} artwork URLs in list format');
        } else {
          print(
            '  ⚠️  artworkUrls field exists but is in wrong format: ${rawUrls.runtimeType}',
          );
          needsFix = true;
        }
      } else {
        print('  ❌ Missing artworkUrls field');
        needsFix = true;

        // Try to use imageUrl as first artwork URL if available
        if (data.containsKey('imageUrl') &&
            data['imageUrl'] != null &&
            data['imageUrl'].toString().isNotEmpty) {
          artworkUrls = [data['imageUrl'].toString()];
          print(
            '  🔄 Using imageUrl as first artwork URL: ${artworkUrls.first}',
          );
        }
      }

      if (needsFix || artworkUrls.isEmpty) {
        print('  🛠️  Fixing ad...');

        // Update the document with List<String> format
        await doc.reference.update({'artworkUrls': artworkUrls});

        fixedCount++;
        print('  ✅ Fixed! Added ${artworkUrls.length} artwork URLs');
      } else {
        print('  ✅ Already correct');
      }
    }

    print('\n🎉 Fix complete!');
    print('📊 Total ads processed: ${adsSnapshot.docs.length}');
    print('🔧 Ads fixed: $fixedCount');
  } catch (e) {
    print('❌ Error: $e');
  }
}
