import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryInvitationModel {
  final String id;
  final String galleryId;
  final String artistId;
  final String galleryName;
  final String artistName;
  final String message;
  final String status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? galleryImageUrl;
  final String? artistImageUrl;
  final Map<String, dynamic>? terms;

  GalleryInvitationModel({
    required this.id,
    required this.galleryId,
    required this.artistId,
    required this.galleryName,
    required this.artistName,
    required this.message,
    required this.status,
    this.createdAt,
    this.expiresAt,
    this.galleryImageUrl,
    this.artistImageUrl,
    this.terms,
  });

  factory GalleryInvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryInvitationModel(
      id: doc.id,
      galleryId: data['galleryId'] ?? '',
      artistId: data['artistId'] ?? '',
      galleryName: data['galleryName'] ?? '',
      artistName: data['artistName'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      galleryImageUrl: data['galleryImageUrl'],
      artistImageUrl: data['artistImageUrl'],
      terms: data['terms'],
    );
  }
}
