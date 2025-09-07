// This file is used to generate mocks for testing
// Run: dart run build_runner build --delete-conflicting-outputs

import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Generate mocks for Firebase services
@GenerateMocks([
  // Firestore mocks
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  Query,
  Transaction,
  WriteBatch,

  // Firebase Storage mocks
  FirebaseStorage,
  Reference,
  UploadTask,
  TaskSnapshot,
  FullMetadata,
  SettableMetadata,

  // Firebase Auth mocks
  FirebaseAuth,
  User,
  UserCredential,

  // Additional mocks for testing
  Stream,
])
void main() {
  // This file is used by build_runner to generate mocks
  // The actual mock generation happens when you run:
  // dart run build_runner build --delete-conflicting-outputs
}
