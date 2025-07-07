import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/capture_model.dart';

class CaptureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch captures with optional filter and limit
  Future<List<CaptureModel>> getCaptures({
    Map<String, dynamic>? filter,
    int limit = 50,
  }) async {
    final CollectionReference capturesRef = _firestore.collection('captures');
    Query query = capturesRef;
    if (filter != null) {
      filter.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });
    }
    query = query.limit(limit);
    final snapshot = await query.get();
    return snapshot.docs
        .map(
          (doc) => CaptureModel.fromJson({
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          }),
        )
        .toList();
  }
}
