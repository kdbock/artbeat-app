import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'ticket_type.dart';
import 'refund_policy.dart';

/// Main event model for the ARTbeat events system
/// Supports multiple images, ticketing, and comprehensive event management
class ArtbeatEvent {
  final String id;
  final String title;
  final String description;
  final String artistId;
  final List<String> imageUrls; // multiple event images
  final String artistHeadshotUrl;
  final String eventBannerUrl;
  final DateTime dateTime;
  final String location;
  final List<TicketType> ticketTypes;
  final RefundPolicy refundPolicy;
  final bool reminderEnabled;
  final bool isPublic; // Whether event shows on community calendar
  final List<String> attendeeIds;
  final int maxAttendees;
  final List<String> tags; // art-related tags for categorization
  final String contactEmail;
  final String? contactPhone;
  final Map<String, dynamic>? metadata; // for additional event-specific data
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArtbeatEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.artistId,
    required this.imageUrls,
    required this.artistHeadshotUrl,
    required this.eventBannerUrl,
    required this.dateTime,
    required this.location,
    required this.ticketTypes,
    required this.refundPolicy,
    required this.reminderEnabled,
    this.isPublic = true,
    this.attendeeIds = const [],
    this.maxAttendees = 100,
    this.tags = const [],
    required this.contactEmail,
    this.contactPhone,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor to create a new event with generated ID
  factory ArtbeatEvent.create({
    required String title,
    required String description,
    required String artistId,
    required List<String> imageUrls,
    required String artistHeadshotUrl,
    required String eventBannerUrl,
    required DateTime dateTime,
    required String location,
    required List<TicketType> ticketTypes,
    RefundPolicy? refundPolicy,
    bool reminderEnabled = true,
    bool isPublic = true,
    int maxAttendees = 100,
    List<String> tags = const [],
    required String contactEmail,
    String? contactPhone,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return ArtbeatEvent(
      id: const Uuid().v4(),
      title: title,
      description: description,
      artistId: artistId,
      imageUrls: imageUrls,
      artistHeadshotUrl: artistHeadshotUrl,
      eventBannerUrl: eventBannerUrl,
      dateTime: dateTime,
      location: location,
      ticketTypes: ticketTypes,
      refundPolicy: refundPolicy ?? const RefundPolicy(),
      reminderEnabled: reminderEnabled,
      isPublic: isPublic,
      attendeeIds: [],
      maxAttendees: maxAttendees,
      tags: tags,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Create an ArtbeatEvent from a Firestore document
  factory ArtbeatEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ArtbeatEvent(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      artistId: data['artistId']?.toString() ?? '',
      imageUrls: _parseStringList(data['imageUrls']),
      artistHeadshotUrl: data['artistHeadshotUrl']?.toString() ?? '',
      eventBannerUrl: data['eventBannerUrl']?.toString() ?? '',
      dateTime: _parseDateTime(data['dateTime']),
      location: data['location']?.toString() ?? '',
      ticketTypes: _parseTicketTypes(data['ticketTypes']),
      refundPolicy: RefundPolicy.fromMap(data['refundPolicy'] ?? {}),
      reminderEnabled: data['reminderEnabled'] as bool? ?? true,
      isPublic: data['isPublic'] as bool? ?? true,
      attendeeIds: _parseStringList(data['attendeeIds']),
      maxAttendees: data['maxAttendees'] as int? ?? 100,
      tags: _parseStringList(data['tags']),
      contactEmail: data['contactEmail']?.toString() ?? '',
      contactPhone: data['contactPhone']?.toString(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// Convert ArtbeatEvent to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'artistId': artistId,
      'imageUrls': imageUrls,
      'artistHeadshotUrl': artistHeadshotUrl,
      'eventBannerUrl': eventBannerUrl,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'ticketTypes': ticketTypes.map((t) => t.toMap()).toList(),
      'refundPolicy': refundPolicy.toMap(),
      'reminderEnabled': reminderEnabled,
      'isPublic': isPublic,
      'attendeeIds': attendeeIds,
      'maxAttendees': maxAttendees,
      'tags': tags,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy of this ArtbeatEvent with the given fields replaced
  ArtbeatEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? artistId,
    List<String>? imageUrls,
    String? artistHeadshotUrl,
    String? eventBannerUrl,
    DateTime? dateTime,
    String? location,
    List<TicketType>? ticketTypes,
    RefundPolicy? refundPolicy,
    bool? reminderEnabled,
    bool? isPublic,
    List<String>? attendeeIds,
    int? maxAttendees,
    List<String>? tags,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtbeatEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      artistId: artistId ?? this.artistId,
      imageUrls: imageUrls ?? this.imageUrls,
      artistHeadshotUrl: artistHeadshotUrl ?? this.artistHeadshotUrl,
      eventBannerUrl: eventBannerUrl ?? this.eventBannerUrl,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      ticketTypes: ticketTypes ?? this.ticketTypes,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isPublic: isPublic ?? this.isPublic,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      tags: tags ?? this.tags,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Check if the event is sold out
  bool get isSoldOut {
    final totalSold = ticketTypes.fold<int>(
      0,
      (total, ticket) => total + (ticket.quantitySold ?? 0),
    );
    return totalSold >= maxAttendees;
  }

  /// Check if the event has passed
  bool get hasEnded => DateTime.now().isAfter(dateTime);

  /// Check if refunds are still available
  bool get canRefund {
    final deadline = dateTime.subtract(refundPolicy.fullRefundDeadline);
    return DateTime.now().isBefore(deadline);
  }

  /// Get total available tickets
  int get totalAvailableTickets {
    return ticketTypes.fold<int>(
      0,
      (total, ticket) => total + ticket.quantity,
    );
  }

  /// Get total tickets sold
  int get totalTicketsSold {
    return ticketTypes.fold<int>(
      0,
      (total, ticket) => total + (ticket.quantitySold ?? 0),
    );
  }

  /// Check if event has free tickets
  bool get hasFreeTickets {
    return ticketTypes.any((ticket) => ticket.category == TicketCategory.free);
  }

  /// Check if event has paid tickets
  bool get hasPaidTickets {
    return ticketTypes.any((ticket) => ticket.category != TicketCategory.free);
  }

  // Helper methods for parsing Firestore data
  static List<String> _parseStringList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime _parseDateTime(dynamic data) {
    if (data is Timestamp) {
      return data.toDate();
    }
    return DateTime.now();
  }

  static List<TicketType> _parseTicketTypes(dynamic data) {
    if (data is List) {
      return data
          .map((e) => TicketType.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  String toString() {
    return 'ArtbeatEvent{id: $id, title: $title, dateTime: $dateTime, location: $location}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtbeatEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
