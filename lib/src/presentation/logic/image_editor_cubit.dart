import 'dart:async';

import 'package:bloc/bloc.dart';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

part 'image_editor_state.dart';

@injectable
class ImageEditorCubit extends Cubit<ImageEditorState> {
  Uint8List? originalImage; // Oryginalny obraz jako Uint8List
  Uint8List? processedImage; // Przetworzony obraz jako Uint8List

  ImageEditorCubit() : super(ImageEditorInitial());

  /// Wczytaj obraz (z Uint8List)
  void loadImage(Uint8List imageData) async {
    try {
      originalImage = imageData;
      processedImage = Uint8List.fromList(imageData); // Kopia obrazu
      emit(ImageLoaded(originalImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się wczytać obrazu: $e"));
    }
  }

  /// Rozciągnięcie histogramu
  void stretchHistogram() async {
    if (originalImage == null) {
      emit(ImageEditorError("Brak obrazu do przetwarzania."));
      return;
    }

    try {
      final ui.Image image = await _decodeImageFromUint8List(originalImage!);
      final stretchedImage = await _stretchHistogram(image);
      processedImage = await _encodeImageToUint8List(stretchedImage);
      emit(ImageProcessed(originalImage!, processedImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się przetworzyć obrazu: $e"));
    }
  }

  /// Wyrównanie histogramu
  void equalizeHistogram() async {
    if (originalImage == null) {
      emit(ImageEditorError("Brak obrazu do przetwarzania."));
      return;
    }

    try {
      final ui.Image image = await _decodeImageFromUint8List(originalImage!);
      final equalizedImage = await _equalizeHistogram(image);
      processedImage = await _encodeImageToUint8List(equalizedImage);
      emit(ImageProcessed(originalImage!, processedImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się przetworzyć obrazu: $e"));
    }
  }

  /// Binaryzacja ręczna
  void manualThreshold(int threshold) async {
    if (originalImage == null) {
      emit(ImageEditorError("Brak obrazu do przetwarzania."));
      return;
    }

    try {
      final ui.Image image = await _decodeImageFromUint8List(originalImage!);
      final binaryImage = await _applyThreshold(image, threshold);
      processedImage = await _encodeImageToUint8List(binaryImage);
      emit(ImageProcessed(originalImage!, processedImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się przetworzyć obrazu: $e"));
    }
  }

  /// Binaryzacja Otsu
  void otsuThreshold() async {
    if (originalImage == null) {
      emit(ImageEditorError("Brak obrazu do przetwarzania."));
      return;
    }

    try {
      final ui.Image image = await _decodeImageFromUint8List(originalImage!);
      final threshold = await _calculateOtsuThreshold(image);
      final binaryImage = await _applyThreshold(image, threshold);
      processedImage = await _encodeImageToUint8List(binaryImage);
      emit(ImageProcessed(originalImage!, processedImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się przetworzyć obrazu: $e"));
    }
  }

  /// Pomocnicza metoda: dekodowanie obrazu z Uint8List do ui.Image
  Future<ui.Image> _decodeImageFromUint8List(Uint8List data) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(data, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  /// Pomocnicza metoda: kodowanie obrazu z ui.Image do Uint8List
  Future<Uint8List> _encodeImageToUint8List(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Rozciągnięcie histogramu
  Future<ui.Image> _stretchHistogram(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null)
      throw Exception("Nie udało się pobrać danych obrazu.");

    Uint8List pixels = byteData.buffer.asUint8List();

    // Znajdź minimalną i maksymalną wartość
    int min = 255;
    int max = 0;
    for (int i = 0; i < pixels.length; i += 4) {
      final intensity = pixels[i];
      if (intensity < min) min = intensity;
      if (intensity > max) max = intensity;
    }

    // Przekształć wartości pikseli
    for (int i = 0; i < pixels.length; i += 4) {
      final intensity = pixels[i];
      final stretched = ((intensity - min) * 255 / (max - min)).round();
      pixels[i] = stretched; // R
      pixels[i + 1] = stretched; // G
      pixels[i + 2] = stretched; // B
    }

    return _createImageFromBytes(image.width, image.height, pixels);
  }

  /// Wyrównanie histogramu
  Future<ui.Image> _equalizeHistogram(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null)
      throw Exception("Nie udało się pobrać danych obrazu.");

    Uint8List pixels = byteData.buffer.asUint8List();
    List<int> histogram = List.filled(256, 0);
    List<int> cumulativeHistogram = List.filled(256, 0);

    // Tworzenie histogramu
    for (int i = 0; i < pixels.length; i += 4) {
      histogram[pixels[i]]++;
    }

    // Obliczanie histogramu skumulowanego
    cumulativeHistogram[0] = histogram[0];
    for (int i = 1; i < 256; i++) {
      cumulativeHistogram[i] = cumulativeHistogram[i - 1] + histogram[i];
    }

    // Normalizacja skumulowanego histogramu
    final totalPixels = image.width * image.height;
    List<int> lookupTable = cumulativeHistogram
        .map((value) => (255 * value / totalPixels).round())
        .toList();

    // Zastosowanie wyrównania histogramu
    for (int i = 0; i < pixels.length; i += 4) {
      final intensity = pixels[i];
      final equalized = lookupTable[intensity];
      pixels[i] = equalized; // R
      pixels[i + 1] = equalized; // G
      pixels[i + 2] = equalized; // B
    }

    return _createImageFromBytes(image.width, image.height, pixels);
  }

  /// Binaryzacja z progiem
  Future<ui.Image> _applyThreshold(ui.Image image, int threshold) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null)
      throw Exception("Nie udało się pobrać danych obrazu.");

    Uint8List pixels = byteData.buffer.asUint8List();

    for (int i = 0; i < pixels.length; i += 4) {
      final intensity = pixels[i];
      final binaryValue = intensity >= threshold ? 255 : 0;
      pixels[i] = binaryValue; // R
      pixels[i + 1] = binaryValue; // G
      pixels[i + 2] = binaryValue; // B
    }

    return _createImageFromBytes(image.width, image.height, pixels);
  }

  /// Obliczanie progu Otsu
  Future<int> _calculateOtsuThreshold(ui.Image image) async {
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null)
      throw Exception("Nie udało się pobrać danych obrazu.");

    Uint8List pixels = byteData.buffer.asUint8List();
    List<int> histogram = List.filled(256, 0);

    // Tworzenie histogramu
    for (int i = 0; i < pixels.length; i += 4) {
      histogram[pixels[i]]++;
    }

    final totalPixels = image.width * image.height;
    int sumB = 0, wB = 0, wF = 0;
    double maxVar = 0.0;
    int threshold = 0;
    int sum1 = 0;

    for (int i = 0; i < 256; i++) {
      sum1 += i * histogram[i];
    }

    for (int t = 0; t < 256; t++) {
      wB += histogram[t];
      if (wB == 0) continue;

      wF = totalPixels - wB;
      if (wF == 0) break;

      sumB += t * histogram[t];
      final mB = sumB / wB;
      final mF = (sum1 - sumB) / wF;
      final betweenVar = wB * wF * (mB - mF) * (mB - mF);

      if (betweenVar > maxVar) {
        maxVar = betweenVar;
        threshold = t;
      }
    }

    return threshold;
  }

  /// Tworzenie ui.Image z pikseli
  Future<ui.Image> _createImageFromBytes(
      int width, int height, Uint8List pixels) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (ui.Image img) {
        completer.complete(img);
      },
    );
    return completer.future;
  }

  void niblack(int windowSize) async {
    if (originalImage == null) {
      emit(ImageEditorError("Brak obrazu do przetwarzania."));
      return;
    }

    try {
      final ui.Image image = await _decodeImageFromUint8List(originalImage!);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null)
        throw Exception("Nie udało się pobrać danych obrazu.");

      Uint8List pixels = byteData.buffer.asUint8List();
      Uint8List newPixels = Uint8List.fromList(pixels);

      final width = image.width;
      final height = image.height;
      final offset = windowSize ~/ 2;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          List<int> windowPixels = [];

          for (int wy = -offset; wy <= offset; wy++) {
            for (int wx = -offset; wx <= offset; wx++) {
              int nx = x + wx;
              int ny = y + wy;
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                int pixelIndex = (ny * width + nx) * 4;
                windowPixels.add(pixels[pixelIndex]);
              }
            }
          }

          final mean =
              windowPixels.reduce((a, b) => a + b) ~/ windowPixels.length;
          final stdDev = windowPixels.fold(
                0,
                (sum, p) => sum + ((p - mean) * (p - mean)),
              ) /
              windowPixels.length;

          final threshold = mean - (0.2 * stdDev).toInt();
          final pixelIndex = (y * width + x) * 4;
          final intensity = pixels[pixelIndex];
          final binaryValue = intensity >= threshold ? 255 : 0;

          newPixels[pixelIndex] = binaryValue;
          newPixels[pixelIndex + 1] = binaryValue;
          newPixels[pixelIndex + 2] = binaryValue;
        }
      }

      final binaryImage = await _createImageFromBytes(width, height, newPixels);
      processedImage = await _encodeImageToUint8List(binaryImage);
      emit(ImageProcessed(originalImage!, processedImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się przetworzyć obrazu: $e"));
    }
  }

  void sauvola(int windowSize) async {
    if (originalImage == null) {
      emit(ImageEditorError("Brak obrazu do przetwarzania."));
      return;
    }

    try {
      final ui.Image image = await _decodeImageFromUint8List(originalImage!);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null)
        throw Exception("Nie udało się pobrać danych obrazu.");

      Uint8List pixels = byteData.buffer.asUint8List();
      Uint8List newPixels = Uint8List.fromList(pixels);

      final width = image.width;
      final height = image.height;
      final offset = windowSize ~/ 2;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          List<int> windowPixels = [];

          for (int wy = -offset; wy <= offset; wy++) {
            for (int wx = -offset; wx <= offset; wx++) {
              int nx = x + wx;
              int ny = y + wy;
              if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                int pixelIndex = (ny * width + nx) * 4;
                windowPixels.add(pixels[pixelIndex]);
              }
            }
          }

          final mean =
              windowPixels.reduce((a, b) => a + b) ~/ windowPixels.length;
          final stdDev = windowPixels.fold(
                0,
                (sum, p) => sum + ((p - mean) * (p - mean)),
              ) /
              windowPixels.length;

          final threshold = mean * (1 + 0.2 * ((stdDev / 128.0) - 1));
          final pixelIndex = (y * width + x) * 4;
          final intensity = pixels[pixelIndex];
          final binaryValue = intensity >= threshold ? 255 : 0;

          newPixels[pixelIndex] = binaryValue;
          newPixels[pixelIndex + 1] = binaryValue;
          newPixels[pixelIndex + 2] = binaryValue;
        }
      }

      final binaryImage = await _createImageFromBytes(width, height, newPixels);
      processedImage = await _encodeImageToUint8List(binaryImage);
      emit(ImageProcessed(originalImage!, processedImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się przetworzyć obrazu: $e"));
    }
  }

  void meanIterativeSelection() async {
    if (originalImage == null) {
      emit(ImageEditorError("Brak obrazu do przetwarzania."));
      return;
    }

    try {
      final ui.Image image = await _decodeImageFromUint8List(originalImage!);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null)
        throw Exception("Nie udało się pobrać danych obrazu.");

      Uint8List pixels = byteData.buffer.asUint8List();

      // Iteracyjnie znajdowanie progu
      int threshold = 128;
      int newThreshold;
      do {
        int lowerSum = 0, lowerCount = 0;
        int upperSum = 0, upperCount = 0;

        for (int i = 0; i < pixels.length; i += 4) {
          int intensity = pixels[i];
          if (intensity < threshold) {
            lowerSum += intensity;
            lowerCount++;
          } else {
            upperSum += intensity;
            upperCount++;
          }
        }

        final lowerMean = lowerCount == 0 ? 0 : (lowerSum ~/ lowerCount);
        final upperMean = upperCount == 0 ? 0 : (upperSum ~/ upperCount);
        newThreshold = ((lowerMean + upperMean) ~/ 2);

        if (newThreshold == threshold) break;
        threshold = newThreshold;
      } while (true);

      final binaryImage = await _applyThreshold(image, threshold);
      processedImage = await _encodeImageToUint8List(binaryImage);
      emit(ImageProcessed(originalImage!, processedImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się przetworzyć obrazu: $e"));
    }
  }

  void percentBlackSelection(double percent) async {
    if (originalImage == null) {
      emit(ImageEditorError("Brak obrazu do przetwarzania."));
      return;
    }

    try {
      final ui.Image image = await _decodeImageFromUint8List(originalImage!);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      if (byteData == null)
        throw Exception("Nie udało się pobrać danych obrazu.");

      Uint8List pixels = byteData.buffer.asUint8List();
      int totalPixels = image.width * image.height;
      int blackPixelsTarget = (totalPixels * percent).round();

      // Histogram i znalezienie progu
      List<int> histogram = List.filled(256, 0);
      for (int i = 0; i < pixels.length; i += 4) {
        histogram[pixels[i]]++;
      }

      int cumulative = 0;
      int threshold = 0;
      for (int i = 0; i < 256; i++) {
        cumulative += histogram[i];
        if (cumulative >= blackPixelsTarget) {
          threshold = i;
          break;
        }
      }

      final binaryImage = await _applyThreshold(image, threshold);
      processedImage = await _encodeImageToUint8List(binaryImage);
      emit(ImageProcessed(originalImage!, processedImage!));
    } catch (e) {
      emit(ImageEditorError("Nie udało się przetworzyć obrazu: $e"));
    }
  }

    void restart() {
    if (originalImage == null) return;
    originalImage = originalImage;
    emit(ImageProcessed(originalImage!, originalImage!));
  }

  Future<(ui.Image, Uint8List, int width, int height)?> set() async {
    final imageBytes = processedImage ?? originalImage;
    if (imageBytes == null) return null;

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return (image, imageBytes, image.width, image.height);
  }
}
