import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

/// Abstrakcyjna klasa bazowa dla obsługi obrazów w formatach PBM, PGM, PPM
abstract class ImageFile {
  List<List<Color>> pixels = [];

  /// Wczytywanie obrazu z boundary do macierzy pikseli
  Future<void> fromBoundaries(RenderRepaintBoundary boundary) async {
    final ui.Image image = await boundary.toImage();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    pixels = List.generate(
        image.height, (_) => List.filled(image.width, Colors.black));
    int index = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final r = byteData.getUint8(index);
        final g = byteData.getUint8(index + 1);
        final b = byteData.getUint8(index + 2);
        final a = byteData.getUint8(index + 3);
        pixels[y][x] = Color.fromARGB(a, r, g, b);
        index += 4;
      }
    }
  }

  /// Konwersja koloru na wartość specyficzną dla formatu (np. skala szarości dla PGM)
  int getColorValue(Color color);

  /// Eksportowanie do formatu tekstowego
  Future<void> exportAsText(String path);

  /// Eksportowanie do formatu binarnego
  Future<void> exportAsBinary(String path);

  /// Importowanie z formatu tekstowego
  Future<void> importAsText(String path);

  /// Importowanie z formatu binarnego
  Future<void> importAsBinary(String path);

  String get extension;
}

class PBMFile extends ImageFile {
  @override
  int getColorValue(Color color) {
    final isTransparent = color.alpha == 0;
    if (isTransparent) return 0;
    final grayScale =
        (0.3 * color.red + 0.59 * color.green + 0.11 * color.blue).toInt();
    return grayScale > 200 ? 0 : 1;
  }

  @override
  Future<void> exportAsText(String path) async {
    final file = File(path);
    final sink = file.openWrite();
    sink.write('P1\n');
    sink.write('${pixels[0].length} ${pixels.length}\n');
    for (var row in pixels) {
      final line = row.map((color) => getColorValue(color)).join(' ');
      sink.writeln(line);
    }
    await sink.close();
  }

  @override
  Future<void> exportAsBinary(String path) async {
    final file = File(path);
    final sink = file.openWrite();
    sink.write('P4\n');
    sink.write('${pixels[0].length} ${pixels.length}\n');

    final bytes = Uint8List((pixels.length * pixels[0].length + 7) ~/ 8);
    int index = 0;
    for (var row in pixels) {
      for (var pixel in row) {
        final byteIndex = index ~/ 8;
        final bitIndex = 7 - (index % 8);
        if (getColorValue(pixel) == 1) {
          bytes[byteIndex] |= (1 << bitIndex);
        }
        index++;
      }
    }

    sink.add(bytes);
    await sink.close();
  }

  @override
  Future<void> importAsText(String path) async {
    final file = File(path);
    final lines = await file.readAsLines();

    // Filter out comment lines
    final contentLines =
        lines.where((line) => !line.trim().startsWith('#')).toList();

    if (contentLines.isEmpty || contentLines[0] != 'P1') {
      throw const FormatException('Invalid PBM text format');
    }

    // Parse dimensions
    final dimensions = contentLines[1].split(RegExp(r'\s+'));
    final width = int.parse(dimensions[0]);
    final height = int.parse(dimensions[1]);

    // Initialize the pixel array
    pixels = List.generate(height, (_) => List.filled(width, Colors.black));
    int y = 0;

    // Process pixel data
    for (var line in contentLines.skip(2)) {
      if (line.trim().isEmpty) continue; // Skip empty lines
      final row = line.split(RegExp(r'\s+')).map((value) {
        final isWhite = int.parse(value) == 1;
        return isWhite ? Colors.white : Colors.black;
      }).toList();
      pixels[y++] = row;
    }
  }

