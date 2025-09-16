import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatSettingsScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatSettingsScreen({super.key, required this.chat});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _mediaAutoDownload = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled =
          prefs.getBool('chat_notifications_enabled') ?? true;
      _mediaAutoDownload = prefs.getBool('chat_media_auto_download') ?? true;
    });
  }

  Future<void> _updateNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_notifications_enabled', value);
  }

  Future<void> _updateAutoDownloadSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_media_auto_download', value);
  }

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
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await _updateNotificationSetting(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Auto-download Media'),
            subtitle: const Text('Automatically download photos and videos'),
            trailing: Switch(
              value: _mediaAutoDownload,
              onChanged: (value) async {
                setState(() {
                  _mediaAutoDownload = value;
                });
                await _updateAutoDownloadSetting(value);
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
              final MenuController controller = MenuController();
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Theme'),
                  content: MenuAnchor(
                    controller: controller,
                    menuChildren: [
                      RadioMenuButton<String>(
                        value: 'system',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTheme = value;
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('System'),
                      ),
                      RadioMenuButton<String>(
                        value: 'light',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTheme = value;
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Light'),
                      ),
                      RadioMenuButton<String>(
                        value: 'dark',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTheme = value;
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Dark'),
                      ),
                    ],
                    child: const SizedBox.shrink(),
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
                builder: (context) => AlertDialog(
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
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          final chatService = Provider.of<ChatService>(
                            context,
                            listen: false,
                          );
                          await chatService.clearChatHistory(widget.chat.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Chat history cleared'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to clear chat: $e'),
                              ),
                            );
                          }
                        }
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
              Navigator.pushNamed(context, '/messaging/blocked-users');
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
