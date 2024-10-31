import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_paint/config/injectable/injectable.dart';
import 'package:flutter_paint/core/extensions/double_extension.dart';
import 'package:flutter_paint/src/presentation/logic/color_cubit.dart';
import 'package:flutter_paint/src/presentation/widgets/rgb_3d_cube.dart';

class ColorPicker extends StatelessWidget {
  const ColorPicker({
    super.key,
    required this.initColor,
  });

  final Color initColor;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => locator<ColorCubit>()..initialize(initColor),
      child: BlocBuilder<ColorCubit, ColorState>(
        builder: (context, colorState) {
          final colorCubit = context.watch<ColorCubit>();
          final state = colorState as ColorIdle;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Color Picker'),
              actions: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Select'),
                  onPressed: () {
                    Navigator.pop(context, state.color);
                  },
                ),
                const SizedBox(width: 64),
              ],
            ),
            body: Row(
              children: [
                const Flexible( 
                  flex: 1,
                  child: RGB3DCube(
                    rotateX: pi * 8 / 7,
                    rotateY: pi / 4,
                    rotateZ: 0,
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: RepaintBoundary(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context, state.color),
                                child: Container(
                                  height: 64,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: state.color,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2.4,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${state.color.value.toRadixString(16).substring(2).toUpperCase()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(
                                            color: state.color.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('RGB',
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Red: ${state.r.toInt()}',
                                      value: state.r.toDouble(),
                                      max: 255,
                                      step: 1,
                                      onChanged: (value) => colorCubit.updateRGB(
                                          value.toInt(), state.g, state.b)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Green: ${state.g.toInt()}',
                                      value: state.g.toDouble(),
                                      max: 255,
                                      step: 1,
                                      onChanged: (value) => colorCubit.updateRGB(
                                          state.r, value.toInt(), state.b)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Blue: ${state.b.toInt()}',
                                      value: state.b.toDouble(),
                                      max: 255,
                                      step: 1,
                                      onChanged: (value) => colorCubit.updateRGB(
                                          state.r, state.g, value.toInt())),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text('HSL',
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Hue: ${state.H.toInt()}',
                                      value: state.H,
                                      max: 359.9,
                                      step: 1,
                                      onChanged: (value) => colorCubit.updateHSL(
                                          value, state.S, state.L)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label:
                                          'Saturation: ${(state.S * 100).toPrecision(2)}%',
                                      value: state.S,
                                      max: 1,
                                      step: 0.01,
                                      onChanged: (value) => colorCubit.updateHSL(
                                          state.H, value, state.L)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label:
                                          'Lightness: ${(state.L * 100).toPrecision(2)}%',
                                      value: state.L,
                                      max: 1,
                                      step: 0.01,
                                      onChanged: (value) => colorCubit.updateHSL(
                                          state.H, state.S, value)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text('HSV',
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Hue: ${state.H.toInt()}',
                                      value: state.H,
                                      max: 359.9,
                                      step: 1,
                                      onChanged: (value) => colorCubit.updateHSV(
                                          value, state.S, state.V)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label:
                                          'Saturation: ${(state.S * 100).toPrecision(2)}%',
                                      value: state.S,
                                      max: 1,
                                      step: 0.01,
                                      onChanged: (value) => colorCubit.updateHSV(
                                          state.H, value, state.V)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label:
                                          'Value: ${(state.V * 100).toPrecision(2)}%',
                                      value: state.V,
                                      max: 1,
                                      step: 0.01,
                                      onChanged: (value) => colorCubit.updateHSV(
                                          state.H, state.S, value)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text('CMYK',
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Cyan: ${state.C.toPrecision(2)}',
                                      value: state.C,
                                      max: 1,
                                      step: 0.01,
                                      onChanged: (value) => colorCubit.updateCMYK(
                                          value, state.M, state.Y, state.K)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Magenta: ${state.M.toPrecision(2)}',
                                      value: state.M,
                                      max: 1,
                                      step: 0.01,
                                      onChanged: (value) => colorCubit.updateCMYK(
                                          state.C, value, state.Y, state.K)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Yellow: ${state.Y.toPrecision(2)}',
                                      value: state.Y,
                                      max: 1,
                                      step: 0.01,
                                      onChanged: (value) => colorCubit.updateCMYK(
                                          state.C, state.M, value, state.K)),
                                ),
                                Flexible(
                                  child: _BuildSlider(
                                      label: 'Black: ${state.K.toPrecision(2)}',
                                      value: state.K,
                                      max: 1,
                                      step: 0.01,
                                      onChanged: (value) => colorCubit.updateCMYK(
                                          state.C, state.M, state.Y, value)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BuildSlider extends StatelessWidget {
  const _BuildSlider({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    required this.step,
  });

  final String label;
  final double value;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: max,
                divisions: max ~/ step,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: TextEditingController(text: value.toPrecision(2).toString()),
                keyboardType: TextInputType.number,
                onSubmitted: (value) {
                  double newValue;
                  try {
                   newValue = double.parse(value);
                  } catch (e) {
                    return;
                  }
                  if (newValue >= 0 && newValue <= max) {
                    onChanged(newValue);
                    return;
                  } 

                  if (newValue < 0) {
                    onChanged(0);
                    return;
                  }

                  if (newValue > max) {
                    onChanged(max);
                    return;
                  }
                },
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
        
      ],
    );
  }
}
