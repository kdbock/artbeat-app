import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/message_reaction_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service for handling message reactions
class MessageReactionService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MessageReactionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String get currentUserId {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return userId;
  }

  /// Add or update a reaction to a message
  Future<void> addReaction({
    required String messageId,
    required String chatId,
    required String reactionType,
    String? customEmoji,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final emoji = customEmoji ?? ReactionTypes.getEmoji(reactionType);

      final reaction = MessageReactionModel.create(
        messageId: messageId,
        chatId: chatId,
        userId: user.uid,
        userName: user.displayName ?? 'Unknown User',
        userAvatar: user.photoURL ?? '',
        reactionType: reactionType,
        emoji: emoji,
      );

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .doc(reaction.id)
          .set(reaction.toMap());

      // Update reaction count on the message
      await _updateMessageReactionCount(chatId, messageId);

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error adding reaction: $e');
      rethrow;
    }
  }

  /// Remove a reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String chatId,
    required String reactionType,
  }) async {
    try {
      final userId = currentUserId;
      final reactionId = '${messageId}_${userId}_$reactionType';

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .doc(reactionId)
          .delete();

      // Update reaction count on the message
      await _updateMessageReactionCount(chatId, messageId);

      notifyListeners();
    } catch (e) {
      AppLogger.error('Error removing reaction: $e');
      rethrow;
    }
  }

  /// Toggle a reaction (add if not exists, remove if exists)
  Future<void> toggleReaction({
    required String messageId,
    required String chatId,
    required String reactionType,
    String? customEmoji,
  }) async {
    try {
      final hasReaction = await hasUserReacted(
        messageId: messageId,
        chatId: chatId,
        reactionType: reactionType,
      );

      if (hasReaction) {
        await removeReaction(
          messageId: messageId,
          chatId: chatId,
          reactionType: reactionType,
        );
      } else {
        await addReaction(
          messageId: messageId,
          chatId: chatId,
          reactionType: reactionType,
          customEmoji: customEmoji,
        );
      }
    } catch (e) {
      AppLogger.error('Error toggling reaction: $e');
      rethrow;
    }
  }

  /// Check if current user has reacted to a message with a specific reaction type
  Future<bool> hasUserReacted({
    required String messageId,
    required String chatId,
    required String reactionType,
  }) async {
    try {
      final userId = currentUserId;
      final reactionId = '${messageId}_${userId}_$reactionType';

      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .doc(reactionId)
          .get();

      return doc.exists;
    } catch (e) {
      AppLogger.error('Error checking user reaction: $e');
      return false;
    }
  }

  /// Get all reactions for a message
  Future<List<MessageReactionModel>> getMessageReactions({
    required String messageId,
    required String chatId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => MessageReactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      AppLogger.error('Error getting message reactions: $e');
      return [];
    }
  }

  /// Get reactions summary for a message
  Future<MessageReactionsSummary> getMessageReactionsSummary({
    required String messageId,
    required String chatId,
  }) async {
    try {
      final reactions = await getMessageReactions(
        messageId: messageId,
        chatId: chatId,
      );

      return MessageReactionsSummary.fromReactions(messageId, reactions);
    } catch (e) {
      AppLogger.error('Error getting reactions summary: $e');
      return MessageReactionsSummary.fromReactions(messageId, []);
    }
  }

  /// Stream reactions for a message in real-time
  Stream<List<MessageReactionModel>> streamMessageReactions({
    required String messageId,
    required String chatId,
  }) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .collection('reactions')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageReactionModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Stream reactions summary for a message in real-time
  Stream<MessageReactionsSummary> streamMessageReactionsSummary({
    required String messageId,
    required String chatId,
  }) {
    return streamMessageReactions(messageId: messageId, chatId: chatId).map(
      (reactions) =>
          MessageReactionsSummary.fromReactions(messageId, reactions),
    );
  }

  /// Get reactions by a specific user
  Future<List<MessageReactionModel>> getUserReactions({
    required String userId,
    required String chatId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final allReactions = <MessageReactionModel>[];

      for (final messageDoc in snapshot.docs) {
        final reactionsSnapshot = await messageDoc.reference
            .collection('reactions')
            .where('userId', isEqualTo: userId)
            .get();

        for (final reactionDoc in reactionsSnapshot.docs) {
          allReactions.add(MessageReactionModel.fromFirestore(reactionDoc));
        }
      }

      // Sort by creation date and limit results
      allReactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allReactions.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting user reactions: $e');
      return [];
    }
  }

  /// Get most popular reactions across all messages in a chat
  Future<Map<String, int>> getChatReactionStats(String chatId) async {
    try {
      final snapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final reactionCounts = <String, int>{};

      for (final messageDoc in snapshot.docs) {
        final reactionsSnapshot = await messageDoc.reference
            .collection('reactions')
            .get();

        for (final reactionDoc in reactionsSnapshot.docs) {
          final reaction = MessageReactionModel.fromFirestore(reactionDoc);
          reactionCounts[reaction.reactionType] =
              (reactionCounts[reaction.reactionType] ?? 0) + 1;
        }
      }

      return reactionCounts;
    } catch (e) {
      AppLogger.error('Error getting chat reaction stats: $e');
      return {};
    }
  }

  /// Remove all reactions from a message (used when deleting messages)
  Future<void> removeAllReactionsFromMessage({
    required String messageId,
    required String chatId,
  }) async {
    try {
      final reactionsSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .get();

      final batch = _firestore.batch();
      for (final doc in reactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('Error removing all reactions from message: $e');
      rethrow;
    }
  }

  /// Update the reaction count field on the message document
  Future<void> _updateMessageReactionCount(
    String chatId,
    String messageId,
  ) async {
    try {
      final reactionsSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .collection('reactions')
          .get();

      final reactionCount = reactionsSnapshot.size;

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'reactionCount': reactionCount});
    } catch (e) {
      AppLogger.error('Error updating message reaction count: $e');
      // Don't rethrow as this is not critical
    }
  }

  /// Get available reaction types for quick selection
  List<String> getQuickReactionTypes() {
    return [
      ReactionTypes.thumbsUp,
      ReactionTypes.heart,
      ReactionTypes.laugh,
      ReactionTypes.surprise,
      ReactionTypes.sad,
      ReactionTypes.angry,
    ];
  }

  /// Get emoji for quick reactions
  Map<String, String> getQuickReactionEmojis() {
    final quickTypes = getQuickReactionTypes();
    return Map.fromEntries(
      quickTypes.map((type) => MapEntry(type, ReactionTypes.getEmoji(type))),
    );
  }
}
