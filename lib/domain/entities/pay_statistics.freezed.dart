// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pay_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayStatistics {
  /// Sum of every recorded amount, in KRW.
  int get totalAmount;

  /// Number of schedules with a recorded amount.
  int get recordCount;

  /// Sum per wedding year, keyed by year.
  Map<int, int> get yearlyTotals;

  /// Sum per relation; unrecorded relations land under [Relation.unset].
  Map<Relation, int> get relationTotals;

  /// Create a copy of PayStatistics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PayStatisticsCopyWith<PayStatistics> get copyWith =>
      _$PayStatisticsCopyWithImpl<PayStatistics>(
          this as PayStatistics, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PayStatistics &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.recordCount, recordCount) ||
                other.recordCount == recordCount) &&
            const DeepCollectionEquality()
                .equals(other.yearlyTotals, yearlyTotals) &&
            const DeepCollectionEquality()
                .equals(other.relationTotals, relationTotals));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalAmount,
      recordCount,
      const DeepCollectionEquality().hash(yearlyTotals),
      const DeepCollectionEquality().hash(relationTotals));

  @override
  String toString() {
    return 'PayStatistics(totalAmount: $totalAmount, recordCount: $recordCount, yearlyTotals: $yearlyTotals, relationTotals: $relationTotals)';
  }
}

/// @nodoc
abstract mixin class $PayStatisticsCopyWith<$Res> {
  factory $PayStatisticsCopyWith(
          PayStatistics value, $Res Function(PayStatistics) _then) =
      _$PayStatisticsCopyWithImpl;
  @useResult
  $Res call(
      {int totalAmount,
      int recordCount,
      Map<int, int> yearlyTotals,
      Map<Relation, int> relationTotals});
}

/// @nodoc
class _$PayStatisticsCopyWithImpl<$Res>
    implements $PayStatisticsCopyWith<$Res> {
  _$PayStatisticsCopyWithImpl(this._self, this._then);

  final PayStatistics _self;
  final $Res Function(PayStatistics) _then;

  /// Create a copy of PayStatistics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAmount = null,
    Object? recordCount = null,
    Object? yearlyTotals = null,
    Object? relationTotals = null,
  }) {
    return _then(_self.copyWith(
      totalAmount: null == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as int,
      recordCount: null == recordCount
          ? _self.recordCount
          : recordCount // ignore: cast_nullable_to_non_nullable
              as int,
      yearlyTotals: null == yearlyTotals
          ? _self.yearlyTotals
          : yearlyTotals // ignore: cast_nullable_to_non_nullable
              as Map<int, int>,
      relationTotals: null == relationTotals
          ? _self.relationTotals
          : relationTotals // ignore: cast_nullable_to_non_nullable
              as Map<Relation, int>,
    ));
  }
}

/// Adds pattern-matching-related methods to [PayStatistics].
extension PayStatisticsPatterns on PayStatistics {
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
    TResult Function(_PayStatistics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PayStatistics() when $default != null:
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
    TResult Function(_PayStatistics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PayStatistics():
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
    TResult? Function(_PayStatistics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PayStatistics() when $default != null:
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
    TResult Function(int totalAmount, int recordCount,
            Map<int, int> yearlyTotals, Map<Relation, int> relationTotals)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PayStatistics() when $default != null:
        return $default(_that.totalAmount, _that.recordCount,
            _that.yearlyTotals, _that.relationTotals);
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
    TResult Function(int totalAmount, int recordCount,
            Map<int, int> yearlyTotals, Map<Relation, int> relationTotals)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PayStatistics():
        return $default(_that.totalAmount, _that.recordCount,
            _that.yearlyTotals, _that.relationTotals);
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
    TResult? Function(int totalAmount, int recordCount,
            Map<int, int> yearlyTotals, Map<Relation, int> relationTotals)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PayStatistics() when $default != null:
        return $default(_that.totalAmount, _that.recordCount,
            _that.yearlyTotals, _that.relationTotals);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PayStatistics extends PayStatistics {
  const _PayStatistics(
      {required this.totalAmount,
      required this.recordCount,
      required final Map<int, int> yearlyTotals,
      required final Map<Relation, int> relationTotals})
      : _yearlyTotals = yearlyTotals,
        _relationTotals = relationTotals,
        super._();

  /// Sum of every recorded amount, in KRW.
  @override
  final int totalAmount;

  /// Number of schedules with a recorded amount.
  @override
  final int recordCount;

  /// Sum per wedding year, keyed by year.
  final Map<int, int> _yearlyTotals;

  /// Sum per wedding year, keyed by year.
  @override
  Map<int, int> get yearlyTotals {
    if (_yearlyTotals is EqualUnmodifiableMapView) return _yearlyTotals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_yearlyTotals);
  }

  /// Sum per relation; unrecorded relations land under [Relation.unset].
  final Map<Relation, int> _relationTotals;

  /// Sum per relation; unrecorded relations land under [Relation.unset].
  @override
  Map<Relation, int> get relationTotals {
    if (_relationTotals is EqualUnmodifiableMapView) return _relationTotals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_relationTotals);
  }

  /// Create a copy of PayStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PayStatisticsCopyWith<_PayStatistics> get copyWith =>
      __$PayStatisticsCopyWithImpl<_PayStatistics>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PayStatistics &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.recordCount, recordCount) ||
                other.recordCount == recordCount) &&
            const DeepCollectionEquality()
                .equals(other._yearlyTotals, _yearlyTotals) &&
            const DeepCollectionEquality()
                .equals(other._relationTotals, _relationTotals));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalAmount,
      recordCount,
      const DeepCollectionEquality().hash(_yearlyTotals),
      const DeepCollectionEquality().hash(_relationTotals));

  @override
  String toString() {
    return 'PayStatistics(totalAmount: $totalAmount, recordCount: $recordCount, yearlyTotals: $yearlyTotals, relationTotals: $relationTotals)';
  }
}

/// @nodoc
abstract mixin class _$PayStatisticsCopyWith<$Res>
    implements $PayStatisticsCopyWith<$Res> {
  factory _$PayStatisticsCopyWith(
          _PayStatistics value, $Res Function(_PayStatistics) _then) =
      __$PayStatisticsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int totalAmount,
      int recordCount,
      Map<int, int> yearlyTotals,
      Map<Relation, int> relationTotals});
}

/// @nodoc
class __$PayStatisticsCopyWithImpl<$Res>
    implements _$PayStatisticsCopyWith<$Res> {
  __$PayStatisticsCopyWithImpl(this._self, this._then);

  final _PayStatistics _self;
  final $Res Function(_PayStatistics) _then;

  /// Create a copy of PayStatistics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? totalAmount = null,
    Object? recordCount = null,
    Object? yearlyTotals = null,
    Object? relationTotals = null,
  }) {
    return _then(_PayStatistics(
      totalAmount: null == totalAmount
          ? _self.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as int,
      recordCount: null == recordCount
          ? _self.recordCount
          : recordCount // ignore: cast_nullable_to_non_nullable
              as int,
      yearlyTotals: null == yearlyTotals
          ? _self._yearlyTotals
          : yearlyTotals // ignore: cast_nullable_to_non_nullable
              as Map<int, int>,
      relationTotals: null == relationTotals
          ? _self._relationTotals
          : relationTotals // ignore: cast_nullable_to_non_nullable
              as Map<Relation, int>,
    ));
  }
}

// dart format on
