import 'package:artbeat_core/artbeat_core.dart' show ArtistProfileModel;
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtworkModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String artistId;
  final ArtistProfileModel? artist; // Added artist property
  final String medium;
  final String location;
  final Timestamp createdAt;

  ArtworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.artistId,
    this.artist, // Initialize artist as nullable
    required this.medium,
    required this.location,
    required this.createdAt,
  });

  factory ArtworkModel.fromFirestore(
    DocumentSnapshot doc,
    ArtistProfileModel? artist,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtworkModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      artistId: (data['artistId'] as String?) ?? '',
      artist: artist, // Populate artist property
      medium: (data['medium'] as String?) ?? '',
      location: (data['location'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'artistId': artistId,
      'medium': medium,
      'location': location,
      'createdAt': createdAt,
    };
  }
}
