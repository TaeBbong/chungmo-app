// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) =>
    _ScheduleModel(
      link: json['link'] as String,
      thumbnail: json['thumbnail'] as String,
      groom: json['groom'] as String,
      bride: json['bride'] as String,
      date: json['datetime'] as String,
      location: json['location'] as String,
      groomAccounts: json['groom_accounts'] as String? ?? '[]',
      brideAccounts: json['bride_accounts'] as String? ?? '[]',
      attendance: json['attendance'] as String? ?? 'undecided',
      pay: (json['pay'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ScheduleModelToJson(_ScheduleModel instance) =>
    <String, dynamic>{
      'link': instance.link,
      'thumbnail': instance.thumbnail,
      'groom': instance.groom,
      'bride': instance.bride,
      'datetime': instance.date,
      'location': instance.location,
      'groom_accounts': instance.groomAccounts,
      'bride_accounts': instance.brideAccounts,
      'attendance': instance.attendance,
      'pay': instance.pay,
    };
