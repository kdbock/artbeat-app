import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApplauseButton extends StatefulWidget {
  final String postId;
  final String userId;

  const ApplauseButton({
    super.key,
    required this.postId,
    required this.userId,
  });

  @override
  _ApplauseButtonState createState() => _ApplauseButtonState();
}

class _ApplauseButtonState extends State<ApplauseButton> {
  int applauseCount = 0;

  void sendApplause() async {
    if (applauseCount < 5) {
      setState(() {
        applauseCount++;
      });

      await FirebaseFirestore.instance.collection('applause').add({
        'postId': widget.postId,
        'userId': widget.userId,
        'count': applauseCount,
        'timestamp': Timestamp.now(),
      });

      if (applauseCount == 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for showing support!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.favorite, color: Colors.red),
      onPressed: sendApplause,
    );
  }
}
