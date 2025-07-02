import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/artist_profile_model.dart';

class ArtistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ArtistProfileModel>> getFeaturedArtists() async {
    try {
      debugPrint('🎨 ArtistService: Fetching featured artists...');
      final snapshot = await _firestore
          .collection('artists')
          .where('isFeatured', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10));

      final artists = snapshot.docs
          .map((doc) => ArtistProfileModel.fromMap(doc.data()..['id'] = doc.id))
          .toList();

      debugPrint('🎨 ArtistService: Loaded ${artists.length} featured artists');
      return artists;
    } catch (e) {
      debugPrint('❌ ArtistService: Error fetching featured artists: $e');
      return [];
    }
  }
}
