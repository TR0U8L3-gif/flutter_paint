import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BezierState {
  final List<Offset> controlPoints;
  final List<Offset> bezierCurve;

  BezierState({
    required this.controlPoints,
    required this.bezierCurve,
  });

  BezierState copyWith({
    List<Offset>? controlPoints,
    List<Offset>? bezierCurve,
  }) {
    return BezierState(
      controlPoints: controlPoints ?? this.controlPoints,
      bezierCurve: bezierCurve ?? this.bezierCurve,
    );
  }
}

class BezierCubit extends Cubit<BezierState> {
  BezierCubit() : super(BezierState(controlPoints: [], bezierCurve: []));

  void addControlPoint(Offset point) {
    final index = _getClosestControlPointIndex(point);
    if (index != -1) return;
    final updatedPoints = List<Offset>.from(state.controlPoints)..add(point);
    emit(state.copyWith(controlPoints: updatedPoints));
    _calculateBezierCurve();
  }

  void updateControlPointAtPosition(Offset position) {
    final index = _getClosestControlPointIndex(position);
    if (index != -1) {
      final updatedPoints = List<Offset>.from(state.controlPoints);
      updatedPoints[index] = position;
      emit(state.copyWith(controlPoints: updatedPoints));
      _calculateBezierCurve();
    }
  }

  void removeControlPoint(int index) {
    final updatedPoints = List<Offset>.from(state.controlPoints)
      ..removeAt(index);
    emit(state.copyWith(controlPoints: updatedPoints));
    _calculateBezierCurve();
  }

  void addControlPointFromPercentage(
      double percentX, double percentY, Size screenSize) {
    final newPoint = Offset(
        screenSize.width * percentX / 100, screenSize.height * percentY / 100);
    addControlPoint(newPoint);
  }

  int _getClosestControlPointIndex(Offset position) {
    const double threshold = 20.0; // Sensitivity radius for selection
    for (int i = 0; i < state.controlPoints.length; i++) {
      if ((state.controlPoints[i] - position).distance <= threshold) {
        return i;
      }
    }
    return -1;
  }

  void _calculateBezierCurve() {
    final controlPoints = state.controlPoints;
    if (controlPoints.isEmpty) return;

    const int steps = 100; // Precision of the curve
    final bezierPoints = <Offset>[];

    for (int i = 0; i <= steps; i++) {
      double t = i / steps;
      bezierPoints.add(_calculatePoint(controlPoints, t));
    }

    emit(state.copyWith(bezierCurve: bezierPoints));
  }

  Offset _calculatePoint(List<Offset> points, double t) {
    if (points.length == 1) return points.first;

    final List<Offset> nextLevel = [];
    for (int i = 0; i < points.length - 1; i++) {
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      nextLevel.add(Offset(
        (1 - t) * p1.dx + t * p2.dx,
        (1 - t) * p1.dy + t * p2.dy,
      ));
    }
    return _calculatePoint(nextLevel, t);
  }

  void setBezierDegree(int degree) {
    if (degree < 1) return;

    final requiredPoints = degree + 1;
    final currentPoints = state.controlPoints;

    if (currentPoints.length < requiredPoints) {
      // Dodaj brakujące punkty na środku ekranu
      final additionalPoints = List.generate(
        requiredPoints - currentPoints.length,
        (_) => const Offset(100, 100), // Domyślne współrzędne
      );
      emit(state
          .copyWith(controlPoints: [...currentPoints, ...additionalPoints]));
    } else if (currentPoints.length > requiredPoints) {
      // Usuń nadmiarowe punkty
      emit(state.copyWith(
          controlPoints: currentPoints.sublist(0, requiredPoints)));
    }

    _calculateBezierCurve();
  }

  void updateControlPoint(int index, Offset newPoint) {
    if (index < 0 || index >= state.controlPoints.length) {
      return; // Nieprawidłowy indeks - nic nie robimy
    }

    // Aktualizujemy punkt w liście
    final updatedPoints = List<Offset>.from(state.controlPoints);
    updatedPoints[index] = newPoint;

    // Emitujemy nowy stan z aktualizowaną listą punktów
    emit(state.copyWith(controlPoints: updatedPoints));

    // Przeliczamy krzywą Béziera
    _calculateBezierCurve();
  }
}
