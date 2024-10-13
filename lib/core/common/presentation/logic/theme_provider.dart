import 'package:flutter/material.dart';
import 'package:flutter_paint/config/assets/theme.dart';

class ThemeProvider extends ChangeNotifier {
  Brightness _brightness = Brightness.light;

  ThemeData _themeData = AppTheme.getTheme(Brightness.light);

  ThemeData get themeData => _themeData;

  void toggleTheme() {
    _brightness = _brightness == Brightness.light ? Brightness.dark : Brightness.light;
    _themeData = AppTheme.getTheme(_brightness);
    notifyListeners();
  }
}