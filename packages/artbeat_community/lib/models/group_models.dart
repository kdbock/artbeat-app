import 'package:cloud_firestore/cloud_firestore.dart';

/// Base class for all group posts
abstract class BaseGroupPost {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final String location;
  final DateTime createdAt;
  final int applauseCount; // Like/Follow count
  final int commentCount;
  final int shareCount;
  final bool isPublic;
  final bool isUserVerified;

  BaseGroupPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.content,
    required this.imageUrls,
    required this.tags,
    required this.location,
    required this.createdAt,
    this.applauseCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isPublic = true,
    this.isUserVerified = false,
  });
}

/// Artist Group Post Model
class ArtistGroupPost extends BaseGroupPost {
  final String artistId;
  final String artworkTitle;
  final String artworkDescription;
  final String medium;
  final String style;
  final double? price;
  final bool isForSale;
  final List<String> techniques;

  ArtistGroupPost({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userPhotoUrl,
    required super.content,
    required super.imageUrls,
    required super.tags,
    required super.location,
    required super.createdAt,
    super.applauseCount,
    super.commentCount,
    super.shareCount,
    super.isPublic,
    super.isUserVerified,
    required this.artistId,
    required this.artworkTitle,
    required this.artworkDescription,
    required this.medium,
    required this.style,
    this.price,
    this.isForSale = false,
    this.techniques = const [],
  });

