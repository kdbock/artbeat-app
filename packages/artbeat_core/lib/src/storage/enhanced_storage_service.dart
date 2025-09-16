import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

class EnhancedStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<Map<String, String>> uploadImageWithOptimization({
    required File imageFile,
    required String category,
    bool generateThumbnail = false,
    int maxWidth = 1200,
    int maxHeight = 1200,
    int quality = 85,
    int thumbnailSize = 200,
  }) async {
    try {
      AppLogger.info('📸 Starting optimized image upload for category: $category');

      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Could not decode image');
      }

      // Get original size for logging
      final originalSize = bytes.length;
      debugPrint(
        '📊 Original image size: ${(originalSize / 1024).toStringAsFixed(2)} KB',
      );

      // Resize image if needed while maintaining aspect ratio
      img.Image resizedImage = originalImage;
      if (originalImage.width > maxWidth || originalImage.height > maxHeight) {
        resizedImage = img.copyResize(
          originalImage,
          width: originalImage.width > originalImage.height ? maxWidth : null,
          height: originalImage.height >= originalImage.width
              ? maxHeight
              : null,
        );
      }

      // Encode the image with specified quality
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      debugPrint(
        '📊 Compressed size: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB',
      );

      // Generate unique filename
      final extension = path.extension(imageFile.path).toLowerCase();
      final filename = '${_uuid.v4()}$extension';
      final storagePath = '$category/$filename';

      // Upload compressed image
      final mainRef = _storage.ref().child(storagePath);
      await mainRef.putData(
        compressedBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final imageUrl = await mainRef.getDownloadURL();

      final result = {
        'imageUrl': imageUrl,
        'originalSize': originalSize.toString(),
        'compressedSize': compressedBytes.length.toString(),
      };

      // Generate and upload thumbnail if requested
      if (generateThumbnail) {
        AppLogger.debug('🔍 Generating thumbnail...');
        final thumbnail = img.copyResize(
          originalImage,
          width: thumbnailSize,
          height: thumbnailSize,
          interpolation: img.Interpolation.linear,
        );

        final thumbnailBytes = img.encodeJpg(thumbnail, quality: 85);
        final thumbnailPath = '$category/thumbnails/$filename';
        final thumbnailRef = _storage.ref().child(thumbnailPath);

        await thumbnailRef.putData(
          thumbnailBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final thumbnailUrl = await thumbnailRef.getDownloadURL();
        result['thumbnailUrl'] = thumbnailUrl;
        AppLogger.info('✅ Thumbnail generated and uploaded');
      }

      AppLogger.info('✅ Enhanced image upload completed successfully');
      return result;
    } catch (e) {
      AppLogger.error('❌ Error in enhanced image upload: $e');
      rethrow;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      AppLogger.info('✅ Image deleted successfully: $imageUrl');
    } catch (e) {
      AppLogger.error('❌ Error deleting image: $e');
      rethrow;
    }
  }
}
