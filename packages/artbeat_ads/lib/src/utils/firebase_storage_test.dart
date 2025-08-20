import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Utility class to test Firebase Storage connectivity and diagnose issues
class FirebaseStorageTest {
  static Future<void> runDiagnostics() async {
    debugPrint('🔍 Starting Firebase Storage diagnostics...');

    try {
      // Test 1: Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ User not authenticated');
        return;
      }
      debugPrint('✅ User authenticated: ${user.uid}');

      // Test 2: Test basic Firebase Storage reference creation
      try {
        final ref = FirebaseStorage.instance.ref().child(
          'test_diagnostics.txt',
        );
        debugPrint('✅ Firebase Storage reference created successfully');

        // Test 3: Try to get metadata for a non-existent file (should fail gracefully)
        try {
          await ref.getMetadata();
          debugPrint('⚠️ Unexpected: test file exists');
        } catch (e) {
          if (e.toString().contains('object-not-found')) {
            debugPrint(
              '✅ Firebase Storage connectivity confirmed (expected object-not-found)',
            );
          } else {
            debugPrint('❌ Firebase Storage connectivity issue: $e');
          }
        }

        // Test 4: Try to upload a small test file
        try {
          debugPrint('🔄 Testing small file upload...');
          final testData =
              'Firebase Storage test - ${DateTime.now().toIso8601String()}';
          final uploadTask = ref.putString(testData);

          final snapshot = await uploadTask.timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Test upload timed out'),
          );

          final downloadUrl = await snapshot.ref.getDownloadURL();
          debugPrint('✅ Test upload successful: $downloadUrl');

          // Clean up test file
          await ref.delete();
          debugPrint('✅ Test file cleaned up');
        } catch (e) {
          debugPrint('❌ Test upload failed: $e');

          if (e.toString().contains('cannot parse response')) {
            debugPrint('🚨 "Cannot parse response" error detected!');
            debugPrint('💡 This usually indicates:');
            debugPrint('   - Network connectivity issues');
            debugPrint('   - Firebase Storage service interruption');
            debugPrint('   - Incorrect Firebase configuration');
            debugPrint('   - Storage rules blocking the operation');
          }
        }
      } catch (e) {
        debugPrint('❌ Firebase Storage reference creation failed: $e');
      }
    } catch (e) {
      debugPrint('❌ Diagnostics failed: $e');
    }

    debugPrint('🏁 Firebase Storage diagnostics completed');
  }

  /// Test different upload paths to see which ones work
  static Future<void> testUploadPaths() async {
    debugPrint('🔍 Testing different upload paths...');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('❌ User not authenticated');
      return;
    }

    final testData = 'Path test - ${DateTime.now().millisecondsSinceEpoch}';
    final paths = [
      'test_root.txt',
      'uploads/test_uploads.txt',
      'temp_uploads/test_temp.txt',
      'debug_uploads/test_debug.txt',
      'ads/${user.uid}/test_ads.txt',
    ];

    for (final path in paths) {
      try {
        debugPrint('🔄 Testing path: $path');
        final ref = FirebaseStorage.instance.ref().child(path);
        final uploadTask = ref.putString(testData);

        await uploadTask.timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Path test timed out'),
        );

        debugPrint('✅ Path $path: SUCCESS');

        // Clean up
        await ref.delete();
      } catch (e) {
        debugPrint('❌ Path $path: FAILED - $e');
      }
    }

    debugPrint('🏁 Path testing completed');
  }
}
