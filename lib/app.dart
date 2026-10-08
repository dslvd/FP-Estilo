import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/plant_provider.dart';
import 'routes.dart';
import 'services/plant_api.dart';
import 'theme.dart';

/// The app shell: sets up the theme, the two shared objects every screen
/// needs (the plant store and the API client), and the named-route table.
///
/// Using named routes here means a screen can navigate with
/// `Navigator.pushNamed(context, Routes.addPlant)` instead of constructing
/// widgets inline, and the whole route map is readable in one place.
class PlantPalApp extends StatelessWidget {
  final PlantProvider? provider;

  const PlantPalApp({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PlantProvider>(
          create: (_) => provider ?? PlantProvider(),
        ),
        Provider<PlantApi>(create: (_) => PlantApi()),
      ],
      child: MaterialApp(
        title: 'PlantPal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        initialRoute: Routes.home,
        routes: Routes.table,
      ),
    );
  }
}
