import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/utils/response.dart';
import 'package:flutter_paint/src/data/data_source/paint_local_data_source.dart';
import 'package:flutter_paint/src/domain/repositories/paint_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@Singleton(as: PaintRepository)
class PaintRepositoryImpl implements PaintRepository {
  const PaintRepositoryImpl({
    required PaintLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;
  
  final PaintLocalDataSource _localDataSource;

  @override
  Future<Either<Failure, String?>> saveFile(RenderRepaintBoundary boundary,  String extension) async {
    try {
      final result = await _localDataSource.saveFile(boundary, extension);
      return right(result);
    } catch (e) {
      return left(Failure(message: 'Error saving file: $e'));
    }
  }
  
}