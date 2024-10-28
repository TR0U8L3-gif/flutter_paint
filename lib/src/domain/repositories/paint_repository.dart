import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/utils/response.dart';
import 'package:fpdart/fpdart.dart';

abstract class PaintRepository {
  Future<Either<Failure, String?>> saveFile(RenderRepaintBoundary boundary, String extension);
}