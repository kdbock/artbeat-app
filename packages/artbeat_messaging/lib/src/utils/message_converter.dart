import '../models/message.dart';
import '../models/message_model.dart';

extension MessageModelConverter on MessageModel {
  Message toMessage(String chatId) {
    return Message(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: type == MessageType.text ? content : null,
      imageUrl: type == MessageType.image ? content : null,
      timestamp: timestamp,
      isRead: isRead,
      metadata: {
        ...?metadata,
        if (replyToId != null) 'replyToId': replyToId,
        'type': type.toString(),
      },
    );
  }
}

extension MessageConverter on Message {
  MessageModel toMessageModel() {
    return MessageModel(
      id: id,
      senderId: senderId,
      content: text ?? imageUrl ?? '',
      timestamp: timestamp,
      type: imageUrl != null ? MessageType.image : MessageType.text,
      isRead: isRead,
      replyToId: metadata?['replyToId'] as String?,
      metadata: {
        ...?metadata,
        if (metadata?.containsKey('replyToId') != true) ...{},
      },
    );
  }
}
