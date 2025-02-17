import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';

@freezed
class Schedule with _$Schedule{
  const factory Schedule({
    required String id, 
    required String link, 
    required String thumbnail,
    required String groom,
    required String bride,
    required DateTime date,
    required String location,
  }) = _Schedule;
}