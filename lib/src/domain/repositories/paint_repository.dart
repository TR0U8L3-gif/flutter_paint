import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/image_file.dart';
import 'package:flutter_paint/core/utils/response.dart';
import 'package:fpdart/fpdart.dart';

abstract class PaintRepository {
  Future<Either<Failure, String?>> saveFile(RenderRepaintBoundary boundary, String extension);

  Future<Either<Failure, String>> exportFile(RenderRepaintBoundary boundary, ImageFile imageFile, bool isFile);

  Future<Either<Failure, ImageFile>> importFile(String path, ImageFile imageFile, bool isFile);
}