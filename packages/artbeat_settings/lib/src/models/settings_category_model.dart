/// Settings category model for organizing settings
/// Implementation Date: September 5, 2025
class SettingsCategoryModel {
  final String id;
  final String title;
  final String description;
  final String iconData;
  final String route;
  final bool isEnabled;
  final int order;

  const SettingsCategoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconData,
    required this.route,
    this.isEnabled = true,
    this.order = 0,
  });

  factory SettingsCategoryModel.fromMap(Map<String, dynamic> map) {
    return SettingsCategoryModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconData: map['iconData'] as String? ?? '',
      route: map['route'] as String? ?? '',
      isEnabled: map['isEnabled'] as bool? ?? true,
      order: map['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconData': iconData,
      'route': route,
      'isEnabled': isEnabled,
      'order': order,
    };
  }

  SettingsCategoryModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconData,
    String? route,
    bool? isEnabled,
    int? order,
  }) {
    return SettingsCategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconData: iconData ?? this.iconData,
      route: route ?? this.route,
      isEnabled: isEnabled ?? this.isEnabled,
      order: order ?? this.order,
    );
  }

  bool isValid() => id.isNotEmpty && title.isNotEmpty && route.isNotEmpty;

  /// Default settings categories
  static List<SettingsCategoryModel> getDefaultCategories() {
    return [
      const SettingsCategoryModel(
        id: 'account',
        title: 'Account',
        description: 'Manage your account information',
        iconData: 'account_circle',
        route: '/settings/account',
        order: 1,
      ),
      const SettingsCategoryModel(
        id: 'privacy',
        title: 'Privacy',
        description: 'Control your privacy settings',
        iconData: 'privacy_tip',
        route: '/settings/privacy',
        order: 2,
      ),
      const SettingsCategoryModel(
        id: 'notifications',
        title: 'Notifications',
        description: 'Manage notification preferences',
        iconData: 'notifications',
        route: '/settings/notifications',
        order: 3,
      ),
      const SettingsCategoryModel(
        id: 'security',
        title: 'Security',
        description: 'Security and authentication settings',
        iconData: 'security',
        route: '/settings/security',
        order: 4,
      ),
      const SettingsCategoryModel(
        id: 'blocked-users',
        title: 'Blocked Users',
        description: 'Manage blocked users',
        iconData: 'block',
        route: '/settings/blocked-users',
        order: 5,
      ),
    ];
  }
}
