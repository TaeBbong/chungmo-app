/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

/// Account entity in domain layer.
///
/// Represents a single 축의금 account parsed from an invitation.
@freezed
abstract class Account with _$Account {
  const factory Account({
    /// Bank name, e.g. `국민`.
    @Default('') String bank,

    /// Account number, e.g. `123-45-6789`.
    @Default('') String number,

    /// Account holder name, e.g. `김철수`.
    @Default('') String holder,

    /// Relation to the couple, e.g. `신랑`, `아버지`, `어머니`.
    @Default('') String relation,
  }) = _Account;
}
