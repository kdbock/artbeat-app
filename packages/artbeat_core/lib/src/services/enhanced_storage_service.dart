import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Enhanced storage service with image compression and optimization
class EnhancedStorageService {
  static final EnhancedStorageService _instance =
      EnhancedStorageService._internal();
  factory EnhancedStorageService() => _instance;
  EnhancedStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Image compression settings
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int thumbnailSize = 300;
  static const int profileImageSize = 400;
  static const int jpegQuality = 85;

  /// Upload image with automatic compression and thumbnail generation
  Future<Map<String, String>> uploadImageWithOptimization({
    required File imageFile,
    required String category, // 'profile', 'capture', 'artwork', etc.
    bool generateThumbnail = true,
    int? customWidth,
    int? customHeight,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      debugPrint(
        '📸 Original image: ${originalImage.width}x${originalImage.height}',
      );

      // Determine compression settings based on category
      final settings = _getCompressionSettings(category);

      // Compress main image
      final compressedImage = _compressImage(
        originalImage,
        maxWidth: customWidth ?? settings['maxWidth']!,
        maxHeight: customHeight ?? settings['maxHeight']!,
        quality: settings['quality']!,
      );

      // Generate thumbnail if requested
      img.Image? thumbnail;
      if (generateThumbnail) {
        thumbnail = _generateThumbnail(originalImage, thumbnailSize);
      }

      // Upload compressed image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${category}_${timestamp}_${user.uid}';

      final mainImageUrl = await _uploadImageData(
        compressedImage,
        '$category/${user.uid}/$fileName.jpg',
        user.uid,
      );

      String? thumbnailUrl;
      if (thumbnail != null) {
        thumbnailUrl = await _uploadImageData(
          thumbnail,
          '$category/${user.uid}/thumbnails/${fileName}_thumb.jpg',
          user.uid,
        );
      }

      final result = {
        'imageUrl': mainImageUrl,
        'originalSize': '${originalImage.width}x${originalImage.height}',
        'compressedSize': '${compressedImage.width}x${compressedImage.height}',
      };

      if (thumbnailUrl != null) {
        result['thumbnailUrl'] = thumbnailUrl;
      }

      debugPrint('✅ Image upload successful');
      debugPrint('📊 Original: ${originalImage.width}x${originalImage.height}');
      debugPrint(
        '📊 Compressed: ${compressedImage.width}x${compressedImage.height}',
      );
      if (thumbnail != null) {
        debugPrint('📊 Thumbnail: ${thumbnail.width}x${thumbnail.height}');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Enhanced storage upload failed: $e');
      rethrow;
    }
  }

  /// Get compression settings for different categories
  Map<String, int> _getCompressionSettings(String category) {
    switch (category) {
      case 'profile':
        return {
          'maxWidth': profileImageSize,
          'maxHeight': profileImageSize,
          'quality': 90,
        };
      case 'capture':
      case 'artwork':
        return {
          'maxWidth': maxImageWidth,
          'maxHeight': maxImageHeight,
          'quality': jpegQuality,
        };
      case 'thumbnail':
        return {
          'maxWidth': thumbnailSize,
          'maxHeight': thumbnailSize,
          'quality': 80,
        };
      default:
        return {
          'maxWidth': maxImageWidth,
          'maxHeight': maxImageHeight,
          'quality': jpegQuality,
        };
    }
  }

  /// Compress image while maintaining aspect ratio
  img.Image _compressImage(
    img.Image originalImage, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) {
    // Calculate new dimensions while maintaining aspect ratio
    final aspectRatio = originalImage.width / originalImage.height;
    int newWidth = originalImage.width;
    int newHeight = originalImage.height;

    if (newWidth > maxWidth) {
      newWidth = maxWidth;
      newHeight = (newWidth / aspectRatio).round();
    }

    if (newHeight > maxHeight) {
      newHeight = maxHeight;
      newWidth = (newHeight * aspectRatio).round();
    }

    // Only resize if necessary
    if (newWidth < originalImage.width || newHeight < originalImage.height) {
      return img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    return originalImage;
  }

  /// Generate thumbnail from original image
  img.Image _generateThumbnail(img.Image originalImage, int size) {
    // Create square thumbnail
    final smallerDimension = originalImage.width < originalImage.height
        ? originalImage.width
        : originalImage.height;

    // Crop to square first
    final centerX = (originalImage.width / 2).round();
    final centerY = (originalImage.height / 2).round();
    final cropSize = (smallerDimension / 2).round();

    final croppedImage = img.copyCrop(
      originalImage,
      x: centerX - cropSize,
      y: centerY - cropSize,
      width: cropSize * 2,
      height: cropSize * 2,
    );

    // Resize to thumbnail size
    return img.copyResize(
      croppedImage,
      width: size,
      height: size,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Upload image data to Firebase Storage
  Future<String> _uploadImageData(
    img.Image imageData,
    String storagePath,
    String userId,
  ) async {
    final jpegBytes = Uint8List.fromList(
      img.encodeJpg(imageData, quality: jpegQuality),
    );

    final ref = _storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uploadedBy': userId,
        'uploadTime': DateTime.now().toIso8601String(),
        'compressed': 'true',
      },
    );

    final uploadTask = ref.putData(jpegBytes, metadata);
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  /// Upload multiple images with batch processing
  Future<List<Map<String, String>>> uploadMultipleImages({
    required List<File> imageFiles,
    required String category,
    bool generateThumbnails = true,
    int maxConcurrent = 3,
  }) async {
    final results = <Map<String, String>>[];

    // Process images in batches to avoid overwhelming the system
    for (int i = 0; i < imageFiles.length; i += maxConcurrent) {
      final batch = imageFiles.skip(i).take(maxConcurrent).toList();
      final futures = batch.map(
        (file) => uploadImageWithOptimization(
          imageFile: file,
          category: category,
          generateThumbnail: generateThumbnails,
        ),
      );

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);

      // Add delay between batches
      if (i + maxConcurrent < imageFiles.length) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    return results;
  }

  /// Delete image and its thumbnail
  Future<void> deleteImageWithThumbnail(
    String imageUrl, [
    String? thumbnailUrl,
  ]) async {
    try {
      // Delete main image
      final mainRef = _storage.refFromURL(imageUrl);
      await mainRef.delete();

      // Delete thumbnail if provided
      if (thumbnailUrl != null) {
        final thumbRef = _storage.refFromURL(thumbnailUrl);
        await thumbRef.delete();
      }

      debugPrint('🗑️ Image and thumbnail deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      rethrow;
    }
  }

  /// Get image metadata
  Future<Map<String, dynamic>> getImageMetadata(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();

      return {
        'contentType': metadata.contentType,
        'size': metadata.size,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      debugPrint('❌ Error getting image metadata: $e');
      return {};
    }
  }
}
