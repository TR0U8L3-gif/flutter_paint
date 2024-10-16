import 'package:flutter/rendering.dart';
import 'package:flutter_paint/src/data/data_source/paint_local_data_source.dart';
import 'package:flutter_paint/src/domain/repositories/paint_repository.dart';
import 'package:fpdart/fpdart.dart';

class PaintRepositoryImpl implements PaintRepository {
  const PaintRepositoryImpl({
    required PaintLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;
  
  final PaintLocalDataSource _localDataSource;

  @override
  Future<Either<String, String?>> saveFile(RenderRepaintBoundary boundary,  String extension) async {
    try {
      final result = await _localDataSource.saveFile(boundary, extension);
      return right(result);
    } catch (e) {
      return left('Error saving file: $e');
    }
  }
  
}