import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:artbeat_core/artbeat_core.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile(File file, String path) async {
    try {
      AppLogger.info('Uploading file to path: $path');
      AppLogger.info('File exists: ${await file.exists()}');
      AppLogger.info('File size: ${await file.length()} bytes');

      final ref = _storage.ref().child(path);

      // Add metadata for better debugging
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploaded_at': DateTime.now().toIso8601String(),
          'uploaded_by': 'mobile_app',
          'debug_mode': kDebugMode.toString(),
          'build_mode': kDebugMode ? 'debug' : 'release',
        },
      );

      final uploadTask = ref.putFile(file, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        AppLogger.info('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('Upload successful. Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Error uploading file: $e');
      AppLogger.info('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<bool> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      return true;
    } catch (e) {
      AppLogger.error('Error deleting file: $e');
      return false;
    }
  }
}
