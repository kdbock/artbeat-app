import 'package:cloud_firestore/cloud_firestore.dart';
import 'ad_location.dart';

/// Model for tracking individual ad impressions (views)
class AdImpressionModel {
  final String id;
  final String adId;
  final String ownerId;
  final String? viewerId; // null for anonymous users
  final AdLocation location;
  final DateTime timestamp;
  final Duration? viewDuration; // how long the ad was visible
  final Map<String, dynamic>? metadata; // additional tracking data
  final String? userAgent; // browser/app information
  final String? ipAddress; // for geo-analytics (anonymized)
  final String? sessionId; // user session identifier

  AdImpressionModel({
    required this.id,
    required this.adId,
    required this.ownerId,
    this.viewerId,
    required this.location,
    required this.timestamp,
    this.viewDuration,
    this.metadata,
    this.userAgent,
    this.ipAddress,
    this.sessionId,
  });

  /// Factory constructor from Firestore data
  factory AdImpressionModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return AdImpressionModel(
      id: documentId,
      adId: (map['adId'] ?? '') as String,
      ownerId: (map['ownerId'] ?? '') as String,
      viewerId: map['viewerId'] as String?,
      location: AdLocation.values.firstWhere(
        (loc) => loc.name == (map['location'] ?? ''),
        orElse: () => AdLocation.fluidDashboard,
      ),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      viewDuration: map['viewDurationMs'] != null
          ? Duration(milliseconds: (map['viewDurationMs'] as num).toInt())
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      userAgent: map['userAgent'] as String?,
      ipAddress: map['ipAddress'] as String?,
      sessionId: map['sessionId'] as String?,
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
      'viewDurationMs': viewDuration?.inMilliseconds,
      'metadata': metadata,
      'userAgent': userAgent,
      'ipAddress': ipAddress,
      'sessionId': sessionId,
    };
  }

  /// Create impression with current timestamp
  factory AdImpressionModel.create({
    required String adId,
    required String ownerId,
    String? viewerId,
    required AdLocation location,
    Duration? viewDuration,
    Map<String, dynamic>? metadata,
    String? userAgent,
    String? ipAddress,
    String? sessionId,
  }) {
    return AdImpressionModel(
      id: '', // Will be set by Firestore
      adId: adId,
      ownerId: ownerId,
      viewerId: viewerId,
      location: location,
      timestamp: DateTime.now(),
      viewDuration: viewDuration,
      metadata: metadata,
      userAgent: userAgent,
      ipAddress: ipAddress,
      sessionId: sessionId,
    );
  }

  /// Copy with method for updates
  AdImpressionModel copyWith({
    String? id,
    String? adId,
    String? ownerId,
    String? viewerId,
    AdLocation? location,
    DateTime? timestamp,
    Duration? viewDuration,
    Map<String, dynamic>? metadata,
    String? userAgent,
    String? ipAddress,
    String? sessionId,
  }) {
    return AdImpressionModel(
      id: id ?? this.id,
      adId: adId ?? this.adId,
      ownerId: ownerId ?? this.ownerId,
      viewerId: viewerId ?? this.viewerId,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      viewDuration: viewDuration ?? this.viewDuration,
      metadata: metadata ?? this.metadata,
      userAgent: userAgent ?? this.userAgent,
      ipAddress: ipAddress ?? this.ipAddress,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  String toString() {
    return 'AdImpressionModel(id: $id, adId: $adId, viewerId: $viewerId, location: $location, timestamp: $timestamp)';
  }
}
