import 'package:bloc/bloc.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

part 'image_processing_state.dart';

@injectable
class ImageProcessingCubit extends Cubit<ImageProcessingState> {
  ImageProcessingCubit() : super(ImageProcessingInitial());

  Uint8List? originalImageBytes;
  Uint8List? processedImageBytes;

  void loadImage(Uint8List imageBytes) {
    originalImageBytes = imageBytes;
    emit(ImageLoaded(imageBytes: imageBytes));
  }

  Future<void> addRGB(int red, int green, int blue) async {
    await _processImage((pixel) {
      pixel[0] = (pixel[0] + red).clamp(0, 255);
      pixel[1] = (pixel[1] + green).clamp(0, 255);
      pixel[2] = (pixel[2] + blue).clamp(0, 255);
    });
  }

  Future<void> subtractRGB(int red, int green, int blue) async {
    await _processImage((pixel) {
      pixel[0] = (pixel[0] - red).clamp(0, 255);
      pixel[1] = (pixel[1] - green).clamp(0, 255);
      pixel[2] = (pixel[2] - blue).clamp(0, 255);
    });
  }

  Future<void> multiplyRGB(
      double redFactor, double greenFactor, double blueFactor) async {
    await _processImage((pixel) {
      pixel[0] = (pixel[0] * redFactor).clamp(0, 255).toInt();
      pixel[1] = (pixel[1] * greenFactor).clamp(0, 255).toInt();
      pixel[2] = (pixel[2] * blueFactor).clamp(0, 255).toInt();
    });
  }

  Future<void> divideRGB(
      double redDivisor, double greenDivisor, double blueDivisor) async {
    await _processImage((pixel) {
      pixel[0] = (pixel[0] / redDivisor).clamp(0, 255).toInt();
      pixel[1] = (pixel[1] / greenDivisor).clamp(0, 255).toInt();
      pixel[2] = (pixel[2] / blueDivisor).clamp(0, 255).toInt();
    });
  }

  Future<void> adjustBrightness(int brightness) async {
    await _processImage((pixel) {
      for (int i = 0; i < 3; i++) {
        pixel[i] = (pixel[i] + brightness).clamp(0, 255);
      }
    });
  }

  Future<void> grayscale(String method) async {
    await _processImage((pixel) {
      int gray;
      switch (method) {
        case 'average':
          gray = ((pixel[0] + pixel[1] + pixel[2]) / 3).toInt();
          break;
        case 'red':
          gray = pixel[0];
          break;
        case 'green':
          gray = pixel[1];
          break;
        case 'blue':
          gray = pixel[2];
          break;
        case 'max':
          gray = [pixel[0], pixel[1], pixel[2]].reduce((a, b) => a > b ? a : b);
          break;
        case 'min':
          gray = [pixel[0], pixel[1], pixel[2]].reduce((a, b) => a < b ? a : b);
          break;
        default:
          gray = ((pixel[0] + pixel[1] + pixel[2]) / 3).toInt();
      }
      pixel[0] = gray;
      pixel[1] = gray;
      pixel[2] = gray;
    });
  }

  Future<void> applySmoothingFilter() async {
    // Filtr wygładzający
    final smoothingMask = [
      [1, 1, 1],
      [1, 1, 1],
      [1, 1, 1],
    ];
    await applyFilter(smoothingMask, divisor: 9, offset: 0);
  }

