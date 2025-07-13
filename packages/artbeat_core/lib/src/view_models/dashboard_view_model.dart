import 'package:flutter/foundation.dart';
import 'package:artbeat_core/src/models/artist_profile_model.dart';
import 'package:artbeat_core/src/services/subscription_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final SubscriptionService _subscriptionService;

  bool _isLoadingFeaturedArtists = false;
  List<ArtistProfileModel> _featuredArtists = [];

  DashboardViewModel({required SubscriptionService subscriptionService})
    : _subscriptionService = subscriptionService;

  bool get isLoadingFeaturedArtists => _isLoadingFeaturedArtists;
  List<ArtistProfileModel> get featuredArtists => _featuredArtists;

  Future<void> initialize() async {
    await loadFeaturedArtists();
  }

  Future<void> loadFeaturedArtists() async {
    _isLoadingFeaturedArtists = true;
    notifyListeners();

    try {
      _featuredArtists = await _subscriptionService.getFeaturedArtists();
    } catch (e) {
      debugPrint('Error loading featured artists: $e');
      _featuredArtists = [];
    } finally {
      _isLoadingFeaturedArtists = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadFeaturedArtists();
  }
}
