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

    // Validate image file before upload
    if (!validateImageFile(imageFile)) {
      throw Exception('Invalid image file: ${imageFile.path}');
    }

    String? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🔄 Upload attempt $attempt/$maxRetries for $category');

        final fileName = _generateFileName(imageFile);
        final ref = _storage.ref().child('$category/$userId/$fileName');

        // Add metadata for better error tracking
        final metadata = SettableMetadata(
          contentType: _getContentType(imageFile),
          customMetadata: {
            'uploadedBy': userId,
            'category': category,
            'attempt': attempt.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        // Try putData approach first (more reliable for some Firebase configs)
        UploadTask uploadTask;
        try {
          final imageBytes = await imageFile.readAsBytes();
          uploadTask = ref.putData(imageBytes, metadata);
          debugPrint('📤 Using putData method for upload');
        } catch (readError) {
          debugPrint(
            '⚠️ Failed to read file as bytes, falling back to putFile: $readError',
          );
          uploadTask = ref.putFile(imageFile, metadata);
        }

        // Track progress if callback provided (but don't let progress errors fail the upload)
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen(
            (snapshot) {
              try {
                final progress =
                    snapshot.bytesTransferred / snapshot.totalBytes;
                onProgress(progress);
              } catch (progressError) {
                debugPrint(
                  '⚠️ Progress tracking error (non-fatal): $progressError',
                );
              }
            },
            onError: (Object error) {
              debugPrint('⚠️ Upload progress stream error (non-fatal): $error');
            },
          );
        }

        // Wait for upload completion with timeout
        final snapshot = await uploadTask.timeout(
          const Duration(minutes: 2),
          onTimeout: () {
            throw Exception('Upload timeout after 2 minutes');
          },
        );

        // Add a longer delay to ensure Firebase processes the upload completely
        await Future<void>.delayed(const Duration(milliseconds: 1500));

        // Try to get download URL with retry logic
        String? downloadUrl;
        for (int urlAttempt = 1; urlAttempt <= 3; urlAttempt++) {
          try {
            downloadUrl = await snapshot.ref.getDownloadURL();
            break;
          } catch (urlError) {
            debugPrint('❌ Download URL attempt $urlAttempt failed: $urlError');
            if (urlAttempt == 3) rethrow;
            await Future<void>.delayed(Duration(seconds: urlAttempt));
          }
        }

        if (downloadUrl == null) {
          throw Exception('Failed to get download URL after 3 attempts');
        }

        debugPrint('✅ Upload successful: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        lastError = e.toString();
        debugPrint('❌ Upload attempt $attempt failed: $e');

        // Handle specific Firebase Storage errors
        if (e.toString().contains('cannot parse response')) {
          debugPrint(
            '🔄 Parse error detected, adding extra delay before retry',
          );
          await Future<void>.delayed(Duration(seconds: attempt * 3));

          // On last attempt with parse error, try simple upload method
          if (attempt == maxRetries) {
            debugPrint('🔄 Trying simple upload method as last resort');
            try {
              return await _simpleUpload(imageFile, userId, category);
            } catch (simpleError) {
              debugPrint('❌ Simple upload also failed: $simpleError');
            }
          }
        } else if (e.toString().contains('network')) {
          debugPrint('🔄 Network error detected, checking connectivity');
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        } else {
          // Standard exponential backoff
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }

        // Don't retry on the last attempt
        if (attempt == maxRetries) break;
      }
    }

    throw Exception(
      'Upload failed after $maxRetries attempts. Last error: $lastError',
    );
  }

  /// Upload multiple images with batch progress tracking (sequential to avoid conflicts)
  Future<List<String>> uploadImages(
    List<File> imageFiles, {
    required String userId,
    required String category,
    void Function(double)? onProgress,
  }) async {
    if (imageFiles.isEmpty) return [];

    final results = <String>[];

    for (int i = 0; i < imageFiles.length; i++) {
      debugPrint('📤 Uploading image ${i + 1}/${imageFiles.length}');

      // Add delay between uploads to prevent rate limiting
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1000));
      }

      final imageUrl = await uploadImage(
        imageFiles[i],
        userId: userId,
        category: category,
        onProgress: onProgress != null
            ? (progress) => onProgress((i + progress) / imageFiles.length)
            : null,
      );
      results.add(imageUrl);

      debugPrint('✅ Image ${i + 1}/${imageFiles.length} uploaded successfully');
    }

    return results;
  }

  /// Generate unique filename for uploaded image
  String _generateFileName(File imageFile) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = imageFile.path.split('.').last.toLowerCase();
    return '${timestamp}_upload.$extension';
  }

  /// Get content type for image file
  String _getContentType(File imageFile) {
    final extension = imageFile.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  /// Simple upload method as fallback for parse errors
  Future<String> _simpleUpload(
    File imageFile,
    String userId,
    String category,
  ) async {
    debugPrint('🔄 Attempting simple upload without metadata');

    final fileName = _generateFileName(imageFile);
    final ref = _storage.ref().child('$category/$userId/$fileName');

    // Simple upload without metadata or progress tracking
    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;

    // Wait a bit longer for simple uploads
    await Future<void>.delayed(const Duration(seconds: 3));

    final downloadUrl = await snapshot.ref.getDownloadURL();
    debugPrint('✅ Simple upload successful: $downloadUrl');

    return downloadUrl;
  }

  /// Test upload connectivity and permissions
  Future<bool> testUploadCapability(String userId, {String? userType}) async {
    debugPrint(
      '🔍 Testing upload capability for user: $userId (type: $userType)',
    );

    // Use appropriate test path based on user type
    String testPath;
    if (userType == 'admin') {
      testPath = 'admin_ads/$userId/connectivity_test.txt';
    } else if (userType == 'artist') {
      testPath = 'artist_ads/$userId/connectivity_test.txt';
    } else if (userType == 'gallery') {
      testPath = 'gallery_ads/$userId/connectivity_test.txt';
    } else {
      testPath = 'user_ads/$userId/connectivity_test.txt';
    }

    try {
      final testRef = _storage.ref().child(testPath);
      final testData = 'Test upload - ${DateTime.now().toIso8601String()}';

      final uploadTask = testRef.putString(testData);
      await uploadTask;

      // Test download URL generation
      final downloadUrl = await testRef.getDownloadURL();
      debugPrint('🔗 Test download URL: $downloadUrl');

      // Clean up
      await testRef.delete();

      debugPrint('✅ Upload capability test passed');
      return true;
    } catch (e) {
      debugPrint('❌ Upload capability test failed: $e');

      // Log specific error types
      if (e.toString().contains('cannot parse response')) {
        debugPrint(
          '🚨 Parse response error detected - possible Firebase config issue',
        );
      } else if (e.toString().contains('network')) {
        debugPrint('🚨 Network error detected - check internet connection');
      } else if (e.toString().contains('permission')) {
        debugPrint(
          '🚨 Permission error detected - check Firebase Storage rules',
        );
        debugPrint('💡 Trying to upload to: $testPath');
      }

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
