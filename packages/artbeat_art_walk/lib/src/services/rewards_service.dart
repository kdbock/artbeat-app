import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

/// Service for managing user rewards, XP, and achievements
class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  /// XP rewards for different actions
  static const Map<String, int> _xpRewards = {
    'art_capture_approved': 50,
    'art_walk_completion': 100,
    'art_walk_creation': 75, // Creating a new art walk
    'art_visit': 10, // For individual art visits during walks
    'review_submission': 30, // Minimum 50 words required
    'helpful_vote_received': 10,
    'public_walk_popular': 75, // When your walk is used by 5+ users
    'walk_edit': 20, // Editing or updating existing walk
  };

  /// Level system with art movement titles and XP thresholds
  static const Map<int, Map<String, dynamic>> levelSystem = {
    1: {'title': 'Sketcher (Frida Kahlo)', 'minXP': 0, 'maxXP': 199},
    2: {'title': 'Color Blender (Jacob Lawrence)', 'minXP': 200, 'maxXP': 499},
    3: {
      'title': 'Brush Trailblazer (Yayoi Kusama)',
      'minXP': 500,
      'maxXP': 999,
    },
    4: {
      'title': 'Street Master (Jean-Michel Basquiat)',
      'minXP': 1000,
      'maxXP': 1499,
    },
    5: {'title': 'Mural Maven (Faith Ringgold)', 'minXP': 1500, 'maxXP': 2499},
    6: {
      'title': 'Avant-Garde Explorer (Zarina Hashmi)',
      'minXP': 2500,
      'maxXP': 3999,
    },
    7: {
      'title': 'Visionary Creator (El Anatsui)',
      'minXP': 4000,
      'maxXP': 5999,
    },
    8: {
      'title': 'Art Legend (Leonardo da Vinci)',
      'minXP': 6000,
      'maxXP': 7999,
    },
    9: {
      'title': 'Cultural Curator (Shirin Neshat)',
      'minXP': 8000,
      'maxXP': 9999,
    },
    10: {'title': 'Art Walk Influencer', 'minXP': 10000, 'maxXP': 999999},
  };

  /// Badge definitions with requirements
  static const Map<String, Map<String, dynamic>> badges = {
    // First achievements
    'first_walk_completed': {
      'name': 'First Walk Completed',
      'description': 'Complete your first art walk',
      'icon': '🚶',
      'requirement': {'type': 'walks_completed', 'count': 1},
    },
    'first_walk_created': {
      'name': 'First Walk Created',
      'description': 'Create your first art walk',
      'icon': '🎨',
      'requirement': {'type': 'walks_created', 'count': 1},
    },
    'first_capture_approved': {
      'name': 'First Capture Approved',
      'description': 'Get your first art capture approved',
      'icon': '📸',
      'requirement': {'type': 'captures_approved', 'count': 1},
    },
    'first_review_submitted': {
      'name': 'First Review Submitted',
      'description': 'Submit your first review',
      'icon': '✍️',
      'requirement': {'type': 'reviews_submitted', 'count': 1},
    },
    'first_helpful_vote': {
      'name': 'First Helpful Vote Received',
      'description': 'Receive your first helpful vote on a review',
      'icon': '👍',
      'requirement': {'type': 'helpful_votes', 'count': 1},
    },

    // Milestone achievements
    'ten_walks_completed': {
      'name': 'Ten Walks Completed',
      'description': 'Complete 10 art walks',
      'icon': '🏃',
      'requirement': {'type': 'walks_completed', 'count': 10},
    },
    'ten_captures_approved': {
      'name': 'Ten Captures Approved',
      'description': 'Get 10 art captures approved',
      'icon': '📷',
      'requirement': {'type': 'captures_approved', 'count': 10},
    },
    'ten_reviews_submitted': {
      'name': 'Ten Reviews Submitted',
      'description': 'Submit 10 reviews',
      'icon': '📝',
      'requirement': {'type': 'reviews_submitted', 'count': 10},
    },
    'ten_helpful_votes': {
      'name': 'Ten Helpful Votes Received',
      'description': 'Receive 10 helpful votes on reviews',
      'icon': '🌟',
      'requirement': {'type': 'helpful_votes', 'count': 10},
    },

    // Creator achievements
    'gallery_builder': {
      'name': 'Gallery Builder',
      'description': 'Create 5 art walks',
      'icon': '🏛️',
      'requirement': {'type': 'walks_created', 'count': 5},
    },
    'reviewer_extraordinaire': {
      'name': 'Reviewer Extraordinaire',
      'description': 'Submit 50 reviews',
      'icon': '🎭',
      'requirement': {'type': 'reviews_submitted', 'count': 50},
    },
    'popular_walk_creator': {
      'name': 'Popular Walk Creator',
      'description': 'Create a walk used by 10+ users',
      'icon': '🔥',
      'requirement': {'type': 'walk_popularity', 'count': 10},
    },

    // XP Level achievements
    'contributor_level_1': {
      'name': 'Contributor Level 1',
      'description': 'Reach 100 XP',
      'icon': '🥉',
      'requirement': {'type': 'total_xp', 'count': 100},
    },
    'contributor_level_2': {
      'name': 'Contributor Level 2',
      'description': 'Reach 500 XP',
      'icon': '🥈',
      'requirement': {'type': 'total_xp', 'count': 500},
    },
    'contributor_level_3': {
      'name': 'Contributor Level 3',
      'description': 'Reach 1000 XP',
      'icon': '🥇',
      'requirement': {'type': 'total_xp', 'count': 1000},
    },

    // Explorer achievements
    'artistic_explorer': {
      'name': 'Artistic Explorer',
      'description': 'Visit 10 different art locations',
      'icon': '🗺️',
      'requirement': {'type': 'locations_visited', 'count': 10},
    },
    'consistent_walker': {
      'name': 'Consistent Walker',
      'description': 'Complete 5 walks in a week',
      'icon': '📅',
      'requirement': {'type': 'walks_per_week', 'count': 5},
    },
    'helpful_reviewer': {
      'name': 'Helpful Reviewer',
      'description': 'Receive 20 helpful votes',
      'icon': '💡',
      'requirement': {'type': 'helpful_votes', 'count': 20},
    },

    // Special achievements
    'art_historian': {
      'name': 'Art Historian',
      'description': 'Review 25 different artworks',
      'icon': '📚',
      'requirement': {'type': 'unique_artworks_reviewed', 'count': 25},
    },
    'community_voice': {
      'name': 'Community Voice',
      'description': 'Submit 50 reviews with helpful votes',
      'icon': '📢',
      'requirement': {'type': 'helpful_reviews', 'count': 50},
    },
    'top_rated_walk': {
      'name': 'Top Rated Walk',
      'description': 'Create a walk with 5 stars and 10+ votes',
      'icon': '⭐',
      'requirement': {'type': 'top_rated_walk', 'rating': 5.0, 'votes': 10},
    },

    // Advanced achievements
    'capture_collector': {
      'name': 'Capture Collector',
      'description': 'Get 50 captures approved',
      'icon': '🎯',
      'requirement': {'type': 'captures_approved', 'count': 50},
    },
    'daily_walker': {
      'name': 'Daily Walker',
      'description': 'Complete 1 walk per day for 7 days',
      'icon': '🌅',
      'requirement': {'type': 'daily_streak', 'count': 7},
    },
    'local_guide': {
      'name': 'Local Guide',
      'description': 'Capture 10 artworks from your home area',
      'icon': '🏠',
      'requirement': {'type': 'local_captures', 'count': 10},
    },
    'art_enthusiast': {
      'name': 'Art Enthusiast',
      'description': 'Reach 1000 XP total',
      'icon': '🎨',
      'requirement': {'type': 'total_xp', 'count': 1000},
    },
    'seasoned_contributor': {
      'name': 'Seasoned Contributor',
      'description': 'Reach 5000 XP total',
      'icon': '🏆',
      'requirement': {'type': 'total_xp', 'count': 5000},
    },
    'artistic_influencer': {
      'name': 'Artistic Influencer',
      'description': 'Reach 10000 XP and create 20 public walks',
      'icon': '👑',
      'requirement': {'type': 'influencer', 'xp': 10000, 'walks': 20},
    },
  };

  /// Level unlockable perks
  static const Map<int, List<String>> levelPerks = {
    3: ['Suggest edits to any public artwork'],
    5: ['Moderate reviews (report abuse, vote quality)'],
    7: ['Early access to beta features'],
    10: [
      'Become an Art Walk Influencer',
      'Post updates and thoughts on art walks',
      'Featured profile section',
      'Eligible for community spotlight',
    ],
  };

  /// Award XP to the current user
  Future<void> awardXP(String action, {int? customAmount}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final xpAmount = customAmount ?? _xpRewards[action] ?? 0;
    if (xpAmount <= 0) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data() ?? {};

        final currentXP = userData['experiencePoints'] as int? ?? 0;
        final newXP = currentXP + xpAmount;
        final newLevel = _calculateLevel(newXP);
        final oldLevel = _calculateLevel(currentXP);

        // Update user stats
        final updates = <String, dynamic>{
          'experiencePoints': newXP,
          'level': newLevel,
          'lastXPGain': FieldValue.serverTimestamp(),
        };

        // Track action-specific stats
        switch (action) {
          case 'art_capture_approved':
            updates['stats.capturesApproved'] = FieldValue.increment(1);
            break;
          case 'art_walk_completion':
            updates['stats.walksCompleted'] = FieldValue.increment(1);
            break;
          case 'art_walk_creation':
            updates['stats.walksCreated'] = FieldValue.increment(1);
            break;
          case 'review_submission':
            updates['stats.reviewsSubmitted'] = FieldValue.increment(1);
            break;
          case 'helpful_vote_received':
            updates['stats.helpfulVotes'] = FieldValue.increment(1);
            break;
          case 'public_walk_popular':
            updates['stats.popularWalks'] = FieldValue.increment(1);
            break;
          case 'walk_edit':
            updates['stats.walksEdited'] = FieldValue.increment(1);
            break;
        }

        transaction.update(userRef, updates);

        // Check for new achievements if level increased
        if (newLevel > oldLevel) {
          _checkLevelAchievements(user.uid, newLevel, newXP);
        }

        // Check for action-specific achievements
        _checkActionAchievements(user.uid, action, userData);
      });

      _logger.i('Awarded $xpAmount XP for $action to user ${user.uid}');
    } catch (e) {
      _logger.e('Error awarding XP: $e');
    }
  }

  /// Calculate user level based on XP
  int _calculateLevel(int xp) {
    for (int level = 10; level >= 1; level--) {
      final levelData = levelSystem[level]!;
      if (xp >= (levelData['minXP'] as int)) {
        return level;
      }
    }
    return 1;
  }

  /// Get level title for a given level
  String getLevelTitle(int level) {
    return (levelSystem[level]?['title'] as String?) ?? 'Unknown Level';
  }

  /// Get XP range for a level
  Map<String, int> getLevelXPRange(int level) {
    final levelData = levelSystem[level];
    if (levelData == null) return {'min': 0, 'max': 199};
    return {'min': levelData['minXP'] as int, 'max': levelData['maxXP'] as int};
  }

  /// Get level progress (0.0 to 1.0)
  double getLevelProgress(int currentXP, int level) {
    final range = getLevelXPRange(level);
    if (level >= 10) return 1.0; // Max level

    final progressXP = currentXP - range['min']!;
    final requiredXP = range['max']! - range['min']! + 1;

    return (progressXP / requiredXP).clamp(0.0, 1.0);
  }

  /// Check for level-based achievements
  Future<void> _checkLevelAchievements(
    String userId,
    int newLevel,
    int xp,
  ) async {
    // Check XP milestone badges
    final xpBadges = [
      'contributor_level_1',
      'contributor_level_2',
      'contributor_level_3',
      'art_enthusiast',
      'seasoned_contributor',
    ];

    for (final badgeId in xpBadges) {
      final badge = badges[badgeId]!;
      final requirement = badge['requirement'] as Map<String, dynamic>;

      if (requirement['type'] == 'total_xp' &&
          xp >= (requirement['count'] as int)) {
        await _awardBadge(userId, badgeId);
      }
    }

    // Check for influencer status
    if (xp >= 10000) {
      // Need to check if user also has 20 public walks
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final walksCreated =
          userDoc.data()?['stats']?['walksCreated'] as int? ?? 0;

      if (walksCreated >= 20) {
        await _awardBadge(userId, 'artistic_influencer');
      }
    }
  }

  /// Check for action-specific achievements
  Future<void> _checkActionAchievements(
    String userId,
    String action,
    Map<String, dynamic> userData,
  ) async {
    final stats = userData['stats'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'art_walk_completion':
        final walksCompleted = (stats['walksCompleted'] as int? ?? 0) + 1;
        if (walksCompleted == 1)
          await _awardBadge(userId, 'first_walk_completed');
        if (walksCompleted == 10)
          await _awardBadge(userId, 'ten_walks_completed');
        break;

      case 'art_walk_creation':
        final walksCreated = (stats['walksCreated'] as int? ?? 0) + 1;
        if (walksCreated == 1) await _awardBadge(userId, 'first_walk_created');
        if (walksCreated == 5) await _awardBadge(userId, 'gallery_builder');
        if (walksCreated == 20) {
          // Check if user also has 10k XP for influencer status
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();
          final xp = userDoc.data()?['experiencePoints'] as int? ?? 0;
          if (xp >= 10000) {
            await _awardBadge(userId, 'artistic_influencer');
          }
        }
        break;

      case 'art_capture_approved':
        final capturesApproved = (stats['capturesApproved'] as int? ?? 0) + 1;
        if (capturesApproved == 1)
          await _awardBadge(userId, 'first_capture_approved');
        if (capturesApproved == 10)
          await _awardBadge(userId, 'ten_captures_approved');
        if (capturesApproved == 50)
          await _awardBadge(userId, 'capture_collector');
        break;

      case 'review_submission':
        final reviewsSubmitted = (stats['reviewsSubmitted'] as int? ?? 0) + 1;
        if (reviewsSubmitted == 1)
          await _awardBadge(userId, 'first_review_submitted');
        if (reviewsSubmitted == 10)
          await _awardBadge(userId, 'ten_reviews_submitted');
        if (reviewsSubmitted == 50)
          await _awardBadge(userId, 'reviewer_extraordinaire');
        break;

      case 'helpful_vote_received':
        final helpfulVotes = (stats['helpfulVotes'] as int? ?? 0) + 1;
        if (helpfulVotes == 1) await _awardBadge(userId, 'first_helpful_vote');
        if (helpfulVotes == 10) await _awardBadge(userId, 'ten_helpful_votes');
        if (helpfulVotes == 20) await _awardBadge(userId, 'helpful_reviewer');
        break;
    }
  }

  /// Award a badge to a user (public method for debugging)
  Future<void> awardBadge(String userId, String badgeId) async {
    await _awardBadge(userId, badgeId);
  }

  /// Award a badge to a user (private method)
  Future<void> _awardBadge(String userId, String badgeId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      final badgesMap =
          userDoc.data()?['badges'] as Map<String, dynamic>? ?? {};

      // Only award if not already present
      if (badgesMap.containsKey(badgeId)) {
        _logger.i('Badge $badgeId already awarded to user $userId');
        return;
      }

      await userRef.set({
        'badges': {
          badgeId: {'earnedAt': FieldValue.serverTimestamp(), 'viewed': false},
        },
      }, SetOptions(merge: true));

      _logger.i('Awarded badge $badgeId to user $userId');
    } catch (e) {
      _logger.e('Error awarding badge: $e');
    }
  }

  /// Get user's badges
  Future<Map<String, dynamic>> getUserBadges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['badges'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      _logger.e('Error getting user badges: $e');
      return {};
    }
  }

  /// Get unviewed badges for showing notifications
  Future<List<String>> getUnviewedBadges(String userId) async {
    try {
      final badges = await getUserBadges(userId);
      return badges.entries
          .where((entry) => entry.value['viewed'] == false)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      _logger.e('Error getting unviewed badges: $e');
      return [];
    }
  }

  /// Mark badges as viewed
  Future<void> markBadgesAsViewed(String userId, List<String> badgeIds) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final updates = <String, dynamic>{};

      for (final badgeId in badgeIds) {
        updates['badges.$badgeId.viewed'] = true;
      }

      await userRef.update(updates);
    } catch (e) {
      _logger.e('Error marking badges as viewed: $e');
    }
  }

  /// Get level perks for a user
  List<String> getLevelPerks(int level) {
    final perks = <String>[];
    for (final entry in levelPerks.entries) {
      if (level >= entry.key) {
        perks.addAll(entry.value);
      }
    }
    return perks;
  }

  /// Check if user has specific perk
  bool hasLevelPerk(int level, String perk) {
    final perks = getLevelPerks(level);
    return perks.any((p) => p.toLowerCase().contains(perk.toLowerCase()));
  }
}
