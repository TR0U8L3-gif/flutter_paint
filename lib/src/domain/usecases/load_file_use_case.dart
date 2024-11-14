import 'dart:typed_data';

import 'package:flutter_paint/core/utils/response.dart';
import 'package:flutter_paint/core/utils/typedef.dart';
import 'package:flutter_paint/core/utils/use_case.dart';
import 'package:flutter_paint/src/domain/repositories/paint_repository.dart';
import 'package:injectable/injectable.dart';

@singleton
class LoadFileUseCase extends UseCase<Uint8List,LoadFileUseCaseParams> {
  LoadFileUseCase({required PaintRepository repository}) : _repository = repository;
  final PaintRepository _repository;

  @override
  ResultFuture<Failure, Uint8List> call(LoadFileUseCaseParams params) {
    return _repository.loadFile(params.path, params.extension);
  }
  
}

class LoadFileUseCaseParams {
  LoadFileUseCaseParams({required this.path, required this.extension});
  
  final String path;
  final String extension;
}