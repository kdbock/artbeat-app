import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/artist_model.dart';

class ArtistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ArtistModel>> searchArtists(String query) async {
    Query artistsQuery = _firestore.collection('artists');

    if (query.isNotEmpty) {
      // Case-insensitive search using Firebase's array-contains operator
      artistsQuery = artistsQuery.where(
        'searchTerms',
        arrayContains: query.toLowerCase(),
      );
    }

    final snapshot = await artistsQuery.get();
    return snapshot.docs
        .map(
          (doc) => ArtistModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
            null,
          ),
        )
        .toList();
  }

  Future<List<ArtistModel>> getFeaturedArtists() async {
    try {
      final snapshot = await _firestore
          .collection('artists')
          .where('isFeatured', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map(
            (doc) => ArtistModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              null,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting featured artists: $e');
      return [];
    }
  }

  Future<List<ArtistModel>> getAllArtists() async {
    try {
      final snapshot = await _firestore
          .collection('artists')
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map(
            (doc) => ArtistModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              null,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting all artists: $e');
      return [];
    }
  }

  Future<ArtistModel> createArtist(String name) async {
    final artist = ArtistModel(
      id: '', // Will be set by Firestore
      name: name,
      isVerified: false,
    );

    // Generate search terms for case-insensitive search
    final searchTerms = _generateSearchTerms(name);
    final artistData = {...artist.toFirestore(), 'searchTerms': searchTerms};

    final docRef = await _firestore.collection('artists').add(artistData);

    return ArtistModel(
      id: docRef.id,
      name: name,
      isVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<String> _generateSearchTerms(String name) {
    final terms = <String>[];
    final nameLower = name.toLowerCase();

    // Add full name
    terms.add(nameLower);

    // Add each word
    terms.addAll(nameLower.split(' '));

    // Add prefixes of each word for partial matching
    for (final word in nameLower.split(' ')) {
      for (int i = 1; i <= word.length; i++) {
        terms.add(word.substring(0, i));
      }
    }

    return terms.toSet().toList(); // Remove duplicates
  }
}
