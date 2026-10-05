import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/species.dart';

/// Searches species with the GBIF API and loads descriptions and photos
/// from the Wikipedia REST API. Neither API needs a key.
class PlantApi {
  PlantApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _headers = {'User-Agent': 'PlantPal/1.0 (student project)'};
  static const _plantaeKey = 6;

  Future<List<Species>> search(String query) async {
    final uri = Uri.https('api.gbif.org', '/v1/species/search', {
      'q': query,
      'rank': 'SPECIES',
      'status': 'ACCEPTED',
      'highertaxonKey': '$_plantaeKey',
      'limit': '20',
    });
    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Search failed (${res.statusCode})');
    }
    final results = (jsonDecode(res.body)['results'] as List)
        .map((e) => Species.fromGbif(e as Map<String, dynamic>))
        .toList();
    final seen = <String>{};
    return results.where((s) => seen.add(s.scientificName)).toList();
  }

  Future<SpeciesInfo> info(String scientificName) async {
    final title = Uri.encodeComponent(scientificName.replaceAll(' ', '_'));
    final uri = Uri.parse(
        'https://en.wikipedia.org/api/rest_v1/page/summary/$title');
    final res = await _client.get(uri, headers: _headers);
    if (res.statusCode == 404) return const SpeciesInfo();
    if (res.statusCode != 200) {
      throw Exception('Could not load info (${res.statusCode})');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return SpeciesInfo(
      description: json['extract'] as String?,
      imageUrl: (json['thumbnail'] as Map<String, dynamic>?)?['source'] as String?,
    );
  }
}