  factory ArtistGroupPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtistGroupPost(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      userPhotoUrl: (data['userPhotoUrl'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as Iterable? ?? []),
      tags: List<String>.from(data['tags'] as Iterable? ?? []),
      location: (data['location'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applauseCount: (data['applauseCount'] as int?) ?? 0,
      commentCount: (data['commentCount'] as int?) ?? 0,
      shareCount: (data['shareCount'] as int?) ?? 0,
      isPublic: (data['isPublic'] as bool?) ?? true,
      isUserVerified: (data['isUserVerified'] as bool?) ?? false,
      artistId: (data['artistId'] as String?) ?? '',
      artworkTitle: (data['artworkTitle'] as String?) ?? '',
      artworkDescription: (data['artworkDescription'] as String?) ?? '',
      medium: (data['medium'] as String?) ?? '',
      style: (data['style'] as String?) ?? '',
      price: (data['price'] as num?)?.toDouble(),
      isForSale: (data['isForSale'] as bool?) ?? false,
      techniques: List<String>.from(data['techniques'] as Iterable? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'applauseCount': applauseCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isPublic': isPublic,
      'isUserVerified': isUserVerified,
      'artistId': artistId,
      'artworkTitle': artworkTitle,
      'artworkDescription': artworkDescription,
      'medium': medium,
      'style': style,
      'price': price,
      'isForSale': isForSale,
      'techniques': techniques,
      'groupType': 'artist',
    };
  }
}

/// Event Group Post Model
class EventGroupPost extends BaseGroupPost {
  final String eventId;
  final String eventTitle;
  final String eventDescription;
  final DateTime eventDate;
  final String eventLocation;
  final String eventType; // hosting, attending
  final double? ticketPrice;
  final int maxAttendees;
  final List<String> attendeeIds;
  final bool requiresTicket;

  EventGroupPost({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userPhotoUrl,
    required super.content,
    required super.imageUrls,
    required super.tags,
    required super.location,
    required super.createdAt,
    super.applauseCount,
    super.commentCount,
    super.shareCount,
    super.isPublic,
    super.isUserVerified,
    required this.eventId,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventDate,
    required this.eventLocation,
    required this.eventType,
    this.ticketPrice,
    this.maxAttendees = 0,
    this.attendeeIds = const [],
    this.requiresTicket = false,
  });

  factory EventGroupPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return EventGroupPost(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      userPhotoUrl: (data['userPhotoUrl'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as Iterable? ?? []),
      tags: List<String>.from(data['tags'] as Iterable? ?? []),
      location: (data['location'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applauseCount: (data['applauseCount'] as int?) ?? 0,
      commentCount: (data['commentCount'] as int?) ?? 0,
      shareCount: (data['shareCount'] as int?) ?? 0,
      isPublic: (data['isPublic'] as bool?) ?? true,
      isUserVerified: (data['isUserVerified'] as bool?) ?? false,
      eventId: (data['eventId'] as String?) ?? '',
      eventTitle: (data['eventTitle'] as String?) ?? '',
      eventDescription: (data['eventDescription'] as String?) ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventLocation: (data['eventLocation'] as String?) ?? '',
      eventType: (data['eventType'] as String?) ?? '',
      ticketPrice: (data['ticketPrice'] as num?)?.toDouble(),
      maxAttendees: (data['maxAttendees'] as int?) ?? 0,
      attendeeIds: List<String>.from(data['attendeeIds'] as Iterable? ?? []),
      requiresTicket: (data['requiresTicket'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'applauseCount': applauseCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isPublic': isPublic,
      'isUserVerified': isUserVerified,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventLocation': eventLocation,
      'eventType': eventType,
      'ticketPrice': ticketPrice,
      'maxAttendees': maxAttendees,
      'attendeeIds': attendeeIds,
      'requiresTicket': requiresTicket,
      'groupType': 'event',
    };
  }
}

/// Art Walk Adventure Group Post Model
class ArtWalkAdventurePost extends BaseGroupPost {
  final String routeId;
  final String routeName;
  final List<String> artworkPhotos; // Max 5 photos
  final List<Map<String, dynamic>> artworkLocations;
  final double walkDistance;
  final int estimatedDuration; // in minutes
  final String difficulty; // easy, moderate, hard
  final List<String> landmarks;

  ArtWalkAdventurePost({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userPhotoUrl,
    required super.content,
    required super.imageUrls,
    required super.tags,
    required super.location,
    required super.createdAt,
    super.applauseCount,
    super.commentCount,
    super.shareCount,
    super.isPublic,
    super.isUserVerified,
    required this.routeId,
    required this.routeName,
    required this.artworkPhotos,
    required this.artworkLocations,
    this.walkDistance = 0.0,
    this.estimatedDuration = 0,
    this.difficulty = 'easy',
    this.landmarks = const [],
  });

  factory ArtWalkAdventurePost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtWalkAdventurePost(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      userPhotoUrl: (data['userPhotoUrl'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as Iterable? ?? []),
      tags: List<String>.from(data['tags'] as Iterable? ?? []),
      location: (data['location'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applauseCount: (data['applauseCount'] as int?) ?? 0,
      commentCount: (data['commentCount'] as int?) ?? 0,
      shareCount: (data['shareCount'] as int?) ?? 0,
      isPublic: (data['isPublic'] as bool?) ?? true,
      isUserVerified: (data['isUserVerified'] as bool?) ?? false,
      routeId: (data['routeId'] as String?) ?? '',
      routeName: (data['routeName'] as String?) ?? '',
      artworkPhotos: List<String>.from(
        data['artworkPhotos'] as Iterable? ?? [],
      ),
      artworkLocations: List<Map<String, dynamic>>.from(
        data['artworkLocations'] as Iterable? ?? [],
      ),
      walkDistance: (data['walkDistance'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: (data['estimatedDuration'] as int?) ?? 0,
      difficulty: (data['difficulty'] as String?) ?? 'easy',
      landmarks: List<String>.from(data['landmarks'] as Iterable? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'applauseCount': applauseCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isPublic': isPublic,
      'isUserVerified': isUserVerified,
      'routeId': routeId,
      'routeName': routeName,
      'artworkPhotos': artworkPhotos,
      'artworkLocations': artworkLocations,
      'walkDistance': walkDistance,
      'estimatedDuration': estimatedDuration,
      'difficulty': difficulty,
      'landmarks': landmarks,
      'groupType': 'artwalk',
    };
  }
}

/// Artist Wanted Group Post Model
class ArtistWantedPost extends BaseGroupPost {
  final String projectId;
  final String projectTitle;
  final String projectDescription;
  final double budget;
  final String budgetType; // fixed, hourly, negotiable
  final DateTime deadline;
  final List<String> requiredSkills;
  final String experienceLevel; // beginner, intermediate, expert
  final List<String> applicantIds;
  final bool isUrgent;
  final String contactMethod; // message, email, phone

  ArtistWantedPost({
    required super.id,
    required super.userId,
    required super.userName,
    required super.userPhotoUrl,
    required super.content,
    required super.imageUrls,
    required super.tags,
    required super.location,
    required super.createdAt,
    super.applauseCount,
    super.commentCount,
    super.shareCount,
    super.isPublic,
    super.isUserVerified,
    required this.projectId,
    required this.projectTitle,
    required this.projectDescription,
    required this.budget,
    required this.budgetType,
    required this.deadline,
    required this.requiredSkills,
    required this.experienceLevel,
    this.applicantIds = const [],
    this.isUrgent = false,
    this.contactMethod = 'message',
  });

  factory ArtistWantedPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtistWantedPost(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      userPhotoUrl: (data['userPhotoUrl'] as String?) ?? '',
      content: (data['content'] as String?) ?? '',
      imageUrls: List<String>.from(data['imageUrls'] as Iterable? ?? []),
      tags: List<String>.from(data['tags'] as Iterable? ?? []),
      location: (data['location'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      applauseCount: (data['applauseCount'] as int?) ?? 0,
      commentCount: (data['commentCount'] as int?) ?? 0,
      shareCount: (data['shareCount'] as int?) ?? 0,
      isPublic: (data['isPublic'] as bool?) ?? true,
      isUserVerified: (data['isUserVerified'] as bool?) ?? false,
      projectId: (data['projectId'] as String?) ?? '',
      projectTitle: (data['projectTitle'] as String?) ?? '',
      projectDescription: (data['projectDescription'] as String?) ?? '',
      budget: (data['budget'] as num?)?.toDouble() ?? 0.0,
      budgetType: (data['budgetType'] as String?) ?? 'negotiable',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requiredSkills: List<String>.from(
        data['requiredSkills'] as Iterable? ?? [],
      ),
      experienceLevel: (data['experienceLevel'] as String?) ?? 'intermediate',
      applicantIds: List<String>.from(data['applicantIds'] as Iterable? ?? []),
      isUrgent: (data['isUrgent'] as bool?) ?? false,
      contactMethod: (data['contactMethod'] as String?) ?? 'message',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrls': imageUrls,
      'tags': tags,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'applauseCount': applauseCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'isPublic': isPublic,
      'isUserVerified': isUserVerified,
      'projectId': projectId,
      'projectTitle': projectTitle,
      'projectDescription': projectDescription,
      'budget': budget,
      'budgetType': budgetType,
      'deadline': Timestamp.fromDate(deadline),
      'requiredSkills': requiredSkills,
      'experienceLevel': experienceLevel,
      'applicantIds': applicantIds,
      'isUrgent': isUrgent,
      'contactMethod': contactMethod,
      'groupType': 'artistwanted',
    };
  }
}

/// Group types enum
enum GroupType {
  artist(
    'artist',
    'Artist Groups',
    'Share your artwork and connect with fellow artists',
  ),
  event(
    'event',
    'Event Groups',
    'Discover and share art events and exhibitions',
  ),
  artWalk(
    'artwalk',
    'Art Walk Adventure',
    'Share your public art discoveries and routes',
  ),
  artistWanted(
    'artistwanted',
    'Artist Wanted',
    'Find artists for your projects or offer your services',
  );

  const GroupType(this.value, this.title, this.description);

  final String value;
  final String title;
  final String description;
}
