import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_paint/core/common/domain/stroke.dart';
import 'package:flutter_paint/core/extensions/context_extensions.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';
import 'package:flutter_paint/src/domain/models/undo_redo_stack.dart';
import 'package:flutter_paint/src/presentation/logic/current_stroke_value_notifier.dart';
import 'package:flutter_paint/src/presentation/widgets/color_palette.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';

class CanvasSideBar extends StatefulWidget {
  const CanvasSideBar({
    Key? key,
    required this.selectedColor,
    required this.strokeSize,
    required this.drawingTool,
    required this.currentSketch,
    required this.allSketches,
    required this.canvasGlobalKey,
    required this.filled,
    required this.polygonSides,
    required this.backgroundImage,
    required this.undoRedoStack,
    required this.showGrid,
  }) : super(key: key);

  final ValueNotifier<Color> selectedColor;
  final ValueNotifier<double> strokeSize;
  final ValueNotifier<DrawingTool> drawingTool;
  final CurrentStrokeValueNotifier currentSketch;
  final ValueNotifier<List<Stroke>> allSketches;
  final GlobalKey canvasGlobalKey;
  final ValueNotifier<bool> filled;
  final ValueNotifier<int> polygonSides;
  final ValueNotifier<ui.Image?> backgroundImage;
  final UndoRedoStack undoRedoStack;
  final ValueNotifier<bool> showGrid;

  @override
  State<CanvasSideBar> createState() => _CanvasSideBarState();
}

