import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_artist_approved_model.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';

/// Service for managing Artist Approved Ads with GIF animation support
class AdArtistApprovedService {
  final _adsRef = FirebaseFirestore.instance.collection('artist_approved_ads');
  final _adAnalyticsRef = FirebaseFirestore.instance.collection('ad_analytics');

  /// Create a new artist approved ad
  Future<String> createArtistApprovedAd(AdArtistApprovedModel ad) async {
    try {
      final adData = ad.toMap();
      adData['createdAt'] = FieldValue.serverTimestamp();
      adData['updatedAt'] = FieldValue.serverTimestamp();

      final doc = await _adsRef.add(adData);

      if (kDebugMode) {
        debugPrint('✅ Artist approved ad created with ID: ${doc.id}');
      }

      return doc.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating artist approved ad: $e');
      }
      rethrow;
    }
  }

  /// Update an existing artist approved ad
  Future<void> updateArtistApprovedAd(
    String adId,
    Map<String, dynamic> data,
  ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _adsRef.doc(adId).update(data);

      if (kDebugMode) {
        debugPrint('✅ Artist approved ad updated: $adId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error updating artist approved ad: $e');
      }
      rethrow;
    }
  }

  /// Delete an artist approved ad
  Future<void> deleteArtistApprovedAd(String adId) async {
    try {
      await _adsRef.doc(adId).delete();

      if (kDebugMode) {
        debugPrint('✅ Artist approved ad deleted: $adId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error deleting artist approved ad: $e');
      }
      rethrow;
    }
  }

  /// Get a specific artist approved ad by ID
  Future<AdArtistApprovedModel?> getArtistApprovedAd(String adId) async {
    try {
      final doc = await _adsRef.doc(adId).get();
      if (!doc.exists) return null;

      return AdArtistApprovedModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting artist approved ad: $e');
      }
      return null;
    }
  }

  /// Get all artist approved ads by owner/artist
  Stream<List<AdArtistApprovedModel>> getArtistApprovedAdsByOwner(
    String ownerId,
  ) {
    return _adsRef
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdArtistApprovedModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Get all artist approved ads by artist ID
  Stream<List<AdArtistApprovedModel>> getArtistApprovedAdsByArtist(
    String artistId,
  ) {
    return _adsRef
        .where('artistId', isEqualTo: artistId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdArtistApprovedModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Get active artist approved ads by location
  Stream<List<AdArtistApprovedModel>> getActiveArtistApprovedAdsByLocation(
    AdLocation location,
  ) {
    return _adsRef
        .where('location', isEqualTo: location.index)
        .where('status', isEqualTo: AdStatus.running.index)
        .where('startDate', isLessThanOrEqualTo: DateTime.now())
        .where('endDate', isGreaterThanOrEqualTo: DateTime.now())
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdArtistApprovedModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Get a random active artist approved ad for a specific location
  Future<AdArtistApprovedModel?> getRandomActiveArtistApprovedAd(
    AdLocation location,
  ) async {
    try {
      final now = DateTime.now();
      final query = await _adsRef
          .where('location', isEqualTo: location.index)
          .where('status', isEqualTo: AdStatus.running.index)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('endDate', isGreaterThanOrEqualTo: now)
          .get();

      if (query.docs.isEmpty) return null;

      // Get a random ad from the results
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % query.docs.length;
      final doc = query.docs[randomIndex];

      return AdArtistApprovedModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting random artist approved ad: $e');
      }
      return null;
    }
  }

  /// Get all active artist approved ads (for admin/review purposes)
  Stream<List<AdArtistApprovedModel>> getAllActiveArtistApprovedAds() {
    return _adsRef
        .where('status', isEqualTo: AdStatus.running.index)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdArtistApprovedModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Get pending artist approved ads (for admin approval)
  Stream<List<AdArtistApprovedModel>> getPendingArtistApprovedAds() {
    return _adsRef
        .where('status', isEqualTo: AdStatus.pending.index)
        .orderBy('createdAt', descending: false) // Oldest first for review
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdArtistApprovedModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  /// Approve an artist approved ad
  Future<void> approveArtistApprovedAd(String adId, String approvalId) async {
    try {
      await updateArtistApprovedAd(adId, {
        'status': AdStatus.running.index,
        'approvalId': approvalId,
      });

      if (kDebugMode) {
        debugPrint('✅ Artist approved ad approved: $adId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error approving artist approved ad: $e');
      }
      rethrow;
    }
  }

  /// Reject an artist approved ad
  Future<void> rejectArtistApprovedAd(String adId, String reason) async {
    try {
      await updateArtistApprovedAd(adId, {
        'status': AdStatus.rejected.index,
        'rejectionReason': reason,
      });

      if (kDebugMode) {
        debugPrint('✅ Artist approved ad rejected: $adId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error rejecting artist approved ad: $e');
      }
      rethrow;
    }
  }

  /// Track ad impression for analytics
  Future<void> trackAdImpression(
    String adId,
    String userId,
    String location,
  ) async {
    try {
      await _adAnalyticsRef.add({
        'adId': adId,
        'userId': userId,
        'action': 'impression',
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'adType': 'artist_approved',
      });

      // Update the ad's impression count
      await _adsRef.doc(adId).update({
        'impressionCount': FieldValue.increment(1),
        'lastImpressionTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking user experience
      if (kDebugMode) {
        debugPrint('❌ Error tracking ad impression: $e');
      }
    }
  }

  /// Track ad click for analytics
  Future<void> trackAdClick(String adId, String userId, String location) async {
    try {
      await _adAnalyticsRef.add({
        'adId': adId,
        'userId': userId,
        'action': 'click',
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'adType': 'artist_approved',
      });

      // Update the ad's click count
      await _adsRef.doc(adId).update({
        'clickCount': FieldValue.increment(1),
        'lastClickTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking user experience
      if (kDebugMode) {
        debugPrint('❌ Error tracking ad click: $e');
      }
    }
  }

  /// Get ad analytics for a specific ad
  Future<Map<String, dynamic>> getAdAnalytics(String adId) async {
    try {
      final impressionsQuery = await _adAnalyticsRef
          .where('adId', isEqualTo: adId)
          .where('action', isEqualTo: 'impression')
          .get();

      final clicksQuery = await _adAnalyticsRef
          .where('adId', isEqualTo: adId)
          .where('action', isEqualTo: 'click')
          .get();

      final impressions = impressionsQuery.docs.length;
      final clicks = clicksQuery.docs.length;
      final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0.0;

      return {
        'impressions': impressions,
        'clicks': clicks,
        'ctr': ctr, // Click-through rate as percentage
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting ad analytics: $e');
      }
      return {'impressions': 0, 'clicks': 0, 'ctr': 0.0};
    }
  }
}
