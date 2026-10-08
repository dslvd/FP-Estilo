import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plantpal/models/species.dart';
import 'package:plantpal/services/plant_api.dart';

void main() {
  group('PlantApi.search', () {
    test('parses GBIF results and removes duplicate species', () async {
      final api = PlantApi(
        client: MockClient((req) async {
          expect(req.url.host, 'api.gbif.org');
          expect(req.url.queryParameters['q'], 'monstera');
          // The plant-kingdom filter must always be sent.
          expect(req.url.queryParameters['highertaxonKey'], '6');
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'key': 1,
                  'canonicalName': 'Monstera deliciosa',
                  'family': 'Araceae',
                },
                {
                  'key': 2,
                  'canonicalName': 'Monstera deliciosa',
                  'family': 'Araceae',
                },
                {'key': 3, 'scientificName': 'Monstera acuminata K.Koch'},
              ],
            }),
            200,
          );
        }),
      );

      final results = await api.search('monstera');

      expect(results.map((s) => s.scientificName), [
        'Monstera deliciosa',
        'Monstera acuminata K.Koch',
      ]);
      expect(results.first.family, 'Araceae');
      // The third record had no canonicalName, so it fell back to
      // scientificName and its family stayed null.
      expect(results.last.family, isNull);
    });

    test('reports being offline as an offline ApiException', () async {
      final api = PlantApi(
        client: MockClient(
          (_) async => throw const SocketException('no route to host'),
        ),
      );

      expect(
        () => api.search('fern'),
        throwsA(
          isA<ApiException>().having((e) => e.isOffline, 'isOffline', isTrue),
        ),
      );
    });

    test('treats a web ClientException as being offline', () async {
      // On Flutter web there is no dart:io, so "no network" arrives as an
      // http.ClientException instead of a SocketException.
      final api = PlantApi(
        client: MockClient(
          (_) async => throw http.ClientException('Failed to fetch'),
        ),
      );

      expect(
        () => api.search('fern'),
        throwsA(
          isA<ApiException>().having((e) => e.isOffline, 'isOffline', isTrue),
        ),
      );
    });

    test('reports a non-200 response as a non-offline failure', () async {
      final api = PlantApi(
        client: MockClient((_) async => http.Response('nope', 503)),
      );

      expect(
        () => api.search('fern'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isOffline, 'isOffline', isFalse)
              .having((e) => e.message, 'message', contains('503')),
        ),
      );
    });
  });

  group('PlantApi.info', () {
    test('parses the Wikipedia summary extract and thumbnail', () async {
      final api = PlantApi(
        client: MockClient((req) async {
          expect(req.url.path, contains('Monstera_deliciosa'));
          return http.Response(
            jsonEncode({
              'extract': 'A species of flowering plant.',
              'thumbnail': {'source': 'https://example.test/m.jpg'},
            }),
            200,
          );
        }),
      );

      final info = await api.info('Monstera deliciosa');

      expect(info.description, 'A species of flowering plant.');
      expect(info.imageUrl, 'https://example.test/m.jpg');
    });

    test('treats a missing Wikipedia article as empty, not an error', () async {
      final api = PlantApi(
        client: MockClient((_) async => http.Response('missing', 404)),
      );

      final info = await api.info('Nonexistent plant');

      expect(info.description, isNull);
      expect(info.imageUrl, isNull);
    });
  });

  group('Species.fromGbif', () {
    test('falls back to scientificName when canonicalName is absent', () {
      final s = Species.fromGbif({
        'key': 7,
        'scientificName': 'Ficus lyrata Warb.',
      });
      expect(s.scientificName, 'Ficus lyrata Warb.');
      expect(s.family, isNull);
    });
  });
}
