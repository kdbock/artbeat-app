import 'package:artbeat_core/artbeat_core.dart'
    show ArtistProfileModel, SubscriptionTier, UserType;
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtistProfileService {
  static final ArtistProfileService _instance =
      ArtistProfileService._internal();
  factory ArtistProfileService() => _instance;
  ArtistProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _artistProfilesCollection =>
      _firestore.collection('artistProfiles');

  /// Create a new artist profile
  Future<ArtistProfileModel> createArtistProfile({
    required String userId,
    required String displayName,
    required String bio,
    String? website,
    List<String>? mediums,
    List<String>? styles,
    String? location,
    required UserType userType,
    required SubscriptionTier subscriptionTier,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'userId': userId,
        'displayName': displayName,
        'bio': bio,
        'website': website,
        'mediums': mediums ?? [],
        'styles': styles ?? [],
        'location': location,
        'userType': userType.name,
        'subscriptionTier': subscriptionTier.name,
        'isVerified': false,
        'isFeatured': false,
        'socialLinks': <String, String>{},
        'createdAt': now,
        'updatedAt': now,
      };

      final docRef = await _artistProfilesCollection.add(data);
      data['id'] = docRef.id;

      return ArtistProfileModel(
        id: docRef.id,
        userId: userId,
        displayName: displayName,
        bio: bio,
        userType: userType,
        location: location,
        mediums: mediums ?? [],
        styles: styles ?? [],
        profileImageUrl: null,
        coverImageUrl: null,
        socialLinks: const {},
        isVerified: false,
        isFeatured: false,
        subscriptionTier: subscriptionTier,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('Error creating artist profile: $e');
    }
  }

  /// Get artist profile by user ID
  Future<ArtistProfileModel?> getArtistProfileByUserId(String userId) async {
    try {
      final querySnapshot = await _artistProfilesCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      return ArtistProfileModel(
        id: doc.id,
        userId: data['userId'],
        displayName: data['displayName'],
        bio: data['bio'],
        userType: UserType.fromString(data['userType'] ?? UserType.artist.name),
        location: data['location'],
        mediums: List<String>.from(data['mediums'] ?? []),
        styles: List<String>.from(data['styles'] ?? []),
        profileImageUrl: data['profileImageUrl'],
        coverImageUrl: data['coverImageUrl'],
        socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
        isVerified: data['isVerified'] ?? false,
        isFeatured: data['isFeatured'] ?? false,
        subscriptionTier: SubscriptionTier.values.firstWhere(
          (tier) => tier.name == data['subscriptionTier'],
          orElse: () => SubscriptionTier.artistBasic,
        ),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      throw Exception('Error getting artist profile: $e');
    }
  }

  /// Get artist profile by ID
  Future<ArtistProfileModel?> getArtistProfileById(String profileId) async {
    try {
      final doc = await _artistProfilesCollection.doc(profileId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      return ArtistProfileModel(
        id: doc.id,
        userId: data['userId'],
        displayName: data['displayName'],
        bio: data['bio'] ?? '',
        userType: UserType.fromString(data['userType'] ?? UserType.artist.name),
        location: data['location'],
        mediums: List<String>.from(data['mediums'] ?? []),
        styles: List<String>.from(data['styles'] ?? []),
        profileImageUrl: data['profileImageUrl'],
        coverImageUrl: data['coverImageUrl'],
        socialLinks: Map<String, String>.from(data['socialLinks'] ?? {}),
        isVerified: data['isVerified'] ?? false,
        isFeatured: data['isFeatured'] ?? false,
        subscriptionTier: SubscriptionTier.values.firstWhere(
          (tier) => tier.apiName == data['subscriptionTier'],
          orElse: () => SubscriptionTier.artistBasic,
        ),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      );
    } catch (e) {
      throw Exception('Error getting artist profile by ID: $e');
    }
  }

  /// Update artist profile
  Future<void> updateArtistProfile(
    String profileId, {
    String? displayName,
    String? bio,
    String? website,
    List<String>? mediums,
    List<String>? styles,
    String? location,
    String? profileImageUrl,
    String? coverImageUrl,
    Map<String, String>? socialLinks,
    bool? isVerified,
    bool? isFeatured,
    SubscriptionTier? subscriptionTier,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (website != null) updates['website'] = website;
      if (mediums != null) updates['mediums'] = mediums;
      if (styles != null) updates['styles'] = styles;
      if (location != null) updates['location'] = location;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      if (coverImageUrl != null) updates['coverImageUrl'] = coverImageUrl;
      if (socialLinks != null) updates['socialLinks'] = socialLinks;
      if (isVerified != null) updates['isVerified'] = isVerified;
      if (isFeatured != null) updates['isFeatured'] = isFeatured;
      if (subscriptionTier != null) {
        updates['subscriptionTier'] = subscriptionTier.name;
      }

      await _artistProfilesCollection.doc(profileId).update(updates);
    } catch (e) {
      throw Exception('Error updating artist profile: $e');
    }
  }
}
