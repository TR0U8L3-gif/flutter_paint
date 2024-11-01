import 'package:flutter/material.dart' hide Image;
import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/image_file.dart';
import 'package:flutter_paint/core/utils/enums/drawing_tool.dart';
import 'package:flutter_paint/src/presentation/widgets/color_palette.dart';
import 'package:flutter_paint/src/presentation/widgets/icon_box.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CanvasSideBar extends StatelessWidget {
  const CanvasSideBar({
    super.key,
    required this.selectedColor,
    required this.additionalColor,
    required this.selectedStrokeSize,
    required this.selectedDrawingTool,
    required this.canvasGlobalKey,
    required this.isFilled,
    required this.selectedPolygonSides,
    required this.isGridShowed,
    required this.canUndo,
    required this.canRedo,
    required this.onFilledChanged,
    required this.onColorChanged,
    required this.onAdditionalColorChanged,
    required this.onGridShowedChanged,
    required this.onStrokeSizeChanged,
    required this.onPolygonSidesChanged,
    required this.onDrawingToolChanged,
    required this.onUndo,
    required this.onRedo,
    required this.onClear,
    required this.saveFile,
    required this.onExport,
    required this.onImport,
  });

  final GlobalKey canvasGlobalKey;

  final Color? selectedColor;
  final Color additionalColor;
  final double selectedStrokeSize;
  final DrawingTool selectedDrawingTool;
  final int selectedPolygonSides;
  final bool isFilled;
  final bool isGridShowed;
  final bool canUndo;
  final bool canRedo;

  final void Function(bool isFilled) onFilledChanged;
  final void Function(Color selectedColor) onColorChanged;
  final void Function() onAdditionalColorChanged;
  final void Function(bool isGridShowed) onGridShowedChanged;
  final void Function(double selectedStrokeSize) onStrokeSizeChanged;
  final void Function(int selectedPolygonSides) onPolygonSidesChanged;
  final void Function(DrawingTool selectedDrawingTool) onDrawingToolChanged;
  final void Function() onUndo;
  final void Function() onRedo;
  final void Function() onClear;
  final void Function(
    RenderRepaintBoundary? boundary,
    ImageFile file,
  ) onExport;
  final void Function(
    ImageFile file,
  ) onImport;
  final void Function(
    RenderRepaintBoundary? boundary,
    String fileExtension,
  ) saveFile;

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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
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
                  IconBox(
                    iconData: FontAwesomeIcons.pencil,
                    selected: selectedDrawingTool == DrawingTool.pencil,
                    onTap: () => onDrawingToolChanged(DrawingTool.pencil),
                    tooltip: 'Pencil',
                  ),
                  IconBox(
                    selected: selectedDrawingTool == DrawingTool.eraser,
                    onTap: () => onDrawingToolChanged(DrawingTool.eraser),
                    tooltip: 'Eraser',
                    iconData: FontAwesomeIcons.eraser,
                  ),
                  IconBox(
                    selected: selectedDrawingTool == DrawingTool.line,
                    onTap: () => onDrawingToolChanged(DrawingTool.line),
                    tooltip: 'Line',
                    iconData: Icons.remove,
                  ),
                  IconBox(
                    iconData: Icons.hexagon_outlined,
                    selected: selectedDrawingTool == DrawingTool.polygon,
                    onTap: () => onDrawingToolChanged(DrawingTool.polygon),
                    tooltip: 'Polygon',
                  ),
                  IconBox(
                    iconData: FontAwesomeIcons.square,
                    selected: selectedDrawingTool == DrawingTool.square,
                    onTap: () => onDrawingToolChanged(DrawingTool.square),
                    tooltip: 'Square',
                  ),
                  IconBox(
                    iconData: FontAwesomeIcons.circle,
                    selected: selectedDrawingTool == DrawingTool.circle,
                    onTap: () => onDrawingToolChanged(DrawingTool.circle),
                    tooltip: 'Circle',
                  ),
                  // IconBox(
                  //   iconData: FontAwesomeIcons.text,
                  //   selected: selectedDrawingTool == DrawingTool.text,
                  //   onTap: () =>
                  //       sonDrawingToolChanged(DrawingTool.text,
                  //   tooltip: 'Text',
                  // ),
                  IconBox(
                    iconData: FontAwesomeIcons.ruler,
                    selected: isGridShowed,
                    onTap: () => onGridShowedChanged(!isGridShowed),
                    tooltip: 'Guide Lines',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (selectedDrawingTool == DrawingTool.polygon ||
                  selectedDrawingTool == DrawingTool.circle ||
                  selectedDrawingTool == DrawingTool.square)
                Row(
                  children: [
                    const Text(
                      'Fill Shape: ',
                      style: TextStyle(fontSize: 12),
                    ),
                    Checkbox(
                      value: isFilled,
                      onChanged: (val) => onFilledChanged(val ?? false),
                    ),
                  ],
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: selectedDrawingTool == DrawingTool.polygon
                    ? Row(
                        children: [
                          const Text(
                            'Polygon Sides: ',
                            style: TextStyle(fontSize: 12),
                          ),
                          Slider(
                            value: selectedPolygonSides.toDouble(),
                            inactiveColor: theme.tertiary.withOpacity(0.8),
                            min: 3,
                            max: 8,
                            onChanged: (val) =>
                                onPolygonSidesChanged(val.toInt()),
                            label: '$selectedPolygonSides',
                            divisions: 5,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              if (selectedDrawingTool != DrawingTool.eraser) ...[
                const Text(
                  'Colors',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Divider(
                  color: theme.onPrimaryContainer,
                ),
                ColorPalette(
                  selectedColor: selectedColor,
                  additionalColor: additionalColor,
                  onColorChanged: (color) => onColorChanged(color),
                  onAdditionalColorChanged: onAdditionalColorChanged,
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
                    value: selectedStrokeSize,
                    min: 0,
                    max: 50,
                    inactiveColor: theme.tertiary.withOpacity(0.8),
                    onChanged: (val) => onStrokeSizeChanged(val),
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
              // create undo state
              Wrap(
                children: [
                  TextButton(
                    onPressed: canUndo ? () => onUndo() : null,
                    child: const Text('Undo'),
                  ),
                  TextButton(
                    onPressed: canRedo ? () => onRedo() : null,
                    child: const Text('Redo'),
                  ),
                  TextButton(
                    onPressed: () => onClear(),
                    child: const Text('Clear'),
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
                      onPressed: () => saveFile(
                          canvasGlobalKey.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?,
                          'png'),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      child: const Text('Export JPEG'),
                      onPressed: () => saveFile(
                          canvasGlobalKey.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?,
                          'jpeg'),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: TextButton(
                      child: const Text('PBM '),
                      onPressed: () => onExport(
                          canvasGlobalKey.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?,
                          PBMFile()),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      child: const Text('PGM'),
                      onPressed: () => onExport(
                          canvasGlobalKey.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?,
                          PGMFile()),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      child: const Text('PPM '),
                      onPressed: () => onExport(
                          canvasGlobalKey.currentContext?.findRenderObject()
                              as RenderRepaintBoundary?,
                          PPMFile()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Import',
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
                      child: const Text('PBM'),
                      onPressed: () => onImport(PBMFile()),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      child: const Text('PGM '),
                      onPressed: () => onImport(PGMFile()),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      child: const Text('PPM  '),
                      onPressed: () => onImport(PPMFile()),
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
  }
}
