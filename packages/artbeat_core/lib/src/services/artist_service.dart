import 'package:cloud_firestore/cloud_firestore.dart';
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

    final snapshot = await artistsQuery
        .orderBy('name')
        .limit(10)
        .withConverter(
          fromFirestore: ArtistModel.fromFirestore,
          toFirestore: (ArtistModel artist, _) => artist.toFirestore(),
        )
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<ArtistModel> createArtist(String name) async {
    final artist = ArtistModel(
      id: '', // Will be set by Firestore
      name: name,
      isVerified: false,
    );

    // Generate search terms for case-insensitive search
    final searchTerms = _generateSearchTerms(name);
    final artistData = {
      ...artist.toFirestore(),
      'searchTerms': searchTerms,
    };

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
