import 'package:flutter/material.dart';

import 'screens/add_plant_screen.dart';
import 'screens/home_shell.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/species_detail_screen.dart';

/// Every route name in the app, in one place.
///
/// Using constants instead of raw strings means a typo becomes a compile-time
/// error rather than a blank screen at runtime.
class Routes {
  const Routes._();

  static const home = '/';
  static const addPlant = '/plants/add';
  static const plantDetail = '/plants/detail';
  static const speciesDetail = '/species/detail';

  /// Arguments for [addPlant]: pass a `Plant` to edit it, or null to create.
  static const editPlantArg = 'plant';

  /// The route table handed to `MaterialApp.routes`.
  ///
  /// The three tab screens (My Plants, Water Schedule, Plant Search) are not
  /// listed here: they are panes inside [HomeShell], which is what the bottom
  /// navigation bar switches between. Only the screens pushed *on top* of the
  /// shell get their own named route.
  static Map<String, WidgetBuilder> get table => {
    home: (_) => const HomeShell(),
    addPlant: (_) => const AddPlantScreen(),
    plantDetail: (_) => const PlantDetailScreen(),
    speciesDetail: (_) => const SpeciesDetailScreen(),
  };
}
