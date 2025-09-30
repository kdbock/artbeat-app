/// Universal entity model representing all searchable items in the app
class KnownEntity {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final KnownEntityType type;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const KnownEntity({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.type,
    required this.data,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from artist/user data
  factory KnownEntity.fromArtist({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final fullName = data['fullName'] as String? ?? '';
    final username = data['username'] as String? ?? '';
    final profileImageUrl = data['profileImageUrl'] as String?;

    return KnownEntity(
      id: id,
      title: fullName.isNotEmpty ? fullName : username,
      subtitle: username.isNotEmpty ? '@$username' : 'Artist',
      imageUrl: profileImageUrl,
      type: KnownEntityType.artist,
      data: data,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create from artwork/capture data
  factory KnownEntity.fromArtwork({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] as String? ?? '';
    final artistName = data['artistName'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String?;

    return KnownEntity(
      id: id,
      title: title.isNotEmpty ? title : 'Untitled Artwork',
      subtitle: artistName.isNotEmpty ? 'by $artistName' : 'Artwork',
      imageUrl: imageUrl,
      type: KnownEntityType.artwork,
      data: data,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create from art walk data
  factory KnownEntity.fromArtWalk({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] as String? ?? '';
    final zipCode = data['zipCode'] as String? ?? '';
    final coverImageUrl = data['coverImageUrl'] as String?;

    return KnownEntity(
      id: id,
      title: title.isNotEmpty ? title : 'Art Walk',
      subtitle: 'Art Walk${zipCode.isNotEmpty ? ' • $zipCode' : ''}',
      imageUrl: coverImageUrl,
      type: KnownEntityType.artWalk,
      data: data,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create from event data
  factory KnownEntity.fromEvent({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = data['title'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final imageUrl = data['imageUrl'] as String?;

    return KnownEntity(
      id: id,
      title: title.isNotEmpty ? title : 'Event',
      subtitle: location.isNotEmpty ? location : 'Event',
      imageUrl: imageUrl,
      type: KnownEntityType.event,
      data: data,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Create from location data
  factory KnownEntity.fromLocation({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final name = data['name'] as String? ?? '';
    final address = data['address'] as String? ?? '';

    return KnownEntity(
      id: id,
      title: name.isNotEmpty ? name : 'Location',
      subtitle: address.isNotEmpty ? address : 'Location',
      imageUrl: null,
      type: KnownEntityType.location,
      data: data,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  /// Helper method to parse timestamp from various formats
  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    if (timestamp is DateTime) return timestamp;

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (_) {
        return null;
      }
    }

    // Handle Firestore Timestamp if available
    if (timestamp.runtimeType.toString() == 'Timestamp') {
      try {
        final dynamic timestampData = timestamp;
        return (timestampData as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'type': type.toString(),
      'data': data,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory KnownEntity.fromJson(Map<String, dynamic> json) {
    return KnownEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      imageUrl: json['imageUrl'] as String?,
      type: KnownEntityType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => KnownEntityType.unknown,
      ),
      data: json['data'] as Map<String, dynamic>,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'KnownEntity(id: $id, title: $title, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnownEntity && other.id == id && other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, type);
}

/// Types of entities that can be searched
enum KnownEntityType { artist, artwork, event, artWalk, location, unknown }

/// Extension to get user-friendly labels for entity types
extension KnownEntityTypeExtension on KnownEntityType {
  String get label {
    switch (this) {
      case KnownEntityType.artist:
        return 'Artist';
      case KnownEntityType.artwork:
        return 'Artwork';
      case KnownEntityType.event:
        return 'Event';
      case KnownEntityType.artWalk:
        return 'Art Walk';
      case KnownEntityType.location:
        return 'Location';
      case KnownEntityType.unknown:
        return 'Unknown';
    }
  }
}
