import 'package:flutter_paint/core/common/domain/image_file.dart';
import 'package:flutter_paint/core/utils/response.dart';
import 'package:flutter_paint/core/utils/typedef.dart';
import 'package:flutter_paint/core/utils/use_case.dart';
import 'package:flutter_paint/src/domain/repositories/paint_repository.dart';
import 'package:injectable/injectable.dart';

@singleton
class ImportFileUseCase extends UseCase<ImageFile,ImportFileUseCaseParams> {
  ImportFileUseCase({required PaintRepository repository}) : _repository = repository;
  final PaintRepository _repository;

  @override
  ResultFuture<Failure, ImageFile> call(ImportFileUseCaseParams params) {
    return _repository.importFile(params.path, params.imageFile, params.isFile);
  }
  
}

class ImportFileUseCaseParams {
  ImportFileUseCaseParams({required this.imageFile, required this.path, required this.isFile});
  
  final ImageFile imageFile;
  final String path;
  final bool isFile;
}