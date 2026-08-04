/// One level of schooling (e.g. "Matric") and the groups/streams offered
/// under it (e.g. "Science", "Arts").
class AcademicLevel {
  final String name;
  final List<String> groups;

  const AcademicLevel({required this.name, required this.groups});

  /// Flat class-name strings this level contributes, e.g. "Matric - Science".
  List<String> get classNames => groups.map((g) => '$name - $g').toList();

  Map<String, dynamic> toMap() => {'name': name, 'groups': groups};

  factory AcademicLevel.fromMap(Map<dynamic, dynamic> map) => AcademicLevel(
        name: (map['name'] ?? '').toString(),
        groups: (map['groups'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  AcademicLevel copyWith({String? name, List<String>? groups}) =>
      AcademicLevel(name: name ?? this.name, groups: groups ?? this.groups);
}

/// An academy's configurable academic structure (levels + groups), stored
/// as one doc per academy. Replaces the previous hardcoded `AppClasses.all`
/// list — every place that used to consume that fixed list now consumes
/// [AcademicStructure.flatClassNames] instead, so downstream code (class
/// dropdowns, attendance, fees, reports) keeps working against a plain
/// class-name string exactly as before.
class AcademicStructure {
  final List<AcademicLevel> levels;

  const AcademicStructure({required this.levels});

  List<String> get flatClassNames =>
      levels.expand((l) => l.classNames).toList();

  /// Seed defaults matching the academy's usual Matric/Intermediate
  /// structure — used the first time an academy has no structure doc yet.
  static const AcademicStructure defaults = AcademicStructure(levels: [
    AcademicLevel(name: 'Matric', groups: ['Science', 'Arts']),
    AcademicLevel(name: 'Intermediate', groups: [
      'FSc Pre-Medical',
      'FSc Pre-Engineering',
      'ICS',
      'ICom',
      'FA',
    ]),
  ]);

  Map<String, dynamic> toMap() =>
      {'levels': levels.map((l) => l.toMap()).toList()};

  factory AcademicStructure.fromMap(Map<dynamic, dynamic> map) {
    final rawLevels = map['levels'] as List<dynamic>?;
    if (rawLevels == null || rawLevels.isEmpty) return defaults;
    return AcademicStructure(
      levels: rawLevels
          .map((e) => AcademicLevel.fromMap(e as Map<dynamic, dynamic>))
          .toList(),
    );
  }

  AcademicStructure copyWith({List<AcademicLevel>? levels}) =>
      AcademicStructure(levels: levels ?? this.levels);
}
