import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Service to integrate commission messages into main messaging inbox
class CommissionMessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a commission message in the main messaging system
  Future<void> createCommissionMessage({
    required String commissionId,
    required String recipientId,
    required String recipientName,
    required String message,
    required String senderName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be authenticated');

      final chatId = _createChatId(user.uid, recipientId);

      // Create chat if doesn't exist
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [user.uid, recipientId],
          'participantNames': {
            user.uid: senderName,
            recipientId: recipientName,
          },
          'type': 'commission_discussion',
          'commissionId': commissionId,
          'createdAt': Timestamp.now(),
          'lastMessageAt': Timestamp.now(),
          'lastMessage': message,
        });
      }

      // Add message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': user.uid,
            'senderName': senderName,
            'text': message,
            'content': message,
            'timestamp': Timestamp.now(),
            'type': 'text',
            'read': {recipientId: false},
            'isCommissionMessage': true,
            'commissionId': commissionId,
          });

      // Update last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': Timestamp.now(),
        'lastMessage': message,
      });
    } catch (e) {
      AppLogger.error('Failed to create commission message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get commission-related chat
  Future<DocumentSnapshot?> getCommissionChat(
    String userId,
    String otherUserId,
    String commissionId,
  ) async {
    try {
      final chatId = _createChatId(userId, otherUserId);
      final doc = await _firestore.collection('chats').doc(chatId).get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      if (data['commissionId'] != commissionId) return null;

      return doc;
    } catch (e) {
      AppLogger.error('Failed to get commission chat: $e');
      return null;
    }
  }

  /// Get all commission chats for user
  Future<List<DocumentSnapshot>> getCommissionChats(String userId) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .where('type', isEqualTo: 'commission_discussion')
          .orderBy('lastMessageAt', descending: true)
          .get();

      return query.docs;
    } catch (e) {
      AppLogger.error('Failed to get commission chats: $e');
      return [];
    }
  }

  /// Mark commission messages as read
  Future<void> markCommissionMessagesAsRead(
    String chatId,
    String userId,
  ) async {
    try {
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isCommissionMessage', isEqualTo: true)
          .get();

      final batch = _firestore.batch();

      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {'read.$userId': true});
      }

      await batch.commit();
    } catch (e) {
      AppLogger.error('Failed to mark messages as read: $e');
    }
  }

  /// Stream commission messages
  Stream<QuerySnapshot> streamCommissionMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isCommissionMessage', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get commission message count
  Future<int> getUnreadCommissionMessageCount(String userId) async {
    try {
      final chats = await getCommissionChats(userId);

      int totalUnread = 0;
      for (final chat in chats) {
        final data = chat.data() as Map<String, dynamic>;
        final participants = List<String>.from(
          (data['participants'] as List?) ?? [],
        );
        final otherUserId = participants.firstWhere(
          (p) => p != userId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          final messages = await _firestore
              .collection('chats')
              .doc(chat.id)
              .collection('messages')
              .where('isCommissionMessage', isEqualTo: true)
              .where('read.$userId', isEqualTo: false)
              .get();

          totalUnread += messages.docs.length;
        }
      }

      return totalUnread;
    } catch (e) {
      AppLogger.error('Failed to get unread count: $e');
      return 0;
    }
  }

  /// Create chat ID from user IDs
  String _createChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Get or create commission discussion thread
  Future<String> getOrCreateCommissionThread({
    required String commissionId,
    required String userId1,
    required String user1Name,
    required String userId2,
    required String user2Name,
  }) async {
    try {
      final chatId = _createChatId(userId1, userId2);

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [userId1, userId2],
          'participantNames': {userId1: user1Name, userId2: user2Name},
          'type': 'commission_discussion',
          'commissionId': commissionId,
          'createdAt': Timestamp.now(),
          'lastMessageAt': Timestamp.now(),
          'lastMessage': 'Commission discussion started',
        });
      }

      return chatId;
    } catch (e) {
      throw Exception('Failed to create commission thread: $e');
    }
  }
}
