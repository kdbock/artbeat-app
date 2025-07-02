import 'package:flutter/foundation.dart';
import '../models/ad_user_model.dart';
import '../services/ad_user_service.dart';

/// Manages user ad creation, updates, and state for UI
class UserAdManager extends ChangeNotifier {
  final AdUserService _service = AdUserService();

  List<AdUserModel> _ads = [];
  List<AdUserModel> get ads => _ads;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  Future<void> loadUserAds(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _service.getUserAdsByUser(userId).listen((adList) {
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

  Future<String?> createUserAd(AdUserModel ad) async {
    try {
      final id = await _service.createUserAd(ad);
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteUserAd(String adId) async {
    try {
      await _service.deleteUserAd(adId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
