import 'package:flutter/material.dart';
import 'package:flutter_paint/config/assets/theme.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';

class DrawingCanvasOptions {
  final Color strokeColor;
  final double size;
  final double opacity;
  final DrawingTool currentTool;
  final Color backgroundColor;
  final bool showGrid;
  final int polygonSides;
  final bool fillShape;

  const DrawingCanvasOptions({
    this.strokeColor = AppColors.blackAccent,
    this.size = 10,
    this.opacity = 1,
    this.currentTool = DrawingTool.pencil,
    this.backgroundColor = AppColors.lightAccent,
    this.showGrid = false,
    this.polygonSides = 3,
    this.fillShape = false,
  });

  DrawingCanvasOptions copyWith({
    Color? strokeColor,
    double? size,
    double? opacity,
    DrawingTool? currentTool,
    Color? backgroundColor,
    bool? showGrid,
    int? polygonSides,
    bool? fillShape,
  }) {
    return DrawingCanvasOptions(
      strokeColor: strokeColor ?? this.strokeColor,
      size: size ?? this.size,
      opacity: opacity ?? this.opacity,
      currentTool: currentTool ?? this.currentTool,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showGrid: showGrid ?? this.showGrid,
      polygonSides: polygonSides ?? this.polygonSides,
      fillShape: fillShape ?? this.fillShape,
    );
  }
}
