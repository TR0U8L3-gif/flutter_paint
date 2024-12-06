import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/core/extensions/context_extensions.dart';
import 'dart:ui' as ui;

import 'package:flutter_paint/src/presentation/logic/shape_cubit.dart';

class ShapeCreationPage extends StatefulWidget {
  const ShapeCreationPage({
    super.key,
    required this.imageBytes,
    required this.callback,
  });

  final Uint8List imageBytes;
  final void Function(ui.Image? image, Uint8List? pixels, int width, int height)
      callback;

  @override
  State<ShapeCreationPage> createState() => _ShapeCreationPageState();
}

class _ShapeCreationPageState extends State<ShapeCreationPage> {
  ui.Image? _backgroundImage;

  final TextEditingController _vertexCountController =
      TextEditingController(text: "3");
  final ScrollController _scrollContext = ScrollController();

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
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ShapeCubit>();
    return BlocBuilder<ShapeCubit, ShapeState>(
      bloc: cubit,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text("Shape Creation")),
          body: Column(
            children: [
              // Pole tekstowe do wpisania liczby wierzchołków
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Opacity(
                      opacity: state.vertices.isNotEmpty ? 0.2 : 1,
                      child: IgnorePointer(
                        ignoring: state.vertices.isNotEmpty,
                        child: Switch(
                          value: state.isCreatingShape,
                          onChanged: cubit.isCreatingShape,
                        ),
                      ),
                    ),
                    if (state.isCreatingShape) ...[
                      Expanded(
                        child: TextField(
                          controller: _vertexCountController,
                          decoration: const InputDecoration(
                            labelText: "Liczba wierzchołków",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onSubmitted: (value) {
                            final count = int.tryParse(value) ?? 3;
                            context.read<ShapeCubit>().setVertexCount(count);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final count =
                              int.tryParse(_vertexCountController.text) ?? 3;
                          context.read<ShapeCubit>().setVertexCount(count);
                        },
                        child: const Text("Ustaw"),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) {
                    if (state.isCreatingShape) {
                      cubit.addVertex(details.localPosition);
                    } else {
                      cubit.editNearestShape(details.localPosition);
                    }
                  },
                  onPanStart: (details) {
                    if (state.isCreatingShape) {
                      cubit
                          .updateVerticesPointAtPosition(details.localPosition);
                    }
                  },
                  onPanUpdate: (details) {
                    if (state.isCreatingShape) {
                      cubit
                          .updateVerticesPointAtPosition(details.localPosition);
                    }
                  },
                  child: BlocBuilder<ShapeCubit, ShapeState>(
                    builder: (context, state) {
                      return CustomPaint(
                        painter: ShapePainter(
                          shapes: state.shapes,
                          vertices: state.vertices,
                          backgroundImage: _backgroundImage,
                        ),
                        child: Container(),
                      );
                    },
                  ),
                ),
              ),
              if (state.isCreatingShape)
                ColoredBox(
                  color: context.theme.colorScheme.primary.withOpacity(0.4),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text("Dodaj wierzchołki: "),
                          if (state.vertices.isNotEmpty) ...[
                            TextButton(
                              onPressed: () => cubit.finalizeShape(),
                              child: const Text("Zakończ"),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () => cubit.finalizeShape(true),
                              child: const Text("Dodaj kolejną figurę"),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () => cubit.clearVertices(),
                              child: const Text("Wyczyść"),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        height: 100,
                        width: double.infinity,
                        child: Scrollbar(
                          controller: _scrollContext,
                          child: ListView.builder(
                            controller: _scrollContext,
                            scrollDirection: Axis.horizontal,
                            itemCount: state.vertices.length,
                            itemBuilder: (context, index) {
                              final point = state.vertices[index];
                              final xController = TextEditingController(
                                  text: point.dx.toStringAsFixed(2));
                              final yController = TextEditingController(
                                  text: point.dy.toStringAsFixed(2));
                              return Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0),
                                child: Column(
                                  children: [
                                    Text('Punkt ${index + 1}'),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: xController,
                                            decoration: const InputDecoration(
                                              labelText: 'X',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onSubmitted: (value) =>
                                                cubit.updateVertex(
                                                    index,
                                                    Offset(double.parse(value),
                                                        point.dy)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: yController,
                                            decoration: const InputDecoration(
                                              labelText: 'Y',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onSubmitted: (value) =>
                                                cubit.updateVertex(
                                                    index,
                                                    Offset(point.dx,
                                                        double.parse(value))),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ShapePainter extends CustomPainter {
  final List<Shape> shapes;
  final List<Offset> vertices;
  final ui.Image? backgroundImage;

  ShapePainter({
    required this.shapes,
    required this.vertices,
    required this.backgroundImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      paintBackgroundImage(canvas, size);
    }

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (shapes.isNotEmpty) {
      for (final shape in shapes) {
        final shapeVertices = shape.vertices;
        final path = Path()
          ..moveTo(shapeVertices.first.dx, shapeVertices.first.dy);
        for (final vertex in shapeVertices) {
          path.lineTo(vertex.dx, vertex.dy);
        }
        if (shapeVertices.length > 2) {
          path.close();
        }
        canvas.drawPath(path, paint);
      }
    }

    if (vertices.isNotEmpty) {
      final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
      for (final vertex in vertices) {
        path.lineTo(vertex.dx, vertex.dy);
        final pointPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;
        canvas.drawCircle(vertex, 4, pointPaint);
      }
      if (vertices.length > 2) {
        path.close();
      }
      canvas.drawPath(path, paint);
    }
  }

  void paintBackgroundImage(Canvas canvas, Size size) {
    final paint = Paint();
    final src = Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(),
        backgroundImage!.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(backgroundImage!, src, dst, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
