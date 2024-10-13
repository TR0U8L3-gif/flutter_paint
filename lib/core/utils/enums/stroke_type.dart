enum StrokeType {
  normal,
  eraser,
  line,
  polygon,
  square,
  circle;

  static StrokeType fromString(String value) {
    switch (value) {
      case 'normal':
        return StrokeType.normal;
      case 'eraser':
        return StrokeType.eraser;
      case 'line':
        return StrokeType.line;
      case 'polygon':
        return StrokeType.polygon;
      case 'square':
        return StrokeType.square;
      case 'circle':
        return StrokeType.circle;
      default:
        return StrokeType.normal;
    }
  }

  @override
  String toString() {
    switch (this) {
      case StrokeType.normal:
        return 'normal';
      case StrokeType.eraser:
        return 'eraser';
      case StrokeType.line:
        return 'line';
      case StrokeType.polygon:
        return 'polygon';
      case StrokeType.square:
        return 'square';
      case StrokeType.circle:
        return 'circle';
    }
  }
}