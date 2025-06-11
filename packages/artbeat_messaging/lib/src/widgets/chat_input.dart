import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';

class ChatInputWidget extends StatefulWidget {
  final String chatId;
  final Function(String) onSendMessage;
  final Function(File) onSendImage;

  const ChatInputWidget({
    super.key,
    required this.chatId,
    required this.onSendMessage,
    required this.onSendImage,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final _textController = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    if (_isTyping) {
      final chatService = context.read<ChatService>();
      final userId = chatService.currentUserId;
      chatService.updateTypingStatus(widget.chatId, userId, false);
    }
    super.dispose();
  }

  void _onTextChanged() {
    final isCurrentlyTyping = _textController.text.isNotEmpty;
    if (isCurrentlyTyping != _isTyping) {
      setState(() => _isTyping = isCurrentlyTyping);
      final chatService = context.read<ChatService>();
      final userId = chatService.currentUserId;
      chatService.updateTypingStatus(widget.chatId, userId, isCurrentlyTyping);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      widget.onSendImage(File(pickedFile.path));
    }
  }

  void _handleSend() {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _handleSend),
          ],
        ),
      ),
    );
  }
}
