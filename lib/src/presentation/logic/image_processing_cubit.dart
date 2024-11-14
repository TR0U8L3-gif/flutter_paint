import 'package:bloc/bloc.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  Future<void> applyFilter(
      List<List<int>> mask, int divisor, int offset) async {
    // Filtering logic with mask convolution
    if (originalImageBytes == null) return;

    final codec = await ui.instantiateImageCodec(originalImageBytes!);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception("Failed to retrieve pixel data.");

    final pixels = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    final newPixels = Uint8List.fromList(pixels);

    final maskHeight = mask.length;
    final maskWidth = mask[0].length;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int r = 0, g = 0, b = 0;

        for (int i = 0; i < maskHeight; i++) {
          for (int j = 0; j < maskWidth; j++) {
            final px = (y + i - maskHeight ~/ 2) * width * 4 +
                (x + j - maskWidth ~/ 2) * 4;
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

  Future<void> _processImage(Function(List<int>) processPixel) async {
    if (originalImageBytes == null) return;

    final codec = await ui.instantiateImageCodec(originalImageBytes!);
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

  Future<(ui.Image? image, Uint8List? pixels, int width, int height)?> set() async {
    if (originalImageBytes == null) return null;
    final codec = await ui.instantiateImageCodec(originalImageBytes!);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width;
    final height = image.height;
    final pixels = (state as ImageProcessed).imageBytes;
    return (image, pixels, width, height);
  }
}
