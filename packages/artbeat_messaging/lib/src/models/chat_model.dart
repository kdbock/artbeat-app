import 'package:cloud_firestore/cloud_firestore.dart';
import 'message_model.dart';
import 'user_model.dart';

class ChatModel {
  final String id;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isGroup;
  final String? groupName;
  final String? groupImage;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.isGroup = false,
    this.groupName,
    this.groupImage,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participants:
          (data['participants'] as List)
              .map((p) => UserModel.fromMap(p))
              .toList(),
      lastMessage:
          data['lastMessage'] != null
              ? MessageModel.fromMap(data['lastMessage'])
              : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupImage: data['groupImage'],
    );
  }
}
