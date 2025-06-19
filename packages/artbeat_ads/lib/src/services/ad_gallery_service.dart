import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_gallery_model.dart';

/// Service for gallery/institution ads
class AdGalleryService {
  final _galleryAdsRef = FirebaseFirestore.instance.collection('gallery_ads');

  Future<String> createGalleryAd(AdGalleryModel ad) async {
    final doc = await _galleryAdsRef.add(ad.toMap());
    return doc.id;
  }

  Future<void> updateGalleryAd(String adId, Map<String, dynamic> data) async {
    await _galleryAdsRef.doc(adId).update(data);
  }

  Future<void> deleteGalleryAd(String adId) async {
    await _galleryAdsRef.doc(adId).delete();
  }

  Future<AdGalleryModel?> getGalleryAd(String adId) async {
    final doc = await _galleryAdsRef.doc(adId).get();
    if (!doc.exists) return null;
    return AdGalleryModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<AdGalleryModel>> getGalleryAdsByGallery(String galleryId) {
    return _galleryAdsRef
        .where('galleryId', isEqualTo: galleryId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdGalleryModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }
}
