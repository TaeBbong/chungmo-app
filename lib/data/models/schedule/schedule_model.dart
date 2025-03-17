/// Step 4:
/// Model
///
/// Based on entity from domain layer,
/// Implement data model that can be used in data sources & repositories

import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_model.freezed.dart';
part 'schedule_model.g.dart';

/// ScheduleModel in data layer.
///
/// Used in local/remote data sources.
@freezed
class ScheduleModel with _$ScheduleModel {
  factory ScheduleModel({
    required String link,
    required String thumbnail,
    required String groom,
    required String bride,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'datetime') required String date,
    required String location,
  }) = _ScheduleModel;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);
}
