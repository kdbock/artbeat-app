import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/weekly_goal_model.dart';
import 'rewards_service.dart';

/// Service for managing weekly goals (longer-term challenges)
class WeeklyGoalsService {
  static final WeeklyGoalsService _instance = WeeklyGoalsService._internal();

  factory WeeklyGoalsService() => _instance;

  WeeklyGoalsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RewardsService _rewardsService = RewardsService();

  /// Get current week's goals for the user
  Future<List<WeeklyGoalModel>> getCurrentWeekGoals() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final now = DateTime.now();
      final weekKey = _getWeekKey(now);

      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyGoals')
          .where('weekNumber', isEqualTo: _getWeekNumber(now))
          .where('year', isEqualTo: now.year)
          .get();

      if (goalsSnapshot.docs.isNotEmpty) {
        return goalsSnapshot.docs
            .map((doc) => WeeklyGoalModel.fromMap(doc.data()))
            .toList();
      } else {
        // Generate new weekly goals
        final newGoals = await _generateWeeklyGoals(user.uid);
        for (final goal in newGoals) {
          await _saveWeeklyGoal(goal, weekKey);
        }
        return newGoals;
      }
    } catch (e) {
      AppLogger.error('Error getting current week goals: $e');
      return [];
    }
  }

  /// Generate weekly goals for the user (3 goals per week)
  Future<List<WeeklyGoalModel>> _generateWeeklyGoals(String userId) async {
    final userStats = await _getUserStats(userId);
    final userLevel = (userStats['level'] as int?) ?? 1;
    final now = DateTime.now();
    final weekNumber = _getWeekNumber(now);
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 7));

    // Pool of weekly goals across different categories
    final allGoals = [
      // Exploration Goals
      WeeklyGoalModel(
        id: 'weekly_explorer_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Weekly Art Explorer',
        description:
            'Discover ${_scaleTarget(15, userLevel)} pieces of art this week',
        category: WeeklyGoalCategory.exploration,
        targetCount: _scaleTarget(15, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(500, userLevel),
        rewardDescription:
            '${_scaleReward(500, userLevel)} XP + Explorer Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🗺️',
        milestones: [
          'Discover 5 artworks',
          'Discover 10 artworks',
          'Complete the challenge!',
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_neighborhoods_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Neighborhood Navigator',
        description:
            'Explore ${_scaleTarget(5, userLevel)} different neighborhoods',
        category: WeeklyGoalCategory.exploration,
        targetCount: _scaleTarget(5, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(600, userLevel),
        rewardDescription:
            '${_scaleReward(600, userLevel)} XP + Navigator Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🏘️',
        milestones: [
          'Visit 2 neighborhoods',
          'Visit 4 neighborhoods',
          'Complete the challenge!',
        ],
      ),

      // Photography Goals
      WeeklyGoalModel(
        id: 'weekly_photographer_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Master Photographer',
        description:
            'Capture ${_scaleTarget(20, userLevel)} stunning art photos',
        category: WeeklyGoalCategory.photography,
        targetCount: _scaleTarget(20, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(550, userLevel),
        rewardDescription:
            '${_scaleReward(550, userLevel)} XP + Photographer Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '📸',
        milestones: [
          'Take 7 photos',
          'Take 14 photos',
          'Complete the challenge!',
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_golden_hour_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Golden Hour Master',
        description:
            'Capture ${_scaleTarget(10, userLevel)} artworks during golden hour',
        category: WeeklyGoalCategory.photography,
        targetCount: _scaleTarget(10, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(700, userLevel),
        rewardDescription:
            '${_scaleReward(700, userLevel)} XP + Golden Hour Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🌅',
        milestones: [
          'Capture 3 golden hour photos',
          'Capture 7 golden hour photos',
          'Complete the challenge!',
        ],
      ),

      // Social Goals
      WeeklyGoalModel(
        id: 'weekly_social_butterfly_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Social Butterfly',
        description:
            'Share ${_scaleTarget(10, userLevel)} discoveries and get ${_scaleTarget(20, userLevel)} likes',
        category: WeeklyGoalCategory.social,
        targetCount: _scaleTarget(10, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(450, userLevel),
        rewardDescription: '${_scaleReward(450, userLevel)} XP + Social Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🦋',
        milestones: [
          'Share 3 discoveries',
          'Share 7 discoveries',
          'Complete the challenge!',
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_community_builder_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Community Builder',
        description:
            'Comment on ${_scaleTarget(15, userLevel)} other users\' discoveries',
        category: WeeklyGoalCategory.social,
        targetCount: _scaleTarget(15, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(500, userLevel),
        rewardDescription:
            '${_scaleReward(500, userLevel)} XP + Community Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🤝',
        milestones: [
          'Comment 5 times',
          'Comment 10 times',
          'Complete the challenge!',
        ],
      ),

      // Fitness Goals
      WeeklyGoalModel(
        id: 'weekly_walker_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Urban Walker',
        description: 'Walk ${_scaleTarget(15, userLevel)}km exploring art',
        category: WeeklyGoalCategory.fitness,
        targetCount: _scaleTarget(15000, userLevel), // meters
        currentCount: 0,
        rewardXP: _scaleReward(650, userLevel),
        rewardDescription: '${_scaleReward(650, userLevel)} XP + Walker Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🚶',
        milestones: ['Walk 5km', 'Walk 10km', 'Complete the challenge!'],
      ),
      WeeklyGoalModel(
        id: 'weekly_step_champion_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Step Champion',
        description:
            'Take ${_scaleTarget(35000, userLevel)} steps on your art journey',
        category: WeeklyGoalCategory.fitness,
        targetCount: _scaleTarget(35000, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(600, userLevel),
        rewardDescription:
            '${_scaleReward(600, userLevel)} XP + Champion Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '👟',
        milestones: [
          'Take 10,000 steps',
          'Take 25,000 steps',
          'Complete the challenge!',
        ],
      ),

      // Mastery Goals
      WeeklyGoalModel(
        id: 'weekly_quest_master_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Quest Master',
        description: 'Complete ${_scaleTarget(5, userLevel)} daily quests',
        category: WeeklyGoalCategory.mastery,
        targetCount: _scaleTarget(5, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(800, userLevel),
        rewardDescription: '${_scaleReward(800, userLevel)} XP + Master Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🏆',
        milestones: [
          'Complete 2 daily quests',
          'Complete 4 daily quests',
          'Complete the challenge!',
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_streak_keeper_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Streak Keeper',
        description: 'Maintain a 7-day streak',
        category: WeeklyGoalCategory.mastery,
        targetCount: 7,
        currentCount: 0,
        rewardXP: _scaleReward(1000, userLevel),
        rewardDescription:
            '${_scaleReward(1000, userLevel)} XP + Legendary Streak Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🔥',
        milestones: [
          'Maintain 3-day streak',
          'Maintain 5-day streak',
          'Complete the challenge!',
        ],
      ),

      // Collection Goals
      WeeklyGoalModel(
        id: 'weekly_style_collector_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Style Collector',
        description:
            'Find art in ${_scaleTarget(8, userLevel)} different styles',
        category: WeeklyGoalCategory.collection,
        targetCount: _scaleTarget(8, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(750, userLevel),
        rewardDescription:
            '${_scaleReward(750, userLevel)} XP + Collector Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🎨',
        milestones: [
          'Collect 3 styles',
          'Collect 6 styles',
          'Complete the challenge!',
        ],
      ),
      WeeklyGoalModel(
        id: 'weekly_artist_fan_${now.millisecondsSinceEpoch}',
        userId: userId,
        title: 'Artist Fan',
        description:
            'Discover works from ${_scaleTarget(10, userLevel)} different artists',
        category: WeeklyGoalCategory.collection,
        targetCount: _scaleTarget(10, userLevel),
        currentCount: 0,
        rewardXP: _scaleReward(700, userLevel),
        rewardDescription: '${_scaleReward(700, userLevel)} XP + Fan Badge',
        isCompleted: false,
        createdAt: now,
        expiresAt: weekEnd,
        weekNumber: weekNumber,
        year: now.year,
        iconEmoji: '🎭',
        milestones: [
          'Discover 3 artists',
          'Discover 7 artists',
          'Complete the challenge!',
        ],
      ),
    ];

    // Select 3 goals from different categories
    final selectedGoals = <WeeklyGoalModel>[];
    final usedCategories = <WeeklyGoalCategory>{};

    // Use week number and user ID as seed for consistent selection
    final seed = weekNumber + (userId.hashCode % 100);
    final random = Random(seed);

    // Shuffle goals deterministically based on seed
    final shuffledGoals = List<WeeklyGoalModel>.from(allGoals);
    shuffledGoals.shuffle(random);

    // Select 3 goals from different categories
    for (final goal in shuffledGoals) {
      if (!usedCategories.contains(goal.category)) {
        selectedGoals.add(goal);
        usedCategories.add(goal.category);
        if (selectedGoals.length == 3) break;
      }
    }

    // If we couldn't get 3 different categories, just take the first 3
    if (selectedGoals.length < 3) {
      return shuffledGoals.take(3).toList();
    }

    return selectedGoals;
  }

  /// Scale target count based on user level
  int _scaleTarget(int baseTarget, int userLevel) {
    if (userLevel <= 5) return baseTarget;
    if (userLevel <= 10) return (baseTarget * 1.2).round();
    if (userLevel <= 20) return (baseTarget * 1.5).round();
    return (baseTarget * 2).round();
  }

  /// Scale reward XP based on user level
  int _scaleReward(int baseReward, int userLevel) {
    if (userLevel <= 5) return baseReward;
    if (userLevel <= 10) return (baseReward * 1.3).round();
    if (userLevel <= 20) return (baseReward * 1.6).round();
    return (baseReward * 2).round();
  }

  /// Get user statistics for goal personalization
  Future<Map<String, dynamic>> _getUserStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return {};

      final userData = userDoc.data() ?? {};

      return {
        'level': userData['level'] ?? 1,
        'totalXP': userData['totalXP'] ?? 0,
      };
    } catch (e) {
      AppLogger.error('Error getting user stats: $e');
      return {};
    }
  }

  /// Update weekly goal progress
  Future<void> updateWeeklyGoalProgress(String goalId, int increment) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final weekKey = _getWeekKey(now);

      final goalRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyGoals')
          .doc('${weekKey}_$goalId');

      await _firestore.runTransaction((transaction) async {
        final goalDoc = await transaction.get(goalRef);

        if (!goalDoc.exists) return;

        final goal = WeeklyGoalModel.fromMap(goalDoc.data()!);
        final newCount = (goal.currentCount + increment).clamp(
          0,
          goal.targetCount,
        );

        if (newCount >= goal.targetCount && !goal.isCompleted) {
          // Goal completed! Award XP with combo multiplier
          await _rewardsService.awardXPWithCombo(
            'weekly_goal_completed',
            baseXP: goal.rewardXP,
            isDailyChallenge: false,
            isWeeklyGoal: true,
          );

          transaction.update(goalRef, {
            'currentCount': newCount,
            'isCompleted': true,
            'completedAt': Timestamp.now(),
          });

          AppLogger.info('Weekly goal completed: ${goal.title}');

          // Check for perfect week badge (after transaction completes)
          final weekKey = _getWeekKey(DateTime.now());
          await _rewardsService.checkPerfectWeek(user.uid, weekKey);

          // Check quest milestones
          await _rewardsService.checkQuestMilestones(user.uid);
        } else {
          transaction.update(goalRef, {'currentCount': newCount});
        }
      });
    } catch (e) {
      AppLogger.error('Error updating weekly goal progress: $e');
    }
  }

  /// Save weekly goal to Firestore
  Future<void> _saveWeeklyGoal(WeeklyGoalModel goal, String weekKey) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyGoals')
          .doc('${weekKey}_${goal.id}')
          .set(goal.toMap());
    } catch (e) {
      AppLogger.error('Error saving weekly goal: $e');
    }
  }

  /// Get weekly goal statistics
  Future<Map<String, dynamic>> getWeeklyGoalStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final allGoals = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('weeklyGoals')
          .get();

      final completedGoals = allGoals.docs.where(
        (doc) => doc.data()['isCompleted'] == true,
      );

      final totalGoals = allGoals.docs.length;
      final completedCount = completedGoals.length;
      final completionRate = totalGoals > 0
          ? (completedCount / totalGoals * 100).round()
          : 0;

      // Calculate total XP earned from weekly goals
      final totalXPEarned = completedGoals.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['rewardXP'] as int? ?? 0),
      );

      return {
        'totalGoals': totalGoals,
        'completedGoals': completedCount,
        'completionRate': completionRate,
        'totalXPEarned': totalXPEarned,
      };
    } catch (e) {
      AppLogger.error('Error getting weekly goal stats: $e');
      return {};
    }
  }

  /// Get week number (ISO 8601 week date)
  int _getWeekNumber(DateTime date) {
    final dayOfYear = int.parse(
      date.difference(DateTime(date.year, 1, 1)).inDays.toString(),
    );
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Get week key for Firestore document ID (format: YYYY-Www)
  String _getWeekKey(DateTime date) {
    final weekNumber = _getWeekNumber(date);
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Get start of week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final daysToSubtract = date.weekday - 1;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  /// Track daily quest completion for weekly mastery goals
  Future<void> trackDailyQuestCompletion() async {
    final goals = await getCurrentWeekGoals();
    for (final goal in goals) {
      if (goal.category == WeeklyGoalCategory.mastery &&
          goal.title == 'Quest Master') {
        await updateWeeklyGoalProgress(goal.id, 1);
      }
    }
  }

  /// Track streak maintenance for weekly mastery goals
  Future<void> trackStreakDay() async {
    final goals = await getCurrentWeekGoals();
    for (final goal in goals) {
      if (goal.category == WeeklyGoalCategory.mastery &&
          goal.title == 'Streak Keeper') {
        await updateWeeklyGoalProgress(goal.id, 1);
      }
    }
  }
}
