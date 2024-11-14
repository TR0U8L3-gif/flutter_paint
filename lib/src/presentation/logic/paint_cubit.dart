import 'dart:async';
import 'dart:ui' as ui;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/image_file.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/core/common/domain/undo_redo.dart';
import 'package:flutter_paint/core/extensions/drawing_tool_extensions.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';
import 'package:flutter_paint/core/utils/enums/stroke_type.dart';
import 'package:flutter_paint/core/utils/response.dart';
import 'package:flutter_paint/src/domain/usecases/export_file_use_case.dart';
import 'package:flutter_paint/src/domain/usecases/import_file_use_case.dart';
import 'package:flutter_paint/src/domain/usecases/load_file_use_case.dart';
import 'package:flutter_paint/src/domain/usecases/save_file_use_case.dart';
import 'package:flutter_paint/src/presentation/logic/save_load_data.dart';
import 'package:fpdart/fpdart.dart';
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
    required LoadFileUseCase loadFileUseCase,
  })  : _saveFileUseCase = saveFileUseCase,
        _exportFileUseCase = exportFileUseCase,
        _importFileUseCase = importFileUseCase,
        _loadFileUseCase = loadFileUseCase,
        super(_initialState) {
    _initializeCubit();
  }

  final SaveFileUseCase _saveFileUseCase;

  final ExportFileUseCase _exportFileUseCase;

  final ImportFileUseCase _importFileUseCase;

  final LoadFileUseCase _loadFileUseCase;

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

  void loadFile({required String? path, required String extension}) {
    if (path == null || path.isEmpty) {
      emit(const PaintMessage('Error loading file: path is empty'));
      return;
    }

    if (extension != 'jpeg' && extension != 'png') {
      emit(
          const PaintMessage('Error loading file: extension is not supported'));
      return;
    }

    emit(PaintMessage('Loading $extension file...'));

    _loadFileUseCase
        .call(LoadFileUseCaseParams(
      extension: extension,
      path: path,
    ))
        .then((result) {
      result.fold(
        (failure) =>
            emit(PaintMessage(failure.message ?? 'Unknown error loading file')),
        (result) async {
          final imageData = await decodeImageFromList(result);

          final stroke = ImageStroke(
              pixels: result, height: imageData.height, width: imageData.width);
          stroke.setImage(imageData);

          memento.add(stroke);
          safeEmit(
            _lastBuildState.copyWith(
              strokes: List.from(memento.undoStack),
              currentStroke: () => null,
              canUndo: memento.canUndo,
              canRedo: memento.canRedo,
            ),
          );
        },
      );
    });
  }

  void onExportFile({
    required RenderRepaintBoundary? boundary,
    required ImageFile imageFile,
    required bool isFile,
  }) {
    if (boundary == null) {
      emit(const PaintMessage('Error exporting file: boundary is null'));
      return;
    }
    queue.add(SaveFileData(imageFile, boundary, isFile));
  }

  void onImportFile(
      {required String? path,
      required ImageFile imageFile,
      required bool isFile}) {
    if (path == null || path.isEmpty) {
      emit(const PaintMessage('Error importing file: path is empty'));
      return;
    }
    queue.add(LoadFileData(imageFile, path, isFile));
  }

  void _loadFile(LoadFileData event) {
    emit(PaintMessage(
        'Loading file ${event.imageFile.extension} at ${event.path}'));

    final now = DateTime.now();

    // Use an isolate to load the file
    compute(_loadFileInIsolate, {
      'imageFile': event.imageFile,
      'path': event.path,
      'isFile': event.isFile,
      'usecase': _importFileUseCase
    }).then((result) {
      result.fold(
        (failure) =>
            emit(PaintMessage(failure.message ?? 'Unknown error loading file')),
        (stroke) async {
          final image = await ImageStroke.renderImageFromUint8List(
              stroke.pixels, stroke.width, stroke.height);
          stroke.setImage(image);

          final then = DateTime.now();

          emit(PaintMessage(
              'File loaded in ${then.difference(now).inMilliseconds} ms'));
          memento.add(stroke);
          safeEmit(
            _lastBuildState.copyWith(
              strokes: List.from(memento.undoStack),
              currentStroke: () => null,
              canUndo: memento.canUndo,
              canRedo: memento.canRedo,
            ),
          );
        },
      );
    });

    // _importFileUseCase
    //     .call(ImportFileUseCaseParams(
    //   imageFile: event.imageFile,
    //   path: event.path,
    //   isFile: event.isFile,
    // ))
    //     .then((result) {
    //   result.fold(
    //     (failure) =>
    //         emit(PaintMessage(failure.message ?? 'Unknown error loading file')),
    //     (image) {
    //       final stroke = ImageStroke(pixels: image.pixels);
    //       stroke.loadImage();

    //       memento.add(stroke);
    //       safeEmit(
    //         _lastBuildState.copyWith(
    //           strokes: List.from(memento.undoStack),
    //           currentStroke: () => null,
    //           canUndo: memento.canUndo,
    //           canRedo: memento.canRedo,
    //         ),
    //       );
    //     },
    //   );
    // });
  }

  void _saveFile(SaveFileData event) {
    emit(PaintMessage('Saving ${event.imageFile.extension} file...'));

    // Use an isolate for saving the file
    compute(_saveFileInIsolate, {
      'boundary': event.boundary,
      'imageFile': event.imageFile,
      'isFile': event.isFile,
      'usecase': _exportFileUseCase
    }).then((result) {
      result.fold(
        (failure) =>
            emit(PaintMessage(failure.message ?? 'Unknown error saving file')),
        (success) => emit(PaintMessage(success)),
      );
    });
    // _exportFileUseCase
    //     .call(ExportFileUseCaseParams(
    //   boundary: event.boundary,
    //   imageFile: event.imageFile,
    //   isFile: event.isFile,
    // ))
    //     .then((result) {
    //   result.fold(
    //     (failure) =>
    //         emit(PaintMessage(failure.message ?? 'Unknown error saving file')),
    //     (success) => emit(PaintMessage(success)),
    //   );
    // });
  }

  Future<Uint8List?> convertCanvasToUint8List(GlobalKey canvasGlobalKey) async {
    try {
      // Retrieve the RenderRepaintBoundary
      RenderRepaintBoundary? boundary = canvasGlobalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        return null;
      }

      // Capture the boundary as an image
      ui.Image image = await boundary.toImage(
          pixelRatio: 3.0); // Adjust pixelRatio if needed

      // Convert the image to byte data in PNG format
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      // Convert the ByteData to Uint8List
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print("Error capturing canvas: $e");
      return null;
    }
  }

  void set(ui.Image? image, Uint8List? pixels, int width, int height) {
    if (pixels == null) {
      emit(const PaintMessage('Error setting image: pixels are null'));
      return;
    }
    if(image == null) {
      emit(const PaintMessage('Error setting image: image is null'));
      return;
    }
    final stroke = ImageStroke(pixels: pixels, width: width, height: height);
    stroke.setImage(image);

    clear();

    memento.add(stroke);
    
    safeEmit(
      _lastBuildState.copyWith(
        strokes: List.from([stroke]),
        currentStroke: () => null,
        canUndo: memento.canUndo,
        canRedo: memento.canRedo,
      ),
    );

  }

  @override
  Future<void> close() {
    queue.close();
    return super.close();
  }
}

