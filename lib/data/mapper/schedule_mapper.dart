import '../models/schedule/schedule_model.dart';
import '../../domain/entities/schedule.dart';

class ScheduleMapper {
  static ScheduleModel toModel(Schedule entity) {
    return ScheduleModel(
      link: entity.link,
      thumbnail: entity.thumbnail,
      groom: entity.groom,
      bride: entity.bride,
      date: entity.date,
      location: entity.location,
    );
  }

  static Schedule toEntity(ScheduleModel model) {
    return Schedule(
      link: model.link,
      thumbnail: model.thumbnail,
      groom: model.groom,
      bride: model.bride,
      date: model.date,
      location: model.location,
    );
  }
}
