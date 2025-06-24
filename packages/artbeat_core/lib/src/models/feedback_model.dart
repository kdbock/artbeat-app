import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackType { bug, feature, improvement, usability, performance, other }

enum FeedbackPriority { low, medium, high, critical }

enum FeedbackStatus { open, inProgress, resolved, closed }

class FeedbackModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String title;
  final String description;
  final FeedbackType type;
  final FeedbackPriority priority;
  final FeedbackStatus status;
  final List<String>
  packageModules; // Which packages/modules the feedback relates to
  final String deviceInfo;
  final String appVersion;
  final List<String> imageUrls;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? developerResponse;

  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.packageModules,
    required this.deviceInfo,
    required this.appVersion,
    required this.imageUrls,
    required this.metadata,
    required this.createdAt,
    this.resolvedAt,
    this.developerResponse,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      userEmail: (data['userEmail'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      type: FeedbackType.values[(data['type'] as int?) ?? 0],
      priority: FeedbackPriority.values[(data['priority'] as int?) ?? 0],
      status: FeedbackStatus.values[(data['status'] as int?) ?? 0],
      packageModules: List<String>.from(
        (data['packageModules'] as List?) ?? ['general'],
      ),
      deviceInfo: (data['deviceInfo'] as String?) ?? '',
      appVersion: (data['appVersion'] as String?) ?? '',
      imageUrls: List<String>.from((data['imageUrls'] as List?) ?? []),
      metadata: Map<String, dynamic>.from((data['metadata'] as Map?) ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      developerResponse: data['developerResponse'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'title': title,
      'description': description,
      'type': type.index,
      'priority': priority.index,
      'status': status.index,
      'packageModules': packageModules,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
      'imageUrls': imageUrls,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'developerResponse': developerResponse,
    };
  }

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? title,
    String? description,
    FeedbackType? type,
    FeedbackPriority? priority,
    FeedbackStatus? status,
    List<String>? packageModules,
    String? deviceInfo,
    String? appVersion,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? developerResponse,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      packageModules: packageModules ?? this.packageModules,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
      imageUrls: imageUrls ?? this.imageUrls,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      developerResponse: developerResponse ?? this.developerResponse,
    );
  }
}

// Extensions for better UX
extension FeedbackTypeExtension on FeedbackType {
  String get displayName {
    switch (this) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.feature:
        return 'Feature Request';
      case FeedbackType.improvement:
        return 'Improvement';
      case FeedbackType.usability:
        return 'Usability Issue';
      case FeedbackType.performance:
        return 'Performance Issue';
      case FeedbackType.other:
        return 'Other';
    }
  }
}

extension FeedbackPriorityExtension on FeedbackPriority {
  String get displayName {
    switch (this) {
      case FeedbackPriority.low:
        return 'Low';
      case FeedbackPriority.medium:
        return 'Medium';
      case FeedbackPriority.high:
        return 'High';
      case FeedbackPriority.critical:
        return 'Critical';
    }
  }
}

extension FeedbackStatusExtension on FeedbackStatus {
  String get displayName {
    switch (this) {
      case FeedbackStatus.open:
        return 'Open';
      case FeedbackStatus.inProgress:
        return 'In Progress';
      case FeedbackStatus.resolved:
        return 'Resolved';
      case FeedbackStatus.closed:
        return 'Closed';
    }
  }
}
