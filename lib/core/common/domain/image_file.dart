import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

/// Abstract class to define basic image operations
abstract class ImageFile {
  List<List<int>> pixels = [];

  Future<void> fromBoundaries(RenderRepaintBoundary boundary) async {
    final ui.Image image = await boundary.toImage();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    pixels = List.generate(image.height, (_) => List.filled(image.width, 0));
    int index = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final r = byteData.getUint8(index);
        final g = byteData.getUint8(index + 1);
        final b = byteData.getUint8(index + 2);
        pixels[y][x] = getColorValue(r, g, b);
        index += 4; // Move by 4 bytes (RGBA format)
      }
    }
  }
  
  void fromDataString(String data);
  String toDataString();

  int getColorValue(int r, int g, int b);
}

/// PBM (Portable Bitmap) file format implementation
class PBMFile extends ImageFile {
  @override
  void fromDataString(String data) {
    final lines = data
        .split('\n')
        .where((line) => !line.startsWith('#') && line.isNotEmpty);
    var isBinary = false;
    int width = 0, height = 0;

    final format = lines.first.trim();
    if (format == 'P1') {
      isBinary = false;
    } else if (format == 'P4') {
      isBinary = true;
    } else {
      throw FormatException("Unsupported PBM format: $format");
    }

    final dimensions = lines.skip(1).first.split(' ').map(int.parse).toList();
    width = dimensions[0];
    height = dimensions[1];
    pixels = List.generate(height, (_) => List.filled(width, 0));

    final pixelData =
        lines.skip(2).join(' ').split(isBinary ? '' : ' ').map(int.parse);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y][x] = pixelData.elementAt(x + y * width);
      }
    }
  }

  @override
  String toDataString() {
    final buffer = StringBuffer('P1\n${pixels[0].length} ${pixels.length}\n');
    for (var row in pixels) {
      buffer.writeln(row.join(' '));
    }
    return buffer.toString();
  }

  @override
  int getColorValue(int r, int g, int b) {
    // Returns 1 or 0 based on color (black/white)
    return (r + g + b) / 3 > 127 ? 1 : 0;
  }
}

/// PGM (Portable Graymap) file format implementation
class PGMFile extends ImageFile {
  int maxGray = 255;

  @override
  void fromDataString(String data) {
    final lines = data
        .split('\n')
        .where((line) => !line.startsWith('#') && line.isNotEmpty);
    var isBinary = false;
    int width = 0, height = 0;

    final format = lines.first.trim();
    if (format == 'P2') {
      isBinary = false;
    } else if (format == 'P5') {
      isBinary = true;
    } else {
      throw FormatException("Unsupported PGM format: $format");
    }

    final dimensions = lines.skip(1).first.split(' ').map(int.parse).toList();
    width = dimensions[0];
    height = dimensions[1];
    pixels = List.generate(height, (_) => List.filled(width, 0));
    maxGray = int.parse(lines.skip(2).first);

    final pixelData =
        lines.skip(3).join(' ').split(isBinary ? '' : ' ').map(int.parse);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        pixels[y][x] = pixelData.elementAt(x + y * width);
      }
    }
  }

  @override
  String toDataString() {
    final buffer =
        StringBuffer('P2\n${pixels[0].length} ${pixels.length}\n$maxGray\n');
    for (var row in pixels) {
      buffer.writeln(row.join(' '));
    }
    return buffer.toString();
  }

  @override
  int getColorValue(int r, int g, int b) {
    // Returns grayscale value (0–255) for PGM
    return ((r + g + b) / 3).round();
  }
}

/// PPM (Portable Pixmap) file format implementation
class PPMFile extends ImageFile {
  @override
  void fromDataString(String data) {
    final lines = data
        .split('\n')
        .where((line) => !line.startsWith('#') && line.isNotEmpty);
    var isBinary = false;
    int width = 0, height = 0;

    final format = lines.first.trim();
    if (format == 'P3') {
      isBinary = false;
    } else if (format == 'P6') {
      isBinary = true;
    } else {
      throw FormatException("Unsupported PPM format: $format");
    }

    final dimensions = lines.skip(1).first.split(' ').map(int.parse).toList();
    width = dimensions[0];
    height = dimensions[1];
    pixels = List.generate(
        height, (_) => List.filled(width * 3, 0)); // 3 values per pixel (RGB)

    final maxColor = int.parse(lines.skip(2).first);
    if (maxColor != 255) {
      throw FormatException("Unsupported max color value: $maxColor");
    }

    final pixelData =
        lines.skip(3).join(' ').split(isBinary ? '' : ' ').map(int.parse);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width * 3; x++) {
        pixels[y][x] = pixelData.elementAt(x + y * width * 3);
      }
    }
  }

  @override
  String toDataString() {
    final buffer =
        StringBuffer('P3\n${pixels[0].length ~/ 3} ${pixels.length}\n255\n');
    for (var row in pixels) {
      for (var i = 0; i < row.length; i += 3) {
        buffer.write('${row[i]} ${row[i + 1]} ${row[i + 2]} ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  @override
  int getColorValue(int r, int g, int b) {
    // Encodes RGB value for PPM
    return (r << 16) | (g << 8) | b;
  }
}
