import 'package:cloud_firestore/cloud_firestore.dart';
import 'subscription_tier.dart';

import 'user_type.dart';

/// Model for artist profiles
class ArtistProfileModel {
  final String id;
  final String userId;
  final String displayName;
  final String? bio;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final String? website;
  final String? location;
  final UserType userType;
  final SubscriptionTier subscriptionTier;
  final bool isVerified;
  final bool isFeatured;
  final List<String> mediums;
  final List<String> styles;
  final Map<String, String> socialLinks;
  final DateTime createdAt;
  final DateTime updatedAt;

  ArtistProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    this.bio,
    this.profileImageUrl,
    this.coverImageUrl,
    this.website,
    this.location,
    required this.userType,
    this.subscriptionTier = SubscriptionTier.artistBasic,
    this.isVerified = false,
    this.isFeatured = false,
    this.mediums = const [],
    this.styles = const [],
    this.socialLinks = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory ArtistProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ArtistProfileModel(
      id: doc.id,
      userId: data['userId'] as String,
      displayName: data['displayName'] as String,
      bio: data['bio'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      website: data['website'] as String?,
      location: data['location'] as String?,
      userType: _parseUserType(data['userType']),
      subscriptionTier: _parseSubscriptionTier(data['subscriptionTier']),
      isVerified: data['isVerified'] as bool? ?? false,
      isFeatured: data['isFeatured'] as bool? ?? false,
      mediums: _parseStringList(data['mediums']),
      styles: _parseStringList(data['styles']),
      socialLinks: _parseStringMap(data['socialLinks']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'website': website,
      'location': location,
      'userType': userType.name,
      'subscriptionTier': subscriptionTier.name,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'mediums': mediums,
      'styles': styles,
      'socialLinks': socialLinks,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Parse user type from string or int
  static UserType _parseUserType(dynamic value) {
    if (value is String) {
      return UserType.fromString(value);
    } else if (value is int && value >= 0 && value < UserType.values.length) {
      return UserType.values[value];
    }
    return UserType.regular;
  }

  /// Parse subscription tier from string or int
  static SubscriptionTier _parseSubscriptionTier(dynamic value) {
    if (value is String) {
      return SubscriptionTier.fromLegacyName(value);
    } else if (value is int &&
        value >= 0 &&
        value < SubscriptionTier.values.length) {
      return SubscriptionTier.values[value];
    }
    return SubscriptionTier.free;
  }

  /// Parse list of strings from dynamic value
  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  /// Parse map of strings from dynamic value
  static Map<String, String> _parseStringMap(dynamic value) {
    if (value is Map) {
      return Map<String, String>.from(value);
    }
    return {};
  }

  /// Check if artist has a free subscription
  bool get isBasicSubscription =>
      subscriptionTier == SubscriptionTier.free ||
      subscriptionTier == SubscriptionTier.artistBasic;

  /// Check if artist has a pro subscription
  bool get isProSubscription => subscriptionTier == SubscriptionTier.artistPro;

  /// Check if artist has a gallery subscription
  bool get isGallerySubscription =>
      subscriptionTier == SubscriptionTier.gallery;

  /// Get maximum number of artworks allowed for this subscription
  int get maxArtworkCount {
    switch (subscriptionTier) {
      case SubscriptionTier.free:
      case SubscriptionTier.artistBasic:
        return 5;
      case SubscriptionTier.artistPro:
        return 100;
      case SubscriptionTier.gallery:
        return 1000;
    }
  }

  /// Check if artist can upload more artwork
  Future<bool> canUploadMoreArtwork() async {
    final artworkRef = FirebaseFirestore.instance.collection('artwork');
    final count = await artworkRef
        .where('userId', isEqualTo: userId)
        .count()
        .get();

    return (count.count ?? 0) < maxArtworkCount;
  }
}
