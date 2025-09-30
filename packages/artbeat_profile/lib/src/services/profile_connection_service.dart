import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_connection_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for managing profile connections, mutual friends, and friend suggestions
class ProfileConnectionService extends ChangeNotifier {
  static final ProfileConnectionService _instance =
      ProfileConnectionService._internal();
  factory ProfileConnectionService() => _instance;
  ProfileConnectionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _connectionsCollection =>
      _firestore.collection('profile_connections');

  CollectionReference get _followersCollection =>
      _firestore.collection('followers');

  /// Get mutual connections between two users
  Future<List<ProfileConnectionModel>> getMutualConnections(
    String userId1,
    String userId2,
  ) async {
    try {
      // Get followers of both users
      final [user1Followers, user2Followers] = await Future.wait([
        _getFollowerIds(userId1),
        _getFollowerIds(userId2),
      ]);

      // Find mutual followers
      final mutualFollowerIds = user1Followers
          .where((followerId) => user2Followers.contains(followerId))
          .toList();

      if (mutualFollowerIds.isEmpty) {
        return [];
      }

      // Get existing connection records for mutual followers
      final connectionQuery = await _connectionsCollection
          .where('userId', isEqualTo: userId1)
          .where('connectedUserId', whereIn: mutualFollowerIds)
          .get();

      final connections = connectionQuery.docs
          .map((doc) => ProfileConnectionModel.fromFirestore(doc))
          .toList();

      // Create connection models for mutual followers not yet in the connections collection
      final existingConnectedIds = connections
          .map((c) => c.connectedUserId)
          .toSet();
      final missingMutualIds = mutualFollowerIds
          .where((id) => !existingConnectedIds.contains(id))
          .toList();

      for (final mutualId in missingMutualIds) {
        try {
          // Get user info for the mutual connection
          final userDoc = await _firestore
              .collection('users')
              .doc(mutualId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;

            final connection = ProfileConnectionModel(
              id: '${userId1}_$mutualId',
              userId: userId1,
              connectedUserId: mutualId,
              connectedUserName:
                  (userData['displayName'] ??
                          userData['fullName'] ??
                          'Unknown User')
                      as String,
              connectedUserAvatar: userData['photoURL'] as String?,
              connectionType: 'mutual_follower',
              mutualFollowersCount:
                  mutualFollowerIds.length -
                  1, // Exclude the connected user themselves
              mutualFollowerIds: mutualFollowerIds
                  .where((id) => id != mutualId)
                  .toList(),
              connectionScore: _calculateMutualConnectionScore(
                mutualFollowerIds.length,
              ),
              connectionReason: {
                'type': 'mutual_followers',
                'count': mutualFollowerIds.length - 1,
                'message':
                    'You both follow each other and have ${mutualFollowerIds.length - 1} mutual connections',
              },
              createdAt: DateTime.now(),
            );

            connections.add(connection);
          }
        } catch (e) {
          AppLogger.error('Error creating connection model for $mutualId: $e');
        }
      }

      return connections;
    } catch (e) {
      AppLogger.error('Error getting mutual connections: $e');
      return [];
    }
  }

