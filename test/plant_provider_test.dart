import 'package:flutter_test/flutter_test.dart';
import 'package:plantpal/models/plant.dart';
import 'package:plantpal/providers/plant_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Plant _plant({
  String id = '1',
  String nickname = 'Fern',
  int waterEveryDays = 7,
  int wateredDaysAgo = 0,
}) => Plant(
  id: id,
  nickname: nickname,
  species: 'Nephrolepis exaltata',
  waterEveryDays: waterEveryDays,
  lastWatered: DateTime.now().subtract(Duration(days: wateredDaysAgo)),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PlantProvider CRUD', () {
    test('load() seeds a fresh install', () async {
      final p = PlantProvider();
      await p.load();
      expect(p.count, 2);
      expect(p.isLoading, isFalse);
    });

    test('add() inserts a plant and increases the count', () async {
      final p = PlantProvider();
      await p.load();
      final before = p.count;

      await p.add(_plant(id: 'x', nickname: 'Basil'));

      expect(p.count, before + 1);
      expect(p.plants.any((e) => e.nickname == 'Basil'), isTrue);
    });

    test('update() replaces an existing plant in place', () async {
      final p = PlantProvider();
      await p.load();
      final target = p.plants.first;

      await p.update(target.copyWith(nickname: 'Renamed', waterEveryDays: 3));

      expect(p.count, 2, reason: 'update must not add a row');
      final updated = p.plants.firstWhere((e) => e.id == target.id);
      expect(updated.nickname, 'Renamed');
      expect(updated.waterEveryDays, 3);
    });

    test(
      'markWatered() resets the timer so the plant is no longer due',
      () async {
        final p = PlantProvider();
        await p.load();
        for (final existing in p.plants) {
          await p.remove(existing);
        }
        await p.add(_plant(wateredDaysAgo: 30));
        expect(p.dueToday.length, 1);

        await p.markWatered(p.plants.first);

        expect(p.dueToday, isEmpty);
      },
    );

    test('remove() deletes a plant', () async {
      final p = PlantProvider();
      await p.load();
      final target = p.plants.first;

      await p.remove(target);

      expect(p.plants.any((e) => e.id == target.id), isFalse);
      expect(p.count, 1);
    });

    test('byNextWatering() sorts soonest-first', () async {
      final p = PlantProvider();
      await p.load();
      for (final existing in p.plants) {
        await p.remove(existing);
      }
      await p.add(_plant(id: 'later', nickname: 'Later', wateredDaysAgo: 0));
      await p.add(_plant(id: 'sooner', nickname: 'Sooner', wateredDaysAgo: 6));

      expect(p.byNextWatering.first.nickname, 'Sooner');
    });

    test('notifies listeners when the collection changes', () async {
      final p = PlantProvider();
      await p.load();
      var notifications = 0;
      p.addListener(() => notifications++);

      await p.add(_plant(id: 'n', nickname: 'New'));

      expect(notifications, greaterThan(0));
    });

    test('survives a corrupt saved payload without crashing', () async {
      SharedPreferences.setMockInitialValues({
        'plantpal.plants.v1': '{not valid json at all',
      });
      final p = PlantProvider();

      await p.load();

      // Falls back to the seed list rather than throwing.
      expect(p.count, greaterThan(0));
      expect(p.isLoading, isFalse);
    });
  });

  group('Plant', () {
    test('needsWaterToday is true when the interval has elapsed', () {
      expect(
        _plant(waterEveryDays: 7, wateredDaysAgo: 7).needsWaterToday,
        isTrue,
      );
      expect(
        _plant(waterEveryDays: 7, wateredDaysAgo: 8).needsWaterToday,
        isTrue,
      );
      expect(
        _plant(waterEveryDays: 7, wateredDaysAgo: 1).needsWaterToday,
        isFalse,
      );
    });

    test('wateringStatus describes overdue, today and future states', () {
      expect(
        _plant(waterEveryDays: 7, wateredDaysAgo: 9).wateringStatus,
        'Overdue by 2 days',
      );
      expect(
        _plant(waterEveryDays: 7, wateredDaysAgo: 7).wateringStatus,
        'Water today',
      );
      expect(
        _plant(waterEveryDays: 7, wateredDaysAgo: 6).wateringStatus,
        'Water tomorrow',
      );
    });

    test('round-trips through JSON for persistence', () {
      final original = _plant(id: 'rt', nickname: 'Roundtrip');
      final restored = Plant.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.nickname, original.nickname);
      expect(restored.species, original.species);
      expect(restored.waterEveryDays, original.waterEveryDays);
      expect(
        restored.lastWatered.toIso8601String(),
        original.lastWatered.toIso8601String(),
      );
    });

    test('fromJson tolerates missing optional fields', () {
      final restored = Plant.fromJson({
        'id': 'sparse',
        'lastWatered': 'not-a-date',
      });

      expect(restored.nickname, 'Unnamed plant');
      expect(restored.species, '');
      expect(restored.waterEveryDays, 7);
      expect(restored.lastWatered, isA<DateTime>());
    });
  });
}
