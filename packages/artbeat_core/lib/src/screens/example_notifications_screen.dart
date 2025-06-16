import 'package:flutter/material.dart';

class ExampleNotificationsScreen extends StatelessWidget {
  const ExampleNotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Notifications'),
      ),
      body: const Center(
        child: Text('This is a placeholder for Core Notifications Screen'),
      ),
    );
  }
}
