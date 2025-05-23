import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/config/injectable/injectable.dart';
import 'package:flutter_paint/core/common/presentation/logic/theme_provider.dart';
import 'package:flutter_paint/core/common/presentation/widgets/app_nav_bar.dart';
import 'package:flutter_paint/src/domain/entities/drawing_canvas_options.dart';
import 'package:flutter_paint/src/presentation/logic/bezier_cubit.dart';
import 'package:flutter_paint/src/presentation/logic/color_area_selection_cubit.dart';
import 'package:flutter_paint/src/presentation/logic/paint_cubit.dart';
import 'package:flutter_paint/src/presentation/logic/shape_cubit.dart';
import 'package:flutter_paint/src/presentation/pages/bezier_page.dart';
import 'package:flutter_paint/src/presentation/pages/color_area_selection_page.dart';
import 'package:flutter_paint/src/presentation/pages/color_picker.dart';
import 'package:flutter_paint/src/presentation/pages/image_editor_page.dart';
import 'package:flutter_paint/src/presentation/pages/image_processing_page.dart';
import 'package:flutter_paint/src/presentation/pages/shape_creation_page.dart';
import 'package:flutter_paint/src/presentation/widgets/canvas_side_bar.dart';
import 'package:flutter_paint/src/presentation/widgets/drawing_canvas.dart';

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
              strokeColor:
                  currentState.selectedColor ?? currentState.additionalColor,
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
                      additionalColor: currentState.additionalColor,
                      selectedStrokeSize: currentState.strokeSize,
                      selectedDrawingTool: currentState.drawingTool,
                      isFilled: currentState.filled,
                      selectedPolygonSides: currentState.polygonSides,
                      isGridShowed: currentState.showGrid,
                      canUndo: currentState.canUndo,
                      canRedo: currentState.canRedo,
                      onFilledChanged: paintCubit.updateFilled,
                      onColorChanged: paintCubit.updateSelectedColor,
                      onAdditionalColorChanged: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ColorPicker(
                              initColor: currentState.additionalColor,
                            ),
                          ),
                        );
                        if (result != null) {
                          paintCubit.updateAdditionalColor(result);
                        }
                      },
                      onGridShowedChanged: paintCubit.updateShowGrid,
                      onStrokeSizeChanged: paintCubit.updateStrokeSize,
                      onPolygonSidesChanged: paintCubit.updatePolygonSides,
                      onDrawingToolChanged: paintCubit.updateDrawingTool,
                      onUndo: paintCubit.undo,
                      onRedo: paintCubit.redo,
                      onClear: paintCubit.clear,
                      saveFile: paintCubit.saveFile,
                      onExport: (boundary, file, isFile) =>
                          paintCubit.onExportFile(
                        boundary: boundary,
                        imageFile: file,
                        isFile: isFile,
                      ),
                      onImport: (file, isFile) async {
                        final result = await FilePicker.platform
                            .pickFiles(type: FileType.any);
                        paintCubit.onImportFile(
                          path: result?.files.single.path,
                          imageFile: file,
                          isFile: isFile,
                        );
                      },
                      loadFile: (extension) async {
                        final result = await FilePicker.platform
                            .pickFiles(type: FileType.image);
                        paintCubit.loadFile(
                          path: result?.files.single.path,
                          extension: extension,
                        );
                      },
                      filter: (boundary) async {
                        final data = await paintCubit
                            .convertCanvasToUint8List(canvasGlobalKey);
                        if (data == null) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ImageProcessingPage(
                                    imageBytes: data,
                                    callback: paintCubit.set,
                                  )),
                        );
                      },
                      edit: (boundary) async {
                        final data = await paintCubit
                            .convertCanvasToUint8List(canvasGlobalKey);
                        if (data == null) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ImageEditorPage(
                                    imageBytes: data,
                                    callback: paintCubit.set,
                                  )),
                        );
                      },
                      interactiveMode: (boundary) async {
                        final data = await paintCubit
                            .convertCanvasToUint8List(canvasGlobalKey);
                        if (data == null) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                    create: (_) => BezierCubit(),
                                    child: BezierPage(
                                      imageBytes: data,
                                      callback: paintCubit.set,
                                    ),
                                  )),
                        );
                      },
                      shapeCreation: (boundary) async {
                        final data = await paintCubit
                            .convertCanvasToUint8List(canvasGlobalKey);
                        if (data == null) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                    create: (_) => ShapeCubit(),
                                    child: ShapeCreationPage(
                                      imageBytes: data,
                                      callback: paintCubit.set,
                                    ),
                                  )),
                        );
                      },
                      colorAreaSelection: (boundary) async {
                        final data = await paintCubit
                            .convertCanvasToUint8List(canvasGlobalKey);
                        if (data == null) return;
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BlocProvider(
                                    create: (_) => ColorAreaSelectionCubit()..init(data),
                                    child: ColorAreaSelectionPage(
                                      imageBytes: data,
                                      callback: paintCubit.set,
                                    ),
                                  )),
                        );
                      },
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
