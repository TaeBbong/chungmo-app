// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:chungmo/core/services/notification_service.dart' as _i109;
import 'package:chungmo/core/services/preferences_checker.dart' as _i391;
import 'package:chungmo/data/repositories/schedule_repository.dart' as _i798;
import 'package:chungmo/data/sources/local/app_preferences_local_source.dart'
    as _i98;
import 'package:chungmo/data/sources/local/schedule_local_source.dart'
    as _i1014;
import 'package:chungmo/data/sources/remote/schedule_remote_source.dart'
    as _i153;
import 'package:chungmo/domain/repositories/schedule_repository.dart' as _i561;
import 'package:chungmo/domain/usecases/analyze_link_usecase.dart' as _i596;
import 'package:chungmo/domain/usecases/count_schedules_usecase.dart' as _i877;
import 'package:chungmo/domain/usecases/delete_schedule_usecase.dart' as _i993;
import 'package:chungmo/domain/usecases/edit_schedule_usecase.dart' as _i15;
import 'package:chungmo/domain/usecases/get_schedule_by_link_usecase.dart'
    as _i634;
import 'package:chungmo/domain/usecases/list_schedules_by_date_usecase.dart'
    as _i437;
import 'package:chungmo/domain/usecases/list_schedules_usecase.dart' as _i56;
import 'package:chungmo/domain/usecases/save_schedule_usecase.dart' as _i485;
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
    gh.lazySingleton<_i109.NotificationService>(
        () => _i109.NotificationServiceImpl());
    gh.lazySingleton<_i1014.ScheduleLocalSource>(
        () => _i1014.ScheduleLocalSourceImpl());
    gh.lazySingleton<_i98.AppPreferencesLocalSource>(
        () => _i98.AppPreferencesSourceImpl());
    gh.lazySingleton<_i153.ScheduleRemoteSource>(
        () => _i153.ScheduleRemoteSourceImpl());
    gh.factory<_i391.PreferencesChecker>(
        () => _i391.PreferencesChecker(gh<_i98.AppPreferencesLocalSource>()));
    gh.lazySingleton<_i561.ScheduleRepository>(
        () => _i798.ScheduleRepositoryImpl(
              gh<_i153.ScheduleRemoteSource>(),
              gh<_i1014.ScheduleLocalSource>(),
              gh<_i109.NotificationService>(),
            ));
    gh.factory<_i56.ListSchedulesUsecase>(
        () => _i56.ListSchedulesUsecase(gh<_i561.ScheduleRepository>()));
    gh.factory<_i634.GetScheduleByLinkUsecase>(
        () => _i634.GetScheduleByLinkUsecase(gh<_i561.ScheduleRepository>()));
    gh.factory<_i485.SaveScheduleUsecase>(
        () => _i485.SaveScheduleUsecase(gh<_i561.ScheduleRepository>()));
    gh.factory<_i596.AnalyzeLinkUsecase>(
        () => _i596.AnalyzeLinkUsecase(gh<_i561.ScheduleRepository>()));
    gh.factory<_i993.DeleteScheduleUsecase>(
        () => _i993.DeleteScheduleUsecase(gh<_i561.ScheduleRepository>()));
    gh.factory<_i437.ListSchedulesByDateUsecase>(
        () => _i437.ListSchedulesByDateUsecase(gh<_i561.ScheduleRepository>()));
    gh.factory<_i15.EditScheduleUsecase>(
        () => _i15.EditScheduleUsecase(gh<_i561.ScheduleRepository>()));
    gh.factory<_i877.CountSchedulesUsecase>(
        () => _i877.CountSchedulesUsecase(gh<_i561.ScheduleRepository>()));
    return this;
  }
}
