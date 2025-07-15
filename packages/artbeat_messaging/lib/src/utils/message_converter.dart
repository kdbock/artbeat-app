import '../models/message.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

// Create MessageConverter utility for converting between models
class MessageConverter {
  static Message fromMessageModel(
    MessageModel messageModel,
    String chatId, {
    ChatModel? chat,
    ChatService? chatService,
  }) {
    // Try to get sender information from chat participants first
    String? senderName;
    String? senderPhotoUrl;

    if (chat != null) {
      senderName = chat.getParticipantDisplayName(messageModel.senderId);
      senderPhotoUrl = chat.getParticipantPhotoUrl(messageModel.senderId);

      // If we got "Unknown User" from participants, try to get fresh data from ChatService
      if (senderName == 'Unknown User' && chatService != null) {
        senderName = null; // Reset so we can try to get fresh data
        senderPhotoUrl = null;
      }
    }

    return Message(
      id: messageModel.id,
      chatId: chatId,
      senderId: messageModel.senderId,
      text: messageModel.type == MessageType.text ? messageModel.content : null,
      imageUrl: messageModel.type == MessageType.image
          ? messageModel.content
          : null,
      timestamp: messageModel.timestamp,
      isRead: messageModel.isRead,
      replyToId: messageModel.replyToId,
      metadata: messageModel.metadata,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
    );
  }

  static Future<Message> fromMessageModelAsync(
    MessageModel messageModel,
    String chatId, {
    ChatModel? chat,
    ChatService? chatService,
  }) async {
    // Try to get sender information from chat participants first
    String? senderName;
    String? senderPhotoUrl;

    if (chat != null) {
      senderName = chat.getParticipantDisplayName(messageModel.senderId);
      senderPhotoUrl = chat.getParticipantPhotoUrl(messageModel.senderId);
    }

    // If we didn't get user info from participants or got "Unknown User", fetch from ChatService
    if (chatService != null &&
        (senderName == null || senderName == 'Unknown User')) {
      senderName = await chatService.getUserDisplayName(messageModel.senderId);
      senderPhotoUrl = await chatService.getUserPhotoUrl(messageModel.senderId);
    }

    return Message(
      id: messageModel.id,
      chatId: chatId,
      senderId: messageModel.senderId,
      text: messageModel.type == MessageType.text ? messageModel.content : null,
      imageUrl: messageModel.type == MessageType.image
          ? messageModel.content
          : null,
      timestamp: messageModel.timestamp,
      isRead: messageModel.isRead,
      replyToId: messageModel.replyToId,
      metadata: messageModel.metadata,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
    );
  }
}

// Extension to add toMessage method to MessageModel
extension MessageModelExtension on MessageModel {
  Message toMessage(
    String chatId, {
    ChatModel? chat,
    ChatService? chatService,
  }) {
    return MessageConverter.fromMessageModel(
      this,
      chatId,
      chat: chat,
      chatService: chatService,
    );
  }

  Future<Message> toMessageAsync(
    String chatId, {
    ChatModel? chat,
    ChatService? chatService,
  }) {
    return MessageConverter.fromMessageModelAsync(
      this,
      chatId,
      chat: chat,
      chatService: chatService,
    );
  }
}
