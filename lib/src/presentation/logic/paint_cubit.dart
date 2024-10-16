import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/core/common/domain/undo_redo.dart';
import 'package:flutter_paint/core/extensions/drawing_tool_extensions.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';
import 'package:flutter_paint/core/utils/enums/stroke_type.dart';
import 'package:flutter_paint/src/domain/repositories/paint_repository.dart';

part 'paint_state.dart';

const _initialState = PaintIdle(
  selectedColor: Color.fromARGB(255, 68, 255, 239),
  strokeSize: 10,
  drawingTool: DrawingTool.pencil,
  filled: false,
  polygonSides: 3,
  showGrid: false,
  strokes: const [],
  currentStroke: null,
  canUndo: false,
  canRedo: false,
);

class PaintCubit extends Cubit<PaintState> {
  PaintCubit({
    required PaintRepository paintRepository,
  })  : _paintRepository = paintRepository,
        super(_initialState) {
    _initializeCubit();
  }

  void _initializeCubit() {
    stream.listen((state) {
      if (state is PaintIdle) {
        _updateLastBuildState(state);
      }
    });
  }

  final PaintRepository _paintRepository;

  PaintIdle _lastBuildState = _initialState;

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

  void saveFile(RenderRepaintBoundary? boundary, String extension) {
    if(boundary == null) {
      emit(const PaintMessage('Error saving file: boundary is null'));
      return;
    }
    emit(const PaintMessage('Saving file...'));
    _paintRepository.saveFile(boundary, extension).then((result) {
      result.fold(
        (failure) => emit(PaintMessage(failure)),
        (success) {
          if (success != null) {
            emit(PaintMessage(success));
          }
        },
      );
    });
  }
}
