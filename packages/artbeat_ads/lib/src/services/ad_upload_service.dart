import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Unified service for handling all ad image uploads
/// Provides consistent upload logic, retry mechanisms, and progress tracking
class AdUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload an image with progress tracking and retry logic
  Future<String> uploadImage(
    File imageFile, {
    required String userId,
    required String category,
    void Function(double)? onProgress,
    int maxRetries = 3,
  }) async {
    if (_auth.currentUser?.uid != userId) {
      throw Exception('User authentication mismatch');
    }

    String? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Upload attempt $attempt/$maxRetries for $category');

        final fileName = _generateFileName(imageFile);
        final ref = _storage.ref().child('$category/$userId/$fileName');

        final uploadTask = ref.putFile(imageFile);

        // Track progress if callback provided
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen((snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          });
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        debugPrint('✅ Upload successful: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        lastError = e.toString();
        debugPrint('❌ Upload attempt $attempt failed: $e');

        // Wait before retry (exponential backoff)
        if (attempt < maxRetries) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    throw Exception(
      'Upload failed after $maxRetries attempts. Last error: $lastError',
    );
  }

  /// Upload multiple images with batch progress tracking
  Future<List<String>> uploadImages(
    List<File> imageFiles, {
    required String userId,
    required String category,
    void Function(double)? onProgress,
  }) async {
    if (imageFiles.isEmpty) return [];

    final results = <String>[];

    for (int i = 0; i < imageFiles.length; i++) {
      final imageUrl = await uploadImage(
        imageFiles[i],
        userId: userId,
        category: category,
        onProgress: onProgress != null
            ? (progress) => onProgress((i + progress) / imageFiles.length)
            : null,
      );
      results.add(imageUrl);
    }

    return results;
  }

  /// Generate unique filename for uploaded image
  String _generateFileName(File imageFile) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = imageFile.path.split('.').last.toLowerCase();
    return '${timestamp}_upload.$extension';
  }

  /// Test upload connectivity and permissions
  Future<bool> testUploadCapability(String userId) async {
    try {
      // Create a small test file
      final testRef = _storage.ref().child(
        'test_uploads/$userId/connectivity_test.txt',
      );
      final testData = 'Test upload - ${DateTime.now().toIso8601String()}';

      await testRef.putString(testData);
      await testRef.delete(); // Clean up

      debugPrint('✅ Upload capability test passed');
      return true;
    } catch (e) {
      debugPrint('❌ Upload capability test failed: $e');
      return false;
    }
  }

  /// Get upload path for specific ad type and user
  String getUploadPath(String category, String userId) {
    return '$category/$userId';
  }

  /// Validate image file before upload
  bool validateImageFile(File imageFile) {
    // Check file exists
    if (!imageFile.existsSync()) return false;

    // Check file size (max 10MB)
    final fileSizeInBytes = imageFile.lengthSync();
    if (fileSizeInBytes > 10 * 1024 * 1024) return false;

    // Check file extension
    final extension = imageFile.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!allowedExtensions.contains(extension)) return false;

    return true;
  }
}
