// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleModelImpl _$$ScheduleModelImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleModelImpl(
      link: json['link'] as String,
      thumbnail: json['thumbnail'] as String,
      groom: json['groom'] as String,
      bride: json['bride'] as String,
      date: json['datetime'] as String,
      location: json['location'] as String,
    );

Map<String, dynamic> _$$ScheduleModelImplToJson(_$ScheduleModelImpl instance) =>
    <String, dynamic>{
      'link': instance.link,
      'thumbnail': instance.thumbnail,
      'groom': instance.groom,
      'bride': instance.bride,
      'datetime': instance.date,
      'location': instance.location,
    };
