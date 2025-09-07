class Validators {
  // Validate email format
  static String? validateEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email address';
    }
    return null;
  }

  // Validate password strength
  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  // Validate non-empty fields
  static String? validateNonEmpty(String value) {
    if (value.trim().isEmpty) {
      return 'This field cannot be empty';
    }
    return null;
  }

  // Validate username format
  static String? validateUsername(String username) {
    final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
    if (!usernameRegex.hasMatch(username)) {
      return 'Username must be 3-15 characters and contain only letters, numbers, or underscores';
    }
    return null;
  }
}
