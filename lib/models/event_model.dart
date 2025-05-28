import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model representing an event in the ARTbeat app
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final String location;
  final String imageUrl;
  final String userId; // Creator of the event
  final bool isPublic; // Whether event shows on community calendar
  final List<String> attendees;
  final Map<String, dynamic>? metadata;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.location,
    required this.imageUrl,
    required this.userId,
    required this.isPublic,
    required this.attendees,
    this.metadata,
  });

  /// Convert TimeOfDay to minutes since midnight for Firestore storage
  static int _timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Convert minutes since midnight to TimeOfDay
  static TimeOfDay _minutesToTimeOfDay(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  /// Create an EventModel from a Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert Firestore Timestamp to DateTime
    final dateTime = (data['date'] as Timestamp).toDate();

    // Convert stored minutes to TimeOfDay
    final startTimeMinutes = data['startTimeMinutes'] as int;
    final startTime = _minutesToTimeOfDay(startTimeMinutes);

    // Handle optional endTime
    TimeOfDay? endTime;
    if (data['endTimeMinutes'] != null) {
      final endTimeMinutes = data['endTimeMinutes'] as int;
      endTime = _minutesToTimeOfDay(endTimeMinutes);
    }

    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: dateTime,
      startTime: startTime,
      endTime: endTime,
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      userId: data['userId'] ?? '',
      isPublic: data['isPublic'] ?? false,
      attendees: List<String>.from(data['attendees'] ?? []),
      metadata: data['metadata'],
    );
  }

  /// Convert model to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'startTimeMinutes': _timeOfDayToMinutes(startTime),
      if (endTime != null) 'endTimeMinutes': _timeOfDayToMinutes(endTime!),
      'location': location,
      'imageUrl': imageUrl,
      'userId': userId,
      'isPublic': isPublic,
      'attendees': attendees,
      if (metadata != null) 'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy of this EventModel with the given fields replaced
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? location,
    String? imageUrl,
    String? userId,
    bool? isPublic,
    List<String>? attendees,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      isPublic: isPublic ?? this.isPublic,
      attendees: attendees ?? this.attendees,
      metadata: metadata ?? this.metadata,
    );
  }
}
