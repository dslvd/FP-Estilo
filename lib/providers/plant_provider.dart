import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plant.dart';

/// Single source of truth for the user's plant collection.
///
/// Every screen reads from this one object instead of receiving the plant
/// list through constructor parameters, which is what the project brief means
/// by "state must not be passed through long constructor chains".
///
/// It is a [ChangeNotifier], so `context.watch<PlantProvider>()` rebuilds a
/// screen whenever the list changes and `context.read<PlantProvider>()` calls
/// the mutating methods without subscribing to rebuilds.
class PlantProvider extends ChangeNotifier {
  PlantProvider({SharedPreferences? prefs}) : _prefs = prefs;

  static const _storageKey = 'plantpal.plants.v1';

  /// Set once the saved list has been read, so a deliberately emptied list is
  /// not re-seeded on the next launch.
  static const _seededKey = 'plantpal.seeded.v1';

  SharedPreferences? _prefs;
  final List<Plant> _plants = [];

  /// True while the saved list is being read from disk on start-up.
  bool _loading = true;
  bool get isLoading => _loading;

  /// Unmodifiable so screens cannot mutate the list behind the provider's back.
  List<Plant> get plants => List.unmodifiable(_plants);

  /// Plants ordered by how soon they need water, soonest first.
  /// Used by the Water Schedule screen.
  List<Plant> get byNextWatering {
    final sorted = [..._plants];
    sorted.sort((a, b) => a.nextWatering.compareTo(b.nextWatering));
    return sorted;
  }

  /// Every plant that is due today or overdue. Used for the home-screen banner.
  List<Plant> get dueToday =>
      _plants.where((p) => p.needsWaterToday).toList(growable: false);

  int get count => _plants.length;

  /// Reads the persisted list. Called once from `main()` before `runApp`.
  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    _plants.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _plants.addAll(
          decoded
              .map((e) => Plant.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } catch (error) {
        // A corrupt store must not crash the app: start from an empty list
        // and leave the bad payload in place for debugging.
        debugPrint('PlantProvider.load: could not read saved plants: $error');
      }
    }
    if (_plants.isEmpty && !(_prefs!.getBool(_seededKey) ?? false)) {
      _plants.addAll(_seedPlants());
      await _prefs!.setBool(_seededKey, true);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(
      _storageKey,
      jsonEncode(_plants.map((p) => p.toJson()).toList()),
    );
  }

  /// CREATE — adds a plant, or replaces the existing one with the same id.
  Future<void> add(Plant plant) async {
    _plants.removeWhere((p) => p.id == plant.id);
    _plants.add(plant);
    notifyListeners();
    await _persist();
  }

  /// UPDATE — edits the nickname / species / interval of an existing plant.
  Future<void> update(Plant plant) async {
    final i = _plants.indexWhere((p) => p.id == plant.id);
    if (i == -1) return;
    _plants[i] = plant;
    notifyListeners();
    await _persist();
  }

  /// UPDATE — resets the watering timer to right now.
  Future<void> markWatered(Plant plant) async {
    final i = _plants.indexWhere((p) => p.id == plant.id);
    if (i == -1) return;
    _plants[i] = plant.copyWith(lastWatered: DateTime.now());
    notifyListeners();
    await _persist();
  }

  /// DELETE — removes a plant from the collection.
  Future<void> remove(Plant plant) async {
    _plants.removeWhere((p) => p.id == plant.id);
    notifyListeners();
    await _persist();
  }

  /// Convenience for the species search screen's "Add to my plants" button.
  Future<Plant> addSpecies(
    String scientificName, {
    int waterEveryDays = 7,
  }) async {
    final plant = Plant(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nickname: scientificName,
      species: scientificName,
      waterEveryDays: waterEveryDays,
      lastWatered: DateTime.now(),
    );
    await add(plant);
    return plant;
  }

  /// Two example plants so a fresh install is not an empty screen.
  List<Plant> _seedPlants() => [
    Plant(
      id: 'seed-1',
      nickname: 'Monstera',
      species: 'Monstera deliciosa',
      waterEveryDays: 7,
      lastWatered: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Plant(
      id: 'seed-2',
      nickname: 'Snake plant',
      species: 'Dracaena trifasciata',
      waterEveryDays: 14,
      lastWatered: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}
