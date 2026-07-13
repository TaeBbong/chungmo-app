// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleModel {
  String get link;
  String get thumbnail;
  String get groom;
  String get bride; // ignore: invalid_annotation_target
  @JsonKey(name: 'datetime')
  String get date;
  String get location;

  /// JSON-encoded `List<AccountModel>`; sqflite has no list column type.
// ignore: invalid_annotation_target
  @JsonKey(name: 'groom_accounts')
  String get groomAccounts; // ignore: invalid_annotation_target
  @JsonKey(name: 'bride_accounts')
  String get brideAccounts;

  /// `Attendance.name`; unknown/NULL values fall back to `undecided`.
  String get attendance;

  /// 축의금 in KRW; 0 means not recorded.
  int get pay;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScheduleModelCopyWith<ScheduleModel> get copyWith =>
      _$ScheduleModelCopyWithImpl<ScheduleModel>(
          this as ScheduleModel, _$identity);

  /// Serializes this ScheduleModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ScheduleModel &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            (identical(other.groom, groom) || other.groom == groom) &&
            (identical(other.bride, bride) || other.bride == bride) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.groomAccounts, groomAccounts) ||
                other.groomAccounts == groomAccounts) &&
            (identical(other.brideAccounts, brideAccounts) ||
                other.brideAccounts == brideAccounts) &&
            (identical(other.attendance, attendance) ||
                other.attendance == attendance) &&
            (identical(other.pay, pay) || other.pay == pay));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, link, thumbnail, groom, bride,
      date, location, groomAccounts, brideAccounts, attendance, pay);

  @override
  String toString() {
    return 'ScheduleModel(link: $link, thumbnail: $thumbnail, groom: $groom, bride: $bride, date: $date, location: $location, groomAccounts: $groomAccounts, brideAccounts: $brideAccounts, attendance: $attendance, pay: $pay)';
  }
}

/// @nodoc
abstract mixin class $ScheduleModelCopyWith<$Res> {
  factory $ScheduleModelCopyWith(
          ScheduleModel value, $Res Function(ScheduleModel) _then) =
      _$ScheduleModelCopyWithImpl;
  @useResult
  $Res call(
      {String link,
      String thumbnail,
      String groom,
      String bride,
      @JsonKey(name: 'datetime') String date,
      String location,
      @JsonKey(name: 'groom_accounts') String groomAccounts,
      @JsonKey(name: 'bride_accounts') String brideAccounts,
      String attendance,
      int pay});
}

/// @nodoc
class _$ScheduleModelCopyWithImpl<$Res>
    implements $ScheduleModelCopyWith<$Res> {
  _$ScheduleModelCopyWithImpl(this._self, this._then);

  final ScheduleModel _self;
  final $Res Function(ScheduleModel) _then;

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
    Object? groomAccounts = null,
    Object? brideAccounts = null,
    Object? attendance = null,
    Object? pay = null,
  }) {
    return _then(_self.copyWith(
      link: null == link
          ? _self.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: null == thumbnail
          ? _self.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String,
      groom: null == groom
          ? _self.groom
          : groom // ignore: cast_nullable_to_non_nullable
              as String,
      bride: null == bride
          ? _self.bride
          : bride // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      groomAccounts: null == groomAccounts
          ? _self.groomAccounts
          : groomAccounts // ignore: cast_nullable_to_non_nullable
              as String,
      brideAccounts: null == brideAccounts
          ? _self.brideAccounts
          : brideAccounts // ignore: cast_nullable_to_non_nullable
              as String,
      attendance: null == attendance
          ? _self.attendance
          : attendance // ignore: cast_nullable_to_non_nullable
              as String,
      pay: null == pay
          ? _self.pay
          : pay // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [ScheduleModel].
extension ScheduleModelPatterns on ScheduleModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ScheduleModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ScheduleModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ScheduleModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String link,
            String thumbnail,
            String groom,
            String bride,
            @JsonKey(name: 'datetime') String date,
            String location,
            @JsonKey(name: 'groom_accounts') String groomAccounts,
            @JsonKey(name: 'bride_accounts') String brideAccounts,
            String attendance,
            int pay)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ScheduleModel() when $default != null:
        return $default(
            _that.link,
            _that.thumbnail,
            _that.groom,
            _that.bride,
            _that.date,
            _that.location,
            _that.groomAccounts,
            _that.brideAccounts,
            _that.attendance,
            _that.pay);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String link,
            String thumbnail,
            String groom,
            String bride,
            @JsonKey(name: 'datetime') String date,
            String location,
            @JsonKey(name: 'groom_accounts') String groomAccounts,
            @JsonKey(name: 'bride_accounts') String brideAccounts,
            String attendance,
            int pay)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleModel():
        return $default(
            _that.link,
            _that.thumbnail,
            _that.groom,
            _that.bride,
            _that.date,
            _that.location,
            _that.groomAccounts,
            _that.brideAccounts,
            _that.attendance,
            _that.pay);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String link,
            String thumbnail,
            String groom,
            String bride,
            @JsonKey(name: 'datetime') String date,
            String location,
            @JsonKey(name: 'groom_accounts') String groomAccounts,
            @JsonKey(name: 'bride_accounts') String brideAccounts,
            String attendance,
            int pay)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ScheduleModel() when $default != null:
        return $default(
            _that.link,
            _that.thumbnail,
            _that.groom,
            _that.bride,
            _that.date,
            _that.location,
            _that.groomAccounts,
            _that.brideAccounts,
            _that.attendance,
            _that.pay);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ScheduleModel implements ScheduleModel {
  _ScheduleModel(
      {required this.link,
      required this.thumbnail,
      required this.groom,
      required this.bride,
      @JsonKey(name: 'datetime') required this.date,
      required this.location,
      @JsonKey(name: 'groom_accounts') this.groomAccounts = '[]',
      @JsonKey(name: 'bride_accounts') this.brideAccounts = '[]',
      this.attendance = 'undecided',
      this.pay = 0});
  factory _ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);

  @override
  final String link;
  @override
  final String thumbnail;
  @override
  final String groom;
  @override
  final String bride;
// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'datetime')
  final String date;
  @override
  final String location;

  /// JSON-encoded `List<AccountModel>`; sqflite has no list column type.
// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'groom_accounts')
  final String groomAccounts;
// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'bride_accounts')
  final String brideAccounts;

  /// `Attendance.name`; unknown/NULL values fall back to `undecided`.
  @override
  @JsonKey()
  final String attendance;

  /// 축의금 in KRW; 0 means not recorded.
  @override
  @JsonKey()
  final int pay;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScheduleModelCopyWith<_ScheduleModel> get copyWith =>
      __$ScheduleModelCopyWithImpl<_ScheduleModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ScheduleModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ScheduleModel &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            (identical(other.groom, groom) || other.groom == groom) &&
            (identical(other.bride, bride) || other.bride == bride) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.groomAccounts, groomAccounts) ||
                other.groomAccounts == groomAccounts) &&
            (identical(other.brideAccounts, brideAccounts) ||
                other.brideAccounts == brideAccounts) &&
            (identical(other.attendance, attendance) ||
                other.attendance == attendance) &&
            (identical(other.pay, pay) || other.pay == pay));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, link, thumbnail, groom, bride,
      date, location, groomAccounts, brideAccounts, attendance, pay);

  @override
  String toString() {
    return 'ScheduleModel(link: $link, thumbnail: $thumbnail, groom: $groom, bride: $bride, date: $date, location: $location, groomAccounts: $groomAccounts, brideAccounts: $brideAccounts, attendance: $attendance, pay: $pay)';
  }
}

/// @nodoc
abstract mixin class _$ScheduleModelCopyWith<$Res>
    implements $ScheduleModelCopyWith<$Res> {
  factory _$ScheduleModelCopyWith(
          _ScheduleModel value, $Res Function(_ScheduleModel) _then) =
      __$ScheduleModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String link,
      String thumbnail,
      String groom,
      String bride,
      @JsonKey(name: 'datetime') String date,
      String location,
      @JsonKey(name: 'groom_accounts') String groomAccounts,
      @JsonKey(name: 'bride_accounts') String brideAccounts,
      String attendance,
      int pay});
}

/// @nodoc
class __$ScheduleModelCopyWithImpl<$Res>
    implements _$ScheduleModelCopyWith<$Res> {
  __$ScheduleModelCopyWithImpl(this._self, this._then);

  final _ScheduleModel _self;
  final $Res Function(_ScheduleModel) _then;

  /// Create a copy of ScheduleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? link = null,
    Object? thumbnail = null,
    Object? groom = null,
    Object? bride = null,
    Object? date = null,
    Object? location = null,
    Object? groomAccounts = null,
    Object? brideAccounts = null,
    Object? attendance = null,
    Object? pay = null,
  }) {
    return _then(_ScheduleModel(
      link: null == link
          ? _self.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnail: null == thumbnail
          ? _self.thumbnail
          : thumbnail // ignore: cast_nullable_to_non_nullable
              as String,
      groom: null == groom
          ? _self.groom
          : groom // ignore: cast_nullable_to_non_nullable
              as String,
      bride: null == bride
          ? _self.bride
          : bride // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
      groomAccounts: null == groomAccounts
          ? _self.groomAccounts
          : groomAccounts // ignore: cast_nullable_to_non_nullable
              as String,
      brideAccounts: null == brideAccounts
          ? _self.brideAccounts
          : brideAccounts // ignore: cast_nullable_to_non_nullable
              as String,
      attendance: null == attendance
          ? _self.attendance
          : attendance // ignore: cast_nullable_to_non_nullable
              as String,
      pay: null == pay
          ? _self.pay
          : pay // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
