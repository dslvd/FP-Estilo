import 'package:flutter/material.dart';

import '../models/species.dart';
import '../services/plant_api.dart';
import 'species_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  final PlantApi api;
  final void Function(Species) onAddSpecies;

  const SearchScreen({super.key, required this.api, required this.onAddSpecies});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Species> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.api.search(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not search. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text(_error!));
    } else if (_searched && _results.isEmpty) {
      body = const Center(child: Text('No plants found.'));
    } else {
      body = ListView(
        children: [
          for (final s in _results)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.eco)),
              title: Text(s.scientificName),
              subtitle: s.family == null ? null : Text(s.family!),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SpeciesDetailScreen(
                  species: s,
                  api: widget.api,
                  onAdd: widget.onAddSpecies,
                ),
              )),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Search plant name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
