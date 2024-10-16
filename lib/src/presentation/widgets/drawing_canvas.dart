import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_paint/core/extensions/drawing_tool_extensions.dart';
import 'package:flutter_paint/core/extensions/offset_extensions.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/src/domain/models/drawing_canvas_options.dart';

class DrawingCanvas extends StatelessWidget {

  const DrawingCanvas({
    super.key,
    required this.canvasKey,
    required this.strokes,
    required this.currentStroke,
    required this.options,
    required this.showGrid,
    required this.isDarkTheme,
    required this.onPointerUp,
    required this.onPointerMove,
    required this.onPointerDown,
  });

  final GlobalKey canvasKey;
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final DrawingCanvasOptions options;
  final bool showGrid;
  final bool isDarkTheme;
  final void Function(PointerUpEvent)? onPointerUp;
  final void Function(PointerMoveEvent)? onPointerMove;
  final void Function(PointerDownEvent)? onPointerDown;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: options.currentTool.cursor,
      child: Listener(
        onPointerUp: onPointerUp,
        onPointerMove: onPointerMove,
        onPointerDown: onPointerDown,
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                key: canvasKey,
                child: CustomPaint(
                  isComplex: true,
                  painter: _DrawingCanvasPainter(
                    strokes: strokes,
                    stroke: currentStroke,
                    isDarkTheme: isDarkTheme,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  painter: _DrawingCanvasPainter(
                    isDarkTheme: isDarkTheme,
                    showGrid: showGrid,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingCanvasPainter extends CustomPainter {
  _DrawingCanvasPainter({
     this.strokes,
     this.stroke,
     this.showGrid,
     this.isDarkTheme = false,
  });

  final List<Stroke>? strokes;
  final Stroke? stroke;
  final bool? showGrid;
  final bool isDarkTheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.largest, Paint());

    if (strokes != null || stroke != null) {
      final strokesData = List<Stroke>.from(strokes ?? []);
      
      if (stroke != null) strokesData.add(stroke as Stroke);


      for (final strokeData in strokesData) {
        final points = strokeData.points;
        if (points.isEmpty) continue;

        final strokeSize = max(strokeData.size, 1.0);
        final paint = Paint()
          ..color = strokeData.color.withOpacity(strokeData.opacity)
          ..strokeWidth = strokeSize
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        // Pencil stroke
        if (strokeData is NormalStroke) {
          final path = _getStrokePath(strokeData, size);

          // If the path only has one line, draw a dot.
          if (strokeData.points.length == 1) {
            // scale the point to the standard size
            final center = strokeData.points.first.scaleFromStandard(size);
            final radius = strokeSize / 2;
            canvas.drawCircle(
                center, radius, paint..style = PaintingStyle.fill);

            continue;
          }

          canvas.drawPath(path, paint);
          continue;
        }

        // Eraser stroke. The eraser stroke is drawn with the background color.
        if (strokeData is EraserStroke) {
          final path = _getStrokePath(strokeData, size);
          paint.blendMode = BlendMode.clear;
          canvas.drawPath(path, paint);
          continue;
        }

        // Line stroke.
        if (strokeData is LineStroke) {
          // scale the points to the standard size
          final firstPoint = points.first.scaleFromStandard(size);
          final lastPoint = points.last.scaleFromStandard(size);
          canvas.drawLine(firstPoint, lastPoint, paint);
          continue;
        }

        if (strokeData is CircleStroke) {
          // scale the points to the standard size
          final firstPoint = points.first.scaleFromStandard(size);
          final lastPoint = points.last.scaleFromStandard(size);
          final rect = Rect.fromPoints(firstPoint, lastPoint);

          if (strokeData.filled) {
            paint.style = PaintingStyle.fill;
          }

          canvas.drawOval(rect, paint);
          continue;
        }

        if (strokeData is SquareStroke) {
          // scale the points to the standard size
          final firstPoint = points.first.scaleFromStandard(size);
          final lastPoint = points.last.scaleFromStandard(size);
          final rect = Rect.fromPoints(firstPoint, lastPoint);

          if (strokeData.filled) {
            paint.style = PaintingStyle.fill;
          }

          canvas.drawRect(rect, paint);
          continue;
        }

        if (strokeData is PolygonStroke) {
          // scale the points to the standard size
          final firstPoint = points.first.scaleFromStandard(size);
          final lastPoint = points.last.scaleFromStandard(size);
          final centerPoint = (firstPoint / 2) + (lastPoint / 2);
          final radius = (firstPoint - lastPoint).distance / 2;
          final sides = strokeData.sides;
          final angle = (2 * pi) / sides;
          final path = Path();
          final double x = centerPoint.dx;
          final double y = centerPoint.dy;
          final double radiusX = radius;
          final double radiusY = radius;
          const double initialAngle = -pi / 2;
          final double centerX = x + radiusX * cos(initialAngle);
          final double centerY = y + radiusY * sin(initialAngle);
          path.moveTo(centerX, centerY);
          for (int i = 1; i <= sides; i++) {
            final double currentAngle = initialAngle + (angle * i);
            final double x = centerPoint.dx + radius * cos(currentAngle);
            final double y = centerPoint.dy + radius * sin(currentAngle);
            path.lineTo(x, y);
          }
          path.close();

          if (strokeData.filled) {
            paint.style = PaintingStyle.fill;
          }
          canvas.drawPath(path, paint);
          continue;
        }
      }
    }

    // Draw the grid last so it's on top of everything else.
    if (showGrid ?? false) {
      _drawGrid(size, canvas);
    }

    canvas.restore();
  }

  void _drawGrid(Size size, Canvas canvas) {
    const gridStrokeWidth = 1.0;
    const gridSpacing = 50.0;
    const subGridSpacing = 10.0; // Spacing for smaller boxes
    const subGridStrokeWidth = 0.5; // Lighter stroke for smaller boxes

    final gridPaint = Paint()
      ..color = !isDarkTheme ? Colors.black : Colors.white
      ..strokeWidth = gridStrokeWidth;

    final subGridPaint = Paint()
      ..color = !isDarkTheme ?  Colors.grey[800]! :Colors.grey 
      ..strokeWidth = subGridStrokeWidth;

    // Horizontal lines for main grid
    for (double y = 0; y <= size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical lines for main grid
    for (double x = 0; x <= size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw smaller boxes within each grid cell
    for (double y = 0; y <= size.height; y += gridSpacing) {
      for (double subY = y;
          subY < y + gridSpacing && subY <= size.height;
          subY += subGridSpacing) {
        canvas.drawLine(
          Offset(0, subY),
          Offset(size.width, subY),
          subGridPaint,
        );
      }
    }

    for (double x = 0; x <= size.width; x += gridSpacing) {
      for (double subX = x;
          subX < x + gridSpacing && subX <= size.width;
          subX += subGridSpacing) {
        canvas.drawLine(
          Offset(subX, 0),
          Offset(subX, size.height),
          subGridPaint,
        );
      }
    }
  }

  Path _getStrokePath(Stroke stroke, Size size) {
    final path = Path();
    final points = stroke.points;
    if (points.isNotEmpty) {
      // scale the point to the standard size
      final firstPoint = points.first.scaleFromStandard(size);
      path.moveTo(firstPoint.dx, firstPoint.dy);
      for (int i = 1; i < points.length - 1; ++i) {
        // scale the points to the standard size
        final p0 = points[i].scaleFromStandard(size);
        final p1 = points[i + 1].scaleFromStandard(size);

        // use quadratic bezier to draw smooth curves through the points
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
