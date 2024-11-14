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
}
