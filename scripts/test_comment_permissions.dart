#!/usr/bin/env dart
// Script to test comment permissions and identify the exact issue

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:logging/logging.dart';

Future<void> main() async {
  final log = Logger('TestCommentPermissions');
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    stdout.writeln('[${record.level.name}] ${record.time}: ${record.message}');
  });
  log.info('🧪 Testing Comment Permissions...\n');

  try {
    // Initialize Firebase
    await SecureFirebaseConfig.ensureInitialized(
      teamId: 'H49R32NPY6',
      debug: true,
    );

    log.info('✅ Firebase initialized successfully');

    // Check authentication status
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      log.severe('❌ No user is currently signed in');
      log.info('💡 Please sign in to the app first, then run this test');
      exit(1);
    }

    log.info('✅ User authenticated: ${user.uid}');
    log.info('   Email: ${user.email}');

    // Test Firestore access
    final firestore = FirebaseFirestore.instance;

    // Test 1: Try to read posts collection
    log.info('\n🧪 Test 1: Reading posts collection...');
    try {
      final postsQuery = await firestore.collection('posts').limit(1).get();
      log.info('✅ Can read posts collection (${postsQuery.docs.length} docs)');

      if (postsQuery.docs.isNotEmpty) {
        final testPostId = postsQuery.docs.first.id;
        log.info('   Using test post ID: $testPostId');

        // Test 2: Try to read comments subcollection
        log.info('\n🧪 Test 2: Reading comments subcollection...');
        try {
          final commentsQuery = await firestore
              .collection('posts')
              .doc(testPostId)
              .collection('comments')
              .limit(1)
              .get();
          log.info(
            '✅ Can read comments subcollection (${commentsQuery.docs.length} docs)',
          );
        } catch (e) {
          log.severe('❌ Cannot read comments subcollection: $e');
        }

        // Test 3: Try to create a test comment
        log.info('\n🧪 Test 3: Creating test comment...');
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
          log.info('✅ Successfully created test comment: ${commentRef.id}');

          // Test 4: Try to update post comment count
          log.info('\n🧪 Test 4: Updating post comment count...');
          try {
            await firestore.collection('posts').doc(testPostId).update({
              'commentCount': FieldValue.increment(1),
            });
            log.info('✅ Successfully updated post comment count');

            // Clean up: Remove the test comment and decrement count
            await commentRef.delete();
            await firestore.collection('posts').doc(testPostId).update({
              'commentCount': FieldValue.increment(-1),
            });
            log.info('✅ Cleaned up test comment');
          } catch (e) {
            log.severe('❌ Cannot update post comment count: $e');
            log.info('   This is likely the source of the permission error!');

            // Clean up the comment even if count update failed
            try {
              await commentRef.delete();
              log.info('✅ Cleaned up test comment');
            } catch (deleteError) {
              log.warning('⚠️ Could not clean up test comment: $deleteError');
            }
          }
        } catch (e) {
          log.severe('❌ Cannot create test comment: $e');
          log.info('   Error type: ${e.runtimeType}');
        }
      }
    } catch (e) {
      log.severe('❌ Cannot read posts collection: $e');
    }

    // Test 5: Check user document and permissions
    log.info('\n🧪 Test 5: Checking user permissions...');
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        log.info('✅ User document exists');
        log.info('   User type: ${userData['userType'] ?? 'not set'}');
        log.info(
          '   Is content creator: ${userData['userType'] == 'artist' || userData['userType'] == 'gallery'}',
        );
      } else {
        log.severe('❌ User document does not exist');
        log.info('💡 This might be why permissions are failing');
      }
    } catch (e) {
      log.severe('❌ Cannot read user document: $e');
    }
  } catch (e, stackTrace) {
    final log = Logger('TestCommentPermissions');
    log.severe('❌ Error: $e');
    log.severe('Stack trace: $stackTrace');
  }

  exit(0);
}
