import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Simple script to test Firestore connectivity and create sample posts
Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    
    print('Firebase initialized successfully');
    
    // Test connection to Firestore
    final firestore = FirebaseFirestore.instance;
    
    // Check if we can read public posts
    print('Checking for existing posts...');
    
    try {
      final postsSnapshot = await firestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .limit(5)
          .get();
      
      print('Found ${postsSnapshot.docs.length} public posts');
      
      for (final doc in postsSnapshot.docs) {
        final data = doc.data();
        print('Post: ${doc.id} - ${data['content']?.toString().substring(0, 50) ?? 'No content'}...');
      }
      
      // If no posts exist, create some sample posts
      if (postsSnapshot.docs.isEmpty) {
        print('No posts found. Creating sample posts...');
        await createSamplePosts(firestore);
      }
      
    } catch (e) {
      print('Error reading posts: $e');
      
      // Try to create sample posts anyway
      print('Attempting to create sample posts...');
      await createSamplePosts(firestore);
    }
    
  } catch (e) {
    print('Error initializing Firebase: $e');
    exit(1);
  }
}

Future<void> createSamplePosts(FirebaseFirestore firestore) async {
  try {
    // Sample posts data
    final samplePosts = [
      {
        'userId': 'sample_user_1',
        'userName': 'Art Lover',
        'userPhotoUrl': '',
        'content': 'Just finished this amazing watercolor painting! What do you think? 🎨',
        'imageUrls': [],
        'tags': ['watercolor', 'painting', 'art'],
        'location': 'San Francisco, CA',
        'zipCode': '94102',
        'createdAt': FieldValue.serverTimestamp(),
        'applauseCount': 5,
        'commentCount': 2,
        'shareCount': 1,
        'isPublic': true,
        'isUserVerified': false,
      },
      {
        'userId': 'sample_user_2',
        'userName': 'Digital Artist',
        'userPhotoUrl': '',
        'content': 'Exploring new digital art techniques. This piece took me 3 hours to complete! 💻✨',
        'imageUrls': [],
        'tags': ['digital', 'art', 'illustration'],
        'location': 'Los Angeles, CA',
        'zipCode': '90210',
        'createdAt': FieldValue.serverTimestamp(),
        'applauseCount': 12,
        'commentCount': 4,
        'shareCount': 3,
        'isPublic': true,
        'isUserVerified': true,
      },
      {
        'userId': 'sample_user_3',
        'userName': 'Gallery Curator',
        'userPhotoUrl': '',
        'content': 'Excited to announce our new exhibition opening next week! Come see amazing local artists showcase their work.',
        'imageUrls': [],
        'tags': ['gallery', 'exhibition', 'local', 'artists'],
        'location': 'New York, NY',
        'zipCode': '10001',
        'createdAt': FieldValue.serverTimestamp(),
        'applauseCount': 8,
        'commentCount': 6,
        'shareCount': 4,
        'isPublic': true,
        'isUserVerified': true,
      },
    ];
    
    final batch = firestore.batch();
    
    for (final postData in samplePosts) {
      final docRef = firestore.collection('posts').doc();
      batch.set(docRef, postData);
    }
    
    await batch.commit();
    print('Successfully created ${samplePosts.length} sample posts');
    
  } catch (e) {
    print('Error creating sample posts: $e');
  }
}
