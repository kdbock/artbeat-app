import '../models/message.dart';
import '../models/message_model.dart';

// Create MessageConverter utility for converting between models
class MessageConverter {
  static Message fromMessageModel(MessageModel messageModel, String chatId) {
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
    );
  }
}

// Extension to add toMessage method to MessageModel
extension MessageModelExtension on MessageModel {
  Message toMessage(String chatId) {
    return MessageConverter.fromMessageModel(this, chatId);
  }
}
