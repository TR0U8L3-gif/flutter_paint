import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  Size get screenSize => MediaQuery.sizeOf(this);

  EdgeInsets get screenPadding => MediaQuery.paddingOf(this);

  TextScaler get screenTextScaleFactor => MediaQuery.textScalerOf(this);

  bool get isMobile => isSmallScreen;

  bool get isSmallScreen => screenSize.width < 800;

  bool get isMediumScreen =>
      screenSize.width >= 800 && screenSize.width <= 1200;

  bool get isLargeScreen => screenSize.width > 800 && !isMediumScreen;

  bool get isPlatformDarkThemed =>
      MediaQuery.platformBrightnessOf(this) == Brightness.dark;

  void showSnackBar(SnackBar snackBar) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }

  void showSnackBarUsingText(String text) {
    final theme = Theme.of(this).colorScheme;
    final snackBar = SnackBar(
      backgroundColor: theme.primaryContainer,
      content: Text(
        text,
        style: TextStyle(color: theme.onPrimaryContainer),
      ),
    );
    ScaffoldMessenger.of(this).showSnackBar(snackBar);
  }

  double get customBorderWidth => isMobile ? 2.5 : 4;
  double get dialogWidth => isMobile ? 285 : 400;
}
