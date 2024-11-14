import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/config/injectable/injectable.dart';
import 'package:flutter_paint/src/presentation/logic/image_processing_cubit.dart';

class ImageProcessingScreen extends StatelessWidget {
  const ImageProcessingScreen(
      {super.key, required this.imageBytes, required this.callback});

  final Uint8List imageBytes;
  final void Function(ui.Image? image, Uint8List? pixels, int width, int height) callback;

  @override
  Widget build(BuildContext context) {
    final cubit = locator<ImageProcessingCubit>();
    return BlocProvider(
      create: (_) => cubit..loadImage(imageBytes),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Image Processing'),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: BlocBuilder<ImageProcessingCubit, ImageProcessingState>(
            builder: (context, state) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Original Image
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Original Image'),
                                if (state is ImageLoaded ||
                                    state is ImageProcessed)
                                  Image.memory(imageBytes)
                                else
                                  const Text('Loading...'),
                              ],
                            ),
                          ),
                          // Processed Image
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Processed Image'),
                                if (state is ImageProcessed)
                                  Image.memory(state.imageBytes)
                                else
                                  const Text('No Image Processed'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const ControlPanelContent(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => cubit.restart,
                            child: const Text('Reset'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await cubit.set();
                              if (result == null) return;
                              callback(result.$1, result.$2, result.$3, result.$4);
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ControlPanelContent extends StatefulWidget {
  const ControlPanelContent({super.key});

  @override
  State<ControlPanelContent> createState() => _ControlPanelContentState();
}

class _ControlPanelContentState extends State<ControlPanelContent> {
  double redValue = 0;
  double greenValue = 0;
  double blueValue = 0;
  double brightness = 0;

  String grayscaleMethod = 'average';
  List<List<int>> mask = [
    [0, -1, 0],
    [-1, 4, -1],
    [0, -1, 0],
  ];

  int divisor = 1;
  int offset = 0;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ImageProcessingCubit>();
    return SingleChildScrollView(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: Divider(),
          ),
          _buildRGBControls(cubit),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: Divider(),
          ),
          _buildBrightnessControl(cubit),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: Divider(),
          ),
          _buildGrayscaleControls(cubit),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: Divider(),
          ),
          _buildFilterControls(cubit),
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: Divider(),
          ),
        ],
      ),
    );
  }

  Widget _buildRGBControls(ImageProcessingCubit cubit) {
    return Column(
      children: [
        const Text('RGB Operations'),
        _buildSlider(
          label: "Red",
          value: redValue,
          onChanged: (value) => setState(() => redValue = value),
        ),
        _buildSlider(
          label: "Green",
          value: greenValue,
          onChanged: (value) => setState(() => greenValue = value),
        ),
        _buildSlider(
          label: "Blue",
          value: blueValue,
          onChanged: (value) => setState(() => blueValue = value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => cubit.addRGB(
                  redValue.toInt(), greenValue.toInt(), blueValue.toInt()),
              child: const Text('Add RGB'),
            ),
            ElevatedButton(
              onPressed: () => cubit.subtractRGB(
                  redValue.toInt(), greenValue.toInt(), blueValue.toInt()),
              child: const Text('Subtract RGB'),
            ),
            ElevatedButton(
              onPressed: () => cubit.multiplyRGB(
                  redValue / 255, greenValue / 255, blueValue / 255),
              child: const Text('Multiply RGB'),
            ),
            ElevatedButton(
              onPressed: () => cubit.divideRGB(
                  redValue / 255, greenValue / 255, blueValue / 255),
              child: const Text('Divide RGB'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBrightnessControl(ImageProcessingCubit cubit) {
    return Column(
      children: [
        const Text('Brightness'),
        _buildSlider(
          label: "Brightness",
          value: brightness,
          onChanged: (value) => setState(() => brightness = value),
        ),
        ElevatedButton(
          onPressed: () => cubit.adjustBrightness(brightness.toInt()),
          child: const Text('Apply Brightness'),
        ),
      ],
    );
  }

  Widget _buildGrayscaleControls(ImageProcessingCubit cubit) {
    return Column(
      children: [
        const Text('Grayscale Conversion'),
        DropdownButton<String>(
          value: grayscaleMethod,
          items: const [
            DropdownMenuItem(value: 'average', child: Text('Average')),
            DropdownMenuItem(value: 'red', child: Text('Red Channel')),
            DropdownMenuItem(value: 'green', child: Text('Green Channel')),
            DropdownMenuItem(value: 'blue', child: Text('Blue Channel')),
            DropdownMenuItem(value: 'max', child: Text('Max RGB')),
            DropdownMenuItem(value: 'min', child: Text('Min RGB')),
          ],
          onChanged: (value) =>
              setState(() => grayscaleMethod = value ?? 'average'),
        ),
        ElevatedButton(
          onPressed: () => cubit.grayscale(grayscaleMethod),
          child: const Text('Apply Grayscale'),
        ),
      ],
    );
  }

  Widget _buildFilterControls(ImageProcessingCubit cubit) {
    return Column(
      children: [
        const Text('Filter Operations'),
        const Text('Mask Values'),
        TextField(
          onChanged: (value) {
            // Parse the input into a 2D mask
            // For simplicity, you can add more UI components to define masks
          },
          decoration: const InputDecoration(hintText: 'Enter mask row by row'),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) =>
                    setState(() => divisor = int.tryParse(value) ?? 1),
                decoration: const InputDecoration(labelText: 'Divisor'),
                keyboardType: TextInputType.number,
              ),
            ),
            Expanded(
              child: TextField(
                onChanged: (value) =>
                    setState(() => offset = int.tryParse(value) ?? 0),
                decoration: const InputDecoration(labelText: 'Offset'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () => cubit.applyFilter(mask, divisor, offset),
          child: const Text('Apply Filter'),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Row(
      children: [
        Text(label),
        Expanded(
          child: Slider(
            value: value,
            min: -255,
            max: 255,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
