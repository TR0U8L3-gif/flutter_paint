part of 'image_processing_cubit.dart';

abstract class ImageProcessingState {}

class ImageProcessingInitial extends ImageProcessingState {}

class ImageLoaded extends ImageProcessingState {
  final Uint8List imageBytes;
  ImageLoaded({required this.imageBytes});
}

class ImageProcessed extends ImageProcessingState {
  final Uint8List imageBytes;
  ImageProcessed({required this.imageBytes});
}
