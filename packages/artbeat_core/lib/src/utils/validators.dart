/// Validate an email address
bool isValidEmail(String email) {
  final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  return emailRegExp.hasMatch(email);
}

/// Validate a password
bool isValidPassword(String password) {
  // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
  final passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}$');
  return passwordRegExp.hasMatch(password);
}

/// Validate a phone number
bool isValidPhone(String phone) {
  final phoneRegExp = RegExp(r'^\+?[\d\s-]{10,}$');
  return phoneRegExp.hasMatch(phone);
}

/// Validate a username
bool isValidUsername(String username) {
  // 3-20 characters, letters, numbers, underscores, hyphens
  final usernameRegExp = RegExp(r'^[a-zA-Z0-9_-]{3,20}$');
  return usernameRegExp.hasMatch(username);
}

/// Validate a ZIP code
bool isValidZipCode(String zipCode) {
  final zipRegExp = RegExp(r'^\d{5}(?:[-\s]\d{4})?$');
  return zipRegExp.hasMatch(zipCode);
}

/// Validate latitude
bool isValidLatitude(double lat) {
  return lat >= -90 && lat <= 90;
}

/// Validate longitude
bool isValidLongitude(double lng) {
  return lng >= -180 && lng <= 180;
}

/// Validate price
bool isValidPrice(double price) {
  return price >= 0;
}

/// Validate a date string in yyyy-MM-dd format
bool isValidDateString(String date) {
  try {
    DateTime.parse(date);
    return true;
  } catch (_) {
    return false;
  }
}
