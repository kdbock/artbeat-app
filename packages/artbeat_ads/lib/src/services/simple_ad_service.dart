import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';

/// Simplified ad service for the new ad system
class SimpleAdService extends ChangeNotifier {
  final _adsRef = FirebaseFirestore.instance.collection('ads');
  final _storage = FirebaseStorage.instance;

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
      debugPrint('Error creating ad with images: $e');
      rethrow;
    }
  }

  /// Upload multiple images to Firebase Storage
  Future<List<String>> _uploadImages(List<File> images, String ownerId) async {
    final List<String> imageUrls = [];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < images.length; i++) {
      try {
        final fileName = '${timestamp}_${i}_upload.png';
        final ref = _storage.ref().child('ads/$ownerId/$fileName');

        final uploadTask = ref.putFile(images[i]);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        imageUrls.add(downloadUrl);
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
        throw Exception('Failed to upload image ${i + 1}');
      }
    }

    return imageUrls;
  }

  /// Get ads by location for display
  Stream<List<AdModel>> getAdsByLocation(AdLocation location) {
    return _adsRef
        .where('location', isEqualTo: location.index)
        .where('status', isEqualTo: AdStatus.approved.index)
        .where('endDate', isGreaterThan: Timestamp.now())
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
        .orderBy('startDate', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
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
      debugPrint('Error deleting ad: $e');
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
          debugPrint('Error deleting image $url: $e');
          // Continue with other images even if one fails
        }
      }

      // Delete primary image if different from artwork URLs
      if (ad.imageUrl.isNotEmpty && !ad.artworkUrls.contains(ad.imageUrl)) {
        try {
          final ref = _storage.refFromURL(ad.imageUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting primary image ${ad.imageUrl}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error deleting ad images: $e');
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
      debugPrint('Error getting ad: $e');
      return null;
    }
  }

  /// Update an ad
  Future<void> updateAd(String adId, Map<String, dynamic> data) async {
    await _adsRef.doc(adId).update(data);
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
      debugPrint('Error getting active ads count: $e');
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
      debugPrint('Error getting ads statistics: $e');
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