  /// Get friend suggestions for a user based on various factors
  Future<List<ProfileConnectionModel>> getFriendSuggestions(
    String userId,
  ) async {
    try {
      final suggestions = <ProfileConnectionModel>[];

      // Get user's current followers and following
      final [userFollowers, userFollowing] = await Future.wait([
        _getFollowerIds(userId),
        _getFollowingIds(userId),
      ]);

      // Get followers of people the user follows (friends of friends)
      final friendsOfFriends = await _getFriendsOfFriends(
        userId,
        userFollowing,
      );

      // Filter out users already connected
      final alreadyConnected = {...userFollowers, ...userFollowing, userId};
      final potentialConnections = friendsOfFriends
          .where((id) => !alreadyConnected.contains(id))
          .toList();

      // Get existing dismissed or blocked connections to exclude
      final existingConnections = await _connectionsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final dismissedOrBlockedIds = existingConnections.docs
          .map((doc) => ProfileConnectionModel.fromFirestore(doc))
          .where((connection) => connection.isDismissed || connection.isBlocked)
          .map((connection) => connection.connectedUserId)
          .toSet();

      final validConnections = potentialConnections
          .where((id) => !dismissedOrBlockedIds.contains(id))
          .take(20) // Limit suggestions
          .toList();

      // Create connection models for suggestions
      for (final connectionId in validConnections) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(connectionId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;

            // Calculate mutual followers with this suggested user
            final suggestedUserFollowers = await _getFollowerIds(connectionId);
            final mutualFollowerIds = userFollowers
                .where((id) => suggestedUserFollowers.contains(id))
                .toList();

            final connection = ProfileConnectionModel(
              id: '${userId}_$connectionId',
              userId: userId,
              connectedUserId: connectionId,
              connectedUserName:
                  (userData['displayName'] ??
                          userData['fullName'] ??
                          'Unknown User')
                      as String,
              connectedUserAvatar: userData['photoURL'] as String?,
              connectionType: 'suggestion',
              mutualFollowersCount: mutualFollowerIds.length,
              mutualFollowerIds: mutualFollowerIds,
              connectionScore: _calculateSuggestionScore(
                mutualFollowerIds.length,
                userData,
              ),
              connectionReason: _generateSuggestionReason(
                mutualFollowerIds.length,
                userData,
              ),
              createdAt: DateTime.now(),
            );

            suggestions.add(connection);
          }
        } catch (e) {
          AppLogger.error('Error creating suggestion for $connectionId: $e');
        }
      }

      // Sort suggestions by connection score
      suggestions.sort(
        (a, b) => b.connectionScore.compareTo(a.connectionScore),
      );

