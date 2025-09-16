import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService;
  List<ChatModel> _chats = [];
  bool _isLoading = false;

  ChatController(this._chatService);

  List<ChatModel> get chats => _chats;
  bool get isLoading => _isLoading;
  String get currentUserId => _chatService.currentUserId;

  Future<void> loadChats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _chats = await _chatService.getChats();
    } catch (e) {
      AppLogger.error('Error loading chats: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String chatId, String text) async {
    try {
      await _chatService.sendMessage(chatId, text);
      await loadChats(); // Refresh chat list
    } catch (e) {
      AppLogger.error('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> sendImage(String chatId, String imagePath) async {
    try {
      await _chatService.sendImage(chatId, imagePath);
      await loadChats(); // Refresh chat list
    } catch (e) {
      AppLogger.error('Error sending image: $e');
      rethrow;
    }
  }

  Stream<List<MessageModel>>? getMessagesStream(String chatId) {
    return _chatService.getMessagesStream(chatId);
  }

  void updateTypingStatus(String chatId, bool isTyping) {
    try {
      _chatService.updateTypingStatus(chatId, currentUserId, isTyping);
    } catch (e) {
      AppLogger.error('Error updating typing status: $e');
    }
  }
}
