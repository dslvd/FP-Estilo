import 'package:flutter_test/flutter_test.dart';
import 'package:plantpal/app.dart';
import 'package:plantpal/models/plant.dart';
import 'package:plantpal/providers/plant_provider.dart';
import 'package:plantpal/widgets/empty_state.dart';
import 'package:plantpal/widgets/plant_list_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the app with an in-memory SharedPreferences store so the widget
/// tests never touch real device storage.
Future<PlantProvider> _providerWith(List<Plant> plants) async {
  SharedPreferences.setMockInitialValues({});
  final provider = PlantProvider();
  await provider.load();
  // Replace the seed data with exactly what the test wants to see.
  for (final p in provider.plants) {
    await provider.remove(p);
  }
  for (final p in plants) {
    await provider.add(p);
  }
  return provider;
}

Plant _plant({
  String id = '1',
  String nickname = 'Monstera',
  int waterEveryDays = 7,
  int wateredDaysAgo = 0,
}) => Plant(
  id: id,
  nickname: nickname,
  species: 'Monstera deliciosa',
  waterEveryDays: waterEveryDays,
  lastWatered: DateTime.now().subtract(Duration(days: wateredDaysAgo)),
);

void main() {
  testWidgets('shows the plant list and the app title on launch', (
    tester,
  ) async {
    final provider = await _providerWith([_plant()]);
    await tester.pumpWidget(PlantPalApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('PlantPal'), findsOneWidget);
    expect(find.byType(PlantListTile), findsOneWidget);
    expect(find.text('Monstera'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no plants', (tester) async {
    final provider = await _providerWith([]);
    await tester.pumpWidget(PlantPalApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('No plants yet'), findsOneWidget);
  });

  testWidgets('summary banner reports plants that need water today', (
    tester,
  ) async {
    final provider = await _providerWith([
      _plant(
        id: '1',
        nickname: 'Thirsty',
        waterEveryDays: 7,
        wateredDaysAgo: 9,
      ),
      _plant(id: '2', nickname: 'Happy', waterEveryDays: 7, wateredDaysAgo: 0),
    ]);
    await tester.pumpWidget(PlantPalApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 need water today'), findsOneWidget);
  });

  testWidgets('tapping a plant opens its detail screen', (tester) async {
    final provider = await _providerWith([_plant(nickname: 'Fern')]);
    await tester.pumpWidget(PlantPalApp(provider: provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fern'));
    await tester.pumpAndSettle();

    // The detail screen shows the CRUD actions.
    expect(find.text('Mark as watered'), findsOneWidget);
    expect(find.text('Delete plant'), findsOneWidget);
  });

  testWidgets('water icon marks a plant watered and updates the UI', (
    tester,
  ) async {
    final provider = await _providerWith([
      _plant(nickname: 'Thirsty', waterEveryDays: 7, wateredDaysAgo: 9),
    ]);
    await tester.pumpWidget(PlantPalApp(provider: provider));
    await tester.pumpAndSettle();

    expect(provider.dueToday.length, 1);

    await tester.tap(find.byTooltip('Water now'));
    await tester.pumpAndSettle();

    // After watering, nothing is due and the banner says so.
    expect(provider.dueToday, isEmpty);
    expect(find.text('All 1 plants are watered'), findsOneWidget);
  });

  testWidgets('the bottom navigation bar switches to the schedule tab', (
    tester,
  ) async {
    final provider = await _providerWith([_plant()]);
    await tester.pumpWidget(PlantPalApp(provider: provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(find.text('Water Schedule'), findsOneWidget);
  });

  testWidgets('the add form rejects an empty nickname', (tester) async {
    final provider = await _providerWith([]);
    await tester.pumpWidget(PlantPalApp(provider: provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add a plant'));
    await tester.pumpAndSettle();

    expect(find.text('New Plant'), findsOneWidget);

    // Save with the form still empty.
    await tester.tap(find.text('Save plant'));
    await tester.pumpAndSettle();

    expect(find.text('Give your plant a nickname'), findsOneWidget);
    // Nothing was created.
    expect(provider.count, 0);
  });
}
