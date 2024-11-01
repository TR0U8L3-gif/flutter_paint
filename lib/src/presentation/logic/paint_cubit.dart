import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/image_file.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/core/common/domain/undo_redo.dart';
import 'package:flutter_paint/core/extensions/drawing_tool_extensions.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';
import 'package:flutter_paint/core/utils/enums/stroke_type.dart';
import 'package:flutter_paint/src/domain/usecases/export_file_use_case.dart';
import 'package:flutter_paint/src/domain/usecases/import_file_use_case.dart';
import 'package:flutter_paint/src/domain/usecases/save_file_use_case.dart';
import 'package:flutter_paint/src/presentation/logic/save_load_data.dart';
import 'package:injectable/injectable.dart';

part 'paint_state.dart';

const _initialState = PaintIdle(
  selectedColor: Colors.blue,
  strokeSize: 10,
  drawingTool: DrawingTool.pencil,
  filled: false,
  polygonSides: 3,
  showGrid: false,
  strokes: [],
  currentStroke: null,
  canUndo: false,
  canRedo: false,
  additionalColor: Colors.white,
);

@injectable
class PaintCubit extends Cubit<PaintState> {
  PaintCubit({
    required SaveFileUseCase saveFileUseCase,
    required ExportFileUseCase exportFileUseCase,
    required ImportFileUseCase importFileUseCase,
  })  : _saveFileUseCase = saveFileUseCase,
        _exportFileUseCase = exportFileUseCase,
        _importFileUseCase = importFileUseCase,
        super(_initialState) {
    _initializeCubit();
  }

  final SaveFileUseCase _saveFileUseCase;

  final ExportFileUseCase _exportFileUseCase;

  final ImportFileUseCase _importFileUseCase;

  PaintIdle _lastBuildState = _initialState;

  final memento = UndoRedo<Stroke>();

  final queue = StreamController<SaveLoadData>.broadcast();

  get buildState => _lastBuildState;

  void _initializeCubit() {
    stream.listen((state) {
      if (state is PaintIdle) {
        _updateLastBuildState(state);
      }
    });
    queue.stream.listen((event) {
      if (event is LoadFileData) {
        _loadFile(event);
      } else if (event is SaveFileData) {
        _saveFile(event);
      }
    });
  }

  void _updateLastBuildState(PaintIdle state) {
    _lastBuildState = state;
  }

  /// Update the selected color
  void updateSelectedColor(Color color) {
    safeEmit(_lastBuildState.copyWith(selectedColor: () => color));
  }

  /// Update the additional color
  void updateAdditionalColor(Color color) {
    safeEmit(_lastBuildState.copyWith(
        additionalColor: color, selectedColor: () => null));
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
      color: _lastBuildState.selectedColor ?? _lastBuildState.additionalColor,
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
    if (boundary == null) {
      emit(const PaintMessage('Error saving file: boundary is null'));
      return;
    }
    emit(const PaintMessage('Saving file...'));
    _saveFileUseCase
        .call(SaveFileUseCaseParams(
      boundary: boundary,
      extension: extension,
    ))
        .then((result) {
      result.fold(
        (failure) =>
            emit(PaintMessage(failure.message ?? 'Unknown error saving file')),
        (success) {
          if (success != null) {
            emit(PaintMessage(success));
          }
        },
      );
    });
  }

  void onExportFile(
      {required RenderRepaintBoundary? boundary,
      required ImageFile imageFile}) {
    if (boundary == null) {
      emit(const PaintMessage('Error exporting file: boundary is null'));
      return;
    }
    queue.add(SaveFileData(imageFile, boundary));
  }

  void onImportFile({required String? path, required ImageFile imageFile}) {
    if (path == null || path.isEmpty) {
      emit(const PaintMessage('Error importing file: path is empty'));
      return;
    }
    queue.add(LoadFileData(imageFile, path));
  }

  void _loadFile(LoadFileData event) {
    _importFileUseCase
        .call(ImportFileUseCaseParams(
      imageFile: event.imageFile,
      path: event.path,
    ))
        .then((result) {
      result.fold(
        (failure) =>
            emit(PaintMessage(failure.message ?? 'Unknown error loading file')),
        (success) {
          final stroke = convertPixelsToStrokes(success.pixels);

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
        },
      );
    });
  }

  void _saveFile(SaveFileData event) {
    _exportFileUseCase
        .call(ExportFileUseCaseParams(
      boundary: event.boundary,
      imageFile: event.imageFile,
    ))
        .then((result) {
      result.fold(
        (failure) =>
            emit(PaintMessage(failure.message ?? 'Unknown error saving file')),
        (success) => emit(PaintMessage(success)),
      );
    });
  }

  // TODO: nie diziała wszytsko opróc grey scale ale i tak źle
  // dodatkowo trzeba umieć przesakaloać obrazek na canvas i wyśrodkować
  // dodatkowo ogarnąć te rozszerzenia o co z nimi chodzi
  Stroke convertPixelsToStrokes(List<List<int>> pixels) {
    List<Offset> allPoints = [];

    // Example dimensions; you may need to adjust based on image size and interpretation
    int width = pixels.length;
    int height = pixels[0].length;

    // A simple interpretation could be to treat each row or column as a distinct stroke,
    // or to detect connected regions of the same color.

    for (int x = 0; x < width; x++) {
      List<Offset> points = [];

      for (int y = 0; y < height; y++) {
        int pixel = pixels[x][y];

        if (pixel != 0) {
          // Assuming 0 is a transparent/empty pixel
          Offset point = Offset(y.toDouble(), x.toDouble());
          points.add(point);
        }
      }

      if (points.isNotEmpty) {
        allPoints.addAll(points);
      }
    }

    return NormalStroke(
      points: allPoints,
      color: Colors.black, // Fallback color
      size: 1.0,
      opacity: 1.0,
    );
  }

  @override
  Future<void> close() {
    queue.close();
    return super.close();
  }
}
