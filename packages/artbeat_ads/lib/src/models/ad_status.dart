import 'package:flutter/material.dart';

/// Status of an ad in the system
enum AdStatus {
  pending, // Awaiting approval
  approved, // Approved and scheduled
  rejected, // Rejected by admin
  running, // Currently running
  paused, // Temporarily paused
  expired, // Finished
  draft,
  active,
}

extension AdStatusExtension on AdStatus {
  String get displayName {
    switch (this) {
      case AdStatus.draft:
        return 'Draft';
      case AdStatus.pending:
        return 'Pending Review';
      case AdStatus.approved:
        return 'Approved';
      case AdStatus.rejected:
        return 'Rejected';
      case AdStatus.active:
        return 'Active';
      case AdStatus.expired:
        return 'Expired';
      case AdStatus.running:
        return 'Running';
      case AdStatus.paused:
        return 'Paused';
    }
  }

  String get description {
    switch (this) {
      case AdStatus.draft:
        return 'Ad is being created.';
      case AdStatus.pending:
        return 'Ad is pending review.';
      case AdStatus.approved:
        return 'Ad has been approved.';
      case AdStatus.rejected:
        return 'Ad has been rejected.';
      case AdStatus.active:
        return 'Ad is currently running.';
      case AdStatus.expired:
        return 'Ad has expired.';
      case AdStatus.running:
        return 'Ad is running.';
      case AdStatus.paused:
        return 'Ad is paused.';
    }
  }

  Color get color {
    switch (this) {
      case AdStatus.draft:
        return Colors.grey;
      case AdStatus.pending:
        return Colors.orange;
      case AdStatus.approved:
        return Colors.green;
      case AdStatus.rejected:
        return Colors.red;
      case AdStatus.active:
        return Colors.blue;
      case AdStatus.expired:
        return Colors.black;
      case AdStatus.running:
        return Colors.lightBlue;
      case AdStatus.paused:
        return Colors.yellow;
    }
  }

  bool get isEditable {
    switch (this) {
      case AdStatus.draft:
      case AdStatus.rejected:
        return true;
      case AdStatus.pending:
      case AdStatus.approved:
      case AdStatus.active:
      case AdStatus.expired:
      case AdStatus.running:
      case AdStatus.paused:
        return false;
    }
  }

  bool get isFinal {
    switch (this) {
      case AdStatus.expired:
      case AdStatus.rejected:
        return true;
      case AdStatus.draft:
      case AdStatus.pending:
      case AdStatus.approved:
      case AdStatus.active:
      case AdStatus.running:
      case AdStatus.paused:
        return false;
    }
  }
}
