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
    
    // Convert participants data to UserModel list
    List<UserModel> participantsList = [];
    if (data['participants'] != null) {
      final participantsData = data['participants'] as List<dynamic>;
      participantsList = participantsData.map((p) {
        final participantMap = p as Map<String, dynamic>;
        return UserModel.fromMap(participantMap);
      }).toList();
    }

    return ChatModel(
      id: doc.id,
      participants: participantsList,
      lastMessage: data['lastMessage'] != null
          ? MessageModel.fromMap(data['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isGroup: data['isGroup'] as bool? ?? false,
      groupName: data['groupName'] as String?,
      groupImage: data['groupImage'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants.map((p) => p.toMap()).toList(),
      'lastMessage': lastMessage?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImage': groupImage,
    };
  }
}