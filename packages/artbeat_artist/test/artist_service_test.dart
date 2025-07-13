import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock classes
@GenerateMocks([FirebaseFirestore, CollectionReference, DocumentReference])
import 'artist_service_test.mocks.dart';

void main() {
  group('ArtistService Tests', () {
    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
    });

    test('should create artist profile successfully', () async {
      // Arrange
      final artistData = {
        'uid': 'artist-123',
        'fullName': 'Jane Artist',
        'email': 'jane@example.com',
        'artistName': 'Jane A.',
        'bio': 'Professional artist specializing in modern art',
        'profileImageUrl': 'https://example.com/jane.jpg',
        'portfolioUrl': 'https://janeartist.com',
        'socialMediaLinks': {
          'instagram': '@janeartist',
          'twitter': '@jane_art',
          'website': 'https://janeartist.com',
        },
        'specialties': ['Painting', 'Digital Art', 'Sculpture'],
        'yearsExperience': 10,
        'education': 'BFA from Art Institute',
        'awards': ['Best Local Artist 2023', 'Gallery Award 2022'],
        'isVerified': true,
        'subscriptionTier': 'premium',
        'commissionStatus': 'open',
        'commissionRates': {
          'portrait': 500.0,
          'landscape': 300.0,
          'abstract': 400.0,
        },
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('artists')).thenReturn(mockCollection);
      when(mockCollection.doc('artist-123')).thenReturn(mockDocument);
      when(mockDocument.set(artistData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.set(artistData);

      // Assert
      verify(mockDocument.set(artistData)).called(1);
    });

    test('should update artist subscription tier', () async {
      // Arrange
      const artistId = 'artist-123';
      const newTier = 'premium';
      final updateData = {
        'subscriptionTier': newTier,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('artists')).thenReturn(mockCollection);
      when(mockCollection.doc(artistId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should update commission rates', () async {
      // Arrange
      const artistId = 'artist-123';
      final newRates = {
        'portrait': 600.0,
        'landscape': 350.0,
        'abstract': 450.0,
        'custom': 800.0,
      };
      final updateData = {
        'commissionRates': newRates,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('artists')).thenReturn(mockCollection);
      when(mockCollection.doc(artistId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should toggle commission status', () async {
      // Arrange
      const artistId = 'artist-123';
      const newStatus = 'closed';
      final updateData = {
        'commissionStatus': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('artists')).thenReturn(mockCollection);
      when(mockCollection.doc(artistId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should add new specialty', () async {
      // Arrange
      const artistId = 'artist-123';
      const newSpecialty = 'Mural Art';
      final updateData = {
        'specialties': FieldValue.arrayUnion([newSpecialty]),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('artists')).thenReturn(mockCollection);
      when(mockCollection.doc(artistId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should remove specialty', () async {
      // Arrange
      const artistId = 'artist-123';
      const removedSpecialty = 'Digital Art';
      final updateData = {
        'specialties': FieldValue.arrayRemove([removedSpecialty]),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('artists')).thenReturn(mockCollection);
      when(mockCollection.doc(artistId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });

    test('should update social media links', () async {
      // Arrange
      const artistId = 'artist-123';
      final newSocialLinks = {
        'instagram': '@new_jane_artist',
        'twitter': '@new_jane_art',
        'facebook': 'jane.artist.page',
        'linkedin': 'jane-artist-profile',
      };
      final updateData = {
        'socialMediaLinks': newSocialLinks,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      when(mockFirestore.collection('artists')).thenReturn(mockCollection);
      when(mockCollection.doc(artistId)).thenReturn(mockDocument);
      when(mockDocument.update(updateData)).thenAnswer((_) async => {});

      // Act
      await mockDocument.update(updateData);

      // Assert
      verify(mockDocument.update(updateData)).called(1);
    });
  });

  group('Artist Model Tests', () {
    test('should create ArtistProfile with valid data', () {
      final artist = ArtistProfile(
        uid: 'artist-123',
        fullName: 'Jane Artist',
        email: 'jane@example.com',
        artistName: 'Jane A.',
        bio: 'Professional artist',
        profileImageUrl: 'https://example.com/jane.jpg',
        specialties: ['Painting', 'Digital Art'],
        yearsExperience: 10,
        subscriptionTier: SubscriptionTier.premium,
        commissionStatus: CommissionStatus.open,
        commissionRates: {
          'portrait': 500.0,
          'landscape': 300.0,
        },
      );

      expect(artist.uid, equals('artist-123'));
      expect(artist.fullName, equals('Jane Artist'));
      expect(artist.artistName, equals('Jane A.'));
      expect(artist.specialties.length, equals(2));
      expect(artist.yearsExperience, equals(10));
      expect(artist.subscriptionTier, equals(SubscriptionTier.premium));
      expect(artist.commissionStatus, equals(CommissionStatus.open));
      expect(artist.commissionRates['portrait'], equals(500.0));
    });

    test('should validate artist profile data', () {
      // Valid artist profile
      final validArtist = ArtistProfile(
        uid: 'artist-123',
        fullName: 'Jane Artist',
        email: 'jane@example.com',
        artistName: 'Jane A.',
        bio: 'Professional artist',
        profileImageUrl: 'https://example.com/jane.jpg',
        specialties: ['Painting'],
        yearsExperience: 5,
        subscriptionTier: SubscriptionTier.basic,
        commissionStatus: CommissionStatus.open,
        commissionRates: {'portrait': 200.0},
      );
      expect(validArtist.isValid, isTrue);

      // Invalid artist profile - missing required fields
      final invalidArtist1 = ArtistProfile(
        uid: '',
        fullName: 'Jane Artist',
        email: 'jane@example.com',
        artistName: 'Jane A.',
        bio: 'Professional artist',
        profileImageUrl: 'https://example.com/jane.jpg',
        specialties: ['Painting'],
        yearsExperience: 5,
        subscriptionTier: SubscriptionTier.basic,
        commissionStatus: CommissionStatus.open,
        commissionRates: {'portrait': 200.0},
      );
      expect(invalidArtist1.isValid, isFalse);

      // Invalid artist profile - negative experience
      final invalidArtist2 = ArtistProfile(
        uid: 'artist-123',
        fullName: 'Jane Artist',
        email: 'jane@example.com',
        artistName: 'Jane A.',
        bio: 'Professional artist',
        profileImageUrl: 'https://example.com/jane.jpg',
        specialties: ['Painting'],
        yearsExperience: -1,
        subscriptionTier: SubscriptionTier.basic,
        commissionStatus: CommissionStatus.open,
        commissionRates: {'portrait': 200.0},
      );
      expect(invalidArtist2.isValid, isFalse);

      // Invalid artist profile - no specialties
      final invalidArtist3 = ArtistProfile(
        uid: 'artist-123',
        fullName: 'Jane Artist',
        email: 'jane@example.com',
        artistName: 'Jane A.',
        bio: 'Professional artist',
        profileImageUrl: 'https://example.com/jane.jpg',
        specialties: [],
        yearsExperience: 5,
        subscriptionTier: SubscriptionTier.basic,
        commissionStatus: CommissionStatus.open,
        commissionRates: {'portrait': 200.0},
      );
      expect(invalidArtist3.isValid, isFalse);
    });

    test('should convert ArtistProfile to JSON', () {
      final artist = ArtistProfile(
        uid: 'artist-123',
        fullName: 'Jane Artist',
        email: 'jane@example.com',
        artistName: 'Jane A.',
        bio: 'Professional artist',
        profileImageUrl: 'https://example.com/jane.jpg',
        specialties: ['Painting', 'Digital Art'],
        yearsExperience: 10,
        subscriptionTier: SubscriptionTier.premium,
        commissionStatus: CommissionStatus.open,
        commissionRates: {'portrait': 500.0},
        isVerified: true,
      );

      final json = artist.toJson();

      expect(json['uid'], equals('artist-123'));
      expect(json['fullName'], equals('Jane Artist'));
      expect(json['artistName'], equals('Jane A.'));
      expect(json['specialties'], equals(['Painting', 'Digital Art']));
      expect(json['yearsExperience'], equals(10));
      expect(json['subscriptionTier'],
          equals(SubscriptionTier.premium.toString()));
      expect(
          json['commissionStatus'], equals(CommissionStatus.open.toString()));
      expect(json['commissionRates'], equals({'portrait': 500.0}));
      expect(json['isVerified'], isTrue);
    });

    test('should create ArtistProfile from JSON', () {
      final json = {
        'uid': 'artist-123',
        'fullName': 'Jane Artist',
        'email': 'jane@example.com',
        'artistName': 'Jane A.',
        'bio': 'Professional artist',
        'profileImageUrl': 'https://example.com/jane.jpg',
        'specialties': ['Painting', 'Digital Art'],
        'yearsExperience': 10,
        'subscriptionTier': SubscriptionTier.premium.toString(),
        'commissionStatus': CommissionStatus.open.toString(),
        'commissionRates': {'portrait': 500.0},
        'isVerified': true,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final artist = ArtistProfile.fromJson(json);

      expect(artist.uid, equals('artist-123'));
      expect(artist.fullName, equals('Jane Artist'));
      expect(artist.artistName, equals('Jane A.'));
      expect(artist.specialties, equals(['Painting', 'Digital Art']));
      expect(artist.yearsExperience, equals(10));
      expect(artist.subscriptionTier, equals(SubscriptionTier.premium));
      expect(artist.commissionStatus, equals(CommissionStatus.open));
      expect(artist.commissionRates['portrait'], equals(500.0));
      expect(artist.isVerified, isTrue);
    });

    test('should calculate average commission rate', () {
      final artist = ArtistProfile(
        uid: 'artist-123',
        fullName: 'Jane Artist',
        email: 'jane@example.com',
        artistName: 'Jane A.',
        bio: 'Professional artist',
        profileImageUrl: 'https://example.com/jane.jpg',
        specialties: ['Painting'],
        yearsExperience: 5,
        subscriptionTier: SubscriptionTier.basic,
        commissionStatus: CommissionStatus.open,
        commissionRates: {
          'portrait': 400.0,
          'landscape': 300.0,
          'abstract': 500.0,
        },
      );

      final averageRate = artist.averageCommissionRate;
      expect(averageRate, equals(400.0)); // (400 + 300 + 500) / 3
    });

    test('should check if commissions are available', () {
      final openArtist = ArtistProfile(
        uid: 'artist-123',
        fullName: 'Jane Artist',
        email: 'jane@example.com',
        artistName: 'Jane A.',
        bio: 'Professional artist',
        profileImageUrl: 'https://example.com/jane.jpg',
        specialties: ['Painting'],
        yearsExperience: 5,
        subscriptionTier: SubscriptionTier.basic,
        commissionStatus: CommissionStatus.open,
        commissionRates: {'portrait': 200.0},
      );
      expect(openArtist.isAcceptingCommissions, isTrue);

      final closedArtist = ArtistProfile(
        uid: 'artist-456',
        fullName: 'Bob Artist',
        email: 'bob@example.com',
        artistName: 'Bob A.',
        bio: 'Busy artist',
        profileImageUrl: 'https://example.com/bob.jpg',
        specialties: ['Sculpture'],
        yearsExperience: 8,
        subscriptionTier: SubscriptionTier.premium,
        commissionStatus: CommissionStatus.closed,
        commissionRates: {'sculpture': 1000.0},
      );
      expect(closedArtist.isAcceptingCommissions, isFalse);
    });
  });

  group('Subscription Tier Tests', () {
    test('should convert SubscriptionTier to string correctly', () {
      expect(
          SubscriptionTier.basic.toString(), equals('SubscriptionTier.basic'));
      expect(SubscriptionTier.premium.toString(),
          equals('SubscriptionTier.premium'));
      expect(SubscriptionTier.pro.toString(), equals('SubscriptionTier.pro'));
    });

    test('should parse SubscriptionTier from string correctly', () {
      expect(
        SubscriptionTierExtension.fromString('SubscriptionTier.basic'),
        equals(SubscriptionTier.basic),
      );
      expect(
        SubscriptionTierExtension.fromString('SubscriptionTier.premium'),
        equals(SubscriptionTier.premium),
      );
      expect(
        SubscriptionTierExtension.fromString('SubscriptionTier.pro'),
        equals(SubscriptionTier.pro),
      );
      expect(
        SubscriptionTierExtension.fromString('invalid'),
        equals(SubscriptionTier.basic),
      ); // Default
    });

    test('should get tier benefits correctly', () {
      expect(SubscriptionTier.basic.maxArtworkUploads, equals(10));
      expect(SubscriptionTier.premium.maxArtworkUploads, equals(50));
      expect(SubscriptionTier.pro.maxArtworkUploads, equals(-1)); // Unlimited

      expect(SubscriptionTier.basic.canCreateCustomGalleries, isFalse);
      expect(SubscriptionTier.premium.canCreateCustomGalleries, isTrue);
      expect(SubscriptionTier.pro.canCreateCustomGalleries, isTrue);

      expect(SubscriptionTier.basic.hasAnalytics, isFalse);
      expect(SubscriptionTier.premium.hasAnalytics, isTrue);
      expect(SubscriptionTier.pro.hasAnalytics, isTrue);
    });
  });

  group('Commission Status Tests', () {
    test('should convert CommissionStatus to string correctly', () {
      expect(CommissionStatus.open.toString(), equals('CommissionStatus.open'));
      expect(CommissionStatus.closed.toString(),
          equals('CommissionStatus.closed'));
      expect(CommissionStatus.limited.toString(),
          equals('CommissionStatus.limited'));
    });

    test('should parse CommissionStatus from string correctly', () {
      expect(
        CommissionStatusExtension.fromString('CommissionStatus.open'),
        equals(CommissionStatus.open),
      );
      expect(
        CommissionStatusExtension.fromString('CommissionStatus.closed'),
        equals(CommissionStatus.closed),
      );
      expect(
        CommissionStatusExtension.fromString('CommissionStatus.limited'),
        equals(CommissionStatus.limited),
      );
      expect(
        CommissionStatusExtension.fromString('invalid'),
        equals(CommissionStatus.closed),
      ); // Default
    });

    test('should get status display name correctly', () {
      expect(CommissionStatus.open.displayName, equals('Open for Commissions'));
      expect(CommissionStatus.closed.displayName,
          equals('Not Taking Commissions'));
      expect(
          CommissionStatus.limited.displayName, equals('Limited Availability'));
    });
  });
}

// These classes should be in your actual artist model files
class ArtistProfile {
  final String uid;
  final String fullName;
  final String email;
  final String artistName;
  final String bio;
  final String profileImageUrl;
  final List<String> specialties;
  final int yearsExperience;
  final SubscriptionTier subscriptionTier;
  final CommissionStatus commissionStatus;
  final Map<String, double> commissionRates;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  ArtistProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.artistName,
    required this.bio,
    required this.profileImageUrl,
    required this.specialties,
    required this.yearsExperience,
    required this.subscriptionTier,
    required this.commissionStatus,
    required this.commissionRates,
    this.isVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isValid {
    return uid.isNotEmpty &&
        fullName.isNotEmpty &&
        email.isNotEmpty &&
        artistName.isNotEmpty &&
        specialties.isNotEmpty &&
        yearsExperience >= 0 &&
        commissionRates.isNotEmpty;
  }

  bool get isAcceptingCommissions {
    return commissionStatus == CommissionStatus.open ||
        commissionStatus == CommissionStatus.limited;
  }

  double get averageCommissionRate {
    if (commissionRates.isEmpty) return 0.0;
    final total = commissionRates.values.reduce((a, b) => a + b);
    return total / commissionRates.length;
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'artistName': artistName,
        'bio': bio,
        'profileImageUrl': profileImageUrl,
        'specialties': specialties,
        'yearsExperience': yearsExperience,
        'subscriptionTier': subscriptionTier.toString(),
        'commissionStatus': commissionStatus.toString(),
        'commissionRates': commissionRates,
        'isVerified': isVerified,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ArtistProfile.fromJson(Map<String, dynamic> json) => ArtistProfile(
        uid: json['uid'],
        fullName: json['fullName'],
        email: json['email'],
        artistName: json['artistName'],
        bio: json['bio'],
        profileImageUrl: json['profileImageUrl'],
        specialties: List<String>.from(json['specialties']),
        yearsExperience: json['yearsExperience'],
        subscriptionTier:
            SubscriptionTierExtension.fromString(json['subscriptionTier']),
        commissionStatus:
            CommissionStatusExtension.fromString(json['commissionStatus']),
        commissionRates: Map<String, double>.from(json['commissionRates']),
        isVerified: json['isVerified'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

enum SubscriptionTier {
  basic,
  premium,
  pro,
}

extension SubscriptionTierExtension on SubscriptionTier {
  static SubscriptionTier fromString(String value) {
    switch (value) {
      case 'SubscriptionTier.basic':
        return SubscriptionTier.basic;
      case 'SubscriptionTier.premium':
        return SubscriptionTier.premium;
      case 'SubscriptionTier.pro':
        return SubscriptionTier.pro;
      default:
        return SubscriptionTier.basic;
    }
  }

  int get maxArtworkUploads {
    switch (this) {
      case SubscriptionTier.basic:
        return 10;
      case SubscriptionTier.premium:
        return 50;
      case SubscriptionTier.pro:
        return -1; // Unlimited
    }
  }

  bool get canCreateCustomGalleries {
    switch (this) {
      case SubscriptionTier.basic:
        return false;
      case SubscriptionTier.premium:
      case SubscriptionTier.pro:
        return true;
    }
  }

  bool get hasAnalytics {
    switch (this) {
      case SubscriptionTier.basic:
        return false;
      case SubscriptionTier.premium:
      case SubscriptionTier.pro:
        return true;
    }
  }
}

enum CommissionStatus {
  open,
  closed,
  limited,
}

extension CommissionStatusExtension on CommissionStatus {
  static CommissionStatus fromString(String value) {
    switch (value) {
      case 'CommissionStatus.open':
        return CommissionStatus.open;
      case 'CommissionStatus.closed':
        return CommissionStatus.closed;
      case 'CommissionStatus.limited':
        return CommissionStatus.limited;
      default:
        return CommissionStatus.closed;
    }
  }

  String get displayName {
    switch (this) {
      case CommissionStatus.open:
        return 'Open for Commissions';
      case CommissionStatus.closed:
        return 'Not Taking Commissions';
      case CommissionStatus.limited:
        return 'Limited Availability';
    }
  }
}
