import 'package:cloud_firestore/cloud_firestore.dart';

/// Status options for gallery invitations
enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
}

/// Model for gallery invitations to artists
class GalleryInvitationModel {
  final String id;
  final String galleryId; // Gallery profile ID
  final String artistId; // Artist profile ID
  final String galleryName; // Gallery display name for UI
  final String artistName; // Artist display name for UI
  final String message; // Custom message to the artist
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime
      expiresAt; // When invitation becomes invalid if not responded to
  final DateTime? respondedAt; // When artist responded
  final String? galleryImageUrl; // For UI display
  final String? artistImageUrl; // For UI display
  final Map<String, dynamic>?
      terms; // Any specific terms or commission rates offered

  GalleryInvitationModel({
    required this.id,
    required this.galleryId,
    required this.artistId,
    required this.galleryName,
    required this.artistName,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.galleryImageUrl,
    this.artistImageUrl,
    this.terms,
  });

  /// Convert Firestore document to GalleryInvitationModel
  factory GalleryInvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryInvitationModel(
      id: doc.id,
      galleryId: data['galleryId'] as String,
      artistId: data['artistId'] as String,
      galleryName: data['galleryName'] as String,
      artistName: data['artistName'] as String,
      message: data['message'] as String,
      status: _statusFromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      galleryImageUrl: data['galleryImageUrl'] as String?,
      artistImageUrl: data['artistImageUrl'] as String?,
      terms: data['terms'] as Map<String, dynamic>?,
    );
  }

  /// Convert GalleryInvitationModel to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'galleryId': galleryId,
      'artistId': artistId,
      'galleryName': galleryName,
      'artistName': artistName,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'respondedAt':
          respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'galleryImageUrl': galleryImageUrl,
      'artistImageUrl': artistImageUrl,
      'terms': terms,
    };
  }

  /// Helper to convert string status to enum
  static InvitationStatus _statusFromString(String status) {
    return InvitationStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => InvitationStatus.pending,
    );
  }

  /// Create a copy of the model with updated fields
  GalleryInvitationModel copyWith({
    String? id,
    String? galleryId,
    String? artistId,
    String? galleryName,
    String? artistName,
    String? message,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
    String? galleryImageUrl,
    String? artistImageUrl,
    Map<String, dynamic>? terms,
  }) {
    return GalleryInvitationModel(
      id: id ?? this.id,
      galleryId: galleryId ?? this.galleryId,
      artistId: artistId ?? this.artistId,
      galleryName: galleryName ?? this.galleryName,
      artistName: artistName ?? this.artistName,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      galleryImageUrl: galleryImageUrl ?? this.galleryImageUrl,
      artistImageUrl: artistImageUrl ?? this.artistImageUrl,
      terms: terms ?? this.terms,
    );
  }
}
