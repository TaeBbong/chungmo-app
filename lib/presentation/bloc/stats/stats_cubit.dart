import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/di.dart';
import '../../../domain/entities/pay_statistics.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/usecases/usecases.dart';

part 'stats_state.dart';

/// Backs the gift-money statistics dashboard: watches the schedule stream
/// and aggregates it into [PayStatistics], so the page stays live as
/// records change.
class StatsCubit extends Cubit<StatsState> {
  final WatchAllSchedulesUsecase watchAllSchedulesUsecase;

  StreamSubscription<List<Schedule>>? _subscription;

  StatsCubit({WatchAllSchedulesUsecase? watchAllSchedulesUsecase})
      : watchAllSchedulesUsecase =
            watchAllSchedulesUsecase ?? getIt<WatchAllSchedulesUsecase>(),
        super(const StatsState());

  void watchStatistics() {
    _subscription = watchAllSchedulesUsecase.execute().listen((schedules) {
      emit(StatsState(
        loaded: true,
        statistics: PayStatistics.fromSchedules(schedules),
      ));
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
