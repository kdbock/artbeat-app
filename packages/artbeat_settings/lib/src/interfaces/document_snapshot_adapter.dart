import 'package:cloud_firestore/cloud_firestore.dart';
import 'i_test_document_snapshot.dart';

/// Adapter class to wrap DocumentSnapshot and implement our test interface
class DocumentSnapshotAdapter implements ITestDocumentSnapshot {
  final DocumentSnapshot<Map<String, dynamic>> _snapshot;

  DocumentSnapshotAdapter(this._snapshot);

  @override
  bool get exists => _snapshot.exists;

  @override
  Map<String, dynamic>? data() => _snapshot.data();
}
