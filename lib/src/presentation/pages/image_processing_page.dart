import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/config/injectable/injectable.dart';
import 'package:flutter_paint/src/presentation/logic/image_processing_cubit.dart';

class ImageProcessingScreen extends StatelessWidget {
  const ImageProcessingScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

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
          padding: const EdgeInsets.all(16.0),
          child: BlocBuilder<ImageProcessingCubit, ImageProcessingState>(
            builder: (context, state) {
          
              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Original Image
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Original Image'),
                              if (state is ImageLoaded || state is ImageProcessed)
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
                  ),
                  ControlPanelContent(
                    onApplyTransformation: (red, green, blue, brightness) {
                      cubit.applyTransformation(
                        redValue: red,
                        greenValue: green,
                        blueValue: blue,
                        brightness: brightness,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ControlPanelContent extends StatefulWidget {
  final Function(double red, double green, double blue, double brightness)
      onApplyTransformation;

  const ControlPanelContent({
    Key? key,
    required this.onApplyTransformation,
  }) : super(key: key);

  @override
  _ControlPanelContentState createState() => _ControlPanelContentState();
}

class _ControlPanelContentState extends State<ControlPanelContent> {
  double redValue = 0;
  double greenValue = 0;
  double blueValue = 0;
  double brightness = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        _buildSlider(
          label: "Brightness",
          value: brightness,
          onChanged: (value) => setState(() => brightness = value),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApplyTransformation(redValue, greenValue, blueValue, brightness);
          },
          child: const Text('Apply Transformation'),
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

