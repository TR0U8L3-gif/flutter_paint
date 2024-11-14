import 'package:flutter/services.dart';
import 'package:flutter_paint/src/presentation/logic/image_processing_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'dart:typed_data';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ImageProcessingCubit', () {
    late ImageProcessingCubit cubit;
    late Uint8List testImage;

    setUp(() async {
      cubit = ImageProcessingCubit();
      testImage = await rootBundle
          .load('assets/test_image.png')
          .then((data) => data.buffer.asUint8List());
    });

    tearDown(() {
      cubit.close();
    });

    group('Initial state', () {
      test('Initial state is ImageProcessingInitial', () {
        expect(cubit.state, isA<ImageProcessingInitial>());
      });
    });

    group('loadImage', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageLoaded] when an image is loaded',
        build: () => ImageProcessingCubit(),
        act: (cubit) => cubit.loadImage(testImage),
        expect: () => [
          isA<ImageLoaded>().having(
            (state) => state.imageBytes,
            'imageBytes',
            testImage,
          ),
        ],
      );
    });

    group('addRGB', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after addRGB is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.addRGB(10, 10, 10),
        wait: const Duration(milliseconds: 2000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('subtractRGB', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after subtractRGB is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.subtractRGB(50, 50, 50),
        wait: const Duration(milliseconds: 2000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('multiplyRGB', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after multiplyRGB is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.multiplyRGB(1.5, 1.5, 1.5),
        wait: const Duration(milliseconds: 2000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('divideRGB', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after divideRGB is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.divideRGB(2, 2, 2),
        wait: const Duration(milliseconds: 2000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('adjustBrightness', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after adjustBrightness is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.adjustBrightness(30),
        wait: const Duration(milliseconds: 2000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('grayscale', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after grayscale is applied with average method',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.grayscale('average'),
        wait: const Duration(milliseconds: 2000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('applySmoothingFilter', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after applySmoothingFilter is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.applySmoothingFilter(),
        wait: const Duration(milliseconds: 4000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('applyMedianFilter', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after applyMedianFilter is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.applyMedianFilter(),
        wait: const Duration(milliseconds: 4000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('applySobelFilter', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after applySobelFilter is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.applySobelFilter(),
        wait: const Duration(milliseconds: 4000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('applySharpeningFilter', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after applySharpeningFilter is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.applySharpeningFilter(),
        wait: const Duration(milliseconds: 4000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('applyGaussianBlur', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'emits [ImageProcessed] after applyGaussianBlur is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) => cubit.applyGaussianBlur(),
        wait: const Duration(milliseconds: 4000),
        expect: () => [
          isA<ImageProcessed>(),
        ],
      );
    });

    group('restart', () {
      blocTest<ImageProcessingCubit, ImageProcessingState>(
        'resets processed image to original after restart is called',
        build: () =>
            ImageProcessingCubit()..loadImage(Uint8List.fromList(testImage)),
        act: (cubit) async {
          await cubit.addRGB(10, 10, 10);
          cubit.restart();
        },
        wait: const Duration(milliseconds: 2000),
        expect: () => [
          isA<ImageProcessed>(), // After addRGB
          isA<ImageProcessed>(), // After restart
        ],
      );
    });
  });
}
