import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/image_file.dart';
import 'package:flutter_paint/core/utils/response.dart';
import 'package:flutter_paint/core/utils/typedef.dart';
import 'package:flutter_paint/core/utils/use_case.dart';
import 'package:flutter_paint/src/domain/repositories/paint_repository.dart';
import 'package:injectable/injectable.dart';

@singleton
class ExportFileUseCase
    extends UseCase<String, ExportFileUseCaseParams> {
  ExportFileUseCase({required PaintRepository repository})
      : _repository = repository;
  final PaintRepository _repository;

  @override
  ResultFuture<Failure, String> call(ExportFileUseCaseParams params) {
    return _repository.exportFile(params.boundary, params.imageFile, params.isFile);
  }
}

class ExportFileUseCaseParams {
  ExportFileUseCaseParams({
    required this.boundary,
    required this.imageFile,
    required this.isFile,
  });
  final RenderRepaintBoundary boundary;
  final ImageFile imageFile;
  final bool isFile;
}
