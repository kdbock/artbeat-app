import 'package:cloud_firestore/cloud_firestore.dart';

/// Internal event model for the artist module
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? imageUrl;
  final String artistId;
  final bool isPublic;
  final List<String> attendeeIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    this.imageUrl,
    required this.artistId,
    required this.isPublic,
    required this.attendeeIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create an EventModel from a Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      title: data['title'] != null ? data['title'].toString() : '',
      description:
          data['description'] != null ? data['description'].toString() : '',
      startDate: data['startDate'] is Timestamp
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] is Timestamp
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      location: data['location'] != null ? data['location'].toString() : '',
      imageUrl: data['imageUrl'] != null ? data['imageUrl'].toString() : null,
      artistId: data['artistId'] != null ? data['artistId'].toString() : '',
      isPublic: data['isPublic'] is bool ? data['isPublic'] as bool : false,
      attendeeIds: data['attendeeIds'] is List
          ? (data['attendeeIds'] as List).map((e) => e.toString()).toList()
          : <String>[],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert EventModel to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'imageUrl': imageUrl,
      'artistId': artistId,
      'isPublic': isPublic,
      'attendeeIds': attendeeIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of this EventModel with the given fields replaced
  EventModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    String? artistId,
    bool? isPublic,
    List<String>? attendeeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      artistId: artistId ?? this.artistId,
      isPublic: isPublic ?? this.isPublic,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
