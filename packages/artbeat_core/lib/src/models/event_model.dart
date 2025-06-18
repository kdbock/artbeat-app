import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an event in the ARTbeat app
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? imageUrl;
  final String artistId; // Creator of the event
  final bool isPublic; // Whether event shows on community calendar
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
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      location: data['location'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      artistId: data['artistId'] as String? ?? '',
      isPublic: data['isPublic'] as bool? ?? false,
      attendeeIds: List<String>.from(
        data['attendeeIds'] as List<dynamic>? ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert model to a Firestore document
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

  /// Create a copy of this EventModel with given fields replaced
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
