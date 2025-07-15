import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  ChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  String get currentUserId {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return userId;
  }

  Stream<List<ChatModel>> getChatStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.error(Exception('User not authenticated'));
    }

    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          try {
            final chats = <ChatModel>[];
            for (final doc in snapshot.docs) {
              try {
                final chat = ChatModel.fromFirestore(doc);
                chats.add(chat);
              } catch (e) {
                debugPrint('Error parsing chat document ${doc.id}: $e');
                // Skip malformed documents rather than breaking the entire stream
                continue;
              }
            }
            return chats;
          } catch (e) {
            debugPrint('Error processing chat stream: $e');
            rethrow;
          }
        })
        .handleError((Object error) {
          debugPrint('Chat stream error: $error');
          throw Exception('Failed to load chats: $error');
        });
  }

  Future<List<ChatModel>> getChats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final snapshot = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
  }

  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage(String chatId, String text) async {
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      content: text,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );
    return _sendMessage(chatId, message);
  }

  Future<void> sendImage(String chatId, String imagePath) async {
    final file = File(imagePath);
    final ref = _storage
        .ref()
        .child('chat_images')
        .child(chatId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(file);
    final imageUrl = await ref.getDownloadURL();

    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      content: imageUrl,
      timestamp: DateTime.now(),
      type: MessageType.image,
    );
    return _sendMessage(chatId, message);
  }

  Future<void> _sendMessage(String chatId, MessageModel message) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  Stream<List<MessageModel>> getMessageStream(String chatId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Stream<Map<String, bool>> getTypingStatus(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc('status')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return <String, bool>{};
          }

          final data = snapshot.data()!;
          return Map<String, bool>.from(data);
        });
  }

  Future<void> updateTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    try {
      final typingRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc('status');

      if (isTyping) {
        await typingRef.set({userId: true}, SetOptions(merge: true));
        // Start an auto-reset timer
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            final snapshot = await typingRef.get();
            final data = snapshot.data();
            if (data?[userId] == true) {
              await typingRef.update({userId: false});
            }
          } catch (e) {
            debugPrint('Error in auto-reset timer: $e');
          }
        });
      } else {
        await typingRef.update({userId: false});
      }
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  Future<void> clearTypingStatus(String chatId, String userId) async {
    try {
      final typingRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc('status');

      await typingRef.set({
        userId: FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error clearing typing status: $e');
    }
  }

  Future<String?> getUserDisplayName(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }
      final userData = userDoc.data();
      if (userData == null) {
        return null;
      }

      // Use the same fallback logic as UserModel.fromFirestore
      return userData['displayName'] as String? ??
          userData['fullName'] as String? ??
          userData['username'] as String?;
    } catch (e) {
      debugPrint('Error getting user display name: $e');
      return null;
    }
  }

  Future<String?> getUserPhotoUrl(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return null;
      }
      final userData = userDoc.data();
      if (userData == null) {
        return null;
      }

      // Use the same fallback logic as UserModel.fromFirestore
      return userData['photoUrl'] as String? ??
          userData['profileImageUrl'] as String?;
    } catch (e) {
      debugPrint('Error getting user photo URL: $e');
      return null;
    }
  }

  Future<List<ChatModel>> searchChats(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    query = query.toLowerCase();
    final chats = await getChats();
    final filteredChats = <ChatModel>[];

    for (final chat in chats) {
      if (chat.isGroup && chat.groupName != null) {
        if (chat.groupName!.toLowerCase().contains(query)) {
          filteredChats.add(chat);
        }
        continue;
      }

      // Search participant names
      for (final participantId in chat.participantIds.where(
        (id) => id != userId,
      )) {
        final name = await getUserDisplayName(participantId);
        if (name?.toLowerCase().contains(query) ?? false) {
          filteredChats.add(chat);
          break;
        }
      }
    }

    return filteredChats;
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    if (query.isEmpty) return [];

    query = query.toLowerCase().trim();
    try {
      // Since Firestore doesn't support full-text search, we'll use multiple queries
      // and combine the results
      final List<UserModel> allResults = [];
      final Set<String> seenIds = <String>{};

      // Search by fullName (case-insensitive prefix search)
      try {
        final fullNameQuery = await _firestore
            .collection('users')
            .orderBy('fullName')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(10)
            .get();

        for (final doc in fullNameQuery.docs) {
          if (!seenIds.contains(doc.id) && doc.id != userId) {
            final user = UserModel.fromFirestore(doc);
            allResults.add(user);
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        debugPrint('Error in fullName search: $e');
      }

      // Search by username (case-insensitive prefix search)
      try {
        final usernameQuery = await _firestore
            .collection('users')
            .orderBy('username')
            .startAt([query])
            .endAt(['$query\uf8ff'])
            .limit(10)
            .get();

        for (final doc in usernameQuery.docs) {
          if (!seenIds.contains(doc.id) && doc.id != userId) {
            final user = UserModel.fromFirestore(doc);
            allResults.add(user);
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        debugPrint('Error in username search: $e');
      }

      // Search by zipCode (exact match)
      try {
        final zipCodeQuery = await _firestore
            .collection('users')
            .where('zipCode', isEqualTo: query)
            .limit(10)
            .get();

        for (final doc in zipCodeQuery.docs) {
          if (!seenIds.contains(doc.id) && doc.id != userId) {
            final user = UserModel.fromFirestore(doc);
            allResults.add(user);
            seenIds.add(doc.id);
          }
        }
      } catch (e) {
        debugPrint('Error in zipCode search: $e');
      }

      // If we still don't have many results, do a broader search
      if (allResults.length < 5) {
        try {
          // Get all users and do client-side filtering (not ideal for large datasets)
          final allUsersQuery = await _firestore
              .collection('users')
              .limit(100) // Limit to prevent too much data transfer
              .get();

          for (final doc in allUsersQuery.docs) {
            if (!seenIds.contains(doc.id) && doc.id != userId) {
              final data = doc.data();
              final fullName = (data['fullName'] as String? ?? '')
                  .toLowerCase();
              final username = (data['username'] as String? ?? '')
                  .toLowerCase();
              final location = (data['location'] as String? ?? '')
                  .toLowerCase();

              // Check if query matches any part of the name or location
              if (fullName.contains(query) ||
                  username.contains(query) ||
                  location.contains(query)) {
                final user = UserModel.fromFirestore(doc);
                allResults.add(user);
                seenIds.add(doc.id);

                if (allResults.length >= 20) break; // Limit results
              }
            }
          }
        } catch (e) {
          debugPrint('Error in broad search: $e');
        }
      }

      return allResults;
    } catch (e) {
      debugPrint('Error searching users: $e');
      throw Exception('Failed to search users');
    }
  }

  Future<ChatModel> createOrGetChat(String otherUserId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if chat already exists
      final existingChatQuery = await _firestore
          .collection('chats')
          .where('participantIds', arrayContainsAny: [userId])
          .where('isGroup', isEqualTo: false)
          .get();

      for (final doc in existingChatQuery.docs) {
        final participantIds = (doc.data()['participantIds'] as List)
            .cast<String>();
        if (participantIds.contains(otherUserId) &&
            participantIds.length == 2) {
          return ChatModel.fromFirestore(doc);
        }
      }

      // No existing chat found, create new one
      final otherUser = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();

      if (!otherUser.exists) {
        throw Exception('Other user not found');
      }

      final currentUser = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!currentUser.exists) {
        throw Exception('Current user not found');
      }

      final chatDoc = await _firestore.collection('chats').add({
        'participantIds': [userId, otherUserId],
        'participants': [currentUser.data(), otherUser.data()],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isGroup': false,
      });

      final newChat = await chatDoc.get();
      return ChatModel.fromFirestore(newChat);
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      throw Exception('Failed to create or get chat');
    }
  }

  Future<ChatModel> createGroupChat({
    required String groupName,
    required List<String> participantIds,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    // Add current user to participants if not already included
    if (!participantIds.contains(userId)) {
      participantIds.add(userId);
    }

    try {
      // Get all participant user documents
      final participantDocs = await Future.wait(
        participantIds.map(
          (id) => _firestore.collection('users').doc(id).get(),
        ),
      );

      // Verify all users exist
      if (participantDocs.any((doc) => !doc.exists)) {
        throw Exception('One or more users not found');
      }

      // Create new group chat
      final chatDoc = await _firestore.collection('chats').add({
        'participantIds': participantIds,
        'participants': participantDocs.map((doc) => doc.data()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isGroup': true,
        'groupName': groupName,
      });

      final newChat = await chatDoc.get();
      return ChatModel.fromFirestore(newChat);
    } catch (e) {
      debugPrint('Error creating group chat: $e');
      throw Exception('Failed to create group chat');
    }
  }

  /// Refreshes the chat list by clearing any cached data and triggering a reload
  Future<void> refresh() async {
    try {
      // Force a refresh by notifying listeners
      notifyListeners();

      // You can also add any cache clearing logic here if needed
      debugPrint('Chat service refreshed');
    } catch (e) {
      debugPrint('Error refreshing chat service: $e');
    }
  }

  /// Marks a chat as read for the current user
  Future<void> markChatAsRead(String chatId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('messageStats')
        .doc('chatStats')
        .collection('unreadCounts')
        .doc(chatId)
        .set({'count': 0}, SetOptions(merge: true));
  }

  /// Gets a stream of typing status updates for a chat
  Stream<Map<String, bool>> getTypingStatusStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typingStatus')
        .snapshots()
        .map((snapshot) {
          final data = <String, dynamic>{};
          for (var doc in snapshot.docs) {
            data[doc.id] = doc.data()['isTyping'] ?? false;
          }
          return data.cast<String, bool>();
        });
  }

  /// Gets a user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Gets a chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      if (!doc.exists) return null;
      return ChatModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting chat: $e');
      return null;
    }
  }

  /// Gets blocked users for current user
  Future<List<UserModel>> getBlockedUsers() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('blockedUsers')
          .get();

      final blockedUsers = <UserModel>[];
      for (final doc in snapshot.docs) {
        final blockedUserId = doc.id;
        final userData = doc.data();

        // Get full user data from users collection
        final userDoc = await _firestore
            .collection('users')
            .doc(blockedUserId)
            .get();

        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc);
          // Add blocked date from the blockedUsers collection
          user.blockedAt = (userData['blockedAt'] as Timestamp?)?.toDate();
          blockedUsers.add(user);
        }
      }

      return blockedUsers;
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  /// Blocks a user
  Future<void> blockUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .set({'blockedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error blocking user: $e');
      throw Exception('Failed to block user');
    }
  }

  /// Unblocks a user
  Future<void> unblockUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .delete();
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      throw Exception('Failed to unblock user');
    }
  }

  /// Checks if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Refresh participant data for a chat
  Future<void> refreshChatParticipants(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data() as Map<String, dynamic>;
      final participantIds =
          (chatData['participantIds'] as List?)?.cast<String>() ?? [];

      if (participantIds.isEmpty) return;

      // Fetch fresh participant data
      final participantDocs = await Future.wait(
        participantIds.map(
          (id) => _firestore.collection('users').doc(id).get(),
        ),
      );

      final participants = participantDocs
          .where((doc) => doc.exists)
          .map((doc) => doc.data())
          .where((data) => data != null)
          .toList();

      // Update the chat document with fresh participant data
      await _firestore.collection('chats').doc(chatId).update({
        'participants': participants,
      });

      debugPrint('Refreshed participant data for chat $chatId');
    } catch (e) {
      debugPrint('Error refreshing chat participants: $e');
    }
  }
}
