import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/config/injectable/injectable.dart';
import 'package:flutter_paint/core/common/presentation/logic/theme_provider.dart';
import 'package:flutter_paint/core/common/presentation/widgets/app_nav_bar.dart';
import 'package:flutter_paint/src/data/data_source/paint_local_data_source.dart';
import 'package:flutter_paint/src/data/repositories/paint_repository_impl.dart';
import 'package:flutter_paint/src/domain/entites/drawing_canvas_options.dart';
import 'package:flutter_paint/src/presentation/logic/paint_cubit.dart';
import 'package:flutter_paint/src/presentation/widgets/canvas_side_bar.dart';
import 'package:flutter_paint/src/presentation/widgets/drawing_canvas.dart';
import 'package:provider/provider.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey canvasGlobalKey = GlobalKey();

  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => locator<PaintCubit>(),
        child: BlocConsumer<PaintCubit, PaintState>(
          listener: (context, state) {
            if (state is PaintMessage) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                ),
              );
            }
          },
          builder: (context, state) {
            final paintCubit = context.read<PaintCubit>();
            final themeData = context.watch<ThemeProvider>().themeData;
            PaintIdle currentState;
            if (state is PaintIdle) {
              currentState = state;
            } else {
              currentState = paintCubit.buildState;
            }

            final options = DrawingCanvasOptions(
              strokeColor: currentState.selectedColor,
              size: currentState.strokeSize,
              opacity: 1.0,
              currentTool: currentState.drawingTool,
              showGrid: currentState.showGrid,
              polygonSides: currentState.polygonSides,
              fillShape: currentState.filled,
            );

            return Stack(
              children: [
                DrawingCanvas(
                  canvasKey: canvasGlobalKey,
                  options: options,
                  strokes: currentState.strokes,
                  currentStroke: currentState.currentStroke,
                  isDarkTheme: themeData.brightness == Brightness.dark,
                  onPointerUp: paintCubit.onPointerUp,
                  onPointerMove: paintCubit.onPointerMove,
                  onPointerDown: paintCubit.onPointerDown,
                ),
                // CanvasSideBar
                Positioned(
                  top: kToolbarHeight,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(animationController),
                    child: CanvasSideBar(
                      canvasGlobalKey: canvasGlobalKey,
                      selectedColor: currentState.selectedColor,
                      selectedStrokeSize: currentState.strokeSize,
                      selectedDrawingTool: currentState.drawingTool,
                      isFilled: currentState.filled,
                      selectedPolygonSides: currentState.polygonSides,
                      isGridShowed: currentState.showGrid,
                      canUndo: currentState.canUndo,
                      canRedo: currentState.canRedo,
                      onFilledChanged: paintCubit.updateFilled,
                      onColorChanged: paintCubit.updateSelectedColor,
                      onGridShowedChanged: paintCubit.updateShowGrid,
                      onStrokeSizeChanged: paintCubit.updateStrokeSize,
                      onPolygonSidesChanged: paintCubit.updatePolygonSides,
                      onDrawingToolChanged: paintCubit.updateDrawingTool,
                      onUndo: paintCubit.undo,
                      onRedo: paintCubit.redo,
                      onClear: paintCubit.clear,
                      saveFile: paintCubit.saveFile,
                    ),
                  ),
                ),
                // AppNavBar
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
            );
          },
        ),
      ),
    );
  }
}
