import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_model.dart';
import '../models/ad_location.dart';
import '../models/ad_status.dart';

/// Base service for managing ads (CRUD)
class AdService {
  final _adsRef = FirebaseFirestore.instance.collection('ads');

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
    final randomIndex = DateTime.now().millisecondsSinceEpoch % query.docs.length;
    final doc = query.docs[randomIndex];
    
    return AdModel.fromMap(doc.data(), doc.id);
  }
}
