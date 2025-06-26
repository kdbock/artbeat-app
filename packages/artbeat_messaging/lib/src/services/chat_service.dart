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
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList(),
        );
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
          return Map<String, bool>.fromEntries(
            data.entries.map((e) => MapEntry(e.key, e.value == true)),
          );
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

  Future<List<ChatModel>> searchChats(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    query = query.toLowerCase();
    final chats = await getChats();

    return chats.where((chat) {
      if (chat.isGroup && chat.groupName != null) {
        return chat.groupName!.toLowerCase().contains(query);
      }

      // Search participant names
      return chat.participants
          .where((p) => p.id != userId) // Exclude current user
          .any((p) => p.displayName.toLowerCase().contains(query));
    }).toList();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    query = query.toLowerCase();
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('searchTerms', arrayContains: query)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
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
}
