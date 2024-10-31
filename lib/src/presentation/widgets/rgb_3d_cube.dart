import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as math;

class RGB3DCube extends StatefulWidget {
  const RGB3DCube({
    super.key,
    required this.rotateX,
    required this.rotateY,
    required this.rotateZ,
  });

  final double rotateX;
  final double rotateY;
  final double rotateZ;

  @override
  State<RGB3DCube> createState() => _RGB3DCubeState();
}

class _RGB3DCubeState extends State<RGB3DCube> {
  double _rx = 0;
  double _ry = 0;
  double _rz = 0;
  double _perspective = 0;

  @override
  void initState() {
    _rx = widget.rotateX;
    _ry = widget.rotateY;
    _rz = widget.rotateZ;
    _perspective = 0.0005;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const size = 200.0;
    final rotationMatrix = Matrix4.identity()
      ..rotateX(_rx)
      ..rotateY(_ry)
      ..rotateZ(_rz);
    return Scaffold(
      body: Align(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  print(details);
                  _rx += details.delta.dy * pi / 180;
                  _ry += details.delta.dx * pi / 180;
                  setState(() {
                    _rx %= pi * 2;
                    _ry %= pi * 2;
                  });
                },
                child: Transform(
                  transform: (Matrix4.identity()..setEntry(3, 2, _perspective)) *
                      rotationMatrix,
                  alignment: FractionalOffset.center,
                  child: Cube(
                    size: size,
                    rotation: rotationMatrix,
                    perspective: _perspective,
                    front: CustomPaint(
                      painter: PointsPainter(
                        r: 255,
                        g: 255,
                        b: 0,
                        static: RGBSide.r,
                        rgbSideX: RGBSide.g,
                      ),
                    ),
                    back: CustomPaint(
                      painter: PointsPainter(
                        r: 0,
                        g: 255,
                        b: 255,
                        static: RGBSide.r,
                        rgbSideX: RGBSide.g,
                      ),
                    ),
                    left: CustomPaint(
                      painter: PointsPainter(
                        r: 0,
                        g: 0,
                        b: 0,
                        static: RGBSide.g,
                        rgbSideX: RGBSide.r,
                      ),
                    ),
                    right: CustomPaint(
                      painter: PointsPainter(
                        r: 255,
                        g: 255,
                        b: 0,
                        static: RGBSide.g,
                        rgbSideX: RGBSide.r,
                      ),
                    ),
                    top: CustomPaint(
                      painter: PointsPainter(
                        r: 255,
                        g: 255,
                        b: 255,
                        static: RGBSide.b,
                        rgbSideX: RGBSide.g,
                      ),
                    ),
                    bottom: CustomPaint(
                      painter: PointsPainter(
                        r: 0,
                        g: 255,
                        b: 0,
                        static: RGBSide.b,
                        rgbSideX: RGBSide.g,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text('Rotate X: $_rx'),
              Slider(
                value: _rx,
                min: 0,
                max: pi * 2,
                onChanged: (value) => setState(() {
                  _rx = value;
                }),
              ),
              Text('Rotate Y: $_ry'),
              Slider(
                value: _ry,
                min: 0,
                max: pi * 2,
                onChanged: (value) => setState(() {
                  _ry = value;
                }),
              ),
              Text('Rotate Z: $_rz'),
              Slider(
                value: _rz,
                min: 0,
                max: pi * 2,
                onChanged: (value) => setState(() {
                  _rz = value;
                }),
              ),
              // Text('Perspective: $_perspective'),
              // Slider(
              //   value: _perspective,
              //   min: 0,
              //   max: 0.005,
              //   onChanged: (value) => setState(() => _perspective = value),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class PointsPainter extends CustomPainter {
  PointsPainter(
      {this.r = 255,
      this.g = 255,
      this.b = 255,
      this.static = RGBSide.r,
      this.rgbSideX = RGBSide.g});

  final int r;
  final int g;
  final int b;
  final RGBSide static;
  final RGBSide rgbSideX;

  @override
  void paint(Canvas canvas, Size size) {
    // Iterate over each point
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(rect);
    canvas.save();
    for (int ySide = 255; ySide >= 0; ySide -= 5) {
      for (int xSide = 255; xSide >= 0; xSide -= 5) {
        int rColor = _getColor(
            initialValue: r,
            rgbSide: RGBSide.r,
            value: _getValueFromSide(RGBSide.r, rgbSideX, xSide, ySide),
            static: static);
        int gColor = _getColor(
            initialValue: g,
            rgbSide: RGBSide.g,
            value: _getValueFromSide(RGBSide.g, rgbSideX, xSide, ySide),
            static: static);
        int bColor = _getColor(
            initialValue: b,
            rgbSide: RGBSide.b,
            value: _getValueFromSide(RGBSide.b, rgbSideX, xSide, ySide),
            static: static);

        Paint paint = Paint()
          ..color = Color.fromARGB(255, rColor, gColor, bColor)
          ..strokeWidth = 7.5;

        // Draw a point on the canvas at coordinates (r, g)
        canvas.drawPoints(
          PointMode.points,
          [
            Offset(size.width * (xSide.toDouble() / 255),
                size.height * (ySide.toDouble() / 255))
          ],
          paint,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  int _getColor({
    required RGBSide rgbSide,
    required RGBSide static,
    required int value,
    required int initialValue,
  }) {
    if (rgbSide == static) {
      return initialValue;
    }
    return initialValue == 0 ? 255 - value : value;
  }

  int _getValueFromSide(
      RGBSide rgbSide, RGBSide rgbSideX, int valueX, int valueY) {
    return rgbSide == rgbSideX ? valueX : valueY;
  }
}

enum RGBSide {
  r,
  g,
  b,
}

class Cube extends StatelessWidget {
  const Cube({
    super.key,
    this.size = 200,
    required this.rotation,
    required this.perspective,
    required this.front,
    required this.back,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  final double size;
  final Matrix4 rotation;
  final double perspective;

  final Widget front;
  final Widget back;
  final Widget left;
  final Widget right;
  final Widget top;
  final Widget bottom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 2,
      height: size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: _getVisibleSides(),
      ),
    );
  }

  Widget _buildSide(Widget face, Matrix4 transform) {
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: size,
        height: size,
        color: Colors.grey,
        child: face,
      ),
    );
  }

  List<Widget> _getVisibleSides() {
    List<Widget> sides = [];

    // Create the transformation matrix based on the cube's overall rotation
    Matrix4 rotationMatrix = rotation;
    // Matrix4 perspectiveMatrix = Matrix4.identity()..setEntry(3, 2, perspective);

    Matrix4 finalMatrix = rotationMatrix;

    // Define normal vectors for each face of the cube
    final List<math.Vector3> normals = [
      math.Vector3(0, 0, 1), // Front
      math.Vector3(0, 0, -1), // Back
      math.Vector3(1, 0, 0), // Right
      math.Vector3(-1, 0, 0), // Left
      math.Vector3(0, 1, 0), // Top
      math.Vector3(0, -1, 0), // Bottom
    ];

    // Apply the cube's rotation to each normal vector
    final List<math.Vector3> transformedNormals = normals.map((normal) {
      final vector = finalMatrix.transform3(normal);
      return vector;
    }).toList();

    for (var i = 0; i < transformedNormals.length; i++) {
      final String side = i == 0
          ? "Front"
          : i == 1
              ? "Back"
              : i == 2
                  ? "Right"
                  : i == 3
                      ? "Left"
                      : i == 4
                          ? "Top"
                          : "Bottom";
      print("${transformedNormals[i].z} -> $side");
    }

    final zThreshold = perspective * 100;

    // Check visibility for each side: if the z-component of the normal is positive, it's facing the viewer
    if (transformedNormals[0].z > zThreshold) {
      // Add the front side of the cube
      sides.add(
        _buildSide(
          front,
          Matrix4.identity()..translate(0.0, 0.0, -size / 2),
        ),
      );
    }

    if (transformedNormals[1].z > zThreshold) {
      // Add the back side of the cube
      sides.add(
        _buildSide(
          back,
          Matrix4.identity()
            ..translate(0.0, 0.0, size / 2)
            ..rotateX(pi),
        ),
      );
    }

    if (transformedNormals[2].z > zThreshold) {
      // Add the left side of the cube
      sides.add(
        _buildSide(
          left,
          Matrix4.identity()
            ..translate(-size / 2, 0.0, 0.0)
            ..rotateY(-pi / 2),
        ),
      );
    }

    if (transformedNormals[3].z > zThreshold) {
      // Add the right side of the cube
      sides.add(
        _buildSide(
          right,
          Matrix4.identity()
            ..translate(size / 2, 0.0, 0.0)
            ..rotateY(pi / 2),
        ),
      );
    }

    if (transformedNormals[4].z > zThreshold) {
      // Add the top side of the cube
      sides.add(
        _buildSide(
          top,
          Matrix4.identity()
            ..rotateX(-pi / 2)
            ..translate(0.0, 0.0, -size / 2),
        ),
      );
    }

    if (transformedNormals[5].z > zThreshold) {
      // Add the bottom side of the cube
      sides.add(
        _buildSide(
          bottom,
          Matrix4.identity()
            ..rotateX(pi / 2)
            ..translate(0.0, 0.0, -size / 2),
        ),
      );
    }

    return sides;
  }
}
