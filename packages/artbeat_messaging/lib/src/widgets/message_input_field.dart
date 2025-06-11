import 'package:flutter/material.dart';
import '../theme/chat_theme.dart';
import '../controllers/typing_indicator_controller.dart';

class MessageInputField extends StatefulWidget {
  final Function(String) onSend;
  final TypingIndicatorController? typingController;

  const MessageInputField({
    super.key,
    required this.onSend,
    this.typingController,
  });

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isComposing = _controller.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() => _isComposing = isComposing);
      widget.typingController?.setTypingStatus(isComposing);
    }
  }

  void _handleSubmitted(String text) {
    widget.onSend(text);
    _controller.clear();
    widget.typingController?.setTypingStatus(false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: ChatTheme.messageInputDecoration,
              onSubmitted: _isComposing ? _handleSubmitted : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed:
                _isComposing ? () => _handleSubmitted(_controller.text) : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
