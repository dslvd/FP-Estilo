class Plant {
  final String id;
  final String nickname;
  final String species;
  final int waterEveryDays;
  final DateTime lastWatered;

  const Plant({
    required this.id,
    required this.nickname,
    required this.species,
    required this.waterEveryDays,
    required this.lastWatered,
  });

  DateTime get nextWatering => lastWatered.add(Duration(days: waterEveryDays));

  bool get needsWaterToday {
    final now = DateTime.now();
    final next = nextWatering;
    return !DateTime(next.year, next.month, next.day)
        .isAfter(DateTime(now.year, now.month, now.day));
  }

  Plant copyWith({DateTime? lastWatered}) => Plant(
        id: id,
        nickname: nickname,
        species: species,
        waterEveryDays: waterEveryDays,
        lastWatered: lastWatered ?? this.lastWatered,
      );
}
