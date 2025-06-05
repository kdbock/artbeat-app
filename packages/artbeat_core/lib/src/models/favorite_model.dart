class FavoriteModel {
  final String id;
  final String title;
  final String description;
  final String type; // e.g., word, quote, article, etc.
  final String imageUrl;
  final Map<String, dynamic>? metadata;

  FavoriteModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.imageUrl,
    this.metadata,
  });

  factory FavoriteModel.fromMap(Map<String, dynamic> data, String documentId) {
    return FavoriteModel(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'content',
      imageUrl: data['imageUrl'] ?? '',
      metadata:
          data['metadata'] != null
              ? Map<String, dynamic>.from(data['metadata'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'imageUrl': imageUrl,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