class _CanvasSideBarState extends State<CanvasSideBar> {
  UndoRedoStack get undoRedoStack => widget.undoRedoStack;

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Container(
      width: 320,
      height: 440,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.3),
            blurRadius: 3,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          widget.selectedColor,
          widget.strokeSize,
          widget.drawingTool,
          widget.filled,
          widget.polygonSides,
          widget.backgroundImage,
          widget.showGrid,
        ]),
        builder: (context, _) {
          return Scrollbar(
            controller: scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(10.0),
                  controller: scrollController,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Shapes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(
                      color: theme.onPrimaryContainer,
                    ),
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _IconBox(
                          iconData: FontAwesomeIcons.pencil,
                          selected:
                              widget.drawingTool.value == DrawingTool.pencil,
                          onTap: () =>
                              widget.drawingTool.value = DrawingTool.pencil,
                          tooltip: 'Pencil',
                        ),
                        _IconBox(
                          selected:
                              widget.drawingTool.value == DrawingTool.eraser,
                          onTap: () =>
                              widget.drawingTool.value = DrawingTool.eraser,
                          tooltip: 'Eraser',
                          iconData: FontAwesomeIcons.eraser,
                        ),
                        _IconBox(
                          selected:
                              widget.drawingTool.value == DrawingTool.line,
                          onTap: () =>
                              widget.drawingTool.value = DrawingTool.line,
                          tooltip: 'Line',
                          iconData: Icons.remove,
                        ),
                        _IconBox(
                          iconData: Icons.hexagon_outlined,
                          selected:
                              widget.drawingTool.value == DrawingTool.polygon,
                          onTap: () =>
                              widget.drawingTool.value = DrawingTool.polygon,
                          tooltip: 'Polygon',
                        ),
                        _IconBox(
                          iconData: FontAwesomeIcons.square,
                          selected:
                              widget.drawingTool.value == DrawingTool.square,
                          onTap: () =>
                              widget.drawingTool.value = DrawingTool.square,
                          tooltip: 'Square',
                        ),
                        _IconBox(
                          iconData: FontAwesomeIcons.circle,
                          selected:
                              widget.drawingTool.value == DrawingTool.circle,
                          onTap: () =>
                              widget.drawingTool.value = DrawingTool.circle,
                          tooltip: 'Circle',
                        ),
                        // _IconBox(
                        //   iconData: FontAwesomeIcons.text,
                        //   selected: widget.drawingTool.value == DrawingTool.text,
                        //   onTap: () =>
                        //       widget.drawingTool.value = DrawingTool.text,
                        //   tooltip: 'Text',
                        // ),
                        _IconBox(
                          iconData: FontAwesomeIcons.ruler,
                          selected: widget.showGrid.value,
                          onTap: () =>
                              widget.showGrid.value = !widget.showGrid.value,
                          tooltip: 'Guide Lines',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (widget.drawingTool.value == DrawingTool.polygon ||
                        widget.drawingTool.value == DrawingTool.circle ||
                        widget.drawingTool.value == DrawingTool.square)
                      Row(
                        children: [
                          const Text(
                            'Fill Shape: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          Checkbox(
                            value: widget.filled.value,
                            onChanged: (val) {
                              widget.filled.value = val ?? false;
                            },
                          ),
                        ],
                      ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: widget.drawingTool.value == DrawingTool.polygon
                          ? Row(
                              children: [
                                const Text(
                                  'Polygon Sides: ',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Slider(
                                  value: widget.polygonSides.value.toDouble(),
                                  inactiveColor:
                                      theme.tertiary.withOpacity(0.8),
                                  min: 3,
                                  max: 8,
                                  onChanged: (val) {
                                    widget.polygonSides.value = val.toInt();
                                  },
                                  label: '${widget.polygonSides.value}',
                                  divisions: 5,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    if(widget.drawingTool.value != DrawingTool.eraser) ...[
                    const Text(
                      'Colors',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(
                      color: theme.onPrimaryContainer,
                    ),
                    ColorPalette(
                      selectedColor: widget.selectedColor.value,
                      onColorChanged: (color) {
                        widget.selectedColor.value = color;
                      },
                    ),
                    const SizedBox(height: 20),
                    ],
                    const Text(
                      'Size',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(
                      color: theme.onPrimaryContainer,
                    ),
                    Row(
                      children: [
                        const Text(
                          'Stroke Size: ',
                          style: TextStyle(fontSize: 14),
                        ),
                        Slider(
                          value: widget.strokeSize.value,
                          min: 0,
                          max: 50,
                          inactiveColor: theme.tertiary.withOpacity(0.8),
                          onChanged: (val) {
                            widget.strokeSize.value = val;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Actions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(
                      color: theme.onPrimaryContainer,
                    ),
                    Wrap(
                      children: [
                        TextButton(
                          onPressed: widget.allSketches.value.isNotEmpty
                              ? () => undoRedoStack.undo()
                              : null,
                          child: const Text('Undo'),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: undoRedoStack.canRedo,
                          builder: (_, canRedo, __) {
                            return TextButton(
                              onPressed:
                                  canRedo ? () => undoRedoStack.redo() : null,
                              child: const Text('Redo'),
                            );
                          },
                        ),
                        TextButton(
                          child: const Text('Clear'),
                          onPressed: () => undoRedoStack.clear(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Export',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(
                      color: theme.onPrimaryContainer,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: TextButton(
                            child: const Text('Export PNG'),
                            onPressed: () async {
                              Uint8List? pngBytes = await getBytes();
                              if (pngBytes != null)
                                saveFile(pngBytes, 'png').then((value) =>
                                    context.showSnackBarUsingText(value));
                            },
                          ),
                        ),
                        Flexible(
                          child: TextButton(
                            child: const Text('Export JPEG'),
                            onPressed: () async {
                              Uint8List? pngBytes = await getBytes();
                              if (pngBytes != null)
                                saveFile(pngBytes, 'jpeg').then((value) =>
                                    context.showSnackBarUsingText(value));
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String> saveFile(Uint8List bytes, String extension) async {
    try {
      String directoryPath;

      if (Platform.isAndroid || Platform.isIOS) {
        // Get the external storage directory for Android and iOS
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          return ('Could not access external storage.');
        }
        directoryPath = directory.path;
      } else if (Platform.isWindows) {
        // Get the Documents directory for Windows
        final directory = await getApplicationDocumentsDirectory();
        directoryPath = directory.path;
      } else {
        return ('Unsupported platform');
      }

      // Define the file name with a unique timestamp
      final String fileName =
          'file_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final String filePath = '$directoryPath/$fileName';

      // Create the file and write the bytes to it
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      return ('File saved at: $filePath');
    } catch (e) {
      return ('Error saving file: $e');
    }
  }

  Future<Uint8List?> getBytes() async {
    RenderRepaintBoundary boundary = widget.canvasGlobalKey.currentContext
        ?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();
    return pngBytes;
  }
}

class _IconBox extends StatelessWidget {
  final IconData? iconData;
  final Widget? child;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  const _IconBox({
    Key? key,
    this.iconData,
    this.child,
    this.tooltip,
    required this.selected,
    required this.onTap,
  })  : assert(child != null || iconData != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? theme.primary : Colors.transparent,
              width: 2.4,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: Tooltip(
            message: tooltip,
            preferBelow: false,
            child: child ??
                Icon(
                  iconData,
                  color: selected ? theme.primary : theme.tertiary,
                  size: 20,
                ),
          ),
        ),
      ),
    );
  }
}
