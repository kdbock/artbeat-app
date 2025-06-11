import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../utils/message_converter.dart';
import 'media_viewer_screen.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;

  String get _chatName =>
      widget.chat.isGroup
          ? widget.chat.groupName ?? 'Group Chat'
          : widget.chat.participants
              .firstWhere(
                (p) => p.id != context.read<ChatService>().currentUserId,
              )
              .displayName;

  @override
  void initState() {
    super.initState();
    _setupTypingListener();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _clearTypingStatus();
    super.dispose();
  }

  void _setupTypingListener() {
    _messageController.addListener(() {
      final isCurrentlyTyping = _messageController.text.isNotEmpty;
      if (isCurrentlyTyping != _isTyping) {
        setState(() => _isTyping = isCurrentlyTyping);
        _updateTypingStatus(isCurrentlyTyping);
      }
    });
  }

  void _clearTypingStatus() {
    if (_isTyping) {
      _updateTypingStatus(false);
    }
  }

  void _updateTypingStatus(bool isTyping) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final userId = chatService.currentUserId;
    chatService.updateTypingStatus(widget.chat.id, userId, isTyping);
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    try {
      await chatService.sendMessage(widget.chat.id, text);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleImagePick() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    try {
      await chatService.sendImage(widget.chat.id, image.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image: ${e.toString()}')),
        );
      }
    }
  }

  void _handleImageTap(List<String> mediaUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => MediaViewerScreen(
              mediaUrls: mediaUrls,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_chatName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: Provider.of<ChatService>(
                context,
              ).getMessagesStream(widget.chat.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                final allImageUrls =
                    messages
                        .where((msg) => msg.type == MessageType.image)
                        .map((msg) => msg.content)
                        .toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageModel = messages[index];
                    final message = messageModel.toMessage(widget.chat.id);
                    final isCurrentUser =
                        messageModel.senderId ==
                        context.read<ChatService>().currentUserId;

                    return MessageBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      onImageTap:
                          message.imageUrl != null
                              ? () {
                                final imageIndex = allImageUrls.indexOf(
                                  message.imageUrl!,
                                );
                                _handleImageTap(allImageUrls, imageIndex);
                              }
                              : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _handleImagePick,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _handleSendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