  @override
  Future<void> importAsBinary(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    if (bytes.length < 2 ||
        String.fromCharCode(bytes[0]) != 'P' ||
        String.fromCharCode(bytes[1]) != '4') {
      throw const FormatException('Invalid PBM binary format');
    }

    // Extract the header and ignore comments
    int index = 2;
    final header = StringBuffer();
    while (header.toString().split('\n').length < 2) {
      final char = String.fromCharCode(bytes[index++]);
      if (char == '#') {
        // Skip the comment line
        while (bytes[index++] != 10); // 10 = '\n'
      } else {
        header.write(char);
      }
    }

    final headerLines = header
        .toString()
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final dimensions = headerLines[0].split(RegExp(r'\s+'));
    final width = int.parse(dimensions[0]);
    final height = int.parse(dimensions[1]);

    // Initialize the pixel array
    pixels = List.generate(height, (_) => List.filled(width, Colors.black));

    // Calculate where the pixel data starts
    int pixelDataStartIndex = index;

    // Process binary pixel data
    int bitIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final byte = bytes[pixelDataStartIndex + (bitIndex ~/ 8)];
        final bit = 7 - (bitIndex % 8);
        final isWhite = ((byte >> bit) & 1) == 1;
        pixels[y][x] = isWhite ? Colors.white : Colors.black;
        bitIndex++;
      }
    }
  }

  @override
  String get extension => 'pbm';
}

class PPMFile extends ImageFile {
  @override
  int getColorValue(Color color) {
    final isTransparent = color.alpha == 0;
    if (isTransparent) {
      return 0xFFFFFF;
    }
    return (color.red << 16) | (color.green << 8) | color.blue;
  }

  @override
  Future<void> exportAsText(String path) async {
    final file = File(path);
    final sink = file.openWrite();
    sink.write('P3\n');
    sink.write('${pixels[0].length} ${pixels.length}\n');
    sink.write('255\n');
    for (var row in pixels) {
      final line = row.map((data) {
        final color = Color(getColorValue(data));
        return '${color.red} ${color.green} ${color.blue}';
      }).join(' ');
      sink.writeln(line);
    }
    await sink.close();
  }

  @override
  Future<void> exportAsBinary(String path) async {
    final file = File(path);
    final sink = file.openWrite();
    sink.write('P6\n');
    sink.write('${pixels[0].length} ${pixels.length}\n');
    sink.write('255\n');

    final bytes = Uint8List(pixels.length * pixels[0].length * 3);
    int index = 0;
    for (var row in pixels) {
      for (var data in row) {
        final color = Color(getColorValue(data));
        bytes[index++] = color.red;
        bytes[index++] = color.green;
        bytes[index++] = color.blue;
      }
    }
    sink.add(bytes);
    await sink.close();
  }

  @override
  Future<void> importAsText(String path) async {
    final file = File(path);
    final lines = await file.readAsLines();

    // Filter out comment lines and trim whitespace
    final contentLines =
        lines.where((line) => !line.trim().startsWith('#')).toList();

    if (contentLines.isEmpty || contentLines[0] != 'P3') {
      throw const FormatException('Invalid PPM text format');
    }

    // Parse width, height, and max color value
    final dimensions = contentLines[1].split(RegExp(r'\s+'));
    final width = int.parse(dimensions[0]);
    final height = int.parse(dimensions[1]);
    final maxColorValue = int.parse(contentLines[
        2]); // Assumes no comments between dimensions and max color

    if (maxColorValue != 255) {
      throw const FormatException('Unsupported max color value (must be 255)');
    }

    // Initialize the pixels array
    pixels = List.generate(height, (_) => List.filled(width, Colors.black));
    int y = 0;

    // Process pixel data
    for (var line in contentLines.skip(3)) {
      if (line.trim().isEmpty) continue; // Skip empty lines
      final values = line.split(RegExp(r'\s+')).map(int.parse).toList();
      for (int x = 0; x < width; x++) {
        final r = values[x * 3];
        final g = values[x * 3 + 1];
        final b = values[x * 3 + 2];
        pixels[y][x] = Color.fromARGB(255, r, g, b);
      }
      y++;
    }
  }

