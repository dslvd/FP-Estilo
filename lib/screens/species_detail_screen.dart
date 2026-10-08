import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/species.dart';
import '../providers/plant_provider.dart';
import '../services/plant_api.dart';
import '../widgets/async_builder.dart';

/// "Species Details" — the Wikipedia photo and description for a species the
/// user tapped in Plant Search, plus a button to add it to their collection.
///
/// This is the screen that demonstrates the full API round trip: the GBIF
/// result chosen on the previous screen is passed in as a route argument, and
/// the Wikipedia call for that species is made here.
class SpeciesDetailScreen extends StatefulWidget {
  const SpeciesDetailScreen({super.key});

  @override
  State<SpeciesDetailScreen> createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  Future<SpeciesInfo>? _future;
  Species? _species;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future != null) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Species) {
      _species = arg;
      _load();
    }
  }

  void _load() {
    setState(() {
      _future = context.read<PlantApi>().info(_species!.scientificName);
    });
  }

  Future<void> _addToMyPlants(SpeciesInfo info) async {
    final provider = context.read<PlantProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final plant = await provider.addSpecies(_species!.scientificName);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${plant.nickname} added to My Plants')),
      );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final species = _species;
    if (species == null) {
      return const Scaffold(
        body: Center(child: Text('No species was selected.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(species.scientificName)),
      body: AsyncBuilder<SpeciesInfo>(
        future: _future!,
        onRetry: _load,
        loadingLabel: 'Loading care info\u2026',
        builder: (context, info) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HeroImage(imageUrl: info.imageUrl),
            const SizedBox(height: 20),
            _InfoChip(
              icon: Icons.account_tree_outlined,
              label: 'Family',
              value: species.family ?? 'Not recorded by GBIF',
            ),
            const SizedBox(height: 20),
            Text(
              'About this species',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              info.description ??
                  'Wikipedia has no summary for this species yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: info.description == null
                    ? Theme.of(context).colorScheme.outline
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Description and photo from the Wikipedia REST API.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _addToMyPlants(info),
              icon: const Icon(Icons.add),
              label: const Text('Add to my plants'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The species photo, with a graceful placeholder when Wikipedia has none
/// (or when the image itself fails to load over a slow connection).
class _HeroImage extends StatelessWidget {
  final String? imageUrl;

  const _HeroImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholder = Container(
      height: 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'No photo available',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );

    if (imageUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imageUrl!,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 220,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        // A broken image URL should not leave a red error box on screen.
        errorBuilder: (context, error, stack) => placeholder,
      ),
    );
  }
}

/// Small labelled chip used for the species' taxonomic family.
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