/// Function to load the file in an isolate
Future<Either<Failure, ImageStroke>> _loadFileInIsolate(
    Map<String, dynamic> params) async {
  final imageFile = params['imageFile'];
  final path = params['path'];
  final isFile = params['isFile'];
  final usecase = params['usecase'];
  try {
    // Process the file using your import file use case
    final result = await (usecase as ImportFileUseCase).call(
      ImportFileUseCaseParams(
        imageFile: imageFile,
        path: path,
        isFile: isFile,
      ),
    );

    return result.fold(
      (failure) => Left(failure),
      (image) {
        final width = image.pixels[0].length;
        final height = image.pixels.length;
        // Create the ImageStroke with pixels
        final stroke = ImageStroke(
          pixels: ImageStroke.fromColors(image.pixels),
          width: width,
          height: height,
        );
        return Right(stroke);
      },
    );
  } catch (e) {
    return Left(Failure(message: e.toString()));
  }
}

/// Function to save the file in an isolate
Future<Either<Failure, String>> _saveFileInIsolate(
    Map<String, dynamic> params) async {
  final boundary = params['boundary'];
  final imageFile = params['imageFile'];
  final isFile = params['isFile'];
  final usecase = params['usecase'];

  try {
    // Process saving the file using your export file use case
    final result = await (usecase as ExportFileUseCase).call(
      ExportFileUseCaseParams(
        boundary: boundary,
        imageFile: imageFile,
        isFile: isFile,
      ),
    );

    return result.fold(
      (failure) => Left(failure),
      (success) => Right(success),
    );
  } catch (e) {
    return Left(Failure(message: e.toString()));
  }
}
