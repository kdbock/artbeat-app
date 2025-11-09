import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/profile_customization_model.dart';
import '../services/profile_customization_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileCustomizationScreen extends StatefulWidget {
  const ProfileCustomizationScreen({super.key});

  @override
  State<ProfileCustomizationScreen> createState() =>
      _ProfileCustomizationScreenState();
}

class _ProfileCustomizationScreenState
    extends State<ProfileCustomizationScreen> {
  final ProfileCustomizationService _customizationService =
      ProfileCustomizationService();
  ProfileCustomizationModel? _customization;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers and state
  String _selectedTheme = 'default';
  String _primaryColor = '#00fd8a';
  String _secondaryColor = '#8c52ff';
  bool _showBio = true;
  bool _showLocation = true;
  bool _showAchievements = true;
  bool _showActivity = true;
  String _layoutStyle = 'grid';
  Map<String, bool> _visibilitySettings = {
    'showEmail': false,
    'showPhone': false,
    'showLocation': true,
    'showBirthday': false,
    'showJoinDate': true,
  };

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'default',
      'name': 'Default',
      'colors': ['#00fd8a', '#8c52ff'],
    },
    {
      'id': 'dark',
      'name': 'Dark Mode',
      'colors': ['#ffffff', '#000000'],
    },
    {
      'id': 'ocean',
      'name': 'Ocean',
      'colors': ['#00bcd4', '#3f51b5'],
    },
    {
      'id': 'sunset',
      'name': 'Sunset',
      'colors': ['#ff5722', '#ff9800'],
    },
    {
      'id': 'forest',
      'name': 'Forest',
      'colors': ['#4caf50', '#2e7d32'],
    },
    {
      'id': 'royal',
      'name': 'Royal',
      'colors': ['#9c27b0', '#673ab7'],
    },
  ];

  final List<Color> _colorOptions = [
    const Color(0xFF00fd8a), // Default green
    const Color(0xFF8c52ff), // Default purple
    const Color(0xFFff5722), // Red-orange
    const Color(0xFF2196f3), // Blue
    const Color(0xFF4caf50), // Green
    const Color(0xFFff9800), // Orange
    const Color(0xFF9c27b0), // Purple
    const Color(0xFFe91e63), // Pink
    const Color(0xFF00bcd4), // Cyan
    const Color(0xFF795548), // Brown
  ];

  @override
  void initState() {
    super.initState();
    _loadCustomizationSettings();
  }

  Future<void> _loadCustomizationSettings() async {
    try {
      final user = Provider.of<UserService>(context, listen: false).currentUser;
      if (user != null) {
        final customization = await _customizationService
            .getCustomizationSettings(user.uid);
        if (customization != null) {
          setState(() {
            _customization = customization;
            _selectedTheme = customization.selectedTheme ?? 'default';
            _primaryColor = customization.primaryColor ?? '#00fd8a';
            _secondaryColor = customization.secondaryColor ?? '#8c52ff';
            _showBio = customization.showBio;
            _showLocation = customization.showLocation;
            _showAchievements = customization.showAchievements;
            _showActivity = customization.showActivity;
            _layoutStyle = customization.layoutStyle ?? 'grid';
            _visibilitySettings = Map<String, bool>.from(
              customization.visibilitySettings,
            );
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customization: $e')),
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

  Future<void> _saveCustomizationSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = Provider.of<UserService>(context, listen: false).currentUser;
      if (user != null) {
        final updatedCustomization = ProfileCustomizationModel(
          userId: user.uid,
          selectedTheme: _selectedTheme,
          primaryColor: _primaryColor,
          secondaryColor: _secondaryColor,
          showBio: _showBio,
          showLocation: _showLocation,
          showAchievements: _showAchievements,
          showActivity: _showActivity,
          layoutStyle: _layoutStyle,
          visibilitySettings: _visibilitySettings,
          createdAt: _customization?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _customizationService.updateCustomizationSettings(
          updatedCustomization,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile customization saved!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile Customization')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('profile_customization_title'.tr()),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveCustomizationSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThemeSection(),
            const SizedBox(height: 24),
            _buildColorSection(),
            const SizedBox(height: 24),
            _buildVisibilitySection(),
            const SizedBox(height: 24),
            _buildLayoutSection(),
            const SizedBox(height: 24),
            _buildPrivacySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _themes.length,
            itemBuilder: (context, index) {
              final theme = _themes[index];
              final isSelected = theme['id'] == _selectedTheme;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTheme = theme['id'] as String;
                    _primaryColor =
                        (theme['colors'] as List<dynamic>)[0] as String;
                    _secondaryColor =
                        (theme['colors'] as List<dynamic>)[1] as String;
                  });
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                      ((theme['colors'] as List<dynamic>)[0]
                                              as String)
                                          .substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                      ((theme['colors'] as List<dynamic>)[1]
                                              as String)
                                          .substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        theme['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Colors',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Primary Color'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorOptions.length,
                      itemBuilder: (context, index) {
                        final color = _colorOptions[index];
                        final colorHex =
                            '#${color.toARGB32().toRadixString(16).substring(2)}';
                        final isSelected = colorHex == _primaryColor;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _primaryColor = colorHex;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Secondary Color'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorOptions.length,
                      itemBuilder: (context, index) {
                        final color = _colorOptions[index];
                        final colorHex =
                            '#${color.toARGB32().toRadixString(16).substring(2)}';
                        final isSelected = colorHex == _secondaryColor;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _secondaryColor = colorHex;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Elements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Show Bio'),
          subtitle: Text('profile_customization_bio'.tr()),
          value: _showBio,
          onChanged: (value) {
            setState(() {
              _showBio = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Show Location'),
          subtitle: Text('profile_customization_location'.tr()),
          value: _showLocation,
          onChanged: (value) {
            setState(() {
              _showLocation = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Show Achievements'),
          subtitle: Text('profile_customization_badges'.tr()),
          value: _showAchievements,
          onChanged: (value) {
            setState(() {
              _showAchievements = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Show Recent Activity'),
          subtitle: const Text('Display your recent activity feed'),
          value: _showActivity,
          onChanged: (value) {
            setState(() {
              _showActivity = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLayoutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Layout Style',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            const ButtonSegment<String>(
              value: 'grid',
              label: Text('Grid'),
              icon: Icon(Icons.grid_view),
            ),
            const ButtonSegment<String>(
              value: 'list',
              label: Text('List'),
              icon: Icon(Icons.view_list),
            ),
            ButtonSegment<String>(
              value: 'compact',
              label: Text('profile_customization_compact'.tr()),
              icon: const Icon(Icons.view_compact),
            ),
          ],
          selected: {_layoutStyle},
          onSelectionChanged: (Set<String> newSelection) {
            setState(() {
              _layoutStyle = newSelection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: _visibilitySettings.entries.map((entry) {
                return SwitchListTile(
                  title: Text(_getPrivacySettingTitle(entry.key)),
                  subtitle: Text(_getPrivacySettingSubtitle(entry.key)),
                  value: entry.value,
                  onChanged: (value) {
                    setState(() {
                      _visibilitySettings[entry.key] = value;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _getPrivacySettingTitle(String key) {
    switch (key) {
      case 'showEmail':
        return 'Show Email';
      case 'showPhone':
        return 'Show Phone';
      case 'showLocation':
        return 'Show Location';
      case 'showBirthday':
        return 'Show Birthday';
      case 'showJoinDate':
        return 'Show Join Date';
      default:
        return key;
    }
  }

  String _getPrivacySettingSubtitle(String key) {
    switch (key) {
      case 'showEmail':
        return 'Allow others to see your email address';
      case 'showPhone':
        return 'Allow others to see your phone number';
      case 'showLocation':
        return 'Show your location to other users';
      case 'showBirthday':
        return 'Display your birthday on your profile';
      case 'showJoinDate':
        return 'Show when you joined ARTbeat';
      default:
        return 'Privacy setting';
    }
  }
}
