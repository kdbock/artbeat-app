/// Privacy settings model for user privacy controls
/// Implementation Date: September 5, 2025
class PrivacySettingsModel {
  final String userId;
  final ProfilePrivacySettings profile;
  final ContentPrivacySettings content;
  final DataPrivacySettings data;
  final LocationPrivacySettings location;
  final DateTime updatedAt;

  const PrivacySettingsModel({
    required this.userId,
    required this.profile,
    required this.content,
    required this.data,
    required this.location,
    required this.updatedAt,
  });

  factory PrivacySettingsModel.fromMap(Map<String, dynamic> map) {
    return PrivacySettingsModel(
      userId: map['userId'] as String? ?? '',
      profile: ProfilePrivacySettings.fromMap(
        map['profile'] as Map<String, dynamic>? ?? {},
      ),
      content: ContentPrivacySettings.fromMap(
        map['content'] as Map<String, dynamic>? ?? {},
      ),
      data: DataPrivacySettings.fromMap(
        map['data'] as Map<String, dynamic>? ?? {},
      ),
      location: LocationPrivacySettings.fromMap(
        map['location'] as Map<String, dynamic>? ?? {},
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'profile': profile.toMap(),
      'content': content.toMap(),
      'data': data.toMap(),
      'location': location.toMap(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PrivacySettingsModel.defaultSettings(String userId) {
    return PrivacySettingsModel(
      userId: userId,
      profile: ProfilePrivacySettings.defaultSettings(),
      content: ContentPrivacySettings.defaultSettings(),
      data: DataPrivacySettings.defaultSettings(),
      location: LocationPrivacySettings.defaultSettings(),
      updatedAt: DateTime.now(),
    );
  }

  PrivacySettingsModel copyWith({
    String? userId,
    ProfilePrivacySettings? profile,
    ContentPrivacySettings? content,
    DataPrivacySettings? data,
    LocationPrivacySettings? location,
  }) {
    return PrivacySettingsModel(
      userId: userId ?? this.userId,
      profile: profile ?? this.profile,
      content: content ?? this.content,
      data: data ?? this.data,
      location: location ?? this.location,
      updatedAt: DateTime.now(),
    );
  }

  bool isValid() => userId.isNotEmpty;
}

/// Profile privacy settings
class ProfilePrivacySettings {
  final String visibility; // public, friends, private
  final bool showLastSeen;
  final bool showOnlineStatus;
  final bool allowMessages;
  final bool allowFollowRequests;
  final bool showFollowersCount;
  final bool showFollowingCount;

  const ProfilePrivacySettings({
    this.visibility = 'public',
    this.showLastSeen = true,
    this.showOnlineStatus = true,
    this.allowMessages = true,
    this.allowFollowRequests = true,
    this.showFollowersCount = true,
    this.showFollowingCount = true,
  });

  factory ProfilePrivacySettings.fromMap(Map<String, dynamic> map) {
    return ProfilePrivacySettings(
      visibility: map['visibility'] as String? ?? 'public',
      showLastSeen: map['showLastSeen'] as bool? ?? true,
      showOnlineStatus: map['showOnlineStatus'] as bool? ?? true,
      allowMessages: map['allowMessages'] as bool? ?? true,
      allowFollowRequests: map['allowFollowRequests'] as bool? ?? true,
      showFollowersCount: map['showFollowersCount'] as bool? ?? true,
      showFollowingCount: map['showFollowingCount'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'visibility': visibility,
      'showLastSeen': showLastSeen,
      'showOnlineStatus': showOnlineStatus,
      'allowMessages': allowMessages,
      'allowFollowRequests': allowFollowRequests,
      'showFollowersCount': showFollowersCount,
      'showFollowingCount': showFollowingCount,
    };
  }

  factory ProfilePrivacySettings.defaultSettings() {
    return const ProfilePrivacySettings();
  }

  ProfilePrivacySettings copyWith({
    String? visibility,
    bool? showLastSeen,
    bool? showOnlineStatus,
    bool? allowMessages,
    bool? allowFollowRequests,
    bool? showFollowersCount,
    bool? showFollowingCount,
  }) {
    return ProfilePrivacySettings(
      visibility: visibility ?? this.visibility,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowMessages: allowMessages ?? this.allowMessages,
      allowFollowRequests: allowFollowRequests ?? this.allowFollowRequests,
      showFollowersCount: showFollowersCount ?? this.showFollowersCount,
      showFollowingCount: showFollowingCount ?? this.showFollowingCount,
    );
  }
}

/// Content privacy settings
class ContentPrivacySettings {
  final bool allowComments;
  final bool allowLikes;
  final bool allowSharing;
  final bool showInSearch;
  final bool allowEmbedding;
  final bool allowDownloads;
  final String commentsPermission; // everyone, followers, friends, none

  const ContentPrivacySettings({
    this.allowComments = true,
    this.allowLikes = true,
    this.allowSharing = true,
    this.showInSearch = true,
    this.allowEmbedding = false,
    this.allowDownloads = false,
    this.commentsPermission = 'everyone',
  });

  factory ContentPrivacySettings.fromMap(Map<String, dynamic> map) {
    return ContentPrivacySettings(
      allowComments: map['allowComments'] as bool? ?? true,
      allowLikes: map['allowLikes'] as bool? ?? true,
      allowSharing: map['allowSharing'] as bool? ?? true,
      showInSearch: map['showInSearch'] as bool? ?? true,
      allowEmbedding: map['allowEmbedding'] as bool? ?? false,
      allowDownloads: map['allowDownloads'] as bool? ?? false,
      commentsPermission: map['commentsPermission'] as String? ?? 'everyone',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowComments': allowComments,
      'allowLikes': allowLikes,
      'allowSharing': allowSharing,
      'showInSearch': showInSearch,
      'allowEmbedding': allowEmbedding,
      'allowDownloads': allowDownloads,
      'commentsPermission': commentsPermission,
    };
  }

  factory ContentPrivacySettings.defaultSettings() {
    return const ContentPrivacySettings();
  }

  ContentPrivacySettings copyWith({
    bool? allowComments,
    bool? allowLikes,
    bool? allowSharing,
    bool? showInSearch,
    bool? allowEmbedding,
    bool? allowDownloads,
    String? commentsPermission,
  }) {
    return ContentPrivacySettings(
      allowComments: allowComments ?? this.allowComments,
      allowLikes: allowLikes ?? this.allowLikes,
      allowSharing: allowSharing ?? this.allowSharing,
      showInSearch: showInSearch ?? this.showInSearch,
      allowEmbedding: allowEmbedding ?? this.allowEmbedding,
      allowDownloads: allowDownloads ?? this.allowDownloads,
      commentsPermission: commentsPermission ?? this.commentsPermission,
    );
  }
}

/// Data privacy settings for GDPR/CCPA compliance
class DataPrivacySettings {
  final bool allowAnalytics;
  final bool allowPersonalization;
  final bool allowMarketing;
  final bool allowThirdPartySharing;
  final bool allowCookies;
  final bool allowTargetedAds;
  final List<String> dataRetentionPreferences;

  const DataPrivacySettings({
    this.allowAnalytics = true,
    this.allowPersonalization = true,
    this.allowMarketing = false,
    this.allowThirdPartySharing = false,
    this.allowCookies = true,
    this.allowTargetedAds = false,
    this.dataRetentionPreferences = const ['essential'],
  });

  factory DataPrivacySettings.fromMap(Map<String, dynamic> map) {
    return DataPrivacySettings(
      allowAnalytics: map['allowAnalytics'] as bool? ?? true,
      allowPersonalization: map['allowPersonalization'] as bool? ?? true,
      allowMarketing: map['allowMarketing'] as bool? ?? false,
      allowThirdPartySharing: map['allowThirdPartySharing'] as bool? ?? false,
      allowCookies: map['allowCookies'] as bool? ?? true,
      allowTargetedAds: map['allowTargetedAds'] as bool? ?? false,
      dataRetentionPreferences: List<String>.from(
        map['dataRetentionPreferences'] as List<dynamic>? ?? ['essential'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allowAnalytics': allowAnalytics,
      'allowPersonalization': allowPersonalization,
      'allowMarketing': allowMarketing,
      'allowThirdPartySharing': allowThirdPartySharing,
      'allowCookies': allowCookies,
      'allowTargetedAds': allowTargetedAds,
      'dataRetentionPreferences': dataRetentionPreferences,
    };
  }

  factory DataPrivacySettings.defaultSettings() {
    return const DataPrivacySettings();
  }

  DataPrivacySettings copyWith({
    bool? allowAnalytics,
    bool? allowPersonalization,
    bool? allowMarketing,
    bool? allowThirdPartySharing,
    bool? allowCookies,
    bool? allowTargetedAds,
    List<String>? dataRetentionPreferences,
  }) {
    return DataPrivacySettings(
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowPersonalization: allowPersonalization ?? this.allowPersonalization,
      allowMarketing: allowMarketing ?? this.allowMarketing,
      allowThirdPartySharing:
          allowThirdPartySharing ?? this.allowThirdPartySharing,
      allowCookies: allowCookies ?? this.allowCookies,
      allowTargetedAds: allowTargetedAds ?? this.allowTargetedAds,
      dataRetentionPreferences:
          dataRetentionPreferences ?? this.dataRetentionPreferences,
    );
  }
}

/// Location privacy settings
class LocationPrivacySettings {
  final bool shareLocation;
  final bool showLocationInProfile;
  final bool allowLocationBasedRecommendations;
  final bool allowLocationHistory;
  final String locationAccuracy; // precise, approximate, none

  const LocationPrivacySettings({
    this.shareLocation = false,
    this.showLocationInProfile = false,
    this.allowLocationBasedRecommendations = true,
    this.allowLocationHistory = false,
    this.locationAccuracy = 'approximate',
  });

  factory LocationPrivacySettings.fromMap(Map<String, dynamic> map) {
    return LocationPrivacySettings(
      shareLocation: map['shareLocation'] as bool? ?? false,
      showLocationInProfile: map['showLocationInProfile'] as bool? ?? false,
      allowLocationBasedRecommendations:
          map['allowLocationBasedRecommendations'] as bool? ?? true,
      allowLocationHistory: map['allowLocationHistory'] as bool? ?? false,
      locationAccuracy: map['locationAccuracy'] as String? ?? 'approximate',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shareLocation': shareLocation,
      'showLocationInProfile': showLocationInProfile,
      'allowLocationBasedRecommendations': allowLocationBasedRecommendations,
      'allowLocationHistory': allowLocationHistory,
      'locationAccuracy': locationAccuracy,
    };
  }

  factory LocationPrivacySettings.defaultSettings() {
    return const LocationPrivacySettings();
  }

  LocationPrivacySettings copyWith({
    bool? shareLocation,
    bool? showLocationInProfile,
    bool? allowLocationBasedRecommendations,
    bool? allowLocationHistory,
    String? locationAccuracy,
  }) {
    return LocationPrivacySettings(
      shareLocation: shareLocation ?? this.shareLocation,
      showLocationInProfile:
          showLocationInProfile ?? this.showLocationInProfile,
      allowLocationBasedRecommendations:
          allowLocationBasedRecommendations ??
          this.allowLocationBasedRecommendations,
      allowLocationHistory: allowLocationHistory ?? this.allowLocationHistory,
      locationAccuracy: locationAccuracy ?? this.locationAccuracy,
    );
  }
}
