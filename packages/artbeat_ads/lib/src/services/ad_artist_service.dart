import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_artist_model.dart';

/// Service for artist-created ads
class AdArtistService {
  final _artistAdsRef = FirebaseFirestore.instance.collection('artist_ads');

  Future<String> createArtistAd(AdArtistModel ad) async {
    final doc = await _artistAdsRef.add(ad.toMap());
    return doc.id;
  }

  Future<void> updateArtistAd(String adId, Map<String, dynamic> data) async {
    await _artistAdsRef.doc(adId).update(data);
  }

  Future<void> deleteArtistAd(String adId) async {
    await _artistAdsRef.doc(adId).delete();
  }

  Future<AdArtistModel?> getArtistAd(String adId) async {
    final doc = await _artistAdsRef.doc(adId).get();
    if (!doc.exists) return null;
    return AdArtistModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<AdArtistModel>> getArtistAdsByArtist(String artistId) {
    return _artistAdsRef
        .where('artistId', isEqualTo: artistId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdArtistModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }
}
