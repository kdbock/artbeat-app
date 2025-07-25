import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';

/// Base service for managing ads (CRUD)
class AdService {
  final _adsRef = FirebaseFirestore.instance.collection('ads');
  final _adAnalyticsRef = FirebaseFirestore.instance.collection('ad_analytics');

  Future<String> createAd(AdModel ad) async {
    final doc = await _adsRef.add(ad.toMap());
    return doc.id;
  }

  Future<void> updateAd(String adId, Map<String, dynamic> data) async {
    await _adsRef.doc(adId).update(data);
  }

  Future<void> deleteAd(String adId) async {
    await _adsRef.doc(adId).delete();
  }

  Future<AdModel?> getAd(String adId) async {
    final doc = await _adsRef.doc(adId).get();
    if (!doc.exists) return null;
    return AdModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<AdModel>> getAdsByOwner(String ownerId) {
    return _adsRef
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<AdModel>> getAllAds() {
    return _adsRef.snapshots().map(
      (snap) => snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
    );
  }

  /// Get ads by location that are currently running
  Stream<List<AdModel>> getAdsByLocation(AdLocation location) {
    return _adsRef
        .where('location', isEqualTo: location.index)
        .where('status', isEqualTo: AdStatus.running.index)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AdModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  /// Get a single random ad for a specific location
  Future<AdModel?> getRandomAdForLocation(AdLocation location) async {
    final query = await _adsRef
        .where('location', isEqualTo: location.index)
        .where('status', isEqualTo: AdStatus.running.index)
        .where('startDate', isLessThanOrEqualTo: DateTime.now())
        .where('endDate', isGreaterThanOrEqualTo: DateTime.now())
        .get();

    if (query.docs.isEmpty) return null;

    // Get a random ad from the results
    final randomIndex =
        DateTime.now().millisecondsSinceEpoch % query.docs.length;
    final doc = query.docs[randomIndex];

    return AdModel.fromMap(doc.data(), doc.id);
  }

  /// Track ad click for analytics
  Future<void> trackAdClick(String adId, String userId) async {
    try {
      await _adAnalyticsRef.add({
        'adId': adId,
        'userId': userId,
        'action': 'click',
        'timestamp': FieldValue.serverTimestamp(),
        'location': 'profile', // Can be parameterized later
      });

      // Also update the ad's click count
      await _adsRef.doc(adId).update({
        'clickCount': FieldValue.increment(1),
        'lastClickTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking user experience
      if (kDebugMode) {
        debugPrint('Error tracking ad click: $e');
      }
    }
  }

  /// Track ad impression for analytics
  Future<void> trackAdImpression(String adId, String userId) async {
    try {
      await _adAnalyticsRef.add({
        'adId': adId,
        'userId': userId,
        'action': 'impression',
        'timestamp': FieldValue.serverTimestamp(),
        'location': 'profile', // Can be parameterized later
      });

      // Also update the ad's impression count
      await _adsRef.doc(adId).update({
        'impressionCount': FieldValue.increment(1),
        'lastImpressionTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking user experience
      if (kDebugMode) {
        debugPrint('Error tracking ad impression: $e');
      }
    }
  }
}
