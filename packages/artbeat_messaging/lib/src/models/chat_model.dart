import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_model.dart';

class ChatModel {
  final String id;
  final List<String> participantIds;
  final MessageModel? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isGroup;
  final String? groupName;
  final String? groupImage;
  final Map<String, int> unreadCounts;
  final String creatorId;

  ChatModel({
    required this.id,
    required this.participantIds,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    this.isGroup = false,
    this.groupName,
    this.groupImage,
    required this.unreadCounts,
    required this.creatorId,
  });

  int get unreadCount =>
      unreadCounts[FirebaseAuth.instance.currentUser?.uid ?? ''] ?? 0;

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      participantIds:
          (data['participantIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
      unreadCounts:
          (data['unreadCounts'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          {},
      creatorId: data['creatorId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'lastMessage': lastMessage?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImage': groupImage,
      'unreadCounts': unreadCounts,
      'creatorId': creatorId,
    };
  }
}
