import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/commission_template_model.dart';
import '../models/direct_commission_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CommissionTemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new commission template
  Future<String> createTemplate({
    required String name,
    required String description,
    required String detailedDescription,
    required double basePrice,
    required int estimatedDays,
    required String category,
    required List<String> tags,
    required List<String> includedFeatures,
    required List<String> additionalOptions,
    String? imageUrl,
    bool isPublic = true,
    required Map<String, dynamic> specs,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User must be authenticated');

      final templateId = _firestore.collection('commission_templates').doc().id;

      final template = CommissionTemplate(
        id: templateId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        type: CommissionType.digital,
        basePrice: basePrice,
        estimatedDays: estimatedDays,
        category: category,
        tags: tags,
        specs: CommissionSpecs.fromMap(specs),
        detailedDescription: detailedDescription,
        includedFeatures: includedFeatures,
        additionalOptions: additionalOptions,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        createdById: user.uid,
        metadata: {},
      );

      await _firestore
          .collection('commission_templates')
          .doc(templateId)
          .set(template.toFirestore());

      return templateId;
    } catch (e) {
      throw Exception('Failed to create template: $e');
    }
  }

  /// Get public templates
  Future<List<CommissionTemplate>> getPublicTemplates({
    String? category,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('commission_templates')
          .where('isPublic', isEqualTo: true);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      final result = await query
          .orderBy('avgRating', descending: true)
          .limit(limit)
          .get();

      return result.docs
          .map((doc) => CommissionTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get templates: $e');
    }
  }

  /// Get artist's templates
  Future<List<CommissionTemplate>> getArtistTemplates(String artistId) async {
    try {
      final query = await _firestore
          .collection('commission_templates')
          .where('createdById', isEqualTo: artistId)
          .orderBy('avgRating', descending: true)
          .get();

      return query.docs
          .map((doc) => CommissionTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get artist templates: $e');
    }
  }

  /// Search templates by name/description
  Future<List<CommissionTemplate>> searchTemplates(String query) async {
    try {
      // Note: For full text search, consider using Algolia or similar
      final result = await _firestore
          .collection('commission_templates')
          .where('isPublic', isEqualTo: true)
          .get();

      final templates = result.docs
          .map((doc) => CommissionTemplate.fromFirestore(doc))
          .toList();

      final searchTerm = query.toLowerCase();
      return templates
          .where(
            (t) =>
                t.name.toLowerCase().contains(searchTerm) ||
                t.description.toLowerCase().contains(searchTerm) ||
                t.tags.any((tag) => tag.toLowerCase().contains(searchTerm)),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search templates: $e');
    }
  }

  /// Get featured/trending templates
  Future<List<CommissionTemplate>> getFeaturedTemplates() async {
    try {
      final query = await _firestore
          .collection('commission_templates')
          .where('isPublic', isEqualTo: true)
          .orderBy('useCount', descending: true)
          .limit(10)
          .get();

      return query.docs
          .map((doc) => CommissionTemplate.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get featured templates: $e');
    }
  }

  /// Update template
  Future<void> updateTemplate(
    String templateId,
    CommissionTemplate template,
  ) async {
    try {
      await _firestore
          .collection('commission_templates')
          .doc(templateId)
          .update({...template.toFirestore(), 'updatedAt': Timestamp.now()});
    } catch (e) {
      throw Exception('Failed to update template: $e');
    }
  }

  /// Increment template use count
  Future<void> incrementUseCount(String templateId) async {
    try {
      await _firestore
          .collection('commission_templates')
          .doc(templateId)
          .update({'useCount': FieldValue.increment(1)});
    } catch (e) {
      AppLogger.error('Failed to increment template use count: $e');
    }
  }

  /// Update template rating
  Future<void> updateTemplateRating(String templateId, double rating) async {
    try {
      // Get current ratings
      final doc = await _firestore
          .collection('commission_templates')
          .doc(templateId)
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final currentRating = (data['avgRating'] as num?)?.toDouble() ?? 0.0;
      final useCount = data['useCount'] as int? ?? 1;

      // Calculate new average
      final newRating = (currentRating * useCount + rating) / (useCount + 1);

      await _firestore
          .collection('commission_templates')
          .doc(templateId)
          .update({'avgRating': newRating});
    } catch (e) {
      AppLogger.error('Failed to update template rating: $e');
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    try {
      await _firestore
          .collection('commission_templates')
          .doc(templateId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete template: $e');
    }
  }

  /// Get template by ID
  Future<CommissionTemplate?> getTemplateById(String templateId) async {
    try {
      final doc = await _firestore
          .collection('commission_templates')
          .doc(templateId)
          .get();

      if (!doc.exists) return null;
      return CommissionTemplate.fromFirestore(doc);
    } catch (e) {
      AppLogger.error('Failed to get template: $e');
      return null;
    }
  }
}
