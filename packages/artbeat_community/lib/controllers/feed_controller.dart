import 'package:flutter/material.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_core/artbeat_core.dart';

class FeedController extends ChangeNotifier {
  final artwork.ArtworkService _artworkService;

  FeedController(this._artworkService);

  List<artwork.ArtworkModel> _feedItems = [];
  List<artwork.ArtworkModel> get feedItems => _feedItems;

  Future<void> fetchFeed(String userId) async {
    try {
      _feedItems = await _artworkService.getArtworkByArtistProfileId(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error fetching feed: $e');
    }
  }

  Future<void> refreshFeed(String userId) async {
    await fetchFeed(userId);
  }
}
