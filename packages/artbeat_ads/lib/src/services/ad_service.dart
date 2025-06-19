import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_model.dart';

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
}
