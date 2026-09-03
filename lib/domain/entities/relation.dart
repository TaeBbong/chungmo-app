/// Step 1:
/// Pure Entity Model
///
/// Only getter, setter enabled
/// to passthrough data to presentation layer

/// The user's relationship to the couple.
///
/// Persisted by [name], so the names are part of the DB contract:
/// renaming one requires a migration.
enum Relation {
  unset,
  family,
  friend,
  coworker,
  acquaintance;

  static Relation fromName(String? name) {
    return Relation.values.firstWhere(
      (value) => value.name == name,
      orElse: () => Relation.unset,
    );
  }

  String get label => switch (this) {
        Relation.unset => '미지정',
        Relation.family => '가족·친척',
        Relation.friend => '친구',
        Relation.coworker => '직장',
        Relation.acquaintance => '지인',
      };
}
