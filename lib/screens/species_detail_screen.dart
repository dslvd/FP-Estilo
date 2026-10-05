import 'package:flutter/material.dart';

import '../models/species.dart';
import '../services/plant_api.dart';

class SpeciesDetailScreen extends StatefulWidget {
  final Species species;
  final PlantApi api;
  final void Function(Species) onAdd;

  const SpeciesDetailScreen({
    super.key,
    required this.species,
    required this.api,
    required this.onAdd,
  });

  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  late final Future<SpeciesInfo> _info =
      widget.api.info(widget.species.scientificName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.species.scientificName)),
      body: FutureBuilder<SpeciesInfo>(
        future: _info,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final info = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (info?.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(info!.imageUrl!, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              if (widget.species.family != null)
                Text('Family: ${widget.species.family}'),
              const SizedBox(height: 8),
              Text(snap.hasError
                  ? 'Could not load description.'
                  : info?.description ?? 'No description available.'),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add to my plants'),
                onPressed: () {
                  widget.onAdd(widget.species);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
