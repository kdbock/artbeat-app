import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/content_review_model.dart';

/// AI-powered content analysis service for moderation
/// Implements 2025 industry standards for automated content review
class ContentAnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIService _aiService = AIService();
  final Logger _logger = Logger('ContentAnalysisService');

  static const String _moderationApiUrl =
      'https://api.openai.com/v1/moderations';

  // This would typically come from environment variables or Firebase config
  static const String _apiKey = 'your-openai-api-key-here';

  /// Analyze content for inappropriate material, spam, and quality scoring
  Future<ContentAnalysisResult> analyzeContent({
    required String contentId,
    required ContentType contentType,
    required String content,
    String? imageUrl,
    String? title,
    String? description,
  }) async {
    try {
      final analysis = ContentAnalysisResult(
        contentId: contentId,
        contentType: contentType,
        analyzedAt: DateTime.now(),
      );

      // 1. Text-based analysis for inappropriate content
      if (content.isNotEmpty) {
        final textAnalysis = await _analyzeTextContent(content);
        analysis.inappropriateContentScore = textAnalysis.inappropriateScore;
        analysis.spamScore = textAnalysis.spamScore;
        analysis.hateSpeechScore = textAnalysis.hateSpeechScore;
        analysis.violenceScore = textAnalysis.violenceScore;
        analysis.flags.addAll(textAnalysis.flags);
      }

      // 2. Image analysis if image is present
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final imageAnalysis = await _analyzeImageContent(
          imageUrl,
          title: title,
          description: description,
        );
        analysis.nsfwScore = imageAnalysis.nsfwScore;
        analysis.imageFlags.addAll(imageAnalysis.flags);
        analysis.flags.addAll(imageAnalysis.flags);
      }

      // 3. Quality scoring
      analysis.qualityScore = await _calculateQualityScore(
        content: content,
        title: title,
        description: description,
        flags: analysis.flags,
      );

      // 4. Generate AI recommendations
      analysis.aiRecommendation = await _generateAIRecommendation(analysis);

      // 5. Calculate overall risk score
      analysis.overallRiskScore = _calculateOverallRiskScore(analysis);

      // Store analysis results
      await _storeAnalysisResult(analysis);

      return analysis;
    } catch (e) {
      _logger.severe('Error analyzing content $contentId', e);
      // Return basic analysis on error
      return ContentAnalysisResult(
        contentId: contentId,
        contentType: contentType,
        analyzedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Analyze text content for inappropriate material
  Future<TextAnalysisResult> _analyzeTextContent(String content) async {
    try {
      final response = await http.post(
        Uri.parse(_moderationApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'input': content,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        if (results.isNotEmpty) {
          final result = results[0] as Map<String, dynamic>;
          final categories = result['categories'] as Map<String, dynamic>;
          final categoryScores =
              result['category_scores'] as Map<String, dynamic>;

          final flags = <ContentFlag>[];

          // Check for various inappropriate content types
          if (categories['sexual'] == true) {
            flags.add(ContentFlag(
              type: FlagType.inappropriate,
              severity: Severity.high,
              reason: 'Sexual content detected',
              confidence: (categoryScores['sexual'] as num).toDouble(),
            ));
          }

          if (categories['hate'] == true) {
            flags.add(ContentFlag(
              type: FlagType.hateSpeech,
              severity: Severity.high,
              reason: 'Hate speech detected',
              confidence: (categoryScores['hate'] as num).toDouble(),
            ));
          }

          if (categories['violence'] == true) {
            flags.add(ContentFlag(
              type: FlagType.violence,
              severity: Severity.medium,
              reason: 'Violent content detected',
              confidence: (categoryScores['violence'] as num).toDouble(),
            ));
          }

          return TextAnalysisResult(
            inappropriateScore: (categoryScores['sexual'] as num).toDouble(),
            spamScore: _calculateSpamScore(content),
            hateSpeechScore: (categoryScores['hate'] as num).toDouble(),
            violenceScore: (categoryScores['violence'] as num).toDouble(),
            flags: flags,
          );
        }
      }

      // Fallback analysis if API fails
      return _fallbackTextAnalysis(content);
    } catch (e) {
      _logger.warning('Text analysis API error, using fallback', e);
      return _fallbackTextAnalysis(content);
    }
  }

  /// Analyze image content for NSFW material
  Future<ImageAnalysisResult> _analyzeImageContent(
    String imageUrl, {
    String? title,
    String? description,
  }) async {
    try {
      // Use AI service for image analysis
      final tags = await _aiService.generateSmartTags(
        imageUrl: imageUrl,
        title: title,
        description: description,
      );

      final flags = <ContentFlag>[];
      double nsfwScore = 0.0;

      // Check for potentially inappropriate tags
      final inappropriateTags = [
        'nude',
        'nudity',
        'sexual',
        'erotic',
        'porn',
        'pornographic',
        'violent',
        'gore',
        'blood',
        'death',
        'weapon',
        'drugs',
        'hate',
        'offensive',
        'racist',
        'discriminatory'
      ];

      for (final tag in tags) {
        if (inappropriateTags.any(
            (inappropriate) => tag.toLowerCase().contains(inappropriate))) {
          nsfwScore += 0.3;
          flags.add(ContentFlag(
            type: FlagType.inappropriate,
            severity: Severity.medium,
            reason: 'Potentially inappropriate content detected: $tag',
            confidence: 0.7,
          ));
        }
      }

      // Additional analysis for explicit content
      if (tags.contains('adult') || tags.contains('mature')) {
        nsfwScore += 0.4;
        flags.add(ContentFlag(
          type: FlagType.nsfw,
          severity: Severity.high,
          reason: 'Adult/mature content detected',
          confidence: 0.8,
        ));
      }

      return ImageAnalysisResult(
        nsfwScore: nsfwScore.clamp(0.0, 1.0),
        flags: flags,
      );
    } catch (e) {
      _logger.warning('Image analysis error', e);
      return ImageAnalysisResult(nsfwScore: 0.0, flags: []);
    }
  }

  /// Calculate spam score based on content patterns
  double _calculateSpamScore(String content) {
    double score = 0.0;

    // Check for excessive caps
    final capsRatio = content.replaceAll(RegExp(r'[^A-Z]'), '').length /
        content.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (capsRatio > 0.3) score += 0.3;

    // Check for excessive punctuation
    final punctuationRatio =
        content.replaceAll(RegExp(r'[a-zA-Z0-9\s]'), '').length /
            content.length;
    if (punctuationRatio > 0.1) score += 0.2;

    // Check for repetitive words
    final words = content.toLowerCase().split(RegExp(r'\s+'));
    final wordFrequency = <String, int>{};
    for (final word in words) {
      if (word.length > 3) {
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      }
    }
    final maxFrequency = wordFrequency.values.fold(0, (a, b) => a > b ? a : b);
    if (maxFrequency > 3) score += 0.2;

    // Check for URL spam
    final urlCount = RegExp(r'https?://').allMatches(content).length;
    if (urlCount > 2) score += 0.3;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate overall quality score
  Future<double> _calculateQualityScore({
    required String content,
    String? title,
    String? description,
    required List<ContentFlag> flags,
  }) async {
    double score = 1.0; // Start with perfect score

    // Length-based scoring
    if (content.length < 10) score -= 0.3;
    if (content.length > 5000) score -= 0.2; // Too long

    // Title quality
    if (title != null) {
      if (title.length < 5) score -= 0.2;
      if (title.toUpperCase() == title) score -= 0.1; // All caps
    }

    // Description quality
    if (description != null && description.length < 20) score -= 0.1;

    // Flag penalties
    for (final flag in flags) {
      switch (flag.severity) {
        case Severity.low:
          score -= 0.1;
        case Severity.medium:
          score -= 0.2;
        case Severity.high:
          score -= 0.4;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Generate AI recommendation for content moderation
  Future<AIRecommendation> _generateAIRecommendation(
    ContentAnalysisResult analysis,
  ) async {
    final riskScore = analysis.overallRiskScore;
    final qualityScore = analysis.qualityScore;

    if (riskScore > 0.8) {
      return AIRecommendation.reject;
    } else if (riskScore > 0.5) {
      return AIRecommendation.review;
    } else if (qualityScore < 0.3) {
      return AIRecommendation.review;
    } else {
      return AIRecommendation.approve;
    }
  }

  /// Calculate overall risk score
  double _calculateOverallRiskScore(ContentAnalysisResult analysis) {
    double riskScore = 0.0;

    // Weight different risk factors
    riskScore += analysis.inappropriateContentScore * 0.4;
    riskScore += analysis.hateSpeechScore * 0.3;
    riskScore += analysis.violenceScore * 0.2;
    riskScore += analysis.spamScore * 0.1;
    riskScore += (analysis.nsfwScore ?? 0.0) * 0.3;

    // Adjust based on quality score
    riskScore += (1.0 - analysis.qualityScore) * 0.2;

    return riskScore.clamp(0.0, 1.0);
  }

  /// Fallback text analysis when API is unavailable
  TextAnalysisResult _fallbackTextAnalysis(String content) {
    final flags = <ContentFlag>[];
    double inappropriateScore = 0.0;
    double hateSpeechScore = 0.0;
    double violenceScore = 0.0;

    // Simple keyword-based detection
    final inappropriateWords = [
      'sex',
      'porn',
      'nude',
      'naked',
      'fuck',
      'shit',
      'damn',
      'bitch'
    ];
    final hateWords = ['hate', 'racist', 'nazi', 'terrorist', 'kill'];
    final violenceWords = ['kill', 'murder', 'death', 'blood', 'weapon'];

    final lowerContent = content.toLowerCase();

    for (final word in inappropriateWords) {
      if (lowerContent.contains(word)) {
        inappropriateScore += 0.2;
        flags.add(ContentFlag(
          type: FlagType.inappropriate,
          severity: Severity.medium,
          reason: 'Potentially inappropriate language detected',
          confidence: 0.6,
        ));
        break;
      }
    }

    for (final word in hateWords) {
      if (lowerContent.contains(word)) {
        hateSpeechScore += 0.3;
        flags.add(ContentFlag(
          type: FlagType.hateSpeech,
          severity: Severity.high,
          reason: 'Potentially hateful content detected',
          confidence: 0.7,
        ));
        break;
      }
    }

    for (final word in violenceWords) {
      if (lowerContent.contains(word)) {
        violenceScore += 0.2;
        flags.add(ContentFlag(
          type: FlagType.violence,
          severity: Severity.medium,
          reason: 'Potentially violent content detected',
          confidence: 0.6,
        ));
        break;
      }
    }

    return TextAnalysisResult(
      inappropriateScore: inappropriateScore.clamp(0.0, 1.0),
      spamScore: _calculateSpamScore(content),
      hateSpeechScore: hateSpeechScore.clamp(0.0, 1.0),
      violenceScore: violenceScore.clamp(0.0, 1.0),
      flags: flags,
    );
  }

  /// Store analysis results in Firestore
  Future<void> _storeAnalysisResult(ContentAnalysisResult analysis) async {
    try {
      await _firestore
          .collection('content_analysis')
          .doc(analysis.contentId)
          .set(analysis.toJson());
    } catch (e) {
      _logger.warning('Failed to store analysis result', e);
    }
  }

  /// Get analysis history for content
  Future<List<ContentAnalysisResult>> getAnalysisHistory(
    String contentId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('content_analysis')
          .where('contentId', isEqualTo: contentId)
          .orderBy('analyzedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ContentAnalysisResult.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.severe('Error getting analysis history', e);
      return [];
    }
  }

  /// Get analysis statistics for reporting
  Future<Map<String, dynamic>> getAnalysisStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('content_analysis');

      if (startDate != null) {
        query = query.where('analyzedAt', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('analyzedAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      final stats = {
        'totalAnalyzed': snapshot.docs.length,
        'highRiskContent': 0,
        'approvedByAI': 0,
        'rejectedByAI': 0,
        'requiresReview': 0,
        'averageRiskScore': 0.0,
        'averageQualityScore': 0.0,
      };

      double totalRiskScore = 0.0;
      double totalQualityScore = 0.0;

      for (final doc in snapshot.docs) {
        final analysis =
            ContentAnalysisResult.fromJson(doc.data() as Map<String, dynamic>);

        totalRiskScore += analysis.overallRiskScore;
        totalQualityScore += analysis.qualityScore;

        if (analysis.overallRiskScore > 0.7) {
          stats['highRiskContent'] = (stats['highRiskContent'] as int) + 1;
        }

        switch (analysis.aiRecommendation) {
          case AIRecommendation.approve:
            stats['approvedByAI'] = (stats['approvedByAI'] as int) + 1;
          case AIRecommendation.reject:
            stats['rejectedByAI'] = (stats['rejectedByAI'] as int) + 1;
          case AIRecommendation.review:
            stats['requiresReview'] = (stats['requiresReview'] as int) + 1;
        }
      }

      if (snapshot.docs.isNotEmpty) {
        stats['averageRiskScore'] = totalRiskScore / snapshot.docs.length;
        stats['averageQualityScore'] = totalQualityScore / snapshot.docs.length;
      }

      return stats;
    } catch (e) {
      _logger.severe('Error getting analysis statistics', e);
      return {};
    }
  }
}

/// Result of content analysis
class ContentAnalysisResult {
  final String contentId;
  final ContentType contentType;
  final DateTime analyzedAt;
  final List<ContentFlag> flags = [];
  final List<ContentFlag> imageFlags = [];

  double inappropriateContentScore = 0.0;
  double spamScore = 0.0;
  double hateSpeechScore = 0.0;
  double violenceScore = 0.0;
  double? nsfwScore;
  double qualityScore = 1.0;
  double overallRiskScore = 0.0;
  AIRecommendation aiRecommendation = AIRecommendation.review;
  String? error;

  ContentAnalysisResult({
    required this.contentId,
    required this.contentType,
    required this.analyzedAt,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'contentType': contentType.name,
      'analyzedAt': analyzedAt.toIso8601String(),
      'flags': flags.map((f) => f.toJson()).toList(),
      'imageFlags': imageFlags.map((f) => f.toJson()).toList(),
      'inappropriateContentScore': inappropriateContentScore,
      'spamScore': spamScore,
      'hateSpeechScore': hateSpeechScore,
      'violenceScore': violenceScore,
      'nsfwScore': nsfwScore,
      'qualityScore': qualityScore,
      'overallRiskScore': overallRiskScore,
      'aiRecommendation': aiRecommendation.name,
      'error': error,
    };
  }

  static ContentAnalysisResult fromJson(Map<String, dynamic> json) {
    final result = ContentAnalysisResult(
      contentId: json['contentId'] as String,
      contentType: ContentType.fromString(json['contentType'] as String),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      error: json['error'] as String?,
    );

    result.inappropriateContentScore =
        (json['inappropriateContentScore'] as num?)?.toDouble() ?? 0.0;
    result.spamScore = (json['spamScore'] as num?)?.toDouble() ?? 0.0;
    result.hateSpeechScore =
        (json['hateSpeechScore'] as num?)?.toDouble() ?? 0.0;
    result.violenceScore = (json['violenceScore'] as num?)?.toDouble() ?? 0.0;
    result.nsfwScore = (json['nsfwScore'] as num?)?.toDouble();
    result.qualityScore = (json['qualityScore'] as num?)?.toDouble() ?? 1.0;
    result.overallRiskScore =
        (json['overallRiskScore'] as num?)?.toDouble() ?? 0.0;
    result.aiRecommendation = AIRecommendation.values.firstWhere(
      (r) => r.name == json['aiRecommendation'] as String?,
      orElse: () => AIRecommendation.review,
    );

    if (json['flags'] != null) {
      result.flags.addAll(
        (json['flags'] as List<dynamic>)
            .map((f) => ContentFlag.fromJson(f as Map<String, dynamic>)),
      );
    }

    if (json['imageFlags'] != null) {
      result.imageFlags.addAll(
        (json['imageFlags'] as List<dynamic>)
            .map((f) => ContentFlag.fromJson(f as Map<String, dynamic>)),
      );
    }

    return result;
  }
}

/// Types of content flags
enum FlagType {
  inappropriate,
  hateSpeech,
  violence,
  spam,
  nsfw,
  lowQuality;

  String get displayName {
    switch (this) {
      case FlagType.inappropriate:
        return 'Inappropriate';
      case FlagType.hateSpeech:
        return 'Hate Speech';
      case FlagType.violence:
        return 'Violence';
      case FlagType.spam:
        return 'Spam';
      case FlagType.nsfw:
        return 'NSFW';
      case FlagType.lowQuality:
        return 'Low Quality';
    }
  }
}

/// Severity levels for flags
enum Severity {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case Severity.low:
        return 'Low';
      case Severity.medium:
        return 'Medium';
      case Severity.high:
        return 'High';
    }
  }
}

/// AI recommendation for content moderation
enum AIRecommendation {
  approve,
  review,
  reject;

  String get displayName {
    switch (this) {
      case AIRecommendation.approve:
        return 'Approve';
      case AIRecommendation.review:
        return 'Review';
      case AIRecommendation.reject:
        return 'Reject';
    }
  }
}

/// Content flag with details
class ContentFlag {
  final FlagType type;
  final Severity severity;
  final String reason;
  final double confidence;

  ContentFlag({
    required this.type,
    required this.severity,
    required this.reason,
    required this.confidence,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'severity': severity.name,
      'reason': reason,
      'confidence': confidence,
    };
  }

  static ContentFlag fromJson(Map<String, dynamic> json) {
    return ContentFlag(
      type: FlagType.values.firstWhere((t) => t.name == json['type'] as String),
      severity: Severity.values
          .firstWhere((s) => s.name == json['severity'] as String),
      reason: json['reason'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

/// Result of text analysis
class TextAnalysisResult {
  final double inappropriateScore;
  final double spamScore;
  final double hateSpeechScore;
  final double violenceScore;
  final List<ContentFlag> flags;

  TextAnalysisResult({
    required this.inappropriateScore,
    required this.spamScore,
    required this.hateSpeechScore,
    required this.violenceScore,
    required this.flags,
  });
}

/// Result of image analysis
class ImageAnalysisResult {
  final double nsfwScore;
  final List<ContentFlag> flags;

  ImageAnalysisResult({
    required this.nsfwScore,
    required this.flags,
  });
}
