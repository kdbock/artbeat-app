import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

abstract class StorageService {
  Future<String> uploadImage(String userId, File imageFile);
}

class ReleaseStorageService implements StorageService {
  @override
  Future<String> uploadImage(String userId, File imageFile) async {
    // TODO: Implement release storage service once App Check issues are resolved
    throw UnimplementedError('Release storage not yet implemented');
  }
}

class DebugStorageService implements StorageService {
  @override
  Future<String> uploadImage(String userId, File imageFile) async {
    try {
      // Get local app directory
      final appDir = await getApplicationDocumentsDirectory();
      final capturesDir =
          Directory(path.join(appDir.path, 'debug_captures', userId));

      // Create captures directory if it doesn't exist
      if (!capturesDir.existsSync()) {
        capturesDir.createSync(recursive: true);
      }

      // Generate unique filename
      final ext = path.extension(imageFile.path);
      final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}$ext';
      final savedFile = File(path.join(capturesDir.path, fileName));

      // Copy image file to debug storage location
      await imageFile.copy(savedFile.path);

      // Return file URL for debug mode
      return 'file://${savedFile.path}';
    } catch (e) {
      debugPrint('❌ Failed to save image locally: $e');
      rethrow;
    }
  }
}
