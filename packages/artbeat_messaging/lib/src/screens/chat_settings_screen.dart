import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({super.key});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _mediaAutoDownload = true;
  String _selectedTheme = 'system';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Chat Settings',
        showLogo: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Chat Notifications'),
            subtitle: const Text('Get notified about new messages'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                // TODO: Implement notification settings update
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Auto-download Media'),
            subtitle: const Text('Automatically download photos and videos'),
            trailing: Switch(
              value: _mediaAutoDownload,
              onChanged: (value) {
                setState(() {
                  _mediaAutoDownload = value;
                });
                // TODO: Implement auto-download settings update
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Chat Theme'),
            subtitle: Text(
              _selectedTheme.substring(0, 1).toUpperCase() +
                  _selectedTheme.substring(1),
            ),
            onTap: () {
              showDialog<void>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Select Theme'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            title: const Text('System'),
                            value: 'system',
                            groupValue: _selectedTheme,
                            onChanged: (value) {
                              setState(() {
                                _selectedTheme = value!;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Light'),
                            value: 'light',
                            groupValue: _selectedTheme,
                            onChanged: (value) {
                              setState(() {
                                _selectedTheme = value!;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          RadioListTile<String>(
                            title: const Text('Dark'),
                            value: 'dark',
                            groupValue: _selectedTheme,
                            onChanged: (value) {
                              setState(() {
                                _selectedTheme = value!;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Chat History'),
            onTap: () {
              showDialog<void>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Clear Chat History'),
                      content: const Text(
                        'Are you sure you want to clear all chat history? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Implement clear chat history
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chat history cleared'),
                              ),
                            );
                          },
                          child: Text(
                            'Clear',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Users'),
            onTap: () {
              // TODO: Navigate to blocked users screen
            },
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Changes to these settings will apply to all your chats.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
