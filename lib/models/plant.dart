/// The core data entity of the app: one plant the user is looking after.
///
/// This class is deliberately free of any Flutter imports so it can be used
/// and unit-tested without a widget tree.
class Plant {
  final String id;
  final String nickname;
  final String species;

  /// How many days the user waits between waterings for this plant.
  final int waterEveryDays;

  final DateTime lastWatered;

  const Plant({
    required this.id,
    required this.nickname,
    required this.species,
    required this.waterEveryDays,
    required this.lastWatered,
  });

  /// The date this plant is next due to be watered.
  DateTime get nextWatering => lastWatered.add(Duration(days: waterEveryDays));

  /// True when the plant is due today or already overdue.
  bool get needsWaterToday {
    final now = DateTime.now();
    final next = nextWatering;
    return !DateTime(
      next.year,
      next.month,
      next.day,
    ).isAfter(DateTime(now.year, now.month, now.day));
  }

  /// Whole days remaining until the next watering (negative when overdue).
  int get daysUntilWatering {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = DateTime(
      nextWatering.year,
      nextWatering.month,
      nextWatering.day,
    );
    return next.difference(today).inDays;
  }

  /// A short human-readable status such as "Water today" or "in 3 days".
  String get wateringStatus {
    final d = daysUntilWatering;
    if (d < 0) return 'Overdue by ${-d} day${-d == 1 ? '' : 's'}';
    if (d == 0) return 'Water today';
    if (d == 1) return 'Water tomorrow';
    return 'Water in $d days';
  }

  /// Copy with any field replaced. Used by the edit flow and by "mark watered".
  Plant copyWith({
    String? nickname,
    String? species,
    int? waterEveryDays,
    DateTime? lastWatered,
  }) => Plant(
    id: id,
    nickname: nickname ?? this.nickname,
    species: species ?? this.species,
    waterEveryDays: waterEveryDays ?? this.waterEveryDays,
    lastWatered: lastWatered ?? this.lastWatered,
  );

  /// Serialised for local persistence (SharedPreferences).
  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'species': species,
    'waterEveryDays': waterEveryDays,
    'lastWatered': lastWatered.toIso8601String(),
  };

  /// Rebuilds a plant from stored JSON. [lastWatered] is parsed defensively
  /// so a single corrupt record cannot take down the whole list.
  factory Plant.fromJson(Map<String, dynamic> json) => Plant(
    id: json['id'] as String,
    nickname: json['nickname'] as String? ?? 'Unnamed plant',
    species: json['species'] as String? ?? '',
    waterEveryDays: (json['waterEveryDays'] as num?)?.toInt() ?? 7,
    lastWatered:
        DateTime.tryParse(json['lastWatered'] as String? ?? '') ??
        DateTime.now(),
  );

  @override
  String toString() => 'Plant($id, $nickname, every $waterEveryDays d)';
}
