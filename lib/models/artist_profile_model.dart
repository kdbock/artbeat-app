import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat/models/subscription_model.dart';

/// Model representing an artist profile
class ArtistProfileModel {
  final String id;
  final String userId;
  final String displayName;
  final String bio;
  final List<String> mediums; // e.g., "Oil Paint", "Watercolor", "Digital"
  final List<String> styles; // e.g., "Abstract", "Realism", "Pop Art"
  final String? location;
  final String? websiteUrl;
  final String? etsy;
  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? profileImageUrl;
  final String? coverImageUrl;
  final bool isFeatured;
  final UserType userType;
  final SubscriptionTier subscriptionTier;
  final Map<String, dynamic>? additionalInfo;
  final List<String>? galleryArtists; // Only for gallery profiles
  final bool isVerified;

  ArtistProfileModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.bio,
    required this.mediums,
    required this.styles,
    this.location,
    this.websiteUrl,
    this.etsy,
    this.instagram,
    this.facebook,
    this.twitter,
    this.profileImageUrl,
    this.coverImageUrl,
    this.isFeatured = false,
    required this.userType,
    required this.subscriptionTier,
    this.additionalInfo,
    this.galleryArtists,
    this.isVerified = false,
  });

  /// Convert Firestore document to ArtistProfileModel
  factory ArtistProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtistProfileModel(
      id: doc.id,
      userId: data['userId'] as String,
      displayName: data['displayName'] as String,
      bio: data['bio'] as String,
      mediums: List<String>.from(data['mediums'] ?? []),
      styles: List<String>.from(data['styles'] ?? []),
      location: data['location'] as String?,
      websiteUrl: data['websiteUrl'] as String?,
      etsy: data['etsy'] as String?,
      instagram: data['instagram'] as String?,
      facebook: data['facebook'] as String?,
      twitter: data['twitter'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      isFeatured: data['isFeatured'] as bool? ?? false,
      userType: _userTypeFromString(data['userType'] as String),
      subscriptionTier: _tierFromString(data['subscriptionTier'] as String),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
      galleryArtists: data['userType'] == 'gallery'
          ? List<String>.from(data['galleryArtists'] ?? [])
          : null,
      isVerified: data['isVerified'] as bool? ?? false,
    );
  }

  /// Convert ArtistProfileModel to Firestore data
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'mediums': mediums,
      'styles': styles,
      'location': location,
      'websiteUrl': websiteUrl,
      'etsy': etsy,
      'instagram': instagram,
      'facebook': facebook,
      'twitter': twitter,
      'profileImageUrl': profileImageUrl,
      'coverImageUrl': coverImageUrl,
      'isFeatured': isFeatured,
      'userType': _userTypeToString(userType),
      'subscriptionTier': _tierToString(subscriptionTier),
      'isVerified': isVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (additionalInfo != null) {
      data['additionalInfo'] = additionalInfo;
    }

    // Only include gallery artists for gallery type profiles
    if (userType == UserType.gallery && galleryArtists != null) {
      data['galleryArtists'] = galleryArtists;
    }

    return data;
  }

  /// Helper to convert string tier to enum
  static SubscriptionTier _tierFromString(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return SubscriptionTier.free;
      case 'standard':
        return SubscriptionTier.standard;
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }

  /// Helper to convert enum tier to string
  static String _tierToString(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.standard:
        return 'standard';
      case SubscriptionTier.premium:
        return 'premium';
    }
  }

  /// Helper to convert string userType to enum
  static UserType _userTypeFromString(String userType) {
    switch (userType.toLowerCase()) {
      case 'regular':
        return UserType.regular;
      case 'artist':
        return UserType.artist;
      case 'gallery':
        return UserType.gallery;
      default:
        return UserType.regular;
    }
  }

  /// Helper to convert enum userType to string
  static String _userTypeToString(UserType userType) {
    switch (userType) {
      case UserType.regular:
        return 'regular';
      case UserType.artist:
        return 'artist';
      case UserType.gallery:
        return 'gallery';
    }
  }

  /// Create a copy of the artist profile model with updated fields
  ArtistProfileModel copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? bio,
    List<String>? mediums,
    List<String>? styles,
    String? location,
    String? websiteUrl,
    String? etsy,
    String? instagram,
    String? facebook,
    String? twitter,
    String? profileImageUrl,
    String? coverImageUrl,
    bool? isFeatured,
    UserType? userType,
    SubscriptionTier? subscriptionTier,
    Map<String, dynamic>? additionalInfo,
    List<String>? galleryArtists,
    bool? isVerified,
  }) {
    return ArtistProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      mediums: mediums ?? this.mediums,
      styles: styles ?? this.styles,
      location: location ?? this.location,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      etsy: etsy ?? this.etsy,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      userType: userType ?? this.userType,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      galleryArtists: galleryArtists ?? this.galleryArtists,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
