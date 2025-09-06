import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/models.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettingsModel? _notificationSettings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load from service
      _notificationSettings = NotificationSettingsModel.defaultSettings(
        'current-user-id',
      );
    } catch (e) {
      _showErrorMessage('Failed to load notification settings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _updateSettings(NotificationSettingsModel settings) async {
    try {
      // TODO: Save to service
      setState(() => _notificationSettings = settings);
      _showSuccessMessage('Notification settings updated');
    } catch (e) {
      _showErrorMessage('Failed to update settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Notification Settings',
        showLogo: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildNotificationSettings(),
    );
  }

  Widget _buildNotificationSettings() {
    if (_notificationSettings == null)
      return const Center(child: Text('No settings available'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEmailSettings(),
        const SizedBox(height: 24),
        _buildPushSettings(),
        const SizedBox(height: 24),
        _buildInAppSettings(),
        const SizedBox(height: 24),
        _buildQuietHoursSettings(),
      ],
    );
  }

  Widget _buildEmailSettings() {
    final email = _notificationSettings!.email;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.email),
                const SizedBox(width: 8),
                Text(
                  'Email Notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: email.enabled,
              onChanged: (value) {
                final updated = _notificationSettings!.copyWith(
                  email: email.copyWith(enabled: value),
                );
                _updateSettings(updated);
              },
            ),
            if (email.enabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Frequency'),
                subtitle: Text('Currently: ${email.frequency}'),
                trailing: DropdownButton<String>(
                  value: email.frequency,
                  items: const [
                    DropdownMenuItem(
                      value: 'immediate',
                      child: Text('Immediate'),
                    ),
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text('Daily digest'),
                    ),
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('Weekly digest'),
                    ),
                    DropdownMenuItem(value: 'never', child: Text('Never')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      final updated = _notificationSettings!.copyWith(
                        email: email.copyWith(frequency: value),
                      );
                      _updateSettings(updated);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPushSettings() {
    final push = _notificationSettings!.push;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications),
                const SizedBox(width: 8),
                Text(
                  'Push Notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Push Notifications'),
              subtitle: const Text('Receive notifications on your device'),
              value: push.enabled,
              onChanged: (value) {
                final updated = _notificationSettings!.copyWith(
                  push: push.copyWith(enabled: value),
                );
                _updateSettings(updated);
              },
            ),
            if (push.enabled) ...[
              const Divider(),
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play sound for notifications'),
                value: push.allowSounds,
                onChanged: (value) {
                  final updated = _notificationSettings!.copyWith(
                    push: push.copyWith(allowSounds: value),
                  );
                  _updateSettings(updated);
                },
              ),
              SwitchListTile(
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate for notifications'),
                value: push.allowVibration,
                onChanged: (value) {
                  final updated = _notificationSettings!.copyWith(
                    push: push.copyWith(allowVibration: value),
                  );
                  _updateSettings(updated);
                },
              ),
              SwitchListTile(
                title: const Text('Badges'),
                subtitle: const Text('Show notification count on app icon'),
                value: push.allowBadges,
                onChanged: (value) {
                  final updated = _notificationSettings!.copyWith(
                    push: push.copyWith(allowBadges: value),
                  );
                  _updateSettings(updated);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInAppSettings() {
    final inApp = _notificationSettings!.inApp;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active),
                const SizedBox(width: 8),
                Text(
                  'In-App Notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable In-App Notifications'),
              subtitle: const Text('Show notifications while using the app'),
              value: inApp.enabled,
              onChanged: (value) {
                final updated = _notificationSettings!.copyWith(
                  inApp: inApp.copyWith(enabled: value),
                );
                _updateSettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursSettings() {
    final quietHours = _notificationSettings!.quietHours;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nightlight_round),
                const SizedBox(width: 8),
                Text(
                  'Quiet Hours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              subtitle: const Text(
                'Reduce notifications during specified hours',
              ),
              value: quietHours.enabled,
              onChanged: (value) {
                final updated = _notificationSettings!.copyWith(
                  quietHours: quietHours.copyWith(enabled: value),
                );
                _updateSettings(updated);
              },
            ),
            if (quietHours.enabled) ...[
              const Divider(),
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(quietHours.startTime),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, quietHours.startTime, true),
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(quietHours.endTime),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, quietHours.endTime, false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    String currentTime,
    bool isStartTime,
  ) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final timeString =
          '${selectedTime.hour.toString().padLeft(2, '0')}:'
          '${selectedTime.minute.toString().padLeft(2, '0')}';

      final quietHours = _notificationSettings!.quietHours;
      final updated = _notificationSettings!.copyWith(
        quietHours: isStartTime
            ? quietHours.copyWith(startTime: timeString)
            : quietHours.copyWith(endTime: timeString),
      );
      _updateSettings(updated);
    }
  }
}
