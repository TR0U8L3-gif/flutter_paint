import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/core/common/domain/undo_redo.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';
import 'package:flutter_paint/core/utils/enums/stroke_type.dart';

part 'paint_state.dart';

class PaintCubit extends Cubit<PaintState> {
  PaintCubit({
    Color selectedColor = Colors.black,
    double strokeSize = 10.0,
    DrawingTool drawingTool = DrawingTool.pencil,
    bool filled = false,
    int polygonSides = 3,
    bool showGrid = false,
    List<Stroke> strokes = const [],
    Stroke? currentStroke,
    bool canUndo = false,
    bool canRedo = false,
  })  : _lastBuildState = PaintIdle(
          selectedColor: selectedColor,
          strokeSize: strokeSize,
          drawingTool: drawingTool,
          filled: filled,
          polygonSides: polygonSides,
          showGrid: showGrid,
          strokes: strokes,
          currentStroke: currentStroke,
          canUndo: canUndo,
          canRedo: canRedo,
        ),
        super(
          PaintIdle(
            selectedColor: selectedColor,
            strokeSize: strokeSize,
            drawingTool: drawingTool,
            filled: filled,
            polygonSides: polygonSides,
            showGrid: showGrid,
            strokes: strokes,
            currentStroke: currentStroke,
            canUndo: canUndo,
            canRedo: canRedo,
          ),
        ) {
    _initializeCubit();
  }

  void _initializeCubit() {
    stream.listen((state) {
      if (state is PaintIdle) {
        _updateLastBuildState(state);
      }
    });
  }

  PaintIdle _lastBuildState;
  final memento = const UndoRedo<Stroke>();

  void _updateLastBuildState(PaintIdle state) {
    _lastBuildState = state;
  }

  /// Update the selected color
  void updateSelectedColor(Color color) {
    safeEmit(_lastBuildState.copyWith(selectedColor: color));
  }

  /// Update the stroke size
  void updateStrokeSize(double size) {
    safeEmit(_lastBuildState.copyWith(strokeSize: size));
  }

  /// Update the drawing tool
  void updateDrawingTool(DrawingTool tool) {
    safeEmit(_lastBuildState.copyWith(drawingTool: tool));
  }

  /// Update the list of strokes
  void updateFilled(bool filled) {
    safeEmit(_lastBuildState.copyWith(filled: filled));
  }

  /// Update the list of strokes
  void updatePolygonSides(int sides) {
    safeEmit(_lastBuildState.copyWith(polygonSides: sides));
  }

  /// Update the list of strokes
  void updateShowGrid(bool showGrid) {
    safeEmit(_lastBuildState.copyWith(showGrid: showGrid));
  }

  // current stroke

  /// On stroke start
  void startCurrentStroke(
    Offset point, {
    Color color = const Color.fromARGB(255, 68, 255, 239),
    double size = 10,
    double opacity = 1,
    StrokeType type = StrokeType.normal,
    int? sides,
    bool? filled,
  }) {
    final stroke = () {
      if (type == StrokeType.eraser) {
        return EraserStroke(
          points: [point],
          color: color,
          size: size,
          opacity: opacity,
        );
      }

      if (type == StrokeType.line) {
        return LineStroke(
          points: [point],
          color: color,
          size: size,
          opacity: opacity,
        );
      }

      if (type == StrokeType.polygon) {
        return PolygonStroke(
          points: [point],
          color: color,
          size: size,
          opacity: opacity,
          sides: sides ?? 3,
          filled: filled ?? false,
        );
      }

      if (type == StrokeType.circle) {
        return CircleStroke(
          points: [point],
          color: color,
          size: size,
          opacity: opacity,
          filled: filled ?? false,
        );
      }

      if (type == StrokeType.square) {
        return SquareStroke(
          points: [point],
          color: color,
          size: size,
          opacity: opacity,
          filled: filled ?? false,
        );
      }

      return NormalStroke(
        points: [point],
        color: color,
        size: size,
        opacity: opacity,
      );
    }();

    safeEmit(_lastBuildState.copyWith(currentStroke: () => stroke));
  }

  /// Add a point to the current stroke
  void addPointToCurrentStroke(Offset point) {
    final points =
        List<Offset>.from(_lastBuildState.currentStroke?.points ?? [])
          ..add(point);
    safeEmit(
      _lastBuildState.copyWith(
        currentStroke: () =>
            _lastBuildState.currentStroke?.copyWith(points: points),
      ),
    );
  }

  void clearCurrentStroke() {
    safeEmit(_lastBuildState.copyWith(currentStroke: () => null));
  }

  void safeEmit(PaintState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }
}
