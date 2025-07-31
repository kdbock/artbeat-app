#!/usr/bin/env dart
// Script to test comment permissions and identify the exact issue

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

Future<void> main() async {
  print('🧪 Testing Comment Permissions...\n');

  try {
    // Initialize Firebase
    await SecureFirebaseConfig.ensureInitialized(
      teamId: 'H49R32NPY6',
      debug: true,
    );

    print('✅ Firebase initialized successfully');

    // Check authentication status
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      print('❌ No user is currently signed in');
      print('💡 Please sign in to the app first, then run this test');
      exit(1);
    }

    print('✅ User authenticated: ${user.uid}');
    print('   Email: ${user.email}');

    // Test Firestore access
    final firestore = FirebaseFirestore.instance;

    // Test 1: Try to read posts collection
    print('\n🧪 Test 1: Reading posts collection...');
    try {
      final postsQuery = await firestore.collection('posts').limit(1).get();
      print('✅ Can read posts collection (${postsQuery.docs.length} docs)');

      if (postsQuery.docs.isNotEmpty) {
        final testPostId = postsQuery.docs.first.id;
        print('   Using test post ID: $testPostId');

        // Test 2: Try to read comments subcollection
        print('\n🧪 Test 2: Reading comments subcollection...');
        try {
          final commentsQuery = await firestore
              .collection('posts')
              .doc(testPostId)
              .collection('comments')
              .limit(1)
              .get();
          print(
            '✅ Can read comments subcollection (${commentsQuery.docs.length} docs)',
          );
        } catch (e) {
          print('❌ Cannot read comments subcollection: $e');
        }

        // Test 3: Try to create a test comment
        print('\n🧪 Test 3: Creating test comment...');
        try {
          final commentRef = await firestore
              .collection('posts')
              .doc(testPostId)
              .collection('comments')
              .add({
                'userId': user.uid,
                'userName': user.displayName ?? 'Test User',
                'userPhotoUrl': user.photoURL ?? '',
                'content': 'Test comment from debug script',
                'createdAt': FieldValue.serverTimestamp(),
                'parentCommentId': null,
              });
          print('✅ Successfully created test comment: ${commentRef.id}');

          // Test 4: Try to update post comment count
          print('\n🧪 Test 4: Updating post comment count...');
          try {
            await firestore.collection('posts').doc(testPostId).update({
              'commentCount': FieldValue.increment(1),
            });
            print('✅ Successfully updated post comment count');

            // Clean up: Remove the test comment and decrement count
            await commentRef.delete();
            await firestore.collection('posts').doc(testPostId).update({
              'commentCount': FieldValue.increment(-1),
            });
            print('✅ Cleaned up test comment');
          } catch (e) {
            print('❌ Cannot update post comment count: $e');
            print('   This is likely the source of the permission error!');

            // Clean up the comment even if count update failed
            try {
              await commentRef.delete();
              print('✅ Cleaned up test comment');
            } catch (deleteError) {
              print('⚠️ Could not clean up test comment: $deleteError');
            }
          }
        } catch (e) {
          print('❌ Cannot create test comment: $e');
          print('   Error type: ${e.runtimeType}');
        }
      }
    } catch (e) {
      print('❌ Cannot read posts collection: $e');
    }

    // Test 5: Check user document and permissions
    print('\n🧪 Test 5: Checking user permissions...');
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        print('✅ User document exists');
        print('   User type: ${userData['userType'] ?? 'not set'}');
        print(
          '   Is content creator: ${userData['userType'] == 'artist' || userData['userType'] == 'gallery'}',
        );
      } else {
        print('❌ User document does not exist');
        print('💡 This might be why permissions are failing');
      }
    } catch (e) {
      print('❌ Cannot read user document: $e');
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  }

  exit(0);
}
