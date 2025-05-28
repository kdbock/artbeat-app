import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat/data/nc_zip_code_db.dart';
import 'package:artbeat/models/artwork_model.dart';
import 'package:artbeat/models/artist_profile_model.dart';
import 'package:artbeat/models/event_model.dart';
import 'package:artbeat/models/art_walk_model.dart';

/// Service class for North Carolina region-specific operations
class NCRegionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NCZipCodeDatabase _db = NCZipCodeDatabase();

  /// Get all artwork from a specific NC region
  Future<List<ArtworkModel>> getArtworkByRegion(String regionName,
      {int limit = 20}) async {
    // Get ZIP codes for the region
    final zipCodes = _db.getZipCodesByRegion(regionName);

    // Due to Firestore limitations, we'll limit to 10 ZIP codes for the whereIn clause
    // For a production app, you would structure your data differently
    final limitedZipCodes = zipCodes.take(10).toList();

    try {
      final querySnapshot = await _firestore
          .collection('artwork')
          .where('location', whereIn: limitedZipCodes)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // print('Error fetching artwork by region: $e');
      return [];
    }
  }

  /// Get all artists from a specific NC region
  Future<List<ArtistProfileModel>> getArtistsByRegion(String regionName,
      {int limit = 20}) async {
    // Get ZIP codes for the region
    final zipCodes = _db.getZipCodesByRegion(regionName);
    final limitedZipCodes = zipCodes.take(10).toList();

    try {
      final querySnapshot = await _firestore
          .collection('artistProfiles')
          .where('location', whereIn: limitedZipCodes)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ArtistProfileModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // print('Error fetching artists by region: $e');
      return [];
    }
  }

  /// Get all events from a specific NC region
  Future<List<EventModel>> getEventsByRegion(String regionName,
      {int limit = 20}) async {
    // Get ZIP codes for the region
    final zipCodes = _db.getZipCodesByRegion(regionName);
    final limitedZipCodes = zipCodes.take(10).toList();

    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('location', whereIn: limitedZipCodes)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('startDate')
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // print('Error fetching events by region: $e');
      return [];
    }
  }

  /// Get all art walks from a specific NC region
  Future<List<ArtWalkModel>> getArtWalksByRegion(String regionName,
      {int limit = 20}) async {
    // Get ZIP codes for the region
    final zipCodes = _db.getZipCodesByRegion(regionName);
    final limitedZipCodes = zipCodes.take(10).toList();

    try {
      final querySnapshot = await _firestore
          .collection('artWalks')
          .where('zipCode', whereIn: limitedZipCodes)
          .where('isPublic', isEqualTo: true)
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => ArtWalkModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // print('Error fetching art walks by region: $e');
      return [];
    }
  }

  /// Get region statistics (counts of artists, artwork, events, etc.)
  Future<Map<String, int>> getRegionStatistics(String regionName) async {
    final zipCodes = _db.getZipCodesByRegion(regionName);
    final limitedZipCodes = zipCodes.take(10).toList();

    try {
      final Map<String, int> stats = {};

      // Count artists
      final artistsQuery = await _firestore
          .collection('artistProfiles')
          .where('location', whereIn: limitedZipCodes)
          .count()
          .get();
      stats['artistCount'] = artistsQuery.count ?? 0;

      // Count artwork
      final artworkQuery = await _firestore
          .collection('artwork')
          .where('location', whereIn: limitedZipCodes)
          .count()
          .get();
      stats['artworkCount'] = artworkQuery.count ?? 0;

      // Count upcoming events
      final eventsQuery = await _firestore
          .collection('events')
          .where('location', whereIn: limitedZipCodes)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.now())
          .count()
          .get();
      stats['eventCount'] = eventsQuery.count ?? 0;

      // Count public art walks
      final artWalksQuery = await _firestore
          .collection('artWalks')
          .where('zipCode', whereIn: limitedZipCodes)
          .where('isPublic', isEqualTo: true)
          .count()
          .get();
      stats['artWalkCount'] = artWalksQuery.count ?? 0;

      return stats;
    } catch (e) {
      // print('Error fetching region statistics: $e');
      return {
        'artistCount': 0,
        'artworkCount': 0,
        'eventCount': 0,
        'artWalkCount': 0,
      };
    }
  }

  /// Get list of counties for a given region
  List<String> getCountyNames(String regionName) {
    final counties = _db.getCountiesByRegion(regionName);
    return counties.map((county) => county.name).toList();
  }

  /// Check if a ZIP code belongs to a specific region
  bool isZipCodeInRegion(String zipCode, String regionName) {
    final info = _db.getInfoForZipCode(zipCode);
    if (info == null) return false;
    return info.region == regionName;
  }

  /// Get nearby artists by ZIP code within a region
  Future<List<ArtistProfileModel>> getNearbyArtists(String zipCode,
      {int limit = 10}) async {
    final info = _db.getInfoForZipCode(zipCode);
    if (info == null) return [];

    return getArtistsByRegion(info.region, limit: limit);
  }

  /// Get nearby events by ZIP code within a region
  Future<List<EventModel>> getNearbyEvents(String zipCode,
      {int limit = 10}) async {
    final info = _db.getInfoForZipCode(zipCode);
    if (info == null) return [];

    return getEventsByRegion(info.region, limit: limit);
  }
}
