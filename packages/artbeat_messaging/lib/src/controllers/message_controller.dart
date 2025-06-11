import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class MessageController extends ChangeNotifier {
  final ChatService _chatService;
  final String chatId;
  Stream<List<MessageModel>>? _messagesStream;

  MessageController(this._chatService, this.chatId) {
    _messagesStream = _chatService.getMessagesStream(chatId);
  }

  Stream<List<MessageModel>>? get messagesStream => _messagesStream;

  Future<void> sendTextMessage(String text) async {
    try {
      await _chatService.sendMessage(chatId, text);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> sendImage(String imagePath) async {
    try {
      await _chatService.sendImage(chatId, imagePath);
    } catch (e) {
      debugPrint('Error sending image: $e');
      rethrow;
    }
  }

  void updateTypingStatus(String userId, bool isTyping) {
    try {
      _chatService.updateTypingStatus(chatId, userId, isTyping);
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }
}
