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
  });

  final Color selectedColor;
  final double strokeSize;
  final DrawingTool drawingTool;
  final bool filled;
  final int polygonSides;
  final bool showGrid;
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final bool canUndo;
  final bool canRedo;

  PaintIdle copyWith({
    Color? selectedColor,
    double? strokeSize,
    DrawingTool? drawingTool,
    bool? filled,
    int? polygonSides,
    bool? showGrid,
    List<Stroke>? strokes,
    Stroke? Function()? currentStroke,
    bool? canUndo,
    bool? canRedo,
  }) {
    return PaintIdle(
      selectedColor: selectedColor ?? this.selectedColor,
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
    );
  }

  @override
  List<Object> get props => [
        selectedColor,
        strokeSize,
        drawingTool,
        filled,
        polygonSides,
        showGrid,
        strokes,
        currentStroke ?? 'currentStroke',
        canUndo,
        canRedo,
      ];
}

final class PaintMessage extends PaintState {
  const PaintMessage(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}