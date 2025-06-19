import 'package:flutter/foundation.dart';
import '../models/ad_artist_model.dart';
import '../services/ad_artist_service.dart';

/// Manages artist ad creation, updates, and state for UI
class ArtistAdManager extends ChangeNotifier {
  final AdArtistService _service = AdArtistService();

  List<AdArtistModel> _ads = [];
  List<AdArtistModel> get ads => _ads;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  Future<void> loadArtistAds(String artistId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _service.getArtistAdsByArtist(artistId).listen((adList) {
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

  Future<String?> createArtistAd(AdArtistModel ad) async {
    try {
      final id = await _service.createArtistAd(ad);
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteArtistAd(String adId) async {
    try {
      await _service.deleteArtistAd(adId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
