import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/config/injectable/injectable.dart';
import 'package:flutter_paint/src/presentation/logic/image_editor_cubit.dart';
import 'dart:typed_data';

class ImageEditorPage extends StatelessWidget {
  const ImageEditorPage({
    super.key,
    required this.imageBytes,
    required this.callback,
  });

  final Uint8List imageBytes;
  final void Function(ui.Image? image, Uint8List? pixels, int width, int height)
      callback;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ImageEditorCubit>()..loadImage(imageBytes),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Image Editor'),
        ),
        body: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: ImageEditorView(),
        ),
      ),
    );
  }
}

class ImageEditorView extends StatelessWidget {
  const ImageEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            BlocBuilder<ImageEditorCubit, ImageEditorState>(
              builder: (context, state) {
                if (state is ImageEditorInitial) {
                  return const Center(
                    child: Text('Loading...'),
                  );
                } else if (state is ImageLoaded || state is ImageProcessed) {
                  final originalImage = state is ImageProcessed
                      ? state.originalImage
                      : (state as ImageLoaded).originalImage;
                  final processedImage =
                      state is ImageProcessed ? state.processedImage : null;

                  return Row(
                    children: [
                      Flexible(
                        child: Column(
                          children: [
                            const Text('Original Image'),
                            Image.memory(
                              originalImage,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Column(
                          children: [
                            const Text('Processed Image'),
                            processedImage == null
                                ? const Align(
                                    child: Text('No Image Processed'),
                                  )
                                : Image.memory(
                                    processedImage,
                                    fit: BoxFit.contain,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else if (state is ImageEditorError) {
                  return Center(
                    child: Text(
                      'Error: ${state.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocBuilder<ImageEditorCubit, ImageEditorState>(
                builder: (context, state) {
                  if (state is ImageLoaded || state is ImageProcessed) {
                    return Wrap(
                      spacing: 8.0,
                      children: [
                        ElevatedButton(
                          onPressed: () => context
                              .read<ImageEditorCubit>()
                              .stretchHistogram(),
                          child: const Text('Stretch Histogram'),
                        ),
                        ElevatedButton(
                          onPressed: () => context
                              .read<ImageEditorCubit>()
                              .equalizeHistogram(),
                          child: const Text('Equalize Histogram'),
                        ),
                        ElevatedButton(
                          onPressed: () => context
                              .read<ImageEditorCubit>()
                              .manualThreshold(128),
                          child: const Text('Manual Threshold'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<ImageEditorCubit>().otsuThreshold(),
                          child: const Text('Otsu Threshold'),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
