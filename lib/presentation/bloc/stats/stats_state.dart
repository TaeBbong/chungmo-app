part of 'stats_cubit.dart';

class StatsState extends Equatable {
  /// False until the first schedule list arrives.
  final bool loaded;

  final PayStatistics statistics;

  const StatsState({
    this.loaded = false,
    this.statistics = PayStatistics.empty,
  });

  @override
  List<Object?> get props => [loaded, statistics];
}
