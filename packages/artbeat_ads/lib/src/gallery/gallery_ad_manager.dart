import 'package:flutter/foundation.dart';
import '../models/ad_gallery_model.dart';
import '../services/ad_gallery_service.dart';

/// Manages gallery ad creation, updates, and state for UI
class GalleryAdManager extends ChangeNotifier {
  final AdGalleryService _service = AdGalleryService();

  List<AdGalleryModel> _ads = [];
  List<AdGalleryModel> get ads => _ads;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  Future<void> loadGalleryAds(String galleryId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _service.getGalleryAdsByGallery(galleryId).listen((adList) {
        _ads = adList;
        _loading = false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> createGalleryAd(AdGalleryModel ad) async {
    try {
      final id = await _service.createGalleryAd(ad);
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteGalleryAd(String adId) async {
    try {
      await _service.deleteGalleryAd(adId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
