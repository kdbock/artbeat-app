import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';

/// Enhanced security service for Art Walk operations
///
/// This service provides comprehensive security features including:
/// - Input validation and sanitization
/// - Rate limiting and abuse prevention
/// - Content moderation and filtering
/// - Privacy controls and data protection
/// - Audit logging and monitoring
class ArtWalkSecurityService {
  static ArtWalkSecurityService? _instance;
  static ArtWalkSecurityService get instance =>
      _instance ??= ArtWalkSecurityService._();

  final Logger _logger = Logger();

  // Rate limiting storage
  final Map<String, List<DateTime>> _rateLimitingMap = {};
  final Map<String, int> _suspiciousActivityCounter = {};

  // Security configurations
  static const int _maxRequestsPerMinute = 60;
  static const int _maxSuspiciousActivities = 10;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  // Content validation patterns
  static const int _maxTitleLength = 100;
  static const int _maxDescriptionLength = 2000;
  static const int _maxCommentLength = 500;
  static const int _minTitleLength = 3;

  // Prohibited content patterns
  static final List<RegExp> _prohibitedPatterns = [
    RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
    RegExp(r'javascript:', caseSensitive: false),
    RegExp(r'vbscript:', caseSensitive: false),
    RegExp(r'on\w+\s*=', caseSensitive: false),
  ];

  ArtWalkSecurityService._();

  /// Initialize security service
  Future<void> initialize() async {
    try {
      // Start background cleanup tasks
      _startBackgroundTasks();
      _logger.i('ArtWalkSecurityService initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize ArtWalkSecurityService', error: e);
      rethrow;
    }
  }

  /// Validate and sanitize Art Walk creation input
  Future<ValidationResult> validateArtWalkInput({
    required String title,
    required String description,
    required String userId,
    List<String>? tags,
    String? zipCode,
  }) async {
    try {
      // Rate limiting check
      final rateLimitResult = await _checkRateLimit(userId, 'createArtWalk');
      if (!rateLimitResult.isValid) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Rate limit exceeded. Please try again later.',
          errorCode: 'RATE_LIMIT_EXCEEDED',
        );
      }

      // Input length validation
      if (title.length < _minTitleLength || title.length > _maxTitleLength) {
        return ValidationResult(
          isValid: false,
          errorMessage:
              'Title must be between $_minTitleLength and $_maxTitleLength characters.',
          errorCode: 'INVALID_TITLE_LENGTH',
        );
      }

      if (description.length > _maxDescriptionLength) {
        return ValidationResult(
          isValid: false,
          errorMessage:
              'Description must be less than $_maxDescriptionLength characters.',
          errorCode: 'INVALID_DESCRIPTION_LENGTH',
        );
      }

      // Prohibited content check BEFORE sanitization
      if (_containsProhibitedContent(title) ||
          _containsProhibitedContent(description)) {
        await _logSuspiciousActivity(userId, 'PROHIBITED_CONTENT', {
          'title': title,
          'description': description.substring(0, min(100, description.length)),
        });

        return ValidationResult(
          isValid: false,
          errorMessage: 'Content contains prohibited elements.',
          errorCode: 'PROHIBITED_CONTENT',
        );
      }

      // Content sanitization
      final sanitizedTitle = _sanitizeInput(title);
      final sanitizedDescription = _sanitizeInput(description);

