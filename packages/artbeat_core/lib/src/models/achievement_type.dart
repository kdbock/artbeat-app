/// Achievement types for the art walk feature
enum AchievementType {
  /// Awarded when completing first art walk
  firstWalk('first_walk'),

  /// Awarded when completing 5 art walks
  explorer('explorer'),

  /// Awarded when completing 10 art walks
  master('master');

  final String value;
  const AchievementType(this.value);
}
