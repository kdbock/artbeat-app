enum LocalAdStatus {
  active,
  expired,
  deleted,
  pendingReview,
  flagged,
  rejected,
}

extension LocalAdStatusExtension on LocalAdStatus {
  String get displayName {
    switch (this) {
      case LocalAdStatus.active:
        return 'Active';
      case LocalAdStatus.expired:
        return 'Expired';
      case LocalAdStatus.deleted:
        return 'Deleted';
      case LocalAdStatus.pendingReview:
        return 'Pending Review';
      case LocalAdStatus.flagged:
        return 'Flagged';
      case LocalAdStatus.rejected:
        return 'Rejected';
    }
  }

  int get index {
    switch (this) {
      case LocalAdStatus.active:
        return 0;
      case LocalAdStatus.expired:
        return 1;
      case LocalAdStatus.deleted:
        return 2;
      case LocalAdStatus.pendingReview:
        return 3;
      case LocalAdStatus.flagged:
        return 4;
      case LocalAdStatus.rejected:
        return 5;
    }
  }

  static LocalAdStatus fromIndex(int idx) {
    if (idx < 0 || idx >= LocalAdStatus.values.length) {
      return LocalAdStatus.pendingReview; // Default fallback
    }
    return LocalAdStatus.values[idx];
  }

  /// Check if the ad is visible to users
  bool get isVisible => this == LocalAdStatus.active;

  /// Check if the ad needs admin attention
  bool get needsReview =>
      this == LocalAdStatus.pendingReview || this == LocalAdStatus.flagged;

  /// Check if the ad can be reported
  bool get canBeReported =>
      this == LocalAdStatus.active || this == LocalAdStatus.pendingReview;
}
