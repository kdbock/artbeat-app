import 'package:flutter/material.dart';

class ChatTheme {
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color currentUserBubbleColor = Color(0xFF6200EE);
  static const Color otherUserBubbleColor = Color(0xFFE8E8E8);

  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle timestampTextStyle = TextStyle(
    fontSize: 12,
    color: Colors.black54,
  );

  static InputDecoration messageInputDecoration = InputDecoration(
    hintText: 'Type a message...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: Colors.grey[100],
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  );
}
