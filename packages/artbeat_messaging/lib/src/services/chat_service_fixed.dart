import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class ChatService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;
  FirebaseStorage? _storageInstance;
  NotificationService? _notificationService;

  // Lazy initialization getters
  FirebaseFirestore get firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get auth => _authInstance ??= FirebaseAuth.instance;
  FirebaseStorage get storage => _storageInstance ??= FirebaseStorage.instance;
  NotificationService get notificationService =>
      _notificationService ??= NotificationService();

  ChatService._();
  static final ChatService _instance = ChatService._();
  static ChatService get instance => _instance;

  // Constructor for testing
  ChatService.forTesting({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
    NotificationService? notificationService,
  }) : _firestoreInstance = firestore,
       _authInstance = auth,
       _storageInstance = storage,
       _notificationService = notificationService;

  // Get chats for user
  Stream<List<ChatModel>> getChatsForUser(String userId) {
    if (kDebugMode) {
      print('Getting chats for user: $userId');
    }

    return firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((QuerySnapshot snapshot) async {
          final List<ChatModel> chats = [];
          for (var doc in snapshot.docs) {
            try {
              final chat = ChatModel.fromFirestore(doc);
              chats.add(chat);
            } catch (e) {
              if (kDebugMode) {
                print('Error processing chat document ${doc.id}: $e');
              }
            }
          }
          return chats;
        });
  }

  // Rest of the methods would follow the same pattern...
  // For brevity, I'll just include the method signatures and indicate the pattern

  Future<List<ChatModel>> getArchivedChats(String userId) async {
    final snapshot = await firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .where('archivedBy.$userId', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
  }

  Stream<List<MessageModel>> getMessagesForChat(String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((QuerySnapshot snapshot) {
          final List<MessageModel> messages = [];
          for (var doc in snapshot.docs) {
            try {
              final message = MessageModel.fromFirestore(doc);
              messages.add(message);
            } catch (e) {
              if (kDebugMode) {
                print('Error processing message: $e');
              }
            }
          }
          return messages;
        });
  }

  Future<String> uploadChatImage(File imageFile, String chatId) async {
    final ref = storage
        .ref()
        .child('chat_images')
        .child(chatId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String? imageUrl,
    String? replyToMessageId,
  }) async {
    await firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'replyToMessageId': replyToMessageId,
      'isRead': false,
      'reactions': <String, dynamic>{},
    });

    // Update last message info on chat document
    await firestore.collection('chats').doc(chatId).update({
      'lastMessage': content.isNotEmpty ? content : 'Image',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    });
  }

  // Add more methods following the same pattern...
  // The key is to use firestore, auth, and storage getters instead of _firestore, _auth, _storage
}
