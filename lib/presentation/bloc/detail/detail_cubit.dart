import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/di/di.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/usecases/usecases.dart';

part 'detail_state.dart';

class DetailCubit extends Cubit<DetailState> {
  final EditScheduleUsecase editScheduleUsecase = getIt<EditScheduleUsecase>();
  final DeleteScheduleUsecase deleteScheduleUsecase =
      getIt<DeleteScheduleUsecase>();
  final AnalyticsService _analytics = getIt<AnalyticsService>();

  DetailCubit() : super(const DetailState());

  void setSchedule(Schedule schedule) {
    emit(state.copyWith(schedule: schedule));
  }

  Future<void> editSchedule(Schedule editedSchedule) async {
    emit(state.copyWith(schedule: editedSchedule));
    await editScheduleUsecase.execute(editedSchedule);
  }

  Future<void> deleteSchedule(String link) async {
    _analytics.logEvent(AnalyticsEvents.scheduleDeleted);
    await deleteScheduleUsecase.execute(link);
  }
}
