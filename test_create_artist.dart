import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'packages/artbeat_core/lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await createTestArtist();
}

Future<void> createTestArtist() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Create a test artist profile
    final artistData = {
      'userId': 'test_artist_user_123',
      'displayName': 'Maya Chen',
      'bio': 'Digital muralist creating vibrant street art that brings communities together. Specializing in large-scale community murals and digital art installations.',
      'userType': 'artist',
      'location': '28401', // ZIP code format
      'mediums': ['Digital Art', 'Murals', 'Street Art'],
      'styles': ['Contemporary', 'Abstract', 'Urban'],
      'profileImageUrl': '',
      'coverImageUrl': '',
      'socialLinks': {
        'instagram': '@mayachen_art',
        'website': 'www.mayachenart.com'
      },
      'isVerified': true,
      'isFeatured': true,
      'subscriptionTier': 'artistPro',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    await firestore.collection('artistProfiles').add(artistData);
    print('✅ Test artist profile created successfully!');
    
    // Create another test artist
    final artistData2 = {
      'userId': 'test_artist_user_456',
      'displayName': 'David Martinez',
      'bio': 'Sculptor working with metal and stone. Creating public art installations that inspire and provoke thought.',
      'userType': 'artist',
      'location': '28403',
      'mediums': ['Sculpture', 'Metal Work', 'Stone Carving'],
      'styles': ['Modern', 'Abstract', 'Minimalist'],
      'profileImageUrl': '',
      'coverImageUrl': '',
      'socialLinks': {
        'instagram': '@david_sculptures',
      },
      'isVerified': false,
      'isFeatured': true,
      'subscriptionTier': 'artistBasic',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    await firestore.collection('artistProfiles').add(artistData2);
    print('✅ Second test artist profile created successfully!');
    
    // List all artist profiles to verify
    final snapshot = await firestore.collection('artistProfiles').get();
    print('📊 Total artist profiles in database: ${snapshot.docs.length}');
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      print('Artist: ${data['displayName']} (${data['location']}) - Featured: ${data['isFeatured']}');
    }
    
  } catch (e) {
    print('❌ Error creating test artist: $e');
  }
}
