import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_user_model.dart';

/// Service for user-purchased ads
class AdUserService {
  final _userAdsRef = FirebaseFirestore.instance.collection('user_ads');

  Future<String> createUserAd(AdUserModel ad) async {
    final doc = await _userAdsRef.add(ad.toMap());
    return doc.id;
  }

  Future<void> updateUserAd(String adId, Map<String, dynamic> data) async {
    await _userAdsRef.doc(adId).update(data);
  }

  Future<void> deleteUserAd(String adId) async {
    await _userAdsRef.doc(adId).delete();
  }

  Future<AdUserModel?> getUserAd(String adId) async {
    final doc = await _userAdsRef.doc(adId).get();
    if (!doc.exists) return null;
    return AdUserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<AdUserModel>> getUserAdsByUser(String userId) {
    return _userAdsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdUserModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }
}
