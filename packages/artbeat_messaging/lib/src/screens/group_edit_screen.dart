import 'package:flutter/material.dart';

class GroupEditScreen extends StatefulWidget {
  final String chatId;
  const GroupEditScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  // Artist posts can be edited directly through their own artist feed interface

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Artist Feed')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Feed Name'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter feed name'),
            ),
            const SizedBox(height: 24),
            const Text('Feed Image (Coming soon)'),
            const SizedBox(height: 24),
            const Text('Posts Management (Coming soon)'),
            const SizedBox(height: 16),
            const Text(
              'Use your artist dashboard to manage individual posts.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Simple save - just pop the screen for now
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feed settings saved!')),
                );
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
