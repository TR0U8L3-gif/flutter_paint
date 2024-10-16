import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/core/common/domain/undo_redo.dart';
import 'package:flutter_paint/core/extensions/drawing_tool_extensions.dart';
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

  final memento = UndoRedo<Stroke>();

  get buildState => _lastBuildState;

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
  Stroke _startCurrentStroke(
    Offset point, {
    Color color = const Color.fromARGB(255, 68, 255, 239),
    double size = 10,
    double opacity = 1,
    StrokeType type = StrokeType.normal,
    int? sides,
    bool? filled,
  }) {
    return () {
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
  }

  // drawing
  void onPointerDown(Offset point) {
    final currentStroke = _startCurrentStroke(
      point,
      color: _lastBuildState.selectedColor,
      size: _lastBuildState.strokeSize,
      opacity: 1,
      type: _lastBuildState.drawingTool.strokeType,
      sides: _lastBuildState.polygonSides,
      filled: _lastBuildState.filled,
    );
    safeEmit(_lastBuildState.copyWith(currentStroke: () => currentStroke));
  }

  void onPointerMove(Offset point) {
    final points =
        List<Offset>.from(_lastBuildState.currentStroke?.points ?? [])
          ..add(point);
    final currentStroke =
        _lastBuildState.currentStroke?.copyWith(points: points);
    if (currentStroke == null) return; 
    safeEmit(
      _lastBuildState.copyWith(
        currentStroke: () => currentStroke,
      ),
    );
  }

  void onPointerUp() {
    final stroke = _lastBuildState.currentStroke;
    if (stroke == null) return;

    final result = memento.add(stroke);

    result.fold(
      (failure) => emit(PaintMessage(failure)),
      (success) {
        if (success != null) {
          emit(PaintMessage(success));
        }
      },
    );

    safeEmit(
      _lastBuildState.copyWith(
        strokes: memento.undoStack,
        currentStroke: () => null,
        canUndo: memento.canUndo,
        canRedo: memento.canRedo,
      ),
    );
  }

  void safeEmit(PaintState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  void undo() {
    final result = memento.undo();

    result.fold((failure) => emit(PaintMessage(failure)), (success) {
      if (success != null) {
        emit(PaintMessage(success));
      }
      final strokes = List<Stroke>.from(memento.undoStack);

      safeEmit(
        _lastBuildState.copyWith(
          strokes: strokes,
          canUndo: memento.canUndo,
          canRedo: memento.canRedo,
        ),
      );
    });
  }

  void redo() {
    final result = memento.redo();

    result.fold(
      (failure) => emit(PaintMessage(failure)),
      (success) {
        if (success != null) {
          emit(PaintMessage(success));
        }
        final strokes = List<Stroke>.from(memento.undoStack);

        safeEmit(
          _lastBuildState.copyWith(
            strokes: strokes,
            canUndo: memento.canUndo,
            canRedo: memento.canRedo,
          ),
        );
      },
    );
  }

  void clear() {
    final result = memento.clear();

    result.fold(
      (failure) => emit(PaintMessage(failure)),
      (success) {
        if (success != null) {
          emit(PaintMessage(success));
        }
        safeEmit(
          _lastBuildState.copyWith(
            strokes: [],
            canUndo: memento.canUndo,
            canRedo: memento.canRedo,
          ),
        );
      },
    );
  }
}
