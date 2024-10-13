import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_paint/config/assets/app_colors.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/core/common/presentation/logic/theme_provider.dart';
import 'package:flutter_paint/core/common/presentation/widgets/app_nav_bar.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';
import 'package:flutter_paint/src/domain/models/drawing_canvas_options.dart';
import 'package:flutter_paint/src/domain/models/undo_redo_stack.dart';
import 'package:flutter_paint/src/presentation/logic/current_stroke_value_notifier.dart';
import 'package:flutter_paint/src/presentation/widgets/widgets.dart';
import 'package:provider/provider.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  final ValueNotifier<Color> selectedColor = ValueNotifier(Colors.black);
  final ValueNotifier<double> strokeSize = ValueNotifier(10.0);
  final ValueNotifier<DrawingTool> drawingTool =
      ValueNotifier(DrawingTool.pencil);
  final GlobalKey canvasGlobalKey = GlobalKey();
  final ValueNotifier<bool> filled = ValueNotifier(false);
  final ValueNotifier<int> polygonSides = ValueNotifier(3);
  final ValueNotifier<ui.Image?> backgroundImage = ValueNotifier(null);
  final CurrentStrokeValueNotifier currentStroke = CurrentStrokeValueNotifier();
  final ValueNotifier<List<Stroke>> allStrokes = ValueNotifier([]);
  late final UndoRedoStack undoRedoStack;
  final ValueNotifier<bool> showGrid = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    undoRedoStack = UndoRedoStack(
      currentStrokeNotifier: currentStroke,
      strokesNotifier: allStrokes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([
              currentStroke,
              allStrokes,
              selectedColor,
              strokeSize,
              drawingTool,
              filled,
              polygonSides,
              backgroundImage,
              showGrid,
            ]),
            builder: (context, _) {
              return DrawingCanvas(
                options: DrawingCanvasOptions(
                  currentTool: drawingTool.value,
                  size: strokeSize.value,
                  strokeColor: selectedColor.value,
                  backgroundColor: AppColors.canvasColor,
                  polygonSides: polygonSides.value,
                  showGrid: showGrid.value,
                  fillShape: filled.value,
                ),
                canvasKey: canvasGlobalKey,
                currentStrokeListenable: currentStroke,
                strokesListenable: allStrokes,
                backgroundImageListenable: backgroundImage,
              );
            },
          ),
          Positioned(
            top: kToolbarHeight,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(animationController),
              child: CanvasSideBar(
                drawingTool: drawingTool,
                selectedColor: selectedColor,
                strokeSize: strokeSize,
                currentSketch: currentStroke,
                allSketches: allStrokes,
                canvasGlobalKey: canvasGlobalKey,
                filled: filled,
                polygonSides: polygonSides,
                backgroundImage: backgroundImage,
                undoRedoStack: undoRedoStack,
                showGrid: showGrid,
              ),
            ),
          ),
          AppNavBar(
            onLeadingButtonPressed: () {
              if (animationController.isCompleted) {
                animationController.reverse();
              } else {
                animationController.forward();
              }
            },
            onTrailingButtonPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
