import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class Shape {
  Shape(this.vertices);

  final List<Offset> vertices;
  int get vertexCount => vertices.length;
}

class ShapeState {
  final List<Shape> shapes;
  final List<Offset> vertices;
  final int vertexCount;
  final bool isCreatingShape;

  ShapeState({
    required this.shapes,
    required this.vertices,
    required this.vertexCount,
    required this.isCreatingShape,
  });

  ShapeState copyWith({
    List<Shape>? shapes,
    List<Offset>? vertices,
    int? vertexCount,
    bool? isCreatingShape,
  }) {
    return ShapeState(
      shapes: shapes ?? this.shapes,
      vertices: vertices ?? this.vertices,
      vertexCount: vertexCount ?? this.vertexCount,
      isCreatingShape: isCreatingShape ?? this.isCreatingShape,
    );
  }
}

class ShapeCubit extends Cubit<ShapeState> {
  ShapeCubit()
      : super(ShapeState(
            shapes: [], vertices: [], vertexCount: 3, isCreatingShape: true));

  void isCreatingShape(bool isCreating) {
    emit(state.copyWith(isCreatingShape: isCreating));
  }

  void setVertexCount(int count) {
    final ver = List<Offset>.from(state.vertices.take(count));
    emit(state.copyWith(vertexCount: count, vertices: ver));
  }

  void addVertex(Offset vertex) {
    if (state.vertices.length < state.vertexCount) {
      emit(state.copyWith(vertices: [...state.vertices, vertex]));
    }

    if (state.vertices.length + 1 == state.vertexCount) {
      finalizeShape();
    }
  }

  void updateVertex(int index, Offset newVertex) {
    final updatedVertices = List<Offset>.from(state.vertices);
    updatedVertices[index] = newVertex;
    emit(state.copyWith(vertices: updatedVertices));
  }

  void finalizeShape([bool addNext = false]) {
    if (state.vertices.length < state.vertexCount) return;
    final newShape = Shape(List<Offset>.from(state.vertices));
    emit(state.copyWith(
        shapes: [...state.shapes, newShape],
        vertices: [],
        isCreatingShape: addNext));
  }

  void clearVertices() {
    emit(state.copyWith(vertices: []));
  }

  void updateVerticesPointAtPosition(Offset position) {
    final index = _getClosestControlPointIndex(position);
    if (index != -1) {
      final updatedPoints = List<Offset>.from(state.vertices);
      updatedPoints[index] = position;
      emit(state.copyWith(vertices: updatedPoints));
    }
  }

  int _getClosestControlPointIndex(Offset position) {
    const double threshold = 20.0; // Sensitivity radius for selection
    for (int i = 0; i < state.vertices.length; i++) {
      if ((state.vertices[i] - position).distance <= threshold) {
        return i;
      }
    }
    return -1;
  }

  void editNearestShape(Offset position) {
    final shapesList = state.shapes;
    final shapesDistanceList = List.generate(shapesList.length, (index) {
      final shape = shapesList[index];
      final smallestDistance = shape.vertices
          .map((vertex) => (vertex - position).distance)
          .reduce((a, b) => a < b ? a : b);
      return smallestDistance < 0 ? smallestDistance * -1 : smallestDistance;
    });
    final smallestDistance = shapesDistanceList.reduce((a, b) => a < b ? a : b);
    final index = shapesDistanceList.indexOf(smallestDistance);
    final shape = shapesList[index];
    final updatedVertices = List<Offset>.from(shape.vertices);
    final updatedShapes = List<Shape>.from(shapesList..remove(shape));
    emit(state.copyWith(
        shapes: updatedShapes,
        vertices: updatedVertices,
        isCreatingShape: true));
  }
}
