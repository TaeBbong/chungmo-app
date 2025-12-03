import '../models/schedule/schedule_model.dart';
import '../../domain/entities/schedule.dart';

/// ScheduleMapper class converts Schedule(entity, domain) <-> ScheduleModel(model, data)
class ScheduleMapper {
  /// Converts Schedule(entity, domain) -> ScheduleModel(model, data)
  static ScheduleModel toModel(Schedule entity) {
    return ScheduleModel(
      link: entity.link,
      thumbnail: entity.thumbnail,
      groom: entity.groom,
      bride: entity.bride,
      date: entity.date.toIso8601String(),
      location: entity.location,
    );
  }

  /// Converts ScheduleModel(model, data) -> Schedule(entity, domain)
  static Schedule toEntity(ScheduleModel model) {
    return Schedule(
      link: model.link,
      thumbnail: model.thumbnail,
      groom: model.groom,
      bride: model.bride,
      date: DateTime.parse(model.date).toLocal(),
      location: model.location,
    );
  }
}
