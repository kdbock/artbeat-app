import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/ad_model.dart';
import '../services/simple_ad_service.dart';

/// Manages gallery ad creation, updates, and state for UI - Simplified Version
class GalleryAdManager extends ChangeNotifier {
  final SimpleAdService _service = SimpleAdService();

  List<AdModel> _ads = [];
  List<AdModel> get ads => _ads;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  Future<void> loadGalleryAds(String galleryId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _service.getAdsByOwner(galleryId).listen((adList) {
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

  Future<String?> createGalleryAd(AdModel ad, List<File> images) async {
    try {
      final id = await _service.createAdWithImages(ad, images);
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteGalleryAd(String adId) async {
    try {
      await _service.deleteAd(adId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
