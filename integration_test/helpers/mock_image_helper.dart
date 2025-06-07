import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MockImageHelper {
  static Future<File> getTestImage() async {
    // Create a temporary file from the test asset
    final byteData = await rootBundle.load('test_resources/test_image.jpg');
    final buffer = byteData.buffer;
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/test_image.jpg';

    final file = await File(tempPath).create();
    await file.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );

    return file;
  }
}
