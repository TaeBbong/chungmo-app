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
abstract class ScheduleModel with _$ScheduleModel {
  factory ScheduleModel({
    required String link,
    required String thumbnail,
    required String groom,
    required String bride,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'datetime') required String date,
    required String location,

    /// JSON-encoded `List<AccountModel>`; sqflite has no list column type.
    // ignore: invalid_annotation_target
    @JsonKey(name: 'groom_accounts') @Default('[]') String groomAccounts,
    // ignore: invalid_annotation_target
    @JsonKey(name: 'bride_accounts') @Default('[]') String brideAccounts,
  }) = _ScheduleModel;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);
}
