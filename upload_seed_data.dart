import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('🔥 Firebase initialized successfully');

    final firestore = FirebaseFirestore.instance;

    // PUBLIC ART DATA
    final publicArtData = [
      {
        'userId': 'artist_user_001',
        'title': 'Rainbow Mural',
        'description':
            'A vibrant rainbow mural celebrating diversity and community',
        'imageUrl': 'https://picsum.photos/400/300?art1',
        'artistName': 'Maya Chen',
        'location': const GeoPoint(35.2651, -77.5866), // Near Kinston, NC
        'address': '123 Main St, Kinston, NC',
        'tags': ['mural', 'rainbow', 'community'],
        'artType': 'Mural',
        'isVerified': true,
        'viewCount': 15,
        'likeCount': 8,
        'usersFavorited': ['artist_user_001'],
        'createdAt': Timestamp.now(),
      },
      {
        'userId': 'artist_user_001',
        'title': 'Bronze Statue',
        'description': 'A bronze statue commemorating local history',
        'imageUrl': 'https://picsum.photos/400/300?art2',
        'artistName': 'David Martinez',
        'location': const GeoPoint(35.2641, -77.5856), // Near Kinston, NC
        'address': '456 Heritage Ave, Kinston, NC',
        'tags': ['sculpture', 'bronze', 'history'],
        'artType': 'Sculpture',
        'isVerified': true,
        'viewCount': 22,
        'likeCount': 12,
        'usersFavorited': ['artist_user_001'],
        'createdAt': Timestamp.now(),
      },
      {
        'userId': 'artist_user_001',
        'title': 'Street Art Installation',
        'description':
            'Modern street art installation with interactive elements',
        'imageUrl': 'https://picsum.photos/400/300?art3',
        'artistName': 'Local Artist Collective',
        'location': const GeoPoint(35.2661, -77.5876), // Near Kinston, NC
        'address': '789 Art District, Kinston, NC',
        'tags': ['street art', 'interactive', 'modern'],
        'artType': 'Installation',
        'isVerified': false,
        'viewCount': 31,
        'likeCount': 18,
        'usersFavorited': ['artist_user_001'],
        'createdAt': Timestamp.now(),
      },
    ];

    print('📊 Uploading ${publicArtData.length} public art pieces...');

    for (var i = 0; i < publicArtData.length; i++) {
      var art = publicArtData[i];
      try {
        await firestore.collection('publicArt').add(art);
        print('✅ Uploaded art piece ${i + 1}: ${art['title']}');
      } catch (e) {
        print(
          '❌ Failed to upload art piece ${i + 1}: ${art['title']} - Error: $e',
        );
      }
    }

    print('🎨 Seed data upload completed!');
    exit(0);
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
