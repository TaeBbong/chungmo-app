// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) {
  return _ScheduleModel.fromJson(json);
}

/// @nodoc
mixin _$ScheduleModel {
  String get link => throw _privateConstructorUsedError;
  String get thumbnail => throw _privateConstructorUsedError;
  String get groom => throw _privateConstructorUsedError;
  String get bride => throw _privateConstructorUsedError;
  @JsonKey(name: 'datetime')
  String get date => throw _privateConstructorUsedError;
  String get location => throw _privateConstructorUsedError;

  /// Serializes this ScheduleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ScheduleModelCopyWith<ScheduleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleModelCopyWith<$Res> {
  factory $ScheduleModelCopyWith(
          ScheduleModel value, $Res Function(ScheduleModel) then) =
      _$ScheduleModelCopyWithImpl<$Res, ScheduleModel>;
  @useResult
  $Res call(
      {String link,
      String thumbnail,
      String groom,
      String bride,
      @JsonKey(name: 'datetime') String date,
      String location});
}

/// @nodoc
class _$ScheduleModelCopyWithImpl<$Res, $Val extends ScheduleModel>
    implements $ScheduleModelCopyWith<$Res> {
  _$ScheduleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? link = null,
    Object? thumbnail = null,
    Object? groom = null,
    Object? bride = null,
    Object? date = null,
    Object? location = null,
  }) {
    return _then(_value.copyWith(
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: null == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String,
      groom: null == groom
          ? _value.groom
          : groom // ignore: cast_nullable_to_non_nullable
              as String,
      bride: null == bride
          ? _value.bride
          : bride // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduleModelImplCopyWith<$Res>
    implements $ScheduleModelCopyWith<$Res> {
  factory _$$ScheduleModelImplCopyWith(
          _$ScheduleModelImpl value, $Res Function(_$ScheduleModelImpl) then) =
      __$$ScheduleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String link,
      String thumbnail,
      String groom,
      String bride,
      @JsonKey(name: 'datetime') String date,
      String location});
}

/// @nodoc
class __$$ScheduleModelImplCopyWithImpl<$Res>
    extends _$ScheduleModelCopyWithImpl<$Res, _$ScheduleModelImpl>
    implements _$$ScheduleModelImplCopyWith<$Res> {
  __$$ScheduleModelImplCopyWithImpl(
      _$ScheduleModelImpl _value, $Res Function(_$ScheduleModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? link = null,
    Object? thumbnail = null,
    Object? groom = null,
    Object? bride = null,
    Object? date = null,
    Object? location = null,
  }) {
    return _then(_$ScheduleModelImpl(
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: null == thumbnail
          ? _value.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String,
      groom: null == groom
          ? _value.groom
          : groom // ignore: cast_nullable_to_non_nullable
              as String,
      bride: null == bride
          ? _value.bride
          : bride // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScheduleModelImpl implements _ScheduleModel {
  _$ScheduleModelImpl(
      {required this.link,
      required this.thumbnail,
      required this.groom,
      required this.bride,
      @JsonKey(name: 'datetime') required this.date,
      required this.location});

  factory _$ScheduleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduleModelImplFromJson(json);

  @override
  final String link;
  @override
  final String thumbnail;
  @override
  final String groom;
  @override
  final String bride;
  @override
  @JsonKey(name: 'datetime')
  final String date;
  @override
  final String location;

  @override
  String toString() {
    return 'ScheduleModel(link: $link, thumbnail: $thumbnail, groom: $groom, bride: $bride, date: $date, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleModelImpl &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            (identical(other.groom, groom) || other.groom == groom) &&
            (identical(other.bride, bride) || other.bride == bride) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, link, thumbnail, groom, bride, date, location);

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleModelImplCopyWith<_$ScheduleModelImpl> get copyWith =>
      __$$ScheduleModelImplCopyWithImpl<_$ScheduleModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduleModelImplToJson(
      this,
    );
  }
}

abstract class _ScheduleModel implements ScheduleModel {
  factory _ScheduleModel(
      {required final String link,
      required final String thumbnail,
      required final String groom,
      required final String bride,
      @JsonKey(name: 'datetime') required final String date,
      required final String location}) = _$ScheduleModelImpl;

  factory _ScheduleModel.fromJson(Map<String, dynamic> json) =
      _$ScheduleModelImpl.fromJson;

  @override
  String get link;
  @override
  String get thumbnail;
  @override
  String get groom;
  @override
  String get bride;
  @override
  @JsonKey(name: 'datetime')
  String get date;
  @override
  String get location;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ScheduleModelImplCopyWith<_$ScheduleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
