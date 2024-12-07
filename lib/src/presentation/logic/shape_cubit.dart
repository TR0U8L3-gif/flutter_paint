import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class Shape {
  Shape(this.vertices);

  final List<Offset> vertices;
  int get vertexCount => vertices.length;

  Map<String, dynamic> toJson() {
    return {
      'vertices': vertices.map((vertex) => [vertex.dx, vertex.dy]).toList(),
    };
  }

  factory Shape.fromJson(Map<String, dynamic> json) {
    final vertices = (json['vertices'] as List)
        .map((vertex) => Offset(vertex[0], vertex[1]))
        .toList();
    return Shape(vertices);
  }
}

class ShapeState {
  final List<Shape> shapes;
  final List<Offset> vertices;
  final int vertexCount;
  final ShapeMode mode;
  final ShapeMoveType type;

  ShapeState({
    required this.shapes,
    required this.vertices,
    required this.vertexCount,
    required this.mode,
    required this.type,
  });

  ShapeState copyWith({
    List<Shape>? shapes,
    List<Offset>? vertices,
    int? vertexCount,
    ShapeMode? mode,
    ShapeMoveType? type,
  }) {
    return ShapeState(
      shapes: shapes ?? this.shapes,
      vertices: vertices ?? this.vertices,
      vertexCount: vertexCount ?? this.vertexCount,
      mode: mode ?? this.mode,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shapes': shapes.map((shape) => shape.toJson()).toList(),
      'vertices': vertices.map((vertex) => [vertex.dx, vertex.dy]).toList(),
      'vertexCount': vertexCount,
      'mode': mode.name,
      'type': type.name,
    };
  }

  factory ShapeState.fromJson(Map<String, dynamic> json) {
    final shapes = (json['shapes'] as List)
        .map((shape) => Shape.fromJson(shape))
        .toList();
    final vertices = (json['vertices'] as List)
        .map((vertex) => Offset(vertex[0], vertex[1]))
        .toList();
    final vertexCount = json['vertexCount'] as int;
    final mode = ShapeMode.values
        .firstWhere((element) => element.name == json['mode']);
    final type = ShapeMoveType.values
        .firstWhere((element) => element.name == json['type']);
    return ShapeState(
      shapes: shapes,
      vertices: vertices,
      vertexCount: vertexCount,
      mode: mode,
      type: type,
    );
  }
}

class ShapeCubit extends Cubit<ShapeState> {
  ShapeCubit()
      : super(ShapeState(
            shapes: [],
            vertices: [],
            vertexCount: 3,
            mode: ShapeMode.edit,
            type: ShapeMoveType.move));

  void isCreatingShape(bool isCreating) {
    emit(state.copyWith(mode: isCreating ? ShapeMode.edit : ShapeMode.select));
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
        mode: addNext ? ShapeMode.edit : ShapeMode.select));
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

  void changeMoveType() {
    final type = state.type == ShapeMoveType.move
        ? ShapeMoveType.rotate
        : state.type == ShapeMoveType.rotate
            ? ShapeMoveType.scale
            : ShapeMoveType.move;
    emit(state.copyWith(type: type));
  }

  void moveShape(Offset delta, [ShapeMoveType? type]) {
    double sumX = 0;
    double sumY = 0;

    for (final point in state.vertices) {
      sumX += point.dx;
      sumY += point.dy;
    }
    final center =
        Offset(sumX / state.vertices.length, sumY / state.vertices.length);

    if ((type ==null && state.type == ShapeMoveType.move) || type == ShapeMoveType.move) {
      final updatedVertices = List<Offset>.from(state.vertices.map((vertex) {
        return vertex + delta;
      }));
      emit(state.copyWith(vertices: updatedVertices));
    } else if ((type ==null && state.type == ShapeMoveType.rotate) ||
        type == ShapeMoveType.rotate) {
      final radians = delta.dx / (16 * pi);
      double cosTheta = cos(radians);
      double sinTheta = sin(radians);
      final updatedVertices = List<Offset>.from(state.vertices.map((vertex) {
        // Translacja punktu do środka
        double translatedX = vertex.dx - center.dx;
        double translatedY = vertex.dy - center.dy;

        // Obrót
        double x = translatedX * cosTheta - translatedY * sinTheta;
        double y = translatedX * sinTheta + translatedY * cosTheta;

        // Translacja z powrotem
        return Offset(x + center.dx, y + center.dy);
      }));
      emit(state.copyWith(vertices: updatedVertices));
    } else if ((type ==null && state.type == ShapeMoveType.scale) ||
        type == ShapeMoveType.scale) {
          final scale = 1 + delta.dx / 100;
      final updatedVertices = List<Offset>.from(state.vertices.map((vertex) {
        // Translacja punktu do środka
        double translatedX = vertex.dx - center.dx;
        double translatedY = vertex.dy - center.dy;

        // Skalowanie
        double x = translatedX * scale;
        double y = translatedY * scale;

        // Translacja z powrotem
        return Offset(x + center.dx, y + center.dy);
      }));
      emit(state.copyWith(vertices: updatedVertices));
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
    final mode =
        state.mode == ShapeMode.select ? ShapeMode.move : ShapeMode.edit;
    if (state.vertices.isNotEmpty) {
      finalizeShape(false);
    }
    emit(state.copyWith(mode: mode));
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
      vertexCount: shape.vertexCount,
      shapes: updatedShapes,
      vertices: updatedVertices,
    ));
  }

  Future<void> save(BuildContext context) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Choose location to save your file',
        fileName: 'data.json',
      );

      if (result != null) {
        final file = File(result);

        // Konwersja mapy na JSON i zapis
        await file.writeAsString(jsonEncode(state.toJson()));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File saved at $result')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File save canceled')),
        );
      }
    } catch (e) {
      print("Error saving file: $e");
    }
  }

  Future<void> load(BuildContext context) async {
    String fileContent = '';
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        fileContent = content;
      }
    } catch (e) {
      print("Error reading file: $e");
    }
    final state = ShapeState.fromJson(jsonDecode(fileContent));
    emit(state);
  }
}

enum ShapeMode {
  edit,
  select,
  move,
}

enum ShapeMoveType {
  move,
  rotate,
  scale,
}
