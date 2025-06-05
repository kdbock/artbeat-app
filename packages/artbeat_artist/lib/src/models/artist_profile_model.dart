// filepath: /Users/kristybock/artbeat/packages/artbeat_artist/lib/src/models/artist_profile_model.dart
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of user accounts
enum UserType {
  /// Regular artist account
  artist,

  /// Gallery business account
  gallery,
}

/// Model for artist profile data
class ArtistProfileModel {
  final String id;
  final String userId;
  final String displayName;
  final String bio;
  final UserType userType;
  final String? location;
  final List<String> mediums;
  final List<String> styles;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final Map<String, String> socialLinks;
  final bool isVerified;
  final bool isFeatured;
  final SubscriptionTier subscriptionTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  ArtistProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.userType,
    this.location,
    required this.mediums,
    required this.styles,
    this.profileImageUrl,
    this.coverImageUrl,
    Map<String, String>? socialLinks,
    this.isVerified = false,
    this.isFeatured = false,
    required this.subscriptionTier,
    required this.createdAt,
    required this.updatedAt,
  }) : socialLinks = socialLinks ?? {};

  factory ArtistProfileModel.fromMap(Map<String, dynamic> map) {
    return ArtistProfileModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'] ?? '',
      userType: _userTypeFromString(map['userType'] ?? 'artist'),
      location: map['location'],
      mediums: List<String>.from(map['mediums'] ?? []),
      styles: List<String>.from(map['styles'] ?? []),
      profileImageUrl: map['profileImageUrl'],
      coverImageUrl: map['coverImageUrl'],
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
      isVerified: map['isVerified'] ?? false,
      isFeatured: map['isFeatured'] ?? false,
      subscriptionTier:
          _tierFromString(map['subscriptionTier'] ?? 'artistBasic'),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'userType': _userTypeToString(userType),
      'location': location,
      'mediums': mediums,
      'styles': styles,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'socialLinks': socialLinks,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'subscriptionTier': _tierToString(subscriptionTier),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static String _userTypeToString(UserType type) {
    switch (type) {
      case UserType.artist:
        return 'artist';
      case UserType.gallery:
        return 'gallery';
    }
  }

  static UserType _userTypeFromString(String typeString) {
    switch (typeString) {
      case 'gallery':
        return UserType.gallery;
      case 'artist':
      default:
        return UserType.artist;
    }
  }

  static String _tierToString(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.basic:
        return 'artistBasic';
      case SubscriptionTier.standard:
        return 'artistPro';
      case SubscriptionTier.premium:
        return 'gallery';
      case SubscriptionTier.none:
      default:
        return 'none';
    }
  }

  static SubscriptionTier _tierFromString(String tierString) {
    switch (tierString) {
      case 'artistPro':
        return SubscriptionTier.standard;
      case 'gallery':
        return SubscriptionTier.premium;
      case 'artistBasic':
      default:
        return SubscriptionTier.basic;
    }
  }
}
