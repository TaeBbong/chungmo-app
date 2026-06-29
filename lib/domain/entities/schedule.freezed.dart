// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Schedule {
  String get link;
  String get thumbnail;
  String get groom;
  String get bride;
  DateTime get date;
  String get location;

  /// Create a copy of Schedule
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ScheduleCopyWith<Schedule> get copyWith =>
      _$ScheduleCopyWithImpl<Schedule>(this as Schedule, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Schedule &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            (identical(other.groom, groom) || other.groom == groom) &&
            (identical(other.bride, bride) || other.bride == bride) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, link, thumbnail, groom, bride, date, location);

  @override
  String toString() {
    return 'Schedule(link: $link, thumbnail: $thumbnail, groom: $groom, bride: $bride, date: $date, location: $location)';
  }
}

/// @nodoc
abstract mixin class $ScheduleCopyWith<$Res> {
  factory $ScheduleCopyWith(Schedule value, $Res Function(Schedule) _then) =
      _$ScheduleCopyWithImpl;
  @useResult
  $Res call(
      {String link,
      String thumbnail,
      String groom,
      String bride,
      DateTime date,
      String location});
}

/// @nodoc
class _$ScheduleCopyWithImpl<$Res> implements $ScheduleCopyWith<$Res> {
  _$ScheduleCopyWithImpl(this._self, this._then);

  final Schedule _self;
  final $Res Function(Schedule) _then;

  /// Create a copy of Schedule
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
              as DateTime,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [Schedule].
extension SchedulePatterns on Schedule {
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
    TResult Function(_Schedule value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Schedule() when $default != null:
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
    TResult Function(_Schedule value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Schedule():
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
    TResult? Function(_Schedule value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Schedule() when $default != null:
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
    TResult Function(String link, String thumbnail, String groom, String bride,
            DateTime date, String location)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Schedule() when $default != null:
        return $default(_that.link, _that.thumbnail, _that.groom, _that.bride,
            _that.date, _that.location);
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
    TResult Function(String link, String thumbnail, String groom, String bride,
            DateTime date, String location)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Schedule():
        return $default(_that.link, _that.thumbnail, _that.groom, _that.bride,
            _that.date, _that.location);
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
    TResult? Function(String link, String thumbnail, String groom, String bride,
            DateTime date, String location)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Schedule() when $default != null:
        return $default(_that.link, _that.thumbnail, _that.groom, _that.bride,
            _that.date, _that.location);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Schedule implements Schedule {
  const _Schedule(
      {required this.link,
      required this.thumbnail,
      required this.groom,
      required this.bride,
      required this.date,
      required this.location});

  @override
  final String link;
  @override
  final String thumbnail;
  @override
  final String groom;
  @override
  final String bride;
  @override
  final DateTime date;
  @override
  final String location;

  /// Create a copy of Schedule
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ScheduleCopyWith<_Schedule> get copyWith =>
      __$ScheduleCopyWithImpl<_Schedule>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Schedule &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.thumbnail, thumbnail) ||
                other.thumbnail == thumbnail) &&
            (identical(other.groom, groom) || other.groom == groom) &&
            (identical(other.bride, bride) || other.bride == bride) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.location, location) ||
                other.location == location));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, link, thumbnail, groom, bride, date, location);

  @override
  String toString() {
    return 'Schedule(link: $link, thumbnail: $thumbnail, groom: $groom, bride: $bride, date: $date, location: $location)';
  }
}

/// @nodoc
abstract mixin class _$ScheduleCopyWith<$Res>
    implements $ScheduleCopyWith<$Res> {
  factory _$ScheduleCopyWith(_Schedule value, $Res Function(_Schedule) _then) =
      __$ScheduleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String link,
      String thumbnail,
      String groom,
      String bride,
      DateTime date,
      String location});
}

/// @nodoc
class __$ScheduleCopyWithImpl<$Res> implements _$ScheduleCopyWith<$Res> {
  __$ScheduleCopyWithImpl(this._self, this._then);

  final _Schedule _self;
  final $Res Function(_Schedule) _then;

  /// Create a copy of Schedule
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
  }) {
    return _then(_Schedule(
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
              as DateTime,
      location: null == location
          ? _self.location
          : location // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
