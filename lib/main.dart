import 'package:flutter/material.dart';
import 'package:flutter_paint/config/injectable/injectable.dart';
import 'package:flutter_paint/src/flutter_paint.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await locator.allReady();
  runApp(const FlutterPaint());
}
