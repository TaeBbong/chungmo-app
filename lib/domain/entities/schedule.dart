/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

import 'package:freezed_annotation/freezed_annotation.dart';

import 'account.dart';
import 'attendance.dart';
import 'relation.dart';

part 'schedule.freezed.dart';

/// Schedule entity in domain layer.
///
/// Used in main business logic, usecases, presentation layer.
@freezed
abstract class Schedule with _$Schedule {
  const factory Schedule({
    required String link,
    required String thumbnail,
    required String groom,
    required String bride,
    required DateTime date,
    required String location,

    /// 축의금 accounts of the groom's side. Empty when not found in invitation.
    @Default(<Account>[]) List<Account> groomAccounts,

    /// 축의금 accounts of the bride's side. Empty when not found in invitation.
    @Default(<Account>[]) List<Account> brideAccounts,

    /// Whether the user plans to attend. Defaults to [Attendance.undecided].
    @Default(Attendance.undecided) Attendance attendance,

    /// 축의금 the user gave, in KRW. 0 means not recorded.
    @Default(0) int pay,

    /// Relationship to the couple. Defaults to [Relation.unset].
    @Default(Relation.unset) Relation relation,

    /// Free-form nuance of the relationship the enum can't carry
    /// (e.g. "한참 연락 안하던 중학교 동창"). Empty when not written.
    @Default('') String relationNote,
  }) = _Schedule;
}
