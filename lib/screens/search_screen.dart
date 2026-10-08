import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/species.dart';
import '../routes.dart';
import '../services/plant_api.dart';
import '../widgets/empty_state.dart';

/// "Plant Search" tab — searches the GBIF species API.
///
/// The API client comes from the provider tree (`context.read<PlantApi>()`)
/// rather than being constructed here, so tests can inject a mock client.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<Species> _results = const [];
  bool _loading = false;
  String? _error;
  bool _offline = false;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    _focus.unfocus();

    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    try {
      final results = await context.read<PlantApi>().search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searched = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _offline = e.isOffline;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search a plant, e.g. Monstera',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching GBIF\u2026'),
          ],
        ),
      );
    }

    if (_error != null) {
      return EmptyState(
        icon: _offline ? Icons.wifi_off : Icons.error_outline,
        title: _offline ? 'You are offline' : 'Search failed',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _search,
      );
    }

    if (!_searched) {
      return const EmptyState(
        icon: Icons.travel_explore,
        title: 'Find a species',
        message:
            'Search the GBIF plant database by name to see matching species, '
            'photos and care notes.',
      );
    }

    if (_results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No plants found',
        message:
            'Nothing matched "${_controller.text.trim()}". '
            'Try a different spelling or a shorter name.',
        actionLabel: 'Clear search',
        onAction: () {
          _controller.clear();
          setState(() {
            _results = const [];
            _searched = false;
          });
        },
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final species = _results[i];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.eco)),
          title: Text(
            species.scientificName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: species.family == null
              ? const Text('Family unknown')
              : Text(species.family!),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).pushNamed(Routes.speciesDetail, arguments: species),
        );
      },
    );
  }
}
