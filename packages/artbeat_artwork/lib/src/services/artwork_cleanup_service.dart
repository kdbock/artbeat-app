import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/artwork_model.dart';

/// Service for cleaning up artwork data inconsistencies
class ArtworkCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find and fix artwork with broken image URLs
  Future<void> cleanupBrokenArtworkImages({bool dryRun = true}) async {
    if (!kDebugMode) {
      debugPrint('⚠️ Cleanup service only runs in debug mode');
      return;
    }

    debugPrint('🔍 Starting artwork image cleanup (dryRun: $dryRun)...');

    try {
      // Get all artwork documents
      final snapshot = await _firestore.collection('artwork').get();

      final int totalArtwork = snapshot.docs.length;
      int brokenImages = 0;
      int fixedImages = 0;

      debugPrint('📊 Found $totalArtwork artwork documents to check');

      for (final doc in snapshot.docs) {
        try {
          final artwork = ArtworkModel.fromFirestore(doc);

          // Check if image URL is accessible
          final isAccessible = await _checkImageUrl(artwork.imageUrl);

          if (!isAccessible) {
            brokenImages++;
            debugPrint('❌ Broken image found:');
            debugPrint('   - ID: ${artwork.id}');
            debugPrint('   - Title: ${artwork.title}');
            debugPrint('   - Artist: ${artwork.userId}');
            debugPrint('   - URL: ${artwork.imageUrl}');

            if (!dryRun) {
              // Option 1: Set a placeholder image
              await _fixBrokenArtworkImage(doc.id, artwork);
              fixedImages++;
              debugPrint('✅ Fixed broken image for artwork ${artwork.id}');
            }
          } else {
            debugPrint('✅ Image OK: ${artwork.title}');
          }
        } catch (e) {
          debugPrint('❌ Error checking artwork ${doc.id}: $e');
        }
      }

      debugPrint('📊 Cleanup Summary:');
      debugPrint('   - Total artwork: $totalArtwork');
      debugPrint('   - Broken images: $brokenImages');
      debugPrint('   - Fixed images: $fixedImages');
      debugPrint('   - Dry run: $dryRun');
    } catch (e) {
      debugPrint('❌ Error during cleanup: $e');
    }
  }

  /// Check if an image URL is accessible
  Future<bool> _checkImageUrl(String imageUrl) async {
    try {
      final response = await http.head(Uri.parse(imageUrl));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Image check failed for $imageUrl: $e');
      return false;
    }
  }

  /// Fix broken artwork image by setting a placeholder
  Future<void> _fixBrokenArtworkImage(
      String artworkId, ArtworkModel artwork) async {
    try {
      // Instead of using an external placeholder, we'll use a local asset or remove the image
      // For now, we'll set it to empty and mark it as needing a new image
      await _firestore.collection('artwork').doc(artworkId).update({
        'imageUrl': '', // Clear the broken URL
        'updatedAt': FieldValue.serverTimestamp(),
        'hasPlaceholderImage': true, // Flag to indicate this needs a new image
        'needsNewImage': true, // Additional flag for UI handling
        'originalBrokenUrl': artwork.imageUrl, // Keep reference to broken URL
      });

      debugPrint('✅ Cleared broken image URL for artwork $artworkId');
    } catch (e) {
      debugPrint('❌ Error fixing artwork $artworkId: $e');
      rethrow;
    }
  }

  /// Remove artwork with broken images (more aggressive cleanup)
  Future<void> removeBrokenArtwork({bool dryRun = true}) async {
    if (!kDebugMode) {
      debugPrint('⚠️ Remove broken artwork only runs in debug mode');
      return;
    }

    debugPrint('🗑️ Starting removal of broken artwork (dryRun: $dryRun)...');

    try {
      final snapshot = await _firestore.collection('artwork').get();

      final int totalArtwork = snapshot.docs.length;
      int brokenArtwork = 0;
      int removedArtwork = 0;

      for (final doc in snapshot.docs) {
        try {
          final artwork = ArtworkModel.fromFirestore(doc);
          final isAccessible = await _checkImageUrl(artwork.imageUrl);

          if (!isAccessible) {
            brokenArtwork++;
            debugPrint(
                '❌ Would remove broken artwork: ${artwork.title} (${artwork.id})');

            if (!dryRun) {
              await doc.reference.delete();
              removedArtwork++;
              debugPrint('🗑️ Removed broken artwork ${artwork.id}');
            }
          }
        } catch (e) {
          debugPrint('❌ Error checking artwork ${doc.id}: $e');
        }
      }

      debugPrint('📊 Removal Summary:');
      debugPrint('   - Total artwork: $totalArtwork');
      debugPrint('   - Broken artwork: $brokenArtwork');
      debugPrint('   - Removed artwork: $removedArtwork');
      debugPrint('   - Dry run: $dryRun');
    } catch (e) {
      debugPrint('❌ Error during removal: $e');
    }
  }

  /// Quick check for the specific problematic image
  Future<void> checkSpecificImage() async {
    const problematicUrl =
        'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/artwork_images%2FEdH8MvWk4Ja6eoSZM59QtOaxEK43%2Fnew%2F1750961590495_EdH8MvWk4Ja6eoSZM59QtOaxEK43?alt=media&token=d9e1ed0b-e106-44e3-a9d4-5da43d0ff045';

    debugPrint('🔍 Checking specific problematic image...');

    try {
      // Find artwork with this specific URL
      final snapshot = await _firestore
          .collection('artwork')
          .where('imageUrl', isEqualTo: problematicUrl)
          .get();

      debugPrint('📊 Found ${snapshot.docs.length} artwork with this URL');

      for (final doc in snapshot.docs) {
        final artwork = ArtworkModel.fromFirestore(doc);
        debugPrint('❌ Problematic artwork:');
        debugPrint('   - ID: ${artwork.id}');
        debugPrint('   - Title: ${artwork.title}');
        debugPrint('   - Artist: ${artwork.userId}');
        debugPrint('   - Created: ${artwork.createdAt}');

        // Check if image is accessible
        final isAccessible = await _checkImageUrl(problematicUrl);
        debugPrint('   - Image accessible: $isAccessible');

        // If image is not accessible, fix it immediately
        if (!isAccessible) {
          debugPrint('🔧 Fixing broken image for artwork ${artwork.id}...');
          await _fixBrokenArtworkImage(doc.id, artwork);
          debugPrint('✅ Fixed broken image for artwork ${artwork.id}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking specific image: $e');
    }
  }
}
