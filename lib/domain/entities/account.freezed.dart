// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Account {
  /// Bank name, e.g. `국민`.
  String get bank;

  /// Account number, e.g. `123-45-6789`.
  String get number;

  /// Account holder name, e.g. `김철수`.
  String get holder;

  /// Relation to the couple, e.g. `신랑`, `아버지`, `어머니`.
  String get relation;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AccountCopyWith<Account> get copyWith =>
      _$AccountCopyWithImpl<Account>(this as Account, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Account &&
            (identical(other.bank, bank) || other.bank == bank) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.holder, holder) || other.holder == holder) &&
            (identical(other.relation, relation) ||
                other.relation == relation));
  }

  @override
  int get hashCode => Object.hash(runtimeType, bank, number, holder, relation);

  @override
  String toString() {
    return 'Account(bank: $bank, number: $number, holder: $holder, relation: $relation)';
  }
}

/// @nodoc
abstract mixin class $AccountCopyWith<$Res> {
  factory $AccountCopyWith(Account value, $Res Function(Account) _then) =
      _$AccountCopyWithImpl;
  @useResult
  $Res call({String bank, String number, String holder, String relation});
}

/// @nodoc
class _$AccountCopyWithImpl<$Res> implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._self, this._then);

  final Account _self;
  final $Res Function(Account) _then;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bank = null,
    Object? number = null,
    Object? holder = null,
    Object? relation = null,
  }) {
    return _then(_self.copyWith(
      bank: null == bank
          ? _self.bank
          : bank // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      holder: null == holder
          ? _self.holder
          : holder // ignore: cast_nullable_to_non_nullable
              as String,
      relation: null == relation
          ? _self.relation
          : relation // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [Account].
extension AccountPatterns on Account {
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
    TResult Function(_Account value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Account() when $default != null:
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
    TResult Function(_Account value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Account():
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
    TResult? Function(_Account value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Account() when $default != null:
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
            String bank, String number, String holder, String relation)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Account() when $default != null:
        return $default(_that.bank, _that.number, _that.holder, _that.relation);
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
    TResult Function(String bank, String number, String holder, String relation)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Account():
        return $default(_that.bank, _that.number, _that.holder, _that.relation);
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
            String bank, String number, String holder, String relation)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Account() when $default != null:
        return $default(_that.bank, _that.number, _that.holder, _that.relation);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Account implements Account {
  const _Account(
      {this.bank = '', this.number = '', this.holder = '', this.relation = ''});

  /// Bank name, e.g. `국민`.
  @override
  @JsonKey()
  final String bank;

  /// Account number, e.g. `123-45-6789`.
  @override
  @JsonKey()
  final String number;

  /// Account holder name, e.g. `김철수`.
  @override
  @JsonKey()
  final String holder;

  /// Relation to the couple, e.g. `신랑`, `아버지`, `어머니`.
  @override
  @JsonKey()
  final String relation;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AccountCopyWith<_Account> get copyWith =>
      __$AccountCopyWithImpl<_Account>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Account &&
            (identical(other.bank, bank) || other.bank == bank) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.holder, holder) || other.holder == holder) &&
            (identical(other.relation, relation) ||
                other.relation == relation));
  }

  @override
  int get hashCode => Object.hash(runtimeType, bank, number, holder, relation);

  @override
  String toString() {
    return 'Account(bank: $bank, number: $number, holder: $holder, relation: $relation)';
  }
}

/// @nodoc
abstract mixin class _$AccountCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$AccountCopyWith(_Account value, $Res Function(_Account) _then) =
      __$AccountCopyWithImpl;
  @override
  @useResult
  $Res call({String bank, String number, String holder, String relation});
}

/// @nodoc
class __$AccountCopyWithImpl<$Res> implements _$AccountCopyWith<$Res> {
  __$AccountCopyWithImpl(this._self, this._then);

  final _Account _self;
  final $Res Function(_Account) _then;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bank = null,
    Object? number = null,
    Object? holder = null,
    Object? relation = null,
  }) {
    return _then(_Account(
      bank: null == bank
          ? _self.bank
          : bank // ignore: cast_nullable_to_non_nullable
              as String,
      number: null == number
          ? _self.number
          : number // ignore: cast_nullable_to_non_nullable
              as String,
      holder: null == holder
          ? _self.holder
          : holder // ignore: cast_nullable_to_non_nullable
              as String,
      relation: null == relation
          ? _self.relation
          : relation // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
