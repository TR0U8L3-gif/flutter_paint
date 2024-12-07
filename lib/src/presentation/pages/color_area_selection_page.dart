import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/core/common/presentation/logic/theme_provider.dart';
import 'package:flutter_paint/src/presentation/logic/color_area_selection_cubit.dart';

class ColorAreaSelectionPage extends StatefulWidget {
  const ColorAreaSelectionPage({
    required this.imageBytes,
    required this.callback,
    super.key,
  });

  final Uint8List imageBytes;
  final void Function(ui.Image? image, Uint8List? pixels, int width, int height)
      callback;

  @override
  State<ColorAreaSelectionPage> createState() => _ColorAreaSelectionPageState();
}

class _ColorAreaSelectionPageState extends State<ColorAreaSelectionPage> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ColorAreaSelectionCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Processing"),
        actions: [
          IconButton(
            onPressed: context.read<ThemeProvider>().toggleTheme,
            icon: const Icon(Icons.brightness_medium_sharp),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<ColorAreaSelectionCubit, Uint8List?>(
        bloc: cubit,
        builder: (context, processedImage) {
          return Center(
            child: processedImage != null
                ? Image.memory(processedImage)
                : Image.memory(widget.imageBytes),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(context, cubit),
    );
  }

  Widget _buildFloatingActionButtons(
      BuildContext context, ColorAreaSelectionCubit cubit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "picked color",
          onPressed: null,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cubit.selectedColor ?? Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "color",
          onPressed: () async {
            // Wybierz kolor z canvas
            final pickedColor = await _pickColorFromCanvas(context);
            if (pickedColor != null) {
              setState(() {
                cubit.setSelectedColor(pickedColor);
              });
            }
          },
          child: const Icon(Icons.colorize),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "threshold",
          onPressed: () async {
            final threshold = await _showThresholdDialog(context);
            cubit.setThreshold(threshold);
          },
          child: const Icon(Icons.tune),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "reset",
          onPressed: () => cubit.resetImage(),
          child: const Icon(Icons.refresh),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "process",
          onPressed: () => cubit.processImage(),
          child: const Icon(Icons.check),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "process largest group",
          onPressed: () => cubit.processLargestGroup(),
          child: const Icon(Icons.check),
        ),
      ],
    );
  }

  Future<ui.Color?> _pickColorFromCanvas(BuildContext context) async {
    final cubit = context.read<ColorAreaSelectionCubit>();
    if (cubit.modifiedImage == null) return null;

    // Dekodowanie obrazu tylko raz.
    final ui.Codec codec = await ui.instantiateImageCodec(cubit.modifiedImage!);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    // Pobranie danych pikseli obrazu.
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return null;

    // Wyświetlenie dialogu do wyboru koloru.
    return await showDialog<ui.Color>(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final imageAspectRatio = image.width / image.height;
        final imageHeight = screenHeight * 0.5;
        final imageWidth = imageHeight * imageAspectRatio;

        return AlertDialog(
          title: const Text("Pick a color from the image"),
          content: GestureDetector(
            onPanDown: (details) {
              // Przeliczenie pozycji kliknięcia na współrzędne obrazu.
              final localPosition = details.localPosition;

              final dx = (localPosition.dx / imageWidth) * image.width;
              final dy = (localPosition.dy / imageHeight) * image.height;

              // Sprawdzenie, czy współrzędne są w granicach obrazu.
              if (dx >= 0 && dx < image.width && dy >= 0 && dy < image.height) {
                final color = _getColorFromPixels(
                    byteData, image.width, dx.toInt(), dy.toInt());
                Navigator.pop(context, color);
              }
            },
            child: CustomPaint(
              size: Size(imageWidth, imageHeight),
              painter: _ImagePainter(image),
            ),
          ),
        );
      },
    );
  }

// Funkcja do pobierania koloru z danych pikseli.
  ui.Color _getColorFromPixels(
      ByteData byteData, int imageWidth, int x, int y) {
    final int index = (y * imageWidth + x) * 4;
    final Uint8List pixels = byteData.buffer.asUint8List();

    return ui.Color.fromARGB(
      pixels[index + 3], // Alpha
      pixels[index], // Red
      pixels[index + 1], // Green
      pixels[index + 2], // Blue
    );
  }

  Future<double> _showThresholdDialog(BuildContext context) async {
    double threshold = 5.0;
    final TextEditingController textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Threshold"),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter threshold (0-255)",
            ),
            onSubmitted: (value) {
              threshold = double.tryParse(value) ?? threshold;
              threshold = threshold.clamp(0, 255);
              Navigator.pop(context);
            },
          ),
        );
      },
    );

    // Upewniamy się, że threshold jest poprawny po zamknięciu dialogu
    final inputValue = double.tryParse(textController.text);
    if (inputValue != null && inputValue >= 0 && inputValue <= 255) {
      threshold = inputValue;
    }

    return threshold;
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
