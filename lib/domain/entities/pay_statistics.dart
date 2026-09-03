/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

import 'package:freezed_annotation/freezed_annotation.dart';

import 'relation.dart';
import 'schedule.dart';

part 'pay_statistics.freezed.dart';

/// Aggregated view of the gift money the user has given (`pay > 0`
/// records only), the data behind the statistics dashboard.
@freezed
abstract class PayStatistics with _$PayStatistics {
  const PayStatistics._();

  const factory PayStatistics({
    /// Sum of every recorded amount, in KRW.
    required int totalAmount,

    /// Number of schedules with a recorded amount.
    required int recordCount,

    /// Sum per wedding year, keyed by year.
    required Map<int, int> yearlyTotals,

    /// Sum per relation; unrecorded relations land under [Relation.unset].
    required Map<Relation, int> relationTotals,
  }) = _PayStatistics;

  /// Aggregates the user's saved schedules; unpaid records are excluded.
  factory PayStatistics.fromSchedules(List<Schedule> schedules) {
    final List<Schedule> paid =
        schedules.where((schedule) => schedule.pay > 0).toList();
    int totalAmount = 0;
    final Map<int, int> yearlyTotals = {};
    final Map<Relation, int> relationTotals = {};
    for (final Schedule schedule in paid) {
      totalAmount += schedule.pay;
      yearlyTotals.update(schedule.date.year, (sum) => sum + schedule.pay,
          ifAbsent: () => schedule.pay);
      relationTotals.update(schedule.relation, (sum) => sum + schedule.pay,
          ifAbsent: () => schedule.pay);
    }
    return PayStatistics(
      totalAmount: totalAmount,
      recordCount: paid.length,
      yearlyTotals: yearlyTotals,
      relationTotals: relationTotals,
    );
  }

  static const PayStatistics empty = PayStatistics(
    totalAmount: 0,
    recordCount: 0,
    yearlyTotals: {},
    relationTotals: {},
  );

  int get averageAmount => recordCount == 0 ? 0 : totalAmount ~/ recordCount;

  bool get isEmpty => recordCount == 0;
}
