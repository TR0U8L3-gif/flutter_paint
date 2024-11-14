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

  void loadImage(Uint8List imageBytes) {
    originalImageBytes = imageBytes;
    emit(ImageLoaded(imageBytes: imageBytes));
  }

  void applyTransformation({
    required double redValue,
    required double greenValue,
    required double blueValue,
    required double brightness,
  }) async {
    if (originalImageBytes == null) return;

    try {
      // Decode original image
      final codec = await ui.instantiateImageCodec(originalImageBytes!);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Extract pixel data
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw Exception("Failed to retrieve pixel data.");
      }

      final Uint8List pixelBytes = byteData.buffer.asUint8List();

      // Run the pixel transformation in an isolate
      final transformedPixels = await compute(
        modifyPixelData,
        TransformationParams(
          imageBytes: pixelBytes,
          redValue: redValue,
          greenValue: greenValue,
          blueValue: blueValue,
        ),
      );

      // Convert back to image and emit new state
      ui.decodeImageFromPixels(
        transformedPixels,
        image.width,
        image.height,
        ui.PixelFormat.rgba8888,
        (result) async {
          final pngByteData =
              await result.toByteData(format: ui.ImageByteFormat.png);
          emit(ImageProcessed(imageBytes: pngByteData!.buffer.asUint8List()));
        },
      );
    } catch (e) {
      print("Error during transformation: $e");
    }
  }
}

// Data class for passing transformation parameters
class TransformationParams {
  final Uint8List imageBytes;
  final double redValue;
  final double greenValue;
  final double blueValue;

  TransformationParams({
    required this.imageBytes,
    required this.redValue,
    required this.greenValue,
    required this.blueValue,
  });
}

// Isolate computation function
Uint8List modifyPixelData(TransformationParams params) {
  final imageBytes = params.imageBytes;
  final redValue = params.redValue;
  final greenValue = params.greenValue;
  final blueValue = params.blueValue;

  final pixels = Uint8List.fromList(imageBytes);

  for (int i = 0; i < pixels.length; i += 4) {
    pixels[i] = (pixels[i] + redValue).clamp(0, 255).toInt(); // R
    pixels[i + 1] = (pixels[i + 1] + greenValue).clamp(0, 255).toInt(); // G
    pixels[i + 2] = (pixels[i + 2] + blueValue).clamp(0, 255).toInt(); // B
  }

  return pixels;
}
