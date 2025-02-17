// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:chungmo/data/repositories/schedule_repository.dart' as _i798;
import 'package:chungmo/data/sources/local/schedule_local_source.dart'
    as _i1014;
import 'package:chungmo/data/sources/remote/schedule_remote_source.dart'
    as _i153;
import 'package:chungmo/domain/repositories/schedule_repository.dart' as _i561;
import 'package:chungmo/domain/usecases/schedule/analyze_link_usecase.dart'
    as _i26;
import 'package:chungmo/domain/usecases/schedule/save_schedule_usecase.dart'
    as _i346;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

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
    gh.lazySingleton<_i1014.ScheduleLocalSource>(
        () => _i1014.ScheduleLocalSourceImpl());
    gh.lazySingleton<_i153.ScheduleRemoteSource>(
        () => _i153.ScheduleRemoteSourceImpl());
    gh.lazySingleton<_i561.ScheduleRepository>(
        () => _i798.ScheduleRepositoryImpl(
              gh<_i153.ScheduleRemoteSource>(),
              gh<_i1014.ScheduleLocalSource>(),
            ));
    gh.factory<_i26.AnalyzeLinkUsecase>(
        () => _i26.AnalyzeLinkUsecase(gh<_i561.ScheduleRepository>()));
    gh.factory<_i346.SaveScheduleUsecase>(
        () => _i346.SaveScheduleUsecase(gh<_i561.ScheduleRepository>()));
    return this;
  }
}
