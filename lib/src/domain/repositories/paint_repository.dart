import 'package:flutter/rendering.dart';
import 'package:fpdart/fpdart.dart';

abstract class PaintRepository {
  Future<Either<String, String?>> saveFile(RenderRepaintBoundary boundary, String extension);
}