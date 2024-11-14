part of 'image_editor_cubit.dart';

@immutable
abstract class ImageEditorState {}

class ImageEditorInitial extends ImageEditorState {}

class ImageLoaded extends ImageEditorState {
  final Uint8List originalImage;

  ImageLoaded(this.originalImage);
}

class ImageProcessed extends ImageEditorState {
  final Uint8List originalImage;
  final Uint8List processedImage;

  ImageProcessed(this.originalImage, this.processedImage);
}

class ImageEditorError extends ImageEditorState {
  final String error;

  ImageEditorError(this.error);
}
