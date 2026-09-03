// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pay_recommendation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PayRecommendation {
  /// Recommended amount in KRW.
  int get amount;

  /// Reasonable lower bound in KRW.
  int get minAmount;

  /// Reasonable upper bound in KRW.
  int get maxAmount;

  /// One or two Korean sentences explaining the amount, citing the
  /// data it was grounded in.
  String get reason;

  /// Create a copy of PayRecommendation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PayRecommendationCopyWith<PayRecommendation> get copyWith =>
      _$PayRecommendationCopyWithImpl<PayRecommendation>(
          this as PayRecommendation, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PayRecommendation &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.minAmount, minAmount) ||
                other.minAmount == minAmount) &&
            (identical(other.maxAmount, maxAmount) ||
                other.maxAmount == maxAmount) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, amount, minAmount, maxAmount, reason);

  @override
  String toString() {
    return 'PayRecommendation(amount: $amount, minAmount: $minAmount, maxAmount: $maxAmount, reason: $reason)';
  }
}

/// @nodoc
abstract mixin class $PayRecommendationCopyWith<$Res> {
  factory $PayRecommendationCopyWith(
          PayRecommendation value, $Res Function(PayRecommendation) _then) =
      _$PayRecommendationCopyWithImpl;
  @useResult
  $Res call({int amount, int minAmount, int maxAmount, String reason});
}

/// @nodoc
class _$PayRecommendationCopyWithImpl<$Res>
    implements $PayRecommendationCopyWith<$Res> {
  _$PayRecommendationCopyWithImpl(this._self, this._then);

  final PayRecommendation _self;
  final $Res Function(PayRecommendation) _then;

  /// Create a copy of PayRecommendation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = null,
    Object? minAmount = null,
    Object? maxAmount = null,
    Object? reason = null,
  }) {
    return _then(_self.copyWith(
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      minAmount: null == minAmount
          ? _self.minAmount
          : minAmount // ignore: cast_nullable_to_non_nullable
              as int,
      maxAmount: null == maxAmount
          ? _self.maxAmount
          : maxAmount // ignore: cast_nullable_to_non_nullable
              as int,
      reason: null == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [PayRecommendation].
extension PayRecommendationPatterns on PayRecommendation {
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
    TResult Function(_PayRecommendation value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PayRecommendation() when $default != null:
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
    TResult Function(_PayRecommendation value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PayRecommendation():
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
    TResult? Function(_PayRecommendation value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PayRecommendation() when $default != null:
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
    TResult Function(int amount, int minAmount, int maxAmount, String reason)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PayRecommendation() when $default != null:
        return $default(
            _that.amount, _that.minAmount, _that.maxAmount, _that.reason);
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
    TResult Function(int amount, int minAmount, int maxAmount, String reason)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PayRecommendation():
        return $default(
            _that.amount, _that.minAmount, _that.maxAmount, _that.reason);
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
    TResult? Function(int amount, int minAmount, int maxAmount, String reason)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PayRecommendation() when $default != null:
        return $default(
            _that.amount, _that.minAmount, _that.maxAmount, _that.reason);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PayRecommendation implements PayRecommendation {
  const _PayRecommendation(
      {required this.amount,
      required this.minAmount,
      required this.maxAmount,
      required this.reason});

  /// Recommended amount in KRW.
  @override
  final int amount;

  /// Reasonable lower bound in KRW.
  @override
  final int minAmount;

  /// Reasonable upper bound in KRW.
  @override
  final int maxAmount;

  /// One or two Korean sentences explaining the amount, citing the
  /// data it was grounded in.
  @override
  final String reason;

  /// Create a copy of PayRecommendation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PayRecommendationCopyWith<_PayRecommendation> get copyWith =>
      __$PayRecommendationCopyWithImpl<_PayRecommendation>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PayRecommendation &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.minAmount, minAmount) ||
                other.minAmount == minAmount) &&
            (identical(other.maxAmount, maxAmount) ||
                other.maxAmount == maxAmount) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, amount, minAmount, maxAmount, reason);

  @override
  String toString() {
    return 'PayRecommendation(amount: $amount, minAmount: $minAmount, maxAmount: $maxAmount, reason: $reason)';
  }
}

/// @nodoc
abstract mixin class _$PayRecommendationCopyWith<$Res>
    implements $PayRecommendationCopyWith<$Res> {
  factory _$PayRecommendationCopyWith(
          _PayRecommendation value, $Res Function(_PayRecommendation) _then) =
      __$PayRecommendationCopyWithImpl;
  @override
  @useResult
  $Res call({int amount, int minAmount, int maxAmount, String reason});
}

/// @nodoc
class __$PayRecommendationCopyWithImpl<$Res>
    implements _$PayRecommendationCopyWith<$Res> {
  __$PayRecommendationCopyWithImpl(this._self, this._then);

  final _PayRecommendation _self;
  final $Res Function(_PayRecommendation) _then;

  /// Create a copy of PayRecommendation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? amount = null,
    Object? minAmount = null,
    Object? maxAmount = null,
    Object? reason = null,
  }) {
    return _then(_PayRecommendation(
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      minAmount: null == minAmount
          ? _self.minAmount
          : minAmount // ignore: cast_nullable_to_non_nullable
              as int,
      maxAmount: null == maxAmount
          ? _self.maxAmount
          : maxAmount // ignore: cast_nullable_to_non_nullable
              as int,
      reason: null == reason
          ? _self.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
