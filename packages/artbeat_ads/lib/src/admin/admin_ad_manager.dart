import 'package:flutter/foundation.dart';
import '../models/ad_model.dart';
import '../services/ad_service.dart';

/// Manages admin ad creation, updates, and state for UI
class AdminAdManager extends ChangeNotifier {
  final AdService _service = AdService();

  List<AdModel> _ads = [];
  List<AdModel> get ads => _ads;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  Future<void> loadAllAds() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _service.getAllAds().listen((adList) {
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

  Future<String?> createAdminAd(AdModel ad) async {
    try {
      final id = await _service.createAd(ad);
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateAdminAd(String adId, Map<String, dynamic> data) async {
    try {
      await _service.updateAd(adId, data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteAdminAd(String adId) async {
    try {
      await _service.deleteAd(adId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
