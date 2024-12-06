import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/src/presentation/logic/bezier_cubit.dart';
class BezierPage extends StatefulWidget {
  const BezierPage({
    super.key,
    required this.imageBytes,
    required this.callback,
  });

  final Uint8List imageBytes;
  final void Function(ui.Image? image, Uint8List? pixels, int width, int height)
      callback;

  @override
  _BezierPageState createState() => _BezierPageState();
}

class _BezierPageState extends State<BezierPage> {
  ui.Image? _backgroundImage;

  // Kontrolery tekstowe
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _backgroundImage = frame.image;
    });
    widget.callback(_backgroundImage, widget.imageBytes, frame.image.width, frame.image.height);
  }

  void _setBezierDegree(BuildContext context) {
    final degree = int.tryParse(_degreeController.text);
    if (degree != null && degree >= 1) {
      context.read<BezierCubit>().setBezierDegree(degree);
    } else {
      _showErrorDialog(context, 'Enter correct bezier degree (number >= 1).');
    }
  }

  void _addPointFromInput(BuildContext context) {
    final xValue = double.tryParse(_xController.text);
    final yValue = double.tryParse(_yController.text);

    if (xValue != null && yValue != null) {
      final size = MediaQuery.of(context).size;
      if (xValue >= 0 && xValue <= size.width && yValue >= 0 && yValue <= size.height) {
        context.read<BezierCubit>().addControlPoint(Offset(xValue, yValue));
        _xController.clear();
        _yController.clear();
      } else {
        _showErrorDialog(context, 'You must enter X and Y values that are inside view.');
      }
    } else {
      _showErrorDialog(context, 'Enter valid X and Y values.');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bezier Curve')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _xController,
                        decoration: const InputDecoration(
                          labelText: 'X (px)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _yController,
                        decoration: const InputDecoration(
                          labelText: 'Y (px)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _addPointFromInput(context),
                      child: const Text('Dodaj Punkt'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _degreeController,
                        decoration: const InputDecoration(
                          labelText: 'Stopień krzywej',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _setBezierDegree(context),
                      child: const Text('Ustaw Stopień'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                final Offset position = details.localPosition;
                context.read<BezierCubit>().addControlPoint(position);
              },
              onPanStart: (details) {
                context.read<BezierCubit>().updateControlPointAtPosition(details.localPosition);
              },
              onPanUpdate: (details) {
                context.read<BezierCubit>().updateControlPointAtPosition(details.localPosition);
              },
              child: BlocBuilder<BezierCubit, BezierState>(
                builder: (context, state) {
                  return CustomPaint(
                    painter: BezierPainter(
                      controlPoints: state.controlPoints,
                      bezierCurve: state.bezierCurve,
                      backgroundImage: _backgroundImage,
                    ),
                    child: Container(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final cubit = context.read<BezierCubit>();
          if (cubit.state.controlPoints.isNotEmpty) {
            cubit.removeControlPoint(cubit.state.controlPoints.length - 1);
          }
        },
        child: const Icon(Icons.undo),
      ),
    );
  }
}

class BezierPainter extends CustomPainter {
  final List<Offset> controlPoints;
  final List<Offset> bezierCurve;
  final ui.Image? backgroundImage;

  BezierPainter({
    required this.controlPoints,
    required this.bezierCurve,
    required this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Rysowanie obrazu tła
    if (backgroundImage != null) {
      paintBackgroundImage(canvas, size);
    }

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final bezierPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Rysowanie punktów kontrolnych i połączeń
    for (int i = 0; i < controlPoints.length; i++) {
      canvas.drawCircle(controlPoints[i], 8.0, pointPaint);
      if (i < controlPoints.length - 1) {
        canvas.drawLine(controlPoints[i], controlPoints[i + 1], linePaint);
      }
    }

    // Rysowanie krzywej Béziera
    if (bezierCurve.isNotEmpty) {
      for (int i = 0; i < bezierCurve.length - 1; i++) {
        canvas.drawLine(bezierCurve[i], bezierCurve[i + 1], bezierPaint);
      }
    }
  }

  void paintBackgroundImage(Canvas canvas, Size size) {
    final paint = Paint();
    final src = Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(), backgroundImage!.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(backgroundImage!, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
