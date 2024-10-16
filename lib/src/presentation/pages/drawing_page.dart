import 'package:flutter/material.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/core/common/presentation/logic/theme_provider.dart';
import 'package:flutter_paint/core/common/presentation/widgets/app_nav_bar.dart';
import 'package:flutter_paint/core/extensions/drawing_tool_extensions.dart';
import 'package:flutter_paint/core/extensions/offset_extensions.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';
import 'package:flutter_paint/core/utils/helpers/value_listenable_builder_7.dart';
import 'package:flutter_paint/src/domain/models/drawing_canvas_options.dart';
import 'package:flutter_paint/src/domain/models/undo_redo_stack.dart';
import 'package:flutter_paint/src/presentation/logic/current_stroke_value_notifier.dart';
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
  late final AnimationController animationController;

  final GlobalKey canvasGlobalKey = GlobalKey();

  final ValueNotifier<Color> selectedColorNotifier =
      ValueNotifier(Colors.black);
  final ValueNotifier<double> strokeSizeNotifier = ValueNotifier(10.0);
  final ValueNotifier<DrawingTool> drawingToolNotifier =
      ValueNotifier(DrawingTool.pencil);
  final ValueNotifier<bool> filledNotifier = ValueNotifier(false);
  final ValueNotifier<int> polygonSidesNotifier = ValueNotifier(3);
  final ValueNotifier<List<Stroke>> allStrokesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> showGridNotifier = ValueNotifier(false);
  late final UndoRedoStack undoRedoStack;
  final CurrentStrokeValueNotifier currentStroke = CurrentStrokeValueNotifier();

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    undoRedoStack = UndoRedoStack(
      currentStrokeNotifier: currentStroke,
      strokesNotifier: allStrokesNotifier,
    );
  }

  void _onPointerDown(PointerDownEvent event, DrawingCanvasOptions options) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.globalToLocal(event.position);
    // convert the offset to standard size so that it
    // can be scaled back to the device size
    final standardOffset = offset.scaleToStandard(box.size);
    currentStroke.startStroke(
      standardOffset,
      color: options.strokeColor,
      size: options.size,
      opacity: options.opacity,
      type: options.currentTool.strokeType,
      sides: polygonSidesNotifier.value,
      filled: filledNotifier.value,
    );
    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent event) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final offset = box.globalToLocal(event.position);
    // convert the offset to standard size so that it
    // can be scaled back to the device size
    final standardOffset = offset.scaleToStandard(box.size);
    currentStroke.addPoint(standardOffset);
    setState(() {});
  }

  void _onPointerUp(PointerUpEvent event) {
    allStrokesNotifier.value = List<Stroke>.from(allStrokesNotifier.value)
      ..add(currentStroke.value!);
    currentStroke.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder7<Color, double, DrawingTool, bool, int, List,
          bool>(
        valueListenableA: selectedColorNotifier,
        valueListenableB: strokeSizeNotifier,
        valueListenableC: drawingToolNotifier,
        valueListenableD: filledNotifier,
        valueListenableE: polygonSidesNotifier,
        valueListenableF: allStrokesNotifier,
        valueListenableG: showGridNotifier,
        builder: (context, selectedColor, strokeSize, drawingTool, filled,
            polygonSides, _, showGrid, __) {
          final options = DrawingCanvasOptions(
            currentTool: drawingTool,
            size: strokeSize,
            strokeColor: selectedColor,
            polygonSides: polygonSides,
            showGrid: showGrid,
            fillShape: filled,
          );
          return Stack(
            children: [
              DrawingCanvas(
                options: options,
                canvasKey: canvasGlobalKey,
                currentStroke: currentStroke.value,
                strokes: allStrokesNotifier.value,
                showGrid: showGrid,
                isDarkTheme:
                    context.watch<ThemeProvider>().themeData.brightness ==
                        Brightness.dark,
                onPointerUp: _onPointerUp,
                onPointerMove: _onPointerMove,
                onPointerDown: (event) => _onPointerDown(event, options),
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
                    selectedColor: selectedColor,
                    selectedStrokeSize: strokeSize,
                    selectedDrawingTool: drawingTool,
                    isFilled: filled,
                    selectedPolygonSides: polygonSides,
                    isGridShowed: showGrid,
                    canUndo: undoRedoStack.canUndo,
                    canRedo: undoRedoStack.canRedo,
                    onFilledChanged: (isFilled) =>
                        filledNotifier.value = isFilled,
                    onColorChanged: (newColor) =>
                        selectedColorNotifier.value = newColor,
                    onGridShowedChanged: (isGridShowed) =>
                        showGridNotifier.value = isGridShowed,
                    onStrokeSizeChanged: (newStrokeSize) =>
                        strokeSizeNotifier.value = newStrokeSize,
                    onPolygonSidesChanged: (newPolygonSides) =>
                        polygonSidesNotifier.value = newPolygonSides,
                    onDrawingToolChanged: (newDrawingTool) =>
                        drawingToolNotifier.value = newDrawingTool,
                    onUndo: undoRedoStack.undo,
                    onRedo: undoRedoStack.redo,
                    onClear: undoRedoStack.clear,
                    saveFile: (boundary, extension) {},
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
    );
  }
}

// add it to domain and data layer
//
// Future<String> saveFile(Uint8List bytes, String extension) async {
//   try {
//     String directoryPath;

//     if (Platform.isAndroid || Platform.isIOS) {
//       // Get the external storage directory for Android and iOS
//       final directory = await getExternalStorageDirectory();
//       if (directory == null) {
//         return ('Could not access external storage.');
//       }
//       directoryPath = directory.path;
//     } else if (Platform.isWindows) {
//       // Get the Documents directory for Windows
//       final directory = await getApplicationDocumentsDirectory();
//       directoryPath = directory.path;
//     } else {
//       return ('Unsupported platform');
//     }

//     // Define the file name with a unique timestamp
//     final String fileName =
//         'file_${DateTime.now().millisecondsSinceEpoch}.$extension';
//     final String filePath = '$directoryPath/$fileName';

//     // Create the file and write the bytes to it
//     final File file = File(filePath);
//     await file.writeAsBytes(bytes);

//     return ('File saved at: $filePath');
//   } catch (e) {
//     return ('Error saving file: $e');
//   }
// }

// Future<Uint8List?> getBytes() async {
//   RenderRepaintBoundary boundary = canvasGlobalKey.currentContext
//       ?.findRenderObject() as RenderRepaintBoundary;
//   ui.Image image = await boundary.toImage();
//   ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//   Uint8List? pngBytes = byteData?.buffer.asUint8List();
//   return pngBytes;
// }
