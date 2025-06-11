import 'package:flutter/foundation.dart';
import '../services/chat_service.dart';

class TypingIndicatorController extends ChangeNotifier {
  final ChatService _chatService;
  final String chatId;
  final String userId;
  bool _isTyping = false;
  Map<String, bool> _typingUsers = {};

  TypingIndicatorController(this._chatService, this.chatId, this.userId) {
    _listenToTypingStatus();
  }

  bool get isTyping => _isTyping;
  Map<String, bool> get typingUsers => _typingUsers;

  void _listenToTypingStatus() {
    _chatService.getTypingStatus(chatId).listen((typingStatus) {
      _typingUsers = Map<String, bool>.from(typingStatus)
        ..removeWhere((key, _) => key == userId);
      notifyListeners();
    });
  }

  void setTypingStatus(bool isTyping) {
    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      _chatService.updateTypingStatus(chatId, userId, isTyping);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    setTypingStatus(false);
    super.dispose();
  }
}
