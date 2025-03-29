/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';

/// Schedule entity in domain layer.
///
/// Used in main business logic, usecases, presentation layer.
@freezed
class Schedule with _$Schedule {
  const factory Schedule({
    required String link,
    required String thumbnail,
    required String groom,
    required String bride,
    required DateTime date,
    required String location,
  }) = _Schedule;
}
