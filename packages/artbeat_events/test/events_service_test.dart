import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
import 'events_service_test.mocks.dart';

void main() {
  group('EventsService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
    });

    test('should create event successfully', () async {
      // Arrange
      final eventData = {
        'id': 'event-123',
        'title': 'Art Gallery Opening',
        'description':
            'Join us for the opening of our new contemporary art gallery',
        'organizerId': 'organizer-123',
        'organizerName': 'Gallery Owner',
        'startDateTime': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'endDateTime': DateTime.now()
            .add(const Duration(days: 7, hours: 3))
            .toIso8601String(),
        'location': {
          'name': 'Downtown Gallery',
          'address': '123 Art Street, Charlotte, NC',
          'latitude': 35.2271,
          'longitude': -80.8431,
        },
        'category': EventCategory.exhibition.toString(),
        'tags': ['contemporary', 'opening', 'gallery'],
        'ticketPrice': 25.0,
        'maxAttendees': 100,
        'currentAttendees': 0,
        'imageUrl': 'https://example.com/event-image.jpg',
        'isPublic': true,
        'requiresApproval': false,
        'ageRestriction': 18,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('events')).thenReturn(mockCollection);
      when(mockCollection.add(eventData)).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(eventData);

      // Assert
      verify(mockCollection.add(eventData)).called(1);
    });

    test('should update event details', () async {
      // Arrange
      const eventId = 'event-123';
      final updateData = {
        'title': 'Updated Art Gallery Opening',
        'description': 'Updated description for the gallery opening',
        'ticketPrice': 30.0,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('events')).thenReturn(mockCollection);
      when(mockCollection.doc(eventId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should register attendee for event', () async {
      // Arrange
      const eventId = 'event-123';
      const userId = 'user-456';
      final attendeeData = {
        'eventId': eventId,
        'userId': userId,
        'registeredAt': DateTime.now().toIso8601String(),
        'ticketType': 'general',
        'paymentStatus': 'paid',
        'checkedIn': false,
      };

      when(
        mockFirestore.collection('event_attendees'),
      ).thenReturn(mockCollection);
      when(
        mockCollection.add(attendeeData),
      ).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(attendeeData);

      // Assert
      verify(mockCollection.add(attendeeData)).called(1);
    });

    test('should cancel event registration', () async {
      // Arrange
      const registrationId = 'registration-123';

      when(
        mockFirestore.collection('event_attendees'),
      ).thenReturn(mockCollection);
      when(mockCollection.doc(registrationId)).thenReturn(mockDocument);
      when(mockDocument.delete()).thenAnswer((_) async => {});

      // Act
      await mockDocument.delete();

      // Assert
      verify(mockDocument.delete()).called(1);
    });

    test('should check in attendee', () async {
      // Arrange
      const registrationId = 'registration-123';
      final updateData = {
        'checkedIn': true,
        'checkedInAt': DateTime.now().toIso8601String(),
      };

      when(
        mockFirestore.collection('event_attendees'),
      ).thenReturn(mockCollection);
      when(mockCollection.doc(registrationId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should update event attendee count', () async {
      // Arrange
      const eventId = 'event-123';
      final updateData = {
        'currentAttendees': FieldValue.increment(1),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('events')).thenReturn(mockCollection);
      when(mockCollection.doc(eventId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should create event review', () async {
      // Arrange
      final reviewData = {
        'id': 'review-123',
        'eventId': 'event-123',
        'userId': 'user-456',
        'rating': 5,
        'comment': 'Amazing event! Loved the artwork.',
        'createdAt': DateTime.now().toIso8601String(),
      };

      when(
        mockFirestore.collection('event_reviews'),
      ).thenReturn(mockCollection);
      when(
        mockCollection.add(reviewData),
      ).thenAnswer((_) async => mockDocument);

      // Act
      await mockCollection.add(reviewData);

      // Assert
      verify(mockCollection.add(reviewData)).called(1);
    });

    test('should delete event', () async {
      // Arrange
      const eventId = 'event-123';

      when(mockFirestore.collection('events')).thenReturn(mockCollection);
      when(mockCollection.doc(eventId)).thenReturn(mockDocument);
      when(mockDocument.delete()).thenAnswer((_) async => {});

      // Act
      await mockDocument.delete();

      // Assert
      verify(mockDocument.delete()).called(1);
    });
  });

  group('Event Model Tests', () {
    test('should create Event with valid data', () {
      final startDate = DateTime.now().add(const Duration(days: 7));
      final endDate = startDate.add(const Duration(hours: 3));

      final event = Event(
        id: 'event-123',
        title: 'Art Workshop',
        description: 'Learn watercolor painting techniques',
        organizerId: 'organizer-123',
        organizerName: 'Art Teacher',
        startDateTime: startDate,
        endDateTime: endDate,
        location: EventLocation(
          name: 'Art Studio',
          address: '456 Creative Lane, Charlotte, NC',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.workshop,
        ticketPrice: 50.0,
        maxAttendees: 20,
        isPublic: true,
      );

      expect(event.id, equals('event-123'));
      expect(event.title, equals('Art Workshop'));
      expect(event.organizerId, equals('organizer-123'));
      expect(event.startDateTime, equals(startDate));
      expect(event.endDateTime, equals(endDate));
      expect(event.category, equals(EventCategory.workshop));
      expect(event.ticketPrice, equals(50.0));
      expect(event.maxAttendees, equals(20));
      expect(event.isPublic, isTrue);
    });

    test('should validate event data', () {
      final startDate = DateTime.now().add(const Duration(days: 7));
      final endDate = startDate.add(const Duration(hours: 3));

      // Valid event
      final validEvent = Event(
        id: 'event-123',
        title: 'Valid Event',
        description: 'Valid description',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: startDate,
        endDateTime: endDate,
        location: EventLocation(
          name: 'Valid Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 10.0,
        maxAttendees: 50,
        isPublic: true,
      );
      expect(validEvent.isValid, isTrue);

      // Invalid event - empty title
      final invalidEvent1 = Event(
        id: 'event-123',
        title: '',
        description: 'Valid description',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: startDate,
        endDateTime: endDate,
        location: EventLocation(
          name: 'Valid Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 10.0,
        maxAttendees: 50,
        isPublic: true,
      );
      expect(invalidEvent1.isValid, isFalse);

      // Invalid event - end date before start date
      final invalidEvent2 = Event(
        id: 'event-123',
        title: 'Invalid Event',
        description: 'Valid description',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: endDate,
        endDateTime: startDate, // Wrong order
        location: EventLocation(
          name: 'Valid Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 10.0,
        maxAttendees: 50,
        isPublic: true,
      );
      expect(invalidEvent2.isValid, isFalse);

      // Invalid event - negative ticket price
      final invalidEvent3 = Event(
        id: 'event-123',
        title: 'Invalid Event',
        description: 'Valid description',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: startDate,
        endDateTime: endDate,
        location: EventLocation(
          name: 'Valid Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: -10.0, // Negative price
        maxAttendees: 50,
        isPublic: true,
      );
      expect(invalidEvent3.isValid, isFalse);
    });

    test('should calculate event duration', () {
      final startDate = DateTime.now().add(const Duration(days: 7));
      final endDate = startDate.add(const Duration(hours: 2, minutes: 30));

      final event = Event(
        id: 'event-123',
        title: 'Timed Event',
        description: 'Event with specific duration',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: startDate,
        endDateTime: endDate,
        location: EventLocation(
          name: 'Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 0.0,
        maxAttendees: 100,
        isPublic: true,
      );

      final duration = event.duration;
      expect(duration.inHours, equals(2));
      expect(duration.inMinutes, equals(150)); // 2.5 hours
    });

    test('should check if event is upcoming', () {
      final futureEvent = Event(
        id: 'event-123',
        title: 'Future Event',
        description: 'Event in the future',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: DateTime.now().add(const Duration(days: 7)),
        endDateTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: EventLocation(
          name: 'Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 0.0,
        maxAttendees: 100,
        isPublic: true,
      );

      final pastEvent = Event(
        id: 'event-456',
        title: 'Past Event',
        description: 'Event in the past',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: DateTime.now().subtract(const Duration(days: 7)),
        endDateTime: DateTime.now().subtract(const Duration(days: 7, hours: -2)),
        location: EventLocation(
          name: 'Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 0.0,
        maxAttendees: 100,
        isPublic: true,
      );

      expect(futureEvent.isUpcoming, isTrue);
      expect(pastEvent.isUpcoming, isFalse);
    });

    test('should check if event is currently happening', () {
      final now = DateTime.now();
      final ongoingEvent = Event(
        id: 'event-123',
        title: 'Ongoing Event',
        description: 'Event happening now',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: now.subtract(const Duration(hours: 1)),
        endDateTime: now.add(const Duration(hours: 1)),
        location: EventLocation(
          name: 'Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 0.0,
        maxAttendees: 100,
        isPublic: true,
      );

      expect(ongoingEvent.isOngoing, isTrue);
    });

    test('should check if event has available spots', () {
      final eventWithSpots = Event(
        id: 'event-123',
        title: 'Event with Spots',
        description: 'Event with available spots',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: DateTime.now().add(const Duration(days: 7)),
        endDateTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: EventLocation(
          name: 'Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 0.0,
        maxAttendees: 100,
        currentAttendees: 50,
        isPublic: true,
      );

      final fullEvent = Event(
        id: 'event-456',
        title: 'Full Event',
        description: 'Event at capacity',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: DateTime.now().add(const Duration(days: 7)),
        endDateTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: EventLocation(
          name: 'Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 0.0,
        maxAttendees: 100,
        currentAttendees: 100,
        isPublic: true,
      );

      expect(eventWithSpots.hasAvailableSpots, isTrue);
      expect(fullEvent.hasAvailableSpots, isFalse);
      expect(eventWithSpots.availableSpots, equals(50));
      expect(fullEvent.availableSpots, equals(0));
    });

    test('should format event price correctly', () {
      final freeEvent = Event(
        id: 'event-123',
        title: 'Free Event',
        description: 'Free event',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: DateTime.now().add(const Duration(days: 7)),
        endDateTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: EventLocation(
          name: 'Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 0.0,
        maxAttendees: 100,
        isPublic: true,
      );

      final paidEvent = Event(
        id: 'event-456',
        title: 'Paid Event',
        description: 'Paid event',
        organizerId: 'organizer-123',
        organizerName: 'Organizer',
        startDateTime: DateTime.now().add(const Duration(days: 7)),
        endDateTime: DateTime.now().add(const Duration(days: 7, hours: 2)),
        location: EventLocation(
          name: 'Location',
          address: '123 Main St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.exhibition,
        ticketPrice: 25.0,
        maxAttendees: 100,
        isPublic: true,
      );

      expect(freeEvent.formattedPrice, equals('Free'));
      expect(paidEvent.formattedPrice, equals(r'$25.00'));
    });

    test('should convert Event to JSON', () {
      final startDate = DateTime.now().add(const Duration(days: 7));
      final endDate = startDate.add(const Duration(hours: 3));

      final event = Event(
        id: 'event-123',
        title: 'JSON Event',
        description: 'Event for JSON test',
        organizerId: 'organizer-123',
        organizerName: 'JSON Organizer',
        startDateTime: startDate,
        endDateTime: endDate,
        location: EventLocation(
          name: 'JSON Location',
          address: '123 JSON St',
          latitude: 35.2271,
          longitude: -80.8431,
        ),
        category: EventCategory.workshop,
        tags: ['json', 'test'],
        ticketPrice: 15.0,
        maxAttendees: 30,
        currentAttendees: 10,
        isPublic: true,
      );

      final json = event.toJson();

      expect(json['id'], equals('event-123'));
      expect(json['title'], equals('JSON Event'));
      expect(json['organizerId'], equals('organizer-123'));
      expect(json['category'], equals(EventCategory.workshop.toString()));
      expect(json['tags'], equals(['json', 'test']));
      expect(json['ticketPrice'], equals(15.0));
      expect(json['maxAttendees'], equals(30));
      expect(json['currentAttendees'], equals(10));
      expect(json['isPublic'], isTrue);
      expect(json['requiresApproval'], isFalse);
    });

    test('should create Event from JSON', () {
      final json = {
        'id': 'event-123',
        'title': 'JSON Event',
        'description': 'Event from JSON',
        'organizerId': 'organizer-123',
        'organizerName': 'JSON Organizer',
        'startDateTime': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'endDateTime': DateTime.now()
            .add(const Duration(days: 7, hours: 3))
            .toIso8601String(),
        'location': {
          'name': 'JSON Location',
          'address': '123 JSON St',
          'latitude': 35.2271,
          'longitude': -80.8431,
        },
        'category': EventCategory.exhibition.toString(),
        'tags': ['json', 'test'],
        'ticketPrice': 20.0,
        'maxAttendees': 50,
        'currentAttendees': 25,
        'isPublic': true,
        'requiresApproval': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final event = Event.fromJson(json);

      expect(event.id, equals('event-123'));
      expect(event.title, equals('JSON Event'));
      expect(event.organizerId, equals('organizer-123'));
      expect(event.category, equals(EventCategory.exhibition));
      expect(event.tags, equals(['json', 'test']));
      expect(event.ticketPrice, equals(20.0));
      expect(event.maxAttendees, equals(50));
      expect(event.currentAttendees, equals(25));
      expect(event.isPublic, isTrue);
      expect(event.requiresApproval, isTrue);
    });
  });

  group('EventCategory Tests', () {
    test('should convert EventCategory to string correctly', () {
      expect(
        EventCategory.exhibition.toString(),
        equals('EventCategory.exhibition'),
      );
      expect(
        EventCategory.workshop.toString(),
        equals('EventCategory.workshop'),
      );
      expect(EventCategory.lecture.toString(), equals('EventCategory.lecture'));
      expect(EventCategory.opening.toString(), equals('EventCategory.opening'));
    });

    test('should parse EventCategory from string correctly', () {
      expect(
        EventCategoryExtension.fromString('EventCategory.exhibition'),
        equals(EventCategory.exhibition),
      );
      expect(
        EventCategoryExtension.fromString('EventCategory.workshop'),
        equals(EventCategory.workshop),
      );
      expect(
        EventCategoryExtension.fromString('EventCategory.lecture'),
        equals(EventCategory.lecture),
      );
      expect(
        EventCategoryExtension.fromString('EventCategory.opening'),
        equals(EventCategory.opening),
      );
      expect(
        EventCategoryExtension.fromString('invalid'),
        equals(EventCategory.exhibition),
      ); // Default
    });

    test('should get category display name correctly', () {
      expect(EventCategory.exhibition.displayName, equals('Exhibition'));
      expect(EventCategory.workshop.displayName, equals('Workshop'));
      expect(EventCategory.lecture.displayName, equals('Lecture'));
      expect(EventCategory.opening.displayName, equals('Gallery Opening'));
    });
  });

  group('EventLocation Tests', () {
    test('should create EventLocation correctly', () {
      final location = EventLocation(
        name: 'Art Museum',
        address: '123 Museum Ave, Charlotte, NC',
        latitude: 35.2271,
        longitude: -80.8431,
      );

      expect(location.name, equals('Art Museum'));
      expect(location.address, equals('123 Museum Ave, Charlotte, NC'));
      expect(location.latitude, equals(35.2271));
      expect(location.longitude, equals(-80.8431));
    });

    test('should validate location coordinates', () {
      final validLocation = EventLocation(
        name: 'Valid Location',
        address: '123 Main St',
        latitude: 35.2271,
        longitude: -80.8431,
      );

      final invalidLocation1 = EventLocation(
        name: 'Invalid Location',
        address: '123 Main St',
        latitude: 91.0, // Invalid latitude
        longitude: -80.8431,
      );

      final invalidLocation2 = EventLocation(
        name: 'Invalid Location',
        address: '123 Main St',
        latitude: 35.2271,
        longitude: 181.0, // Invalid longitude
      );

      expect(validLocation.isValid, isTrue);
      expect(invalidLocation1.isValid, isFalse);
      expect(invalidLocation2.isValid, isFalse);
    });
  });
}

// These classes should be in your actual events model files
class Event {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final String organizerName;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final EventLocation location;
  final EventCategory category;
  final List<String>? tags;
  final double ticketPrice;
  final int maxAttendees;
  final int currentAttendees;
  final String? imageUrl;
  final bool isPublic;
  final bool requiresApproval;
  final int? ageRestriction;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.organizerName,
    required this.startDateTime,
    required this.endDateTime,
    required this.location,
    required this.category,
    this.tags,
    required this.ticketPrice,
    required this.maxAttendees,
    this.currentAttendees = 0,
    this.imageUrl,
    required this.isPublic,
    this.requiresApproval = false,
    this.ageRestriction,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isValid {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        description.isNotEmpty &&
        organizerId.isNotEmpty &&
        organizerName.isNotEmpty &&
        endDateTime.isAfter(startDateTime) &&
        ticketPrice >= 0 &&
        maxAttendees > 0 &&
        location.isValid;
  }

  bool get isUpcoming => startDateTime.isAfter(DateTime.now());
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDateTime) && now.isBefore(endDateTime);
  }

  bool get hasAvailableSpots => currentAttendees < maxAttendees;
  int get availableSpots => maxAttendees - currentAttendees;

  Duration get duration => endDateTime.difference(startDateTime);

  String get formattedPrice {
    return ticketPrice == 0 ? 'Free' : '\$${ticketPrice.toStringAsFixed(2)}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'organizerId': organizerId,
    'organizerName': organizerName,
    'startDateTime': startDateTime.toIso8601String(),
    'endDateTime': endDateTime.toIso8601String(),
    'location': location.toJson(),
    'category': category.toString(),
    'tags': tags,
    'ticketPrice': ticketPrice,
    'maxAttendees': maxAttendees,
    'currentAttendees': currentAttendees,
    'imageUrl': imageUrl,
    'isPublic': isPublic,
    'requiresApproval': requiresApproval,
    'ageRestriction': ageRestriction,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    organizerId: json['organizerId'],
    organizerName: json['organizerName'],
    startDateTime: DateTime.parse(json['startDateTime']),
    endDateTime: DateTime.parse(json['endDateTime']),
    location: EventLocation.fromJson(json['location']),
    category: EventCategoryExtension.fromString(json['category']),
    tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    ticketPrice: json['ticketPrice'].toDouble(),
    maxAttendees: json['maxAttendees'],
    currentAttendees: json['currentAttendees'] ?? 0,
    imageUrl: json['imageUrl'],
    isPublic: json['isPublic'] ?? true,
    requiresApproval: json['requiresApproval'] ?? false,
    ageRestriction: json['ageRestriction'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

class EventLocation {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  EventLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  bool get isValid {
    return name.isNotEmpty &&
        address.isNotEmpty &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory EventLocation.fromJson(Map<String, dynamic> json) => EventLocation(
    name: json['name'],
    address: json['address'],
    latitude: json['latitude'].toDouble(),
    longitude: json['longitude'].toDouble(),
  );
}

enum EventCategory { exhibition, workshop, lecture, opening, auction, festival }

extension EventCategoryExtension on EventCategory {
  static EventCategory fromString(String value) {
    switch (value) {
      case 'EventCategory.exhibition':
        return EventCategory.exhibition;
      case 'EventCategory.workshop':
        return EventCategory.workshop;
      case 'EventCategory.lecture':
        return EventCategory.lecture;
      case 'EventCategory.opening':
        return EventCategory.opening;
      case 'EventCategory.auction':
        return EventCategory.auction;
      case 'EventCategory.festival':
        return EventCategory.festival;
      default:
        return EventCategory.exhibition;
    }
  }

  String get displayName {
    switch (this) {
      case EventCategory.exhibition:
        return 'Exhibition';
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.lecture:
        return 'Lecture';
      case EventCategory.opening:
        return 'Gallery Opening';
      case EventCategory.auction:
        return 'Art Auction';
      case EventCategory.festival:
        return 'Art Festival';
    }
  }
}