  @override
  Future<void> importAsBinary(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    if (bytes.length < 2 ||
        String.fromCharCode(bytes[0]) != 'P' ||
        String.fromCharCode(bytes[1]) != '6') {
      throw const FormatException('Invalid PPM binary format');
    }

    // Read the header and skip comments
    int index = 2;
    final header = StringBuffer();
    while (header.toString().split('\n').length < 3) {
      final char = String.fromCharCode(bytes[index++]);
      if (char == '#') {
        // Skip the comment line
        while (bytes[index++] != 10); // 10 = '\n'
      } else {
        header.write(char);
      }
    }

    final headerLines = header
        .toString()
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final dimensions = headerLines[1].split(RegExp(r'\s+'));
    final width = int.parse(dimensions[0]);
    final height = int.parse(dimensions[1]);
    final maxColorValue = int.parse(headerLines[2].trim());

    if (maxColorValue != 255) {
      throw const FormatException('Unsupported max color value (must be 255)');
    }

    // Initialize the pixels array
    pixels = List.generate(height, (_) => List.filled(width, Colors.black));

    // Process binary pixel data
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = bytes[index++];
        final g = bytes[index++];
        final b = bytes[index++];
        pixels[y][x] = Color.fromARGB(255, r, g, b);
      }
    }
  }

  @override
  String get extension => 'ppm';
}

class PGMFile extends ImageFile {
  @override
  int getColorValue(Color color) {
    final isTransparent = color.alpha == 0;
    if (isTransparent) return 255;
    return (0.3 * color.red + 0.59 * color.green + 0.11 * color.blue).toInt();
  }

  @override
  Future<void> exportAsText(String path) async {
    final file = File(path);
    final sink = file.openWrite();
    sink.write('P2\n');
    sink.write('${pixels[0].length} ${pixels.length}\n');
    sink.write('255\n');
    for (var row in pixels) {
      final line = row.map((color) => getColorValue(color)).join(' ');
      sink.writeln(line);
    }
    await sink.close();
  }

  @override
  Future<void> exportAsBinary(String path) async {
    final file = File(path);
    final sink = file.openWrite();
    sink.write('P5\n');
    sink.write('${pixels[0].length} ${pixels.length}\n');
    sink.write('255\n');

    final bytes = Uint8List(pixels.length * pixels[0].length);
    int index = 0;
    for (var row in pixels) {
      for (var color in row) {
        bytes[index++] = getColorValue(color);
      }
    }
    sink.add(bytes);
    await sink.close();
  }

  @override
  Future<void> importAsText(String path) async {
    final file = File(path);
    final lines = await file.readAsLines();

    // Ignore comment lines and parse the file
    final contentLines =
        lines.where((line) => !line.trim().startsWith('#')).toList();

    if (contentLines[0] != 'P2') {
      throw const FormatException('Invalid PGM text format');
    }

    final dimensions = contentLines[1].split(' ');
    final width = int.parse(dimensions[0]);
    final height = int.parse(dimensions[1]);

    pixels = List.generate(height, (_) => List.filled(width, Colors.black));
    int y = 0;

    for (var line in contentLines.skip(3)) {
      if (line.trim().isEmpty) continue; // Skip empty lines
      final row = line.split(RegExp(r'\s+')).map((value) {
        final grayValue = int.parse(value);
        return Color.fromARGB(255, grayValue, grayValue, grayValue);
      }).toList();
      pixels[y++] = row;
    }
  }

  @override
  Future<void> importAsBinary(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    if (String.fromCharCode(bytes[0]) != 'P' ||
        String.fromCharCode(bytes[1]) != '5') {
      throw const FormatException('Invalid PGM binary format');
    }

    // Extract the header and ignore comments
    final header = String.fromCharCodes(bytes.sublist(0, bytes.indexOf(0x0A)))
        .split('\n')
        .where((line) => !line.trim().startsWith('#'))
        .toList();

    final dimensions = header[1].split(RegExp(r'\s+'));
    final width = int.parse(dimensions[0]);
    final height = int.parse(dimensions[1]);

    pixels = List.generate(height, (_) => List.filled(width, Colors.black));
    int index =
        bytes.indexOf(0x0A, bytes.indexOf(0x0A, bytes.indexOf(0x0A) + 1) + 1) +
            1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final grayValue = bytes[index++];
        pixels[y][x] = Color.fromARGB(255, grayValue, grayValue, grayValue);
      }
    }
  }

  @override
  String get extension => 'pgm';
}
