import 'package:flutter/material.dart';

class GroupEditScreen extends StatefulWidget {
  final String chatId;
  const GroupEditScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends State<GroupEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  // TODO: Load and update group image and participants

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Group')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group Name'),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter group name'),
            ),
            const SizedBox(height: 24),
            const Text('Group Image (not implemented)'),
            const SizedBox(height: 24),
            const Text('Participants (not implemented)'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // TODO: Save group changes
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
