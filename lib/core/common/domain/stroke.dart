import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_paint/core/utils/enums/stroke_type.dart';

abstract class Stroke {
  final List<Offset> points;
  final Color color;
  final double size;
  final double opacity;
  final StrokeType strokeType;
  final DateTime createdAt = DateTime.now();

  Stroke({
    required this.points,
    this.color = Colors.black,
    this.size = 1,
    this.opacity = 1,
    this.strokeType = StrokeType.normal,
  });

  Stroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    double? opacity,
  });

  Map<String, dynamic> toJson();

  factory Stroke.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as List<dynamic>)
        .map(
          (point) =>
              Offset((point as List<dynamic>)[0] as double, point[1] as double),
        )
        .toList();
    final color = Color(json['color'] as int);
    final size = double.parse(json['size'].toString());
    final opacity = double.parse(json['opacity'].toString());
    final strokeType = StrokeType.fromString(json['strokeType'] as String);

    switch (strokeType) {
      case StrokeType.normal:
        return NormalStroke(
          points: points,
          color: color,
          size: size,
          opacity: opacity,
        );
      case StrokeType.eraser:
        return EraserStroke(
          points: points,
          color: color,
          size: size,
          opacity: opacity,
        );
      case StrokeType.line:
        return LineStroke(
          points: points,
          color: color,
          size: size,
          opacity: opacity,
        );
      case StrokeType.polygon:
        return PolygonStroke(
          points: points,
          sides: (json['sides'] as int?) ?? 3,
          color: color,
          size: size,
          opacity: opacity,
        );
      case StrokeType.circle:
        return CircleStroke(
          points: points,
          color: color,
          size: size,
          opacity: opacity,
        );
      case StrokeType.square:
        return SquareStroke(
          points: points,
          color: color,
          size: size,
          opacity: opacity,
        );
      case StrokeType.image:
        return ImageStroke(
          points: points,
          pixels: (json['pixels'] as List<dynamic>)
              .map((row) => (row as List<dynamic>)
                  .map((color) => Color(color as int))
                  .toList())
              .toList(),
          color: color,
          size: size,
          opacity: opacity,
        );
    }
  }

  bool get isEraser => strokeType == StrokeType.eraser;
  bool get isLine => strokeType == StrokeType.line;
  bool get isNormal => strokeType == StrokeType.normal;
}

class NormalStroke extends Stroke {
  NormalStroke({
    required super.points,
    super.color,
    super.size,
    super.opacity,
  }) : super(strokeType: StrokeType.normal);

  @override
  NormalStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    double? opacity,
  }) {
    return NormalStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => [point.dx, point.dy]).toList(),
      'color': color.value,
      'size': size,
      'opacity': opacity,
      'strokeType': strokeType.toString(),
    };
  }
}

class EraserStroke extends Stroke {
  EraserStroke({
    required super.points,
    super.color,
    super.size,
    super.opacity,
  }) : super(strokeType: StrokeType.eraser);

  @override
  EraserStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    double? opacity,
  }) {
    return EraserStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => [point.dx, point.dy]).toList(),
      'color': color.value,
      'size': size,
      'opacity': opacity,
      'strokeType': strokeType.toString(),
    };
  }
}

class LineStroke extends Stroke {
  LineStroke({
    required super.points,
    super.color,
    super.size,
    super.opacity,
  }) : super(strokeType: StrokeType.line);

  @override
  LineStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    double? opacity,
  }) {
    return LineStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => [point.dx, point.dy]).toList(),
      'color': color.value,
      'size': size,
      'opacity': opacity,
      'strokeType': strokeType.toString(),
    };
  }
}

class PolygonStroke extends Stroke {
  final int sides;
  final bool filled;

  PolygonStroke({
    required super.points,
    required this.sides,
    this.filled = false,
    super.color,
    super.size,
    super.opacity,
  }) : super(strokeType: StrokeType.polygon);

  @override
  PolygonStroke copyWith({
    List<Offset>? points,
    int? sides,
    Color? color,
    double? size,
    double? opacity,
    bool? filled,
  }) {
    return PolygonStroke(
      points: points ?? this.points,
      sides: sides ?? this.sides,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      filled: filled ?? this.filled,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => [point.dx, point.dy]).toList(),
      'sides': sides,
      'color': color.value,
      'size': size,
      'opacity': opacity,
      'strokeType': strokeType.toString(),
    };
  }
}

class CircleStroke extends Stroke {
  final bool filled;

  CircleStroke({
    required super.points,
    this.filled = false,
    super.color,
    super.size,
    super.opacity,
  }) : super(strokeType: StrokeType.circle);

  @override
  CircleStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    double? opacity,
    bool? filled,
  }) {
    return CircleStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      filled: filled ?? this.filled,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => [point.dx, point.dy]).toList(),
      'color': color.value,
      'size': size,
      'opacity': opacity,
      'strokeType': strokeType.toString(),
    };
  }
}

class SquareStroke extends Stroke {
  final bool filled;

  SquareStroke({
    required super.points,
    this.filled = false,
    super.color,
    super.size,
    super.opacity,
  }) : super(strokeType: StrokeType.square);

  @override
  SquareStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? size,
    double? opacity,
    bool? filled,
  }) {
    return SquareStroke(
      points: points ?? this.points,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      filled: filled ?? this.filled,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => [point.dx, point.dy]).toList(),
      'color': color.value,
      'size': size,
      'opacity': opacity,
      'strokeType': strokeType.toString(),
    };
  }
}

// ImageStroke class
class ImageStroke extends Stroke {
  final List<List<Color>> pixels;
  late final ui.Image image;

  ImageStroke({
    super.points = const [],
    required this.pixels,
    super.color,
    super.size,
    super.opacity,
    super.strokeType = StrokeType.image,
  });

  /// Converts a List<List<Color>> to a ui.Image
  static Future<ui.Image> createImageFromColors(List<List<Color>> pixels) async{
    final int width = pixels[0].length;
    final int height = pixels.length;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    // Drawing the colors on a canvas
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        paint.color = pixels[y][x];
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }

    final picture = pictureRecorder.endRecording();
    return await picture.toImage(width, height);
  }

  Future<void> loadImage() async {
    image = await createImageFromColors(pixels);
  }

  @override
  Stroke copyWith({
    List<Offset>? points,
    List<List<Color>>? pixels,
    Color? color,
    double? size,
    double? opacity,
    ui.Image? image,
  }) {
    return ImageStroke(
      points: points ?? this.points,
      pixels: pixels ?? this.pixels,
      color: color ?? this.color,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => [point.dx, point.dy]).toList(),
      'pixels': pixels
          .map((row) => row.map((color) => color.value).toList())
          .toList(),
      'color': color.value,
      'size': size,
      'opacity': opacity,
      'strokeType': strokeType.toString(),
    };
  }
}
