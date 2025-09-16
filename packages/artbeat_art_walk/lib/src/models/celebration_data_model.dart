import 'package:equatable/equatable.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

/// Data model for art walk completion celebration
class CelebrationData extends Equatable {
  final ArtWalkModel walk;
  final ArtWalkProgress progress;
  final Duration walkDuration;
  final double distanceWalked;
  final int artPiecesVisited;
  final int pointsEarned;
  final List<AchievementModel> newAchievements;
  final List<String> visitedArtPhotos;
  final Map<String, dynamic> personalBests;
  final List<CelebrationMilestone> milestones;
  final CelebrationType celebrationType;

  const CelebrationData({
    required this.walk,
    required this.progress,
    required this.walkDuration,
    required this.distanceWalked,
    required this.artPiecesVisited,
    required this.pointsEarned,
    required this.newAchievements,
    required this.visitedArtPhotos,
    required this.personalBests,
    required this.milestones,
    required this.celebrationType,
  });

  /// Whether this is a significant achievement worth extra celebration
  bool get isSignificantAchievement {
    return celebrationType == CelebrationType.majorMilestone ||
        newAchievements.length >= 3 ||
        pointsEarned >= 500;
  }

  /// Get the primary celebration message
  String get primaryMessage {
    switch (celebrationType) {
      case CelebrationType.firstWalk:
        return 'Congratulations on your first Art Walk! 🎉';
      case CelebrationType.regularCompletion:
        return 'Art Walk Completed! 🎨';
      case CelebrationType.perfectScore:
        return 'Perfect Walk! You visited every art piece! ⭐';
      case CelebrationType.speedRun:
        return 'Speed Walker! Completed in record time! ⚡';
      case CelebrationType.majorMilestone:
        return 'Major Milestone Achieved! 🏆';
      case CelebrationType.comeback:
        return 'Welcome Back! Great to see you walking again! 🌟';
    }
  }

  /// Get the secondary celebration message
  String get secondaryMessage {
    final messages = <String>[];

    if (artPiecesVisited > 0) {
      messages.add('$artPiecesVisited art pieces discovered');
    }

    if (pointsEarned > 0) {
      messages.add('$pointsEarned points earned');
    }

    if (walkDuration.inMinutes > 0) {
      messages.add('${walkDuration.inMinutes} minutes of exploration');
    }

    if (distanceWalked > 0) {
      messages.add('${distanceWalked.toStringAsFixed(1)}km walked');
    }

    return messages.join(' • ');
  }

  /// Get sharing text for social media
  String get sharingText {
    return 'Just completed "${walk.title}" on ARTbeat! '
        'Discovered $artPiecesVisited amazing art pieces and earned $pointsEarned points. '
        '${newAchievements.isNotEmpty ? "Unlocked ${newAchievements.length} new achievements! " : ""}'
        '#ARTbeat #ArtWalk #PublicArt';
  }

  @override
  List<Object?> get props => [
    walk,
    progress,
    walkDuration,
    distanceWalked,
    artPiecesVisited,
    pointsEarned,
    newAchievements,
    visitedArtPhotos,
    personalBests,
    milestones,
    celebrationType,
  ];
}

/// Types of celebrations based on achievement level
enum CelebrationType {
  firstWalk,
  regularCompletion,
  perfectScore,
  speedRun,
  majorMilestone,
  comeback,
}

/// Individual milestones achieved during the walk
class CelebrationMilestone extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int pointsAwarded;
  final MilestoneType type;
  final Map<String, dynamic> metadata;

  const CelebrationMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsAwarded,
    required this.type,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    icon,
    pointsAwarded,
    type,
    metadata,
  ];
}

/// Types of milestones that can be achieved
enum MilestoneType {
  distance,
  time,
  artPieces,
  photography,
  social,
  exploration,
  consistency,
}

