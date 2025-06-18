import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUtils {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get current user document
  static Future<DocumentSnapshot?> getCurrentUserDocument(
      String collection) async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    return _firestore.collection(collection).doc(userId).get();
  }

  // Add a document to a collection
  static Future<void> addDocument(
      String collection, Map<String, dynamic> data) async {
    await _firestore.collection(collection).add(data);
  }

  // Update a document in a collection
  static Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  // Delete a document from a collection
  static Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  // Query documents in a collection
  static Future<QuerySnapshot> queryCollection(
      String collection, Map<String, dynamic> filters) async {
    Query query = _firestore.collection(collection);
    filters.forEach((key, value) {
      query = query.where(key, isEqualTo: value);
    });
    return await query.get();
  }
}
