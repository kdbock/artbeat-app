import 'package:cloud_firestore/cloud_firestore.dart';

class SponsorModel {
  final String id;
  final String sponsorName;
  final String sponsorLogoUrl;
  final String sponsoredArtworkId;
  final String description;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  SponsorModel({
    required this.id,
    required this.sponsorName,
    required this.sponsorLogoUrl,
    required this.sponsoredArtworkId,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SponsorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SponsorModel(
      id: doc.id,
      sponsorName: data['sponsorName'] ?? '',
      sponsorLogoUrl: data['sponsorLogoUrl'] ?? '',
      sponsoredArtworkId: data['sponsoredArtworkId'] ?? '',
      description: data['description'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sponsorName': sponsorName,
      'sponsorLogoUrl': sponsorLogoUrl,
      'sponsoredArtworkId': sponsoredArtworkId,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
