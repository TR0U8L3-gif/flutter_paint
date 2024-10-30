part of 'paint_cubit.dart';

@immutable
abstract class PaintState extends Equatable {
  const PaintState();
}

final class PaintIdle extends PaintState {
  const PaintIdle({
    required this.selectedColor,
    required this.strokeSize,
    required this.drawingTool,
    required this.filled,
    required this.polygonSides,
    required this.showGrid,
    required this.strokes,
    required this.currentStroke,
    required this.canUndo,
    required this.canRedo,
    required this.additionalColor,
  });

  final Color? selectedColor;
  final double strokeSize;
  final DrawingTool drawingTool;
  final bool filled;
  final int polygonSides;
  final bool showGrid;
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final bool canUndo;
  final bool canRedo;
  final Color additionalColor;

  PaintIdle copyWith({
    Color? Function()? selectedColor,
    double? strokeSize,
    DrawingTool? drawingTool,
    bool? filled,
    int? polygonSides,
    bool? showGrid,
    List<Stroke>? strokes,
    Stroke? Function()? currentStroke,
    bool? canUndo,
    bool? canRedo,
    Color? additionalColor,
  }) {
    return PaintIdle(
      selectedColor: selectedColor != null ? selectedColor() : this.selectedColor,
      strokeSize: strokeSize ?? this.strokeSize,
      drawingTool: drawingTool ?? this.drawingTool,
      filled: filled ?? this.filled,
      polygonSides: polygonSides ?? this.polygonSides,
      showGrid: showGrid ?? this.showGrid,
      strokes: strokes ?? this.strokes,
      currentStroke:
          currentStroke != null ? currentStroke() : this.currentStroke,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      additionalColor: additionalColor ?? this.additionalColor,
    );
  }

  @override
  List<Object> get props => [
        selectedColor ?? 'additionalColor',
        strokeSize,
        drawingTool,
        filled,
        polygonSides,
        showGrid,
        strokes,
        currentStroke ?? 'currentStroke',
        canUndo,
        canRedo,
        additionalColor,
      ];
}

final class PaintMessage extends PaintState {
  const PaintMessage(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}