/// Factory class for creating celebration data
class CelebrationDataFactory {
  /// Create celebration data from walk completion
  static CelebrationData create({
    required ArtWalkModel walk,
    required ArtWalkProgress progress,
    required List<AchievementModel> newAchievements,
    required int pointsEarned,
    List<String> visitedArtPhotos = const [],
    Map<String, dynamic> personalBests = const {},
  }) {
    final walkDuration = progress.timeSpent;
    final artPiecesVisited = progress.visitedArt.length;

    // Calculate distance walked (simplified - could be enhanced with actual route data)
    final distanceWalked = _estimateDistanceWalked(progress);

    // Determine celebration type
    final celebrationType = _determineCelebrationType(
      walk,
      progress,
      newAchievements,
      personalBests,
    );

    // Generate milestones
    final milestones = _generateMilestones(
      walk,
      progress,
      pointsEarned,
      personalBests,
    );

    return CelebrationData(
      walk: walk,
      progress: progress,
      walkDuration: walkDuration,
      distanceWalked: distanceWalked,
      artPiecesVisited: artPiecesVisited,
      pointsEarned: pointsEarned,
      newAchievements: newAchievements,
      visitedArtPhotos: visitedArtPhotos,
      personalBests: personalBests,
      milestones: milestones,
      celebrationType: celebrationType,
    );
  }

  /// Estimate distance walked based on art piece locations
  static double _estimateDistanceWalked(ArtWalkProgress progress) {
    // This is a simplified calculation
    // In a real implementation, you'd use the actual route data
    return progress.visitedArt.length *
        0.2; // Rough estimate: 200m between art pieces
  }

  /// Determine the type of celebration based on achievements
  static CelebrationType _determineCelebrationType(
    ArtWalkModel walk,
    ArtWalkProgress progress,
    List<AchievementModel> newAchievements,
    Map<String, dynamic> personalBests,
  ) {
    // Check for first walk
    if (newAchievements.any((a) => a.type == AchievementType.firstWalk)) {
      return CelebrationType.firstWalk;
    }

    // Check for perfect score (visited all art pieces)
    if (progress.progressPercentage >= 1.0) {
      return CelebrationType.perfectScore;
    }

    // Check for speed run (completed quickly)
    if (progress.timeSpent.inMinutes <= 30 &&
        progress.progressPercentage >= 0.8) {
      return CelebrationType.speedRun;
    }

    // Check for major milestone
    if (newAchievements.length >= 3 ||
        newAchievements.any((a) => a.type == AchievementType.walkMaster)) {
      return CelebrationType.majorMilestone;
    }

    // Check for comeback (first walk in a while)
    final daysSinceLastWalk = personalBests['daysSinceLastWalk'] as int? ?? 0;
    if (daysSinceLastWalk >= 30) {
      return CelebrationType.comeback;
    }

    return CelebrationType.regularCompletion;
  }

  /// Generate milestones achieved during the walk
  static List<CelebrationMilestone> _generateMilestones(
    ArtWalkModel walk,
    ArtWalkProgress progress,
    int pointsEarned,
    Map<String, dynamic> personalBests,
  ) {
    final milestones = <CelebrationMilestone>[];

    // Distance milestone
    final distanceWalked = _estimateDistanceWalked(progress);
    if (distanceWalked >= 2.0) {
      milestones.add(
        CelebrationMilestone(
          id: 'distance_2km',
          title: 'Distance Walker',
          description: 'Walked over 2km exploring art',
          icon: '🚶‍♂️',
          pointsAwarded: 25,
          type: MilestoneType.distance,
          metadata: {'distance': distanceWalked},
        ),
      );
    }

    // Time milestone
    if (progress.timeSpent.inMinutes >= 60) {
      milestones.add(
        CelebrationMilestone(
          id: 'time_1hour',
          title: 'Art Enthusiast',
          description: 'Spent over an hour appreciating art',
          icon: '⏰',
          pointsAwarded: 30,
          type: MilestoneType.time,
          metadata: {'minutes': progress.timeSpent.inMinutes},
        ),
      );
    }

    // Art pieces milestone
    if (progress.visitedArt.length >= 10) {
      milestones.add(
        CelebrationMilestone(
          id: 'art_10pieces',
          title: 'Art Explorer',
          description: 'Discovered 10+ art pieces in one walk',
          icon: '🎨',
          pointsAwarded: 40,
          type: MilestoneType.artPieces,
          metadata: {'artCount': progress.visitedArt.length},
        ),
      );
    }

    // Photography milestone
    final photosCount = progress.visitedArt
        .where((ArtVisit v) => v.photoTaken != null)
        .length;
    if (photosCount >= 5) {
      milestones.add(
        CelebrationMilestone(
          id: 'photography_5photos',
          title: 'Art Photographer',
          description: 'Captured 5+ art pieces with photos',
          icon: '📸',
          pointsAwarded: 35,
          type: MilestoneType.photography,
          metadata: {'photoCount': photosCount},
        ),
      );
    }

    return milestones;
  }
}
