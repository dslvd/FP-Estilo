import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plantpal/services/plant_api.dart';

void main() {
  test('search parses GBIF results and removes duplicates', () async {
    final api = PlantApi(
      client: MockClient((req) async {
        expect(req.url.host, 'api.gbif.org');
        expect(req.url.queryParameters['q'], 'monstera');
        return http.Response(
          jsonEncode({
            'results': [
              {'key': 1, 'canonicalName': 'Monstera deliciosa', 'family': 'Araceae'},
              {'key': 2, 'canonicalName': 'Monstera deliciosa', 'family': 'Araceae'},
              {'key': 3, 'scientificName': 'Monstera acuminata K.Koch'},
            ]
          }),
          200,
        );
      }),
    );
    final r = await api.search('monstera');
    expect(r.map((s) => s.scientificName),
        ['Monstera deliciosa', 'Monstera acuminata K.Koch']);
  });

  test('info returns empty result on 404', () async {
    final api = PlantApi(client: MockClient((_) async => http.Response('', 404)));
    final info = await api.info('Nothing here');
    expect(info.description, isNull);
  });
}
