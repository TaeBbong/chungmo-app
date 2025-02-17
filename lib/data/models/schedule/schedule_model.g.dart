// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleModelImpl _$$ScheduleModelImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleModelImpl(
      id: json['id'] as String,
      link: json['link'] as String,
      thumbnail: json['thumbnail'] as String,
      groom: json['groom'] as String,
      bride: json['bride'] as String,
      date: DateTime.parse(json['date'] as String),
      location: json['location'] as String,
    );

Map<String, dynamic> _$$ScheduleModelImplToJson(_$ScheduleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'link': instance.link,
      'thumbnail': instance.thumbnail,
      'groom': instance.groom,
      'bride': instance.bride,
      'date': instance.date.toIso8601String(),
      'location': instance.location,
    };
