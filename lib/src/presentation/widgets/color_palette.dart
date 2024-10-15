import 'package:flutter/material.dart';

class ColorPalette extends StatelessWidget {
  const ColorPalette({
    super.key,
    required this.selectedColor,
    this.onColorChanged,
  });

  final Color selectedColor;
  final void Function(Color selectedColor)? onColorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    final List<Color> colors = [
      Colors.black,
      Colors.white,
      ...Colors.primaries,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 2,
          runSpacing: 2,
          children: [
            for (Color color in colors)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onColorChanged?.call(color),
                  child: Container(
                    height: 25,
                    width: 25,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: selectedColor == color
                            ? theme.primary
                            : Colors.transparent,
                        width: 2.4,
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
