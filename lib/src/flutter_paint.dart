import 'package:flutter/material.dart';
import 'package:flutter_paint/core/common/presentation/logic/theme_provider.dart';
import 'package:flutter_paint/src/presentation/pages/drawing_page.dart';
import 'package:provider/provider.dart';

class FlutterPaint extends StatelessWidget {
  const FlutterPaint({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      builder: (context, child) => MaterialApp(
        title: "Flutter Paint",
        theme: context.watch<ThemeProvider>().themeData,
        home: const DrawingPage(),
      ),
    );
  }
}
