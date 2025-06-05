import 'package:artbeat_artist/artbeat_artist.dart'; // Import ArtistProfileModel
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
      DocumentSnapshot doc, ArtistProfileModel? artist) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ArtworkModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      artistId: data['artistId'] ?? '',
      artist: artist, // Populate artist property
      medium: data['medium'] ?? '',
      location: data['location'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
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
