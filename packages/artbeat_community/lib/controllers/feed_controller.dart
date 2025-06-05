import 'package:flutter/material.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';

class FeedController extends ChangeNotifier {
  final ArtworkService _artworkService;

  FeedController(this._artworkService);

  List<ArtworkModel> _feedItems = [];
  List<ArtworkModel> get feedItems => _feedItems;

  Future<void> fetchFeed(String userId) async {
    try {
      _feedItems = await _artworkService.getArtworkByArtistProfileId(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching feed: $e');
    }
  }

  Future<void> refreshFeed(String userId) async {
    await fetchFeed(userId);
  }
}