      // ZIP code validation
      if (zipCode != null && !_isValidZipCode(zipCode)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Invalid ZIP code format.',
          errorCode: 'INVALID_ZIP_CODE',
        );
      }

      // Tags validation
      if (tags != null && !_validateTags(tags)) {
        return ValidationResult(
          isValid: false,
          errorMessage: 'Invalid tags format or excessive number of tags.',
          errorCode: 'INVALID_TAGS',
        );
      }

      return ValidationResult(
        isValid: true,
        sanitizedData: {
          'title': sanitizedTitle,
          'description': sanitizedDescription,
          'tags': tags?.map(_sanitizeInput).toList(),
        },
      );
    } catch (e) {
      _logger.e('Error validating art walk input', error: e);
      return ValidationResult(
        isValid: false,
        errorMessage: 'Validation failed due to internal error.',
        errorCode: 'VALIDATION_ERROR',
      );
    }
  }

  /// Validate comment input with enhanced security
  Future<ValidationResult> validateCommentInput({
    required String content,
    required String userId,
    required String artWalkId,
  }) async {
    try {
      // Rate limiting for comments (more restrictive)
      final rateLimitResult = await _checkRateLimit(
        userId,
        'createComment',
        maxRequests: 10,
      );
      if (!rateLimitResult.isValid) {
        return ValidationResult(
          isValid: false,
          errorMessage:
              'Too many comments. Please wait before commenting again.',
          errorCode: 'COMMENT_RATE_LIMIT_EXCEEDED',
        );
      }

      // Content length validation
      if (content.trim().isEmpty || content.length > _maxCommentLength) {
        return ValidationResult(
          isValid: false,
          errorMessage:
              'Comment must be between 1 and $_maxCommentLength characters.',
          errorCode: 'INVALID_COMMENT_LENGTH',
        );
      }

      // Check for prohibited content BEFORE sanitization
      if (_containsProhibitedContent(content)) {
        await _logSuspiciousActivity(userId, 'PROHIBITED_COMMENT', {
          'content': content.substring(0, min(100, content.length)),
          'artWalkId': artWalkId,
        });

        return ValidationResult(
          isValid: false,
          errorMessage: 'Comment contains prohibited content.',
          errorCode: 'PROHIBITED_CONTENT',
        );
      }

      // Sanitize content
      final sanitizedContent = _sanitizeInput(content);

      // Check for spam patterns
      if (_isSpamContent(sanitizedContent)) {
        await _logSuspiciousActivity(userId, 'SPAM_COMMENT', {
          'content': content.substring(0, min(50, content.length)),
          'artWalkId': artWalkId,
        });

        return ValidationResult(
          isValid: false,
          errorMessage: 'Comment appears to be spam.',
          errorCode: 'SPAM_DETECTED',
        );
      }

      return ValidationResult(
        isValid: true,
        sanitizedData: {'content': sanitizedContent},
      );
    } catch (e) {
      _logger.e('Error validating comment input', error: e);
      return ValidationResult(
        isValid: false,
        errorMessage: 'Comment validation failed.',
        errorCode: 'VALIDATION_ERROR',
      );
    }
  }

  /// Check if user has permission to modify art walk
  Future<bool> canModifyArtWalk(String userId, String artWalkId) async {
    try {
      // In a real implementation, this would check Firestore
      // For testing, we'll implement a simple check
      _logger.i(
        'Checking modification permission for user $userId on art walk $artWalkId',
      );

      // This would be replaced with actual Firestore logic in production
      return true; // Simplified for testing
    } catch (e) {
      _logger.e('Error checking art walk modification permission', error: e);
      return false;
    }
  }

  /// Generate secure token for sensitive operations
  String generateSecureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Hash sensitive data for storage
  String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check rate limiting for specific operations
  Future<RateLimitResult> _checkRateLimit(
    String userId,
    String operation, {
    int? maxRequests,
  }) async {
    final key = '${userId}_$operation';
    final now = DateTime.now();
    final requests = _rateLimitingMap[key] ?? [];

    // Remove old requests outside the rate limit window
    requests.removeWhere((time) => now.difference(time) > _rateLimitWindow);

    final requestLimit = maxRequests ?? _maxRequestsPerMinute;

    if (requests.length >= requestLimit) {
      await _logSuspiciousActivity(userId, 'RATE_LIMIT_EXCEEDED', {
        'operation': operation,
        'requestCount': requests.length,
      });

      return RateLimitResult(isValid: false, remainingRequests: 0);
    }

    // Add current request
    requests.add(now);
    _rateLimitingMap[key] = requests;

    return RateLimitResult(
      isValid: true,
      remainingRequests: requestLimit - requests.length,
    );
  }

  /// Sanitize input to prevent XSS and injection attacks
  String _sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('&', '')
        .replaceAll('"', '')
        .replaceAll("'", '') // Remove dangerous characters
        .trim();
  }

  /// Check if content contains prohibited patterns
  bool _containsProhibitedContent(String content) {
    for (final pattern in _prohibitedPatterns) {
      if (pattern.hasMatch(content)) {
        return true;
      }
    }
    return false;
  }

  /// Validate ZIP code format
  bool _isValidZipCode(String zipCode) {
    // Support US ZIP codes (5 digits, optionally +4)
    final zipPattern = RegExp(r'^\d{5}(-\d{4})?$');
    return zipPattern.hasMatch(zipCode);
  }

  /// Validate tags array
  bool _validateTags(List<String> tags) {
    if (tags.length > 10) return false; // Maximum 10 tags

    for (final tag in tags) {
      if (tag.length > 30 || tag.trim().isEmpty) return false;
    }

    return true;
  }

  /// Check if content appears to be spam
  bool _isSpamContent(String content) {
    final lowerContent = content.toLowerCase();

    // Common spam indicators
    final spamIndicators = [
      'buy now',
      'click here',
      'free money',
      'make money fast',
      'limited time',
      'act now',
      'guaranteed',
      'risk-free',
    ];

    int spamScore = 0;
    for (final indicator in spamIndicators) {
      if (lowerContent.contains(indicator)) {
        spamScore++;
      }
    }

    // Check for excessive repetition
    if (RegExp(r'(.)\1{4,}').hasMatch(content)) spamScore++;

    // Check for phrase repetition (more lenient pattern)
    if (RegExp(r'(.{3,}\s+)\1{2,}').hasMatch(content)) spamScore++;

    return spamScore >= 2;
  }

  /// Log suspicious activity for monitoring
  Future<void> _logSuspiciousActivity(
    String userId,
    String activityType,
    Map<String, dynamic> details,
  ) async {
    try {
      final suspiciousKey = '${userId}_suspicious';
      final count = _suspiciousActivityCounter[suspiciousKey] ?? 0;
      _suspiciousActivityCounter[suspiciousKey] = count + 1;

      // In production, this would log to Firestore
      _logger.w('Suspicious activity logged: $activityType for user $userId');

      // If too many suspicious activities, flag user
      if (count + 1 >= _maxSuspiciousActivities) {
        await _flagUserForReview(userId, 'MULTIPLE_SUSPICIOUS_ACTIVITIES');
      }
    } catch (e) {
      _logger.e('Error logging suspicious activity', error: e);
    }
  }

  /// Flag user for admin review
  Future<void> _flagUserForReview(String userId, String reason) async {
    try {
      // In production, this would create a Firestore document
      _logger.w('User flagged for review: $userId, reason: $reason');
    } catch (e) {
      _logger.e('Error flagging user for review', error: e);
    }
  }

  /// Start background cleanup tasks
  void _startBackgroundTasks() {
    // Clean up rate limiting data every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) {
      final now = DateTime.now();
      _rateLimitingMap.removeWhere((key, requests) {
        requests.removeWhere((time) => now.difference(time) > _rateLimitWindow);
        return requests.isEmpty;
      });
    });

    // Clean up suspicious activity counters every hour
    Timer.periodic(const Duration(hours: 1), (_) {
      _suspiciousActivityCounter.clear();
    });
  }
}

/// Result of input validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? sanitizedData;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
    this.sanitizedData,
  });
}

/// Result of rate limiting check
class RateLimitResult {
  final bool isValid;
  final int remainingRequests;

  RateLimitResult({required this.isValid, required this.remainingRequests});
}
