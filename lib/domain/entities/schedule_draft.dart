/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

import 'account.dart';
import 'schedule.dart';

/// A partially extracted schedule: what the parser could read from an
/// invitation when it could not produce a complete [Schedule].
///
/// Unlike [Schedule], [date] is nullable — a missing wedding datetime is
/// the usual reason an extraction is incomplete. The schedule form uses a
/// draft to prefill its fields so the user only fixes what is missing.
class ScheduleDraft {
  final String link;
  final String thumbnail;
  final String groom;
  final String bride;
  final DateTime? date;
  final String location;
  final List<Account> groomAccounts;
  final List<Account> brideAccounts;

  const ScheduleDraft({
    this.link = '',
    this.thumbnail = '',
    this.groom = '',
    this.bride = '',
    this.date,
    this.location = '',
    this.groomAccounts = const <Account>[],
    this.brideAccounts = const <Account>[],
  });

  factory ScheduleDraft.fromSchedule(Schedule schedule, {DateTime? date}) {
    return ScheduleDraft(
      link: schedule.link,
      thumbnail: schedule.thumbnail,
      groom: schedule.groom,
      bride: schedule.bride,
      date: date,
      location: schedule.location,
      groomAccounts: schedule.groomAccounts,
      brideAccounts: schedule.brideAccounts,
    );
  }
}

/// Thrown when an invitation was parsed but the result cannot be saved as-is
/// (no usable datetime). Extends [FormatException] so the existing rethrow
/// chains and failure classification keep working; [draft] carries whatever
/// was extracted so the user can complete it by hand.
class IncompleteScheduleException extends FormatException {
  final ScheduleDraft draft;

  const IncompleteScheduleException(this.draft)
      : super('[-] Invitation parsed without a usable datetime');
}
