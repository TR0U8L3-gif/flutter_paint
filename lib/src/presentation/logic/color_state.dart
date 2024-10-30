part of 'color_cubit.dart';

sealed class ColorState extends Equatable {
  const ColorState();

  @override
  List<Object> get props => [];
}

final class ColorIdle extends ColorState {
  const ColorIdle({
    required this.r,
    required this.g,
    required this.b,
    required this.H,
    required this.S,
    required this.V,
    required this.L,
    required this.C,
    required this.M,
    required this.Y,
    required this.K,
  });

  final int r;
  final int g;
  final int b;
  final double H;
  final double S;
  final double V;
  final double L;
  final double C;
  final double M;
  final double Y;
  final double K;

  Color get color => Color.fromARGB(255, r, g, b); 

  @override
  List<Object> get props => [
    r,
    g,
    b,
    H,
    S,
    V,
    L,
    C,
    M,
    Y,
    K,
  ];
}