      return suggestions;
    } catch (e) {
      AppLogger.error('Error getting friend suggestions: $e');
      return [];
    }
  }

  /// Update connection score based on interactions and other factors
  Future<void> updateConnectionScore(
    String userId,
    String connectedUserId,
    double score,
  ) async {
    try {
      final connectionId = '${userId}_$connectedUserId';
      final docRef = _connectionsCollection.doc(connectionId);

      await docRef.update({
        'connectionScore': score,
        'lastInteraction': Timestamp.fromDate(DateTime.now()),
      });

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error updating connection score: $e');
    }
  }

  /// Generate friend recommendations using advanced algorithms
  Future<List<ProfileConnectionModel>> generateFriendRecommendations(
    String userId, {
    int limit = 10,
  }) async {
    try {
      // Get comprehensive user data for better recommendations
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data() as Map<String, dynamic>;

      // Get user's interests, location, etc. for matching
      final userInterests = List<String>.from(
        userData['interests'] as List<dynamic>? ?? <dynamic>[],
      );
      final userLocation = userData['location'] as String?;

      final recommendations = <ProfileConnectionModel>[];

      // Strategy 1: Users with similar interests
      if (userInterests.isNotEmpty) {
        final interestBasedUsers = await _findUsersByInterests(
          userInterests,
          userId,
        );
        recommendations.addAll(
          await _createConnectionModels(
            userId,
            interestBasedUsers,
            'shared_interests',
            userInterests,
          ),
        );
      }

      // Strategy 2: Users in the same location
      if (userLocation != null && userLocation.isNotEmpty) {
        final locationBasedUsers = await _findUsersByLocation(
          userLocation,
          userId,
        );
        recommendations.addAll(
          await _createConnectionModels(
            userId,
            locationBasedUsers,
            'same_location',
            [userLocation],
          ),
        );
      }

      // Strategy 3: Users with mutual friends (if not already covered)
      final mutualFriendsUsers = await _findUsersByMutualFriends(userId);
      recommendations.addAll(
        await _createConnectionModels(
          userId,
          mutualFriendsUsers,
          'mutual_friends',
          [],
        ),
      );

      // Remove duplicates and sort by score
      final uniqueRecommendations = <String, ProfileConnectionModel>{};
      for (final rec in recommendations) {
        final existing = uniqueRecommendations[rec.connectedUserId];
        if (existing == null ||
            rec.connectionScore > existing.connectionScore) {
          uniqueRecommendations[rec.connectedUserId] = rec;
        }
      }

      final sortedRecommendations = uniqueRecommendations.values.toList()
        ..sort((a, b) => b.connectionScore.compareTo(a.connectionScore));

      return sortedRecommendations.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error generating friend recommendations: $e');
      return [];
    }
  }

  /// Dismiss a connection suggestion
  Future<void> dismissConnection(String userId, String connectedUserId) async {
    try {
      final connectionId = '${userId}_$connectedUserId';
      await _connectionsCollection.doc(connectionId).update({
        'isDismissed': true,
      });

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error dismissing connection: $e');
    }
  }

  /// Block a connection
  Future<void> blockConnection(String userId, String connectedUserId) async {
    try {
      final connectionId = '${userId}_$connectedUserId';
      await _connectionsCollection.doc(connectionId).update({
        'isBlocked': true,
      });

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error blocking connection: $e');
    }
  }

  /// Get connections for a user with filtering options
  Future<List<ProfileConnectionModel>> getConnections(
    String userId, {
    String? connectionType,
    bool includeDismissed = false,
    bool includeBlocked = false,
    int? limit,
  }) async {
    try {
      Query query = _connectionsCollection.where('userId', isEqualTo: userId);

      if (connectionType != null) {
        query = query.where('connectionType', isEqualTo: connectionType);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => ProfileConnectionModel.fromFirestore(doc))
          .where(
            (connection) =>
                (includeDismissed || !connection.isDismissed) &&
                (includeBlocked || !connection.isBlocked),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error getting connections: $e');
      return [];
    }
  }

  /// Stream connections for real-time updates
  Stream<List<ProfileConnectionModel>> streamConnections(
    String userId, {
    String? connectionType,
  }) {
    Query query = _connectionsCollection.where('userId', isEqualTo: userId);

    if (connectionType != null) {
      query = query.where('connectionType', isEqualTo: connectionType);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProfileConnectionModel.fromFirestore(doc))
          .toList();
    });
  }

  // Helper methods

  Future<List<String>> _getFollowerIds(String userId) async {
    final query = await _followersCollection
        .where('followingId', isEqualTo: userId)
        .get();
    return query.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .map((data) => data['followerId'] as String)
        .toList();
  }

  Future<List<String>> _getFollowingIds(String userId) async {
    final query = await _followersCollection
        .where('followerId', isEqualTo: userId)
        .get();
    return query.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .map((data) => data['followingId'] as String)
        .toList();
  }

  Future<List<String>> _getFriendsOfFriends(
    String userId,
    List<String> userFollowing,
  ) async {
    final friendsOfFriends = <String>{};

    for (final followingId in userFollowing.take(10)) {
      // Limit to prevent excessive queries
      try {
        final theirFollowing = await _getFollowingIds(followingId);
        friendsOfFriends.addAll(theirFollowing);
      } catch (e) {
        AppLogger.error(
          'Error getting friends of friends for $followingId: $e',
        );
      }
    }

    return friendsOfFriends.toList();
  }

  double _calculateMutualConnectionScore(int mutualCount) {
    // Score based on mutual connections (more mutual connections = higher score)
    return (mutualCount * 10.0).clamp(0.0, 100.0);
  }

  double _calculateSuggestionScore(
    int mutualCount,
    Map<String, dynamic> userData,
  ) {
    double score = 0.0;

    // Base score from mutual connections
    score += mutualCount * 8.0;

    // Bonus for complete profiles
    if (userData['displayName'] != null) score += 5.0;
    if (userData['photoURL'] != null) score += 5.0;
    if (userData['bio'] != null && (userData['bio'] as String).isNotEmpty)
      score += 5.0;

    // Bonus for recent activity (if available)
    if (userData['lastActive'] != null) {
      final lastActive = (userData['lastActive'] as Timestamp).toDate();
      final daysSinceActive = DateTime.now().difference(lastActive).inDays;
      if (daysSinceActive <= 7)
        score += 10.0;
      else if (daysSinceActive <= 30)
        score += 5.0;
    }

    return score.clamp(0.0, 100.0);
  }

  Map<String, dynamic> _generateSuggestionReason(
    int mutualCount,
    Map<String, dynamic> userData,
  ) {
    if (mutualCount > 0) {
      return {
        'type': 'mutual_connections',
        'count': mutualCount,
        'message':
            'You have $mutualCount mutual connection${mutualCount == 1 ? '' : 's'}',
      };
    }

    return {
      'type': 'algorithm',
      'message': 'Suggested based on your activity and interests',
    };
  }

  Future<List<String>> _findUsersByInterests(
    List<String> interests,
    String excludeUserId,
  ) async {
    try {
      final users = <String>{};

      // Query users with any of the same interests
      for (final interest in interests.take(5)) {
        // Limit queries
        final query = await _firestore
            .collection('users')
            .where('interests', arrayContains: interest)
            .limit(20)
            .get();

        for (final doc in query.docs) {
          if (doc.id != excludeUserId) {
            users.add(doc.id);
          }
        }
      }

      return users.toList();
    } catch (e) {
      AppLogger.error('Error finding users by interests: $e');
      return [];
    }
  }

  Future<List<String>> _findUsersByLocation(
    String location,
    String excludeUserId,
  ) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('location', isEqualTo: location)
          .limit(30)
          .get();

      return query.docs
          .where((doc) => doc.id != excludeUserId)
          .map((doc) => doc.id)
          .toList();
    } catch (e) {
      AppLogger.error('Error finding users by location: $e');
      return [];
    }
  }

  Future<List<String>> _findUsersByMutualFriends(String userId) async {
    try {
      final userFollowing = await _getFollowingIds(userId);
      return await _getFriendsOfFriends(userId, userFollowing);
    } catch (e) {
      AppLogger.error('Error finding users by mutual friends: $e');
      return [];
    }
  }

  Future<List<ProfileConnectionModel>> _createConnectionModels(
    String userId,
    List<String> connectedUserIds,
    String connectionType,
    List<String> matchingFactors,
  ) async {
    final connections = <ProfileConnectionModel>[];

    for (final connectedId in connectedUserIds.take(10)) {
      // Limit processing
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(connectedId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          final connection = ProfileConnectionModel(
            id: '${userId}_$connectedId',
            userId: userId,
            connectedUserId: connectedId,
            connectedUserName:
                (userData['displayName'] ??
                        userData['fullName'] ??
                        'Unknown User')
                    as String,
            connectedUserAvatar: userData['photoURL'] as String?,
            connectionType: connectionType,
            connectionScore: _calculateSuggestionScore(0, userData),
            connectionReason: {
              'type': connectionType,
              'factors': matchingFactors,
              'message': _getConnectionTypeMessage(
                connectionType,
                matchingFactors,
              ),
            },
            createdAt: DateTime.now(),
          );

          connections.add(connection);
        }
      } catch (e) {
        AppLogger.error('Error creating connection model for $connectedId: $e');
      }
    }

    return connections;
  }

  String _getConnectionTypeMessage(String type, List<String> factors) {
    switch (type) {
      case 'shared_interests':
        return 'You both are interested in ${factors.take(2).join(', ')}';
      case 'same_location':
        return 'You\'re both in ${factors.first}';
      case 'mutual_friends':
        return 'You have mutual friends';
      default:
        return 'Recommended for you';
    }
  }
}
