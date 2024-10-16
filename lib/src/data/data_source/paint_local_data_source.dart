import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

abstract class PaintLocalDataSource {
  const PaintLocalDataSource();
  Future<String> saveFile(RenderRepaintBoundary boundary, String extension);
}

class PaintLocalDataSourceImpl implements PaintLocalDataSource {
  @override
  Future<String> saveFile(RenderRepaintBoundary boundary, String extension) async {
    try {
      final bytes = await _getBytesFromBoundary(boundary);
      
      if (bytes == null) {
        throw Exception('Could not get bytes from boundary');
      }

      String directoryPath;

      if (Platform.isAndroid || Platform.isIOS) {
        // Get the external storage directory for Android and iOS
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw Exception('Could not access external storage.');
        }
        directoryPath = directory.path;
      } else if (Platform.isWindows) {
        // Get the Documents directory for Windows
        final directory = await getApplicationDocumentsDirectory();
        directoryPath = directory.path;
      } else {
        throw Exception('Unsupported platform');
      }

      // Define the file name with a unique timestamp
      final String fileName =
          'file_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String filePath = '$directoryPath/$fileName';

      // Create the file and write the bytes to it
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      return 'File saved at: $filePath';
    } catch (e) {
      throw Exception('Error saving file: $e');
    }
  }

  Future<Uint8List?> _getBytesFromBoundary(
      RenderRepaintBoundary boundary) async {
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}
