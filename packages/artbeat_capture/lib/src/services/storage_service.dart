import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File file) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate file exists
      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      // Generate unique filename with timestamp and user ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'capture_${timestamp}_${user.uid}';
      
      // Use the capture_images path that already exists in your Storage
      final ref = _storage.ref().child('capture_images/${user.uid}/$fileName.jpg');

      debugPrint('StorageService: Starting upload...');
      debugPrint('StorageService: File path: ${file.path}');
      debugPrint('StorageService: File size: ${await file.length()} bytes');
      debugPrint('StorageService: Storage path: capture_images/${user.uid}/$fileName.jpg');
      debugPrint('StorageService: Storage bucket: ${_storage.bucket}');

      // Set metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );

      // Upload file
      final uploadTask = ref.putFile(file, metadata);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        debugPrint('StorageService: Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      // Wait for upload completion
      final snapshot = await uploadTask;
      debugPrint('StorageService: Upload completed successfully');

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('StorageService: Upload successful, URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('StorageService: Firebase error: ${e.code} - ${e.message}');
      throw Exception('Firebase upload failed: ${e.message}');
    } catch (e) {
      debugPrint('StorageService: General error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('StorageService: Image deleted successfully');
    } catch (e) {
      debugPrint('StorageService: Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Test Firebase Storage connectivity with detailed bucket info
  Future<bool> testStorageConnectivity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      debugPrint('StorageService: Testing connectivity...');
      debugPrint('StorageService: Storage bucket: ${_storage.bucket}');
      debugPrint('StorageService: App name: ${_storage.app.name}');
      debugPrint('StorageService: Storage max upload size: ${_storage.maxUploadRetryTime}');
      debugPrint('StorageService: Storage max download size: ${_storage.maxDownloadRetryTime}');
      
      // Try to list files in the root to see if we can access the bucket
      try {
        final listResult = await _storage.ref().listAll();
        debugPrint('StorageService: Root directory accessible, found ${listResult.items.length} items');
      } catch (e) {
        debugPrint('StorageService: Cannot list root directory: $e');
      }
      
      // Try to create a simple reference
      final testRef = _storage.ref('test_connection.txt');
      debugPrint('StorageService: Test reference created: ${testRef.fullPath}');
      debugPrint('StorageService: Test reference bucket: ${testRef.bucket}');
      debugPrint('StorageService: Test reference storage: ${testRef.storage}');
      
      return true;
    } catch (e) {
      debugPrint('StorageService: Connectivity test failed: $e');
      return false;
    }
  }

  /// Simple upload method with minimal path requirements
  Future<String> uploadImageSimple(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      // Test connectivity first
      final isConnected = await testStorageConnectivity();
      if (!isConnected) {
        throw Exception('Cannot connect to Firebase Storage');
      }

      // Use the simplest possible path - just filename in root
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'img_$timestamp.jpg';
      
      debugPrint('StorageService: Simple upload starting...');
      debugPrint('StorageService: File: ${file.path} (${await file.length()} bytes)');
      debugPrint('StorageService: Target: $fileName');

      final ref = _storage.ref(fileName);
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'timestamp': timestamp.toString(),
        },
      );

      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('StorageService: Simple upload successful: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('StorageService: Simple upload failed: $e');
      rethrow;
    }
  }

  /// Try uploading with explicit bucket configuration
  Future<String> uploadImageWithExplicitBucket(File file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!await file.exists()) {
        throw Exception('Image file does not exist');
      }

      // Try with different Firebase Storage configurations
      final storageInstances = [
        FirebaseStorage.instance,
        FirebaseStorage.instanceFor(bucket: 'wordnerd-artbeat.firebasestorage.app'),
        FirebaseStorage.instanceFor(bucket: 'gs://wordnerd-artbeat.firebasestorage.app'),
      ];

      for (int i = 0; i < storageInstances.length; i++) {
        try {
          final storage = storageInstances[i];
          debugPrint('StorageService: Trying storage instance $i: ${storage.bucket}');
          
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = 'test_$timestamp.jpg';
          
          final ref = storage.ref(fileName);
          debugPrint('StorageService: Created reference: ${ref.fullPath}');
          
          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'uploadedBy': user.uid,
              'timestamp': timestamp.toString(),
            },
          );

          final uploadTask = ref.putFile(file, metadata);
          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          
          debugPrint('StorageService: Explicit bucket upload successful: $downloadUrl');
          return downloadUrl;

        } catch (e) {
          debugPrint('StorageService: Storage instance $i failed: $e');
          if (i == storageInstances.length - 1) {
            rethrow; // Last attempt failed, rethrow
          }
        }
      }

      throw Exception('All storage configurations failed');

    } catch (e) {
      debugPrint('StorageService: Explicit bucket upload failed: $e');
      rethrow;
    }
  }

  /// Enhanced diagnostic method to check Storage status
  Future<String> diagnosisStorageIssue() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return 'DIAGNOSIS: User not authenticated';
      }

      debugPrint('=== Storage Diagnosis ===');
      debugPrint('User: ${user.uid}');
      debugPrint('Bucket: ${_storage.bucket}');
      
      // Test 1: Try to list root directory
      try {
        final listResult = await _storage.ref().listAll();
        debugPrint('SUCCESS: Storage is enabled, found ${listResult.items.length} items');
        return 'SUCCESS: Firebase Storage is properly configured';
      } catch (e) {
        debugPrint('List error: $e');
        
        if (e.toString().contains('object-not-found')) {
          return 'DIAGNOSIS: Firebase Storage is NOT ENABLED for this project. Please enable it in Firebase Console.';
        } else if (e.toString().contains('permission-denied')) {
          return 'DIAGNOSIS: Storage rules deny access. Check your storage.rules file.';
        } else {
          return 'DIAGNOSIS: Storage error - $e';
        }
      }
    } catch (e) {
      return 'DIAGNOSIS: General error - $e';
    }
  }
}
