import 'package:flutter/foundation.dart';

@immutable
class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final DateTime unlockedAt;
  final int points;
  final String category;
  final String tier; // bronze, silver, gold

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.unlockedAt,
    required this.points,
    required this.category,
    required this.tier,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      points: json['points'] as int,
      category: json['category'] as String,
      tier: json['tier'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'unlockedAt': unlockedAt.toIso8601String(),
      'points': points,
      'category': category,
      'tier': tier,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          iconUrl == other.iconUrl &&
          unlockedAt == other.unlockedAt &&
          points == other.points &&
          category == other.category &&
          tier == other.tier;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      iconUrl.hashCode ^
      unlockedAt.hashCode ^
      points.hashCode ^
      category.hashCode ^
      tier.hashCode;

  @override
  String toString() => 'AchievementModel(id: $id, name: $name)';

  AchievementModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    DateTime? unlockedAt,
    int? points,
    String? category,
    String? tier,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      points: points ?? this.points,
      category: category ?? this.category,
      tier: tier ?? this.tier,
    );
  }
}
