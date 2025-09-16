import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Utility class to test Firebase Storage connectivity and diagnose issues
class FirebaseStorageTest {
  static Future<void> runDiagnostics() async {
    AppLogger.debug('🔍 Starting Firebase Storage diagnostics...');

    try {
      // Test 1: Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('❌ User not authenticated');
        return;
      }
      AppLogger.auth('✅ User authenticated: ${user.uid}');

      // Test 2: Test basic Firebase Storage reference creation
      try {
        final ref = FirebaseStorage.instance.ref().child(
          'test_diagnostics.txt',
        );
        AppLogger.firebase('✅ Firebase Storage reference created successfully');

        // Test 3: Try to get metadata for a non-existent file (should fail gracefully)
        try {
          await ref.getMetadata();
          AppLogger.warning('⚠️ Unexpected: test file exists');
        } catch (e) {
          if (e.toString().contains('object-not-found')) {
            debugPrint(
              '✅ Firebase Storage connectivity confirmed (expected object-not-found)',
            );
          } else {
            AppLogger.error('❌ Firebase Storage connectivity issue: $e');
          }
        }

        // Test 4: Try to upload a small test file
        try {
          AppLogger.info('🔄 Testing small file upload...');
          final testData =
              'Firebase Storage test - ${DateTime.now().toIso8601String()}';
          final uploadTask = ref.putString(testData);

          final snapshot = await uploadTask.timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Test upload timed out'),
          );

          final downloadUrl = await snapshot.ref.getDownloadURL();
          AppLogger.info('✅ Test upload successful: $downloadUrl');

          // Clean up test file
          await ref.delete();
          AppLogger.info('✅ Test file cleaned up');
        } catch (e) {
          AppLogger.error('❌ Test upload failed: $e');

          if (e.toString().contains('cannot parse response')) {
            AppLogger.error('🚨 "Cannot parse response" error detected!');
            AppLogger.info('💡 This usually indicates:');
            AppLogger.network('   - Network connectivity issues');
            AppLogger.firebase('   - Firebase Storage service interruption');
            AppLogger.firebase('   - Incorrect Firebase configuration');
            AppLogger.info('   - Storage rules blocking the operation');
          }
        }
      } catch (e) {
        AppLogger.error('❌ Firebase Storage reference creation failed: $e');
      }
    } catch (e) {
      AppLogger.error('❌ Diagnostics failed: $e');
    }

    AppLogger.firebase('🏁 Firebase Storage diagnostics completed');
  }

  /// Test different upload paths to see which ones work
  static Future<void> testUploadPaths() async {
    AppLogger.debug('🔍 Testing different upload paths...');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.error('❌ User not authenticated');
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
        AppLogger.info('🔄 Testing path: $path');
        final ref = FirebaseStorage.instance.ref().child(path);
        final uploadTask = ref.putString(testData);

        await uploadTask.timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Path test timed out'),
        );

        AppLogger.info('✅ Path $path: SUCCESS');

        // Clean up
        await ref.delete();
      } catch (e) {
        AppLogger.error('❌ Path $path: FAILED - $e');
      }
    }

    AppLogger.info('🏁 Path testing completed');
  }
}
