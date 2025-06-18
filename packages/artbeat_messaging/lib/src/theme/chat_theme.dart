import 'package:flutter/material.dart';

class ChatTheme {
  static const Color primaryColor = Color(0xFF6200EE);
  static const Color currentUserBubbleColor = Color(0xFF007AFF);
  static const Color otherUserBubbleColor = Color(0xFFE5E5EA);
  static const Color backgroundColor = Color(0xFFF2F2F7);

  static const TextStyle currentUserTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
  );

  static const TextStyle otherUserTextStyle = TextStyle(
    color: Colors.black87,
    fontSize: 16,
  );

  static const TextStyle timestampStyle = TextStyle(
    color: Colors.grey,
    fontSize: 12,
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
