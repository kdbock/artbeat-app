import '../models/capture_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CaptureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'captures'; // Or your specific collection name

  Future<List<CaptureModel>> getUserCaptures(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt',
              descending: true) // Optional: order by creation time
          .get();

      return querySnapshot.docs
          .map((doc) => CaptureModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Log error or handle as needed
      print('Error fetching user captures: $e');
      throw Exception('Failed to load captures.');
    }
  }

  Future<List<CaptureModel>> getCapturesForUser(String? userId) async {
    if (userId == null) {
      return [];
    }
    return getUserCaptures(userId);
  }

  // Add other capture-related service methods here, e.g.:
  // Future<String> createCapture(Map<String, dynamic> captureData) async { ... }
  // Future<void> updateCapture(String captureId, Map<String, dynamic> captureData) async { ... }
  // Future<void> deleteCapture(String captureId) async { ... }
}
