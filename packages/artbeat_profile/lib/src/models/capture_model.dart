import 'package:cloud_firestore/cloud_firestore.dart';

class CaptureModel {
  final String id;
  final String userId;
  final String? title;
  final List<String>? textAnnotations;
  final String? imageUrl;
  final String? thumbnailUrl;
  final DateTime? createdAt;
  final String? location; // Could be a GeoPoint or a formatted address string
  final String?
      userDisplayName; // To store the name of the user who made the capture

  CaptureModel({
    required this.id,
    required this.userId,
    this.title,
    this.textAnnotations,
    this.imageUrl,
    this.thumbnailUrl,
    this.createdAt,
    this.location,
    this.userDisplayName,
  });

  factory CaptureModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CaptureModel(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String?,
      textAnnotations: map['textAnnotations'] != null
          ? List<String>.from(map['textAnnotations'] as List<dynamic>)
          : null,
      imageUrl: map['imageUrl'] as String?,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      location: map['location'] as String?,
      userDisplayName: map['userDisplayName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'textAnnotations': textAnnotations,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'location': location,
      'userDisplayName': userDisplayName,
    };
  }
}