  Future<void> applyMedianFilter() async {
    // Filtr medianowy
    final imageBytes = processedImageBytes ?? originalImageBytes;
    if (imageBytes == null) return;

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to retrieve pixel data.");

    final pixels = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    final newPixels = Uint8List.fromList(pixels);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        List<int> rValues = [];
        List<int> gValues = [];
        List<int> bValues = [];

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final index = ((y + dy) * width + (x + dx)) * 4;
            rValues.add(pixels[index]);
            gValues.add(pixels[index + 1]);
            bValues.add(pixels[index + 2]);
          }
        }

        rValues.sort();
        gValues.sort();
        bValues.sort();

        final medianIndex = rValues.length ~/ 2;
        final newIndex = (y * width + x) * 4;
        newPixels[newIndex] = rValues[medianIndex];
        newPixels[newIndex + 1] = gValues[medianIndex];
        newPixels[newIndex + 2] = bValues[medianIndex];
      }
    }

    ui.decodeImageFromPixels(
      newPixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (result) async {
        final pngByteData =
            await result.toByteData(format: ui.ImageByteFormat.png);
        processedImageBytes = pngByteData!.buffer.asUint8List();
        emit(ImageProcessed(imageBytes: processedImageBytes!));
      },
    );
  }

  Future<void> applySobelFilter() async {
    // Filtr Sobela
    final sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    final sobelY = [
      [1, 2, 1],
      [0, 0, 0],
      [-1, -2, -1],
    ];
    await applyCombinedFilters(sobelX, sobelY);
  }

  Future<void> applySharpeningFilter() async {
    // Filtr wyostrzający
    final sharpeningMask = [
      [0, -1, 0],
      [-1, 5, -1],
      [0, -1, 0],
    ];
    await applyFilter(sharpeningMask, divisor: 1, offset: 0);
  }

  Future<void> applyGaussianBlur() async {
    // Rozmycie Gaussowskie
    final gaussianMask = [
      [1, 2, 1],
      [2, 4, 2],
      [1, 2, 1],
    ];
    await applyFilter(gaussianMask, divisor: 16, offset: 0);
  }

  Future<void> applyFilter(
    List<List<int>> mask, {
    required int divisor,
    required int offset,
  }) async {
    // Filtracja splotowa z maską
    final imageBytes = processedImageBytes ?? originalImageBytes;
    if (imageBytes == null) return;

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to retrieve pixel data.");

    final pixels = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    final newPixels = Uint8List.fromList(pixels);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int r = 0, g = 0, b = 0;

        for (int i = 0; i < mask.length; i++) {
          for (int j = 0; j < mask[0].length; j++) {
            final px = (y + i - mask.length ~/ 2) * width * 4 +
                (x + j - mask[0].length ~/ 2) * 4;
            if (px < 0 || px >= pixels.length) continue;

            r += pixels[px] * mask[i][j];
            g += pixels[px + 1] * mask[i][j];
            b += pixels[px + 2] * mask[i][j];
          }
        }

        final index = y * width * 4 + x * 4;
        newPixels[index] = (r ~/ divisor + offset).clamp(0, 255);
        newPixels[index + 1] = (g ~/ divisor + offset).clamp(0, 255);
        newPixels[index + 2] = (b ~/ divisor + offset).clamp(0, 255);
      }
    }

    ui.decodeImageFromPixels(
      newPixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (result) async {
        final pngByteData =
            await result.toByteData(format: ui.ImageByteFormat.png);
        processedImageBytes = pngByteData!.buffer.asUint8List();
        emit(ImageProcessed(imageBytes: processedImageBytes!));
      },
    );
  }

  Future<void> applyCombinedFilters(
    List<List<int>> maskX,
    List<List<int>> maskY,
  ) async {
    // Kombinacja dwóch masek (np. Sobel X i Y)
    final imageBytes = processedImageBytes ?? originalImageBytes;
    if (imageBytes == null) return;

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to retrieve pixel data.");

    final pixels = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    final newPixels = Uint8List.fromList(pixels);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int rX = 0, gX = 0, bX = 0;
        int rY = 0, gY = 0, bY = 0;

        for (int i = 0; i < maskX.length; i++) {
          for (int j = 0; j < maskX[0].length; j++) {
            final px = (y + i - maskX.length ~/ 2) * width * 4 +
                (x + j - maskX[0].length ~/ 2) * 4;
            if (px < 0 || px >= pixels.length) continue;

            rX += pixels[px] * maskX[i][j];
            gX += pixels[px + 1] * maskX[i][j];
            bX += pixels[px + 2] * maskX[i][j];

            rY += pixels[px] * maskY[i][j];
            gY += pixels[px + 1] * maskY[i][j];
            bY += pixels[px + 2] * maskY[i][j];
          }
        }

        final r = (rX.abs() + rY.abs()).clamp(0, 255);
        final g = (gX.abs() + gY.abs()).clamp(0, 255);
        final b = (bX.abs() + bY.abs()).clamp(0, 255);

        final index = y * width * 4 + x * 4;
        newPixels[index] = r;
        newPixels[index + 1] = g;
        newPixels[index + 2] = b;
      }
    }
    ui.decodeImageFromPixels(
      newPixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (result) async {
        final pngByteData =
            await result.toByteData(format: ui.ImageByteFormat.png);
        processedImageBytes = pngByteData!.buffer.asUint8List();
        emit(ImageProcessed(imageBytes: processedImageBytes!));
      },
    );
  }

  Future<void> _processImage(Function(List<int>) processPixel) async {
    final imageBytes = processedImageBytes ?? originalImageBytes;
    if (imageBytes == null) return;

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to retrieve pixel data.");

    final pixels = byteData.buffer.asUint8List();
    for (int i = 0; i < pixels.length; i += 4) {
      final pixel = [pixels[i], pixels[i + 1], pixels[i + 2]];
      processPixel(pixel);
      pixels[i] = pixel[0];
      pixels[i + 1] = pixel[1];
      pixels[i + 2] = pixel[2];
    }

    ui.decodeImageFromPixels(
      pixels,
      image.width,
      image.height,
      ui.PixelFormat.rgba8888,
      (result) async {
        final pngByteData =
            await result.toByteData(format: ui.ImageByteFormat.png);
        processedImageBytes = pngByteData!.buffer.asUint8List();
        emit(ImageProcessed(imageBytes: processedImageBytes!));
      },
    );
  }

  void restart() {
    if (originalImageBytes == null) return;
    processedImageBytes = originalImageBytes;
    emit(ImageProcessed(imageBytes: processedImageBytes!));
  }

  Future<(ui.Image, Uint8List, int width, int height)?> set() async {
    final imageBytes = processedImageBytes ?? originalImageBytes;
    if (imageBytes == null) return null;

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    return (image, imageBytes, image.width, image.height);
  }
}
