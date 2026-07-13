/// Step 4:
/// Model
///
/// Based on entity from domain layer,
/// Implement data model that can be used in data sources & repositories

import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

/// AccountModel in data layer.
///
/// Serialized as a JSON object inside the `groom_accounts` / `bride_accounts`
/// TEXT columns of the `schedules` table.
@freezed
abstract class AccountModel with _$AccountModel {
  factory AccountModel({
    @Default('') String bank,
    @Default('') String number,
    @Default('') String holder,
    @Default('') String relation,
  }) = _AccountModel;

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);
}
