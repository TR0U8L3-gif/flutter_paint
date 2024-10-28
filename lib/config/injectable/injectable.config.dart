// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../core/common/presentation/logic/theme_provider.dart' as _i280;
import '../../src/data/data_source/paint_local_data_source.dart' as _i1052;
import '../../src/data/repositories/paint_repository_impl.dart' as _i681;
import '../../src/domain/repositories/paint_repository.dart' as _i652;
import '../../src/domain/usecases/save_file_use_case.dart' as _i273;
import '../../src/presentation/logic/paint_cubit.dart' as _i788;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.singleton<_i280.ThemeProvider>(() => _i280.ThemeProvider());
    gh.singleton<_i1052.PaintLocalDataSource>(
        () => _i1052.PaintLocalDataSourceImpl());
    gh.singleton<_i652.PaintRepository>(() => _i681.PaintRepositoryImpl(
        localDataSource: gh<_i1052.PaintLocalDataSource>()));
    gh.singleton<_i273.SaveFileUseCase>(
        () => _i273.SaveFileUseCase(repository: gh<_i652.PaintRepository>()));
    gh.factory<_i788.PaintCubit>(
        () => _i788.PaintCubit(saveFileUseCase: gh<_i273.SaveFileUseCase>()));
    return this;
  }
}