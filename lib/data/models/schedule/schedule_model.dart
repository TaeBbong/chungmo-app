/// Step 4:
/// Model
/// 
/// Based on entity from domain layer,
/// Implement data model that can be used in data sources & repositories


import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_model.freezed.dart';
part 'schedule_model.g.dart';


@freezed
class ScheduleModel with _$ScheduleModel {
  factory ScheduleModel({
    required String id,
    required String link,
    required String thumbnail,
    required String groom,
    required String bride,
    required DateTime date,
    required String location,
  }) = _ScheduleModel;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) => _$ScheduleModelFromJson(json);
}