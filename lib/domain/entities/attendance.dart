/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

/// Whether the user plans to attend a wedding.
///
/// Persisted by [name], so the names are part of the DB contract:
/// renaming one requires a migration.
enum Attendance {
  undecided,
  attending,
  absent;

  static Attendance fromName(String? name) {
    return Attendance.values.firstWhere(
      (value) => value.name == name,
      orElse: () => Attendance.undecided,
    );
  }

  String get label => switch (this) {
        Attendance.undecided => '미정',
        Attendance.attending => '참석',
        Attendance.absent => '불참',
      };
}
