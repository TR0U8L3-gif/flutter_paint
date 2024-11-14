import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter_paint/core/common/domain/image_file.dart';
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

  @override
  Future<Either<Failure, String>> exportFile(RenderRepaintBoundary boundary, ImageFile imageFile, bool isFile) async {
    try {
      await imageFile.fromBoundaries(boundary);
      if (isFile) {
        final result = await _localDataSource.saveFileFILE(imageFile);
        return right(result);
      } else {
        final result = await _localDataSource.saveFileTXT(imageFile);
        return right(result);
      }
    } catch (e) {
      return left(Failure(message: 'Error exporting file: $e'));
    }
    
  }

  @override
  Future<Either<Failure, ImageFile>> importFile(String path, ImageFile imageFile, bool isFile) async {
    try {
      if(isFile) {
        // final data = await _localDataSource.readFileFILE(path);
        await imageFile.importAsBinary(path);
      } else {
        // final data = await _localDataSource.readFileTXT(path);
        await imageFile.importAsText(path);
      }
      return right(imageFile);
    } catch (e) {
      return left(Failure(message: 'Error importing file: $e'));
    }
  }

  @override
  Future<Either<Failure, Uint8List>> loadFile(String path, String extension) async {
    try {
      final file = await _localDataSource.loadFile(path, extension);
      final result = await file.readAsBytes();
      return right(result);
    } catch (e) {
      return left(Failure(message: 'Error saving file: $e'));
    }
  }
  
}