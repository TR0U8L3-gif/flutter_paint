import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/utils/response.dart';
import 'package:flutter_paint/core/utils/typedef.dart';
import 'package:flutter_paint/core/utils/use_case.dart';
import 'package:flutter_paint/src/domain/repositories/paint_repository.dart';
import 'package:injectable/injectable.dart';

@singleton
class SaveFileUseCase extends UseCase<String?,SaveFileUseCaseParams> {
  SaveFileUseCase({required PaintRepository repository}) : _repository = repository;
  final PaintRepository _repository;

  @override
  ResultFuture<Failure, String?> call(SaveFileUseCaseParams params) {
    return _repository.saveFile(params.boundary, params.extension);
  }
  
}

class SaveFileUseCaseParams {

  SaveFileUseCaseParams({required this.boundary, required this.extension});

  final RenderRepaintBoundary boundary;
  final String extension;
}