/// Represents the different types of users in the system
enum UserType {
  regular('user'),
  artist('artist'),
  gallery('business'),
  moderator('moderator'),
  admin('admin');

  final String value;

  const UserType(this.value);

  factory UserType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'artist':
        return UserType.artist;
      case 'business':
        return UserType.gallery;
      case 'moderator':
        return UserType.moderator;
      case 'admin':
        return UserType.admin;
      default:
        return UserType.regular;
    }
  }

  String get name => value;

  @override
  String toString() => value;
}
