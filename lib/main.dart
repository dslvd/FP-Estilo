import 'package:flutter/material.dart';

import 'app.dart';
import 'providers/plant_provider.dart';

/// Entry point.
///
/// The saved plant list is read from disk *before* the first frame so the
/// home screen never flashes an empty state on a cold start.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final provider = PlantProvider();
  await provider.load();

  runApp(PlantPalApp(provider: provider));
}
