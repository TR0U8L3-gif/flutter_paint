import 'dart:math';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'color_state.dart';

@injectable
class ColorCubit extends Cubit<ColorState> {
  ColorCubit()
      : super(const ColorIdle(
          r: 0,
          g: 0,
          b: 0,
          H: 0,
          S: 0,
          V: 0,
          L: 0,
          C: 0,
          M: 0,
          Y: 0,
          K: 1,
        ));

  void initialize(Color initColor) {
    final hsl = _calculateHslFromRGB(initColor.red, initColor.green, initColor.blue);
    final hsv = _calculateHsvFromRGB(initColor.red, initColor.green, initColor.blue);
    final cmyk = _calculateCmykFromRGB(initColor.red, initColor.green, initColor.blue);
    emit(
      ColorIdle(
        r: initColor.red,
        g: initColor.green,
        b: initColor.blue,
        H: hsl.H,
        S: hsl.S,
        V: hsv.V,
        L: hsl.L,
        C: cmyk.C,
        M: cmyk.M,
        Y: cmyk.Y,
        K: cmyk.K,
      ),
    );
  }

  void updateRGB(int r, int g, int b) {
    final hsl = _calculateHslFromRGB(r, g, b);
    final hsv = _calculateHsvFromRGB(r, g, b);
    final cmyk = _calculateCmykFromRGB(r, g, b);
    emit(
      ColorIdle(
        r: r,
        g: g,
        b: b,
        H: hsl.H,
        S: hsl.S,
        V: hsv.V,
        L: hsl.L,
        C: cmyk.C,
        M: cmyk.M,
        Y: cmyk.Y,
        K: cmyk.K,
      ),
    );
  }

  void updateHSV(double h, double s, double v) {
    final rgb = _calculateRgbFromHSV(h, s, v);
    updateRGB(rgb.R, rgb.G, rgb.B);

  }

  void updateHSL(double h, double s, double l) {
    final rgb = _calculateRgbFromHSL(h, s, l);
    updateRGB(rgb.R, rgb.G, rgb.B);
  }

  void updateCMYK(double c, double m, double y, double k) {
    final rgb = _calculateRgbFromCMYK(c, m, y, k);
    updateRGB(rgb.R, rgb.G, rgb.B);
  }

  ({int R, int G, int B}) _calculateRgbFromCMYK(
      double C, double M, double Y, double K) {
    int r = ((1 - C) * (1 - K) * 255).round();
    int g = ((1 - M) * (1 - K) * 255).round();
    int b = ((1 - Y) * (1 - K) * 255).round();

    return (R: r, G: g, B: b);
  }

  ({double C, double M, double Y, double K}) _calculateCmykFromRGB(
      int R, int G, int B) {
    double r = R / 255.0;
    double g = G / 255.0;
    double b = B / 255.0;

    double k = 1 - [r, g, b].reduce((a, b) => a > b ? a : b);
    double c = (1 - r - k) / (1 - k);
    double m = (1 - g - k) / (1 - k);
    double y = (1 - b - k) / (1 - k);

    return (C: k < 1 ? c : 0, M: k < 1 ? m : 0, Y: k < 1 ? y : 0, K: k);
  }

  ({int R, int G, int B}) _calculateRgbFromHSL(double h, double s, double l) {
    double r = 0, g = 0, b = 0;

    double c = (1 - (2 * l - 1).abs()) * s;
    double x = c * (1 - ((h / 60) % 2 - 1).abs());
    double m = l - c / 2;

    if (h >= 0 && h < 60) {
      r = c;
      g = x;
      b = 0;
    } else if (h >= 60 && h < 120) {
      r = x;
      g = c;
      b = 0;
    } else if (h >= 120 && h < 180) {
      r = 0;
      g = c;
      b = x;
    } else if (h >= 180 && h < 240) {
      r = 0;
      g = x;
      b = c;
    } else if (h >= 240 && h < 300) {
      r = x;
      g = 0;
      b = c;
    } else if (h >= 300 && h < 360) {
      r = c;
      g = 0;
      b = x;
    }

    return (
      R: ((r + m) * 255).round(),
      G: ((g + m) * 255).round(),
      B: ((b + m) * 255).round()
    );
  }

  ({double H, double S, double L}) _calculateHslFromRGB(int R, int G, int B) {
    double r = R / 255.0;
    double g = G / 255.0;
    double b = B / 255.0;

    double max = [r, g, b].reduce((a, b) => a > b ? a : b);
    double min = [r, g, b].reduce((a, b) => a < b ? a : b);
    double delta = max - min;

    // Calculate Lightness
    double l = (max + min) / 2;

    // Calculate Saturation
    double s = 0;
    if (delta != 0) {
      s = l < 0.5 ? delta / (max + min) : delta / (2 - max - min);
    }

    // Calculate Hue
    double h = 0;
    if (delta != 0) {
      if (max == r) {
        h = ((g - b) / delta) % 6;
      } else if (max == g) {
        h = ((b - r) / delta) + 2;
      } else if (max == b) {
        h = ((r - g) / delta) + 4;
      }
      h *= 60;
      if (h < 0) h += 360;
    }

    return (H: h, S: s, L: l);
  }

  ({int R, int G, int B}) _calculateRgbFromHSV(double h, double s, double v) {
    double r = 0, g = 0, b = 0;

    double c = v * s;
    double x = c * (1 - ((h / 60) % 2 - 1).abs());
    double m = v - c;

    if (h >= 0 && h < 60) {
      r = c;
      g = x;
      b = 0;
    } else if (h >= 60 && h < 120) {
      r = x;
      g = c;
      b = 0;
    } else if (h >= 120 && h < 180) {
      r = 0;
      g = c;
      b = x;
    } else if (h >= 180 && h < 240) {
      r = 0;
      g = x;
      b = c;
    } else if (h >= 240 && h < 300) {
      r = x;
      g = 0;
      b = c;
    } else if (h >= 300 && h < 360) {
      r = c;
      g = 0;
      b = x;
    }

    return (
      R: ((r + m) * 255).round(),
      G: ((g + m) * 255).round(),
      B: ((b + m) * 255).round()
    );
  }

  ({double H, double S, double V}) _calculateHsvFromRGB(int R, int G, int B) {
  double r = R / 255.0;
  double g = G / 255.0;
  double b = B / 255.0;

  double max = [r, g, b].reduce((a, b) => a > b ? a : b);
  double min = [r, g, b].reduce((a, b) => a < b ? a : b);
  double delta = max - min;

  // Calculate Value (V)
  double v = max;

  // Calculate Saturation (S)
  double s = (max == 0) ? 0 : delta / max;

  // Calculate Hue (H)
  double h = 0;
  if (delta != 0) {
    if (max == r) {
      h = ((g - b) / delta) % 6;
    } else if (max == g) {
      h = ((b - r) / delta) + 2;
    } else if (max == b) {
      h = ((r - g) / delta) + 4;
    }
    h *= 60;
    if (h < 0) h += 360;
  }

  return (H: h, S: s, V: v);
}

  ({int R, int G, int B}) _calculateRgbFromRotation(
      double x, double y, double z) {
    final rX = (x % (pi * 2)) / (pi * 2);
    final rY = (y % (pi * 2)) / (pi * 2);
    final rZ = (z % (pi * 2)) / (pi * 2);
    final r = (rX * 255).toInt();
    final g = (rY * 255).toInt();
    final b = (rZ * 255).toInt();
    return (R: r, G: g, B: b);
  }

}
