// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountModel _$AccountModelFromJson(Map<String, dynamic> json) =>
    _AccountModel(
      bank: json['bank'] as String? ?? '',
      number: json['number'] as String? ?? '',
      holder: json['holder'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );

Map<String, dynamic> _$AccountModelToJson(_AccountModel instance) =>
    <String, dynamic>{
      'bank': instance.bank,
      'number': instance.number,
      'holder': instance.holder,
      'relation': instance.relation,
    };
