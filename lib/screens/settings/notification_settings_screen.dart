import 'package:flutter/material.dart';
import 'package:artbeat/services/notification_service.dart';
import 'package:artbeat/services/user_service.dart';
import 'package:artbeat/services/subscription_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = false;
  bool _hasSubscription = false;

  // Services
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notification toggles
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _inAppNotifications = true;

  // Community category toggles
  bool _notifyOnLikes = true;
  bool _notifyOnComments = true;
  bool _notifyOnFollows = true;
  bool _notifyOnMentions = true;
  bool _notifyOnDirectMessages = true;

  // Subscription category toggles
  bool _notifyOnSubscriptionRenewal = true;
  bool _notifyOnPaymentEvents = true;
  bool _notifyOnSubscriptionChanges = true;
  bool _notifyOnSubscriptionCancelled = true;
  bool _notifyOnArtworkLimitReached = true;
  bool _notifyOnEventReminder = true;
  bool _notifyOnGalleryInvite = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final userModel = await _userService.getCurrentUserModel();
      final subscription = await _subscriptionService.getUserSubscription();

      if (mounted) {
        setState(() {
          // Check if user has an active subscription
          _hasSubscription = subscription?.isActive ?? false;
        });
      }
    } catch (e) {
      print('Error checking subscription status: $e');
    }
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load notification preferences from NotificationService
      final preferences =
          await _notificationService.loadNotificationPreferences();

      setState(() {
        // General notification toggles
        _emailNotifications = preferences['emailNotifications'] ?? true;
        _pushNotifications = preferences['notificationsEnabled'] ?? true;
        _inAppNotifications = preferences['inAppNotifications'] ?? true;

        // Community notification toggles
        _notifyOnLikes = preferences['notifyOnLikes'] ?? true;
        _notifyOnComments = preferences['notifyOnComments'] ?? true;
        _notifyOnFollows = preferences['notifyOnFollows'] ?? true;
        _notifyOnMentions = preferences['notifyOnMentions'] ?? true;
        _notifyOnDirectMessages = preferences['notifyOnDirectMessages'] ?? true;

        // Subscription category toggles
        _notifyOnSubscriptionRenewal =
            preferences['notifyOnSubscriptionRenewal'] ?? true;
        _notifyOnPaymentEvents = preferences['notifyOnPaymentEvents'] ?? true;
        _notifyOnSubscriptionChanges =
            preferences['notifyOnSubscriptionChanges'] ?? true;
        _notifyOnSubscriptionCancelled =
            preferences['notifyOnSubscriptionCancelled'] ?? true;
        _notifyOnArtworkLimitReached =
            preferences['notifyOnArtworkLimitReached'] ?? true;
        _notifyOnEventReminder = preferences['notifyOnEventReminder'] ?? true;
        _notifyOnGalleryInvite = preferences['notifyOnGalleryInvite'] ?? false;
      });
    } catch (e) {
      print('Error loading notification settings: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save subscription notification preferences using NotificationService
      await _notificationService.saveNotificationPreferences(
        notificationsEnabled: _pushNotifications,
        notifyOnSubscriptionRenewal: _notifyOnSubscriptionRenewal,
        notifyOnPaymentEvents: _notifyOnPaymentEvents,
        notifyOnSubscriptionChanges: _notifyOnSubscriptionChanges,
        notifyOnSubscriptionCancelled: _notifyOnSubscriptionCancelled,
        notifyOnArtworkLimitReached: _notifyOnArtworkLimitReached,
        notifyOnEventReminder: _notifyOnEventReminder,
        notifyOnGalleryInvite: _notifyOnGalleryInvite,
      );

      // Update user document directly with all notification preferences
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'notificationsEnabled': _pushNotifications,
          'emailNotifications': _emailNotifications,
          'notificationPreferences': {
            // General notification preferences
            'inAppNotifications': _inAppNotifications,

            // Community notification preferences
            'notifyOnLikes': _notifyOnLikes,
            'notifyOnComments': _notifyOnComments,
            'notifyOnFollows': _notifyOnFollows,
            'notifyOnMentions': _notifyOnMentions,
            'notifyOnDirectMessages': _notifyOnDirectMessages,

            // Subscription notification preferences
            'notifyOnSubscriptionRenewal': _notifyOnSubscriptionRenewal,
            'notifyOnPaymentEvents': _notifyOnPaymentEvents,
            'notifyOnSubscriptionChanges': _notifyOnSubscriptionChanges,
            'notifyOnSubscriptionCancelled': _notifyOnSubscriptionCancelled,
            'notifyOnArtworkLimitReached': _notifyOnArtworkLimitReached,
            'notifyOnEventReminder': _notifyOnEventReminder,
            'notifyOnGalleryInvite': _notifyOnGalleryInvite,
          }
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveNotificationSettings,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Notification Channels
                const Text(
                  'Notification Channels',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive notifications via email'),
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text(
                    'Receive notifications on your device',
                  ),
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('In-App Notifications'),
                  subtitle: const Text(
                    'Receive notifications while using the app',
                  ),
                  value: _inAppNotifications,
                  onChanged: (value) {
                    setState(() {
                      _inAppNotifications = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                const Divider(height: 32),

                // Community Notification Categories
                const Text(
                  'Community Notifications',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Likes'),
                  subtitle: const Text('When someone likes your content'),
                  value: _notifyOnLikes,
                  onChanged: (value) {
                    setState(() {
                      _notifyOnLikes = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Comments'),
                  subtitle: const Text(
                    'When someone comments on your content',
                  ),
                  value: _notifyOnComments,
                  onChanged: (value) {
                    setState(() {
                      _notifyOnComments = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Follows'),
                  subtitle: const Text('When someone follows you'),
                  value: _notifyOnFollows,
                  onChanged: (value) {
                    setState(() {
                      _notifyOnFollows = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Mentions'),
                  subtitle: const Text('When someone mentions you'),
                  value: _notifyOnMentions,
                  onChanged: (value) {
                    setState(() {
                      _notifyOnMentions = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Direct Messages'),
                  subtitle: const Text('When someone sends you a message'),
                  value: _notifyOnDirectMessages,
                  onChanged: (value) {
                    setState(() {
                      _notifyOnDirectMessages = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                const Divider(height: 32),

                // Subscription Notification Categories
                FutureBuilder(
                  future: _subscriptionService.getUserSubscription(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // Check if user has a subscription
                    final hasSubscription =
                        snapshot.hasData && snapshot.data != null;

                    // Show subscription notification settings regardless of subscription status
                    // This ensures users always get notifications about subscription-related events
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Subscription Notifications',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (!hasSubscription)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'Settings for artist and gallery subscription notifications.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        SwitchListTile(
                          title: const Text('Subscription Renewals'),
                          subtitle: const Text('When your subscription renews'),
                          value: _notifyOnSubscriptionRenewal,
                          onChanged: (value) {
                            setState(() {
                              _notifyOnSubscriptionRenewal = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Payment Notifications'),
                          subtitle: const Text('When payments succeed or fail'),
                          value: _notifyOnPaymentEvents,
                          onChanged: (value) {
                            setState(() {
                              _notifyOnPaymentEvents = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Subscription Changes'),
                          subtitle:
                              const Text('When your subscription tier changes'),
                          value: _notifyOnSubscriptionChanges,
                          onChanged: (value) {
                            setState(() {
                              _notifyOnSubscriptionChanges = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Subscription Cancellations'),
                          subtitle:
                              const Text('When your subscription is cancelled'),
                          value: _notifyOnSubscriptionCancelled,
                          onChanged: (value) {
                            setState(() {
                              _notifyOnSubscriptionCancelled = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Artwork Limit Notifications'),
                          subtitle:
                              const Text('When you reach your artwork limit'),
                          value: _notifyOnArtworkLimitReached,
                          onChanged: (value) {
                            setState(() {
                              _notifyOnArtworkLimitReached = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Event Reminders'),
                          subtitle:
                              const Text('For upcoming events you\'ve created'),
                          value: _notifyOnEventReminder,
                          onChanged: (value) {
                            setState(() {
                              _notifyOnEventReminder = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text('Gallery Invitations'),
                          subtitle:
                              const Text('When galleries invite you to join'),
                          value: _notifyOnGalleryInvite,
                          onChanged: (value) {
                            setState(() {
                              _notifyOnGalleryInvite = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(height: 32),
                      ],
                    );
                  },
                ),

                // Notification schedule
                const Text(
                  'Notification Schedule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Quiet Hours'),
                  subtitle: const Text(
                    'Mute notifications during specific hours',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Quiet hours settings will be implemented soon',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Marketing preferences
                const Text(
                  'Marketing Preferences',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Product Updates'),
                  subtitle: const Text(
                    'Information about new features and improvements',
                  ),
                  value: true, // Would be fetched from user settings
                  onChanged: (value) {
                    // Would update user settings
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('WordNerd Newsletter'),
                  subtitle: const Text(
                    'Weekly vocabulary tips and learning resources',
                  ),
                  value: true, // Would be fetched from user settings
                  onChanged: (value) {
                    // Would update user settings
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 16),

                // Unsubscribe from all
                OutlinedButton(
                  onPressed: () {
                    _showUnsubscribeConfirmation();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Unsubscribe from all notifications'),
                ),
              ],
            ),
    );
  }

  Future<void> _showUnsubscribeConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsubscribe from all?'),
        content: const Text(
          'Are you sure you want to unsubscribe from all notifications? '
          'You will no longer receive any updates about activity related to your account, '
          'including important subscription and payment notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('UNSUBSCRIBE'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Update all notification preferences to false
      setState(() {
        // General notification channels
        _emailNotifications = false;
        _pushNotifications = false;
        _inAppNotifications = false;

        // Community notifications
        _notifyOnLikes = false;
        _notifyOnComments = false;
        _notifyOnFollows = false;
        _notifyOnMentions = false;
        _notifyOnDirectMessages = false;

        // Subscription notifications
        _notifyOnSubscriptionRenewal = false;
        _notifyOnPaymentEvents = false;
        _notifyOnSubscriptionChanges = false;
        _notifyOnSubscriptionCancelled = false;
        _notifyOnArtworkLimitReached = false;
        _notifyOnEventReminder = false;
        _notifyOnGalleryInvite = false;
      });

      // Save all preferences
      await _saveNotificationSettings();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsubscribed from all notifications')),
      );
    }
  }
}
