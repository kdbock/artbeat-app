import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';
import '../models/ad_duration.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Simplified ad service for the new ad system
class SimpleAdService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  SimpleAdService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _adsRef =>
      _firestore.collection('ads');

  /// Create an ad with images
  Future<String> createAdWithImages(AdModel ad, List<File> images) async {
    if (images.isEmpty) {
      throw Exception('At least one image is required');
    }

    try {
      // Upload images to Firebase Storage
      final imageUrls = await _uploadImages(images, ad.ownerId);

      // Create ad with uploaded image URLs
      final adWithImages = AdModel(
        id: ad.id,
        ownerId: ad.ownerId,
        type: ad.type,
        size: ad.size,
        imageUrl: imageUrls.first, // Primary image
        artworkUrls: imageUrls, // All images for rotation
        title: ad.title,
        description: ad.description,
        location: ad.location,
        duration: ad.duration,
        startDate: ad.startDate,
        endDate: ad.endDate,
        status: ad.status,
        approvalId: ad.approvalId,
        destinationUrl: ad.destinationUrl,
        ctaText: ad.ctaText,
      );

      // Save to Firestore
      final doc = await _adsRef.add(adWithImages.toMap());
      return doc.id;
    } catch (e) {
      AppLogger.error('Error creating ad with images: $e');
      rethrow;
    }
  }

  /// Upload multiple images to Firebase Storage
  Future<List<String>> _uploadImages(List<File> images, String ownerId) async {
    final List<String> imageUrls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < images.length; i++) {
      String? downloadUrl;
      int retryCount = 0;
      const maxRetries = 3;

      while (downloadUrl == null && retryCount < maxRetries) {
        try {
          debugPrint(
            'Starting upload for image $i (attempt ${retryCount + 1}/$maxRetries)',
          );
          debugPrint(
            'Upload strategy: ${retryCount == 0
                ? "Full metadata"
                : retryCount == 1
                ? "Minimal metadata"
                : "No metadata"}',
          );

          // Validate file exists and is readable
          if (!await images[i].exists()) {
            throw Exception('Image file does not exist');
          }

          final fileSize = await images[i].length();
          AppLogger.info('Image $i size: ${fileSize} bytes');

          // Check file size (limit to 10MB)
          if (fileSize > 10 * 1024 * 1024) {
            throw Exception('Image file too large (max 10MB)');
          }

          final fileName = '${timestamp}_${i}_upload.jpg';
          // Try different paths based on retry attempt for better reliability
          String uploadPath;
          if (retryCount == 0) {
            uploadPath = 'debug_uploads/ads/$fileName';
          } else if (retryCount == 1) {
            uploadPath = 'temp_uploads/$fileName';
          } else {
            uploadPath = 'uploads/$fileName';
          }
          final ref = _storage.ref().child(uploadPath);

          AppLogger.info('Uploading to path: $uploadPath');

          // Try putData instead of putFile for better reliability
          final imageBytes = await images[i].readAsBytes();
          debugPrint(
            'Successfully read ${imageBytes.length} bytes from image file',
          );

          // Use different upload strategies based on retry attempt
          UploadTask uploadTask;
          if (retryCount == 0) {
            // First attempt: Full metadata with putData
            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploadedBy': ownerId,
                'uploadedAt': timestamp.toString(),
                'imageIndex': i.toString(),
              },
            );
            uploadTask = ref.putData(imageBytes, metadata);
          } else if (retryCount == 1) {
            // Second attempt: Minimal metadata with putData
            final metadata = SettableMetadata(contentType: 'image/jpeg');
            uploadTask = ref.putData(imageBytes, metadata);
          } else {
            // Final attempt: No metadata, just raw upload
            uploadTask = ref.putData(imageBytes);
          }

          // Monitor upload progress
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            debugPrint(
              'Upload progress for image $i: ${(progress * 100).toStringAsFixed(1)}%',
            );
          });

          // Add timeout to prevent hanging
          final snapshot = await uploadTask.timeout(
            const Duration(minutes: 2),
            onTimeout: () {
              throw Exception(
                'Upload timeout - please check your internet connection',
              );
            },
          );
          AppLogger.info(
            'Upload completed for image $i, getting download URL...',
          );

          downloadUrl = await snapshot.ref.getDownloadURL();
          AppLogger.info('Download URL obtained for image $i: $downloadUrl');

          imageUrls.add(downloadUrl);
          break; // Success, exit retry loop
        } catch (e) {
          retryCount++;
          AppLogger.error('Error uploading image $i (attempt $retryCount): $e');
          AppLogger.error('Error type: ${e.runtimeType}');

          // If this was the last retry, throw the error
          if (retryCount >= maxRetries) {
            // Provide more specific error messages
            if (e.toString().contains('permission-denied')) {
              throw Exception(
                'Permission denied. Please check Firebase Storage rules.',
              );
            } else if (e.toString().contains('network')) {
              throw Exception(
                'Network error. Please check your internet connection.',
              );
            } else if (e.toString().contains('quota-exceeded')) {
              throw Exception(
                'Storage quota exceeded. Please try again later.',
              );
            } else if (e.toString().contains('cannot parse response')) {
              throw Exception(
                'Upload failed due to server response error. Please try again.',
              );
            } else {
              throw Exception(
                'Failed to upload image ${i + 1} after $maxRetries attempts: ${e.toString()}',
              );
            }
          } else {
            // Wait before retrying
            AppLogger.info('Retrying upload for image $i in 2 seconds...');
            await Future<void>.delayed(const Duration(seconds: 2));
          }
        }
      }

      // If we exit the retry loop without success, throw an error
      if (downloadUrl == null) {
        throw Exception(
          'Failed to upload image ${i + 1} after $maxRetries attempts',
        );
      }
    }

    AppLogger.info('All images uploaded successfully. URLs: $imageUrls');
    return imageUrls;
  }

  /// Get ads by location for display
  Stream<List<AdModel>> getAdsByLocation(AdLocation location) {
    final now = Timestamp.now();
    return _adsRef
        .where('location', isEqualTo: location.index)
        .where('status', isEqualTo: AdStatus.approved.index)
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThan: now)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Get ads by owner
  Stream<List<AdModel>> getAdsByOwner(String ownerId) {
    return _adsRef
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Get all ads (for admin)
  Stream<List<AdModel>> getAllAds() {
    return _adsRef
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Get pending ads for approval
  Stream<List<AdModel>> getPendingAds() {
    return _adsRef
        .where('status', isEqualTo: AdStatus.pending.index)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList()
                ..sort(
                  (a, b) => a.startDate.compareTo(b.startDate),
                ), // Sort in memory temporarily
        );
  }

  /// Approve an ad
  Future<void> approveAd(String adId, String approvalId) async {
    await _adsRef.doc(adId).update({
      'status': AdStatus.approved.index,
      'approvalId': approvalId,
    });
    notifyListeners();
  }

  /// Reject an ad
  Future<void> rejectAd(String adId, String approvalId) async {
    await _adsRef.doc(adId).update({
      'status': AdStatus.rejected.index,
      'approvalId': approvalId,
    });
    notifyListeners();
  }

  /// Update ad status
  Future<void> updateAdStatus(String adId, AdStatus status) async {
    await _adsRef.doc(adId).update({'status': status.index});
    notifyListeners();
  }

  /// Delete an ad
  Future<void> deleteAd(String adId) async {
    try {
      // Get ad data to delete associated images
      final doc = await _adsRef.doc(adId).get();
      if (doc.exists) {
        final ad = AdModel.fromMap(doc.data()!, doc.id);

        // Delete images from storage
        await _deleteAdImages(ad);
      }

      // Delete ad document
      await _adsRef.doc(adId).delete();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error deleting ad: $e');
      rethrow;
    }
  }

  /// Delete ad images from Firebase Storage
  Future<void> _deleteAdImages(AdModel ad) async {
    try {
      // Delete all artwork URLs
      for (final url in ad.artworkUrls) {
        try {
          final ref = _storage.refFromURL(url);
          await ref.delete();
        } catch (e) {
          AppLogger.error('Error deleting image $url: $e');
          // Continue with other images even if one fails
        }
      }

      // Delete primary image if different from artwork URLs
      if (ad.imageUrl.isNotEmpty && !ad.artworkUrls.contains(ad.imageUrl)) {
        try {
          final ref = _storage.refFromURL(ad.imageUrl);
          await ref.delete();
        } catch (e) {
          AppLogger.error('Error deleting primary image ${ad.imageUrl}: $e');
        }
      }
    } catch (e) {
      AppLogger.error('Error deleting ad images: $e');
      // Don't throw - we still want to delete the ad document
    }
  }

  /// Get a single ad by ID
  Future<AdModel?> getAd(String adId) async {
    try {
      final doc = await _adsRef.doc(adId).get();
      if (!doc.exists) return null;
      return AdModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      AppLogger.error('Error getting ad: $e');
      return null;
    }
  }

  /// Update an ad
  Future<void> updateAd(String adId, Map<String, dynamic> data) async {
    await _adsRef.doc(adId).update(data);
    notifyListeners();
  }

  /// Update an ad with new images
  Future<void> updateAdWithImages(
    AdModel ad,
    List<File> newImages,
    List<String> imagesToKeep,
  ) async {
    try {
      // Upload new images if any
      List<String> newImageUrls = [];
      if (newImages.isNotEmpty) {
        newImageUrls = await _uploadImages(newImages, ad.ownerId);
      }

      // Combine kept images with new images
      final allImageUrls = [...imagesToKeep, ...newImageUrls];

      // Create updated ad data
      final updatedData = ad.toMap();
      updatedData['imageUrl'] = allImageUrls.isNotEmpty
          ? allImageUrls.first
          : '';
      updatedData['artworkUrls'] = allImageUrls.join(',');

      // Update the ad in Firestore
      await _adsRef.doc(ad.id).update(updatedData);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating ad with images: $e');
      rethrow;
    }
  }

  /// Duplicate an existing ad
  Future<String> duplicateAd(String adId) async {
    try {
      final originalAd = await getAd(adId);
      if (originalAd == null) {
        throw Exception('Original ad not found');
      }

      // Create a new ad with same properties but new ID and reset status
      final duplicatedAd = AdModel(
        id: '', // Will be assigned by Firestore
        ownerId: originalAd.ownerId,
        type: originalAd.type,
        size: originalAd.size,
        imageUrl: originalAd.imageUrl,
        artworkUrls: originalAd.artworkUrls,
        title: '${originalAd.title} (Copy)',
        description: originalAd.description,
        location: originalAd.location,
        duration: originalAd.duration,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(Duration(days: originalAd.duration.days)),
        status: AdStatus.pending,
        approvalId: null, // Reset approval
        destinationUrl: originalAd.destinationUrl,
        ctaText: originalAd.ctaText,
      );

      // Save to Firestore
      final doc = await _adsRef.add(duplicatedAd.toMap());
      notifyListeners();
      return doc.id;
    } catch (e) {
      AppLogger.error('Error duplicating ad: $e');
      rethrow;
    }
  }

  /// Update ad location
  Future<void> updateAdLocation(String adId, AdLocation newLocation) async {
    await _adsRef.doc(adId).update({'location': newLocation.index});
    notifyListeners();
  }

  /// Get active ads count by location (for analytics)
  Future<int> getActiveAdsCount(AdLocation location) async {
    try {
      final query = await _adsRef
          .where('location', isEqualTo: location.index)
          .where('status', isEqualTo: AdStatus.approved.index)
          .where('endDate', isGreaterThan: Timestamp.now())
          .get();
      return query.docs.length;
    } catch (e) {
      AppLogger.error('Error getting active ads count: $e');
      return 0;
    }
  }

  /// Get ads statistics
  Future<Map<String, int>> getAdsStatistics() async {
    try {
      final allAds = await _adsRef.get();
      final stats = <String, int>{
        'total': allAds.docs.length,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'expired': 0,
      };

      final now = Timestamp.now();

      for (final doc in allAds.docs) {
        final data = doc.data();
        final status = data['status'] as int? ?? 0;
        final endDate = data['endDate'] as Timestamp?;

        if (endDate != null && endDate.compareTo(now) < 0) {
          stats['expired'] = (stats['expired'] ?? 0) + 1;
        } else {
          switch (status) {
            case 0: // pending
              stats['pending'] = (stats['pending'] ?? 0) + 1;
              break;
            case 1: // approved
              stats['approved'] = (stats['approved'] ?? 0) + 1;
              break;
            case 2: // rejected
              stats['rejected'] = (stats['rejected'] ?? 0) + 1;
              break;
          }
        }
      }

      return stats;
    } catch (e) {
      AppLogger.error('Error getting ads statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'expired': 0,
      };
    }
  }
}
