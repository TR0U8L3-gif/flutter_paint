import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:bloc/bloc.dart';

class ColorAreaSelectionCubit extends Cubit<Uint8List?> {
  ColorAreaSelectionCubit() : super(null);

  Uint8List? originalImage; // Oryginalny obraz do resetu.
  Uint8List? modifiedImage; // Zmieniony obraz.
  ui.Color? selectedColor; // Wybrany kolor.
  double threshold = 5.0; // Wartość progu.

  void init(Uint8List image) {
    originalImage = image;
    modifiedImage = image;
    emit(image);
  }

  void setThreshold(double value) {
    threshold = value;
  }

  void setSelectedColor(ui.Color color) {
    selectedColor = color;
  }

  void resetImage() {
    modifiedImage = originalImage;
    emit(originalImage);
  }

  Future<void> processImage() async {
    if (selectedColor == null || modifiedImage == null) return;

    // Dekodowanie obrazu na piksele.
    final ui.Codec codec = await ui.instantiateImageCodec(modifiedImage!);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    final Uint8List pixels = byteData.buffer.asUint8List();

    // Przetwarzanie każdego piksela.
    for (int i = 0; i < pixels.length; i += 4) {
      // Piksel RGBA.
      final int r = pixels[i];
      final int g = pixels[i + 1];
      final int b = pixels[i + 2];
      final int a = pixels[i + 3];

      // Oblicz różnicę z wybranym kolorem.
      final double diff = _colorDifference(
        ui.Color.fromARGB(a, r, g, b),
        selectedColor!,
      );

      // Jeśli różnica jest mniejsza niż threshold, ustaw przezroczystość.
      if (diff < threshold) {
        pixels[i + 3] = 0; // Alpha = 0 (całkowicie przezroczysty)
      }
    }

    // Tworzenie nowego obrazu.
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(pixels);
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: image.width,
      height: image.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec newCodec = await descriptor.instantiateCodec();
    final ui.FrameInfo newFrame = await newCodec.getNextFrame();
    final ByteData? newByteData =
        await newFrame.image.toByteData(format: ui.ImageByteFormat.png);

    if (newByteData != null) {
      modifiedImage = newByteData.buffer.asUint8List();
      emit(modifiedImage);
    }
  }

  Future<void> processLargestGroup() async {
    if (selectedColor == null || modifiedImage == null) return;

    // Dekodowanie obrazu.
    final ui.Codec codec = await ui.instantiateImageCodec(modifiedImage!);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    final Uint8List pixels = byteData.buffer.asUint8List();
    final int width = image.width;
    final int height = image.height;

    // Tablica do oznaczania odwiedzonych pikseli.
    final visited = List.generate(height, (_) => List.filled(width, false));
    final List<List<int>> groups = [];

    // Funkcja pomocnicza do obliczania różnicy koloru.
    bool _isWithinThreshold(int x, int y) {
      final int index = (y * width + x) * 4;
      final int r = pixels[index];
      final int g = pixels[index + 1];
      final int b = pixels[index + 2];
      final int a = pixels[index + 3];

      if (a == 0) return false; // Przezroczysty piksel.
      final double diff = _colorDifference(
        ui.Color.fromARGB(a, r, g, b),
        selectedColor!,
      );
      return diff < threshold;
    }

    // Flood Fill do znajdowania grup.
    List<int> _floodFill(int startX, int startY) {
      final queue = <List<int>>[
        [startX, startY]
      ];
      final group = <int>[];

      while (queue.isNotEmpty) {
        final point = queue.removeLast();
        final x = point[0];
        final y = point[1];

        if (x < 0 || x >= width || y < 0 || y >= height || visited[y][x])
          continue;

        visited[y][x] = true;
        if (!_isWithinThreshold(x, y)) continue;

        // Dodaj piksel do grupy.
        group.add(y * width + x);

        // Sprawdź sąsiednie piksele.
        queue.add([x + 1, y]);
        queue.add([x - 1, y]);
        queue.add([x, y + 1]);
        queue.add([x, y - 1]);
      }

      return group;
    }

    // Znajdź wszystkie grupy pikseli.
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!visited[y][x] && _isWithinThreshold(x, y)) {
          final group = _floodFill(x, y);
          if (group.isNotEmpty) {
            groups.add(group);
          }
        }
      }
    }

    // Znajdź największą grupę.
    List<int>? largestGroup;
    for (final group in groups) {
      if (largestGroup == null || group.length > largestGroup.length) {
        largestGroup = group;
      }
    }

    // Ustaw największą grupę na przezroczystą.
    if (largestGroup != null) {
      for (final index in largestGroup) {
        final pixelIndex = index * 4;
        pixels[pixelIndex + 3] = 0; // Alpha = 0
      }
    }

    // Tworzenie nowego obrazu.
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(pixels);
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final ui.Codec newCodec = await descriptor.instantiateCodec();
    final ui.FrameInfo newFrame = await newCodec.getNextFrame();
    final ByteData? newByteData =
        await newFrame.image.toByteData(format: ui.ImageByteFormat.png);

    if (newByteData != null) {
      modifiedImage = newByteData.buffer.asUint8List();
      emit(modifiedImage);
    }
  }

// Pomocnicza funkcja do obliczania różnicy między dwoma kolorami.
  double _colorDifference(ui.Color c1, ui.Color c2) {
    final double rDiff = (c1.red - c2.red).abs().toDouble();
    final double gDiff = (c1.green - c2.green).abs().toDouble();
    final double bDiff = (c1.blue - c2.blue).abs().toDouble();
    return (rDiff + gDiff + bDiff) / 3.0;
  }
}
