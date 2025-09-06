import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_location.dart';

/// Model for tracking individual ad clicks and interactions
class AdClickModel {
  final String id;
  final String adId;
  final String ownerId;
  final String? viewerId; // null for anonymous users
  final AdLocation location;
  final DateTime timestamp;
  final String? destinationUrl; // where the click led to
  final String clickType; // 'cta', 'image', 'title', etc.
  final Map<String, dynamic>? metadata; // additional tracking data
  final String? userAgent; // browser/app information
  final String? ipAddress; // for geo-analytics (anonymized)
  final String? sessionId; // user session identifier
  final String? referrer; // previous page/screen
  final bool isValidClick; // fraud detection flag

  AdClickModel({
    required this.id,
    required this.adId,
    required this.ownerId,
    this.viewerId,
    required this.location,
    required this.timestamp,
    this.destinationUrl,
    this.clickType = 'general',
    this.metadata,
    this.userAgent,
    this.ipAddress,
    this.sessionId,
    this.referrer,
    this.isValidClick = true,
  });

  /// Factory constructor from Firestore data
  factory AdClickModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AdClickModel(
      id: documentId,
      adId: (map['adId'] ?? '') as String,
      ownerId: (map['ownerId'] ?? '') as String,
      viewerId: map['viewerId'] as String?,
      location: AdLocation.values.firstWhere(
        (loc) => loc.name == (map['location'] ?? ''),
        orElse: () => AdLocation.dashboard,
      ),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      destinationUrl: map['destinationUrl'] as String?,
      clickType: (map['clickType'] ?? 'general') as String,
      metadata: map['metadata'] as Map<String, dynamic>?,
      userAgent: map['userAgent'] as String?,
      ipAddress: map['ipAddress'] as String?,
      sessionId: map['sessionId'] as String?,
      referrer: map['referrer'] as String?,
      isValidClick: (map['isValidClick'] ?? true) as bool,
    );
  }

  /// Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'ownerId': ownerId,
      'viewerId': viewerId,
      'location': location.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'destinationUrl': destinationUrl,
      'clickType': clickType,
      'metadata': metadata,
      'userAgent': userAgent,
      'ipAddress': ipAddress,
      'sessionId': sessionId,
      'referrer': referrer,
      'isValidClick': isValidClick,
    };
  }

  /// Create click with current timestamp
  factory AdClickModel.create({
    required String adId,
    required String ownerId,
    String? viewerId,
    required AdLocation location,
    String? destinationUrl,
    String clickType = 'general',
    Map<String, dynamic>? metadata,
    String? userAgent,
    String? ipAddress,
    String? sessionId,
    String? referrer,
    bool isValidClick = true,
  }) {
    return AdClickModel(
      id: '', // Will be set by Firestore
      adId: adId,
      ownerId: ownerId,
      viewerId: viewerId,
      location: location,
      timestamp: DateTime.now(),
      destinationUrl: destinationUrl,
      clickType: clickType,
      metadata: metadata,
      userAgent: userAgent,
      ipAddress: ipAddress,
      sessionId: sessionId,
      referrer: referrer,
      isValidClick: isValidClick,
    );
  }

  /// Copy with method for updates
  AdClickModel copyWith({
    String? id,
    String? adId,
    String? ownerId,
    String? viewerId,
    AdLocation? location,
    DateTime? timestamp,
    String? destinationUrl,
    String? clickType,
    Map<String, dynamic>? metadata,
    String? userAgent,
    String? ipAddress,
    String? sessionId,
    String? referrer,
    bool? isValidClick,
  }) {
    return AdClickModel(
      id: id ?? this.id,
      adId: adId ?? this.adId,
      ownerId: ownerId ?? this.ownerId,
      viewerId: viewerId ?? this.viewerId,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      destinationUrl: destinationUrl ?? this.destinationUrl,
      clickType: clickType ?? this.clickType,
      metadata: metadata ?? this.metadata,
      userAgent: userAgent ?? this.userAgent,
      ipAddress: ipAddress ?? this.ipAddress,
      sessionId: sessionId ?? this.sessionId,
      referrer: referrer ?? this.referrer,
      isValidClick: isValidClick ?? this.isValidClick,
    );
  }

  @override
  String toString() {
    return 'AdClickModel(id: $id, adId: $adId, viewerId: $viewerId, location: $location, clickType: $clickType, timestamp: $timestamp)';
  }
}
