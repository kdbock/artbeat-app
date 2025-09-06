import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for profile customization settings
class ProfileCustomizationModel {
  final String userId;
  final String? selectedTheme;
  final String? primaryColor;
  final String? secondaryColor;
  final String? coverPhotoUrl;
  final bool showBio;
  final bool showLocation;
  final bool showAchievements;
  final bool showActivity;
  final String? layoutStyle;
  final Map<String, bool> visibilitySettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileCustomizationModel({
    required this.userId,
    this.selectedTheme,
    this.primaryColor,
    this.secondaryColor,
    this.coverPhotoUrl,
    this.showBio = true,
    this.showLocation = true,
    this.showAchievements = true,
    this.showActivity = true,
    this.layoutStyle,
    this.visibilitySettings = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileCustomizationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileCustomizationModel(
      userId: doc.id,
      selectedTheme: data['selectedTheme'] as String?,
      primaryColor: data['primaryColor'] as String?,
      secondaryColor: data['secondaryColor'] as String?,
      coverPhotoUrl: data['coverPhotoUrl'] as String?,
      showBio: (data['showBio'] as bool?) ?? true,
      showLocation: (data['showLocation'] as bool?) ?? true,
      showAchievements: (data['showAchievements'] as bool?) ?? true,
      showActivity: (data['showActivity'] as bool?) ?? true,
      layoutStyle: data['layoutStyle'] as String?,
      visibilitySettings: Map<String, bool>.from(
        (data['visibilitySettings'] as Map<String, dynamic>?) ?? {},
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'selectedTheme': selectedTheme,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'coverPhotoUrl': coverPhotoUrl,
      'showBio': showBio,
      'showLocation': showLocation,
      'showAchievements': showAchievements,
      'showActivity': showActivity,
      'layoutStyle': layoutStyle,
      'visibilitySettings': visibilitySettings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ProfileCustomizationModel copyWith({
    String? selectedTheme,
    String? primaryColor,
    String? secondaryColor,
    String? coverPhotoUrl,
    bool? showBio,
    bool? showLocation,
    bool? showAchievements,
    bool? showActivity,
    String? layoutStyle,
    Map<String, bool>? visibilitySettings,
    DateTime? updatedAt,
  }) {
    return ProfileCustomizationModel(
      userId: userId,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      showBio: showBio ?? this.showBio,
      showLocation: showLocation ?? this.showLocation,
      showAchievements: showAchievements ?? this.showAchievements,
      showActivity: showActivity ?? this.showActivity,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      visibilitySettings: visibilitySettings ?? this.visibilitySettings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
