import 'package:flutter/material.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';

class UndoRedoStack with ChangeNotifier {
  UndoRedoStack({
    required this.strokesNotifier,
    required this.currentStrokeNotifier,
  }) {
    _strokeCount = strokesNotifier.value.length;
    strokesNotifier.addListener(_strokesCountListener);
  }

  final ValueNotifier<List<Stroke>> strokesNotifier;
  final ValueNotifier<Stroke?> currentStrokeNotifier;

  List<Stroke> get _redoStack => _redoStackInternal ??= [];
  List<Stroke>? _redoStackInternal;

  // late final ValueNotifier<bool> _canRedo;

  // ValueNotifier<bool> get canRedo => _canRedo;

  late int _strokeCount;

  bool _isRedoing = false;

  get canUndo => strokesNotifier.value.isNotEmpty;

  get canRedo => _redoStack.isNotEmpty;


  void _strokesCountListener() {
    if (!_isRedoing && strokesNotifier.value.length > _strokeCount) {
      // if a new Stroke is drawn,
      // history is invalidated so clear redo stack
      _redoStack.clear();
      _strokeCount = strokesNotifier.value.length;
    }
  }

  void clear() {
    _strokeCount = 0;
    strokesNotifier.value = [];
    _redoStackInternal?.clear();
    currentStrokeNotifier.value = null;
  }

  void undo() {
    if (strokesNotifier.value.isNotEmpty) {
      _strokeCount--;
      final strokes = List<Stroke>.from(strokesNotifier.value);
      _redoStack.add(strokes.removeLast());
      strokesNotifier.value = strokes;
      currentStrokeNotifier.value = null;
    }
  }

  void redo() {
    if(_isRedoing) return;
    if (_redoStack.isNotEmpty) {
      _isRedoing = true;

      final strokes = List<Stroke>.from(strokesNotifier.value);
      strokes.add(_redoStack.removeLast());
      strokesNotifier.value = strokes;
      _strokeCount++;

      _isRedoing = false;
    }
  }

  @override
  void dispose() {
    strokesNotifier.removeListener(_strokesCountListener);
    super.dispose();
  }
}
