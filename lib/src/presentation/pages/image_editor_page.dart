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
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ImageEditorView(
            callback: callback,
          ),
        ),
      ),
    );
  }
}

class ImageEditorView extends StatefulWidget {
  const ImageEditorView({super.key, required this.callback});

  final void Function(ui.Image? image, Uint8List? pixels, int width, int height)
      callback;

  @override
  State<ImageEditorView> createState() => _ImageEditorViewState();
}

class _ImageEditorViewState extends State<ImageEditorView> {
  int manualThresholdValue = 128; // Default value for manual threshold
  double percentBlack = 20.0; // Default percent for Percent Black Selection
  int windowSize = 15; // Default window size for Niblack/Sauvola

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
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 16),
              child: Divider(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('Histogram Operations'),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ImageEditorCubit>().stretchHistogram(),
                      child: const Text('Stretch Histogram'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ImageEditorCubit>().equalizeHistogram(),
                      child: const Text('Equalize Histogram'),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  child: Divider(),
                ),
                const Text('Global Binarization'),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () => context
                          .read<ImageEditorCubit>()
                          .manualThreshold(manualThresholdValue),
                      child: const Text('Manual Threshold'),
                    ),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ImageEditorCubit>()
                          .percentBlackSelection(percentBlack / 100),
                      child: const Text('Percent Black Selection'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ImageEditorCubit>().otsuThreshold(),
                      child: const Text('Otsu Threshold'),
                    ),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ImageEditorCubit>()
                          .meanIterativeSelection(),
                      child: const Text('Mean Iterative Selection'),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  child: Divider(),
                ),
                Text('Manual Threshold Value: $manualThresholdValue'),
                Slider(
                  value: manualThresholdValue.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 255,
                  label: manualThresholdValue.toString(),
                  onChanged: (double value) {
                    setState(() {
                      manualThresholdValue = value.toInt();
                    });
                  },
                  onChangeEnd: (_) => context
                      .read<ImageEditorCubit>()
                      .manualThreshold(manualThresholdValue),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  child: Divider(),
                ),
                const Text('Percent Black Selection (0-100)'),
                const SizedBox(height: 8.0),
                Slider(
                  value: percentBlack,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '$percentBlack%',
                  onChanged: (value) {
                    final percent = value;
                    if (percent >= 0 && percent <= 100) {
                      setState(() {
                        percentBlack = percent;
                      });
                    }
                  },
                  onChangeEnd: (_) => context
                      .read<ImageEditorCubit>()
                      .percentBlackSelection(percentBlack / 100),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  child: Divider(),
                ),
                const Text('Local Binarization'),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ImageEditorCubit>().niblack(windowSize),
                      child: const Text('Niblack'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ImageEditorCubit>().sauvola(windowSize),
                      child: const Text('Sauvola'),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Input Window Size ($windowSize)'),
                  onChanged: (value) {
                    final size = int.tryParse(value);
                    if (size != null && size > 0) {
                      setState(() {
                        windowSize = size;
                      });
                    }
                  },
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  child: Divider(),
                ),
                Wrap(
                  spacing: 8.0,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ImageEditorCubit>().restart(),
                      child: const Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final result =
                            await context.read<ImageEditorCubit>().set();
                        if (result == null) return;
                        widget.callback(
                            result.$1, result.$2, result.$3, result.$4);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
