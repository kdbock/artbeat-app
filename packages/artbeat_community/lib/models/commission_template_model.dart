import 'package:cloud_firestore/cloud_firestore.dart';
import 'direct_commission_model.dart';

/// Commission template for quick commission requests
class CommissionTemplate {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final CommissionType type;
  final double basePrice;
  final int estimatedDays;
  final String category; // portrait, landscape, character, etc.
  final List<String> tags;
  final CommissionSpecs specs;
  final String detailedDescription;
  final List<String> includedFeatures;
  final List<String> additionalOptions;
  final bool isPublic;
  final int useCount; // How many times used
  final double avgRating; // Average rating for this template
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdById;
  final Map<String, dynamic> metadata;

  CommissionTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.type,
    required this.basePrice,
    required this.estimatedDays,
    required this.category,
    required this.tags,
    required this.specs,
    required this.detailedDescription,
    required this.includedFeatures,
    required this.additionalOptions,
    this.isPublic = true,
    this.useCount = 0,
    this.avgRating = 0.0,
    required this.createdAt,
    this.updatedAt,
    required this.createdById,
    required this.metadata,
  });

  factory CommissionTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommissionTemplate(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      type: CommissionType.values.firstWhere(
        (t) => t.name == (data['type'] as String? ?? 'digital'),
        orElse: () => CommissionType.digital,
      ),
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? 0.0,
      estimatedDays: data['estimatedDays'] as int? ?? 7,
      category: data['category'] as String? ?? 'general',
      tags: List<String>.from(data['tags'] as List<dynamic>? ?? []),
      specs: CommissionSpecs.fromMap(
        data['specs'] as Map<String, dynamic>? ?? {},
      ),
      detailedDescription: data['detailedDescription'] as String? ?? '',
      includedFeatures: List<String>.from(
        data['includedFeatures'] as List<dynamic>? ?? [],
      ),
      additionalOptions: List<String>.from(
        data['additionalOptions'] as List<dynamic>? ?? [],
      ),
      isPublic: data['isPublic'] as bool? ?? true,
      useCount: data['useCount'] as int? ?? 0,
      avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdById: data['createdById'] as String? ?? '',
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'basePrice': basePrice,
      'estimatedDays': estimatedDays,
      'category': category,
      'tags': tags,
      'specs': specs.toMap(),
      'detailedDescription': detailedDescription,
      'includedFeatures': includedFeatures,
      'additionalOptions': additionalOptions,
      'isPublic': isPublic,
      'useCount': useCount,
      'avgRating': avgRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdById': createdById,
      'metadata': metadata,
    };
  }

  CommissionTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    CommissionType? type,
    double? basePrice,
    int? estimatedDays,
    String? category,
    List<String>? tags,
    CommissionSpecs? specs,
    String? detailedDescription,
    List<String>? includedFeatures,
    List<String>? additionalOptions,
    bool? isPublic,
    int? useCount,
    double? avgRating,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdById,
    Map<String, dynamic>? metadata,
  }) {
    return CommissionTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      basePrice: basePrice ?? this.basePrice,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      specs: specs ?? this.specs,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      includedFeatures: includedFeatures ?? this.includedFeatures,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      isPublic: isPublic ?? this.isPublic,
      useCount: useCount ?? this.useCount,
      avgRating: avgRating ?? this.avgRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdById: createdById ?? this.createdById,
      metadata: metadata ?? this.metadata,
    );
  }
}
