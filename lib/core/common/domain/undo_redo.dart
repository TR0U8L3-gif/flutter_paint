import 'package:fpdart/fpdart.dart';

class UndoRedo<Type> {
  const UndoRedo({
    List<Type> undoStack = const [],
    List<Type> redoStack = const [],
  })  : _undoStack = undoStack,
        _redoStack = redoStack;

  final List<Type> _undoStack;
  final List<Type> _redoStack;

  get canUndo => _undoStack.isNotEmpty;
  get canRedo => _redoStack.isNotEmpty;

  get undoStack => _undoStack;
  get redoStack => _redoStack;

  Either<String, String?> undo() {
    if (_undoStack.isEmpty) {
      return left('Nothing to undo');
    }
    try {
      final item = _undoStack.removeLast();
      _redoStack.add(item);
      return right(null);
    } catch (e) {
      return left('Error undoing');
    }
  }

  Either<String, String?> redo() {
    if (_redoStack.isEmpty) {
      return left('Nothing to redo');
    }
    try {
      final item = _redoStack.removeLast();
      _undoStack.add(item);
      return right(null);
    } catch (e) {
      return left('Error redoing');
    }
  }

  Either<String, String?> add(Type item) {
    try {
      _undoStack.add(item);
      _redoStack.clear();
      return right(null);
    } catch (e) {
      return left('Error adding item');
    }
  }
}
