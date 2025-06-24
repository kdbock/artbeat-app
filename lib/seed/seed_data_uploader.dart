import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadSeedData() async {
  final firestore = FirebaseFirestore.instance;

  // USERS
  final users = [
    {
      'id': 'artist_user_001',
      'email': 'artist001@example.com',
      'username': 'Artist One',
      'avatarUrl': 'https://picsum.photos/200?1',
      'userType': 'artist',
      'location': 'Kinston, NC',
    },
    {
      'id': 'gallery_user_001',
      'email': 'gallery001@example.com',
      'username': 'Gallery One',
      'avatarUrl': 'https://picsum.photos/200?2',
      'userType': 'gallery',
      'location': 'Durham, NC',
    },
  ];

  for (var user in users) {
    await firestore.collection('users').doc(user['id']).set({
      ...user,
      'createdAt': Timestamp.now(),
    });
  }

  // ARTIST PROFILES
  await firestore.collection('artistProfiles').doc('artist_user_001').set({
    'bio': 'Painter and muralist from Eastern NC',
    'subscriptionTier': 'pro',
    'portfolioLinks': ['https://artistone.com'],
    'userId': 'artist_user_001',
    'createdAt': Timestamp.now(),
  });

  // ARTWORKS
  await firestore.collection('artworks').add({
    'title': 'Sunset Mural',
    'imageUrl': 'https://picsum.photos/300?art',
    'userId': 'artist_user_001',
    'price': 150.0,
    'location': 'Kinston, NC',
    'medium': 'Spray Paint',
    'createdAt': Timestamp.now(),
  });

  // POSTS (Canvas Feed)
  await firestore.collection('posts').add({
    'userId': 'artist_user_001',
    'caption': 'Just finished my new mural!',
    'imageUrl': 'https://picsum.photos/400?post',
    'createdAt': Timestamp.now(),
  });

  // PUBLIC ART
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
      'description': 'Modern street art installation with interactive elements',
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

  for (var art in publicArtData) {
    await firestore.collection('publicArt').add(art);
  }

  // ART WALKS
  await firestore.collection('artWalks').add({
    'userId': 'artist_user_001',
    'title': 'Downtown Kinston Tour',
    'description': 'A guided walk of murals and installations downtown.',
    'artIds': [],
    'distanceKm': 2.5,
    'estimatedMinutes': 45,
    'coverImageUrl': 'https://picsum.photos/500?walk',
    'isPublic': true,
    'viewCount': 0,
    'likeCount': 0,
    'shareCount': 0,
    'createdAt': Timestamp.now(),
  });

  print('✅ Seed data uploaded.');
}
