import 'dart:convert';

import '../models/account/account_model.dart';
import '../models/schedule/schedule_model.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/entities/schedule.dart';

/// ScheduleMapper class converts Schedule(entity, domain) <-> ScheduleModel(model, data)
class ScheduleMapper {
  /// Converts Schedule(entity, domain) -> ScheduleModel(model, data)
  static ScheduleModel toModel(Schedule entity) {
    return ScheduleModel(
      link: entity.link,
      thumbnail: entity.thumbnail,
      groom: entity.groom,
      bride: entity.bride,
      date: entity.date.toIso8601String(),
      location: entity.location,
      groomAccounts: encodeAccounts(entity.groomAccounts),
      brideAccounts: encodeAccounts(entity.brideAccounts),
      attendance: entity.attendance.name,
      pay: entity.pay,
    );
  }

  /// Converts ScheduleModel(model, data) -> Schedule(entity, domain)
  static Schedule toEntity(ScheduleModel model) {
    return Schedule(
      link: model.link,
      thumbnail: model.thumbnail,
      groom: model.groom,
      bride: model.bride,
      date: DateTime.parse(model.date).toLocal(),
      location: model.location,
      groomAccounts: decodeAccounts(model.groomAccounts),
      brideAccounts: decodeAccounts(model.brideAccounts),
      attendance: Attendance.fromName(model.attendance),
      pay: model.pay,
    );
  }

  /// Encodes accounts into the JSON string kept in a single TEXT column.
  static String encodeAccounts(List<Account> accounts) {
    return jsonEncode(accounts
        .map((account) => AccountModel(
              bank: account.bank,
              number: account.number,
              holder: account.holder,
              relation: account.relation,
            ).toJson())
        .toList());
  }

  /// Decodes the TEXT column back into accounts.
  ///
  /// Rows written before the accounts migration hold `null`/empty text,
  /// and a malformed payload should never break the whole schedule,
  /// so both cases fall back to an empty list.
  static List<Account> decodeAccounts(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(AccountModel.fromJson)
          .map((model) => Account(
                bank: model.bank,
                number: model.number,
                holder: model.holder,
                relation: model.relation,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
