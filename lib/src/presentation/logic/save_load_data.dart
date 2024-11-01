import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/image_file.dart';

abstract class SaveLoadData {
  const SaveLoadData(this.imageFile);
  final ImageFile imageFile;
}

class LoadFileData implements SaveLoadData {
  const LoadFileData(this.imageFile, this.path);

  @override
  final ImageFile imageFile;
  final String path;
}

class SaveFileData implements SaveLoadData {
  const SaveFileData(this.imageFile, this.boundary);

  @override
  final ImageFile imageFile;
  final RenderRepaintBoundary boundary;
}
