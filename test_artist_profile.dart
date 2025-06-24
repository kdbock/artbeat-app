import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  const userId = 'ARFuyX0C44PbYlHSUSlQx55b9vt2'; // Kristy's user ID

  print('🔍 Checking artist profile for user: $userId');

  try {
    // Query for artist profile
    final querySnapshot = await firestore
        .collection('artistProfiles')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print('❌ No artist profile found. Creating one...');

      // Create a new artist profile
      await firestore.collection('artistProfiles').add({
        'userId': userId,
        'displayName': 'Kristy Kelly',
        'bio':
            'Artist and art enthusiast exploring the creative world through ARTbeat.',
        'userType': 'artist', // artist, gallery, collector
        'location': 'Asheville, NC',
        'mediums': ['Digital', 'Photography', 'Mixed Media'],
        'styles': ['Contemporary', 'Abstract', 'Street Art'],
        'socialLinks': {
          'website': '',
          'instagram': '',
          'facebook': '',
          'twitter': '',
          'etsy': '',
        },
        'profileImageUrl':
            'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/profile_images%2FARFuyX0C44PbYlHSUSlQx55b9vt2%2Fprofile.jpg?alt=media&token=2b5eafc4-0b82-441c-8bf5-d60a38b51586',
        'coverImageUrl': null,
        'isPortfolioPublic': true,
        'isVerified': false,
        'isFeatured': false,
        'followerCount': 0,
        'followingCount': 0,
        'artworkCount': 0,
        'totalLikes': 0,
        'totalViews': 0,
        'commissionInfo': {
          'isAcceptingCommissions': true,
          'minimumPrice': 100.0,
          'maximumPrice': 1000.0,
          'responseTime': '3-5 days',
          'description': 'Available for custom artwork commissions.',
        },
        'subscription': {'tier': 'free', 'isActive': true},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Created new artist profile for Kristy Kelly');
    } else {
      final doc = querySnapshot.docs.first;
      final data = doc.data();

      print('✅ Found existing artist profile:');
      print('   - ID: ${doc.id}');
      print('   - Display Name: ${data['displayName']}');
      print('   - Bio: ${data['bio']}');
      print('   - User Type: ${data['userType']}');
      print('   - Location: ${data['location']}');
      print('   - Portfolio Public: ${data['isPortfolioPublic']}');
      print('   - Mediums: ${data['mediums']}');
      print('   - Styles: ${data['styles']}');

      // Update to ensure it's public if needed
      if (data['isPortfolioPublic'] != true) {
        print('📝 Updating profile to be public...');
        await doc.reference.update({
          'isPortfolioPublic': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Profile updated to be public');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  exit(0);
}
