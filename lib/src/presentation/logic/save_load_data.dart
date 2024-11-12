import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/image_file.dart';

abstract class SaveLoadData {
  const SaveLoadData(this.imageFile);
  final ImageFile imageFile;
}

class LoadFileData implements SaveLoadData {
  const LoadFileData(this.imageFile, this.path, this.isFile);

  @override
  final ImageFile imageFile;
  final String path;
  final bool isFile;
}

class SaveFileData implements SaveLoadData {
  const SaveFileData(this.imageFile, this.boundary, this.isFile);

  @override
  final ImageFile imageFile;
  final RenderRepaintBoundary boundary;
  final bool isFile;
}
